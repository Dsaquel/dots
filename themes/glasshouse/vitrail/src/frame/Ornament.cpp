#include "frame/Ornament.hpp"
#include "core/Assets.hpp"
#include "core/Ease.hpp"

#include <hyprland/src/render/Renderer.hpp>
#include <hyprland/src/render/OpenGL.hpp>

#include <algorithm>
#include <array>
#include <cmath>
#include <ranges>

using namespace Render::GL;
using namespace Frame;

static double lowest(const std::array<Vector2D, 4>& v, bool y) {
    return std::ranges::min(v | std::views::transform([y](const Vector2D& p) { return y ? p.y : p.x; }));
}

static double highest(const std::array<Vector2D, 4>& v, bool y) {
    return std::ranges::max(v | std::views::transform([y](const Vector2D& p) { return y ? p.y : p.x; }));
}

static Vector2D itemToScreen(const SPiece& pc, double lx, double ly) {
    const double TH = pc.quarter * M_PI / 2, C = std::cos(TH), SN = std::sin(TH), K = std::max(pc.scale, 0.01F);
    const double X = (lx - pc.pivot.x) * K, Y = (ly - pc.pivot.y) * K;
    return Vector2D{pc.origin.x + X * C - Y * SN, pc.origin.y + X * SN + Y * C};
}

static std::array<float, 9> screenToItem(const SPiece& pc, const CBox& phys, double S) {
    const double   TH = pc.quarter * M_PI / 2, C = std::cos(TH), SN = std::sin(TH), K = std::max(pc.scale, 0.01F);
    const Vector2D P0 = phys.pos() / S, D = phys.size() / S, Q = P0 - pc.origin;
    const double   KS = K * pc.size;
    return {float(C * D.x / KS),
            float(-SN * D.x / KS),
            0.F,
            float(SN * D.y / KS),
            float(C * D.y / KS),
            0.F,
            float((pc.pivot.x + (C * Q.x + SN * Q.y) / K) / pc.size),
            float((pc.pivot.y + (-SN * Q.x + C * Q.y) / K) / pc.size),
            1.F};
}

