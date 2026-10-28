#include "translation/Internal.hpp"

namespace Translation {
    const std::string QUARRY =
#include "quarry.frag.inc"
        ;
    const std::string QUARRYV =
#include "quarry.vert.inc"
        ;
    const std::string HUSK =
#include "husk.frag.inc"
        ;
    const std::string VEIL =
#include "veil.frag.inc"
        ;
    const std::string SPARK =
#include "spark.frag.inc"
        ;
    const std::string SPARKV =
#include "spark.vert.inc"
        ;
    const std::string WELDING =
#include "weld.frag.inc"
        ;
    const std::string ASH =
#include "ash.frag.inc"
        ;
    const std::string ASHV =
#include "ash.vert.inc"
        ;
    const std::string INFUSE =
#include "infuse.frag.inc"
        ;
    const std::string STRIKE =
#include "strike.frag.inc"
        ;
    const std::string PIVOT =
#include "pivot.frag.inc"
        ;
    const std::string POOL =
#include "pool.frag.inc"
        ;
    const std::string GATE =
#include "gate.frag.inc"
        ;

    SProgram quarryProgram{.frag = &QUARRY, .name = "quarry", .vert = &QUARRYV};
    SProgram huskProgram{.frag = &HUSK, .name = "husk"};
    SProgram veilProgram{.frag = &VEIL, .name = "veil"};
    SProgram sparkProgram{.frag = &SPARK, .name = "spark", .vert = &SPARKV};
    SProgram weldProgram{.frag = &WELDING, .name = "weld"};
    SProgram ashProgram{.frag = &ASH, .name = "ash", .vert = &ASHV};
    SProgram infuseProgram{.frag = &INFUSE, .name = "infuse"};
    SProgram strikeProgram{.frag = &STRIKE, .name = "strike"};
    SProgram pivotProgram{.frag = &PIVOT, .name = "pivot"};
    SProgram poolProgram{.frag = &POOL, .name = "pool"};
    SProgram gateProgram{.frag = &GATE, .name = "gate"};

    struct SSeen {
        PHLWINDOWREF window;
        CBox         goal;
    };

    std::vector<SSeen>      seen;
    PHLWORKSPACEREF         takenFrom;
}

void Translation::take(const PHLWINDOW& w, const PHLWORKSPACE& to) {
    if (!g_glass->enabled->value() || !g_glass->translation->value() || !validMapped(w) || w->isHidden() || isPinned(w) || !to || isSpecial(to) ||
        !w->presentation().movingFromMonitor() || Fullscreen::controller()->isFullscreen(w) || g_layoutManager->dragController()->target() ||
        (g_pSessionLockManager && g_pSessionLockManager->isSessionLocked()))
        return;
    const auto MON = w->m_monitor.lock();
    if (!MON || !MON->m_output || !MON->m_enabled)
        return;
    if (const auto IT = flightOf(w); IT != flights.end()) {
        if ((*IT)->kind == eKind::TRANSLATE)
            return;
        unveil(**IT);
        flights.erase(IT);
    }
    if (const auto IT = std::ranges::find_if(pyres, [&w](const UP<SPyre>& p) { return p->window.lock() == w && p->seated >= SHUT; }); IT != pyres.end()) {
        if (!aim(**IT, w, to))
            pyres.erase(IT);
        Mullion::hush();
        return;
    }
    std::erase_if(pyres, [&w](const UP<SPyre>& p) { return p->window.lock() == w; });

    const auto&         ALL    = State::monitorState()->monitors();
    const auto          SOURCE = std::ranges::find_if(ALL, [&w](const PHLMONITOR& m) { return m == w->m_monitor.lock(); });
    const auto          SRC    = SOURCE == ALL.end() ? MON : *SOURCE;
    const auto          LAND   = to->m_monitor.lock();
    const auto          FROM   = w->m_workspace != to ? w->m_workspace : SRC->m_activeWorkspace;
    const bool          KINDLE = LAND && kindles(w, FROM, to, SRC, LAND);
    const PHLMONITORREF HOME   = w->m_monitor;
    if (KINDLE) {
        hurry(w, SRC, LAND);
        Mullion::drop(w);
        // a move across the monitor edge points m_monitor at the target before this event, and makeSnapshotFB and CGhost::create render on m_monitor
        w->m_monitor = SRC;
    }
    const bool FORCED    = to->m_forceRendering;
    if (!to->visible())
        to->m_renderOffset->setValueAndWarp({});
    to->m_forceRendering = true;
    const auto SNAP      = shoot(w);
    auto       BEFORE    = KINDLE && SNAP ? capture(w, to, LAND) : std::vector<SBefore>{};
    to->m_forceRendering = FORCED;
    const bool LIT       = SNAP && KINDLE && (!BEFORE.empty() || bare(w, to));
    if (LIT)
        kindle(w, SRC, LAND, FROM, to, SNAP, std::move(BEFORE));
    w->m_monitor = HOME;
    if (!SNAP)
        return;
    takenFrom = w->m_workspace;
    takenAt   = secondsAlive();
    if (LIT)
        return;
    launch(w, MON, SNAP, eKind::TRANSLATE);
    announce(std::format("translate,{}", addressOf(w)));
}

