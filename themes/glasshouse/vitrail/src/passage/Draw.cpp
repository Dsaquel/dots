#include "passage/Internal.hpp"
#include "core/Ease.hpp"

namespace Passage {
    void uniforms(SProgram& p, const SStage& st, const SFlight& f, const PHLMONITOR& monitor) {
        const float    H  = float(monitor->m_pixelSize.y);
        const float    F  = FOCAL * H;
        const Vector2D C  = monitor->logicalBoxMinusReserved().translate(-monitor->m_position).scale(monitor->m_scale).middle();
        const auto&    P  = pal();
        const auto&    U  = hue();
        const auto     L  = worldLightOn(monitor) * monitor->m_scale;
        const V3       LAMP = st.cam.eye + st.cam.r * float((L.x - C.x) * 2.2) + st.cam.u * float((L.y - C.y) * 2.2) + st.cam.f * (0.45F * F);
        glUniform1i(p["tex"], 0);
        glUniform2f(p["texSize"], monitor->m_pixelSize.x, monitor->m_pixelSize.y);
        glUniform3f(p["eye"], st.cam.eye.x, st.cam.eye.y, st.cam.eye.z);
        glUniform3f(p["camR"], st.cam.r.x, st.cam.r.y, st.cam.r.z);
        glUniform3f(p["camU"], st.cam.u.x, st.cam.u.y, st.cam.u.z);
        glUniform3f(p["camF"], st.cam.f.x, st.cam.f.y, st.cam.f.z);
        glUniform2f(p["centre"], C.x, C.y);
        glUniform1f(p["focal"], st.lens > 0 ? st.lens : F);
        glUniform1f(p["rest"], F);
        glUniform2f(p["size"], monitor->m_pixelSize.x, monitor->m_pixelSize.y);
        glUniform1f(p["wall"], WALL * H);
        glUniform1f(p["casing"], CASING * float(monitor->m_scale));
        glUniform1f(p["arch"], f.style == eStyle::LANTERN ? 0.F : ARCH * float(monitor->m_pixelSize.x));
        glUniform1f(p["glass"], f.lift);
        glUniform1f(p["fogK"], (P.dark ? FOG : FOG * 0.45F) * f.lift);
        glUniform1f(p["focus"], st.focus);
        glUniform1f(p["blurK"], BLUR * f.lift);
        glUniform3f(p["lamp"], LAMP.x, LAMP.y, LAMP.z);
        Gl::rgb(p, "fogColor", P.dark ? HAZE_DARK : HAZE_LIGHT);
        Gl::rgb(p, "leadBase", P.metalBase);
        Gl::rgb(p, "leadHi", P.metalHi);
        Gl::rgb(p, "leadLow", P.metalLow);
        Gl::rgb(p, "keyline", P.dark ? U.gold : U.leaf);
        Gl::rgb(p, "hot", U.hot);
        Gl::rgb(p, "jewel0", U.jewel0);
        Gl::rgb(p, "jewel1", U.jewel1);
        Gl::rgb(p, "jewel2", U.jewel2);
        Gl::rgb(p, "edgeGlass", P.dark ? U.jewel2 : P.jewelB);
        Gl::rgb(p, "sepia", U.sepia);
        glUniform1f(p["ink"], U.inked);
    }

    void paintPlace(SProgram& p, const SPlace& pl, const SRoom& room, const SStage& st, const PHLMONITOR& monitor) {
        const auto BOX = boundsOf(pl, room, st, monitor);
        if (!BOX)
            return;
        const auto AREA = Gl::areaOf(*BOX, std::nullopt);
        if (!AREA)
            return;
        const auto [CODE, LEN] = romanOf(room.id);
        glUniform1f(p["mode"], 1.F);
        glUniform4f(p["drawn"], AREA->drawn.x, AREA->drawn.y, AREA->drawn.w, AREA->drawn.h);
        glUniform3f(p["origin"], pl.origin.x, pl.origin.y, pl.origin.z);
        glUniform3f(p["axisX"], pl.x.x, pl.x.y, pl.x.z);
        glUniform3f(p["axisY"], pl.y.x, pl.y.y, pl.y.z);
        glUniform3f(p["axisZ"], pl.z.x, pl.z.y, pl.z.z);
        glUniform1f(p["phi"], pl.phi);
        glUniform1f(p["seam"], room.seam);
        glUniform1f(p["doors"], pl.doors ? 1.F : 0.F);
        glUniform1f(p["frame"], pl.frame);
        glUniform1f(p["kindle"], pl.kindle);
        glUniform1f(p["dim"], pl.dim);
        glUniform1i(p["roman"], CODE);
        glUniform1i(p["romanLen"], LEN);
        glUniform1f(p["filled"], room.fb ? 1.F : 0.F);
        glUniform1f(p["mirror"], pl.mirrored ? st.floor : 0.F);
        Gl::bindTex(0, room.fb ? room.fb->getTexture() : nullptr);
        Gl::paint(p, *AREA);
    }

