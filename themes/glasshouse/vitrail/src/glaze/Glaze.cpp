#include "glaze/Internal.hpp"

namespace Glaze {
    const std::string GLAZE =
#include "glaze.frag.inc"
        ;
    const std::string BOLT =
#include "weld.frag.inc"
        ;
    const std::string SPATTER =
#include "spark.frag.inc"
        ;
    const std::string SPATTERV =
#include "spark.vert.inc"
        ;

    SProgram glazeProgram{.frag = &GLAZE, .name = "glaze"};
    SProgram boltProgram{.frag = &BOLT, .name = "glaze bolt"};
    SProgram spatterProgram{.frag = &SPATTER, .name = "glaze spatter", .vert = &SPATTERV};

    bool swiping = false;

    class CGlazePass : public IPassElement {
      public:
        CGlazePass(PHLMONITORREF monitor) : m_monitor(monitor) {}
        virtual ~CGlazePass() = default;

        virtual std::vector<UP<IPassElement>> draw(Render::CRenderContext& ctx) override {

            Gl::ctx = &ctx;
            const auto MON = m_monitor.lock();
            if (!MON || Gl::ctx->m_data.pMonitor.lock() != MON || !Gl::ready(glazeProgram))
                return {};
            g_pHyprOpenGL->blend(true);
            for (const auto& s : sheets | std::views::filter([&MON](const UP<SSheet>& s) { return s->monitor.lock() == MON; })) {
                const float T = ms(*s);
                for (size_t i = 0; i < s->panes.size(); ++i) {
                    Gl::nudge = s->live ? s->jolt * MON->m_scale : Vector2D{};
                    if (!s->live || T < SLAM + SHOCK + RING + 10)
                        drawGlass(*s, i, T, MON);
                    if (s->live && T < SLAM + SHOCK + ARCED)
                        drawBolt(*s, i, T, MON);
                    Gl::nudge = {};
                    if (s->live)
                        drawSpatter(*s, i, T, MON);
                }
            }
            Gl::nudge = {};
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
            if (!MON)
                return std::nullopt;
            const auto BOXES = sheets | std::views::filter([&MON](const UP<SSheet>& s) { return s->monitor.lock() == MON; }) |
                std::views::transform([](const UP<SSheet>& s) { return std::views::all(s->panes); }) | std::views::join |
                std::views::transform([&MON](const SPane& p) { return reachOf(p.area).translate(-MON->m_position); }) | std::ranges::to<std::vector>();
            if (BOXES.empty())
                return std::nullopt;
            const double X0 = std::ranges::min(BOXES | std::views::transform([](const CBox& b) { return b.x; }));
            const double Y0 = std::ranges::min(BOXES | std::views::transform([](const CBox& b) { return b.y; }));
            const double X1 = std::ranges::max(BOXES | std::views::transform([](const CBox& b) { return b.x + b.w; }));
            const double Y1 = std::ranges::max(BOXES | std::views::transform([](const CBox& b) { return b.y + b.h; }));
            return CBox{X0, Y0, X1 - X0, Y1 - Y0};
        }
        virtual const char* passName() override {
            return "CGlazePass";
        }
        virtual ePassElementType type() override {
            return EK_CUSTOM;
        }

      private:
        PHLMONITORREF m_monitor;
    };
}

void Glaze::toggle(const PHLWORKSPACE& shown, const PHLMONITOR& monitor) {
    if (swiping || !g_glass->enabled->value() || !g_glass->glaze->value() || !monitor || !monitor->m_output || !monitor->m_enabled || !glazeProgram.shader ||
        (g_pSessionLockManager && g_pSessionLockManager->isSessionLocked()))
        return;
    const auto LEAVING = State::workspaceState()->workspaces() | std::views::transform([](const auto& ref) { return ref.lock(); }) |
        std::views::filter([&shown, &monitor](const PHLWORKSPACE& ws) {
                             return ws && ws != shown && isSpecial(ws) && ws->m_monitor == monitor && !ws->visible() && ws->m_alpha->goal() == 0.F &&
                                 (ws->m_alpha->isBeingAnimated() || sheetOf(ws));
                         }) |
        std::ranges::to<std::vector>();
    for (const auto& ws : LEAVING)
        fly(ws, monitor, false);
    if (shown && isSpecial(shown))
        fly(shown, monitor, true);
}

void Glaze::swipe(bool on) {
    swiping = on;
    if (!on)
        return;
    std::ranges::for_each(sheets, [](const UP<SSheet>& s) { settle(*s); });
    sheets.clear();
}

void Glaze::pre(const PHLMONITOR& monitor) {
    std::erase_if(sheets, [&monitor](const UP<SSheet>& s) {
        const auto MON = s->monitor.lock();
        const auto WS  = s->workspace.lock();
        if (!MON || !MON->m_enabled || !WS) {
            settle(*s);
            return true;
        }
        if (MON != monitor)
            return false;
        std::erase_if(s->panes, [&WS](const SPane& p) {
            const auto W = p.window.lock();
            return !validMapped(W) || W->m_workspace != WS;
        });
        if (heading(*s) != WS->visible() || Fullscreen::controller()->hasFullscreen(WS) || s->panes.empty()) {
            settle(*s);
            return true;
        }
        if (!s->clock->isBeingAnimated()) {
            if (!s->back || s->shows) {
                if (heading(*s))
                    WS->m_alpha->setValueAndWarp(1.F);
                return true;
            }
            play(*s, true, SLAM, false, false);
            handBack(*s);
        }
        const float T = ms(*s);
        if (s->shows && !s->back && !s->live && T >= SLAM)
            handBack(*s);
        jolt(*s, T, MON);
        s->veil = veiled(*s, T);
        damage(*s);
        return false;
    });
    dim(monitor);
}

void Glaze::stage(const PHLMONITOR& monitor) {
    if (monitor && std::ranges::any_of(sheets, [&monitor](const UP<SSheet>& s) { return s->monitor.lock() == monitor; }))
        g_pHyprRenderer->addPassElement(*Gl::ctx, makeUnique<CGlazePass>(monitor));
}

void Glaze::exit() {
    std::ranges::for_each(sheets, [](const UP<SSheet>& s) { settle(*s); });
    sheets.clear();
    g_pHyprRenderer->context().m_pass.removeAllOfType("CGlazePass");
}

bool Glaze::warm() {
    for (auto* p : {&glazeProgram, &boltProgram, &spatterProgram})
        Gl::ready(*p);
    return true;
}

void Glaze::destroy() {
    for (auto* p : {&glazeProgram, &boltProgram, &spatterProgram})
        Gl::reset(*p);
}
