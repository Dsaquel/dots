#include "mullion/Internal.hpp"

namespace Mullion {
    float reachOf(const SScene& s, double d) {
        float lo = 0, hi = 4000;
        for (int i = 0; i < 24; ++i) {
            const float MID = (lo + hi) / 2;
            (waveAt(s, MID) >= d ? hi : lo) = MID;
        }
        return hi;
    }

    float realOf(const SScene& s, float t) {
        return t < s.boom ? (t - s.from) / s.rate : (s.boom - s.from) / s.rate + t - s.boom;
    }

    void wind(SScene& s, float from, float rate, float real) {
        s.from = from;
        s.rate = rate;
        s.real = std::round(real);
        s.clock->setConfig(vitrailClock(s.real / s.pace));
        s.clock->setValueAndWarp(0.F);
        *s.clock = 1.F;
    }

    SP<Hyprutils::Animation::SAnimationPropertyConfig> recoil(float pace) {
        auto& cfg = g_glass->paces[std::format("mullionRecoil{}", pace)];
        if (!cfg) {
            const auto SRC       = Config::animationTree()->getAnimationPropertyConfig("windowsMove");
            const auto VAL       = SRC ? SRC->pValues.lock() : nullptr;
            cfg                  = makeShared<Hyprutils::Animation::SAnimationPropertyConfig>();
            cfg->overridden      = true;
            cfg->internalBezier  = "vitrailRecoil";
            cfg->internalStyle   = VAL ? VAL->internalStyle : "";
            cfg->internalSpeed   = RECOIL / pace / 100.F;
            cfg->internalEnabled = 1;
            cfg->pValues         = cfg;
        }
        return cfg;
    }

    void kick(const PHLWINDOW& w, const Vector2D& by, float pace) {
        auto&      v    = w->positionAnimation();
        const auto GOAL = v->goal();
        v->setValueAndWarp(GOAL + by);
        *v = GOAL;
        v->setConfig(recoil(pace));
        std::erase_if(g_glass->retimed, [&w](const SRetimed& r) { return !r.size && r.window.lock() == w; });
        g_glass->retimed.push_back({.window = w, .size = false, .goal = GOAL});
    }

    void layBricks(SScene& s, const SRing& RING) {
        const double                LX = 2 * RING.ex, LY = 2 * RING.ey, A = RING.arc;
        const std::array<double, 4> START = {0, LX + A, LX + 2 * A + LY, 2 * LX + 3 * A + LY};
        for (int side = 0; side < 4; ++side) {
            const double LEN = side % 2 == 0 ? LX : LY;
            const int    N   = std::max(1, int(std::floor(LEN / PIECE_LEN + 0.5)));
            const double SEG = LEN / N;
            for (int k = 0; k <= N; ++k) {
                double     u0 = k < N ? START[side] + k * SEG : START[side] + LEN, u1 = k < N ? u0 + SEG : u0 + A;
                const int  TONE = k < N ? (k + side) % 2 : 2;
                const double D0 = RING.circ(u0, s.farN), D1 = RING.circ(u1, s.farN);
                const bool   ACROSS_FAR = s.farN >= u0 && s.farN <= u1;
                const double LO = ACROSS_FAR ? 0 : std::min(D0, D1);
                double       hi = std::max(D0, D1);
                if (LO >= s.lost - 1)
                    continue;
                if (hi > s.lost) {
                    (D0 > D1 ? u0 : u1) += D0 > D1 ? D0 - s.lost : -(D1 - s.lost);
                    hi = s.lost;
                }
                if (u1 - u0 < 3)
                    continue;
                const float SEED = float(s.bricks.size()) * 1.37F + s.seed;
                const float POP  = CRACK0 + (CRACK1 - CRACK0) * float((s.lost - (LO + hi) / 2) / s.lost) + (noise(SEED, 7.7F) - 0.5F) * 16.F;
                float       back = s.lap0;
                for (float t = EXPAND0; t < s.lap0; t += 1)
                    if (layAt(s, t) >= s.lost - LO - 0.5) {
                        back = t;
                        break;
                    }
                s.bricks.push_back({.u0 = u0, .u1 = u1, .d0 = LO, .d1 = hi, .pop = POP, .back = std::max(back, POP + 230), .seed = SEED, .tone = TONE});
            }
        }
    }

    bool early(const SScene& s) {
        return !s.released && ms(s) < s.boom;
    }

