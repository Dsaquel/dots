#include "passage/Internal.hpp"

namespace Passage {
    const std::string HALL =
#include "passage.frag.inc"
        ;
    const std::string MOTE =
#include "mote.frag.inc"
        ;
    const std::string DUSTV =
#include "dust.vert.inc"
        ;

    SProgram hallProgram{.frag = &HALL, .name = "passage"};
    SProgram dustProgram{.frag = &MOTE, .name = "passage dust", .vert = &DUSTV};

    constexpr GLenum COMPILER_THREADS = 0x91B0, COMPLETION = 0x91B1;

    struct SPrime {
        GLuint program = 0;
        bool   started = false;
    };

    SPrime prime;

    GLuint compiled(GLenum type, const std::string& src) {
        const GLuint SHADER = glCreateShader(type);
        const char*  TEXT   = src.c_str();
        glShaderSource(SHADER, 1, &TEXT, nullptr);
        glCompileShader(SHADER);
        return SHADER;
    }

    void primeHall() {
        if (prime.started || hallProgram.shader || hallProgram.failed)
            return;
        prime.started       = true;
        const auto* EXTS    = reinterpret_cast<const char*>(glGetString(GL_EXTENSIONS));
        const auto  THREADS = reinterpret_cast<void (*)(GLuint)>(eglGetProcAddress("glMaxShaderCompilerThreadsKHR"));
        if (!EXTS || !std::string_view{EXTS}.contains("GL_KHR_parallel_shader_compile") || !THREADS) {
            Gl::ready(hallProgram);
            return;
        }
        GLint was = 0;
        glGetIntegerv(COMPILER_THREADS, &was);
        THREADS(0xFFFFFFFFU);
        const GLuint VERT = compiled(GL_VERTEX_SHADER, g_pHyprOpenGL->m_shaders->TEXVERTSRC);
        const GLuint FRAG = compiled(GL_FRAGMENT_SHADER, HALL);
        prime.program     = glCreateProgram();
        glAttachShader(prime.program, VERT);
        glAttachShader(prime.program, FRAG);
        glLinkProgram(prime.program);
        glDeleteShader(VERT);
        glDeleteShader(FRAG);
        THREADS(GLuint(was));
        while (glGetError() != GL_NO_ERROR)
            ;
    }

    bool hallReady() {
        if (hallProgram.shader || hallProgram.failed)
            return !hallProgram.failed;
        if (prime.program) {
            GLint done = 0;
            glGetProgramiv(prime.program, COMPLETION, &done);
            if (!done)
                return false;
            glDeleteProgram(prime.program);
            prime.program = 0;
        }
        return prime.started && Gl::ready(hallProgram);
    }

    class CPassagePass : public IPassElement {
      public:
        CPassagePass(PHLMONITORREF monitor) : m_monitor(monitor) {}
        virtual ~CPassagePass() = default;

        virtual std::vector<UP<IPassElement>> draw(Render::CRenderContext& ctx) override {

            Gl::ctx = &ctx;
            const auto  MON = m_monitor.lock();
            auto* const F   = MON ? flightOn(MON) : nullptr;
            if (!F || Gl::ctx->m_data.pMonitor.lock() != MON)
                return {};
            const bool TIME = g_glass->debug->value() > 1;
            if (TIME)
                glFinish();
            const auto START = std::chrono::steady_clock::now();
            drawFlight(*F, MON);
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
            return "CPassagePass";
        }
        virtual ePassElementType type() override {
            return EK_CUSTOM;
        }

      private:
        PHLMONITORREF m_monitor;
    };
}

bool Passage::claims(const PHLMONITOR& monitor, const PHLWORKSPACE& from, const PHLWORKSPACE& to, bool pyre) {
    const auto STYLE = styleNow();
    if (!STYLE || !to || !hallReady() || (pyre && STYLE != eStyle::NAVE))
        return false;
    if (const auto* F = flightOn(monitor); F && (F->pyre || !pyre))
        return true;
    return from && from != to && idOf(from) > 0 && idOf(to) > 0 && std::abs(idOf(to) - idOf(from)) <= REACH;
}