bool Frame::drawPiece(const SPiece& pc, const SPalette& P, float alpha, double S) {
    if (pc.opacity * alpha < 0.003F || !ready(ornamentProgram))
        return false;

    const std::array<Vector2D, 4> CORNERS = {itemToScreen(pc, 0, 0), itemToScreen(pc, pc.size, 0), itemToScreen(pc, 0, pc.size), itemToScreen(pc, pc.size, pc.size)};
    const double                  X0 = lowest(CORNERS, false), Y0 = lowest(CORNERS, true);
    const CBox                    PHYS = CBox{X0, Y0, highest(CORNERS, false) - X0, highest(CORNERS, true) - Y0}.scale(S).round();
    const auto                    AREA = areaOf(PHYS, std::nullopt);
    if (!AREA)
        return false;

    const bool  FLOWER = pc.kind == SPiece::FLOWER;
    const bool  CREST  = pc.kind == SPiece::CREST;
    const auto& KIT    = Assets::kit(P.dir, pc.kind);
    const auto  ICON   = CREST && !pc.icon.empty() ? Assets::emblemIcon(pc.icon) : nullptr;
    const auto  MARK   = ICON ? ICON : (CREST && !pc.mark.empty() ? Assets::emblem(pc.mark, pc.glyph) : nullptr);
    const auto  TO     = screenToItem(pc, PHYS, S);

    auto& p = ornamentProgram;
    g_pHyprOpenGL->useShader(p.shader);
    if (p.stamp != std::pair<const SPalette*, int>{&P, pc.kind}) {
        p.stamp        = {&P, pc.kind};
        const auto& M1 = FLOWER || CREST ? P.trim : PEARL;
        glUniform4f(p["layers"], KIT.glow ? 1.F : 0.F, KIT.glass ? 1.F : 0.F, KIT.lead ? 1.F : 0.F, KIT.trim ? 1.F : 0.F);
        rgb(p, "mBase[0]", P.lead.base);
        rgb(p, "mHi[0]", P.lead.hi);
        rgb(p, "mLow[0]", P.lead.low);
        rgb(p, "mSky[0]", P.lead.sky);
        glUniform4f(p["mParam[0]"], P.lead.metal, P.lead.shininess, P.lead.depth, 1.4F);
        rgb(p, "mBase[1]", M1.base);
        rgb(p, "mHi[1]", M1.hi);
        rgb(p, "mLow[1]", M1.low);
        rgb(p, "mSky[1]", M1.sky);
        glUniform4f(p["mParam[1]"], M1.metal, M1.shininess, M1.depth, FLOWER ? 1.4F : 0.9F);
        glUniform4f(p["emRect"], 15.F / 52.F, 15.F / 52.F, 37.F / 52.F, 37.F / 52.F);
        rgb(p, "emBase", P.emBase);
        rgb(p, "emHi", P.emHi);
        rgb(p, "emLow", P.emLow);
        for (const auto& [u, unit] :
             std::initializer_list<std::pair<const char*, int>>{{"glowTex", 0}, {"glassTex", 1}, {"leadTex", 2}, {"giltTex", 3}, {"grainTex", 4}, {"emblemTex", 5}, {"partTex", 6}})
            glUniform1i(p[u], unit);
        glUniform4fv(p["partAxis"], 4, KIT.axis[0].data());
        glUniform4fv(p["partTime"], 4, KIT.timing[0].data());
        glUniform4fv(p["bloom"], 1, KIT.bloom.data());
        glUniform1f(p["forming"], P.dark ? 1.F : 0.35F);
        rgb(p, "spark", P.hot);
    }
    glUniform1f(p["grow"], FLOWER && KIT.parts ? pc.grow : 1.F);
    glUniformMatrix3fv(p["toItem"], 1, GL_FALSE, TO.data());
    glUniform1f(p["hasEmblem"], MARK ? 1.F : 0.F);
    glUniform1f(p["opacity"], pc.opacity * alpha);
    glUniform1f(p["texel"], 1.F / pc.size);
    glUniform2f(p["grainScale"], pc.size / 256.F, pc.size / 256.F);
    glUniform4f(p["gParam[0]"], FLOWER ? pc.glow * 0.8F : pc.glow * 0.55F, 0.F, 3.F, 0.F);
    glUniform2f(p["gLight[0]"], FLOWER ? pc.glassLight.x : 0.42F, FLOWER ? pc.glassLight.y : 0.38F);
    glUniform4f(p["gParam[1]"], FLOWER ? 0.16F + 0.5F * pc.glow : 0.2F + 0.3F * pc.glow, 0.52F, FLOWER ? 1.6F : 1.2F, 0.12F);
    glUniform2f(p["gLight[1]"], pc.glassLight.x, pc.glassLight.y);
    glUniform2f(p["mLight[0]"], pc.metalLight.x, pc.metalLight.y);
    glUniform2f(p["mLight[1]"], pc.metalLight.x, pc.metalLight.y);
    bindTex(0, KIT.glow);
    bindTex(1, KIT.glass);
    bindTex(2, KIT.lead);
    bindTex(3, KIT.trim);
    bindTex(4, Assets::texture("shared/glass-noise.png"));
    bindTex(5, MARK);
    bindTex(6, FLOWER ? KIT.parts : nullptr);
    paint(p, *AREA);
    return true;
}

static float letterAt(const SPlateSpec& pl, size_t n, size_t i) {
    return unit((pl.stream * (pl.spread + pl.flight) - (n > 1 ? pl.spread * float(i) / float(n - 1) : 0.F)) / pl.flight);
}

static void drawLetters(const SPlateSpec& pl, const SPlateText& T, const SPalette& P, const CBox& plate, const CBox& pane, float alpha, double S) {
    if (!ready(letterProgram))
        return;
    auto& p     = letterProgram;
    bool  bound = false;
    CBox  clip  = pane;
    Gl::ctx->m_data.renderModif.applyToBox(clip);
    for (size_t i = 0; i < T.letters.size(); ++i) {
        const float K = letterAt(pl, T.letters.size(), i);
        if (K <= 0.F)
            continue;
        const float  E    = 1.F - std::pow(1.F - K, 3.F);
        const auto&  L    = T.letters[i];
        const double DX   = std::round(16.0 * S * (1.F - E));
        const double X0   = std::floor(L.first * S) - 2;
        const CBox   QUAD = {plate.x + X0 + DX, plate.y, std::ceil((L.second - L.first) * S) + 5, plate.h};
        auto         area = areaOf(QUAD, std::nullopt);
        if (!area)
            continue;
        area->region.intersect(clip);
        if (area->region.empty())
            continue;
        g_pHyprOpenGL->useShader(p.shader);
        if (!bound) {
            bound = true;
            glUniform1i(p["textTex"], 0);
            rgb(p, "hot", P.hot);
            bindTex(0, T.tex);
        }
        glUniform2f(p["box"], float(QUAD.w / S), float(QUAD.h / S));
        glUniform4f(p["textRect"], float(X0 / S - T.origin.x), float(-T.origin.y), float(T.size.x), float(T.size.y));
        glUniform2f(p["cols"], L.first, L.second);
        glUniform1f(p["opacity"], pl.opacity * alpha * std::pow(unit(K / 0.55F), 1.5F));
        glUniform1f(p["glint"], pl.leaving ? 0.F : 0.6F * std::exp(-std::pow((K - 0.75F) / 0.12F, 2.F)) * std::min(1.F, 4.F * (1.F - K)));
        paint(p, *area);
    }
}

