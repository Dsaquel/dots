#include "translation/Internal.hpp"

namespace Translation {
    class CTranslationPass : public IPassElement {
      public:
        CTranslationPass(PHLMONITORREF monitor) : m_monitor(monitor) {}
        virtual ~CTranslationPass() = default;

        virtual std::vector<UP<IPassElement>> draw(Render::CRenderContext& ctx) override {

            Gl::ctx = &ctx;
            const auto MON = m_monitor.lock();
            if (!MON || Gl::ctx->m_data.pMonitor.lock() != MON)
                return {};
            std::vector<const SCarry*> order;
            for (const auto& c : flights)
                order.push_back(c.get());
            std::ranges::stable_sort(order, {}, [](const SCarry* c) {
                const auto W = c->window.lock();
                return std::pair{c->kind == eKind::TRANSLATE, W ? depthOf(W) : 0};
            });
            g_pHyprOpenGL->blend(true);
            for (const auto* c : order)
                if (const auto W = c->window.lock(); (c->kind == eKind::PIVOT || c->kind == eKind::SWAP) && c->lead && c->bed && c->armed && !c->landed && validMapped(W) &&
                    W->m_monitor.lock() == MON && c->snapshot)
                    drawPool(*c, W, ms(*c), MON);
            for (const auto* c : order)
                if (const auto W = c->window.lock(); (c->kind == eKind::PIVOT || c->kind == eKind::SWAP) && c->armed && !c->landed && c->base < SHUT && validMapped(W) &&
                    W->m_monitor.lock() == MON && c->snapshot && c->snapshot->getTexture())
                    drawQuarries(*c, W, ms(*c), MON, true, UMBRA);
            std::vector<const SCarry*> turns, swaps;
            for (const auto* c : order) {
                const auto W = c->window.lock();
                if (!c->armed || !validMapped(W) || !c->snapshot || !c->snapshot->getTexture())
                    continue;
                const float T = ms(*c);
                if (c->from.lock() == MON) {
                    if (c->kind == eKind::PIVOT || c->kind == eKind::SWAP)
                        drawLift(*c, T);
                    else
                        drawHusk(*c, T, MON);
                    if (c->kind == eKind::TRANSLATE && T < BROKEN) {
                        drawQuarries(*c, W, T, MON, false, std::span{PASSES}.first(1));
                        drawSparks(*c, W, T, MON, CRACKS);
                    }
                }
                if (c->base >= SHUT || W->m_monitor.lock() != MON)
                    continue;
                if (c->kind == eKind::SWAP) {
                    if (!c->landed && c->seats)
                        drawSeat(W, T, MON);
                    drawWeld(*c, W, T, MON);
                    swaps.push_back(c);
                    continue;
                }
                if (c->kind == eKind::PIVOT) {
                    if (!c->landed)
                        drawSeat(W, T, MON);
                    drawWeld(*c, W, T, MON);
                    if (!c->landed)
                        drawQuarries(*c, W, T, MON, true, std::span{TRAILS}.first(1));
                    turns.push_back(c);
                    continue;
                }
                if (!c->landed)
                    drawFrame(*c, W, MON);
                drawWeld(*c, W, T, MON);
                if (!c->landed)
                    drawQuarries(*c, W, T, MON, true, PASSES);
                if (c->kind == eKind::TRANSLATE && T >= c->base && T < c->base + FORMING + FORM)
                    drawSparks(*c, W, T, MON, FORMS);
                if (T >= c->base + c->first && T < c->base + c->last + 170)
                    drawSparks(*c, W, T, MON, SLAMS);
                if (T >= weldOf(*c))
                    drawSparks(*c, W, T, MON, WELDS);
            }
            std::ranges::stable_sort(turns, {}, [](const SCarry* c) { return c->lead; });
            for (const auto* c : turns)
                if (!c->landed)
                    drawQuarries(*c, c->window.lock(), ms(*c), MON, true, std::span{TRAILS}.subspan(1));
            for (const auto* c : turns) {
                const auto  W = c->window.lock();
                const float T = ms(*c);
                drawWeld(*c, W, T, MON, true);
                if (c->lead) {
                    drawHand(*c, T, MON);
                    if (T >= SWING && T < SLAM + 220)
                        drawSparks(*c, W, T, MON, TIPS);
                    if (T >= SWING && T < SLAM + 160)
                        drawSparks(*c, W, T, MON, WHIP);
                    if (T >= SLAM && T < SLAM + 240)
                        drawSparks(*c, W, T, MON, BURST);
                }
                if (!c->gilt.empty() && T < FLUSH + 260)
                    drawSparks(*c, W, T, MON, GILT);
                drawRifts(*c, W, T, MON);
            }
            for (const auto& [RANK, PARITY] : {std::pair{0, 1.F}, std::pair{1, 1.F}, std::pair{1, 0.F}, std::pair{0, 0.F}})
                for (const auto* c : swaps)
                    if (!c->landed && c->rank % 2 == RANK)
                        drawQuarries(*c, c->window.lock(), ms(*c), MON, true, WEAVE, PARITY);
            for (const auto* c : swaps) {
                const auto  W = c->window.lock();
                const float T = ms(*c);
                drawWeld(*c, W, T, MON, true);
                if (c->lead) {
                    drawGate(*c, T, MON);
                    if (T >= SWING && T < SLAM + 160)
                        drawSparks(*c, W, T, MON, STREAM);
                    if (T >= SLAM && T < SLAM + 240)
                        drawSparks(*c, W, T, MON, ZIP);
                }
                if (!c->gilt.empty() && T < FLUSH + 260)
                    drawSparks(*c, W, T, MON, GILT);
                drawRifts(*c, W, T, MON);
            }
            for (const auto& p : pyres) {
                if (!p->armed || !touches(*p, MON))
                    continue;
                if (p->ghost && !p->ghost->done() && !Enfilade::view(MON))
                    p->ghost->paint(false, BURNED);
                g_pHyprOpenGL->blend(true);
                const bool LAND = p->monitor.lock() == MON;
                Gl::nudge       = LAND ? Translation::kick(MON) * MON->m_scale : Vector2D{};
                if (LAND) {
                    drawInfuse(*p, ms(*p), MON);
                    drawStrike(*p, ms(*p), MON);
                }
                drawAsh(*p, ms(*p), MON);
                Gl::nudge = {};
            }
            Gl::unbindAll();
            g_pHyprOpenGL->blend(true);
            return {};
        }
        virtual bool needsLiveBlur(Render::CRenderContext& ctx) override {
            return false;
        }
        virtual bool needsPrecomputeBlur(Render::CRenderContext& ctx) override {
            return false;
        }
        virtual std::optional<CBox> boundingBox(Render::CRenderContext& ctx) override {
            const auto MON = m_monitor.lock();
            return MON ? std::optional<CBox>{CBox{{}, MON->m_size}} : std::nullopt;
        }
        virtual const char* passName() override {
            return "CTranslationPass";
        }
        virtual ePassElementType type() override {
            return EK_CUSTOM;
        }

      private:
        PHLMONITORREF m_monitor;
    };
}

void Translation::stage(const PHLMONITOR& monitor) {
    if (monitor &&
        (std::ranges::any_of(flights, [&monitor](const UP<SCarry>& c) { return c->armed && touches(*c, monitor); }) ||
         std::ranges::any_of(pyres, [&monitor](const UP<SPyre>& p) { return p->armed && touches(*p, monitor); })))
        g_pHyprRenderer->addPassElement(*Gl::ctx, makeUnique<CTranslationPass>(monitor));
}