void Passage::take(const PHLMONITOR& monitor, const PHLWORKSPACE& from, const PHLWORKSPACE& to, bool pyre) {
    const auto STYLE      = styleNow();
    const auto [LO, HI]   = rangeOf(monitor);
    auto*      f          = flightOn(monitor);
    if (f && pyre && !f->pyre) {
        land(*f);
        std::erase_if(flights, [f](const UP<SFlight>& x) { return x.get() == f; });
        f = nullptr;
    }
    if (f) {
        if (f->to.lock() == to) {
            f->next.reset();
            return;
        }
        if (pyre && !f->hold && Translation::aims(to)) {
            f->next = to;
            hide(to);
            return;
        }
        f->pyre = pyre;
        turn(*f, monitor, to);
        return;
    }
    auto fl     = makeUnique<SFlight>();
    fl->monitor = monitor;
    fl->serial  = ++serials;
    fl->to      = to;
    fl->style   = *STYLE;
    fl->pyre    = pyre;
    fl->hold    = pyre;
    fl->first   = LO;
    fl->last    = HI;
    fl->from    = idOf(from);
    if (fl->style == eStyle::LANTERN && (idOf(from) < LO || idOf(from) > HI || idOf(to) < LO || idOf(to) > HI || HI - LO > 9))
        fl->style = eStyle::NAVE;
    if (fl->style == eStyle::LANTERN)
        furnish(*fl, monitor, LO, HI);
    else
        furnish(*fl, monitor, std::min(idOf(from), idOf(to)), std::max(idOf(from), idOf(to)));
    for (auto& r : fl->rooms)
        r.paper = r.id == idOf(from) || r.id == idOf(to) ? 1.F : 0.F;
    if (auto ORIGIN = std::ranges::find(fl->rooms, idOf(from), &SRoom::id); ORIGIN != fl->rooms.end()) {
        if (fl->style == eStyle::NAVE) {
            ORIGIN->shot = true;
            ORIGIN->seam = seamOf(monitor, from);
        } else
            shoot(*ORIGIN, monitor);
    }
    if (fl->style == eStyle::NAVE) {
        fl->canvas = canvas(monitor);
        fl->paper  = canvas(monitor);
        fl->live   = canvas(monitor);
        fl->held   = from;
        fl->forced = from->m_forceRendering;
        from->m_forceRendering = true;
        show(from, 1.F);
    } else
        hide(from);
    hide(to);
    fl->s     = float(idOf(from));
    fl->leg   = legOf(fl->s, 0.F, float(idOf(to)));
    fl->reach = std::abs(fl->leg.s1 - fl->leg.s0);
    if (pyre) {
        fl->ember = canvas(monitor);
        sight(*fl, monitor, to);
    } else
        clockOn(*fl, monitor);
    flights.emplace_back(std::move(fl));
    g_pHyprRenderer->damageMonitor(monitor);
}

void Passage::lead(const PHLMONITOR& monitor) {
    if (auto* const F = flightOn(monitor); F && F->next.lock())
        turn(*F, monitor, F->next.lock());
}

void Passage::finish(const PHLMONITOR& monitor) {
    std::erase_if(flights, [&monitor](const UP<SFlight>& f) {
        if (f->monitor.lock() != monitor || !f->pyre)
            return false;
        land(*f);
        return true;
    });
}

void Passage::cut(const PHLMONITOR& monitor) {
    std::erase_if(flights, [&monitor](const UP<SFlight>& f) {
        if (f->monitor.lock() != monitor)
            return false;
        land(*f);
        return true;
    });
}

