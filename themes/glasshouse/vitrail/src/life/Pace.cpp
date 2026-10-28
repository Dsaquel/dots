#include "life/Internal.hpp"

namespace Life {
    SP<Hyprutils::Animation::SAnimationPropertyConfig> pace(const std::string& leaf, const std::string& curve, float ms) {
        auto& cfg = g_glass->paces[leaf + curve + std::to_string(int(ms))];
        if (!cfg) {
            const auto SRC = Config::animationTree()->getAnimationPropertyConfig(leaf);
            const auto VAL = SRC ? SRC->pValues.lock() : nullptr;
            cfg            = makeShared<Hyprutils::Animation::SAnimationPropertyConfig>();
            cfg->overridden      = true;
            cfg->internalBezier  = curve;
            cfg->internalStyle   = VAL ? VAL->internalStyle : "";
            cfg->internalSpeed   = ms / 100.F;
            cfg->internalEnabled = 1;
            cfg->pValues         = cfg;
        }
        return cfg;
    }

    void retime(const PHLWINDOW& w, const std::string& leaf, const std::string& curve, float ms) {
        if (!g_glass->retime->value() || !w)
            return;
        for (const bool SIZE : {false, true}) {
            auto& v = SIZE ? w->sizeAnimation() : w->positionAnimation();
            if (!v->isBeingAnimated())
                continue;
            std::erase_if(g_glass->retimed, [&w, SIZE](const SRetimed& r) { return r.size == SIZE && r.window.lock() == w; });
            v->setConfig(pace(leaf, curve, ms));
            g_glass->retimed.push_back({.window = w, .size = SIZE, .goal = v->goal()});
        }
    }

    void restore(const SRetimed& r) {
        const auto W = r.window.lock();
        if (!W)
            return;
        auto& v = r.size ? W->sizeAnimation() : W->positionAnimation();
        v->setConfig(Config::animationTree()->getAnimationPropertyConfig("windowsMove"));
    }

    void jolt(const PHLWINDOW& receiver, int side, float wait) {
        const auto     AT  = std::chrono::steady_clock::now() + std::chrono::microseconds(int64_t(wait * 1000));
        const Vector2D OUT = {side == 1 ? 1.0 : (side == 3 ? -1.0 : 0.0), side == 2 ? 1.0 : (side == 0 ? -1.0 : 0.0)};
        const CBox     B   = receiver->geometricBox(Desktop::View::IGeometric::GEOMETRIC_GOAL);
        const Vector2D HIT = B.middle() + Vector2D{OUT.x * B.w / 2, OUT.y * B.h / 2};
        std::erase_if(g_jolts, [&receiver](const SJolt& j) { return j.window.lock() == receiver; });
        g_jolts.push_back({.window = receiver, .dir = OUT * -1, .amp = JOLT, .at = AT});
        for (const auto& w : Desktop::windowState()->windows()) {
            if (w == receiver || !validMapped(w) || w->isFloating() || w->m_workspace != receiver->m_workspace)
                continue;
            const CBox     N = w->geometricBox(Desktop::View::IGeometric::GEOMETRIC_GOAL);
            const Vector2D NEAR{std::clamp(HIT.x, N.x, N.x + N.w), std::clamp(HIT.y, N.y, N.y + N.h)};
            const Vector2D D = NEAR - HIT;
            const double   L = std::max(1.0, std::hypot(D.x, D.y));
            const float    A = ECHO * std::exp(-float(L) / FADE);
            if (A < 2 * FAINT)
                continue;
            std::erase_if(g_jolts, [&w](const SJolt& j) { return j.window.lock() == w; });
            g_jolts.push_back({.window = w, .dir = D / L, .amp = A, .at = AT + std::chrono::microseconds(int64_t((LAG + L / WAVE) * 1000))});
        }
    }

    float landsIn(const PHLWINDOW& w) {
        if (!w)
            return 0.F;
        const auto& P   = w->positionAnimation();
        const auto& Z   = w->sizeAnimation();
        const auto& V   = P->isBeingAnimated() ? P : Z;
        const auto  CFG = V->getConfig().lock();
        const auto  BEZ = Animation::mgr()->getBezier(V->getBezierName());
        if (!V->isBeingAnimated() || V->isSpringCurve() || !CFG || !BEZ)
            return 0.F;
        const auto   PB = P->isBeingAnimated() ? P->begun() : P->goal(), PG = P->goal();
        const auto   ZB = Z->isBeingAnimated() ? Z->begun() : Z->goal(), ZG = Z->goal();
        const double D  = std::max({std::abs(PG.x - PB.x), std::abs(PG.y - PB.y), std::abs(PG.x + ZG.x - PB.x - ZB.x), std::abs(PG.y + ZG.y - PB.y - ZB.y)});
        if (D <= LANDED)
            return 0.F;
        const auto  VALUES = CFG->pValues.lock();
        const float NOW    = V->getPercent();
        float       lo = NOW, hi = 1.F;
        for (int i = 0; i < 24; ++i) {
            const float MID = (lo + hi) / 2;
            (BEZ->getYForPoint(MID) >= 1.F - float(LANDED / D) ? hi : lo) = MID;
        }
        return std::max(0.F, (hi - NOW) * (VALUES ? VALUES->internalSpeed : CFG->internalSpeed) * 100.F);
    }

    float paceFor(float end, float land) {
        return land <= 0 ? 1.F : end / std::clamp(land, 0.8F * end, LIFE - 10);
    }

