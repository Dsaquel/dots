#include "translation/Internal.hpp"

namespace Translation {
    SP<Render::IFramebuffer> copyOf(const PHLMONITOR& m, bool make) {
        const auto IT = std::ranges::find_if(copies, [&m](const SCopy& g) { return g.monitor.lock() == m; });
        if (IT != copies.end() && IT->fb->m_size == m->m_pixelSize)
            return IT->fb;
        if (!make)
            return nullptr;
        auto fb = g_pHyprRenderer->createFB("vitrail copy");
        fb->alloc(m->m_pixelSize.x, m->m_pixelSize.y, DRM_FORMAT_ABGR8888);
        fb->setImageDescription(m->workBufferImageDescription());
        {
            auto guard = g_pHyprRenderer->bindTempFB(*Gl::ctx, fb);
            g_pHyprRenderer->disableScissor();
            glClearColor(0.F, 0.F, 0.F, 0.F);
            glClear(GL_COLOR_BUFFER_BIT);
        }
        if (IT != copies.end())
            IT->fb = fb;
        else
            copies.push_back({.monitor = m, .fb = fb});
        return fb;
    }

    void keep(const SP<Render::IFramebuffer>& in, const PHLWINDOW& w, const PHLMONITOR& m) {
        if (Gl::ctx->m_renderingSnapshot)
            return;
        const auto FB   = copyOf(m, true);
        const auto AREA = Gl::areaOf(boxOf(w).translate(-m->m_position).scale(m->m_scale).round().expand(2), std::nullopt);
        if (!FB || !FB->isAllocated() || !AREA)
            return;
        auto& p     = veilProgram;
        auto  guard = g_pHyprRenderer->bindTempFB(*Gl::ctx, FB);
        g_pHyprOpenGL->blend(false);
        g_pHyprOpenGL->useShader(p.shader);
        glUniform1i(p["tex"], 0);
        glUniform1f(p["copy"], 1.F);
        glUniform2f(p["texSize"], in->m_size.x, in->m_size.y);
        glUniform4f(p["drawn"], AREA->drawn.x, AREA->drawn.y, AREA->drawn.w, AREA->drawn.h);
        Gl::bindTex(0, in->getTexture());
        Gl::paint(p, *AREA);
        Gl::bindTex(0, nullptr);
        g_pHyprOpenGL->blend(true);
    }

    class CVeil : public Gl::CTransformer {
      public:
        CVeil(const SCarry* carry) : m_carry(carry) {}

        virtual void preWindowRender(Render::CRenderContext& ctx, CSurfacePassElement::SRenderData* data) override {
            m_calls = 0;
        }

        virtual Render::SWindowTransformBuffer transform(Render::CRenderContext& ctx, const Render::SWindowTransformBuffer& in, const Render::SWindowTransformContext& context) override {
            auto       scope = ctx.saveDrawState();
            const auto WIDE  = Gl::widen(ctx, in);
            return WIDE ? Gl::whole(paint(WIDE, m_calls++ == 0)) : in;
        }

