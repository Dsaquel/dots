#include "enfilade/Internal.hpp"

namespace Enfilade {
    float lengthOf(const SMove& m) {
        return m.pyre ? STRIDE : WALK;
    }

    float ms(const SMove& m) {
        return m.clock ? m.clock->value() * (lengthOf(m) + TAIL) : lengthOf(m) + TAIL;
    }

    SMove* moveOn(const PHLMONITOR& monitor) {
        const auto IT = std::ranges::find_if(moves, [&monitor](const UP<SMove>& m) { return m->monitor.lock() == monitor; });
        return IT == moves.end() ? nullptr : IT->get();
    }

    bool onScreens(const PHLMONITOR& monitor) {
        const std::string SPEC{g_glass->screens->value()};
        return std::ranges::any_of(std::views::split(SPEC, ','), [&monitor](const auto& part) {
            const std::string P{part.begin(), part.end()};
            return P.substr(0, P.find('=')) == monitor->m_name;
        });
    }

    std::vector<PHLWINDOW> windowsOf(const PHLMONITOR& monitor, const PHLWORKSPACE& ws) {
        const auto FOCUS = Desktop::focusState()->window();
        auto       all   = Desktop::windowState()->windows() | std::views::filter([&](const PHLWINDOW& w) {
                         return validMapped(w) && !w->isHidden() && !isPinned(w) && w->m_workspace == ws && w->m_monitor == monitor && !Translation::carries(w);
                     }) |
            std::ranges::to<std::vector>();
        std::ranges::stable_partition(all, [](const PHLWINDOW& w) { return !w->isFloating(); });
        const auto TILED = std::ranges::find_if(all, [](const PHLWINDOW& w) { return w->isFloating(); });
        if (const auto F = std::find(all.begin(), TILED, FOCUS); F != TILED)
            std::rotate(F, F + 1, TILED);
        return all;
    }

    std::vector<SP<Render::IFramebuffer>> shoot(const PHLMONITOR& monitor, const PHLWORKSPACE& ws, eShot kind) {
        std::vector<SP<Render::IFramebuffer>> shots;
        g_glass->shooting = kind;
        for (const auto& w : windowsOf(monitor, ws))
            if (const auto FB = g_pHyprRenderer->makeSnapshotFB(w))
                shots.push_back(FB);
        g_glass->shooting = eShot::NONE;
        return shots;
    }

    float seamOf(const PHLMONITOR& monitor, const PHLWORKSPACE& ws) {
        const CBox  AREA = monitor->logicalBoxMinusReserved().translate(-monitor->m_position);
        const double MID = AREA.middle().x;
        auto spans = windowsOf(monitor, ws) | std::views::transform([&monitor](const PHLWINDOW& w) {
                         const CBox B = w->getWindowMainSurfaceBox().translate(-monitor->m_position);
                         return std::pair{B.x, B.x + B.w};
                     }) |
            std::ranges::to<std::vector>();
        std::ranges::sort(spans);
        double best = MID, reach = AREA.x;
        bool   found = false;
        const auto TRY = [&](double a, double b) {
            const double C = (a + b) / 2;
            if (b - a >= 4 && C > AREA.x + AREA.w * 0.2 && C < AREA.x + AREA.w * 0.8 && (!found || std::abs(C - MID) < std::abs(best - MID))) {
                best  = C;
                found = true;
            }
        };
        for (const auto& [a, b] : spans) {
            TRY(reach, a);
            reach = std::max(reach, b);
        }
        return float(best * monitor->m_scale);
    }

    void release(SMove& m) {
        m.fromShots.clear();
        m.toShots.clear();
        m.farFB.reset();
        m.doorFB.reset();
        m.liveFB.reset();
        m.before.reset();
    }

    void unhold(SMove& m) {
        if (const auto FROM = m.from.lock(); FROM && m.held)
            FROM->m_forceRendering = m.forced;
        m.held = false;
    }