void Translation::watch(const PHLMONITOR& monitor) {
    std::erase_if(seen, [](const SSeen& s) { return !validMapped(s.window.lock()); });
    std::vector<PHLWINDOW> moved, loose;
    std::vector<CBox>      was, looseWas;
    for (const auto& w : Desktop::windowState()->windows()) {
        if (!validMapped(w) || w->m_monitor.lock() != monitor)
            continue;
        const CBox GOAL = w->geometricBox(GEO::GEOMETRIC_GOAL);
        const auto IT   = std::ranges::find_if(seen, [&w](const SSeen& s) { return s.window.lock() == w; });
        if (IT == seen.end()) {
            seen.push_back({.window = w, .goal = GOAL});
            continue;
        }
        const CBox WAS = std::exchange(IT->goal, GOAL);
        if (WAS == GOAL || !shifted(WAS, GOAL) || !turnable(w))
            continue;
        loose.push_back(w);
        looseWas.push_back(WAS);
        if (pourable(w)) {
            moved.push_back(w);
            was.push_back(WAS);
        }
    }
    if (loose.empty() || !g_glass->enabled->value() || !g_glass->relead->value() || secondsAlive() < hushed || g_layoutManager->dragController()->target() ||
        (g_pSessionLockManager && g_pSessionLockManager->isSessionLocked()) || !monitor->m_output || !monitor->m_enabled)
        return;
    const auto FOCUS      = Desktop::focusState()->window();
    if (const auto TURN = pairOf(loose, looseWas)) {
        turnPair(*TURN, monitor, FOCUS);
        return;
    }
    if (const auto RELAY = relayOf(loose, looseWas)) {
        relay(*RELAY, monitor, FOCUS);
        return;
    }
    if (const auto SET = swapOf(loose, looseWas)) {
        swapSet(*SET, monitor, FOCUS);
        return;
    }
    if (moved.empty())
        return;
    std::ranges::for_each(moved, unturn);
    const bool AFTER_TAKE = takenAt >= 0 && secondsAlive() - takenAt < TAKEN;
    for (const auto& w : moved) {
        const auto SNAP = shoot(w);
        if (!SNAP)
            continue;
        auto* const c = launch(w, monitor, SNAP, eKind::RELEAD);
        w->positionAnimation()->warp();
        w->sizeAnimation()->warp();
        c->goal   = w->geometricBox(GEO::GEOMETRIC_GOAL);
        c->opened = 0;
        c->delay  = AFTER_TAKE && w->m_workspace == takenFrom.lock() ? SHIFTED : 0.F;
        c->base   = c->delay;
        plan(*c);
    }
    const auto LEAD = std::ranges::find(moved, FOCUS) != moved.end() ? FOCUS : moved.front();
    announce(std::format("relead,{},{}", addressOf(LEAD), moved.size()));
}

