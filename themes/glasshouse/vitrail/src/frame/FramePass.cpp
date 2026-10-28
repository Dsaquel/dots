#include "frame/Ornament.hpp"
#include "frame/Frame.hpp"
#include "life/Life.hpp"
#include "mullion/Mullion.hpp"
#include "enfilade/Enfilade.hpp"
#include "passage/Passage.hpp"
#include "glaze/Glaze.hpp"
#include "translation/Translation.hpp"
#include "core/Assets.hpp"
#include "core/globals.hpp"

#include <hyprland/src/render/Renderer.hpp>
#include <hyprland/src/render/OpenGL.hpp>
#include <hyprland/src/render/Shader.hpp>
#include <hyprland/src/output/Monitor.hpp>
#include <hyprland/src/debug/log/Logger.hpp>

#include <algorithm>
#include <array>
#include <chrono>
#include <cmath>
#include <optional>

using namespace Render::GL;

namespace Frame {
    const std::string SKIN =
#include "skin.frag.inc"
        ;
    const std::string ORNAMENT =
#include "ornament.frag.inc"
        ;
    const std::string PLATE =
#include "plate.frag.inc"
        ;
    const std::string GLOWING =
#include "glow.frag.inc"
        ;
    const std::string LETTER =
#include "letter.frag.inc"
        ;

    SProgram skinProgram{.frag = &SKIN, .name = "skin"};
    SProgram ornamentProgram{.frag = &ORNAMENT, .name = "ornament"};
    SProgram plateProgram{.frag = &PLATE, .name = "plate"};
    SProgram glowProgram{.frag = &GLOWING, .name = "glow"};
    SProgram letterProgram{.frag = &LETTER, .name = "letter"};

    uint64_t drainGL(bool ours) {
        uint64_t n = 0;
        for (GLenum e = glGetError(); e != GL_NO_ERROR && n < 16; e = glGetError(), ++n) {
            if (ours)
                LOG(Log::ERR, "[vitrail] GL error 0x{:x} in the frame pass", e);
        }
        return n;
    }

    std::array<float, 4> premul(const std::array<float, 4>& c, float a) {
        return {c[0] * c[3] * a, c[1] * c[3] * a, c[2] * c[3] * a, c[3] * a};
    }
}

using namespace Frame;

static void drawSkin(const CGlassPass::SData& d) {
    if (!ready(skinProgram))
        return;
    const double S    = d.scale;
    const CBox   WIN  = d.window.copy().scale(S).round();
    const double E    = std::round((CGlassFrame::MARGIN + d.reach) * S);
    const CBox   QUAD = WIN.copy().expand(E);
    if (QUAD.w < 1 || QUAD.h < 1)
        return;

    const auto& P      = *d.pal;
    const auto  VEIL   = d.probe ? std::array<float, 4>{} : premul(P.veil, (1.F - d.level) * d.veil);
    const auto  SHADOW = d.probe ? std::array<float, 4>{} : premul(P.shadow, d.lift);
    const bool  GRAND  = d.build[0] >= 0 && d.build[2] > 0.5F;
    const auto  HOLE   = VEIL[3] < 1e-3F && SHADOW[3] < 1e-3F && (d.build[0] < 0 || GRAND) ?
           std::optional<CBox>{d.window.copy().expand(-(std::max(d.radius, 0.F) + (GRAND ? 310.0 : (d.hinge[0] >= 0 ? 60.0 : 13.0)))).scale(S).round()} :
           std::nullopt;
    const auto  AREA   = areaOf(QUAD, HOLE);
    if (!AREA)
        return;

    auto& p = skinProgram;
    g_pHyprOpenGL->useShader(p.shader);
    const Vector2D ORIGIN = QUAD.pos() / S;
    glUniform2f(p["box"], QUAD.w / S, QUAD.h / S);
    glUniform4f(p["win"], E / S, E / S, WIN.w / S, WIN.h / S);
    glUniform1f(p["radius"], d.radius);
    glUniform1f(p["offset"], d.offset);
    glUniform1f(p["hwOff"], d.hwOff);
    glUniform1f(p["hwOn"], d.hwOn);
    glUniform4f(p["lightPos"], d.light.x - ORIGIN.x, d.light.y - ORIGIN.y, 520.F, 640.F);
    if (p.stamp.first != &P) {
        p.stamp = {&P, 0};
        glUniform1f(p["pieceLen"], 72.F);
        rgb(p, "pool", SRGB{P.lamp.r / P.poolDarker, P.lamp.g / P.poolDarker, P.lamp.b / P.poolDarker});
        rgb(p, "base", P.metalBase);
        rgb(p, "hi", P.metalHi);
        rgb(p, "low", P.metalLow);
        rgb(p, "sky", P.metalSky);
        rgb(p, "jewelA", P.jewelA);
        rgb(p, "jewelB", P.jewelB);
        rgb(p, "jewelC", P.jewelC);
        rgb(p, "pearl", P.pearl);
        rgb(p, "hot", P.hot);
        glUniform1f(p["unlit"], P.unlit);
        glUniform1f(p["dark"], P.dark ? 1.F : 0.F);
        glUniform1f(p["specGain"], P.specGain);
        glUniform1f(p["shininess"], P.shininess);
    }
    glUniform1f(p["on"], d.level);
    glUniform4fv(p["laid"], 1, d.laid.data());
    glUniform4fv(p["gap"], 1, d.gap.data());
    glUniform4fv(p["hinge"], 1, d.hinge.data());
    glUniform4fv(p["athanor"], 1, d.athanor.data());
    glUniform4fv(p["grow"], 1, d.grow.data());
    glUniform4f(p["gone"], d.gone[0] - ORIGIN.x, d.gone[1] - ORIGIN.y, d.gone[2], d.gone[3]);
    glUniform2f(p["vanish"], d.vanish[0] - ORIGIN.x, d.vanish[1] - ORIGIN.y);
    glUniform4fv(p["seal"], 1, d.seal.data());
    glUniform4fv(p["build"], 1, d.build.data());
    glUniform4fv(p["room"], 1, d.room.data());
    glUniform1f(p["seed"], d.seed);
    glUniform4fv(p["cut"], 1, d.cut.data());
    glUniform4fv(p["melt"], 1, d.melt.data());
    glUniform4f(p["call"], P.alert.r, P.alert.g, P.alert.b, d.call);
    glUniform4f(p["veil"], VEIL[0], VEIL[1], VEIL[2], VEIL[3]);
    glUniform4f(p["shadow"], SHADOW[0], SHADOW[1], SHADOW[2], SHADOW[3]);
    glUniform2f(p["shadowOffset"], 0.F, 4.F + 12.F * d.lift);
    glUniform1f(p["shadowBlur"], 16.F + 24.F * d.lift);
    glUniform1f(p["alpha"], d.alpha);
    glUniform1f(p["probe"], d.probe ? 1.F : 0.F);
    paint(p, *AREA);
}

