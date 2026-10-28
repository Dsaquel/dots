#include "enfilade/Internal.hpp"

namespace Enfilade {
    float inOut(float k) {
        const float X = unit(k);
        return X < 0.5F ? 4.F * X * X * X : 1.F - std::pow(-2.F * X + 2.F, 3.F) / 2.F;
    }

    float soft(float k) {
        const float X = unit(k);
        return X * X * (3.F - 2.F * X);
    }

    struct SFull {
        CRegion damage;
        CBox    clip;

        SFull(const PHLMONITOR& monitor) {
            auto& rd = Gl::ctx->m_data;
            damage   = rd.damage.copy();
            clip     = rd.clipBox;
            rd.damage = CRegion{0, 0, monitor->m_pixelSize.x, monitor->m_pixelSize.y};
            rd.clipBox = {};
        }

        ~SFull() {
            auto& rd   = Gl::ctx->m_data;
            rd.damage  = damage;
            rd.clipBox = clip;
        }
    };

    SP<Render::IFramebuffer> canvas(const PHLMONITOR& monitor) {
        auto fb = g_pHyprRenderer->createFB("vitrail enfilade");
        fb->alloc(monitor->m_pixelSize.x, monitor->m_pixelSize.y, DRM_FORMAT_ABGR8888);
        fb->setImageDescription(monitor->workBufferImageDescription());
        return fb;
    }

    std::array<float, 2> strideOf(bool forward, float t, float depth, float focal) {
        const float ON = inOut(span(t, 70, STRIDE));
        return {forward ? depth * ON - RECOIL * focal * soft(span(t, 0, 110)) * (1.F - ON) : depth * std::pow(1.F - span(t, 0, STRIDE), 1.6F),
                forward ? OPEN * outCubic(span(t, 20, 250)) : OPEN * (1.F - inOut(span(t, 90, STRIDE)))};
    }

    std::array<float, 2> poseOf(const SMove& m, float t, float depth) {
        if (m.pyre)
            return strideOf(m.forward, t, depth, depth / (1.F / START - 1.F));
        return {m.forward ? depth * inOut(span(t, 20, WALK)) : depth * std::pow(1.F - span(t, 0, WALK), 2.4F),
                m.forward ? OPEN * outCubic(span(t, 0, WALK * 0.72F)) : OPEN * (1.F - inOut(span(t, 60, WALK)))};
    }

    SP<Render::IFramebuffer> composite(const std::vector<SP<Render::IFramebuffer>>& shots, const PHLMONITOR& monitor) {
        if (!Gl::ready(doorsProgram))
            return nullptr;
        auto        out = canvas(monitor);
        const SFull FULL(monitor);
        auto        guard = g_pHyprRenderer->bindTempFB(*Gl::ctx, out);
        g_pHyprRenderer->disableScissor();
        glClearColor(0.F, 0.F, 0.F, 0.F);
        glClear(GL_COLOR_BUFFER_BIT);
        g_pHyprOpenGL->blend(true);
        const auto AREA = Gl::areaOf(CBox{{}, monitor->m_pixelSize}, std::nullopt);
        if (!AREA)
            return out;
        auto& p = doorsProgram;
        g_pHyprOpenGL->useShader(p.shader);
        glUniform1f(p["mode"], 0.F);
        glUniform1i(p["farTex"], 0);
        glUniform2f(p["texSize"], monitor->m_pixelSize.x, monitor->m_pixelSize.y);
        glUniform4f(p["drawn"], AREA->drawn.x, AREA->drawn.y, AREA->drawn.w, AREA->drawn.h);
        for (const auto& shot : shots) {
            if (!shot || !shot->getTexture())
                continue;
            Gl::bindTex(0, shot->getTexture());
            Gl::paint(p, *AREA);
        }
        Gl::bindTex(0, nullptr);
        return out;
    }

    void prepare(SMove& m, const PHLMONITOR& monitor) {
        if (m.doorFB && m.farFB)
            return;
        SP<Render::IFramebuffer> flat;
        if (m.before) {
            prepare(*m.before, monitor);
            flat = canvas(monitor);
            const SFull FULL(monitor);
            auto        guard = g_pHyprRenderer->bindTempFB(*Gl::ctx, flat);
            g_pHyprRenderer->disableScissor();
            glClearColor(0.F, 0.F, 0.F, 0.F);
            glClear(GL_COLOR_BUFFER_BIT);
            g_pHyprOpenGL->blend(true);
            if (!m.before->landed)
                drawPlanes(*m.before, m.before->t, monitor);
        }
        const auto FROM = flat ? flat : composite(m.fromShots, monitor);
        const auto TO   = composite(m.toShots, monitor);
        m.doorFB        = m.forward ? FROM : TO;
        m.farFB         = m.forward ? TO : FROM;
        m.fromShots.clear();
        m.toShots.clear();
        m.before.reset();
    }

