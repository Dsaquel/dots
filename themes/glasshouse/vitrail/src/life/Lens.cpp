#include "life/Internal.hpp"

using namespace Life;

namespace Life {
    struct SPortal {
        SP<Render::ITexture> tex;
        Vector2D             texSize;
        CBox                 drawn, foot;
        float                radius = 0, came = 0, t = 0, seed = 0, pass = 0;
    };

    void drawPortal(const SPortal& o, const PHLMONITOR& m) {
        const auto AREA = Gl::areaOf(o.drawn, std::nullopt);
        if (!AREA || !o.tex || !Gl::ready(portalProgram))
            return;
        auto&       p = portalProgram;
        const auto& P = pal();
        const auto& U = hue();
        g_pHyprOpenGL->useShader(p.shader);
        if (p.stamp.first != &P) {
            p.stamp = {&P, 0};
            glUniform1i(p["tex"], 0);
            Gl::rgb(p, "gold", U.gold);
            Gl::rgb(p, "hot", P.hot);
            Gl::rgb(p, "jewelA", P.jewelA);
            Gl::rgb(p, "jewelB", P.jewelB);
            Gl::rgb(p, "jewelC", P.jewelC);
            Gl::rgb(p, "leadLow", P.metalLow);
            Gl::rgb(p, "leadHi", P.metalHi);
            Gl::rgb(p, "sepia", U.sepia);
            Gl::rgb(p, "leaf", U.leaf);
            glUniform1f(p["ink"], U.inked);
        }
        const auto L = lightPx(m);
        glUniform2f(p["texSize"], o.texSize.x, o.texSize.y);
        glUniform4f(p["drawn"], AREA->drawn.x, AREA->drawn.y, AREA->drawn.w, AREA->drawn.h);
        glUniform4f(p["foot"], o.foot.x, o.foot.y, o.foot.w, o.foot.h);
        glUniform1f(p["radius"], o.radius);
        glUniform1f(p["came"], o.came);
        glUniform1f(p["scale"], m->m_scale);
        glUniform1f(p["t"], o.t);
        glUniform1f(p["seed"], o.seed);
        glUniform1f(p["pass"], o.pass);
        glUniform2f(p["lamp"], L.x, L.y);
        Gl::bindTex(0, o.tex);
        Gl::paint(p, *AREA);
        Gl::bindTex(0, nullptr);
    }

    void drawEmbers(const SPortal& o, const PHLMONITOR& m) {
        const double S    = m->m_scale;
        auto&        rd   = Gl::ctx->m_data;
        const auto   AREA = Gl::areaOf(CBox{{}, rd.pMonitor->m_transformedSize}, std::nullopt);
        if (!AREA || !Gl::ready(emberProgram))
            return;
        const int   COUNT = std::clamp(int(std::min(o.foot.w, o.foot.h) / S * SPARKS), 3000, 12000);
        auto&       p     = emberProgram;
        const auto& P     = pal();
        const auto& U     = hue();
        g_pHyprOpenGL->useShader(p.shader);
        CBox whole{0, 0, double(rd.pMonitor->m_pixelSize.x), double(rd.pMonitor->m_pixelSize.y)};
        rd.renderModif.applyToBox(whole);
        p.shader->setUniformMatrix3fv(SHADER_PROJ, 1, GL_TRUE, g_pHyprRenderer->projectBoxToTarget(*Gl::ctx, whole).getMatrix());
        glUniform2f(p["target"], rd.pMonitor->m_pixelSize.x, rd.pMonitor->m_pixelSize.y);
        glUniform1f(p["t"], o.t);
        glUniform4f(p["box"], o.foot.x, o.foot.y, o.foot.w, o.foot.h);
        glUniform1f(p["radius"], o.radius);
        glUniform1f(p["came"], o.came);
        glUniform1f(p["scale"], S);
        glUniform1f(p["count"], COUNT);
        glUniform1f(p["seed"], o.seed);
        Gl::rgb(p, "jewelA", P.jewelA);
        Gl::rgb(p, "jewelB", P.jewelB);
        Gl::rgb(p, "jewelC", P.jewelC);
        Gl::rgb(p, "hot", P.hot);
        Gl::rgb(p, "sepia", U.sepia);
        glUniform1f(p["ink"], U.inked);
        glBindVertexArray(p.shader->getUniformLocation(SHADER_SHADER_VAO));
        AREA->region.forEachRect([&rd, COUNT](const auto& RECT) {
            g_pHyprOpenGL->scissor(*Gl::ctx, &RECT, rd.transformDamage);
            glDrawArrays(GL_TRIANGLES, 0, COUNT * 6);
        });
        glBindVertexArray(0);
        g_pHyprOpenGL->disableScissor();
    }

