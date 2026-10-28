#include "enfilade/Internal.hpp"

namespace Enfilade {
    const std::string DOORS =
#include "enfilade.frag.inc"
        ;
    const std::string MOTE =
#include "mote.frag.inc"
        ;
    const std::string MOTEV =
#include "mote.vert.inc"
        ;

    SProgram doorsProgram{.frag = &DOORS, .name = "enfilade"};
    SProgram moteProgram{.frag = &MOTE, .name = "mote", .vert = &MOTEV};

    class CEnfiladePass : public IPassElement {
      public:
        CEnfiladePass(PHLMONITORREF monitor) : m_monitor(monitor) {}
        virtual ~CEnfiladePass() = default;

        virtual std::vector<UP<IPassElement>> draw(Render::CRenderContext& ctx) override {

            Gl::ctx = &ctx;
            const auto MON = m_monitor.lock();
            auto* const M  = MON ? moveOn(MON) : nullptr;
            if (!M || M->held || Gl::ctx->m_data.pMonitor.lock() != MON)
                return {};
            const bool TIME  = g_glass->debug->value() > 1;
            if (TIME)
                glFinish();
            const auto START = std::chrono::steady_clock::now();
            g_pHyprOpenGL->blend(true);
            M->t = ms(*M);
            if (!M->landed) {
                prepare(*M, MON);
                if (M->pyre)
                    blaze(*M, MON);
                Gl::nudge = Translation::kick(MON) * MON->m_scale;
                drawPlanes(*M, M->t, MON);
                Gl::nudge = {};
            }
            if (!M->pyre)
                drawMotes(*M, M->t, MON);
            Gl::unbindAll();
            g_pHyprOpenGL->blend(true);
            if (TIME) {
                glFinish();
                const uint64_t NS = std::chrono::duration_cast<std::chrono::nanoseconds>(std::chrono::steady_clock::now() - START).count();
                g_glass->enfNs += NS;
                g_glass->enfMaxNs = std::max(g_glass->enfMaxNs, NS);
                ++g_glass->enfTimed;
            }
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
            return "CEnfiladePass";
        }
        virtual ePassElementType type() override {
            return EK_CUSTOM;
        }

      private:
        PHLMONITORREF m_monitor;
    };
}