void Translation::hush() {
    hushed = secondsAlive() + HUSH;
}

void Translation::settle(const PHLMONITOR& monitor) {
    std::erase_if(flights, [&monitor](const UP<SCarry>& c) {
        if (c->kind == eKind::TRANSLATE || !touches(*c, monitor))
            return false;
        unveil(*c);
        return true;
    });
}

bool Translation::blaze(const PHLMONITOR& monitor) {
    bool lit = false;
    for (const auto& p : pyres)
        if (p->armed && p->from.lock() == monitor && p->ghost && !p->ghost->done()) {
            p->ghost->paint(false, BURNED);
            lit = true;
        }
    return lit;
}

bool Translation::carries(const PHLWINDOW& w) {
    return flightOf(w) != flights.end() || std::ranges::any_of(pyres, [&w](const UP<SPyre>& p) { return p->seated >= SHUT && p->window.lock() == w; });
}

std::optional<WORKSPACEID> Translation::holds(const PHLWORKSPACE& to) {
    if (!to)
        return std::nullopt;
    for (const auto& p : pyres) {
        const float T = ms(*p);
        if (p->walks && p->target.lock() == to && (!p->armed || T < HOLD || p->aim.lock()))
            return p->origin;
        if (p->aimWalks && p->aim.lock() == to && (T < HOLD || !ready(*p, T)))
            return p->aimOrigin;
        if (p->held.lock() == to && T < gathered(*p))
            return p->origin;
    }
    return std::nullopt;
}

Vector2D Translation::kick(const PHLMONITOR& monitor) {
    for (const auto& p : pyres)
        if (p->armed && p->monitor.lock() == monitor)
            if (const Vector2D K = Enfilade::view(monitor) ? kickOf(*p, ms(*p)) : p->jolt; K != Vector2D{})
                return K;
    return {};
}

std::optional<WORKSPACEID> Translation::aims(const PHLWORKSPACE& to) {
    const auto IT = std::ranges::find_if(pyres, [&to](const UP<SPyre>& p) { return to && p->aimWalks && p->aim.lock() == to; });
    return IT == pyres.end() ? std::nullopt : std::optional{(*IT)->aimOrigin};
}

void Translation::recue() {
    for (const auto& p : pyres)
        if (const auto W = p->window.lock(); W && p->armed && p->seated >= SHUT)
            if (const auto CUES = cuesOf(*p, W, ms(*p), true); !CUES.empty())
                announce(CUES);
}

bool Translation::reserves(const PHLWINDOW& w) {
    return w && std::ranges::any_of(pyres, [&w](const UP<SPyre>& p) { return p->armed && p->seated >= SHUT && p->giver.lock() == w; });
}

std::vector<SP<Render::IFramebuffer>> Translation::before(const PHLWORKSPACE& ws) {
    const auto IT = std::ranges::find_if(pyres, [&ws](const UP<SPyre>& p) { return p->armed && p->seated >= SHUT && (p->aim.lock() ? p->aim.lock() : p->target.lock()) == ws; });
    if (IT == pyres.end())
        return {};
    return ((*IT)->aim.lock() ? (*IT)->aimed : (*IT)->before) | std::views::transform([](const SBefore& b) { return b.shot; }) | std::ranges::to<std::vector>();
}

bool Translation::bound(const PHLWORKSPACE& ws) {
    return ws && std::ranges::any_of(flights, [&ws](const UP<SCarry>& c) {
               const auto W = c->window.lock();
               return c->kind == eKind::TRANSLATE && !c->landed && W && W->m_workspace == ws;
           });
}

