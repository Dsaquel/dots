#include "life/Internal.hpp"

namespace Life {
    const std::string CONTENT =
#include "content.frag.inc"
        ;
    const std::string PIECE =
#include "piece.frag.inc"
        ;
    const std::string GRAIN =
#include "grain.frag.inc"
        ;
    const std::string GRAINV =
#include "grain.vert.inc"
        ;
    const std::string SLIVER =
#include "sliver.frag.inc"
        ;
    const std::string SLIVERV =
#include "sliver.vert.inc"
        ;
    const std::string PORTAL =
#include "portal.frag.inc"
        ;
    const std::string EMBER =
#include "ember.frag.inc"
        ;
    const std::string EMBERV =
#include "ember.vert.inc"
        ;

    SProgram contentProgram{.frag = &CONTENT, .name = "content"};
    SProgram pieceProgram{.frag = &PIECE, .name = "piece"};
    SProgram grainProgram{.frag = &GRAIN, .name = "grain", .vert = &GRAINV};
    SProgram sliverProgram{.frag = &SLIVER, .name = "sliver", .vert = &SLIVERV};
    SProgram portalProgram{.frag = &PORTAL, .name = "portal"};
    SProgram emberProgram{.frag = &EMBER, .name = "ember", .vert = &EMBERV};
}

void Life::open(const PHLWINDOW& w, const PHLWINDOW& giver) {
    auto* const F = CGlassFrame::of(w);
    if (!F || !w->m_workspace || !w->m_workspace->visible() || Fullscreen::controller()->isFullscreen(w))
        return;
    const int   SIDE = giver ? facing(giver->geometricBox(Desktop::View::IGeometric::GEOMETRIC_GOAL), w->geometricBox(Desktop::View::IGeometric::GEOMETRIC_GOAL)) : -1;
    auto* const G    = giver ? CGlassFrame::of(giver) : nullptr;
    if (!G || SIDE < 0) {
        F->born(nullptr, -1);
        return;
    }
    if (Mullion::open(w, giver, SIDE))
        return;
    F->born(giver, (SIDE + 2) % 4);
    G->lend(CGlassFrame::ROLE_GIVER, w, SIDE);
}

void Life::late(const PHLWINDOW& w) {
    if (Mullion::late(w))
        return;
    auto* const F = CGlassFrame::of(w);
    if (!F || F->role() != CGlassFrame::ROLE_BORN || F->m_lens)
        return;
    F->m_lens = w->effects().transformers()->emplace<CLens>(w);
    w->presentation().alpha(Desktop::View::WINDOW_ALPHA_FADE)->warp();
    settleDim(w);
    const auto G = F->peer();
    if (!validMapped(G)) {
        w->positionAnimation()->warp();
        w->sizeAnimation()->warp();
        return;
    }
    retime(w, "windowsIn");
    retime(G, "windowsMove", "vitrailGive");
    if (!g_glass->retime->value())
        return;
    const float K = paceFor(BORN_END, std::max(landsIn(w), landsIn(G)) + std::max(0.F, F->lifeMs()));
    F->pace(K);
    if (auto* const GF = CGlassFrame::of(G); GF && GF->role() == CGlassFrame::ROLE_GIVER)
        GF->pace(K);
}

void Life::quench(const PHLWINDOW& w) {
    auto* const F = CGlassFrame::of(w);
    if (!F || !F->m_lens || F->role() != CGlassFrame::ROLE_BORN || validMapped(F->peer()) || F->lifeMs() < LIFE)
        return;
    dropLens(w);
    F->lend(CGlassFrame::ROLE_NONE, nullptr, -1);
}

