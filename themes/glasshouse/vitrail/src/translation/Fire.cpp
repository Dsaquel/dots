#include "translation/Internal.hpp"

namespace Translation {
    std::array<float, 4> timesOf(const SPyre& p, float t) {
        const float DOORS = p.doors < SHUT ? p.doors : std::max(HOLD, t);
        const float HIT = p.walks ? p.stride + ARRIVE - Enfilade::STRIDE : LEAP, OPEN = HIT + Enfilade::STRIDE - ARRIVE;
        return {DOORS, DOORS + HIT, p.seated < SHUT ? p.seated : DOORS + OPEN, DOORS + HIT + QUENCHED};
    }

    std::optional<CBox> seamOf(const PHLMONITOR& a, const PHLMONITOR& b) {
        const CBox   A{a->m_position, a->m_size}, B{b->m_position, b->m_size};
        const auto   NEAR = [](double x, double y) { return std::abs(x - y) < 1; };
        const double X0 = std::max(A.x, B.x), X1 = std::min(A.x + A.w, B.x + B.w), Y0 = std::max(A.y, B.y), Y1 = std::min(A.y + A.h, B.y + B.h);
        if ((NEAR(A.x + A.w, B.x) || NEAR(B.x + B.w, A.x)) && Y1 - Y0 > 1)
            return CBox{NEAR(A.x + A.w, B.x) ? B.x : A.x, Y0, 0, Y1 - Y0};
        if ((NEAR(A.y + A.h, B.y) || NEAR(B.y + B.h, A.y)) && X1 - X0 > 1)
            return CBox{X0, NEAR(A.y + A.h, B.y) ? B.y : A.y, X1 - X0, 0};
        return std::nullopt;
    }

    Vector2D awayOf(const SPyre& p) {
        const auto LAND = p.monitor.lock(), SRC = p.from.lock();
        return LAND && SRC ? (SRC->m_position - LAND->m_position) * LAND->m_scale : Vector2D{};
    }

    bool touches(const SPyre& p, const PHLMONITOR& m) {
        return p.monitor.lock() == m || p.from.lock() == m || p.past.lock() == m;
    }

    void rewire(SPyre& p) {
        const PHLMONITORREF LAND = p.monitor, FROM = p.from, PAST = p.past;
        p.clock->setUpdateCallback([LAND, FROM, PAST](auto) {
            for (const auto& ref : {LAND, FROM, PAST})
                if (const auto M = ref.lock())
                    g_pHyprRenderer->damageMonitor(M);
        });
    }

    void cloak(SPyre& p, const PHLWINDOW& w) {
        if (p.shroud)
            return;
        p.shroud = w->effects().transformers()->emplace<CShroud>();
    }