    SP<Render::IFramebuffer> matteOf(const SP<Render::IFramebuffer>& in, const SP<Render::IFramebuffer>& out, const SPortal& o) {
        const auto MON = Gl::ctx->m_data.pMonitor.lock();
        const auto TMP = MON && MON->resources() ? MON->resources()->getUnusedWorkBuffer() : nullptr;
        if (!in || !in->getTexture() || !TMP || !TMP->isAllocated())
            return in;
        const CBox WHOLE{{}, MON->m_transformedSize};
        const CBox FOOT = o.foot.copy().expand(2);
        g_pHyprOpenGL->blend(false);
        if (out && out->getTexture()) {
            {
                auto guard = g_pHyprRenderer->bindTempFB(*Gl::ctx, TMP);
                g_pHyprRenderer->disableScissor();
                drawContent(SContent{.tex = out->getTexture(), .texSize = out->m_size, .drawn = FOOT, .win = FOOT, .radius = 0, .t = 0, .mode = 4}, MON);
            }
            auto guard = g_pHyprRenderer->bindTempFB(*Gl::ctx, out);
            auto s     = o;
            s.tex      = TMP->getTexture();
            s.texSize  = TMP->m_size;
            s.drawn    = FOOT;
            s.pass     = 2;
            drawPortal(s, MON);
        }
        {
            auto guard = g_pHyprRenderer->bindTempFB(*Gl::ctx, TMP);
            g_pHyprRenderer->disableScissor();
            auto s    = o;
            s.tex     = in->getTexture();
            s.texSize = in->m_size;
            s.drawn   = WHOLE;
            s.pass    = 1;
            drawPortal(s, MON);
        }
        g_pHyprOpenGL->blend(true);
        return TMP;
    }
}

CLens::CLens(PHLWINDOW window) : m_window(window) {
    ;
}

void CLens::preWindowRender(Render::CRenderContext& ctx, CSurfacePassElement::SRenderData* data) {
    m_calls  = 0;
    m_portal = false;
    m_stash.reset();
    m_out.reset();
}

void CLens::stash(CGlassPass::SData&& data) {
    m_stash = std::move(data);
}

CBox CLens::transformedExtents(const CBox& currentBox) const {
    const auto W   = m_window.lock();
    const auto MON = W ? W->m_monitor.lock() : nullptr;
    return MON ? CBox{{}, MON->m_size} : currentBox;
}

CBox CLens::transformBoxForDamage(const CBox& currentBox) const {
    return currentBox;
}

Render::SWindowTransformBuffer CLens::transform(Render::CRenderContext& ctx, const Render::SWindowTransformBuffer& in, const Render::SWindowTransformContext& context) {
    auto       scope = ctx.saveDrawState();
    const auto WIDE  = Gl::widen(ctx, in);
    return WIDE ? Gl::whole(paint(WIDE)) : in;
}

