#include "translation/Internal.hpp"

namespace Translation {
    void hurry(const PHLWINDOW& w, const PHLMONITOR& src, const PHLMONITOR& dst) {
        std::vector<UP<SPyre>> landing;
        for (auto& p : pyres)
            if (const auto AIM = p->aim.lock(); p->window.lock() != w && p->seated >= SHUT &&
                (touches(*p, src) || touches(*p, dst) || (AIM && (AIM->m_monitor == src || AIM->m_monitor == dst))))
                landing.push_back(std::move(p));
        if (landing.empty())
            return;
        std::erase(pyres, nullptr);
        Mullion::hush();
        for (auto& p : landing)
            land(*p, w);
    }

    bool aim(SPyre& p, const PHLWINDOW& w, const PHLWORKSPACE& to) {
        const auto LAND = to->m_monitor.lock(), AT = p.monitor.lock(), SRC = p.from.lock();
        const auto FROM = p.source.lock(), TARGET = p.target.lock();
        if (to == TARGET) {
            p.aim.reset();
            p.aimed.clear();
            return true;
        }
        if (to == p.aim.lock())
            return true;
        if (!LAND || !AT || !SRC || !g_glass->enfilade->value() || Fullscreen::controller()->hasFullscreen(to) || !room(w, to) ||
            (LAND != AT && (LAND->m_scale != AT->m_scale || !seamOf(AT, LAND))))
            return false;
        const bool FORCED = to->m_forceRendering;
        if (!to->visible())
            to->m_renderOffset->setValueAndWarp({});
        to->m_forceRendering = true;
        auto BEFORE          = capture(w, to, LAND);
        to->m_forceRendering = FORCED;
        const bool WALKS     = !to->visible();
        if (!p.armed) {
            p.monitor = LAND;
            p.target  = to;
            p.before  = std::move(BEFORE);
            p.walks   = SRC == LAND || WALKS;
            p.origin  = (SRC == LAND || !LAND->m_activeWorkspace) && FROM ? idOf(FROM) : LAND->m_activeWorkspace ? idOf(LAND->m_activeWorkspace) : p.origin;
            p.forward = !p.walks || idOf(to) > p.origin;
            p.alone   = p.before.empty();
            p.fired   = awayOf(p);
        } else {
            p.spurred   = std::min(p.spurred, ms(p));
            p.aim       = to;
            p.aimed     = std::move(BEFORE);
            p.aimWalks  = WALKS;
            p.aimOrigin = LAND != AT ? (LAND->m_activeWorkspace ? idOf(LAND->m_activeWorkspace) : idOf(to)) : (p.walks && p.doors >= SHUT) || !TARGET ? p.origin : idOf(TARGET);
        }
        if (SRC != LAND || !WALKS)
            cloak(p, w);
        return true;
    }

    void adopt(SPyre& p, const PHLMONITOR& mon) {
        const auto AIM = p.aim.lock();
        p.target       = AIM;
        p.before       = std::move(p.aimed);
        p.walks        = p.aimWalks;
        p.origin       = p.aimOrigin;
        p.forward      = !p.walks || idOf(AIM) > p.origin;
        p.alone        = p.before.empty();
        p.side         = -1;
        p.aim.reset();
        p.giver.reset();
        if (!kindled(p, mon)) {
            p.alone = true;
            kindled(p, mon);
        }
    }

    struct SBend {
        std::array<std::array<float, 3>, WAKE> wake = {};
        Vector2D                               heading;
        float                                  lag = LAG, start = 0;
    };

    SBend bend(const SPyre& p, float t) {
        const auto  P      = pathOf(p, t);
        const float LAGGED = float(lagOf(P, t)), START = std::min(std::max(BORN, t - LAGGED), t - 1.F);
        const auto  SEEN   = [&P](double tau) { return project(P, spineAt(P, tau), P.view[0]); };
        SBend       out{.lag = LAGGED, .start = START};
        for (int i = 0; i < WAKE; ++i) {
            const auto D = SEEN(START + (t - START) * i / double(WAKE - 1));
            out.wake[i]  = {float(D.at.x), float(D.at.y), float(P.lens[2] / D.z)};
        }
        out.heading = (SEEN(t).at - SEEN(t - 4).at) / 4.0;
        return out;
    }

    void renew(SPyre& p, float t) {
        p.base = t;
        p.clock->setValueAndWarp(0.F);
        *p.clock = 1.F;
    }

