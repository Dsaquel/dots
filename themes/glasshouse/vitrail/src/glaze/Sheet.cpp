#include "glaze/Internal.hpp"

namespace Glaze {
    using SCue = std::pair<float, std::string>;

    void rest(const PHLWORKSPACE& ws, const Vector2D& applied) {
        if (ws && applied != Vector2D{} && !ws->m_renderOffset->isBeingAnimated())
            ws->m_renderOffset->setValueAndWarp({});
    }

    float lengthOf(bool shows) {
        return shows ? TAIL : HIDDEN;
    }

    float ms(const SSheet& s) {
        const float K = s.clock ? s.clock->value() : 1.F;
        return s.back ? s.from * (1.F - K) : s.from + (lengthOf(s.shows) - s.from) * K;
    }

    bool heading(const SSheet& s) {
        return s.shows != s.back;
    }

    float beatOf(int c, int n, float first, float span, float ratio) {
        return first + span * (1.F - std::pow(ratio, float(c) / float(std::max(n - 1, 1)))) / (1.F - ratio);
    }

    float landOf(int c, int n) {
        return beatOf(c, n, FIRST, SPAN, RATIO);
    }

    float leaveOf(int c, int n) {
        return beatOf(c, n, LIFT, LIFTED, RISEN);
    }

    float veilOf(bool shows, float t) {
        return shows ? smooth((t - VEIL) / (VEILED - VEIL)) : 1.F - smooth((t - UNVEIL) / (UNVEILED - UNVEIL));
    }

    float veiled(const SSheet& s, float t) {
        const float F = veilOf(s.shows, t);
        if (s.shows)
            return s.f0 >= 1.F ? 1.F : 1.F - (1.F - s.v0) * (1.F - F) / (1.F - s.f0);
        return s.f0 <= 0.F ? 0.F : s.v0 * F / s.f0;
    }

    Vector2D kickOf(float x) {
        return x <= 0 || x >= JOLTED ? Vector2D{} : Vector2D{0.0, JOLT * std::exp(-x / SWAY) * std::sin(float(M_PI) * x / PERIOD)};
    }

    CBox reachOf(const CBox& a) {
        return {a.x - REACH, a.y - REACH, a.w + 2 * REACH, a.h + 2 * REACH + SPILL};
    }

    SSheet* sheetOf(const PHLWORKSPACE& ws) {
        const auto IT = std::ranges::find_if(sheets, [&ws](const UP<SSheet>& s) { return s->workspace.lock() == ws; });
        return IT == sheets.end() ? nullptr : IT->get();
    }

    std::vector<PHLWINDOW> windowsOf(const PHLWORKSPACE& ws, const PHLMONITOR& monitor) {
        auto all = Desktop::windowState()->windows() | std::views::filter([&](const PHLWINDOW& w) {
                       return validMapped(w) && !w->isHidden() && !isPinned(w) && w->m_workspace == ws && w->m_monitor == monitor;
                   }) |
            std::ranges::to<std::vector>();
        std::ranges::stable_partition(all, [](const PHLWINDOW& w) { return !w->isFloating(); });
        if (all.size() > PANES)
            all.erase(all.begin(), all.end() - PANES);
        return all;
    }

    std::vector<SPane> shoot(const PHLWORKSPACE& ws, const PHLMONITOR& monitor) {
        const auto WINDOWS = windowsOf(ws, monitor);
        std::ranges::for_each(WINDOWS, [](const PHLWINDOW& w) {
            w->positionAnimation()->warp();
            w->sizeAnimation()->warp();
        });
        const bool FORCED    = ws->m_forceRendering;
        ws->m_forceRendering = true;
        ws->m_alpha->setValueAndWarp(1.F);
        ws->m_renderOffset->setValueAndWarp({});
        g_glass->shooting = eShot::SKINNED;
        const double S     = monitor->m_scale;
        auto         panes = WINDOWS | std::views::transform([&monitor, S](const PHLWINDOW& w) {
                         const CBox AREA = boxOf(w);
                         return SPane{.window = w,
                                      .shot   = g_pHyprRenderer->makeSnapshotFB(w),
                                      .box    = AREA.copy().translate(-monitor->m_position).scale(S),
                                      .area   = AREA,
                                      .grid   = latticeOf(AREA, std::clamp(AREA.h / COURSES, LOW, CELL_H)),
                                      .radius = float(w->presentation().rounding() * S)};
                     }) |
            std::ranges::to<std::vector>();
        std::erase_if(panes, [](const SPane& p) { return !p.shot || !p.shot->getTexture(); });
        g_glass->shooting    = eShot::NONE;
        ws->m_forceRendering = FORCED;
        ws->m_alpha->setValueAndWarp(0.F);
        return panes;
    }

