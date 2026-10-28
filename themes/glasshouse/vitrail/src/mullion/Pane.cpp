#include "mullion/Internal.hpp"

namespace Mullion {
    void stampPane() {
        auto&       p = paneProgram;
        const auto& P = pal();
        const auto& U = hue();
        if (p.stamp.first == &P)
            return;
        p.stamp = {&P, 0};
        glUniform1i(p["tex"], 0);
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

    void drawPane(const SScene& s, float t, int pass, const PHLMONITOR& m) {
        const auto   TEX  = s.still ? s.still->getTexture() : nullptr;
        const double S    = m->m_scale;
        const auto   AREA = Gl::areaOf((pass == 0 ? s.n : s.r).copy().scale(S).round(), std::nullopt);
        if (!TEX || !AREA || !Gl::ready(paneProgram))
            return;
        auto& p = paneProgram;
        g_pHyprOpenGL->useShader(p.shader);
        stampPane();
        const SRing    RING(s.r, s.radius);
        const Vector2D C     = (s.j0 + s.j1) / 2;
        const float    KS    = span(t, s.boom, s.boom + SHOCK);
        const double   AXIS  = s.upright ? s.b.x : s.b.y;
        const double   EDGE  = s.mid + AXIS * s.gutter;
        const float    HEAT  = t >= s.lap0 ? 0.95F * (1.F - span(t, s.lap0 + SWEEP, s.lap0 + SWEEP + 160)) : 0.F;
        const auto     SHOCK4 = t < s.boom ? std::array<float, 4>{0, 0, 0, -1} :
                                             (KS >= 1 ? std::array<float, 4>{float(C.x * S), float(C.y * S), 1e6F, 0.F} :
                                                        std::array<float, 4>{float(C.x * S), float(C.y * S), float(waveAt(s, t - s.boom) * S), 1.F - span(t, s.boom + SHOCK * 0.55F, s.boom + SHOCK)});
        glUniform4f(p["drawn"], AREA->drawn.x, AREA->drawn.y, AREA->drawn.w, AREA->drawn.h);
        glUniform1f(p["pass"], float(pass));
        glUniform1f(p["scale"], S);
        glUniform1f(p["t"], t);
        glUniform1f(p["seed"], s.seed);
        glUniform2f(p["texSize"], s.still->m_size.x, s.still->m_size.y);
        glUniform4f(p["pane"], s.r.x * S, s.r.y * S, s.r.w * S, s.r.h * S);
        glUniform1f(p["radius"], s.radius * S);
        glUniform4f(p["ring"], RING.ex * S, RING.ey * S, RING.rr * S, 0.F);
        glUniform4f(p["born"], s.n.x * S, s.n.y * S, s.n.w * S, s.n.h * S);
        glUniform4f(p["seam"], s.upright ? 1.F : 0.F, s.mid * S, (s.upright ? s.j0.y : s.j0.x) * S, (s.upright ? s.j1.y : s.j1.x) * S);
        const double LEAD = (EDGE - edgeOf(s.r, (s.side + 2) % 4)) * AXIS * (1 - SKIP + (noise(s.seed, 3.3F) - 0.5F) * 0.16F);
        glUniform4f(p["front"], EDGE * S, float(AXIS), s.reach * S, LEAD * S);
        glUniform1f(p["onset"], EXPAND0 - RUN);
        glUniform4f(p["reveal"], EXPAND0, EXPAND1, CELL, 70.F);
        glUniform2f(p["cell"], std::clamp(s.n.w / 18, 36.0, 52.0) * S, std::clamp(s.n.h / 13, 54.0, 78.0) * S);
        glUniform4fv(p["shock"], 1, SHOCK4.data());
        glUniform4f(p["lap"], HEAT, float((t - s.lap0) * s.lapSpeed * S), float(s.farN * S), float(RING.per * S));
        glUniform1f(p["boom"], s.boom);
        glUniform1f(p["heat"], s.heat);
        Gl::bindTex(0, TEX);
        if (pass == 0)
            glBlendFuncSeparate(GL_DST_COLOR, GL_ZERO, GL_ZERO, GL_ONE);
        Gl::paint(p, *AREA);
        // Hyprland 0.57 caches the blend func and skips matching calls, so the raw multiply above must be undone raw too
        if (pass == 0)
            glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
        Gl::bindTex(0, nullptr);
    }

    void drawImpact(const SScene& s, const SImpact& im, float t, const PHLMONITOR& m) {
        const float AGE = im.kind == BEAD ? 0.F : t - im.birth;
        if (AGE < 0 || AGE > LIVES[im.kind] || !Gl::ready(paneProgram))
            return;
        const double S    = m->m_scale;
        const double EXT  = im.kind == BEAD ? im.size * 6 : im.size;
        const auto   AREA = Gl::areaOf(CBox{im.at.x - EXT, im.at.y - EXT, 2 * EXT, 2 * EXT}.scale(S).round(), std::nullopt);
        if (!AREA)
            return;
        auto& p = paneProgram;
        g_pHyprOpenGL->useShader(p.shader);
        stampPane();
        glUniform4f(p["drawn"], AREA->drawn.x, AREA->drawn.y, AREA->drawn.w, AREA->drawn.h);
        glUniform1f(p["pass"], 2.F);
        glUniform1f(p["scale"], S);
        glUniform1f(p["t"], t);
        glUniform1f(p["seed"], s.seed);
        glUniform4f(p["impact"], im.at.x * S, im.at.y * S, AGE, float(im.kind));
        glUniform4f(p["impactAxis"], im.axis.x, im.axis.y, im.strength, im.size);
        Gl::paint(p, *AREA);
    }

    void drawStruck(const SScene& s, float t, const PHLMONITOR& m) {
        const float AGE = t - s.boom;
        if (AGE < 0 || s.struck.empty() || !Gl::ready(paneProgram))
            return;
        const double   S      = m->m_scale;
        const Vector2D C      = (s.j0 + s.j1) / 2;
        const double   W      = waveAt(s, AGE);
        const float    K      = std::exp(-AGE / float(FADE));
        auto&          p      = paneProgram;
        auto&          rd     = Gl::ctx->m_data;
        const CRegion  DAMAGE = rd.damage.copy();
        for (const auto& w : Desktop::windowState()->windows())
            if (validMapped(w) && w->isFloating() && w->m_workspace == s.workspace.lock())
                carve(boxOf(w).translate(-m->m_position).expand(16), m);
        for (const auto& st : s.struck) {
            const auto WIN = st.window.lock();
            if (!WIN || !validMapped(WIN) || Mullion::holds(WIN))
                continue;
            const CBox BOX = boxOf(WIN).translate(-m->m_position);
            if (W < nearest(C, BOX) - 40 || W > farthest(C, BOX) + 40)
                continue;
            const auto AREA = Gl::areaOf(BOX.copy().expand(16).scale(S).round(), std::nullopt);
            if (!AREA)
                continue;
            g_pHyprOpenGL->useShader(p.shader);
            stampPane();
            glUniform4f(p["drawn"], AREA->drawn.x, AREA->drawn.y, AREA->drawn.w, AREA->drawn.h);
            glUniform1f(p["pass"], 4.F);
            glUniform1f(p["scale"], S);
            glUniform4f(p["pane"], BOX.x * S, BOX.y * S, BOX.w * S, BOX.h * S);
            glUniform1f(p["radius"], WIN->presentation().rounding() * S);
            glUniform4f(p["shock"], C.x * S, C.y * S, W * S, K * (1.F + 0.6F * s.heat));
            Gl::paint(p, *AREA);
        }
        rd.damage = DAMAGE;
    }

    void drawBrick(const SPose& ps, const PHLMONITOR& m) {
        if (ps.opacity < 0.003F || ps.len < 1 || !Gl::ready(brickProgram))
            return;
        const double S    = m->m_scale;
        const double EXT  = ps.len / 2 + 40;
        const auto   AREA = Gl::areaOf(CBox{ps.pos.x - EXT, ps.pos.y - EXT, 2 * EXT, 2 * EXT}.scale(S).round(), std::nullopt);
        if (!AREA)
            return;
        auto&       p = brickProgram;
        const auto& P = pal();
        g_pHyprOpenGL->useShader(p.shader);
        if (p.stamp.first != &P) {
            p.stamp = {&P, 0};
            Gl::rgb(p, "base", P.metalBase);
            Gl::rgb(p, "hi", P.metalHi);
            Gl::rgb(p, "low", P.metalLow);
            Gl::rgb(p, "sky", P.metalSky);
            Gl::rgb(p, "pearl", P.pearl);
            Gl::rgb(p, "hot", P.hot);
            Gl::rgb(p, "sepia", hue().sepia);
            Gl::rgb(p, "leaf", hue().leaf);
            glUniform1f(p["ink"], hue().inked);
        }
        const auto L = worldLightOn(m) * S;
        glUniform4f(p["drawn"], AREA->drawn.x, AREA->drawn.y, AREA->drawn.w, AREA->drawn.h);
        glUniform2f(p["pos"], ps.pos.x * S, ps.pos.y * S);
        glUniform2f(p["out2"], ps.out.x, ps.out.y);
        glUniform1f(p["len"], ps.len * S);
        glUniform1f(p["tumble"], ps.tumble);
        glUniform1f(p["lift"], ps.lift);
        glUniform1f(p["fresh"], ps.fresh);
        glUniform1f(p["land"], ps.land);
        glUniform1f(p["fade"], 1.F);
        glUniform1f(p["haloGain"], 0.45F);
        glUniform1f(p["landGain"], 0.6F);
        glUniform1f(p["scale"], S);
        glUniform1f(p["opacity"], ps.opacity);
        Gl::rgb(p, "jewel", ps.tone == 0 ? P.jewelA : (ps.tone == 1 ? P.jewelB : P.jewelC));
        glUniform4f(p["lightPos"], L.x, L.y, 520.F * S, 640.F * S);
        Gl::paint(p, *AREA);
    }
}