    void turn(SPyre& p, float t, SBend&& b) {
        const auto AIM  = p.aim.lock();
        const auto LAND = AIM->m_monitor.lock(), AT = p.monitor.lock();
        if (p.walks && p.doors >= SHUT && AT != LAND)
            p.held = p.target;
        if (const auto G = p.giver.lock(); G && (!p.walks || p.flies)) {
            G->positionAnimation()->warp();
            G->sizeAnimation()->warp();
        }
        const Vector2D SHIFT = AT->m_position - LAND->m_position;
        for (auto& q : b.wake) {
            q[0] = float((q[0] / AT->m_scale + SHIFT.x) * LAND->m_scale);
            q[1] = float((q[1] / AT->m_scale + SHIFT.y) * LAND->m_scale);
        }
        p.wake    = b.wake;
        p.heading = b.heading * (LAND->m_scale / AT->m_scale);
        p.lagged  = b.lag;
        p.waked   = b.start;
        p.turned  = t;
        p.past    = AT;
        p.monitor = LAND;
        p.seated  = SHUT;
        adopt(p, LAND);
        p.doors = t - (p.walks ? std::max(Enfilade::walk(LAND, AIM), 0.F) : 0.F);
        p.flies = p.walks && Enfilade::flies(LAND);
        track(p);
        if (p.flies)
            cloak(p, p.window.lock());
        if (const auto G = p.giver.lock(); G && (!p.walks || p.flies))
            Life::follow(G, HALT);
        if (p.base + PYRE < t + PYRE / 2)
            renew(p, t);
        rewire(p);
    }

    bool steer(SPyre& p, const PHLWINDOW& w, float t, std::vector<std::string>& lit) {
        const auto AIM  = p.aim.lock();
        const auto AT   = p.monitor.lock();
        const auto LAND = AIM ? AIM->m_monitor.lock() : nullptr;
        if (!LAND || !AT || !p.from.lock() || !AIM->visible())
            return false;
        if (LAND == AT && p.walks && p.doors >= SHUT) {
            if (!Enfilade::holding(LAND) && Enfilade::walk(LAND, AIM) < 0)
                return false;
            if (const auto G = p.giver.lock(); G && p.flies) {
                G->positionAnimation()->warp();
                G->sizeAnimation()->warp();
            }
            adopt(p, LAND);
            track(p);
            if (const auto G = p.giver.lock(); G && p.flies)
                Life::follow(G, HALT);
            lit.push_back(cuesOf(p, w, t, false));
            return true;
        }
        if (!ready(p, t))
            return true;
        auto BENT = bend(p, t);
        if (p.aimWalks) {
            Enfilade::lead(LAND);
            if (Enfilade::walk(LAND, AIM) < 0)
                return true;
        }
        turn(p, t, std::move(BENT));
        lit.push_back(cuesOf(p, w, t, false));
        return true;
    }

    bool tend(SPyre& p, const PHLMONITOR& monitor, std::vector<SFell>& fell, std::vector<std::string>& lit, bool& hushed) {
        if (p.monitor.lock() != monitor && (p.armed || p.from.lock() != monitor))
            return false;
        const auto W    = p.window.lock();
        const auto TO   = p.target.lock();
        const auto LAND = p.monitor.lock();
        const auto AIM  = p.aim.lock();
        if (!validMapped(W) || !(AIM ? AIM : TO) || W->m_workspace != (AIM ? AIM : TO) || !LAND) {
            hushed = hushed || (p.armed && p.seated >= SHUT);
            return true;
        }
        const float T = ms(p);
        if (!p.armed) {
            if ((p.walks ? !Enfilade::holding(LAND) : W != Desktop::focusState()->window()) || !kindled(p, LAND)) {
                fell.push_back({W, p.from.lock(), p.snapshot, p.box});
                return true;
            }
            p.armed = true;
            p.flies = p.walks && Enfilade::flies(LAND);
            track(p);
            if (!p.walks)
                p.doors = HOLD;
            if (p.flies)
                cloak(p, W);
            if (const auto G = p.giver.lock(); G && (!p.walks || p.flies))
                Life::follow(G, HALT);
            p.draft = p.from.lock() == LAND ? HOLD : timesOf(p, HOLD)[0] + RISEN;
            stretch(p);
            lit.push_back(cuesOf(p, W, 0, true));
        }
        if (AIM && !steer(p, W, T, lit)) {
            hushed = true;
            return true;
        }
        if (p.aim.lock())
            return !p.clock->isBeingAnimated();
        const auto GOAL = p.target.lock();
        const auto HOST = p.monitor.lock();
        if (!GOAL->visible()) {
            hushed = hushed || p.seated >= SHUT;
            return true;
        }
        const float WALKED = Enfilade::walk(HOST, GOAL);
        if (p.doors >= SHUT && WALKED >= 0)
            p.doors = T - WALKED;
        if (p.seated >= SHUT && p.doors < SHUT && (p.walks ? WALKED >= p.stride || WALKED < 0 : T >= timesOf(p, T)[2]))
            seat(p, T);
        if (p.doors < SHUT && p.base + PYRE < std::min(timesOf(p, T)[3], T + PYRE / 2))
            renew(p, T);
        if (p.doors < SHUT)
            jolt(p, T);
        return !p.clock->isBeingAnimated() || (p.seated < SHUT && T >= timesOf(p, T)[3] && (!p.ghost || p.ghost->done()));
    }
}
