#include "translation/Internal.hpp"

namespace Translation {
    void drawSparks(const SCarry& c, const PHLWINDOW& w, float t, const PHLMONITOR& m, eSpark kind) {
        const bool SOURCE = kind == CRACKS;
        const bool LOOSE  = kind >= TIPS;
        const CBox WHOLE{{}, m->m_pixelSize};
        const auto AREA = SOURCE || LOOSE ? Gl::areaOf(WHOLE, std::nullopt) : areaBelow(WHOLE, w, m);
        if (!AREA || !Gl::ready(sparkProgram))
            return;
        const CBox&     BOX    = SOURCE || kind == BREACH || (kind == MEND && c.kind == eKind::PIVOT) ? c.source : c.goal;
        const Vector2D& GRID   = SOURCE ? c.grid : c.lattice;
        const int       NU     = int(GRID.x + GRID.y);
        const int       COUNT  = kind == TIPS ? 2 * SPRAY : kind == BURST ? 2 * BURSTS : kind == GILT ? int(c.gilt.size()) * GILDED : kind == WHIP ? WHIPS : kind == STREAM ? STREAMS :
                                 kind == ZIP ? ZIPS : kind == BREACH ? BREACHES : kind == FLARE ? FLARES : kind == MEND ? (2 * (NU + 1) * (NU + 1) + 2 * LINKS) * STRIKES * DROPS : kind == CRACKS ? NU * NU :
                                 kind == WELDS ? (NU + 1) * (NU + 1) * 4 : NU * NU * 3;
        const auto&     U      = hue();
        auto&           p      = sparkProgram;
        g_pHyprOpenGL->useShader(p.shader);
        project(p, m);
        glUniform1f(p["kind"], float(kind));
        glUniform4f(p["box"], BOX.x, BOX.y, BOX.w, BOX.h);
        glUniform2f(p["grid"], GRID.x, GRID.y);
        glUniform1f(p["t"], t);
        glUniform1f(p["base"], c.base);
        glUniform1f(p["crack"], CRACK);
        glUniform2f(p["born"], FORM, 0.25F);
        glUniform4f(p["seal"], weldOf(c), WAVE, SEAM, WELD);
        glUniform1f(p["seed"], c.seed);
        glUniform1i(p["perm"], 0);
        Gl::rgb(p, "hot", U.hot);
        Gl::rgb(p, "dust", U.dust);
        Gl::rgb(p, "jewel0", U.jewel0);
        Gl::rgb(p, "jewel1", U.jewel1);
        Gl::rgb(p, "sepia", U.sepia);
        Gl::rgb(p, "leaf", U.leaf);
        glUniform1f(p["ink"], U.inked);
        if (LOOSE) {
            const CBox U = hullOf(c);
            glUniform4f(p["hand"], c.pivot.x, c.pivot.y, c.sweep, c.sense);
            glUniform4f(p["swing"], SWING, SLAM, FLUSH, TWIST);
            glUniform1f(p["ahead"], c.ahead);
            glUniform1fv(p["skew"], SKEWS, c.skew.data());
            glUniform4f(p["hull"], U.x, U.y, U.w, U.h);
            glUniform4f(p["hubs"], c.hubs[0].x, c.hubs[0].y, c.hubs[1].x, c.hubs[1].y);
            if (!c.gilt.empty())
                glUniform4fv(p["gilt"], GLsizei(c.gilt.size()), c.gilt.front().data());
            glUniform1f(p["gilts"], float(c.gilt.size()));
            glUniform1f(p["stride"], float((c.goal.middle() - c.source.middle()).size()));
            glUniform4f(p["goal"], c.goal.x, c.goal.y, c.goal.w, c.goal.h);
            glUniform3f(p["ring"], c.far, SLAM, SHOCK);
            bindGates(p, c, {}, 1);
        }
        bindPerm(0, SOURCE ? 0 : c.perm);
        strokes(p, *AREA, COUNT * 6);
        bindPerm(0, 0);
    }

    void drawRifts(const SCarry& c, const PHLWINDOW& w, float t, const PHLMONITOR& m) {
        if (c.ahead < 0 && t < c.ahead + BREACHED)
            drawSparks(c, w, t, m, BREACH);
        if (c.lead && t >= SLAM && t < SLAM + FLARED)
            drawSparks(c, w, t, m, FLARE);
        if (t >= SLAM && t < SLAM + SHOCK + DUSTED)
            drawSparks(c, w, t, m, MEND);
    }

    std::array<float, 4> hubsOf(const SCarry& c, const PHLMONITOR& m) {
        const auto A = (c.hubs[0] - m->m_position) * m->m_scale, B = (c.hubs[1] - m->m_position) * m->m_scale;
        return {float(A.x), float(A.y), float(B.x), float(B.y)};
    }

