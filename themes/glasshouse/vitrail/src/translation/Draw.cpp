#include "translation/Internal.hpp"

namespace Translation {
    void drawFrame(const SCarry& c, const PHLWINDOW& w, const PHLMONITOR& m) {
        auto* const F = c.framed && w->m_monitor.lock() == m ? CGlassFrame::of(w) : nullptr;
        if (auto data = F ? F->build(m, 1.F) : std::nullopt)
            CGlassPass(std::move(*data)).paint();
    }

    void drawSeat(const PHLWINDOW& w, float t, const PHLMONITOR& m) {
        const float IN   = std::clamp((t - SLAM) / 80, 0.F, 1.F);
        const float K    = std::clamp((t - SEATING) / (SEATED - SEATING), 0.F, 1.F);
        const float SEAT = K * K * (3 - 2 * K);
        const float D    = std::clamp((t - DIMMING) / (SEATED - DIMMING), 0.F, 1.F);
        auto* const F    = IN > 0 && w->m_monitor.lock() == m ? CGlassFrame::of(w) : nullptr;
        auto        data = F ? F->build(m, IN) : std::nullopt;
        if (!data)
            return;
        for (auto& pc : data->pieces) {
            pc.grow *= SEAT;
            pc.opacity *= SEAT;
        }
        data->plate.opacity *= SEAT;
        data->plate.stream *= SEAT;
        data->veil *= D * D * (3 - 2 * D);
        CGlassPass(std::move(*data)).paint();
    }

    void drawLift(const SCarry& c, float t) {
        if (t >= LIFT || !c.ornate)
            return;
        const float K    = std::max(t, 0.F) / LIFT;
        auto        data = *c.ornate;
        data.alpha *= 1 - K * K;
        for (auto& pc : data.pieces) {
            pc.origin.y -= 14 * K;
            pc.opacity *= 1 - K;
        }
        data.plate.pos.y -= 14 * K;
        data.plate.opacity *= 1 - K;
        CGlassPass(std::move(data)).paint();
    }

    void drawHusk(const SCarry& c, float t, const PHLMONITOR& m) {
        const float HUSK_MS = c.kind == eKind::TRANSLATE ? HUSKED : SHED;
        if (t >= HUSK_MS || !Gl::ready(huskProgram))
            return;
        const double S    = m->m_scale;
        const auto   AREA = Gl::areaOf(c.shot.copy().expand(CGlassFrame::MARGIN * S).round(), std::nullopt);
        if (!AREA)
            return;
        auto& p = huskProgram;
        g_pHyprOpenGL->useShader(p.shader);
        glUniform1i(p["tex"], 0);
        glUniform2f(p["texSize"], c.snapshot->m_size.x, c.snapshot->m_size.y);
        glUniform4f(p["drawn"], AREA->drawn.x, AREA->drawn.y, AREA->drawn.w, AREA->drawn.h);
        glUniform4f(p["win"], c.shot.x, c.shot.y, c.shot.w, c.shot.h);
        glUniform1f(p["radius"], c.radius * S);
        glUniform1f(p["scale"], S);
        glUniform1f(p["t"], t);
        glUniform1f(p["husk"], HUSK_MS);
        glUniform1f(p["seed"], c.seed);
        Gl::rgb(p, "hot", hue().hot);
        Gl::rgb(p, "keyline", pal().dark ? hue().gold : hue().leaf);
        glUniform1f(p["ink"], hue().inked);
        Gl::bindTex(0, c.snapshot->getTexture());
        Gl::paint(p, *AREA);
        Gl::bindTex(0, nullptr);
    }