static void drawLantern(const CGlassPass::SData& d) {
    if (!d.lantern || d.lanternGlow * d.alpha < 0.003F || !ready(glowProgram))
        return;
    const auto AREA = areaOf(d.lantern->copy().scale(d.scale).round(), std::nullopt);
    if (!AREA)
        return;

    auto& p = glowProgram;
    g_pHyprOpenGL->useShader(p.shader);
    rgb(p, "tint", d.pal->lamp);
    glUniform1f(p["core"], 0.09F);
    glUniform1f(p["intensity"], 1.35F);
    glUniform1f(p["opacity"], d.lanternGlow * d.alpha);
    paint(p, *AREA);
}

bool warmGlassPrograms() {
    if (!g_pHyprOpenGL || !g_pHyprOpenGL->m_shadersInitialized)
        return false;
    g_pHyprOpenGL->makeEGLCurrent();
    for (auto* p : {&skinProgram, &ornamentProgram, &plateProgram, &glowProgram, &letterProgram})
        ready(*p);
    for (const auto* dir : {"dark", "light"})
        for (int kind = 0; kind < 3; ++kind)
            Assets::kit(dir, kind);
    Assets::texture("shared/glass-noise.png");
    return Life::warm() && Mullion::warm() && Enfilade::warm() && Passage::warm() && Translation::warm() && Glaze::warm();
}

void destroyGlassPrograms() {
    g_pHyprOpenGL->makeEGLCurrent();
    Assets::clear();
    for (auto* p : {&skinProgram, &ornamentProgram, &plateProgram, &glowProgram, &letterProgram})
        Gl::reset(*p);
    Life::destroy();
    Mullion::destroy();
    Enfilade::destroy();
    Passage::destroy();
    Translation::destroy();
    Glaze::destroy();
}

CGlassPass::CGlassPass(SData&& data) : m_data(std::move(data)) {
    ;
}

std::vector<UP<IPassElement>> CGlassPass::draw(Render::CRenderContext& ctx) {
    Gl::ctx = &ctx;
    paint();
    return {};
}

void CGlassPass::paint() {
    if (!Gl::ctx->m_data.pMonitor.lock() || !m_data.pal)
        return;

    ++g_glass->passes;
    const bool CHECK = g_glass->debug->value() > 0;
    if (CHECK)
        g_glass->glForeign += drainGL(false);

    const bool TIME = g_glass->debug->value() > 1;
    if (TIME)
        glFinish();
    const auto START = std::chrono::steady_clock::now();

    g_pHyprOpenGL->blend(true);
    drawSkin(m_data);
    bool textured = false;
    for (const auto& pc : m_data.pieces)
        textured = drawPiece(pc, *m_data.pal, m_data.alpha, m_data.scale) || textured;
    textured = drawPlate(m_data.plate, *m_data.pal, m_data.light, m_data.alpha, m_data.scale) || textured;
    if (textured)
        unbindAll();
    drawLantern(m_data);

    if (TIME) {
        glFinish();
        g_glass->timedNs += std::chrono::duration_cast<std::chrono::nanoseconds>(std::chrono::steady_clock::now() - START).count();
        ++g_glass->timed;
    }

    if (CHECK)
        g_glass->glErrors += drainGL(true);
}

bool CGlassPass::needsLiveBlur(Render::CRenderContext& ctx) {
    return false;
}

bool CGlassPass::needsPrecomputeBlur(Render::CRenderContext& ctx) {
    return false;
}

std::optional<CBox> CGlassPass::boundingBox(Render::CRenderContext& ctx) {
    const CBox FRAME = m_data.window.copy().expand(CGlassFrame::MARGIN + m_data.reach);
    if (!m_data.lantern)
        return FRAME;
    const double X0 = std::min(FRAME.x, m_data.lantern->x), Y0 = std::min(FRAME.y, m_data.lantern->y);
    return CBox{X0, Y0, std::max(FRAME.x + FRAME.w, m_data.lantern->x + m_data.lantern->w) - X0, std::max(FRAME.y + FRAME.h, m_data.lantern->y + m_data.lantern->h) - Y0};
}

const char* CGlassPass::passName() {
    return "CGlassPass";
}

ePassElementType CGlassPass::type() {
    return EK_CUSTOM;
}