    void drawWeld(const SCarry& c, const PHLWINDOW& w, float t, const PHLMONITOR& m, bool bolt) {
        const bool                 TURN = c.kind == eKind::PIVOT;
        const std::array<float, 4> SEAL = TURN || c.kind == eKind::SWAP ? std::array{SLAM, WAVED, SEAMED, COOLED} : std::array{weldOf(c), WAVE, SEAM, WELD};
        if ((bolt ? t < SLAM || t > SLAM + SHOCK + ARCING : t < c.base + c.first || t > SEAL[0] + SEAL[1] + SEAL[3]) || !Gl::ready(weldProgram))
            return;
        const double   S     = m->m_scale;
        const CBox     WIN   = boxOf(w).translate(-m->m_position).scale(S).round();
        const CBox     FRAME = TURN ? c.shot : WIN;
        const Vector2D PIV   = (c.pivot - m->m_position) * S;
        const CBox     HULL  = hullOf(c).translate(-m->m_position).scale(S);
        const auto     AREA  = areaBelow(WIN.copy().expand((bolt ? REACH : 2) * S).round(), w, m);
        if (!AREA)
            return;
        const auto& P = pal();
        const auto& U = hue();
        auto&       p = weldProgram;
        g_pHyprOpenGL->useShader(p.shader);
        glUniform1i(p["perm"], 0);
        glUniform4f(p["drawn"], AREA->drawn.x, AREA->drawn.y, AREA->drawn.w, AREA->drawn.h);
        glUniform4f(p["win"], WIN.x, WIN.y, WIN.w, WIN.h);
        glUniform1f(p["turn"], TURN ? 1.F : 0.F);
        glUniform4f(p["frame"], FRAME.x, FRAME.y, FRAME.w, FRAME.h);
        glUniform4f(p["hull"], HULL.x, HULL.y, HULL.w, HULL.h);
        glUniform4f(p["hand"], PIV.x, PIV.y, c.sweep, c.sense);
        glUniform4fv(p["hubs"], 1, hubsOf(c, m).data());
        glUniform3f(p["ring"], c.far * S, SLAM, SHOCK);
        glUniform2f(p["grid"], c.lattice.x, c.lattice.y);
        glUniform1f(p["radius"], c.radius * S);
        glUniform1f(p["scale"], S);
        glUniform1f(p["t"], t);
        glUniform1f(p["base"], c.base);
        glUniform4f(p["seal"], SEAL[0], SEAL[1], SEAL[2], SEAL[3]);
        glUniform1f(p["bolt"], bolt ? 1.F : 0.F);
        glUniform1f(p["seed"], c.seed);
        bindGates(p, c, m->m_position, S);
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
        bindPerm(0, c.perm);
        Gl::paint(p, *AREA);
        bindPerm(0, 0);
    }

    void drawHand(const SCarry& c, float t, const PHLMONITOR& m) {
        if (t >= SETTLED || !Gl::ready(pivotProgram))
            return;
        const double   S    = m->m_scale;
        const CBox     PAIR = c.pair.copy().translate(-m->m_position).scale(S);
        const CBox     HULL = hullOf(c).translate(-m->m_position).scale(S);
        const Vector2D PIV  = (c.pivot - m->m_position) * S;
        const auto     AREA = Gl::areaOf(PAIR.copy().expand(HALO * S).round(), std::nullopt);
        if (!AREA)
            return;
        const auto& P = pal();
        const auto& U = hue();
        auto&       p = pivotProgram;
        g_pHyprOpenGL->useShader(p.shader);
        glUniform4f(p["drawn"], AREA->drawn.x, AREA->drawn.y, AREA->drawn.w, AREA->drawn.h);
        glUniform4f(p["pair"], PAIR.x, PAIR.y, PAIR.w, PAIR.h);
        glUniform4f(p["hull"], HULL.x, HULL.y, HULL.w, HULL.h);
        glUniform1f(p["corner"], (c.radius + RIM) * S);
        glUniform1f(p["scale"], S);
        glUniform1f(p["t"], t);
        glUniform4f(p["hand"], PIV.x, PIV.y, c.sweep, c.sense);
        glUniform4fv(p["hubs"], 1, hubsOf(c, m).data());
        glUniform4f(p["times"], SWING, SLAM, SHOCK, c.far * S);
        glUniform1f(p["lag"], TWIST);
        glUniform1f(p["ahead"], c.ahead);
        glUniform1fv(p["skew"], SKEWS, c.skew.data());
        glUniform1f(p["bar"], std::max(c.gutter / 2 - RIM + 2.4F, 4.F) * S);
        Gl::rgb(p, "hot", U.hot);
        Gl::rgb(p, "jewel1", U.jewel1);
        Gl::rgb(p, "leadLow", P.metalLow);
        Gl::rgb(p, "leadBase", P.metalBase);
        Gl::rgb(p, "leadHi", P.metalHi);
        Gl::rgb(p, "sepia", U.sepia);
        Gl::rgb(p, "leaf", U.leaf);
        glUniform1f(p["ink"], U.inked);
        Gl::paint(p, *AREA);
    }