    void drawPlanes(SMove& m, float t, const PHLMONITOR& monitor) {
        if (!m.doorFB || !m.farFB || !Gl::ready(doorsProgram))
            return;
        const auto AREA = Gl::areaOf(CBox{{}, monitor->m_pixelSize}, std::nullopt);
        if (!AREA)
            return;
        const double   S     = monitor->m_scale;
        const Vector2D SIZE  = monitor->m_pixelSize;
        const Vector2D C     = monitor->logicalBoxMinusReserved().translate(-monitor->m_position).scale(S).middle();
        const float    F     = FOCAL * float(SIZE.y);
        const float    D     = F * (1.F / START - 1.F);
        const auto [CAM, PHI] = poseOf(m, t, D);
        const float    LEN   = lengthOf(m);
        const float    FAR   = m.forward ? span(t, 0, 80) : 1.F - span(t, LEN * 0.62F, LEN);
        const float    GLINT = m.forward ? std::exp(-std::pow((t - 25.F) / 40.F, 2.F)) : std::exp(-std::pow((t - LEN + 15.F) / 45.F, 2.F)) * (1.F - span(t, LEN - 40, LEN));
        const auto&    P     = pal();
        const auto&    U     = hue();
        const auto     L     = worldLightOn(monitor) * S;
        auto&          p     = doorsProgram;
        g_pHyprOpenGL->useShader(p.shader);
        glUniform1f(p["mode"], 1.F);
        glUniform1i(p["farTex"], 0);
        glUniform1i(p["doorTex"], 1);
        glUniform2f(p["texSize"], SIZE.x, SIZE.y);
        glUniform4f(p["drawn"], AREA->drawn.x, AREA->drawn.y, AREA->drawn.w, AREA->drawn.h);
        glUniform2f(p["centre"], C.x, C.y);
        glUniform2f(p["size"], SIZE.x, SIZE.y);
        glUniform1f(p["focal"], F);
        glUniform1f(p["cam"], CAM);
        glUniform1f(p["depth"], D);
        glUniform1f(p["wall"], REVEAL * float(SIZE.y));
        glUniform1f(p["phi"], PHI);
        glUniform1f(p["seam"], m.seam);
        glUniform1f(p["farAlpha"], FAR);
        glUniform1f(p["casingAlpha"], m.forward ? 1.F - span(t, LEN - 70, LEN - 5) : span(t, 0, 60));
        glUniform1f(p["glint"], GLINT);
        glUniform1f(p["arch"], ARCH * float(SIZE.x));
        glUniform1f(p["casing"], CASING * float(S));
        glUniform1f(p["scale"], S);
        glUniform4f(p["lightPos"], L.x, L.y, 0.F, 0.F);
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
        glUniform1i(p["liveTex"], 2);
        glUniform1f(p["live"], m.lit && m.liveFB ? (m.forward ? 1.F : 2.F) : 0.F);
        Gl::bindTex(0, m.farFB->getTexture());
        Gl::bindTex(1, m.doorFB->getTexture());
        Gl::bindTex(2, m.lit && m.liveFB ? m.liveFB->getTexture() : nullptr);
        Gl::paint(p, *AREA);
        Gl::bindTex(2, nullptr);
        Gl::bindTex(1, nullptr);
        Gl::bindTex(0, nullptr);
    }

    void blaze(SMove& m, const PHLMONITOR& monitor) {
        if (!m.liveFB)
            m.liveFB = canvas(monitor);
        const SFull FULL(monitor);
        auto        guard = g_pHyprRenderer->bindTempFB(*Gl::ctx, m.liveFB);
        g_pHyprRenderer->disableScissor();
        glClearColor(0.F, 0.F, 0.F, 0.F);
        glClear(GL_COLOR_BUFFER_BIT);
        g_pHyprOpenGL->blend(true);
        m.lit = Translation::blaze(monitor);
    }

    void drawMotes(SMove& m, float t, const PHLMONITOR& monitor) {
        if (!Gl::ready(moteProgram))
            return;
        const auto AREA = Gl::areaOf(CBox{{}, monitor->m_pixelSize}, std::nullopt);
        if (!AREA)
            return;
        const double   S    = monitor->m_scale;
        const Vector2D SIZE = monitor->m_pixelSize;
        const Vector2D C    = monitor->logicalBoxMinusReserved().translate(-monitor->m_position).scale(S).middle();
        const float    F    = FOCAL * float(SIZE.y);
        const auto&    U    = hue();
        auto&          p    = moteProgram;
        auto&          rd   = Gl::ctx->m_data;
        g_pHyprOpenGL->useShader(p.shader);
        CBox whole{0, 0, SIZE.x, SIZE.y};
        rd.renderModif.applyToBox(whole);
        p.shader->setUniformMatrix3fv(SHADER_PROJ, 1, GL_TRUE, g_pHyprRenderer->projectBoxToTarget(*Gl::ctx, whole).getMatrix());
        glUniform2f(p["target"], SIZE.x, SIZE.y);
        glUniform2f(p["centre"], C.x, C.y);
        glUniform2f(p["size"], SIZE.x, SIZE.y);
        glUniform1f(p["focal"], F);
        glUniform1f(p["depth"], F * (1.F / START - 1.F));
        glUniform1f(p["wall"], REVEAL * float(SIZE.y));
        glUniform1f(p["t"], t);
        glUniform1f(p["tEnd"], WALK);
        glUniform1f(p["back"], m.forward ? 0.F : 1.F);
        glUniform1f(p["scale"], S);
        glUniform1f(p["casing"], CASING * float(S));
        glUniform1f(p["arch"], ARCH * float(SIZE.x));
        glUniform1f(p["seam"], m.seam);
        glUniform4fv(p["seat"], SEATS, m.seats.data());
        Gl::rgb(p, "dust", U.dust);
        Gl::rgb(p, "hot", U.hot);
        Gl::rgb(p, "keyline", pal().dark ? U.gold : U.leaf);
        glUniform1f(p["ink"], U.inked);
        glBindVertexArray(p.shader->getUniformLocation(SHADER_SHADER_VAO));
        AREA->region.forEachRect([&rd](const auto& RECT) {
            g_pHyprOpenGL->scissor(*Gl::ctx, &RECT, rd.transformDamage);
            glDrawArrays(GL_POINTS, 0, MOTES);
        });
        glBindVertexArray(0);
        g_pHyprOpenGL->disableScissor();
    }
}