    void dropLens(const PHLWINDOW& w) {
        auto* const F = w ? CGlassFrame::of(w) : nullptr;
        if (!F || !F->m_lens)
            return;
        Gl::drop(w, F->m_lens);
        F->m_lens = nullptr;
        if (const auto M = w->m_monitor.lock(); M && !validMapped(F->peer())) {
            g_pHyprRenderer->damageMonitor(M);
            g_pHyprRenderer->damageBox(boxOf(w).expand(SPRAY));
        }
    }

    double slamAt(double s, double a, double b) {
        const double U = 1 - s;
        return 3 * U * U * s * a + 3 * U * s * s * b + s * s * s;
    }

    float cornerAt(double x, double l0, double lf) {
        const double K = (x - l0) / std::max(lf - l0, 1.0);
        if (K <= 0 || K >= 1)
            return K <= 0 ? 0.F : SLAM;
        double lo = 0, hi = 1;
        for (int i = 0; i < 24; ++i)
            (slamAt((lo + hi) / 2, 0.05, 0.7) < K ? lo : hi) = (lo + hi) / 2;
        return std::min(float(slamAt((lo + hi) / 2, 0.4, 0.8) * ANIM), SLAM);
    }

    std::vector<float> locksOf(double l0, double lf, double lg) {
        lg                 = std::clamp(lg, 0.0, lf - l0);
        const double N     = std::max(1.0, std::floor(lg / SLOT + 0.5));
        std::vector<float> locks;
        for (double k = 0; k < N && lg >= 1; ++k)
            locks.push_back(cornerAt(lf - lg + k * lg / N, l0, lf));
        return locks;
    }

    void give(const SP<CGhost>& g, const PHLWINDOW& receiver, float arrive, bool voiced) {
        int side = -1;
        if (receiver) {
            const auto   A = receiver->sizeAnimation()->begun(), B = receiver->sizeAnimation()->goal();
            const auto&  POS = receiver->positionAnimation();
            const auto   P = POS->isBeingAnimated() ? POS->begun() : POS->goal(), Q = POS->goal();
            const std::array<double, 4> MOVES = {P.y - Q.y, (Q.x + B.x) - (P.x + A.x), (Q.y + B.y) - (P.y + A.y), P.x - Q.x};
            const auto   IT = std::ranges::max_element(MOVES);
            side            = *IT > 8 ? int(std::distance(MOVES.begin(), IT)) : -1;
            retime(receiver, "windowsMove", side >= 0 ? "vitrailSlam" : "vitrailPace", side >= 0 ? arrive : LIFE);
            const float LAND = g_glass->retime->value() ? landsIn(receiver) : 0.F;
            const float LEAD = g->ms();
            const float KG   = side >= 0 && LAND > 0 ? paceFor(SLAM, LAND + LEAD) : 1.F;
            const CBox  GA   = g->area();
            const auto  NEAR = [](double a, double b) { return std::abs(a - b) <= FLUSH; };
            g->m_hoisted     = g->skinned() && CGlassFrame::of(receiver) && side % 2 == 1 ? NEAR(GA.y, Q.y) && NEAR(GA.h, B.y) && NEAR(side == 3 ? GA.x : GA.x + GA.w, side == 3 ? Q.x : Q.x + B.x) :
                                               g->skinned() && CGlassFrame::of(receiver) && side >= 0 && NEAR(GA.x, Q.x) && NEAR(GA.w, B.x) && NEAR(side == 0 ? GA.y : GA.y + GA.h, side == 0 ? Q.y : Q.y + B.y);
            if (auto* const F = CGlassFrame::of(receiver); F && side >= 0) {
                dropLens(receiver);
                F->lend(CGlassFrame::ROLE_RECEIVER, nullptr, side, g->m_hoisted ? GA : CBox{}, g->level());
                F->pace(paceFor(RECEIVER_END, LAND));
                F->sync(KG, LEAD);
                jolt(receiver, side, std::max(0.F, SLAM / KG - LEAD));
            }
            if (side >= 0 && LAND > 0)
                g->pace(KG);
            if (side >= 0 && voiced && LAND > 0 && CGlassFrame::of(receiver)) {
                const bool   ACROSS = side % 2 == 1;
                const double R      = receiver->presentation().rounding();
                const auto   LOCKS  = locksOf((ACROSS ? A.x : A.y) - 2 * R, (ACROSS ? B.x : B.y) - 2 * R, g->m_hoisted ? (ACROSS ? GA.w : GA.h) - 2 * R : 0.0);
                const auto   REAL   = [KG, LEAD](float t) { return std::max(0.F, t / KG - LEAD); };
                std::vector<float> heard;
                for (const float LOCK : LOCKS)
                    if (LOCK - (heard.empty() ? -1e9F : heard.back()) >= CUE_GAP && LOCK <= SLAM - CUE_GAP)
                        heard.push_back(LOCK);
                std::string cues = std::format("hoist,{:x}{},shatter@{:.0f}@0.3", rc<uintptr_t>(receiver.get()), g->m_hoisted ? std::format(",glaze-lift-2@{:.0f}@0.35", REAL(10)) : "", REAL(CLAP));
                for (size_t k = 0; k < heard.size(); ++k)
                    cues += std::format(",stone-{}@{:.0f}@0.28", 1 + k * 8 / heard.size(), REAL(heard[k]));
                announce(cues + std::format(",slam@{:.0f},boom@{:.0f}@0.3,weld@{:.0f}@0.5", REAL(SLAM), REAL(SLAM), REAL(SLAM + 4)));
            }
        }
        g->decide(side >= 0 ? receiver : nullptr, side, CGhost::BURN);
    }
}
