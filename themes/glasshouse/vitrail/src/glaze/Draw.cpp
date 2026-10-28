#include "glaze/Internal.hpp"

namespace Glaze {
    float lanesOf(const Vector2D& grid) {
        return std::clamp(std::round(float(grid.x) / 6.F), 2.F, 5.F);
    }

    const float SURGE = SHOCK / (1.F - std::cbrt(1.F - 1.F / SHOT));

    void project(SProgram& p, const PHLMONITOR& m) {
        auto& rd = Gl::ctx->m_data;
        CBox  whole{0, 0, m->m_pixelSize.x, m->m_pixelSize.y};
        rd.renderModif.applyToBox(whole);
        p.shader->setUniformMatrix3fv(SHADER_PROJ, 1, GL_TRUE, g_pHyprRenderer->projectBoxToTarget(*Gl::ctx, whole.translate(Gl::nudge)).getMatrix());
        glUniform2f(p["target"], m->m_pixelSize.x, m->m_pixelSize.y);
        glUniform3f(p["screen"], m->m_position.x, m->m_position.y, m->m_scale);
    }

    void strokes(SProgram& p, const Gl::SArea& area, int count) {
        auto& rd = Gl::ctx->m_data;
        glBindVertexArray(p.shader->getUniformLocation(SHADER_SHADER_VAO));
        area.region.forEachRect([&rd, count](const auto& RECT) {
            g_pHyprOpenGL->scissor(*Gl::ctx, &RECT, rd.transformDamage);
            glDrawArrays(GL_TRIANGLES, 0, count);
        });
        glBindVertexArray(0);
        g_pHyprOpenGL->disableScissor();
    }

    std::optional<Gl::SArea> areaOf(const SSheet& s, size_t i, const CBox& phys) {
        auto area = Gl::areaOf(phys, std::nullopt);
        if (!area || !s.live)
            return area;
        for (const auto& above : s.panes | std::views::drop(i + 1)) {
            CBox b = above.box.copy().round();
            Gl::ctx->m_data.renderModif.applyToBox(b);
            area->region.subtract(CRegion{b.translate(Gl::nudge)});
        }
        return area->region.empty() ? std::nullopt : area;
    }

    void drawGlass(const SSheet& s, size_t i, float t, const PHLMONITOR& m) {
        const auto& PANE = s.panes[i];
        const double S   = m->m_scale;
        const auto  AREA = areaOf(s, i, PANE.box.copy().expand(REACH * S).round());
        if (!AREA)
            return;
        const auto&    P    = pal();
        const auto&    U    = hue();
        const Vector2D LAMP = worldLightOn(m) * S;
        auto&          p    = glazeProgram;
        g_pHyprOpenGL->useShader(p.shader);
        glUniform1i(p["tex"], 0);
        glUniform2f(p["texSize"], m->m_pixelSize.x, m->m_pixelSize.y);
        glUniform4f(p["drawn"], AREA->drawn.x, AREA->drawn.y, AREA->drawn.w, AREA->drawn.h);
        glUniform4f(p["box"], PANE.box.x, PANE.box.y, PANE.box.w, PANE.box.h);
        glUniform1f(p["radius"], PANE.radius);
        glUniform2f(p["grid"], PANE.grid.x, PANE.grid.y);
        glUniform1f(p["t"], t);
        glUniform1f(p["rising"], s.shows ? 0.F : 1.F);
        glUniform1f(p["live"], s.live ? 1.F : 0.F);
        glUniform1f(p["scale"], S);
        glUniform1f(p["ink"], U.inked);
        glUniform1f(p["pop"], std::min(POP, float(2 * OVERHANG * S / PANE.box.w)));
        glUniform4f(p["seat"], FIRST, SPAN, RATIO, FRAMED);
        glUniform4f(p["lift"], LIFT, LIFTED, RISEN, CLIMB);
        glUniform4f(p["weld"], SLAM, SURGE, RING, SHOT);
        glUniform2f(p["lamp"], LAMP.x, LAMP.y);
        Gl::rgb(p, "lampHue", P.lamp);
        Gl::rgb(p, "leadLow", P.metalLow);
        Gl::rgb(p, "hot", U.hot);
        Gl::rgb(p, "gold", P.dark ? U.gold : U.leaf);
        Gl::rgb(p, "sepia", U.sepia);
        Gl::rgb(p, "leaf", U.leaf);
        const SRGB SHADE = P.dark ? P.metalBase : U.sepia;
        glUniform4f(p["umbra"], SHADE.r, SHADE.g, SHADE.b, P.dark ? 0.3F : 0.25F);
        Gl::bindTex(0, PANE.shot->getTexture());
        Gl::paint(p, *AREA);
    }

