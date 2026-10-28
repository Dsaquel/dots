#include "passage/Internal.hpp"
#include "core/Ease.hpp"

namespace Passage {
    void advance(SFlight& f, const PHLMONITOR& monitor) {
        const auto NOW = std::chrono::steady_clock::now();
        if (!f.begin) {
            f.begin  = f.tick = NOW;
            f.frames = 0;
        }
        const float PERIOD = 1000.F / std::max(monitor->m_refreshRate, 30.F);
        const float DT     = std::min(std::chrono::duration<float, std::milli>(NOW - f.tick).count(), f.frames < 3 ? PERIOD : 50.F);
        f.tick             = NOW;
        f.dt               = DT;
        f.t += DT;
        ++f.frames;
        std::tie(f.s, f.v) = along(f.leg, f.t);
        const float RAW    = smooth(std::abs(f.leg.s1 - f.s) / 0.45F);
        f.lift             = RAW > f.lift ? f.lift + (RAW - f.lift) * (1.F - std::exp(-DT / 80.F)) : RAW;
        f.age += DT;
        if (f.style == eStyle::NAVE)
            f.lift = std::min(f.lift, smooth(f.age / ENTRY));
        f.reach += (std::abs(f.leg.s1 - f.leg.s0) - f.reach) * (1.F - std::exp(-DT / 150.F));
        const auto TO = f.to.lock();
        for (auto& r : f.rooms)
            r.paper += ((r.id == f.from || (TO && r.id == idOf(TO)) ? 1.F : 0.F) - r.paper) * (1.F - std::exp(-DT / 70.F));
    }

    void gaze(SFlight& f, const PHLMONITOR& monitor) {
        auto& iris = irises[monitor->m_id];
        if (!iris.fbo) {
            glGenFramebuffers(1, &iris.fbo);
            glGenBuffers(2, iris.pbo.data());
            for (const GLuint B : iris.pbo) {
                glBindBuffer(GL_PIXEL_PACK_BUFFER, B);
                glBufferData(GL_PIXEL_PACK_BUFFER, 4, nullptr, GL_STREAM_READ);
            }
        }
        glBindBuffer(GL_PIXEL_PACK_BUFFER, iris.pbo[iris.at]);
        if (iris.sent[iris.at] == f.serial)
            if (const auto* const PX = static_cast<const uint8_t*>(glMapBufferRange(GL_PIXEL_PACK_BUFFER, 0, 4, GL_MAP_READ_BIT))) {
                const float SEEN = (0.299F * PX[0] + 0.587F * PX[1] + 0.114F * PX[2]) / 255.F;
                glUnmapBuffer(GL_PIXEL_PACK_BUFFER);
                f.adapted = f.adapted < 0 ? SEEN : f.adapted + (SEEN - f.adapted) * (1.F - std::exp(-f.dt / EYE));
            }
        GLint target = 0;
        glGetIntegerv(GL_FRAMEBUFFER_BINDING, &target);
        glBindFramebuffer(GL_READ_FRAMEBUFFER, iris.fbo);
        glFramebufferTexture2D(GL_READ_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, f.canvas->getTexture()->m_texID,
                               int(std::log2(std::max(monitor->m_pixelSize.x, monitor->m_pixelSize.y))));
        glReadPixels(0, 0, 1, 1, GL_RGBA, GL_UNSIGNED_BYTE, nullptr);
        glBindFramebuffer(GL_FRAMEBUFFER, target);
        glBindBuffer(GL_PIXEL_PACK_BUFFER, 0);
        iris.sent[iris.at] = f.serial;
        iris.at ^= 1;
        while (glGetError() != GL_NO_ERROR)
            ;
    }

    void clockOn(SFlight& f, const PHLMONITOR& monitor) {
        f.begin.reset();
        f.t      = 0;
        f.frames = 0;
        Animation::mgr()->createAnimation(0.F, f.clock, vitrailClock(f.leg.T + FADE + HOLD), AVARDAMAGE_NONE);
        const PHLMONITORREF REF = monitor;
        f.clock->setUpdateCallback([REF](auto) {
            if (const auto M = REF.lock())
                g_pHyprRenderer->damageMonitor(M);
        });
        f.clock->setValueAndWarp(0.F);
        *f.clock = 1.F;
    }

    void furnish(SFlight& f, const PHLMONITOR& monitor, WORKSPACEID lo, WORKSPACEID hi) {
        for (WORKSPACEID id = lo; id <= hi; ++id)
            if (std::ranges::none_of(f.rooms, [id](const SRoom& r) { return r.id == id; }))
                f.rooms.push_back({.id = id, .fb = f.style == eStyle::NAVE ? canvas(monitor) : nullptr, .seam = float(monitor->m_pixelSize.x / 2)});
        std::ranges::sort(f.rooms, {}, &SRoom::id);
    }

    void shootNext(SFlight& f, const PHLMONITOR& monitor) {
        auto       WAITING = f.rooms | std::views::filter([](const SRoom& r) { return !r.shot; });
        const auto NEXT    = std::ranges::min_element(WAITING, {}, [&f](const SRoom& r) { return std::abs(float(r.id) - f.s - (f.leg.s1 > f.s ? 0.4F : -0.4F)); });
        if (NEXT != std::ranges::end(WAITING))
            shoot(*NEXT, monitor);
    }

    void land(SFlight& f) {
        release(f);
        show(f.to.lock(), 1.F);
        if (const auto MON = f.monitor.lock())
            g_pHyprRenderer->damageMonitor(MON);
    }

    void sight(SFlight& f, const PHLMONITOR& monitor, const PHLWORKSPACE& to) {
        if (const auto R = std::ranges::find(f.rooms, idOf(to), &SRoom::id); f.pyre && R != f.rooms.end())
            R->seam = seamOf(monitor, to);
    }

    void turn(SFlight& f, const PHLMONITOR& monitor, const PHLWORKSPACE& to) {
        f.next.reset();
        if (!f.hold) {
            advance(f, monitor);
            release(f);
        }
        if (const auto OLD = f.to.lock(); OLD && OLD != to)
            hide(OLD);
        const float SPAN = std::abs(float(idOf(to)) - f.s);
        if (idOf(to) <= 0 || SPAN > float(REACH)) {
            land(f);
            std::erase_if(flights, [&f](const UP<SFlight>& x) { return x.get() == &f; });
            return;
        }
        if (f.style == eStyle::LANTERN && (idOf(to) < f.first || idOf(to) > f.last))
            f.style = eStyle::NAVE;
        furnish(f, monitor, std::min<WORKSPACEID>(WORKSPACEID(std::floor(f.s)), idOf(to)), std::max<WORKSPACEID>(WORKSPACEID(std::ceil(f.s)), idOf(to)));
        hide(to);
        f.to    = to;
        f.shown = 0;
        f.leg   = legOf(f.s, f.v, float(idOf(to)));
        sight(f, monitor, to);
        if (!f.hold)
            clockOn(f, monitor);
        g_pHyprRenderer->damageMonitor(monitor);
    }
}
