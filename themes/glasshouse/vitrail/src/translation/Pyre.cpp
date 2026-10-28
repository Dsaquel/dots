#include "translation/Internal.hpp"

namespace Translation {
    bool bare(const PHLWINDOW& w, const PHLWORKSPACE& to) {
        return std::ranges::none_of(Desktop::windowState()->windows(), [&w, &to](const PHLWINDOW& x) {
            return x != w && validMapped(x) && !x->isHidden() && !isPinned(x) && x->m_workspace == to;
        });
    }

    bool room(const PHLWINDOW& w, const PHLWORKSPACE& to) {
        return bare(w, to) || (!w->isFloating() && std::ranges::any_of(Desktop::windowState()->windows(), [&w, &to](const PHLWINDOW& x) {
                   return x != w && validMapped(x) && !x->isHidden() && !x->isFloating() && x->m_workspace == to;
               }));
    }

    bool kindles(const PHLWINDOW& w, const PHLWORKSPACE& from, const PHLWORKSPACE& to, const PHLMONITOR& src, const PHLMONITOR& land) {
        return g_glass->enfilade->value() && from && from != to && from->visible() && !isSpecial(from) && from->m_monitor == src && to->m_monitor == land &&
            (src == land || (src->m_scale == land->m_scale && seamOf(src, land))) && !Fullscreen::controller()->hasFullscreen(to) && room(w, to);
    }

    std::vector<SBefore> capture(const PHLWINDOW& w, const PHLWORKSPACE& to, const PHLMONITOR& mon) {
        auto windows = Desktop::windowState()->windows() | std::views::filter([&w, &to, &mon](const PHLWINDOW& x) {
                           return x != w && validMapped(x) && !x->isHidden() && !isPinned(x) && x->m_workspace == to && x->m_monitor == mon;
                       }) |
            std::ranges::to<std::vector>();
        std::ranges::stable_partition(windows, [](const PHLWINDOW& x) { return !x->isFloating(); });
        std::vector<SBefore> out;
        const float          ALPHA = to->m_alpha->value();
        to->m_alpha->setValueAndWarp(1.F);
        g_glass->shooting = eShot::BARE;
        for (const auto& x : windows)
            if (const auto SHOT = g_pHyprRenderer->makeSnapshotFB(x); SHOT && SHOT->getTexture())
                out.push_back({.window = x, .box = boxOf(x), .shot = SHOT});
        g_glass->shooting = eShot::NONE;
        to->m_alpha->setValueAndWarp(ALPHA);
        for (auto& b : out)
            if (auto* const F = CGlassFrame::of(b.window.lock()))
                b.ring = F->build(mon, 1.F);
        return out;
    }

    void kindle(const PHLWINDOW& w, const PHLMONITOR& src, const PHLMONITOR& land, const PHLWORKSPACE& from, const PHLWORKSPACE& to, const SP<Render::IFramebuffer>& snap,
                std::vector<SBefore>&& before) {
        auto p      = makeUnique<SPyre>();
        p->window   = w;
        p->monitor  = land;
        p->from     = src;
        p->source   = from;
        p->target   = to;
        p->walks    = src == land || !to->visible();
        p->origin   = src == land || !land->m_activeWorkspace ? idOf(from) : idOf(land->m_activeWorkspace);
        p->forward  = !p->walks || idOf(to) > p->origin;
        p->fired    = awayOf(*p);
        p->box      = boxOf(w);
        p->shot     = p->box.copy().translate(-src->m_position).scale(src->m_scale).round();
        p->snapshot = snap;
        p->before   = std::move(before);
        p->alone    = p->before.empty();
        p->seed     = std::fmod(secondsAlive() * 7.31F, 61.F);
        p->ghost    = CGhost::create(w, snap);
        if (p->ghost) {
            p->ghost->decide(nullptr, -1, CGhost::BURN);
            p->ghost->hasten(HASTE);
        }
        if (src != land)
            cloak(*p, w);
        Animation::mgr()->createAnimation(0.F, p->clock, vitrailClock(PYRE / HASTE), AVARDAMAGE_NONE);
        rewire(*p);
        p->clock->setValueAndWarp(0.F);
        *p->clock = 1.F;
        pyres.emplace_back(std::move(p));
    }

