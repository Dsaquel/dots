#include "core/Gl.hpp"

#include <hyprland/src/render/Renderer.hpp>
#include <hyprland/src/render/OpenGL.hpp>
#include <hyprland/src/render/Shader.hpp>
#include <hyprland/src/debug/log/Logger.hpp>
#include <hyprland/src/desktop/view/window/Window.hpp>
#include <hyprland/src/desktop/view/window/WindowEffectsController.hpp>
#include <hyprland/src/render/transformer/TransformerList.hpp>
#include <hyprland/src/output/Monitor.hpp>
#include <hyprland/src/output/MonitorResources.hpp>

#include <optional>

using namespace Render::GL;

GLint Gl::SProgram::operator[](const char* u) {
    const auto IT = loc.find(u);
    return IT != loc.end() ? IT->second : (loc[u] = glGetUniformLocation(shader->program(), u));
}

bool Gl::ready(SProgram& p) {
    if (p.shader || p.failed)
        return !p.failed;
    auto shader = makeShared<CShader>();
    if (!shader->createProgram(p.vert ? *p.vert : g_pHyprOpenGL->m_shaders->TEXVERTSRC, *p.frag, true, true)) {
        p.failed = true;
        LOG(Log::ERR, "[vitrail] the {} shader did not compile, it stays off", p.name);
        return false;
    }
    p.shader = shader;
    return true;
}

void Gl::reset(SProgram& p) {
    p.shader.reset();
    p.failed = false;
    p.loc.clear();
    p.stamp = {nullptr, -1};
}

void Gl::rgb(SProgram& p, const char* u, const SRGB& c) {
    glUniform3f(p[u], c.r, c.g, c.b);
}

void Gl::bindTex(int unit, const SP<Render::ITexture>& tex) {
    glActiveTexture(GL_TEXTURE0 + unit);
    glBindTexture(GL_TEXTURE_2D, tex ? tex->m_texID : 0);
}

void Gl::unbindAll() {
    for (int unit = 6; unit >= 0; --unit) {
        glActiveTexture(GL_TEXTURE0 + unit);
        glBindTexture(GL_TEXTURE_2D, 0);
    }
}

std::optional<Gl::SArea> Gl::areaOf(const CBox& phys, const std::optional<CBox>& hole) {
    auto& rd    = ctx->m_data;
    CBox  drawn = phys;
    rd.renderModif.applyToBox(drawn);
    CRegion region = rd.damage.copy().intersect(drawn.copy().translate(nudge));
    if (hole && hole->w > 0 && hole->h > 0) {
        CBox h = *hole;
        rd.renderModif.applyToBox(h);
        region.subtract(h.translate(nudge));
    }
    if (rd.clipBox.w > 0 && rd.clipBox.h > 0)
        region.intersect(rd.clipBox);
    if (region.empty())
        return std::nullopt;
    return SArea{drawn, region};
}

void Gl::paint(SProgram& p, const SArea& area) {
    auto& rd = ctx->m_data;
    p.shader->setUniformMatrix3fv(SHADER_PROJ, 1, GL_TRUE, g_pHyprRenderer->projectBoxToTarget(*ctx, area.drawn.copy().translate(nudge)).getMatrix());
    glBindVertexArray(p.shader->getUniformLocation(SHADER_SHADER_VAO));
    area.region.forEachRect([&rd](const auto& RECT) {
        g_pHyprOpenGL->scissor(*ctx, &RECT, rd.transformDamage);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    });
    glBindVertexArray(0);
    g_pHyprOpenGL->disableScissor();
}

bool Gl::CTransformer::active() const {
    return !dropped;
}

void Gl::drop(const PHLWINDOW& w, Render::IWindowTransformer* t) {
    static_cast<CTransformer*>(t)->dropped = true;
    w->effects().transformers()->removeInactive();
}

SP<Render::IFramebuffer> Gl::widen(Render::CRenderContext& c, const Render::SWindowTransformBuffer& in) {
    ctx            = &c;
    auto&      rd  = c.m_data;
    const auto MON = rd.pMonitor.lock();
    const auto OUT = MON && MON->resources() ? MON->resources()->getUnusedWorkBuffer() : nullptr;
    if (!OUT || !OUT->isAllocated() || !in.framebuffer || !in.framebuffer->getTexture())
        return nullptr;
    rd.renderModif     = {};
    rd.clipBox         = {};
    rd.transformDamage = false;
    rd.fbSize          = MON->m_transformedSize;
    rd.damage          = CRegion{CBox{{}, MON->m_transformedSize}};
    g_pHyprRenderer->setProjectionType(c, Render::RPT_MONITOR);
    auto guard = g_pHyprRenderer->bindTempFB(c, OUT);
    g_pHyprRenderer->disableScissor();
    glClearColor(0.F, 0.F, 0.F, 0.F);
    glClear(GL_COLOR_BUFFER_BIT);
    g_pHyprOpenGL->blend(false);
    g_pHyprOpenGL->renderTexturePrimitive(c, in.framebuffer->getTexture(), in.box);
    g_pHyprOpenGL->blend(true);
    return OUT;
}

Render::SWindowTransformBuffer Gl::whole(const SP<Render::IFramebuffer>& fb) {
    const auto MON = ctx->m_data.pMonitor.lock();
    return {.framebuffer = fb, .box = CBox{{}, MON->m_transformedSize}};
}