void Enfilade::begin(const PHLWORKSPACE& to) {
    if (!g_glass->enabled->value() || !g_glass->enfilade->value() || !to || isSpecial(to))
        return;
    const auto MON = to->m_monitor.lock();
    if (!MON || !MON->m_output || !MON->m_enabled || !onScreens(MON) || MON->m_activeSpecialWorkspace || (g_pSessionLockManager && g_pSessionLockManager->isSessionLocked()))
        return;
    const auto AIMED  = Translation::aims(to);
    const auto ORIGIN = AIMED ? AIMED : Translation::holds(to);
    if (auto* const M = moveOn(MON); M && M->pyre && !M->held && !M->landed && (AIMED || M->to.lock() == to)) {
        if (M->to.lock() == to)
            M->next.reset();
        else {
            M->next = to;
            to->m_alpha->setValueAndWarp(0.F);
            to->m_renderOffset->setValueAndWarp({});
        }
        return;
    }
    PHLWORKSPACE from;
    UP<SMove>    held;
    if (const auto HELD = std::ranges::find_if(moves, [&MON](const UP<SMove>& x) { return x->monitor.lock() == MON && x->held; }); HELD != moves.end()) {
        held = std::move(*HELD);
        from = held->from.lock();
        moves.erase(HELD);
    } else
        for (const auto& ref : State::workspaceState()->workspaces()) {
            const auto WS = ref.lock();
            if (WS && WS != to && !isSpecial(WS) && WS->m_monitor == MON && WS->m_alpha->isBeingAnimated() && WS->m_alpha->goal() == 0.F &&
                (!from || WS->m_alpha->value() > from->m_alpha->value()))
                from = WS;
        }
    const bool PYRE = ORIGIN && (!from || idOf(from) == *ORIGIN || Passage::holding(MON));
    if ((!ORIGIN || PYRE) && Passage::claims(MON, from, to, PYRE)) {
        hush(MON);
        if (held)
            unhold(*held);
        std::erase_if(moves, [&MON](const UP<SMove>& x) {
            if (x->monitor.lock() != MON)
                return false;
            unhold(*x);
            reveal(*x);
            release(*x);
            return true;
        });
        Passage::take(MON, from, to, PYRE);
        return;
    }
    Passage::cut(MON);
    if ((!from && !ORIGIN) || from == to) {
        if (held)
            unhold(*held);
        return;
    }

    hush(MON);
    auto       m    = makeUnique<SMove>();
    const auto IT   = std::ranges::find_if(moves, [&MON](const UP<SMove>& x) { return x->monitor.lock() == MON; });
    if (IT != moves.end()) {
        auto old = std::move(*IT);
        moves.erase(IT);
        if (!old->landed) {
            reveal(*old);
            m->before = !old->doorFB && old->before ? std::move(old->before) : std::move(old);
            m->before->lit = false;
        }
    }
    m->monitor = MON;
    m->from    = from;
    m->to      = to;
    m->forward = idOf(to) > (from ? idOf(from) : *ORIGIN);
    if (PYRE) {
        if (held)
            unhold(*held);
        m->pyre = true;
        if (!Translation::holds(to)) {
            start(*m, MON);
            moves.emplace_back(std::move(m));
            g_pHyprRenderer->damageMonitor(MON);
            return;
        }
        m->held = true;
        m->before.reset();
        if (from) {
            m->forced = from->m_forceRendering;
            from->m_alpha->setValueAndWarp(1.F);
            from->m_renderOffset->setValueAndWarp({});
            from->m_forceRendering = true;
        }
        to->m_alpha->setValueAndWarp(0.F);
        to->m_renderOffset->setValueAndWarp({});
    } else {
        start(*m, MON);
        if (held)
            unhold(*held);
    }
    moves.emplace_back(std::move(m));
    g_pHyprRenderer->damageMonitor(MON);
}

bool Enfilade::holding(const PHLMONITOR& monitor) {
    if (Passage::flies(monitor))
        return Passage::holding(monitor);
    const auto* M = moveOn(monitor);
    return M && M->held;
}

bool Enfilade::flies(const PHLMONITOR& monitor) {
    return Passage::flies(monitor);
}

float Enfilade::walk(const PHLMONITOR& monitor, const PHLWORKSPACE& to) {
    if (Passage::flies(monitor))
        return Passage::walk(monitor, to);
    const auto* M = moveOn(monitor);
    return M && !M->held && M->clock && M->to.lock() == to ? ms(*M) : -1.F;
}

float Enfilade::length(const PHLMONITOR& monitor) {
    return Passage::flies(monitor) ? Passage::length(monitor) : STRIDE;
}

void Enfilade::lead(const PHLMONITOR& monitor) {
    if (Passage::flies(monitor)) {
        Passage::lead(monitor);
        return;
    }
    const auto IT = std::ranges::find_if(moves, [&monitor](const UP<SMove>& x) { return x->monitor.lock() == monitor && x->next.lock(); });
    if (IT == moves.end())
        return;
    auto old = std::move(*IT);
    moves.erase(IT);
    auto m     = makeUnique<SMove>();
    m->monitor = monitor;
    m->from    = old->to;
    m->to      = old->next;
    m->pyre    = true;
    m->forward = !old->to.lock() || idOf(old->next.lock()) > idOf(old->to.lock());
    if (!old->landed) {
        old->t   = ms(*old);
        old->lit = false;
        m->before = std::move(old);
    }
    start(*m, monitor);
    moves.emplace_back(std::move(m));
    g_pHyprRenderer->damageMonitor(monitor);
}