void Translation::pre(const PHLMONITOR& monitor) {
    std::vector<PHLWINDOW> cued;
    std::erase_if(flights, [&cued](const UP<SCarry>& c) {
        const auto W  = c->window.lock();
        const auto WS = W ? W->m_workspace : nullptr;
        if (!validMapped(W) || !WS || !WS->visible() || isSpecial(WS) || Fullscreen::controller()->hasFullscreen(WS)) {
            unveil(*c);
            return true;
        }
        c->armed      = true;
        c->goal       = W->geometricBox(GEO::GEOMETRIC_GOAL);
        const float T = ms(*c);
        if (c->opened >= SHUT && WS->m_alpha->value() >= 0.999F && !WS->m_alpha->isBeingAnimated() && !WS->m_renderOffset->isBeingAnimated()) {
            W->positionAnimation()->warp();
            W->sizeAnimation()->warp();
            c->goal   = W->geometricBox(GEO::GEOMETRIC_GOAL);
            c->opened = T;
            c->base   = T;
            plan(*c);
        }
        const bool DONE = !c->clock->isBeingAnimated();
        if (c->opened >= SHUT) {
            if (DONE)
                unveil(*c);
            return DONE;
        }
        if (!c->framed && T >= c->base) {
            c->framed = true;
            if (auto* const F = CGlassFrame::of(W))
                F->arrive(0);
        }
        if (c->kind == eKind::TRANSLATE && !c->cued && T >= weldOf(*c) - CUE) {
            c->cued = true;
            cued.push_back(W);
        }
        if (!c->landed && ((c->kind == eKind::PIVOT || c->kind == eKind::SWAP ? T >= std::max(SEATED, c->last + REGLAZE) : T >= c->base + c->last + REVEAL) || DONE)) {
            c->landed = true;
            unveil(*c);
        }
        const bool GONE = T >= endOf(*c) || DONE;
        if (GONE)
            unveil(*c);
        return GONE;
    });
    for (const auto& w : cued)
        announce(std::format("set,{}", addressOf(w)));
    std::erase_if(copies, [](const SCopy& g) {
        const auto M = g.monitor.lock();
        return !M || std::ranges::none_of(flights, [&M](const UP<SCarry>& c) { return (c->kind == eKind::PIVOT || c->kind == eKind::SWAP) && touches(*c, M); });
    });

    std::vector<SFell>        fell;
    std::vector<std::string>  lit;
    std::vector<const SPyre*> done;
    bool                      hushed = false;
    for (auto* const p : pyres | std::views::transform([](const UP<SPyre>& x) { return x.get(); }) | std::ranges::to<std::vector>())
        if (tend(*p, monitor, fell, lit, hushed))
            done.push_back(p);
    std::erase_if(pyres, [&done](const UP<SPyre>& p) { return std::ranges::contains(done, p.get()); });
    for (const auto& cues : lit)
        if (!cues.empty())
            announce(cues);
    if (hushed)
        Mullion::hush();
    for (const auto& f : fell) {
        launch(f.window, f.monitor ? f.monitor : monitor, f.snapshot, eKind::TRANSLATE, f.box);
        announce(std::format("translate,{}", addressOf(f.window)));
    }
    if (std::ranges::any_of(flights, [&monitor](const UP<SCarry>& c) { return touches(*c, monitor); }) ||
        std::ranges::any_of(pyres, [&monitor](const UP<SPyre>& p) { return touches(*p, monitor); }))
        g_pHyprRenderer->damageMonitor(monitor);
}

void Translation::exit() {
    for (auto& c : flights)
        unveil(*c);
    flights.clear();
    pyres.clear();
    seen.clear();
    copies.clear();
    g_pHyprRenderer->context().m_pass.removeAllOfType("CTranslationPass");
}

bool Translation::warm() {
    for (auto* p : {&quarryProgram, &huskProgram, &veilProgram, &sparkProgram, &weldProgram, &ashProgram, &infuseProgram, &strikeProgram, &pivotProgram, &poolProgram, &gateProgram})
        Gl::ready(*p);
    return true;
}

void Translation::destroy() {
    for (auto* p : {&quarryProgram, &huskProgram, &veilProgram, &sparkProgram, &weldProgram, &ashProgram, &infuseProgram, &strikeProgram, &pivotProgram, &poolProgram, &gateProgram})
        Gl::reset(*p);
}
