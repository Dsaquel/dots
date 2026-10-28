#include "mullion/Internal.hpp"
#include "life/Life.hpp"

namespace Mullion {
    const std::string PANE =
#include "mullion.frag.inc"
        ;
    const std::string PIECE =
#include "piece.frag.inc"
        ;

    SProgram paneProgram{.frag = &PANE, .name = "mullion"};
    SProgram brickProgram{.frag = &PIECE, .name = "brick"};

    class CMullionPass : public IPassElement {
      public:
        CMullionPass(PHLMONITORREF monitor) : m_monitor(monitor) {}
        virtual ~CMullionPass() = default;

        virtual std::vector<UP<IPassElement>> draw(Render::CRenderContext& ctx) override {

            Gl::ctx = &ctx;
            const auto MON = m_monitor.lock();
            if (!MON || Gl::ctx->m_data.pMonitor.lock() != MON)
                return {};
            Gl::nudge = Translation::kick(MON) * MON->m_scale;
            for (const auto& s : scenes)
                if (s->monitor.lock() == MON && s->released)
                    drawRelease(*s, MON);
                else if (s->monitor.lock() == MON)
                    paint(*s, ms(*s), MON);
            Gl::nudge = {};
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
            return "CMullionPass";
        }
        virtual ePassElementType type() override {
            return EK_CUSTOM;
        }

      private:
        PHLMONITORREF m_monitor;
    };
}

bool Mullion::open(const PHLWINDOW& born, const PHLWINDOW& giver, int side, float pace) {
    Life::quench(giver);
    auto* const GF  = CGlassFrame::of(giver);
    const auto  MON = giver->m_monitor.lock();
    if (!g_glass->enabled->value() || !GF || GF->m_lens || !MON || born->m_monitor.lock() != MON || giver->isFloating() || born->isFloating() || !g_pHyprRenderer->shouldRenderWindow(giver))
        return false;
    const CBox R = boxOf(giver).translate(-MON->m_position);
    hurry(giver, R);
    if (!tiles(born, giver, side, R, MON->m_position))
        return false;
    auto ring = GF->build(MON, 1.F);
    if (!ring)
        return false;
    g_glass->shooting = eShot::BARE;
    const auto STILL  = g_pHyprRenderer->makeSnapshotFB(giver);
    g_glass->shooting = eShot::NONE;
    if (!STILL || !STILL->getTexture())
        return false;
    return raise(born, giver, side, std::move(*ring), STILL, 0, pace);
}

bool Mullion::fits(const PHLWINDOW& born, const PHLWINDOW& giver, int side, const CBox& was) {
    const auto MON = giver->m_monitor.lock();
    return MON && born->m_monitor.lock() == MON && tiles(born, giver, side, was.copy().translate(-MON->m_position), MON->m_position);
}

bool Mullion::seat(const PHLWINDOW& born, const PHLWINDOW& giver, int side, const CBox& was, std::optional<CGlassPass::SData> ring, const SP<Render::IFramebuffer>& still, float lead,
                   float pace) {
    const auto MON = giver->m_monitor.lock();
    if (!g_glass->enabled->value() || !CGlassFrame::of(giver) || !MON || born->m_monitor.lock() != MON || giver->isFloating() || born->isFloating() || !ring || !still ||
        !still->getTexture())
        return false;
    const CBox R = was.copy().translate(-MON->m_position);
    hurry(giver, R);
    if (!tiles(born, giver, side, R, MON->m_position))
        return false;
    born->positionAnimation()->warp();
    born->sizeAnimation()->warp();
    raise(born, giver, side, std::move(*ring), still, lead, pace)->heat = 1;
    return true;
}

bool Mullion::late(const PHLWINDOW& born) {
    if (std::ranges::none_of(scenes, [&born](const UP<SScene>& s) { return s->born.lock() == born; }))
        return false;
    born->positionAnimation()->warp();
    born->sizeAnimation()->warp();
    born->presentation().alpha(Desktop::View::WINDOW_ALPHA_FADE)->warp();
    settleDim(born);
    return true;
}