    void project(Gl::SProgram& p, const PHLMONITOR& m) {
        auto& rd = Gl::ctx->m_data;
        CBox  whole{0, 0, m->m_pixelSize.x, m->m_pixelSize.y};
        rd.renderModif.applyToBox(whole);
        p.shader->setUniformMatrix3fv(SHADER_PROJ, 1, GL_TRUE, g_pHyprRenderer->projectBoxToTarget(*Gl::ctx, whole.translate(Gl::nudge)).getMatrix());
        glUniform2f(p["target"], m->m_pixelSize.x, m->m_pixelSize.y);
        glUniform3f(p["screen"], m->m_position.x, m->m_position.y, m->m_scale);
    }

    void strokes(Gl::SProgram& p, const Gl::SArea& area, int count) {
        auto& rd = Gl::ctx->m_data;
        glBindVertexArray(p.shader->getUniformLocation(SHADER_SHADER_VAO));
        area.region.forEachRect([&rd, count](const auto& RECT) {
            g_pHyprOpenGL->scissor(*Gl::ctx, &RECT, rd.transformDamage);
            glDrawArrays(GL_TRIANGLES, 0, count);
        });
        glBindVertexArray(0);
        g_pHyprOpenGL->disableScissor();
    }

    size_t depthOf(const PHLWINDOW& w) {
        const auto& ALL = Desktop::windowState()->windows();
        return size_t(std::ranges::find(ALL, w) - ALL.begin()) + (w->isFloating() ? ALL.size() : 0);
    }

    std::optional<Gl::SArea> areaBelow(const CBox& phys, const PHLWINDOW& w, const PHLMONITOR& m) {
        auto area = Gl::areaOf(phys, std::nullopt);
        if (!area)
            return area;
        const size_t DEPTH = depthOf(w);
        for (const auto& x : Desktop::windowState()->windows()) {
            if (x == w || !x->isFloating() || !validMapped(x) || x->isHidden() || x->m_monitor.lock() != m || (x->m_workspace != w->m_workspace && !isPinned(x)) || depthOf(x) < DEPTH)
                continue;
            CBox box = boxOf(x).translate(-m->m_position).scale(m->m_scale).round();
            Gl::ctx->m_data.renderModif.applyToBox(box);
            area->region.subtract(CRegion{box});
        }
        return area->region.empty() ? std::nullopt : area;
    }