    void cue(const SScene& s) {
        std::vector<std::tuple<float, std::string, float>> list = {{0.F, s.melt ? "melt" : "unframe", 1.F}, {EXPAND0, "expand", 1.F}, {s.lap0, "confirm", 1.F}};
        std::vector<long> welds;
        for (const auto& b : s.bricks)
            welds.push_back(std::lround((b.back + SETTLED) / 5.F) * 5);
        std::ranges::sort(welds);
        welds.erase(std::unique(welds.begin(), welds.end()), welds.end());
        for (const long W : welds)
            list.emplace_back(float(W), "weld", 1.F);
        if (!s.stones.empty())
            list.emplace_back(s.stones.front().spawn, "gather", 1.F);
        for (size_t j = 0; j < s.stones.size(); ++j)
            list.emplace_back(s.stones[j].land, std::format("stone-{}", 1 + j * 8 / s.stones.size()), 0.34F);
        list.emplace_back(s.boom - CHARGE, "blink", 1.F);
        list.emplace_back(s.boom, "boom", 0.85F);
        const float NOW = ms(s), AT = realOf(s, NOW), DAMP = s.rate > 1 ? 0.55F : 1.F;
        float       last = -1e9F;
        std::string out  = std::format("mullion,{:x}", reinterpret_cast<uintptr_t>(s.born.lock().get()));
        for (const auto& [T, NAME, GAIN] : list) {
            const float DELAY = (realOf(s, T) - AT) / s.pace, G = GAIN * DAMP;
            if (T < NOW || (NAME.starts_with("stone") && DELAY - std::exchange(last, DELAY) < 16))
                continue;
            out += G < 1.F ? std::format(",{}@{}@{:.2f}", NAME, std::lround(DELAY), G) : std::format(",{}@{}", NAME, std::lround(DELAY));
        }
        announce(out);
    }

    bool rush(SScene& s) {
        const float T = ms(s), LEFT = (s.boom - T) / s.rate;
        if (s.released || T >= s.boom || LEFT <= RUSH)
            return false;
        wind(s, T, (s.boom - T) / RUSH, RUSH + s.end - s.boom);
        return true;
    }

    void strike(SScene& s, const PHLMONITOR& m) {
        const Vector2D C    = (s.j0 + s.j1) / 2;
        float          last = 0;
        for (const auto& w : Desktop::windowState()->windows()) {
            if (w->m_workspace != s.workspace.lock() || w == s.giver.lock() || w == s.born.lock() || !idle(w))
                continue;
            const CBox  BOX  = boxOf(w).translate(-m->m_position);
            const float AT   = reachOf(s, nearest(C, BOX));
            const auto  AWAY = BOX.middle() - C;
            s.struck.push_back({.window = w, .dir = AWAY / std::max(1.0, AWAY.size()), .at = s.boom + AT, .strength = std::exp(-AT / float(FADE))});
            last = std::max(last, reachOf(s, farthest(C, BOX) + 40));
        }
        const float T = ms(s);
        if (s.boom + last > s.end) {
            s.end = s.boom + last;
            wind(s, T, 1, s.end - T);
        }
    }

    bool moved(const SScene& s) {
        return std::ranges::any_of(std::array{s.giver.lock(), s.born.lock()}, [](const PHLWINDOW& w) { return w && w->sizeAnimation()->isBeingAnimated(); });
    }

    void layStones(SScene& s) {
        const double SPAN = (s.upright ? s.r.h : s.r.w) + 2 * s.came;
        const int    N    = std::max(3, int(std::lround(SPAN / PIECE_LEN)));
        s.len             = SPAN / N;
        float land        = 0;
        for (int j = 0; j < N; ++j) {
            const int      IDX  = s.upright ? N - 1 - j : (j % 2 == 0 ? j / 2 : N - 1 - (j - 1) / 2);
            const Vector2D SLOT = s.j0 + s.a * (s.len * (IDX + 0.5));
            const float    SEED = s.seed + j * 2.17F;
            const double   H    = noise(SEED, 0.7F);
            const int      WING = j % 2 == 0 ? -1 : 1;
            const double   UP   = std::min(ABOVE + 18 * H, std::max(14.0, SLOT.y - s.r.y + 10));
            const Vector2D FROM = s.upright ? SLOT + s.b * (WING * (ASIDE + 10 * H)) - Vector2D{0.0, UP} : SLOT + s.a * (WING * (ASIDE * 0.7 + 10 * H)) - Vector2D{0.0, UP};
            land                = j == 0 ? s.ignite + 40 : land + std::max(18.F, 46.F * std::pow(0.82F, float(j - 1)));
            s.stones.push_back({.slot = SLOT, .from = FROM, .spawn = land - DIVE - HANG - FORM, .drop = land - DIVE, .land = land, .seed = SEED, .tone = IDX % 2, .wing = WING});
        }
        s.boom = land + CHARGE;
        s.end  = s.boom + SETTLE;
    }

    void hurry(const PHLWINDOW& giver, const CBox& R) {
        bool rushed = false;
        for (auto& s : scenes)
            if (s->workspace.lock() == giver->m_workspace && (!s->r.intersection(R).empty() || moved(*s)))
                rushed = rush(*s) || rushed;
        if (rushed)
            Mullion::hush();
    }

