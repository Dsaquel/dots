#include "passage/Internal.hpp"

namespace Passage {
    std::optional<eStyle> styleNow() {
        const std::string S{g_glass->passage->value()};
        if (S == "nave")
            return eStyle::NAVE;
        if (S == "gallery")
            return eStyle::GALLERY;
        if (S == "lantern")
            return eStyle::LANTERN;
        return std::nullopt;
    }

    std::pair<int, int> rangeOf(const PHLMONITOR& monitor) {
        const std::string SPEC{g_glass->screens->value()};
        for (const auto& part : std::views::split(SPEC, ',')) {
            const std::string P{part.begin(), part.end()};
            const auto        EQ = P.find('='), COLON = P.find(':'), DASH = P.rfind('-');
            if (EQ == std::string::npos || P.substr(0, EQ) != monitor->m_name || COLON == std::string::npos || DASH == std::string::npos || DASH < COLON)
                continue;
            return {std::atoi(P.substr(COLON + 1, DASH - COLON - 1).c_str()), std::atoi(P.substr(DASH + 1).c_str())};
        }
        return {1, 10};
    }

    std::pair<int, int> romanOf(WORKSPACEID id) {
        static const std::array<std::vector<int>, 10> UNITS = {{{}, {1}, {1, 1}, {1, 1, 1}, {1, 2}, {2}, {2, 1}, {2, 1, 1}, {2, 1, 1, 1}, {1, 3}}};
        if (id < 1 || id > 39)
            return {0, 0};
        std::vector<int> g(size_t(id / 10), 3);
        std::ranges::copy(UNITS[size_t(id % 10)], std::back_inserter(g));
        int code = 0;
        for (size_t i = 0; i < g.size(); ++i)
            code |= g[i] << (2 * i);
        return {code, int(g.size())};
    }