    void paintGlow(SProgram& p, const SStage& st, const SFlight& f, const PHLMONITOR& monitor) {
        const float    F = FOCAL * float(monitor->m_pixelSize.y);
        const Vector2D C = monitor->logicalBoxMinusReserved().translate(-monitor->m_position).scale(monitor->m_scale).middle();
        const V3       P = st.glow - st.cam.eye;
        const float    Z = dot(P, st.cam.f);
        const auto     AREA = Gl::areaOf(CBox{{}, monitor->m_pixelSize}, std::nullopt);
        if (Z < 1.F || !AREA)
            return;
        const auto& U = hue();
        glUniform1f(p["mode"], 4.F);
        glUniform4f(p["drawn"], AREA->drawn.x, AREA->drawn.y, AREA->drawn.w, AREA->drawn.h);
        glUniform2f(p["glowAt"], C.x + dot(P, st.cam.r) * F / Z, C.y + dot(P, st.cam.u) * F / Z);
        glUniform1f(p["glowR"], st.glowR * F / Z);
        glUniform4f(p["glow"], U.hot.r, U.hot.g, U.hot.b, 0.22F * f.lift);
        Gl::paint(p, *AREA);
    }

    void hallUniforms(SProgram& p, const SStage& st, const SFlight& f, const PHLMONITOR& monitor) {
        const float                W = float(monitor->m_pixelSize.x), H = float(monitor->m_pixelSize.y);
        const float                CW = CASING * float(monitor->m_scale);
        const auto&                P  = pal();
        const size_t               N  = std::min<size_t>(st.doors.size(), DOORS);
        std::array<float, DOORS>   z{}, phi{}, seam{}, reveal{}, paper{}, kindle{}, light{}, lit{};
        std::array<int, DOORS>     roman{}, romanLen{}, slot{};
        for (size_t i = 0; i < N; ++i) {
            const auto& D = st.doors[i];
            const auto& R = f.rooms[D.room];
            z[i]          = D.z;
            phi[i]        = D.phi;
            seam[i]       = R.seam;
            reveal[i]     = D.reveal;
            paper[i]      = R.paper;
            kindle[i]     = D.kindle;
            light[i]      = D.light;
            lit[i]        = D.lit;
            slot[i]       = D.slot;
            std::tie(roman[i], romanLen[i]) = romanOf(R.id);
            if (D.slot >= 0)
                Gl::bindTex(1 + D.slot, imageOf(f, R)->getTexture());
        }
        glUniform1i(p["doorsN"], int(N));
        glUniform1fv(p["doorZ"], GLsizei(N), z.data());
        glUniform1fv(p["doorPhi"], GLsizei(N), phi.data());
        glUniform1fv(p["doorSeam"], GLsizei(N), seam.data());
        glUniform1fv(p["doorReveal"], GLsizei(N), reveal.data());
        glUniform1fv(p["doorPaper"], GLsizei(N), paper.data());
        glUniform1fv(p["doorKindle"], GLsizei(N), kindle.data());
        glUniform1fv(p["doorLight"], GLsizei(N), light.data());
        glUniform1fv(p["doorLit"], GLsizei(N), lit.data());
        glUniform1iv(p["doorRoman"], GLsizei(N), roman.data());
        glUniform1iv(p["doorRomanLen"], GLsizei(N), romanLen.data());
        glUniform1iv(p["doorSlot"], GLsizei(N), slot.data());
        glUniform1i(p["shot0"], 1);
        glUniform1i(p["shot1"], 2);
        glUniform1i(p["shot2"], 3);
        glUniform1i(p["shot3"], 4);
        glUniform1i(p["paper"], 5);
        Gl::bindTex(5, f.paper ? f.paper->getTexture() : nullptr);
        glUniform1f(p["spacing"], SPACING * FOCAL * H);
        glUniform1f(p["aisle"], AISLE * W);
        glUniform1f(p["vault"], -ARCH * W - 0.4F * H);
        glUniform1f(p["floorY"], H + 0.6F * CW);
        Gl::rgb(p, "stone", P.dark ? STONE_DARK : STONE_LIGHT);
        Gl::rgb(p, "paving", P.dark ? PAVING_DARK : PAVING_LIGHT);
        Gl::rgb(p, "ambient", P.dark ? AMBIENT_DARK : AMBIENT_LIGHT);
        Gl::rgb(p, "flame", P.dark ? FLAME_DARK : FLAME_LIGHT);
        Gl::rgb(p, "screenTint", P.dark ? SCREEN_DARK : SCREEN_LIGHT);
        Gl::rgb(p, "came", P.dark ? CAME_DARK : hue().sepia);
        const Vector2D C    = monitor->logicalBoxMinusReserved().translate(-monitor->m_position).scale(monitor->m_scale).middle();
        const float    SIDE = worldLightOn(monitor).x * monitor->m_scale > C.x ? 1.F : -1.F;
        const V3       SUN  = norm(P.dark ? V3{-SIDE * 0.85F, 0.42F, -0.16F} : V3{-SIDE * 0.75F, 0.62F, -0.14F});
        glUniform3f(p["sunDir"], SUN.x, SUN.y, SUN.z);
        const SRGB MOON = P.dark ? MOON_DARK : SUN_LIGHT;
        const float GAIN = (P.dark ? 0.75F : 1.0F) * f.lift;
        glUniform3f(p["sun"], MOON.r * GAIN, MOON.g * GAIN, MOON.b * GAIN);
        glUniform1f(p["glaze"], P.dark ? 0.9F : 1.0F);
        glUniform1f(p["lanternGain"], P.dark ? 2.6F : 0.45F);
        glUniform1f(p["swell"], P.dark ? 0.6F : 0.2F);
        glUniform1f(p["haze"], (P.dark ? 0.00011F : 0.00004F) * f.lift);
        const SRGB STONE = P.dark ? STONE_DARK : STONE_LIGHT;
        glUniform3f(p["leadBase"], STONE.r * 1.15F, STONE.g * 1.15F, STONE.b * 1.15F);
        if (P.dark)
            Gl::rgb(p, "fogColor", NIGHT);
        glUniform1f(p["fogK"], (P.dark ? 0.00024F : FOG * 0.3F) * f.lift);
        glUniform3f(p["leadLow"], STONE.r * 0.3F, STONE.g * 0.3F, STONE.b * 0.3F);
        Gl::rgb(p, "leadHi", hue().hot);
        glUniform1f(p["polish"], P.dark ? 0.85F : 0.35F);
    }