      private:
        SP<Render::IFramebuffer> paint(SP<Render::IFramebuffer> in, bool first) {
            const auto MON = Gl::ctx->m_data.pMonitor.lock();
            const auto W   = m_carry->window.lock();
            const auto OUT = MON && MON->resources() ? MON->resources()->getUnusedWorkBuffer() : nullptr;
            if (!in || !in->getTexture())
                return in;
            const bool LIVE  = W && OUT && OUT->isAllocated() && m_carry->base < SHUT && Gl::ready(veilProgram);
            // Hyprland runs the transformers a second time on the window's white silhouette, its blur mask: only the first call carries the pixels
            if (LIVE && first && (m_carry->kind == eKind::PIVOT || m_carry->kind == eKind::SWAP))
                keep(in, W, MON);
            auto       guard = g_pHyprRenderer->bindTempFB(*Gl::ctx, LIVE ? OUT : in);
            g_pHyprRenderer->disableScissor();
            glClearColor(0.F, 0.F, 0.F, 0.F);
            glClear(GL_COLOR_BUFFER_BIT);
            if (!LIVE)
                return in;
            const double S    = MON->m_scale;
            const CBox   WIN  = boxOf(W).translate(-MON->m_position).scale(S).round();
            const auto   AREA = Gl::areaOf(WIN.copy().expand(2), std::nullopt);
            if (!AREA)
                return OUT;
            auto&          p    = veilProgram;
            const bool     TURN = m_carry->kind == eKind::PIVOT;
            const Vector2D PIV  = (m_carry->pivot - MON->m_position) * S;
            g_pHyprOpenGL->blend(true);
            g_pHyprOpenGL->useShader(p.shader);
            glUniform1i(p["tex"], 0);
            glUniform1i(p["perm"], 1);
            glUniform1f(p["copy"], 0.F);
            glUniform2f(p["texSize"], in->m_size.x, in->m_size.y);
            glUniform4f(p["drawn"], AREA->drawn.x, AREA->drawn.y, AREA->drawn.w, AREA->drawn.h);
            glUniform4f(p["win"], WIN.x, WIN.y, WIN.w, WIN.h);
            glUniform1f(p["turn"], TURN ? 1.F : 0.F);
            glUniform2f(p["pivot"], PIV.x, PIV.y);
            glUniform3f(p["ring"], m_carry->far * S, SLAM, SHOCK);
            glUniform2f(p["grid"], m_carry->lattice.x, m_carry->lattice.y);
            glUniform1f(p["t"], ms(*m_carry));
            glUniform1f(p["base"], m_carry->base);
            glUniform1f(p["reveal"], TURN || m_carry->kind == eKind::SWAP ? REGLAZE : REVEAL);
            bindGates(p, *m_carry, MON->m_position, S);
            Gl::bindTex(0, in->getTexture());
            bindPerm(1, m_carry->perm);
            Gl::paint(p, *AREA);
            bindPerm(1, 0);
            Gl::bindTex(0, nullptr);
            return OUT;
        }

        const SCarry* m_carry;
        int           m_calls = 0;
    };

    bool touches(const SCarry& c, const PHLMONITOR& m) {
        const auto W = c.window.lock();
        return c.from.lock() == m || (W && W->m_monitor.lock() == m);
    }

    void unveil(SCarry& c) {
        const auto W = c.window.lock();
        if (W && c.veil) {
            Gl::drop(W, c.veil);
            g_pHyprRenderer->damageWindow(W);
        }
        c.veil = nullptr;
    }

    std::string addressOf(const PHLWINDOW& w) {
        return w ? std::format("{:x}", rc<uintptr_t>(w.get())) : std::string{};
    }

    SCarry* launch(const PHLWINDOW& w, const PHLMONITOR& mon, const SP<Render::IFramebuffer>& snap, eKind kind, const std::optional<CBox>& was) {
        auto       c   = makeUnique<SCarry>();
        const auto BOX = was.value_or(boxOf(w));
        c->window      = w;
        c->from        = mon;
        c->kind        = kind;
        c->source      = BOX;
        c->goal        = w->geometricBox(GEO::GEOMETRIC_GOAL);
        c->shot        = BOX.copy().translate(-mon->m_position).scale(mon->m_scale).round();
        c->grid        = latticeOf(BOX);
        c->radius      = float(w->presentation().rounding());
        c->seed        = std::fmod(secondsAlive() * 7.31F, 61.F);
        c->snapshot    = snap;
        c->veil        = w->effects().transformers()->emplace<CVeil>(c.get());

        Animation::mgr()->createAnimation(0.F, c->clock, vitrailClock(CLOCK), AVARDAMAGE_NONE);
        const PHLWINDOWREF  WIN  = w;
        const PHLMONITORREF FROM = mon;
        c->clock->setUpdateCallback([WIN, FROM](auto) {
            if (const auto M = FROM.lock())
                g_pHyprRenderer->damageMonitor(M);
            if (const auto W = WIN.lock())
                if (const auto M = W->m_monitor.lock(); M && M != FROM.lock())
                    g_pHyprRenderer->damageMonitor(M);
        });
        c->clock->setValueAndWarp(0.F);
        *c->clock = 1.F;
        g_pHyprRenderer->damageMonitor(mon);
        return flights.emplace_back(std::move(c)).get();
    }

    SP<Render::IFramebuffer> shoot(const PHLWINDOW& w, eShot kind) {
        g_glass->shooting = kind;
        const auto SNAP   = g_pHyprRenderer->makeSnapshotFB(w);
        g_glass->shooting = eShot::NONE;
        return SNAP && SNAP->getTexture() ? SNAP : nullptr;
    }
}