    void drawBolt(const SSheet& s, size_t i, float t, const PHLMONITOR& m) {
        const auto&  PANE = s.panes[i];
        const double S    = m->m_scale;
        const CBox&  B    = PANE.box;
        const auto   AREA = areaOf(s, i, B.copy().expand(BOLTED * S).round());
        if (!AREA || !Gl::ready(boltProgram))
            return;
        const auto&                 P     = pal();
        const auto&                 U     = hue();
        const std::array<float, 16> GATES = {float(B.x), float(B.y + B.h), float(B.x + B.w), float(B.y + B.h)};
        auto&                       p     = boltProgram;
        g_pHyprOpenGL->useShader(p.shader);
        glUniform1i(p["perm"], 0);
        glUniform4f(p["drawn"], AREA->drawn.x, AREA->drawn.y, AREA->drawn.w, AREA->drawn.h);
        glUniform4f(p["win"], B.x, B.y, B.w, B.h);
        glUniform1f(p["turn"], 0.F);
        glUniform4f(p["frame"], B.x, B.y, B.w, B.h);
        glUniform4f(p["hull"], B.x, B.y, B.w, B.h);
        glUniform4f(p["hand"], 0.F, 0.F, 0.F, 1.F);
        glUniform4f(p["hubs"], 0.F, 0.F, 0.F, 0.F);
        glUniform3f(p["ring"], B.h * SHOT, SLAM, SURGE);
        glUniform2f(p["grid"], PANE.grid.x, PANE.grid.y);
        glUniform1f(p["radius"], PANE.radius);
        glUniform1f(p["scale"], S);
        glUniform1f(p["t"], t);
        glUniform1f(p["base"], 0.F);
        glUniform4f(p["seal"], SLAM, 1.F, 1.F, 2.F);
        glUniform1f(p["bolt"], 1.F);
        glUniform1f(p["seed"], s.seed);
        glUniform4fv(p["gates"], 4, GATES.data());
        glUniform1f(p["gated"], 1.F);
        glUniform1f(p["lanes"], lanesOf(PANE.grid));
        glUniform1i(p["under"], 1);
        glUniform2f(p["underSize"], m->m_pixelSize.x, m->m_pixelSize.y);
        glUniform1f(p["knee"], 1.F);
        Gl::rgb(p, "hot", U.hot);
        Gl::rgb(p, "keyline", P.dark ? U.gold : U.leaf);
        Gl::rgb(p, "jewel0", U.jewel0);
        Gl::rgb(p, "jewel1", U.jewel1);
        Gl::rgb(p, "leadLow", P.metalLow);
        Gl::rgb(p, "leadBase", P.metalBase);
        Gl::rgb(p, "leadHi", P.metalHi);
        Gl::rgb(p, "sepia", U.sepia);
        Gl::rgb(p, "leaf", U.leaf);
        glUniform1f(p["ink"], U.inked);
        Gl::bindTex(1, PANE.shot->getTexture());
        Gl::paint(p, *AREA);
        Gl::bindTex(1, nullptr);
    }

    void drawSpatter(const SSheet& s, size_t i, float t, const PHLMONITOR& m) {
        const auto AREA = Gl::areaOf(CBox{{}, m->m_pixelSize}, std::nullopt);
        if (!AREA || !Gl::ready(spatterProgram))
            return;
        const auto&                 PANE  = s.panes[i];
        const CBox&                 A     = PANE.area;
        const int                   NU    = int(PANE.grid.x + PANE.grid.y);
        const auto&                 U     = hue();
        const std::array<float, 16> GATES = {float(A.x), float(A.y + A.h), float(A.x + A.w), float(A.y + A.h)};
        auto&                       p     = spatterProgram;
        g_pHyprOpenGL->useShader(p.shader);
        project(p, m);
        glUniform4f(p["box"], A.x, A.y, A.w, A.h);
        glUniform4f(p["goal"], A.x, A.y, A.w, A.h);
        glUniform2f(p["grid"], PANE.grid.x, PANE.grid.y);
        glUniform1f(p["t"], t);
        glUniform1f(p["base"], 0.F);
        glUniform1f(p["crack"], 0.F);
        glUniform3f(p["ring"], A.h * SHOT, SLAM, SURGE);
        glUniform4f(p["hand"], 0.F, 0.F, 0.F, 1.F);
        glUniform4fv(p["gates"], 4, GATES.data());
        glUniform1f(p["gated"], 1.F);
        glUniform2f(p["glide"], 0.F, 0.F);
        glUniform1f(p["lanes"], lanesOf(PANE.grid));
        glUniform1f(p["cooled"], COOLED);
        glUniform1f(p["seed"], s.seed);
        glUniform1i(p["perm"], 0);
        Gl::rgb(p, "hot", U.hot);
        Gl::rgb(p, "dust", U.dust);
        Gl::rgb(p, "jewel0", U.jewel0);
        Gl::rgb(p, "jewel1", U.jewel1);
        Gl::rgb(p, "sepia", U.sepia);
        Gl::rgb(p, "leaf", U.leaf);
        glUniform1f(p["ink"], U.inked);
        for (const auto& [KIND, COUNT] : {std::pair{MEND, (2 * (NU + 1) * (NU + 1) + 2 * LINKS) * STRIKES * DROPS}, std::pair{SPLASH, SPLASHES}}) {
            glUniform1f(p["kind"], float(KIND));
            strokes(p, *AREA, COUNT * 6);
        }
    }
}