    void drawAsh(const SPyre& p, float t, const PHLMONITOR& m) {
        const CBox WHOLE{{}, m->m_pixelSize};
        const auto AREA = Gl::areaOf(WHOLE, std::nullopt);
        const auto LAND = p.monitor.lock(), SRC = p.from.lock();
        if (!AREA || !LAND || !SRC || !p.snapshot || !p.snapshot->getTexture() || !Gl::ready(ashProgram))
            return;
        const auto     P     = pathOf(p, t);
        const auto&    U     = hue();
        const Vector2D SHIFT = (LAND->m_position - m->m_position) * m->m_scale;
        auto&          a     = ashProgram;
        g_pHyprOpenGL->useShader(a.shader);
        project(a, m);
        glUniform2f(a["target"], P.target.x, P.target.y);
        glUniform4f(a["frame"], SHIFT.x, SHIFT.y, m->m_pixelSize.x, m->m_pixelSize.y);
        glUniform2f(a["away"], P.away.x, P.away.y);
        glUniform1f(a["bridge"], P.bridge);
        glUniform4fv(a["seam"], 1, P.seam.data());
        glUniform2fv(a["poses"], POSES, P.poses.data());
        glUniform1f(a["stride"], P.stride);
        glUniform1i(a["tex"], 0);
        glUniform2f(a["texSize"], p.snapshot->m_size.x, p.snapshot->m_size.y);
        glUniform4fv(a["shot"], 1, P.shot.data());
        glUniform1f(a["t"], t);
        glUniform4fv(a["burn"], 1, P.burn.data());
        glUniform1f(a["burnSeed"], P.burnSeed);
        glUniform1f(a["scale"], P.scale);
        glUniform4fv(a["lens"], 1, P.lens.data());
        glUniform4fv(a["view"], 1, P.view.data());
        glUniform1f(a["forward"], P.forward);
        glUniform1f(a["alone"], P.alone);
        glUniform4fv(a["times"], 1, P.times.data());
        glUniform4fv(a["slot"], 1, P.slot.data());
        glUniform2f(a["entry"], P.entry.x, P.entry.y);
        glUniform2f(a["came"], P.came.x, P.came.y);
        glUniform4fv(a["turn"], 1, P.turn.data());
        glUniform3fv(a["wake"], WAKE, P.wake.front().data());
        glUniform2f(a["heading"], P.heading.x, P.heading.y);
        glUniform1f(a["seed"], p.seed);
        glUniform1f(a["haste"], HASTE);
        glUniform2f(a["fired"], p.fired.x, p.fired.y);
        glUniform1f(a["spurred"], p.spurred);
        glUniform1f(a["nave"], P.nave);
        Gl::rgb(a, "hot", U.hot);
        Gl::rgb(a, "gold", U.gold);
        Gl::rgb(a, "leaf", U.leaf);
        Gl::rgb(a, "sepia", U.sepia);
        Gl::rgb(a, "jewel0", U.jewel0);
        Gl::rgb(a, "jewel1", U.jewel1);
        Gl::rgb(a, "jewel2", U.jewel2);
        glUniform1f(a["ink"], U.inked);
        Gl::bindTex(0, p.snapshot->getTexture());
        auto& rd = Gl::ctx->m_data;
        glBindVertexArray(a.shader->getUniformLocation(SHADER_SHADER_VAO));
        AREA->region.forEachRect([&rd](const auto& RECT) {
            g_pHyprOpenGL->scissor(*Gl::ctx, &RECT, rd.transformDamage);
            glDrawArrays(GL_POINTS, 0, MOTES * TRAIL);
        });
        glBindVertexArray(0);
        g_pHyprOpenGL->disableScissor();
        Gl::bindTex(0, nullptr);
    }

    void drawInfuse(const SPyre& p, float t, const PHLMONITOR& m) {
        const auto TIMES = timesOf(p, t);
        if (p.alone || t < TIMES[1] - PACKED || t > TIMES[3] || !Gl::ready(infuseProgram))
            return;
        const auto LENS = p.lens;
        const auto VIEW = Enfilade::view(m);
        const auto AREA = Gl::areaOf(VIEW ? CBox{{}, m->m_pixelSize} : p.slot.copy().expand(2), std::nullopt);
        if (!AREA)
            return;
        const auto&    U    = hue();
        const Vector2D CAME = cameOf(p);
        auto&          f    = infuseProgram;
        g_pHyprOpenGL->useShader(f.shader);
        glUniform4f(f["drawn"], AREA->drawn.x, AREA->drawn.y, AREA->drawn.w, AREA->drawn.h);
        glUniform4f(f["win"], p.slot.x, p.slot.y, p.slot.w, p.slot.h);
        glUniform2f(f["came"], CAME.x, CAME.y);
        glUniform1f(f["radius"], p.radius * m->m_scale);
        glUniform1f(f["scale"], m->m_scale);
        glUniform1f(f["t"], t);
        glUniform4f(f["times"], TIMES[0], TIMES[1], TIMES[2], TIMES[3]);
        glUniform2f(f["entry"], p.entry.x, p.entry.y);
        glUniform4f(f["lens"], LENS[0], LENS[1], LENS[2], LENS[3]);
        glUniform4f(f["view"], VIEW ? (*VIEW)[0] : 0.F, VIEW ? (*VIEW)[1] : 0.F, VIEW ? (*VIEW)[2] : 0.F, VIEW ? 1.F : 0.F);
        glUniform1f(f["forward"], p.forward ? 1.F : 0.F);
        glUniform2f(f["target"], m->m_pixelSize.x, m->m_pixelSize.y);
        glUniform1f(f["seed"], p.seed);
        Gl::rgb(f, "hot", U.hot);
        Gl::rgb(f, "gold", U.gold);
        Gl::rgb(f, "jewel0", U.jewel0);
        Gl::rgb(f, "jewel1", U.jewel1);
        Gl::rgb(f, "jewel2", U.jewel2);
        Gl::rgb(f, "leaf", U.leaf);
        glUniform4fv(f["cut"], 1, p.cut.data());
        glUniform1f(f["ink"], U.inked);
        Gl::paint(f, *AREA);
    }