    std::array<float, 4> cutOf(const PHLWINDOW& giver, const CBox& born, int side, const CBox& slot, const PHLMONITOR& mon) {
        const auto EDGE = [](const CBox& b, int s) { return s == 0 ? b.y : s == 1 ? b.x + b.w : s == 2 ? b.y + b.h : b.x; };
        const CBox G    = giver->geometricBox(GEO::GEOMETRIC_GOAL).translate(-mon->m_position).scale(mon->m_scale);
        const CBox N    = born.copy().translate(-mon->m_position).scale(mon->m_scale);
        const bool UP   = side % 2 == 1;
        return {UP ? 1.F : 0.F, float((EDGE(G, side) + EDGE(N, (side + 2) % 4)) / 2), float(UP ? slot.y : slot.x), float(UP ? slot.y + slot.h : slot.x + slot.w)};
    }

    std::vector<std::array<float, 5>> leadsOf(const std::vector<SBefore>& before, const PHLMONITOR& mon) {
        return before | std::views::filter([](const SBefore& b) { return validMapped(b.window.lock()); }) | std::views::take(LEADS) | std::views::transform([&mon](const SBefore& b) {
                   const CBox B = b.box.copy().translate(-mon->m_position).scale(mon->m_scale);
                   return std::array{float(B.x), float(B.y), float(B.w), float(B.h), float(b.window.lock()->presentation().rounding() * mon->m_scale)};
               }) |
            std::ranges::to<std::vector>();
    }

    bool kindled(SPyre& p, const PHLMONITOR& mon) {
        const auto W = p.window.lock();
        const CBox N = W->geometricBox(GEO::GEOMETRIC_GOAL);
        p.leads      = leadsOf(p.before, mon);
        p.cut        = {};
        if (p.alone) {
            p.slot   = N.copy().translate(-mon->m_position).scale(mon->m_scale).round();
            p.entry  = p.slot.middle();
            p.radius = float(W->presentation().rounding());
            return true;
        }
        for (const auto& b : p.before) {
            const auto X = b.window.lock();
            if (!validMapped(X) || X->isFloating() || X->m_workspace != W->m_workspace || !b.ring)
                continue;
            const int SIDE = facing(X->geometricBox(GEO::GEOMETRIC_GOAL), N);
            if (SIDE < 0 || !Mullion::fits(W, X, SIDE, b.box))
                continue;
            p.giver  = X;
            p.side   = SIDE;
            p.slot   = b.box.copy().translate(-mon->m_position).scale(mon->m_scale).round();
            p.entry  = p.slot.middle();
            p.radius = float(X->presentation().rounding());
            p.cut    = cutOf(X, N, SIDE, p.slot, mon);
            return true;
        }
        return false;
    }

    void stretch(const SPyre& p) {
        const auto W    = p.window.lock();
        const auto FROM = p.source.lock();
        for (const auto& x : Desktop::windowState()->windows())
            if (x != W && validMapped(x) && !x->isFloating() && x->m_workspace == FROM && (x->sizeAnimation()->isBeingAnimated() || x->positionAnimation()->isBeingAnimated()) &&
                !p.box.copy().expand(8).intersection(x->geometricBox(GEO::GEOMETRIC_GOAL)).empty())
                Life::follow(x, STRETCH / HASTE);
    }

    std::string cuesOf(const SPyre& p, const PHLWINDOW& w, float now, bool rooted) {
        const auto                                         TIMES = timesOf(p, std::max(now, HOLD));
        std::vector<std::tuple<float, std::string, float>> list;
        if (rooted)
            list = {{0.F, "blaze", 1.F}, {EMBERS, "embers", 0.8F}, {p.draft, "draft", 0.9F}};
        if (!p.aim.lock()) {
            list.emplace_back(TIMES[1], "pour", 0.9F);
            list.emplace_back(TIMES[1], "strike", 1.F);
            if (p.alone)
                list.emplace_back(TIMES[2], "athanor", 1.F);
        }
        const auto CUES = list | std::views::filter([now](const auto& c) { return std::get<0>(c) >= now; }) | std::views::transform([now](const auto& c) {
                              const auto& [AT, NAME, GAIN] = c;
                              return GAIN < 1.F ? std::format(",{}@{:.0f}@{}", NAME, (AT - now) / HASTE, GAIN) : std::format(",{}@{:.0f}", NAME, (AT - now) / HASTE);
                          }) |
            std::views::join | std::ranges::to<std::string>();
        return CUES.empty() ? CUES : std::format("pyre,{}{}", addressOf(w), CUES);
    }