void Life::close(const PHLWINDOW& w) {
    Mullion::drop(w);
    if (!g_glass->enabled->value() || !CGlassFrame::of(w) || Fullscreen::controller()->isFullscreen(w) || !g_pHyprRenderer->shouldRenderWindow(w)) {
        dropLens(w);
        return;
    }
    g_glass->capturing = w;
    const auto SNAP    = g_pHyprRenderer->makeSnapshotFB(w);
    g_glass->capturing.reset();
    dropLens(w);
    const auto GHOST = CGhost::create(w, SNAP);
    if (!GHOST)
        return;
    if (auto* const F = CGlassFrame::of(w); F->role() == CGlassFrame::ROLE_BORN && !validMapped(F->peer()) && F->paceMs() < SET)
        GHOST->decide(nullptr, -1, CGhost::DUST);
    w->m_ruleApplicator->noAnim().set(true, Desktop::Types::PRIORITY_SET_PROP);
    Desktop::fadingOutState()->add(GHOST);
    g_glass->ghosts.emplace_back(GHOST);
}

void Life::leave(const PHLWINDOW& w, const PHLWINDOW& receiver, float arrive, bool bare) {
    const auto ADDRESS = std::format("{:x}", rc<uintptr_t>(w.get()));
    for (const auto& weak : g_glass->ghosts)
        if (const auto G = weak.lock(); G && G->m_address == ADDRESS)
            G->finish();
    if (!g_glass->enabled->value() || !CGlassFrame::of(w) || Fullscreen::controller()->isFullscreen(w) || !g_pHyprRenderer->shouldRenderWindow(w))
        return;
    g_glass->capturing = w;
    const auto SNAP    = g_pHyprRenderer->makeSnapshotFB(w);
    g_glass->capturing.reset();
    const auto GHOST = CGhost::create(w, SNAP);
    if (!GHOST)
        return;
    GHOST->m_bare = bare;
    Desktop::fadingOutState()->add(GHOST);
    g_glass->ghosts.emplace_back(GHOST);
    give(GHOST, receiver, arrive);
}

void Life::decide(const std::string& address, const PHLWINDOW& receiver) {
    for (const auto& weak : g_glass->ghosts)
        if (const auto G = weak.lock(); G && G->m_address == address && G->pending())
            give(G, receiver, GIVEN, true);
}

void Life::follow(const PHLWINDOW& w, float ms) {
    retime(w, "windowsMove", "vitrailPace", ms);
}

void Life::pre(const PHLMONITOR& monitor) {
    std::erase_if(g_glass->ghosts, [](const WP<CGhost>& g) { return g.expired(); });
    for (const auto& weak : g_glass->ghosts)
        if (const auto G = weak.lock()) {
            G->m_laid = false;
            G->strand();
        }
    std::erase_if(g_glass->retimed, [](const SRetimed& r) {
        const auto W = r.window.lock();
        if (!W)
            return true;
        const auto& V = r.size ? W->sizeAnimation() : W->positionAnimation();
        if (V->isBeingAnimated() && V->goal() == r.goal)
            return false;
        restore(r);
        return true;
    });
    const auto NOW = std::chrono::steady_clock::now();
    std::erase_if(g_jolts, [&monitor, &NOW](const SJolt& j) {
        const auto W = j.window.lock();
        if (!validMapped(W) || W->isFloating()) {
            if (W)
                W->presentation().clearFloatingOffset();
            return true;
        }
        if (W->m_monitor != monitor)
            return false;
        const float AGE  = std::chrono::duration<float, std::milli>(NOW - j.at).count();
        const bool  OVER = AGE >= SHUDDER || j.amp * std::exp(-AGE / DAMP) < FAINT || Fullscreen::controller()->isFullscreen(W);
        if (AGE < 0) {
            g_pHyprRenderer->damageBox(CBox{boxOf(W).middle(), {1, 1}});
            return false;
        }
        W->presentation().setFloatingOffset(OVER ? Vector2D{} : j.dir * (j.amp * std::exp(-AGE / DAMP) * std::sin(2 * float(M_PI) * AGE / BEAT)));
        g_pHyprRenderer->damageBox(boxOf(W).expand(CGlassFrame::MARGIN + j.amp + 2));
        return OVER;
    });
    std::ranges::for_each(Desktop::windowState()->windows(), [&monitor](const PHLWINDOW& w) {
        auto* const F      = CGlassFrame::of(w);
        const bool  MOVING = F && F->settle();
        if (F && !MOVING && !F->m_lens && F->role() == CGlassFrame::ROLE_RECEIVER && F->side() >= 0 && F->syncMs() >= SLAM - SHOCKIN) {
            F->m_lens = w->effects().transformers()->emplace<CLens>(w);
        }
        if (!F || !F->m_lens)
            return;
        if (F->lifeMs() < 0 || F->role() == CGlassFrame::ROLE_GIVER)
            dropLens(w);
        else if (w->m_monitor == monitor && F->role() == CGlassFrame::ROLE_BORN && !validMapped(F->peer())) {
            g_pHyprRenderer->damageMonitor(monitor);
            g_pHyprRenderer->damageBox(boxOf(w).expand(SPRAY));
        } else if (w->m_monitor == monitor && F->role() == CGlassFrame::ROLE_BORN) {
            g_pHyprRenderer->damageBox(boxOf(w).expand(CGlassFrame::MARGIN + 40));
            g_pHyprRenderer->damageBox(boxOf(F->peer()).expand(CGlassFrame::MARGIN + 40));
        }
    });
}