SP<Render::IFramebuffer> CLens::paint(SP<Render::IFramebuffer> in) {
    if (m_calls++ > 0) {
        const auto OUT = m_out.lock();
        m_out.reset();
        if (m_calls == 2 && m_portal)
            return matteOf(in, OUT, SPortal{.foot = m_win, .radius = m_radius, .came = m_came, .t = m_t, .seed = m_seed});
        if (m_calls == 2)
            straighten(OUT, m_win, m_radius, Gl::ctx->m_data.pMonitor.lock());
        return in;
    }
    if (!in || !in->getTexture())
        return in;
    const auto  W     = m_window.lock();
    auto* const FRAME = W ? CGlassFrame::of(W) : nullptr;
    const auto  MON   = Gl::ctx->m_data.pMonitor.lock();
    const auto  OUT   = MON && MON->resources() ? MON->resources()->getUnusedWorkBuffer() : nullptr;
    if (!FRAME || !OUT || !OUT->isAllocated())
        return in;
    const STimer TIMER;

    const float  T     = std::max(0.F, FRAME->paceMs());
    const double S     = MON->m_scale;
    const CBox   BOX   = boxOf(W).translate(-MON->m_position);
    const CBox   WIN   = BOX.copy().scale(S).round();
    const auto   PEER  = FRAME->peer();
    const bool   SHARE = FRAME->role() == CGlassFrame::ROLE_BORN && validMapped(PEER);
    if (FRAME->role() == CGlassFrame::ROLE_BORN && !SHARE) {
        const SPortal PORTAL{.tex     = in->getTexture(),
                             .texSize = in->m_size,
                             .drawn   = CBox{{}, MON->m_transformedSize},
                             .foot    = WIN,
                             .radius  = float(W->presentation().rounding() * S),
                             .came    = float(cameFor(W, BOX) * S),
                             .t       = T,
                             .seed    = m_stash ? m_stash->athanor[1] : m_seed};
        auto&         rd     = Gl::ctx->m_data;
        const CRegion DAMAGE = rd.damage.copy();
        rd.damage            = CRegion{CBox{{}, MON->m_transformedSize}};
        if (m_stash) {
            auto guard = g_pHyprRenderer->bindTempFB(*Gl::ctx, in);
            CGlassPass(std::move(*m_stash)).paint();
            m_stash.reset();
        }
        {
            auto guard = g_pHyprRenderer->bindTempFB(*Gl::ctx, OUT);
            g_pHyprRenderer->disableScissor();
            glClearColor(0.F, 0.F, 0.F, 0.F);
            glClear(GL_COLOR_BUFFER_BIT);
            g_pHyprOpenGL->blend(true);
            drawPortal(PORTAL, MON);
            drawEmbers(PORTAL, MON);
            Gl::unbindAll();
        }
        rd.damage = DAMAGE;
        g_pHyprOpenGL->blend(true);
        m_out    = OUT;
        m_win    = WIN;
        m_radius = PORTAL.radius;
        m_came   = PORTAL.came;
        m_portal = true;
        m_t      = T;
        m_seed   = PORTAL.seed;
        return OUT;
    }
    {
        auto guard = g_pHyprRenderer->bindTempFB(*Gl::ctx, OUT);
        g_pHyprRenderer->disableScissor();
        glClearColor(0.F, 0.F, 0.F, 0.F);
        glClear(GL_COLOR_BUFFER_BIT);
        g_pHyprOpenGL->blend(true);

        SContent c{.tex = in->getTexture(), .texSize = in->m_size, .drawn = W->getFullWindowBoundingBox().translate(shiftOf(W) - MON->m_position).expand(4).scale(S).round(),
                   .win = WIN, .radius = float(W->presentation().rounding() * S), .t = T, .mode = 1, .seed = float(BOX.w * 0.13 + BOX.h * 0.07)};
        if (FRAME->role() == CGlassFrame::ROLE_RECEIVER && FRAME->side() >= 0) {
            const int      SIDE = FRAME->side();
            const Vector2D AWAY{SIDE == 1 ? 1.0 : (SIDE == 3 ? -1.0 : 0.0), SIDE == 2 ? 1.0 : (SIDE == 0 ? -1.0 : 0.0)};
            const Vector2D EDGE = BOX.middle() + Vector2D{AWAY.x * BOX.w / 2, AWAY.y * BOX.h / 2};
            c.mode              = 5;
            c.t                 = FRAME->syncMs() - SLAM;
            c.origin            = {float(EDGE.x * S), float(EDGE.y * S), float(AWAY.x), float(AWAY.y)};
            c.span              = float((SIDE % 2 == 1 ? BOX.w : BOX.h) * S);
            c.timing            = {float(SHOCKV * S), float(SHOCKW * S), float(SHOCKA * S), 0.F};
        } else if (FRAME->role() != CGlassFrame::ROLE_BORN)
            c.t = 1e5F;
        else {
            const int    SIDE = (FRAME->side() + 2) % 4;
            const SRing  RING(BOX, W->presentation().rounding());
            const auto   AT   = RING.at(RING.mid(FRAME->side()), 0);
            const double DX = SIDE == 1 ? 1 : (SIDE == 3 ? -1 : 0), DY = SIDE == 2 ? 1 : (SIDE == 0 ? -1 : 0);
            c.origin = {float(AT.x * S), float(AT.y * S), float(DX), float(DY)};
            c.span   = float((DX != 0 ? BOX.w : BOX.h) * S);
            c.timing = {70.F, 420.F, 120.F, 40.F};
            c.cell   = Vector2D{std::clamp(BOX.w / 18, 36.0, 52.0), std::clamp(BOX.h / 13, 54.0, 78.0)} * S;
        }
        drawContent(c, MON);
        if (m_stash) {
            CGlassPass(std::move(*m_stash)).paint();
            m_stash.reset();
        }
        if (SHARE) {
            const CBox   G    = boxOf(PEER).translate(-MON->m_position);
            const int    SIDE = (FRAME->side() + 2) % 4;
            const SRing  RING(BOX, W->presentation().rounding());
            const double CAME = cameFor(PEER, G);
            const auto   A = sideSeg(G, SIDE, CAME, true), B = sideSeg(G, SIDE, CAME, false);
            drawFlight(SFlight{.a = A, .b = B, .box = BOX, .radius = W->presentation().rounding(), .at = RING.mid(FRAME->side()), .off = (cameFor(W, BOX) + 1.2) / 2,
                               .count = std::clamp(int(std::round(std::hypot(B.x - A.x, B.y - A.y) / 72)), 2, 28), .seed = float(BOX.w * 0.31 + BOX.h * 0.17)},
                       T, MON);
        }
        Gl::unbindAll();
    }
    g_pHyprOpenGL->blend(true);
    m_out    = OUT;
    m_win    = WIN;
    m_radius = float(W->presentation().rounding() * S);
    return OUT;
}