    void damage(const SSheet& s) {
        std::ranges::for_each(s.panes, [](const SPane& p) { g_pHyprRenderer->damageBox(reachOf(p.area)); });
        if (const auto MON = s.monitor.lock(); MON && s.echo != Vector2D{})
            g_pHyprRenderer->damageMonitor(MON);
    }

    void dim(const PHLMONITOR& m) {
        auto MINE = sheets | std::views::filter([&m](const UP<SSheet>& s) { return s->monitor.lock() == m; });
        if (std::ranges::empty(MINE))
            return;
        const float DIM  = std::ranges::max(MINE | std::views::transform([](const UP<SSheet>& s) { return s->level * s->veil; }));
        const float HAZE = std::ranges::max(MINE | std::views::transform([](const UP<SSheet>& s) { return s->haze * s->veil; }));
        if (m->m_specialDim->value() != DIM || m->m_specialDim->isBeingAnimated())
            m->m_specialDim->setValueAndWarp(DIM);
        if (m->m_specialBlur->value() != HAZE || m->m_specialBlur->isBeingAnimated())
            m->m_specialBlur->setValueAndWarp(HAZE);
    }

    void settle(SSheet& s) {
        const auto WS    = s.workspace.lock();
        const auto MON   = s.monitor.lock();
        const bool SHOWN = WS && WS->visible();
        if (SHOWN)
            WS->m_alpha->setValueAndWarp(1.F);
        if (MON) {
            MON->m_specialDim->setValueAndWarp(SHOWN ? s.level : 0.F);
            MON->m_specialBlur->setValueAndWarp(SHOWN ? s.haze : 0.F);
        }
    }

    void apply(const PHLWORKSPACE& ws, const Vector2D& k, Vector2D& applied) {
        if (!ws || ws->m_renderOffset->isBeingAnimated()) {
            applied = {};
            return;
        }
        if (k == applied && ws->m_renderOffset->value() == k)
            return;
        ws->m_renderOffset->setValueAndWarp(k);
        applied = k;
    }

    void jolt(SSheet& s, float t, const PHLMONITOR& m) {
        const bool FREE   = s.live && !Passage::flies(m) && !Enfilade::view(m) && Translation::kick(m) == Vector2D{};
        const auto ACTIVE = s.jolted.lock();
        apply(s.workspace.lock(), FREE ? kickOf(t - SLAM) : Vector2D{}, s.jolt);
        apply(ACTIVE, FREE && ACTIVE == m->m_activeWorkspace ? kickOf(t - SLAM - LAG) * ECHO : Vector2D{}, s.echo);
    }

    std::vector<SCue> ladder(const std::vector<float>& beats, const char* stem, float gap) {
        std::vector<float> kept;
        for (const float B : beats)
            if (kept.empty() || B - kept.back() >= gap - 0.5F)
                kept.push_back(B);
        const int M = int(kept.size());
        return std::views::iota(0, M) | std::views::transform([&kept, stem, M](int k) { return SCue{kept[size_t(k)], std::format("{}{}", stem, 8 - (M - 1 - k) * 8 / M)}; }) |
            std::ranges::to<std::vector>();
    }

    std::vector<SCue> cuesOf(const SSheet& s, int n) {
        const bool        HIDES = s.shows == s.back;
        const float       F     = s.from;
        const auto        TIMES = std::views::iota(0, n) | std::views::transform([n, &s](int c) { return s.shows ? landOf(c, n) : leaveOf(c, n); });
        std::vector<float> beats = s.back ? TIMES | std::views::reverse | std::views::transform([F](float x) { return F - x; }) | std::ranges::to<std::vector>() :
                                            TIMES | std::views::take(s.shows ? n - 1 : n) | std::views::transform([F](float x) { return x - F; }) | std::ranges::to<std::vector>();
        std::erase_if(beats, [HIDES](float b) { return b < (HIDES ? LIFTBEAT - 0.5F : 0.F); });
        std::vector<SCue> list = ladder(beats, HIDES ? "glaze-lift-" : "glaze-", HIDES ? LIFTBEAT : BEAT);
        if (HIDES)
            list.insert(list.begin(), SCue{0.F, "glaze-crack"});
        const float AT = s.back ? F : SLAM - F;
        if (!HIDES && AT >= 0)
            list.insert(list.end(), {SCue{AT, "glaze-slam"}, SCue{AT, "glaze-run"}, SCue{AT + WELD, "glaze-weld"}, SCue{AT + GILD, "glaze-gild"}});
        std::ranges::stable_sort(list, {}, &SCue::first);
        return list;
    }