void Passage::pre(const PHLMONITOR& monitor) {
    hallReady();
    std::erase_if(flights, [](const UP<SFlight>& f) {
        const auto MON = f->monitor.lock();
        if (MON && MON->m_enabled)
            return false;
        release(*f);
        show(f->to.lock(), 1.F);
        return true;
    });
    std::erase_if(irises, [](const auto& entry) {
        auto& [id, iris] = entry;
        if (std::ranges::any_of(State::monitorState()->monitors(), [id](const PHLMONITOR& m) { return m->m_id == id; }))
            return false;
        glDeleteFramebuffers(1, &iris.fbo);
        glDeleteBuffers(2, iris.pbo.data());
        return true;
    });
    auto* const F = flightOn(monitor);
    if (!F)
        return;
    if (F->hold) {
        if (Translation::holds(F->to.lock())) {
            g_pHyprRenderer->damageMonitor(monitor);
            return;
        }
        F->hold = false;
        clockOn(*F, monitor);
    }
    if (const auto NEXT = F->next.lock(); NEXT && !Translation::aims(NEXT) && !Translation::holds(F->to.lock())) {
        turn(*F, monitor, NEXT);
        return;
    }
    const float T = F->t;
    if (T >= F->leg.T + FADE || !F->clock) {
        land(*F);
        std::erase_if(flights, [F](const UP<SFlight>& x) { return x.get() == F; });
        return;
    }
    shootNext(*F, monitor);
    if (const auto TO = F->to.lock(); TO && (T > F->leg.T || (F->style == eStyle::NAVE && F->frames >= 2))) {
        show(TO, 1.F);
        F->shown = idOf(TO);
    }
    g_pHyprRenderer->damageMonitor(monitor);
}

void Passage::stage(const PHLMONITOR& monitor) {
    if (const auto* F = monitor ? flightOn(monitor) : nullptr; F && !F->hold)
        g_pHyprRenderer->addPassElement(*Gl::ctx, makeUnique<CPassagePass>(monitor));
}

bool Passage::flies(const PHLMONITOR& monitor) {
    return flightOn(monitor);
}

bool Passage::holding(const PHLMONITOR& monitor) {
    const auto* F = flightOn(monitor);
    return F && F->hold;
}

float Passage::walk(const PHLMONITOR& monitor, const PHLWORKSPACE& to) {
    const auto* F = flightOn(monitor);
    return F && !F->hold && F->to.lock() == to ? F->t : -1.F;
}

float Passage::length(const PHLMONITOR& monitor) {
    const auto* F = flightOn(monitor);
    return F ? F->leg.T : 0.F;
}

std::array<float, 4> Passage::lens(const PHLMONITOR& monitor) {
    const auto*    F = flightOn(monitor);
    const Vector2D C = monitor->logicalBoxMinusReserved().translate(-monitor->m_position).scale(monitor->m_scale).middle();
    const float    L = FOCAL * float(monitor->m_pixelSize.y);
    return {float(C.x), float(C.y), L, F ? std::abs(F->leg.s1 - F->leg.s0) * SPACING * L : 0.F};
}

std::optional<std::array<float, 3>> Passage::view(const PHLMONITOR& monitor) {
    const auto* F = flightOn(monitor);
    if (!F || F->hold || F->t >= F->leg.T)
        return std::nullopt;
    const auto [CAM, PHI] = poseOf(*F, monitor, F->s);
    const auto DOOR       = std::ranges::find(F->rooms, WORKSPACEID(std::lround(std::min(F->leg.s0, F->leg.s1))), &SRoom::id);
    return std::array{CAM, PHI, DOOR == F->rooms.end() ? float(monitor->m_pixelSize.x / 2) : DOOR->seam};
}

std::array<float, 2> Passage::pose(const PHLMONITOR& monitor, float t) {
    const auto* F = flightOn(monitor);
    return F ? poseOf(*F, monitor, along(F->leg, t).first) : std::array<float, 2>{};
}

void Passage::exit() {
    for (auto& f : flights)
        land(*f);
    flights.clear();
    g_pHyprRenderer->context().m_pass.removeAllOfType("CPassagePass");
}

bool Passage::warm() {
    primeHall();
    Gl::ready(dustProgram);
    return true;
}

void Passage::destroy() {
    for (auto& [id, iris] : irises) {
        glDeleteFramebuffers(1, &iris.fbo);
        glDeleteBuffers(2, iris.pbo.data());
    }
    irises.clear();
    if (prime.program)
        glDeleteProgram(prime.program);
    prime = {};
    Gl::reset(hallProgram);
    Gl::reset(dustProgram);
}