    void drawStrike(const SPyre& p, float t, const PHLMONITOR& m) {
        const auto TIMES = timesOf(p, t);
        if (t < TIMES[1] - PACKED || t > TIMES[1] + STRUCK || !Gl::ready(strikeProgram))
            return;
        const auto AREA = Gl::areaOf(CBox{{}, m->m_pixelSize}.expand(KICK * m->m_pixelSize.y), std::nullopt);
        if (!AREA)
            return;
        const auto&        U    = hue();
        const auto         LENS = p.lens;
        const auto         VIEW = Enfilade::view(m);
        const auto         P    = pathOf(p, t);
        const auto         SEEN = [&P](double tau) { return project(P, spineAt(P, tau), P.view[0]).at; };
        const Vector2D     HEAD = SEEN(std::min(t, TIMES[1])), TAIL = SEEN(t - SPEAR);
        std::vector<float> boxes, rounds;
        for (const auto& L : p.leads) {
            boxes.insert(boxes.end(), L.begin(), L.begin() + 4);
            rounds.push_back(L[4]);
        }
        auto& s = strikeProgram;
        g_pHyprOpenGL->useShader(s.shader);
        glUniform4f(s["drawn"], AREA->drawn.x, AREA->drawn.y, AREA->drawn.w, AREA->drawn.h);
        glUniform1f(s["t"], t);
        glUniform4f(s["times"], TIMES[0], TIMES[1], TIMES[2], TIMES[3]);
        glUniform2f(s["entry"], p.entry.x, p.entry.y);
        glUniform4f(s["spear"], HEAD.x, HEAD.y, TAIL.x, TAIL.y);
        glUniform1f(s["scale"], m->m_scale);
        glUniform4f(s["lens"], LENS[0], LENS[1], LENS[2], LENS[3]);
        glUniform4f(s["view"], VIEW ? (*VIEW)[0] : 0.F, VIEW ? (*VIEW)[1] : 0.F, VIEW ? (*VIEW)[2] : 0.F, VIEW ? 1.F : 0.F);
        glUniform1f(s["forward"], p.forward ? 1.F : 0.F);
        glUniform2f(s["target"], m->m_pixelSize.x, m->m_pixelSize.y);
        if (!rounds.empty()) {
            glUniform4fv(s["leads"], GLsizei(rounds.size()), boxes.data());
            glUniform1fv(s["rounds"], GLsizei(rounds.size()), rounds.data());
        }
        glUniform1f(s["count"], float(rounds.size()));
        glUniform1f(s["seed"], p.seed);
        Gl::rgb(s, "hot", U.hot);
        Gl::rgb(s, "gold", U.gold);
        Gl::rgb(s, "jewel0", U.jewel0);
        Gl::rgb(s, "jewel1", U.jewel1);
        Gl::rgb(s, "jewel2", U.jewel2);
        Gl::rgb(s, "leaf", U.leaf);
        glUniform1f(s["ink"], U.inked);
        Gl::paint(s, *AREA);
    }
}