void Enfilade::finish(const PHLMONITOR& monitor) {
    if (Passage::flies(monitor)) {
        Passage::finish(monitor);
        return;
    }
    auto* const M = moveOn(monitor);
    if (!M || !M->pyre || M->landed)
        return;
    if (!M->held) {
        land(*M);
        return;
    }
    unhold(*M);
    reveal(*M);
    std::erase_if(moves, [M](const UP<SMove>& x) { return x.get() == M; });
    g_pHyprRenderer->damageMonitor(monitor);
}

std::array<float, 4> Enfilade::lens(const PHLMONITOR& monitor) {
    if (Passage::flies(monitor))
        return Passage::lens(monitor);
    const Vector2D C = monitor->logicalBoxMinusReserved().translate(-monitor->m_position).scale(monitor->m_scale).middle();
    const float    F = FOCAL * float(monitor->m_pixelSize.y);
    return {float(C.x), float(C.y), F, F * (1.F / START - 1.F)};
}

std::optional<std::array<float, 3>> Enfilade::view(const PHLMONITOR& monitor) {
    if (Passage::flies(monitor))
        return Passage::view(monitor);
    const auto* M = moveOn(monitor);
    if (!M || M->held || M->landed || !M->clock)
        return std::nullopt;
    const auto [CAM, PHI] = poseOf(*M, ms(*M), lens(monitor)[3]);
    return std::array{CAM, PHI, M->seam};
}

std::array<float, 2> Enfilade::pose(const PHLMONITOR& monitor, bool forward, float t) {
    if (Passage::flies(monitor))
        return Passage::pose(monitor, t);
    const auto LENS = lens(monitor);
    return strideOf(forward, t, LENS[3], LENS[2]);
}

void Enfilade::pre(const PHLMONITOR& monitor) {
    std::erase_if(moves, [](const UP<SMove>& m) {
        if (const auto MON = m->monitor.lock(); MON && MON->m_enabled)
            return false;
        unhold(*m);
        reveal(*m);
        release(*m);
        return true;
    });
    auto* const M = moveOn(monitor);
    if (!M)
        return;
    if (const auto NEXT = M->next.lock(); NEXT && !Translation::aims(NEXT) && !Translation::holds(M->to.lock())) {
        lead(monitor);
        return;
    }
    if (M->held) {
        if (Translation::holds(M->to.lock())) {
            g_pHyprRenderer->damageMonitor(monitor);
            return;
        }
        start(*M, monitor);
        unhold(*M);
        if (!M->clock) {
            reveal(*M);
            std::erase_if(moves, [M](const UP<SMove>& x) { return x.get() == M; });
        }
        return;
    }
    const float T = ms(*M);
    if (!M->landed && (T >= lengthOf(*M) || !M->clock->isBeingAnimated()))
        land(*M);
    if (!M->clock->isBeingAnimated()) {
        std::erase_if(moves, [M](const UP<SMove>& x) { return x.get() == M; });
        g_pHyprRenderer->damageMonitor(monitor);
        return;
    }
    g_pHyprRenderer->damageMonitor(monitor);
}

void Enfilade::stage(const PHLMONITOR& monitor) {
    if (const auto* M = monitor ? moveOn(monitor) : nullptr; M && !M->held)
        g_pHyprRenderer->addPassElement(*Gl::ctx, makeUnique<CEnfiladePass>(monitor));
}

void Enfilade::exit() {
    for (auto& m : moves) {
        unhold(*m);
        reveal(*m);
        release(*m);
    }
    moves.clear();
    g_pHyprRenderer->context().m_pass.removeAllOfType("CEnfiladePass");
}

bool Enfilade::warm() {
    Gl::ready(doorsProgram);
    Gl::ready(moteProgram);
    return true;
}

void Enfilade::destroy() {
    Gl::reset(doorsProgram);
    Gl::reset(moteProgram);
}