    void paintDust(const SStage& st, const SFlight& f, const PHLMONITOR& monitor) {
        if (!Gl::ready(dustProgram))
            return;
        const auto AREA = Gl::areaOf(CBox{{}, monitor->m_pixelSize}, std::nullopt);
        if (!AREA)
            return;
        const Vector2D SIZE = monitor->m_pixelSize;
        const Vector2D C    = monitor->logicalBoxMinusReserved().translate(-monitor->m_position).scale(monitor->m_scale).middle();
        const auto&    U    = hue();
        auto&          p    = dustProgram;
        auto&          rd   = Gl::ctx->m_data;
        g_pHyprOpenGL->useShader(p.shader);
        CBox whole{0, 0, SIZE.x, SIZE.y};
        rd.renderModif.applyToBox(whole);
        p.shader->setUniformMatrix3fv(SHADER_PROJ, 1, GL_TRUE, g_pHyprRenderer->projectBoxToTarget(*Gl::ctx, whole).getMatrix());
        glUniform2f(p["target"], SIZE.x, SIZE.y);
        glUniform3f(p["eye"], st.cam.eye.x, st.cam.eye.y, st.cam.eye.z);
        glUniform3f(p["camR"], st.cam.r.x, st.cam.r.y, st.cam.r.z);
        glUniform3f(p["camU"], st.cam.u.x, st.cam.u.y, st.cam.u.z);
        glUniform3f(p["camF"], st.cam.f.x, st.cam.f.y, st.cam.f.z);
        glUniform2f(p["centre"], C.x, C.y);
        glUniform1f(p["focal"], st.lens > 0 ? st.lens : FOCAL * float(SIZE.y));
        glUniform1f(p["rest"], FOCAL * float(SIZE.y));
        glUniform1f(p["fogK"], FOG);
        glUniform1f(p["t"], f.t);
        glUniform1f(p["amount"], f.lift);
        glUniform1f(p["scale"], monitor->m_scale);
        glUniform3f(p["boxLo"], st.boxLo.x, st.boxLo.y, st.boxLo.z);
        glUniform3f(p["boxHi"], st.boxHi.x, st.boxHi.y, st.boxHi.z);
        Gl::rgb(p, "dust", U.dust);
        Gl::rgb(p, "hot", U.hot);
        Gl::rgb(p, "keyline", pal().dark ? U.gold : U.leaf);
        glUniform1f(p["ink"], U.inked);
        const size_t             N = std::min<size_t>(st.doors.size(), DOORS);
        std::array<float, DOORS> z{}, shut{};
        for (size_t i = 0; i < N; ++i) {
            z[i]    = st.doors[i].z;
            shut[i] = f.rooms[st.doors[i].room].paper * (1.F - smooth(st.doors[i].phi / 0.4F));
        }
        glUniform1i(p["doorsN"], int(N));
        glUniform1fv(p["doorZ"], GLsizei(N), z.data());
        glUniform1fv(p["doorShut"], GLsizei(N), shut.data());
        glUniform2f(p["size"], SIZE.x, SIZE.y);
        glUniform1f(p["wall"], WALL * float(SIZE.y));
        glBindVertexArray(p.shader->getUniformLocation(SHADER_SHADER_VAO));
        AREA->region.forEachRect([&rd](const auto& RECT) {
            g_pHyprOpenGL->scissor(*Gl::ctx, &RECT, rd.transformDamage);
            glDrawArrays(GL_POINTS, 0, DUSTS);
        });
        glBindVertexArray(0);
        g_pHyprOpenGL->disableScissor();
    }