    void drawQuarries(const SCarry& c, const PHLWINDOW& w, float t, const PHLMONITOR& m, bool shuffled, std::span<const std::array<float, 3>> layers, float parity) {
        const CBox WHOLE{{}, m->m_pixelSize};
        const auto AREA = shuffled ? areaBelow(WHOLE, w, m) : Gl::areaOf(WHOLE, std::nullopt);
        if (!AREA || !Gl::ready(quarryProgram))
            return;
        const auto&     P     = pal();
        const auto&     U     = hue();
        const bool      TURN  = c.kind == eKind::PIVOT;
        const bool      SWAPS = c.kind == eKind::SWAP;
        const CBox&     BOX   = shuffled && !TURN && !SWAPS ? c.goal : c.source;
        const Vector2D& GRID  = shuffled ? c.lattice : c.grid;
        const bool      FORMS_IN = c.kind == eKind::TRANSLATE;
        const auto      COPY     = TURN || SWAPS ? copyOf(m, false) : nullptr;
        auto&           p     = quarryProgram;
        g_pHyprOpenGL->useShader(p.shader);
        project(p, m);
        glUniform4f(p["shot"], c.shot.x, c.shot.y, c.shot.w, c.shot.h);
        glUniform4f(p["box"], BOX.x, BOX.y, BOX.w, BOX.h);
        glUniform2f(p["grid"], GRID.x, GRID.y);
        glUniform1f(p["t"], t);
        glUniform1f(p["base"], c.base);
        glUniform1f(p["mode"], SWAPS ? 3.F : TURN ? 2.F : shuffled ? 1.F : 0.F);
        glUniform1f(p["crack"], CRACK);
        glUniform1f(p["rift"], RIFT);
        glUniform2f(p["born"], FORMS_IN ? FORM : POP, FORMS_IN ? 0.25F : 0.75F);
        glUniform1f(p["reveal"], TURN || SWAPS ? REGLAZE : REVEAL);
        if (SWAPS) {
            glUniform4f(p["goal"], c.goal.x, c.goal.y, c.goal.w, c.goal.h);
            glUniform3f(p["swing"], std::max(SWING, c.ahead), SLAM, FLUSH);
            glUniform3f(p["ring"], c.far, SLAM, SHOCK);
            glUniform1f(p["ahead"], c.ahead);
            glUniform1f(p["parity"], parity);
            glUniform1f(p["ready"], std::clamp((t - c.fresh) / 30.F, 0.F, 1.F));
            Gl::rgb(p, "stream", c.rank % 2 ? U.jewel2 : P.dark ? U.jewel1 : U.jewel0);
            bindGates(p, c, {}, 1);
        }
        if (TURN) {
            double reach = 0;
            for (const auto& corner : {BOX.pos(), BOX.pos() + Vector2D{BOX.w, 0.0}, BOX.pos() + Vector2D{0.0, BOX.h}, BOX.pos() + BOX.size()})
                reach = std::max(reach, (corner.x - c.pivot.x) * c.oldDir.x + (corner.y - c.pivot.y) * c.oldDir.y);
            const CBox U = hullOf(c);
            glUniform4f(p["hull"], U.x, U.y, U.w, U.h);
            glUniform4f(p["hand"], c.pivot.x, c.pivot.y, c.sweep, c.sense);
            glUniform4f(p["hubs"], c.hubs[0].x, c.hubs[0].y, c.hubs[1].x, c.hubs[1].y);
            glUniform3f(p["swing"], SWING, SLAM, TWIST);
            glUniform1f(p["ahead"], c.ahead);
            glUniform1fv(p["skew"], SKEWS, c.skew.data());
            glUniform4f(p["flush"], c.oldDir.x, c.oldDir.y, reach, FLUSH);
        }
        glUniform1f(p["seed"], c.seed);
        glUniform2f(p["eye"], c.pair.middle().x, c.pair.middle().y);
        glUniform1i(p["tex"], 0);
        glUniform1i(p["perm"], 1);
        glUniform1i(p["copy"], 2);
        glUniform1f(p["mixing"], COPY ? 1.F : 0.F);
        glUniform2f(p["copySize"], COPY ? COPY->m_size.x : 1.0, COPY ? COPY->m_size.y : 1.0);
        glUniform2f(p["texSize"], c.snapshot->m_size.x, c.snapshot->m_size.y);
        glUniform1f(p["radius"], c.radius);
        Gl::rgb(p, "leadBase", P.metalBase);
        Gl::rgb(p, "leadHi", P.metalHi);
        Gl::rgb(p, "leadLow", P.metalLow);
        Gl::rgb(p, "keyline", P.dark ? U.gold : U.leaf);
        Gl::rgb(p, "hot", U.hot);
        Gl::rgb(p, "jewel0", U.jewel0);
        Gl::rgb(p, "jewel1", U.jewel1);
        Gl::rgb(p, "jewel2", U.jewel2);
        Gl::rgb(p, "sepia", U.sepia);
        glUniform1f(p["ink"], U.inked);
        Gl::bindTex(2, COPY ? COPY->getTexture() : c.snapshot->getTexture());
        Gl::bindTex(0, c.snapshot->getTexture());
        bindPerm(1, shuffled ? c.perm : 0);
        const int COUNT = int((GRID.x + GRID.y) * (GRID.x + GRID.y)) * 6;
        for (const auto& [LAYER, LAG, GHOST] : layers) {
            glUniform1f(p["layer"], LAYER);
            glUniform1f(p["trail"], LAG);
            glUniform1f(p["ghost"], GHOST);
            strokes(p, *AREA, COUNT);
        }
        bindPerm(1, 0);
        Gl::bindTex(2, nullptr);
        Gl::bindTex(0, nullptr);
    }
}