    void cue(const SSheet& s) {
        const auto WS = s.workspace.lock();
        if (!WS || s.panes.empty())
            return;
        const auto& BIG = std::ranges::max(s.panes, {}, [](const SPane& p) { return p.box.w * p.box.h; });
        announce(std::ranges::fold_left(cuesOf(s, int(BIG.grid.y)), std::format("glaze,{}", WS->displayName()),
                                        [](std::string out, const SCue& c) { return out + std::format(",{}@{}", c.second, std::lround(c.first)); }));
    }

    void play(SSheet& s, bool shows, float from, bool back, bool heard) {
        if (heard && s.clock)
            announce("hush,glaze");
        if (!s.clock || s.shows != shows) {
            s.v0 = s.veil;
            s.f0 = veilOf(shows, from);
        }
        s.shows        = shows;
        s.back         = back;
        s.from         = from;
        const float MS = std::max(back ? from : lengthOf(shows) - from, 16.F);
        if (!s.clock) {
            Animation::mgr()->createAnimation(0.F, s.clock, vitrailClock(MS), AVARDAMAGE_NONE);
            s.clock->setUpdateCallback([S = &s](auto) { damage(*S); });
        } else
            s.clock->setConfig(vitrailClock(MS));
        s.clock->setValueAndWarp(0.F);
        *s.clock = 1.F;
        if (heard)
            cue(s);
        damage(s);
    }

    void handBack(SSheet& s) {
        const auto WS  = s.workspace.lock();
        const auto MON = s.monitor.lock();
        s.live         = true;
        if (WS)
            WS->m_alpha->setValueAndWarp(1.F);
        if (MON)
            s.jolted = MON->m_activeWorkspace;
    }

    void wind(SSheet& s, const PHLMONITOR& monitor, bool shows) {
        if (heading(s) == shows)
            return;
        const float T  = ms(s);
        const auto  WS = s.workspace.lock();
        if (s.shows == shows)
            play(s, shows, T, false, true);
        else if (s.shows ? T < SLAM : T > LIFT)
            play(s, s.shows, T, true, true);
        else if (shows) {
            play(s, true, SLAM, false, true);
            handBack(s);
        } else {
            if (auto panes = shoot(WS, monitor); !panes.empty())
                s.panes = std::move(panes);
            s.live = false;
            play(s, false, 0.F, false, true);
        }
        WS->m_alpha->setValueAndWarp(s.live ? 1.F : 0.F);
        WS->m_renderOffset->setValueAndWarp({});
        s.jolt = {};
    }

    void fly(const PHLWORKSPACE& ws, const PHLMONITOR& monitor, bool shows) {
        std::erase_if(sheets, [&ws, &monitor](const UP<SSheet>& s) {
            const bool AWAY = s->workspace.lock() == ws && s->monitor.lock() != monitor;
            if (AWAY)
                settle(*s);
            return AWAY;
        });
        if (auto* const S = sheetOf(ws)) {
            wind(*S, monitor, shows);
            dim(monitor);
            return;
        }
        if (Fullscreen::controller()->hasFullscreen(ws))
            return;
        auto panes = shoot(ws, monitor);
        if (panes.empty()) {
            if (shows)
                ws->m_alpha->setValueAndWarp(1.F);
            return;
        }
        auto& s     = *sheets.emplace_back(makeUnique<SSheet>());
        s.monitor   = monitor;
        s.workspace = ws;
        s.panes     = std::move(panes);
        s.seed      = std::fmod(secondsAlive() * 7.31F, 1.F);
        s.level     = shows ? monitor->m_specialDim->goal() : monitor->m_specialDim->value();
        s.haze      = shows ? monitor->m_specialBlur->goal() : monitor->m_specialBlur->value();
        s.veil      = s.level > 0 ? std::clamp(monitor->m_specialDim->value() / s.level, 0.F, 1.F) : shows ? 0.F : 1.F;
        play(s, shows, 0.F, false, true);
        dim(monitor);
    }
}