    void reveal(SMove& m) {
        if (const auto TO = m.to.lock(); TO) {
            TO->m_alpha->setValueAndWarp(1.F);
            TO->m_renderOffset->setValueAndWarp({});
        }
    }

    void hush(const PHLMONITOR& monitor) {
        if (std::ranges::any_of(Desktop::windowState()->windows(), [&monitor](const PHLWINDOW& w) {
                const auto* F = validMapped(w) && w->m_monitor == monitor ? CGlassFrame::of(w) : nullptr;
                return F && F->sounding();
            }))
            announce("hush,arrive");
    }

    void land(SMove& m) {
        m.landed = true;
        reveal(m);
        int i = 0;
        for (const auto& ref : m.arrivals)
            if (const auto W = ref.lock(); validMapped(W))
                if (auto* const F = CGlassFrame::of(W))
                    F->arrive(STAGGER * float(i++));
        release(m);
        if (const auto MON = m.monitor.lock())
            g_pHyprRenderer->damageMonitor(MON);
    }

    void start(SMove& m, const PHLMONITOR& MON) {
        const auto FROM = m.from.lock(), TO = m.to.lock();
        if (!TO)
            return;
        if (FROM) {
            if (!m.before)
                m.fromShots = shoot(MON, FROM, eShot::SKINNED);
            FROM->m_alpha->setValueAndWarp(0.F);
            FROM->m_renderOffset->setValueAndWarp({});
        }
        TO->m_alpha->setValueAndWarp(1.F);
        TO->m_renderOffset->setValueAndWarp({});
        if (auto before = Translation::before(TO); !before.empty())
            m.toShots = std::move(before);
        else {
            if (Translation::bound(TO))
                for (const auto& w : windowsOf(MON, TO)) {
                    w->positionAnimation()->warp();
                    w->sizeAnimation()->warp();
                }
            m.toShots = shoot(MON, TO, eShot::BARE);
        }
        TO->m_alpha->setValueAndWarp(0.F);
        m.seam = seamOf(MON, m.forward ? FROM : TO);
        if (m.seam <= 0)
            m.seam = float(MON->m_pixelSize.x / 2);

        const double S        = MON->m_scale;
        auto         arrivals = windowsOf(MON, TO) | std::views::filter([&m](const PHLWINDOW& w) { return !m.pyre && !Translation::reserves(w); }) | std::ranges::to<std::vector>();
        std::ranges::sort(arrivals, [&MON](const PHLWINDOW& a, const PHLWINDOW& b) {
            const auto MID = MON->logicalBoxMinusReserved().middle();
            return a->getWindowMainSurfaceBox().middle().distance(MID) < b->getWindowMainSurfaceBox().middle().distance(MID);
        });
        for (size_t i = 0; i < arrivals.size(); ++i) {
            m.arrivals.emplace_back(arrivals[i]);
            if (i >= size_t(SEATS))
                continue;
            const CBox   B    = arrivals[i]->getWindowMainSurfaceBox().translate(-MON->m_position);
            const double R    = arrivals[i]->presentation().rounding();
            const double IN   = R - (R + (B.w < 360 || B.h < 220 ? 7.5 : 9.5) - 0.5) * M_SQRT1_2;
            m.seats[i * 4 + 0] = float((B.x + IN) * S);
            m.seats[i * 4 + 1] = float((B.y + IN) * S);
            m.seats[i * 4 + 2] = float((B.x + B.w - IN) * S);
            m.seats[i * 4 + 3] = float((B.y + B.h - IN) * S);
        }

        Animation::mgr()->createAnimation(0.F, m.clock, vitrailClock((lengthOf(m) + TAIL) / (m.pyre ? Translation::HASTE : 1.F)), AVARDAMAGE_NONE);
        const PHLMONITORREF REF = MON;
        m.clock->setUpdateCallback([REF](auto) {
            if (const auto M = REF.lock())
                g_pHyprRenderer->damageMonitor(M);
        });
        m.clock->setValueAndWarp(0.F);
        *m.clock = 1.F;
        g_pHyprRenderer->damageMonitor(MON);
    }
}