    void seat(SPyre& p, float t) {
        p.seated      = t;
        const auto W  = p.window.lock(), G = p.giver.lock();
        strip(W, p.shroud);
        if (p.alone) {
            W->positionAnimation()->warp();
            W->sizeAnimation()->warp();
            Life::open(W, nullptr);
            Life::late(W);
            if (auto* const F = CGlassFrame::of(W))
                F->hasten(HASTE);
            if (W == Desktop::focusState()->window())
                CGlassFrame::handoff(nullptr, W, std::nullopt);
            return;
        }
        const auto IT     = std::ranges::find_if(p.before, [&G](const SBefore& b) { return b.window.lock() == G; });
        const auto JOLTED = p.jolt != Vector2D{} ? p.jolted.lock() : nullptr;
        if (JOLTED)
            JOLTED->m_renderOffset->setValueAndWarp({});
        const bool HELD = validMapped(G) && IT != p.before.end() && Mullion::seat(W, G, p.side, IT->box, IT->ring, IT->shot, LEAD, HASTE);
        if (JOLTED)
            JOLTED->m_renderOffset->setValueAndWarp(p.jolt);
        if (!HELD) {
            for (const auto& x : {W, G})
                if (x && (x == W || !p.walks || p.flies)) {
                    x->positionAnimation()->warp();
                    x->sizeAnimation()->warp();
                }
        }
        p.before.clear();
    }

    Vector2D kickOf(const SPyre& p, float t) {
        const auto  LAND = p.monitor.lock();
        const float X    = t - timesOf(p, t)[1];
        if (!LAND || X <= 0 || X >= JOLTED)
            return {};
        return p.recoil * (KICK * LAND->m_size.y * std::exp(-X / 50.F) * std::sin(float(M_PI) * X / 60.F));
    }

    void jolt(SPyre& p, float t) {
        const auto LAND = p.monitor.lock();
        if (p.recoil == Vector2D{} && t >= timesOf(p, t)[1]) {
            const auto     P = pathOf(p, t);
            const Vector2D A = project(P, spineAt(P, P.times[1] - 1), P.view[0]).at, B = project(P, spineAt(P, P.times[1] - 12), P.view[0]).at;
            p.recoil         = (A - B).size() > 0.5 ? unitOf(A - B) : unitOf(p.entry - cameOf(p));
            p.jolted         = p.target;
        }
        const auto WS = p.jolted.lock();
        if (!WS || WS->m_renderOffset->isBeingAnimated()) {
            p.jolt = {};
            return;
        }
        const Vector2D K = LAND && LAND->m_activeWorkspace == WS && (p.flies || !Enfilade::view(LAND)) ? kickOf(p, t) : Vector2D{};
        if (K == p.jolt && WS->m_renderOffset->value() == K)
            return;
        WS->m_renderOffset->setValueAndWarp(K);
        p.jolt = K;
    }

    float gathered(const SPyre& p) {
        return std::min(GATHERED, std::max(p.spurred, RELEASED) + JOINED);
    }

    bool ready(const SPyre& p, float t) {
        const auto SRC = p.from.lock();
        return t >= gathered(p) || !SRC || !Enfilade::view(SRC);
    }

    void land(SPyre& p, const PHLWINDOW& leaving) {
        const auto W    = p.window.lock();
        const auto TO   = p.target.lock();
        const auto LAND = p.monitor.lock();
        if (p.ghost)
            p.ghost->finish();
        if (!p.armed || p.aim.lock() || !validMapped(W) || !TO || !LAND || W->m_workspace != TO)
            return;
        if (p.walks)
            Enfilade::finish(LAND);
        if (!TO->visible())
            return;
        if (p.giver.lock() == leaving) {
            p.alone = true;
            p.giver.reset();
            kindled(p, LAND);
        }
        seat(p, ms(p));
        if (p.alone)
            announce(std::format("pyre,{},athanor@0", addressOf(W)));
    }
}