bool Frame::drawPlate(const SPlateSpec& pl, const SPalette& P, const Vector2D& light, float alpha, double S) {
    if (!pl.on || pl.opacity * alpha < 0.003F || !ready(plateProgram))
        return false;

    const auto&  T    = Assets::plate(pl.app, pl.title, P.dark, pl.maxWidth, S);
    const bool   FLOW = pl.stream < 1.F && !T.letters.empty();
    const size_t N    = T.letters.size();
    const double FULL = std::max(64.0, std::min(T.natural, pl.maxWidth));
    const float  OPEN = FLOW ? 1.F - std::pow(1.F - unit(pl.stream * (pl.spread + pl.flight) / std::max(pl.flight + 0.45F * pl.spread, 1.F)), 3.F) : 1.F;
    const double W    = std::max(22.0, FULL * OPEN);
    const CBox   SLOT = CBox{pl.pos.x, pl.pos.y, FULL, 22.0}.scale(S).round();
    const CBox   PHYS = CBox{pl.pos.x, pl.pos.y, W, 22.0}.scale(S).round();
    const auto   AREA = areaOf(PHYS, std::nullopt);
    if (!AREA || !T.tex)
        return false;

    auto& p = plateProgram;
    g_pHyprOpenGL->useShader(p.shader);
    const Vector2D BOX   = PHYS.size() / S;
    const Vector2D LOCAL = light - PHYS.pos() / S;
    glUniform2f(p["box"], BOX.x, BOX.y);
    glUniform1f(p["radius"], 7.F);
    glUniform1f(p["rim"], P.plateRim);
    rgb(p, "glassTop", P.glassTop);
    rgb(p, "glassBottom", P.glassBottom);
    glUniform1f(p["glassAlpha"], P.glassAlpha);
    rgb(p, "base", P.plateBase);
    rgb(p, "hi", P.plateHi);
    rgb(p, "low", P.plateLow);
    glUniform2f(p["lightPos"], LOCAL.x, LOCAL.y);
    glUniform1f(p["lightZ"], 260.F);
    glUniform1f(p["innerLine"], P.innerLine);
    rgb(p, "innerColor", INNER);
    glUniform1f(p["grain"], 0.08F);
    glUniform2f(p["grainScale"], BOX.x / 256.F, BOX.y / 256.F);
    glUniform4f(p["textRect"], FLOW ? -1e4F : T.origin.x, T.origin.y, T.size.x, T.size.y);
    glUniform1f(p["opacity"], pl.opacity * alpha * (FLOW ? unit(OPEN / 0.2F) : 1.F));
    const auto   MID  = [&T, N](double i) { return (T.letters[std::min(size_t(i), N - 1)].first + T.letters[std::min(size_t(i), N - 1)].second) / 2.0; };
    const float  AT   = N > 1 && pl.spread > 0 ? (pl.stream * (pl.spread + pl.flight) - 0.6F * pl.flight) / pl.spread * float(N - 1) : 0.F;
    const double I    = std::clamp(double(AT), 0.0, double(N > 0 ? N - 1 : 0));
    const double HEAD = N > 0 ? MID(I) + (MID(I + 1) - MID(I)) * (I - std::floor(I)) : 0;
    glUniform3f(p["head"], float(HEAD), 16.F, FLOW && !pl.leaving && AT > -1.F ? 0.4F * unit(AT + 1.F) * (1.F - std::pow(pl.stream, 6.F)) : 0.F);
    rgb(p, "headColor", P.lamp);
    glUniform1i(p["textTex"], 0);
    glUniform1i(p["grainTex"], 4);
    bindTex(0, T.tex);
    bindTex(4, Assets::texture("shared/glass-noise.png"));
    paint(p, *AREA);
    if (FLOW)
        drawLetters(pl, T, P, SLOT, PHYS.copy().expand(-std::round(2.0 * S)), alpha, S);
    return true;
}