    void drawPool(const SCarry& c, const PHLWINDOW& w, float t, const PHLMONITOR& m) {
        if (t >= SLAM + SHOCK + REGLAZE || !Gl::ready(poolProgram))
            return;
        const double   S    = m->m_scale;
        const CBox     PAIR = c.pair.copy().translate(-m->m_position).scale(S);
        const CBox     HULL = hullOf(c).translate(-m->m_position).scale(S);
        const Vector2D PIV  = (c.pivot - m->m_position) * S;
        const auto     AREA = areaBelow(PAIR.copy().expand(2).round(), w, m);
        if (!AREA)
            return;
        const auto& P = pal();
        const auto& U = hue();
        auto&       p = poolProgram;
        g_pHyprOpenGL->useShader(p.shader);
        glUniform4f(p["drawn"], AREA->drawn.x, AREA->drawn.y, AREA->drawn.w, AREA->drawn.h);
        glUniform4f(p["pair"], PAIR.x, PAIR.y, PAIR.w, PAIR.h);
        glUniform4f(p["hull"], HULL.x, HULL.y, HULL.w, HULL.h);
        glUniform1f(p["corner"], (c.radius + RIM) * S);
        glUniform1f(p["scale"], S);
        glUniform1f(p["t"], t);
        glUniform4f(p["hand"], PIV.x, PIV.y, c.sweep, c.sense);
        glUniform4fv(p["hubs"], 1, hubsOf(c, m).data());
        glUniform4f(p["times"], c.kind == eKind::SWAP ? std::max(SWING, c.ahead) : SWING, SLAM, SHOCK, c.far * S);
        glUniform1f(p["lag"], TWIST);
        glUniform1f(p["ahead"], c.ahead);
        glUniform1fv(p["skew"], SKEWS, c.skew.data());
        glUniform1f(p["reveal"], REGLAZE);
        glUniform1f(p["seed"], c.seed);
        const Vector2D WAY  = c.goal.middle() - c.source.middle();
        const bool     WIDE = std::abs(WAY.x) >= std::abs(WAY.y);
        glUniform3f(p["lanes"], WIDE ? 1.F : 0.F, (WIDE ? c.goal.h / (2 * c.lattice.y) : c.goal.w / (2 * c.lattice.x)) * S, (WIDE ? c.goal.y - m->m_position.y : c.goal.x - m->m_position.x) * S);
        bindGates(p, c, m->m_position, S);
        Gl::rgb(p, "hot", U.hot);
        Gl::rgb(p, "gold", U.gold);
        Gl::rgb(p, "leadLow", P.metalLow);
        Gl::rgb(p, "leadBase", P.metalBase);
        Gl::rgb(p, "leadHi", P.metalHi);
        Gl::rgb(p, "sepia", U.sepia);
        Gl::rgb(p, "leaf", U.leaf);
        glUniform1f(p["ink"], U.inked);
        Gl::paint(p, *AREA);
    }

    void drawGate(const SCarry& c, float t, const PHLMONITOR& m) {
        if (t >= SETTLED || !Gl::ready(gateProgram))
            return;
        const double S    = m->m_scale;
        const CBox   PAIR = c.pair.copy().translate(-m->m_position).scale(S);
        const auto   AREA = Gl::areaOf(PAIR.copy().expand(HALO * S).round(), std::nullopt);
        if (!AREA)
            return;
        const auto& P = pal();
        const auto& U = hue();
        auto&       p = gateProgram;
        g_pHyprOpenGL->useShader(p.shader);
        glUniform4f(p["drawn"], AREA->drawn.x, AREA->drawn.y, AREA->drawn.w, AREA->drawn.h);
        glUniform4f(p["pair"], PAIR.x, PAIR.y, PAIR.w, PAIR.h);
        glUniform1f(p["corner"], (c.radius + RIM) * S);
        glUniform1f(p["scale"], S);
        glUniform1f(p["t"], t);
        glUniform4f(p["times"], std::max(SWING, c.ahead), SLAM, SHOCK, c.far * S);
        glUniform1f(p["ahead"], c.ahead);
        glUniform1f(p["bar"], std::max(c.gutter / 2 - RIM + 2.4F, 4.F) * S);
        bindGates(p, c, m->m_position, S);
        Gl::rgb(p, "hot", U.hot);
        Gl::rgb(p, "gold", U.gold);
        Gl::rgb(p, "jewel1", U.jewel1);
        Gl::rgb(p, "leadLow", P.metalLow);
        Gl::rgb(p, "leadBase", P.metalBase);
        Gl::rgb(p, "leadHi", P.metalHi);
        Gl::rgb(p, "sepia", U.sepia);
        Gl::rgb(p, "leaf", U.leaf);
        glUniform1f(p["ink"], U.inked);
        Gl::paint(p, *AREA);
    }
}
