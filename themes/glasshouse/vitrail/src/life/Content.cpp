#include "life/Internal.hpp"

namespace Life {
    Vector2D sideSeg(const CBox& g, int side, double came, bool start) {
        const double MID = (came + 1.2) / 2;
        switch (side) {
            case 0: return start ? Vector2D{g.x + 8, g.y - MID} : Vector2D{g.x + g.w - 8, g.y - MID};
            case 1: return start ? Vector2D{g.x + g.w + MID, g.y + 8} : Vector2D{g.x + g.w + MID, g.y + g.h - 8};
            case 2: return start ? Vector2D{g.x + 8, g.y + g.h + MID} : Vector2D{g.x + g.w - 8, g.y + g.h + MID};
            default: return start ? Vector2D{g.x - MID, g.y + 8} : Vector2D{g.x - MID, g.y + g.h - 8};
        }
    }

    double cameFor(const PHLWINDOW& w, const CBox& b) {
        return w && w->onSpecialWorkspace() ? 7.5 : (b.w < 360 || b.h < 220 ? 7.5 : 9.5);
    }

    void drawContent(const SContent& c, const PHLMONITOR& m) {
        const auto AREA = Gl::areaOf(c.drawn, std::nullopt);
        if (!AREA || !c.tex || !Gl::ready(contentProgram))
            return;
        auto&       p = contentProgram;
        const auto& P = pal();
        const auto& U = hue();
        const auto  S = m->m_scale;
        const auto  L = lightPx(m);
        g_pHyprOpenGL->useShader(p.shader);
        if (p.stamp.first != &P) {
            p.stamp = {&P, 0};
            glUniform1i(p["tex"], 0);
            Gl::rgb(p, "gold", U.gold);
            Gl::rgb(p, "hot", U.hot);
            Gl::rgb(p, "dust", U.dust);
            Gl::rgb(p, "jewel0", U.jewel0);
            Gl::rgb(p, "jewel1", U.jewel1);
            Gl::rgb(p, "jewel2", U.jewel2);
            Gl::rgb(p, "leadColor", P.metalBase);
            Gl::rgb(p, "sepia", U.sepia);
            Gl::rgb(p, "leaf", U.leaf);
            glUniform1f(p["ink"], U.inked);
        }
        glUniform2f(p["texSize"], c.texSize.x, c.texSize.y);
        glUniform1f(p["flipY"], 0.F);
        glUniform4f(p["drawn"], AREA->drawn.x, AREA->drawn.y, AREA->drawn.w, AREA->drawn.h);
        glUniform4f(p["win"], c.win.x, c.win.y, c.win.w, c.win.h);
        glUniform1f(p["radius"], c.radius);
        glUniform1f(p["scale"], S);
        glUniform1f(p["t"], c.t);
        glUniform1f(p["mode"], c.mode);
        glUniform4fv(p["origin"], 1, c.origin.data());
        glUniform1f(p["span"], c.span);
        glUniform4fv(p["timing"], 1, c.timing.data());
        glUniform2f(p["cell"], c.cell.x, c.cell.y);
        glUniform1f(p["edge"], c.edge);
        glUniform1f(p["seed"], c.seed);
        glUniform4f(p["lightPos"], L.x, L.y, 520.F * S, 640.F * S);
        glUniform4fv(p["front"], 1, c.front.data());
        glUniform1f(p["fire"], c.fire);
        glUniform1f(p["came"], c.came);
        Gl::bindTex(0, c.tex);
        Gl::paint(p, *AREA);
        Gl::bindTex(0, nullptr);
    }

    void straighten(const SP<Render::IFramebuffer>& out, const CBox& win, float radius, const PHLMONITOR& m) {
        const auto TMP = m && m->resources() ? m->resources()->getUnusedWorkBuffer() : nullptr;
        if (!out || !out->getTexture() || !TMP || !TMP->isAllocated())
            return;
        SContent c{.tex = out->getTexture(), .texSize = out->m_size, .drawn = win.copy().expand(2), .win = win, .radius = radius, .t = 0, .mode = 4};
        g_pHyprOpenGL->blend(false);
        {
            auto guard = g_pHyprRenderer->bindTempFB(*Gl::ctx, TMP);
            drawContent(c, m);
        }
        c.tex = TMP->getTexture();
        c.t   = 1;
        {
            auto guard = g_pHyprRenderer->bindTempFB(*Gl::ctx, out);
            drawContent(c, m);
        }
        g_pHyprOpenGL->blend(true);
    }