    bool tiles(const PHLWINDOW& born, const PHLWINDOW& giver, int side, const CBox& R, const Vector2D& AT) {
        const CBox G       = giver->geometricBox(GEO::GEOMETRIC_GOAL).translate(shiftOf(giver) - AT);
        const CBox N       = born->geometricBox(GEO::GEOMETRIC_GOAL).translate(shiftOf(born) - AT);
        const auto NEAR    = [](double x, double y) { return std::abs(x - y) < 3; };
        const bool FITS    = side % 2 == 1 ? NEAR(G.y, R.y) && NEAR(N.y, R.y) && NEAR(G.h, R.h) && NEAR(N.h, R.h) && NEAR(std::min(G.x, N.x), R.x) && NEAR(std::max(G.x + G.w, N.x + N.w), R.x + R.w) :
                                             NEAR(G.x, R.x) && NEAR(N.x, R.x) && NEAR(G.w, R.w) && NEAR(N.w, R.w) && NEAR(std::min(G.y, N.y), R.y) && NEAR(std::max(G.y + G.h, N.y + N.h), R.y + R.h);
        return FITS && std::abs(edgeOf(N, (side + 2) % 4) - edgeOf(G, side)) <= 80;
    }

    SScene* raise(const PHLWINDOW& born, const PHLWINDOW& giver, int side, CGlassPass::SData&& ring, const SP<Render::IFramebuffer>& still, float lead, float pace) {
        const auto     MON     = giver->m_monitor.lock();
        const Vector2D AT      = MON->m_position;
        const CBox     G       = giver->geometricBox(GEO::GEOMETRIC_GOAL).translate(shiftOf(giver) - AT);
        const CBox     N       = born->geometricBox(GEO::GEOMETRIC_GOAL).translate(shiftOf(born) - AT);
        const bool     UPRIGHT = side % 2 == 1;
        const double   GE      = edgeOf(G, side), NE = edgeOf(N, (side + 2) % 4);

        auto s       = makeUnique<SScene>();
        s->born      = born;
        s->giver     = giver;
        s->monitor   = MON;
        s->workspace = giver->m_workspace;
        s->side      = side;
        s->upright   = UPRIGHT;
        s->melt      = melting;
        ring.lantern.reset();
        ring.call    = 0;
        s->r         = ring.window;
        s->n         = N;
        s->radius    = ring.radius;
        s->came      = ring.offset;
        s->a         = UPRIGHT ? Vector2D{0, 1} : Vector2D{1, 0};
        s->b         = side == 0 ? Vector2D{0, -1} : side == 1 ? Vector2D{1, 0} : side == 2 ? Vector2D{0, 1} : Vector2D{-1, 0};
        s->mid       = (GE + NE) / 2;
        s->gutter    = std::abs(NE - GE) / 2;
        s->reach     = UPRIGHT ? N.w : N.h;
        s->j0        = UPRIGHT ? Vector2D{s->mid, s->r.y - s->came} : Vector2D{s->r.x - s->came, s->mid};
        s->j1        = UPRIGHT ? Vector2D{s->mid, s->r.y + s->r.h + s->came} : Vector2D{s->r.x + s->r.w + s->came, s->mid};
        s->seed      = std::fmod(float(s->r.x * 0.37 + s->r.y * 0.11) + secondsAlive() * 3.1F, 17.F);
        s->pace      = pace;
        const SRing RING(s->r, s->radius);
        const double EFAR = side % 2 == 0 ? RING.ex : RING.ey;
        s->farN      = RING.mid(side);
        s->lost      = RING.circ(RING.u(s->j0), s->farN);
        s->straight  = std::max(0.0, s->lost - RING.arc - EFAR);
        s->cornerD   = EFAR + RING.arc / 2;
        s->lap0      = EXPAND1 + CLOSE;
        s->lapSpeed  = RING.per / 2 / SWEEP;
        s->ignite    = s->lap0 + float(s->lost / s->lapSpeed);
        s->plateLost = ring.plate.on && (ring.plate.pos + Vector2D{40, 11} - (s->j0 + s->j1) / 2).x * s->b.x + (ring.plate.pos + Vector2D{40, 11} - (s->j0 + s->j1) / 2).y * s->b.y > 0;
        if (!s->melt)
            layBricks(*s, RING);
        for (float t = 0; t < s->lap0 + 50; t += 2) {
            const auto [LO, HI] = cutAt(*s, t);
            const bool HIDDEN   = s->cornerD >= LO && s->cornerD <= HI;
            if (HIDDEN && s->wither > 1e8F)
                s->wither = t;
            if (!HIDDEN && s->wither < 1e8F && s->bloom > 1e8F)
                s->bloom = t;
        }
        layStones(*s);
        s->ring  = std::move(ring);
        s->still = still;

        giver->positionAnimation()->warp();
        giver->sizeAnimation()->warp();

        s->real = s->end;
        Animation::mgr()->createAnimation(0.F, s->clock, vitrailClock(s->end / s->pace), AVARDAMAGE_NONE);
        const CBox AREA = s->r.copy().translate(AT).expand(CGlassFrame::MARGIN + 90);
        s->clock->setUpdateCallback([AREA](auto) { g_pHyprRenderer->damageBox(AREA); });
        s->clock->setValueAndWarp(0.F);
        *s->clock = 1.F;
        if (lead > 0) {
            s->dawn = -lead;
            wind(*s, -lead, 1, s->end + lead);
        }
        g_pHyprRenderer->damageBox(AREA);
        cue(*s);
        return scenes.emplace_back(std::move(s)).get();
    }
}