void Mullion::hush() {
    announce("hush,mullion");
    for (const auto& s : scenes)
        if (early(*s))
            cue(*s);
    Translation::recue();
}

bool Mullion::holds(const PHLWINDOW& window) {
    return window && std::ranges::any_of(scenes, [&window](const UP<SScene>& s) { return !s->released && (s->born.lock() == window || s->giver.lock() == window); });
}

void Mullion::drop(const PHLWINDOW& window, bool keep) {
    const bool HUSH = std::ranges::any_of(scenes, [&window](const UP<SScene>& s) { return early(*s) && (s->born.lock() == window || s->giver.lock() == window); });
    for (auto& s : scenes)
        if (!s->released && s->born.lock() == window && validMapped(s->giver.lock()) && ms(*s) < s->boom)
            s->released = true;
    std::erase_if(scenes, [&window, keep](const UP<SScene>& s) { return (s->giver.lock() == window && !(keep && s->released)) || (!s->released && s->born.lock() == window); });
    if (HUSH)
        Mullion::hush();
}

void Mullion::pre(const PHLMONITOR& monitor) {
    bool cut = false;
    std::erase_if(scenes, [&cut](const UP<SScene>& s) {
        const auto B  = s->born.lock(), G = s->giver.lock();
        const auto WS = s->workspace.lock();
        if (s->released) {
            if (!validMapped(G) || !WS || !WS->visible() || G->m_workspace != WS)
                return true;
            if (G->positionAnimation()->isBeingAnimated() || G->sizeAnimation()->isBeingAnimated())
                s->settled = -1;
            else if (s->settled < 0)
                s->settled = secondsAlive();
            return s->settled >= 0 && secondsAlive() - s->settled > 0.2F;
        }
        const bool GONE = !validMapped(B) || !validMapped(G) || !WS || !WS->visible() || B->m_workspace != WS || G->m_workspace != WS || Fullscreen::controller()->hasFullscreen(WS) ||
            !s->clock || !s->clock->isBeingAnimated();
        cut = cut || (GONE && early(*s));
        return GONE;
    });
    if (cut)
        Mullion::hush();
    for (auto& s : scenes) {
        if (s->released && s->monitor.lock() == monitor)
            g_pHyprRenderer->damageBox(s->r.copy().translate(monitor->m_position).expand(4));
        if (s->released || s->kicked || s->monitor.lock() != monitor || ms(*s) < s->boom)
            continue;
        s->kicked = true;
        for (const auto& [W, BY] : {std::pair{s->giver.lock(), s->b * -KICK}, std::pair{s->born.lock(), s->b * KICK}})
            if (!claimed(*s, W))
                kick(W, BY, s->pace);
        strike(*s, monitor);
    }
    for (auto& s : scenes) {
        if (s->released || s->monitor.lock() != monitor)
            continue;
        for (auto& st : s->struck) {
            const auto W = st.window.lock();
            if (!W)
                continue;
            g_pHyprRenderer->damageBox(boxOf(W).expand(24));
            if (st.kicked || ms(*s) < st.at)
                continue;
            st.kicked = true;
            if (JOLT * st.strength >= 1 && idle(W))
                kick(W, st.dir * (JOLT * st.strength), s->pace);
        }
    }
}

void Mullion::stage(const PHLMONITOR& monitor) {
    if (monitor && std::ranges::any_of(scenes, [&monitor](const UP<SScene>& s) { return s->monitor.lock() == monitor; }))
        g_pHyprRenderer->addPassElement(*Gl::ctx, makeUnique<CMullionPass>(monitor));
}

void Mullion::style(const std::string& name) {
    melting = name == "melt";
}

void Mullion::exit() {
    scenes.clear();
    g_pHyprRenderer->context().m_pass.removeAllOfType("CMullionPass");
}

bool Mullion::warm() {
    Gl::ready(paneProgram);
    Gl::ready(brickProgram);
    return true;
}

void Mullion::destroy() {
    Gl::reset(paneProgram);
    Gl::reset(brickProgram);
}