    void drawFlight(SFlight& f, const PHLMONITOR& monitor) {
        if (!Gl::ready(hallProgram))
            return;
        advance(f, monitor);
        const bool NAVE = f.style == eStyle::NAVE;
        if (NAVE)
            back(f, monitor);
        for (auto& r : f.rooms)
            develop(r, monitor);
        if (f.pyre && NAVE)
            blaze(f, monitor);
        if (!f.canvas)
            f.canvas = canvas(monitor);
        const auto st   = stageOf(f, monitor);
        auto&      p    = hallProgram;
        const auto FULL = Gl::areaOf(CBox{{}, monitor->m_pixelSize}, std::nullopt);
        const float FADED = 1.F - smooth((f.t - f.leg.T) / FADE);
        g_pHyprOpenGL->blend(true);
        g_pHyprOpenGL->useShader(p.shader);
        uniforms(p, st, f, monitor);
        if (FULL && f.lift > 0.001F && !NAVE) {
            const auto& P = pal();
            const SRGB  V = P.dark ? VEIL_DARK : VEIL_LIGHT;
            const float A = (P.dark ? VEIL : VEIL * 0.6F) * f.lift;
            glUniform1f(p["mode"], 3.F);
            glUniform4f(p["drawn"], FULL->drawn.x, FULL->drawn.y, FULL->drawn.w, FULL->drawn.h);
            glUniform4f(p["veil"], V.r, V.g, V.b, A);
            const auto& U = hue();
            glUniform4f(p["glow"], U.hot.r, U.hot.g, U.hot.b, (P.dark ? 0.16F : 0.14F) * f.lift);
            glUniform1f(p["ground"], (P.dark ? 0.62F : 0.3F) * f.lift);
            Gl::paint(p, *FULL);
        }
        {
            const SFull WHOLE(monitor);
            auto        guard = g_pHyprRenderer->bindTempFB(*Gl::ctx, f.canvas);
            g_pHyprRenderer->disableScissor();
            glClearColor(0.F, 0.F, 0.F, 0.F);
            glClear(GL_COLOR_BUFFER_BIT);
            g_pHyprOpenGL->blend(true);
            g_pHyprOpenGL->useShader(p.shader);
            uniforms(p, st, f, monitor);
            glUniform1f(p["sheen"], (pal().dark ? 0.5F : 0.32F) * f.lift);
            if (NAVE) {
                if (const auto AREA = Gl::areaOf(CBox{{}, monitor->m_pixelSize}, std::nullopt)) {
                    hallUniforms(p, st, f, monitor);
                    glUniform1f(p["mode"], 5.F);
                    glUniform4f(p["drawn"], AREA->drawn.x, AREA->drawn.y, AREA->drawn.w, AREA->drawn.h);
                    Gl::paint(p, *AREA);
                    Gl::unbindAll();
                }
            } else {
                if (f.lift > 0.01F)
                    for (auto pl : st.places) {
                        pl.mirrored = true;
                        paintPlace(p, pl, f.rooms[pl.room], st, monitor);
                    }
                bool glowed = f.style != eStyle::LANTERN;
                for (const auto& pl : st.places) {
                    if (!glowed && pl.dim > 0.99F) {
                        paintGlow(p, st, f, monitor);
                        glowed = true;
                    }
                    paintPlace(p, pl, f.rooms[pl.room], st, monitor);
                }
            }
            Gl::bindTex(0, nullptr);
            paintDust(st, f, monitor);
        }
        if (NAVE) {
            mipmap(f.canvas);
            gaze(f, monitor);
        }
        if (FULL) {
            const Vector2D C = monitor->logicalBoxMinusReserved().translate(-monitor->m_position).scale(monitor->m_scale).middle();
            g_pHyprOpenGL->useShader(p.shader);
            glUniform1f(p["mode"], 2.F);
            glUniform1i(p["tex"], 0);
            glUniform2f(p["texSize"], monitor->m_pixelSize.x, monitor->m_pixelSize.y);
            glUniform4f(p["drawn"], FULL->drawn.x, FULL->drawn.y, FULL->drawn.w, FULL->drawn.h);
            glUniform2f(p["vanish"], C.x, C.y);
            glUniform1f(p["zoomBlur"], st.zoom);
            glUniform2f(p["sweep"], st.sweep.x, st.sweep.y);
            glUniform1f(p["fade"], FADED);
            glUniform1f(p["rays"], (pal().dark ? 0.8F : 0.1F) * f.lift * (NAVE ? 0.6F : 1.F));
            glUniform1f(p["bloom"], NAVE ? (pal().dark ? 0.9F : 0.4F) * f.lift : 0.F);
            glUniform1f(p["bloomCut"], pal().dark ? 0.32F : 0.85F);
            glUniform1f(p["shoulder"], NAVE ? f.lift : 0.F);
            const auto  GOAL = NAVE && f.shown ? f.live : f.canvas;
            const float SPAN = f.leg.s1 - f.leg.s0;
            glUniform3f(p["adapt"], std::max(f.adapted, 0.F), NAVE && f.adapted >= 0 ? f.lift : 0.F, GOAL == f.canvas || SPAN == 0.F ? 0.F : unit((f.s - f.leg.s0) / SPAN));
            glUniform1i(p["goal"], 1);
            Gl::bindTex(1, GOAL->getTexture());
            Gl::bindTex(0, f.canvas->getTexture());
            Gl::paint(p, *FULL);
            Gl::bindTex(0, nullptr);
            Gl::bindTex(1, nullptr);
        }
    }
}