void Life::stage(const PHLMONITOR& monitor) {
    if (!monitor || Gl::ctx->m_renderingSnapshot)
        return;
    for (const auto& weak : g_glass->ghosts)
        if (const auto G = weak.lock())
            G->lay(monitor);
}

void Life::exit() {
    for (const auto& j : g_jolts)
        if (const auto W = j.window.lock()) {
            W->presentation().clearFloatingOffset();
            if (validMapped(W))
                g_pHyprRenderer->damageBox(boxOf(W).expand(CGlassFrame::MARGIN + j.amp + 2));
        }
    g_jolts.clear();
    std::ranges::for_each(g_glass->retimed, restore);
    g_glass->retimed.clear();
    unpace();
    std::ranges::for_each(Desktop::windowState()->windows(), dropLens);
    for (const auto& weak : g_glass->ghosts)
        if (const auto G = weak.lock())
            G->finish();
    for (const auto& m : State::monitorState()->monitors())
        Desktop::fadingOutState()->cleanupForMonitor(m);
    g_glass->ghosts.clear();
    g_pHyprRenderer->context().m_pass.removeAllOfType("CGhostPass");
}

void Life::unpace() {
    for (const auto& w : Desktop::windowState()->windows())
        for (auto* const v : {&w->positionAnimation(), &w->sizeAnimation()}) {
            const auto CFG = (*v)->getConfig().lock();
            const auto VAL = CFG ? CFG->pValues.lock() : nullptr;
            if (!VAL || VAL->internalBezier.starts_with("vitrail"))
                (*v)->setConfig(Config::animationTree()->getAnimationPropertyConfig("windowsMove"));
        }
}

void Life::curves() {
    Animation::mgr()->addBezierWithName("vitrailPace", Vector2D{0.25, 0.1}, Vector2D{0.25, 1.0});
    Animation::mgr()->addBezierWithName("vitrailGive", Vector2D{0.15, 0.95}, Vector2D{0.05, 1.0});
    Animation::mgr()->addBezierWithName("vitrailRecoil", Vector2D{0.25, 1.6}, Vector2D{0.45, 1.0});
    Animation::mgr()->addBezierWithName("vitrailSlam", Vector2D{0.4, 0.05}, Vector2D{0.8, 0.7});
}

bool Life::warm() {
    for (auto* p : {&contentProgram, &pieceProgram, &grainProgram, &sliverProgram, &portalProgram, &emberProgram})
        Gl::ready(*p);
    return true;
}

void Life::destroy() {
    for (auto* p : {&contentProgram, &pieceProgram, &grainProgram, &sliverProgram, &portalProgram, &emberProgram})
        Gl::reset(*p);
}