    SFlight* flightOn(const PHLMONITOR& monitor) {
        const auto IT = std::ranges::find_if(flights, [&monitor](const UP<SFlight>& f) { return f->monitor.lock() == monitor; });
        return IT == flights.end() ? nullptr : IT->get();
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

    float seamOf(const PHLMONITOR& monitor, const PHLWORKSPACE& ws) {
        const CBox   AREA = monitor->logicalBoxMinusReserved().translate(-monitor->m_position);
        const double MID  = AREA.middle().x;
        auto         spans = windowsOf(monitor, ws) | std::views::transform([&monitor](const PHLWINDOW& w) {
                         const CBox B = w->getWindowMainSurfaceBox().translate(-monitor->m_position);
                         return std::pair{B.x, B.x + B.w};
                     }) |
            std::ranges::to<std::vector>();
        std::ranges::sort(spans);
        double     best = MID, reach = AREA.x;
        bool       found = false;
        const auto TRY   = [&](double a, double b) {
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

    PHLWORKSPACE workspaceOf(WORKSPACEID id) {
        for (const auto& ref : State::workspaceState()->workspaces())
            if (const auto W = ref.lock(); W && idOf(W) == id && !isSpecial(W))
                return W;
        return nullptr;
    }

    void shoot(SRoom& r, const PHLMONITOR& monitor) {
        r.shot        = true;
        const auto WS = workspaceOf(r.id);
        if (!WS || WS->m_monitor.lock() != monitor)
            return;
        const bool FORCED = WS->m_forceRendering;
        WS->m_forceRendering = true;
        WS->m_alpha->setValueAndWarp(1.F);
        WS->m_renderOffset->setValueAndWarp({});
        if (Translation::bound(WS))
            for (const auto& w : windowsOf(monitor, WS)) {
                w->positionAnimation()->warp();
                w->sizeAnimation()->warp();
            }
        g_glass->shooting = eShot::SKINNED;
        for (const auto& w : windowsOf(monitor, WS))
            if (const auto FB = g_pHyprRenderer->makeSnapshotFB(w))
                r.shots.push_back(FB);
        g_glass->shooting = eShot::NONE;
        WS->m_alpha->setValueAndWarp(0.F);
        WS->m_forceRendering = FORCED;
        r.seam = seamOf(monitor, WS);
    }

    void hide(const PHLWORKSPACE& ws) {
        if (ws) {
            ws->m_alpha->setValueAndWarp(0.F);
            ws->m_renderOffset->setValueAndWarp({});
        }
    }

    void show(const PHLWORKSPACE& ws, float alpha) {
        if (ws) {
            ws->m_alpha->setValueAndWarp(alpha);
            ws->m_renderOffset->setValueAndWarp({});
        }
    }

    void mipmap(const SP<Render::IFramebuffer>& fb) {
        if (const auto TEX = fb->getTexture()) {
            glBindTexture(GL_TEXTURE_2D, TEX->m_texID);
            glGenerateMipmap(GL_TEXTURE_2D);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameterf(GL_TEXTURE_2D, 0x84FE, 8.F);
            glBindTexture(GL_TEXTURE_2D, 0);
            while (glGetError() != GL_NO_ERROR)
                ;
        }
    }

    SP<Render::IFramebuffer> canvas(const PHLMONITOR& monitor) {
        auto fb = g_pHyprRenderer->createFB("vitrail passage");
        fb->alloc(monitor->m_pixelSize.x, monitor->m_pixelSize.y, DRM_FORMAT_ABGR8888);
        fb->setImageDescription(monitor->workBufferImageDescription());
        mipmap(fb);
        return fb;
    }

    void develop(SRoom& r, const PHLMONITOR& monitor) {
        if (r.ready || !r.shot)
            return;
        r.ready = true;
        if (r.shots.empty() || !Gl::ready(hallProgram)) {
            r.fb.reset();
            return;
        }
        if (!r.fb)
            r.fb = canvas(monitor);
        {
            const SFull FULL(monitor);
            auto        guard = g_pHyprRenderer->bindTempFB(*Gl::ctx, r.fb);
            g_pHyprRenderer->disableScissor();
            glClearColor(0.F, 0.F, 0.F, 0.F);
            glClear(GL_COLOR_BUFFER_BIT);
            g_pHyprOpenGL->blend(true);
            if (const auto AREA = Gl::areaOf(CBox{{}, monitor->m_pixelSize}, std::nullopt)) {
                auto& p = hallProgram;
                g_pHyprOpenGL->useShader(p.shader);
                glUniform1f(p["mode"], 0.F);
                glUniform1i(p["tex"], 0);
                glUniform2f(p["texSize"], monitor->m_pixelSize.x, monitor->m_pixelSize.y);
                glUniform4f(p["drawn"], AREA->drawn.x, AREA->drawn.y, AREA->drawn.w, AREA->drawn.h);
                for (const auto& shot : r.shots)
                    if (shot && shot->getTexture()) {
                        Gl::bindTex(0, shot->getTexture());
                        Gl::paint(p, *AREA);
                    }
                Gl::bindTex(0, nullptr);
            }
        }
        r.shots.clear();
        mipmap(r.fb);
    }

    void grab(SP<Render::IFramebuffer>& fb, const PHLMONITOR& monitor) {
        if (!fb)
            fb = canvas(monitor);
        auto* const DST = dynamic_cast<Render::GL::CGLFramebuffer*>(fb.get());
        if (!DST)
            return;
        GLint target = 0;
        glGetIntegerv(GL_FRAMEBUFFER_BINDING, &target);
        g_pHyprRenderer->disableScissor();
        glBindFramebuffer(GL_READ_FRAMEBUFFER, target);
        glBindFramebuffer(GL_DRAW_FRAMEBUFFER, DST->getFBID());
        const GLint W = GLint(monitor->m_pixelSize.x), H = GLint(monitor->m_pixelSize.y);
        glBlitFramebuffer(0, 0, W, H, 0, 0, W, H, GL_COLOR_BUFFER_BIT, GL_NEAREST);
        glBindFramebuffer(GL_FRAMEBUFFER, target);
        mipmap(fb);
    }

    void release(SFlight& f) {
        if (const auto WS = f.held.lock()) {
            WS->m_forceRendering = f.forced;
            hide(WS);
        }
        f.held.reset();
    }

    void back(SFlight& f, const PHLMONITOR& monitor) {
        if (f.held.lock())
            if (auto ORIGIN = std::ranges::find(f.rooms, f.from, &SRoom::id); ORIGIN != f.rooms.end()) {
                grab(ORIGIN->fb, monitor);
                ORIGIN->ready = true;
            }
        release(f);
        grab(f.shown ? f.live : f.paper, monitor);
    }

    SP<Render::IFramebuffer> imageOf(const SFlight& f, const SRoom& r) {
        if (f.shown && r.id == f.shown)
            return f.live;
        if (f.lit && r.id == f.from)
            return f.ember;
        return r.ready ? r.fb : nullptr;
    }

    void blaze(SFlight& f, const PHLMONITOR& monitor) {
        const auto ORIGIN = std::ranges::find(f.rooms, f.from, &SRoom::id);
        f.lit             = false;
        if (!f.ember || ORIGIN == f.rooms.end() || !ORIGIN->ready || !ORIGIN->fb)
            return;
        {
            const SFull FULL(monitor);
            auto        guard = g_pHyprRenderer->bindTempFB(*Gl::ctx, f.ember);
            g_pHyprRenderer->disableScissor();
            glClearColor(0.F, 0.F, 0.F, 0.F);
            glClear(GL_COLOR_BUFFER_BIT);
            g_pHyprOpenGL->blend(true);
            if (const auto AREA = Gl::areaOf(CBox{{}, monitor->m_pixelSize}, std::nullopt)) {
                auto& p = hallProgram;
                g_pHyprOpenGL->useShader(p.shader);
                glUniform1f(p["mode"], 0.F);
                glUniform1i(p["tex"], 0);
                glUniform2f(p["texSize"], monitor->m_pixelSize.x, monitor->m_pixelSize.y);
                glUniform4f(p["drawn"], AREA->drawn.x, AREA->drawn.y, AREA->drawn.w, AREA->drawn.h);
                Gl::bindTex(0, ORIGIN->fb->getTexture());
                Gl::paint(p, *AREA);
                Gl::bindTex(0, nullptr);
            }
            f.lit = Translation::blaze(monitor);
        }
        if (f.lit)
            mipmap(f.ember);
        else
            f.ember.reset();
    }
}