    void drawGrains(const SP<Render::ITexture>& tex, const Vector2D& texSize, const CBox& box, float t, const std::array<float, 4>& front, float seed, const PHLMONITOR& m, const CBox& win,
                    float radius, bool fire) {
        const double S     = m->m_scale;
        const double GRAIN = std::max(2.0, std::round(3.0 * S));
        const CBox   REACH = CBox{box.x - 120 * S, box.y - 360 * S, box.w + 240 * S, box.h + 380 * S};
        const auto   AREA  = Gl::areaOf(REACH, std::nullopt);
        if (!AREA || !tex || !Gl::ready(grainProgram))
            return;
        const int COLS = int(std::ceil(box.w / GRAIN)), ROWS = int(std::ceil(box.h / GRAIN));
        auto&     p    = grainProgram;
        const auto& U  = hue();
        g_pHyprOpenGL->useShader(p.shader);
        if (p.stamp.first != &pal()) {
            p.stamp = {&pal(), 0};
            glUniform1i(p["tex"], 0);
            Gl::rgb(p, "dust", U.dust);
            Gl::rgb(p, "sparkColor", U.spark);
            Gl::rgb(p, "leaf", U.leaf);
            Gl::rgb(p, "hot", U.hot);
            Gl::rgb(p, "sepia", U.sepia);
            glUniform1f(p["ink"], U.inked);
        }
        auto& rd = Gl::ctx->m_data;
        CBox  whole{0, 0, double(rd.pMonitor->m_pixelSize.x), double(rd.pMonitor->m_pixelSize.y)};
        rd.renderModif.applyToBox(whole);
        p.shader->setUniformMatrix3fv(SHADER_PROJ, 1, GL_TRUE, g_pHyprRenderer->projectBoxToTarget(*Gl::ctx, whole).getMatrix());
        glUniform2f(p["target"], rd.pMonitor->m_pixelSize.x, rd.pMonitor->m_pixelSize.y);
        glUniform2f(p["texSize"], texSize.x, texSize.y);
        glUniform1f(p["flipY"], 0.F);
        glUniform4f(p["box"], box.x, box.y, box.w, box.h);
        glUniform1f(p["grain"], GRAIN);
        glUniform1f(p["cols"], COLS);
        glUniform1f(p["t"], t);
        glUniform4fv(p["front"], 1, front.data());
        glUniform1f(p["seed"], seed);
        glUniform1f(p["scale"], S);
        glUniform1f(p["fire"], fire ? 1.F : 0.F);
        glUniform4f(p["win"], win.x, win.y, win.w, win.h);
        glUniform1f(p["radius"], radius);
        const auto L = lightPx(m);
        glUniform2f(p["lightAt"], L.x, L.y);
        Gl::bindTex(0, tex);
        glBindVertexArray(p.shader->getUniformLocation(SHADER_SHADER_VAO));
        AREA->region.forEachRect([&rd, COLS, ROWS](const auto& RECT) {
            g_pHyprOpenGL->scissor(*Gl::ctx, &RECT, rd.transformDamage);
            glDrawArrays(GL_POINTS, 0, COLS * ROWS);
        });
        glBindVertexArray(0);
        g_pHyprOpenGL->disableScissor();
        Gl::bindTex(0, nullptr);
    }

    void drawSlivers(const CBox& box, const CBox& win, float radius, const std::array<float, 4>& front, float came, float t, float seed, const PHLMONITOR& m) {
        const double S    = m->m_scale;
        const auto   AREA = Gl::areaOf(box.copy().expand(60 * S).round(), std::nullopt);
        if (!AREA || !Gl::ready(sliverProgram))
            return;
        const int   COUNT = std::clamp(int(SRing(win, radius).per / (130 * S)), 10, 48);
        auto&       p     = sliverProgram;
        const auto& U     = hue();
        auto&       rd    = Gl::ctx->m_data;
        g_pHyprOpenGL->useShader(p.shader);
        CBox whole{0, 0, double(rd.pMonitor->m_pixelSize.x), double(rd.pMonitor->m_pixelSize.y)};
        rd.renderModif.applyToBox(whole);
        p.shader->setUniformMatrix3fv(SHADER_PROJ, 1, GL_TRUE, g_pHyprRenderer->projectBoxToTarget(*Gl::ctx, whole).getMatrix());
        glUniform2f(p["target"], rd.pMonitor->m_pixelSize.x, rd.pMonitor->m_pixelSize.y);
        glUniform4f(p["win"], win.x, win.y, win.w, win.h);
        glUniform1f(p["radius"], radius);
        glUniform4fv(p["front"], 1, front.data());
        glUniform1f(p["came"], came);
        glUniform1f(p["t"], t);
        glUniform1f(p["scale"], S);
        glUniform1f(p["seed"], seed);
        glUniform1f(p["count"], COUNT);
        Gl::rgb(p, "gold", U.inked > 0.5F ? U.leaf : U.gold);
        Gl::rgb(p, "hot", U.hot);
        glBindVertexArray(p.shader->getUniformLocation(SHADER_SHADER_VAO));
        AREA->region.forEachRect([&rd, COUNT](const auto& RECT) {
            g_pHyprOpenGL->scissor(*Gl::ctx, &RECT, rd.transformDamage);
            glDrawArrays(GL_TRIANGLES, 0, COUNT * 6);
        });
        glBindVertexArray(0);
        g_pHyprOpenGL->disableScissor();
    }
}
