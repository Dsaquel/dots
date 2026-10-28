#include "frame/Internal.hpp"
#include "core/Assets.hpp"
#include "life/Life.hpp"
#include "mullion/Mullion.hpp"
#include "translation/Translation.hpp"
#include <hyprland/src/desktop/view/window/Window.hpp>
#include <hyprland/src/desktop/view/window/WindowPresentation.hpp>
#include <hyprland/src/desktop/state/FocusState.hpp>
#include <hyprland/src/animation/AnimationManager.hpp>

#include <algorithm>
#include <cctype>
#include <format>
#include <fstream>
#include <optional>
#include <unordered_map>

namespace Frame {
    const std::unordered_map<std::string, std::string> GLYPHS = {
        {"kitty", ""},
        {"org.wezfurlong.wezterm", ""},
        {"foot", ""},
        {"Alacritty", ""},
    };

    struct SEntry {
        std::string name, icon;
    };

    SEntry desktopEntry(const std::string& id) {
        static std::unordered_map<std::string, SEntry> cache;
        if (const auto IT = cache.find(id); IT != cache.end())
            return IT->second;
        if (cache.size() > 256)
            cache.clear();
        SEntry entry;
        for (const auto& root : Assets::dataRoots()) {
            std::ifstream file(root + "/applications/" + id + ".desktop");
            for (std::string line; file && std::getline(file, line) && !(line.starts_with("[") && line != "[Desktop Entry]" && !entry.name.empty());) {
                if (entry.name.empty() && line.starts_with("Name="))
                    entry.name = line.substr(5);
                if (entry.icon.empty() && line.starts_with("Icon="))
                    entry.icon = line.substr(5);
            }
            if (!entry.name.empty())
                break;
        }
        return cache[id] = entry;
    }
}

using namespace Frame;

CGlassFrame::CGlassFrame(PHLWINDOW window) : IHyprWindowDecoration(window), m_window(window) {
    for (auto* clock : {&m_light, &m_lift, &m_seal, &m_call, &m_life, &m_arrive, &m_hold})
        Animation::mgr()->createAnimation(1.F, *clock, clockOf(LEVEL_IN), window, AVARDAMAGE_NONE);
    m_on       = Desktop::focusState()->window() == window;
    m_f0       = m_on ? SFocus{1, 1, 1, {1, 1, 1, 1}} : SFocus{};
    m_liftFrom = window->isFloating() ? 1.F : 0.F;
    m_liftTo   = m_liftFrom;
}

CGlassFrame::~CGlassFrame() {
    damageEntire();
}

CGlassFrame* CGlassFrame::of(const PHLWINDOW& window) {
    const auto IT = std::ranges::find_if(window->presentation().decorations(), [](const auto& d) { return d->getDisplayName() == "vitrail"; });
    return IT == window->presentation().decorations().end() ? nullptr : static_cast<CGlassFrame*>(IT->get());
}

SDecorationPositioningInfo CGlassFrame::getPositioningInfo() {
    return {
        .policy         = DECORATION_POSITION_ABSOLUTE,
        .edges          = DECORATION_EDGE_TOP | DECORATION_EDGE_BOTTOM | DECORATION_EDGE_LEFT | DECORATION_EDGE_RIGHT,
        .priority       = 9000,
        .desiredExtents = {{MARGIN, MARGIN}, {MARGIN, MARGIN}},
        .reserved       = false,
    };
}

void CGlassFrame::onPositioningReply(const SDecorationPositioningReply& reply) {
    ;
}

void CGlassFrame::know(const PHLWINDOW& w) {
    if (m_known && m_class == w->metadata().appID())
        return;
    m_known = true;
    m_class = w->metadata().appID();
    std::string comm;
    std::ifstream(std::format("/proc/{}/comm", w->backend().pid())) >> comm;
    const auto BYCLASS = desktopEntry(m_class);
    const auto ID      = !BYCLASS.name.empty() || comm.empty() ? m_class : comm;
    const auto ENTRY   = ID == m_class ? BYCLASS : desktopEntry(comm);
    m_app              = ENTRY.name.empty() ? ID : ENTRY.name;
    const auto GLYPH   = GLYPHS.find(ID);
    m_glyph            = GLYPH != GLYPHS.end();
    m_icon             = m_glyph ? std::string{} : ENTRY.icon;
    m_mark             = m_glyph ? GLYPH->second : (m_app.empty() ? std::string{"?"} : m_app.substr(0, 1));
    if (!m_glyph)
        std::ranges::transform(m_mark, m_mark.begin(), [](unsigned char c) { return char(std::toupper(c)); });
}

CGlassFrame::SFocus CGlassFrame::focusAt(float t) const {
    const auto  MOVE  = [this, t](float v0, float wait, float in, float out) { return m_on ? unit(v0 + std::max(0.F, t - wait) / in) : unit(v0 - t / out); };
    const float K     = unit(t / (m_on ? LEVEL_IN : LEVEL_OUT));
    const float LEVEL = m_on ? (m_f0.level >= 1.F ? 1.F : 1.F - (1.F - std::max(m_f0.level, KICK)) * std::pow(1.F - K, 3.F)) : m_f0.level * (1.F - K * K * (3.F - 2.F * K));
    SFocus      f{.level = LEVEL, .crest = MOVE(m_f0.crest, 0, CREST_IN, CREST_OUT), .plate = MOVE(m_f0.plate, PLATE_DELAY, m_plateIn, PLATE_OUT)};
    for (int q = 0; q < 4; ++q)
        f.plant[q] = MOVE(m_f0.plant[q], m_stagger[q], PLANT_IN, PLANT_OUT);
    return f;
}

CGlassFrame::SFocus CGlassFrame::focusNow() const {
    return focusAt(m_light->value() * m_span);
}

CGlassFrame::SFocus CGlassFrame::shownFocus() const {
    SFocus f = focusNow();
    if (m_role != ROLE_RECEIVER || paceMs() < 0 || !m_on || m_focusAt < m_lentAt - HELD)
        return f;
    const float K = span(syncMs(), SLAM, SLAM + QUICK);
    f.crest       = std::max(m_f0.crest, K);
    f.plate       = std::max(m_f0.plate, K);
    for (int q = 0; q < 4; ++q)
        f.plant[q] = std::max(m_f0.plant[q], K);
    return f;
}

float CGlassFrame::lifted() const {
    return m_liftFrom + (m_liftTo - m_liftFrom) * outCubic(m_lift->value());
}

void CGlassFrame::prepare() {
    const auto W = m_window.lock();
    if (!validMapped(W) || !Render::GL::g_pHyprOpenGL || !Render::GL::g_pHyprOpenGL->m_shadersInitialized)
        return;
    know(W);
    if (!m_icon.empty()) {
        Render::GL::g_pHyprOpenGL->makeEGLCurrent();
        Assets::emblemIcon(m_icon);
    }
}

void CGlassFrame::draw(Render::CRenderContext& ctx, PHLMONITOR monitor, float const& a, const Render::SWindowRenderPresentation& presentation) {
    Gl::ctx      = &ctx;
    const auto W = m_window.lock();
    if (!validMapped(W) || !g_glass->enabled->value() || g_glass->shooting == eShot::BARE || Translation::carries(W) || Mullion::holds(W) ||
        (Gl::ctx->m_renderingSnapshot && g_glass->capturing.lock() != W && g_glass->shooting != eShot::SKINNED))
        return;
    auto data = build(monitor, a);
    if (!data)
        return;
    if (m_lens)
        m_lens->stash(std::move(*data));
    else
        g_pHyprRenderer->addPassElement(ctx, makeUnique<CGlassPass>(std::move(*data)));
}

eDecorationType CGlassFrame::getDecorationType() {
    return DECORATION_CUSTOM;
}

void CGlassFrame::updateWindow(PHLWINDOW window) {
    damageEntire();
}

void CGlassFrame::damageEntire() {
    const auto W = m_window.lock();
    if (!validMapped(W))
        return;

    g_pHyprRenderer->damageBox(boxOf(W).expand(reachNow() + 2.0));
}

eDecorationLayer CGlassFrame::getDecorationLayer() {
    return DECORATION_LAYER_OVER;
}

uint64_t CGlassFrame::getDecorationFlags() {
    return DECORATION_NON_SOLID;
}

std::string CGlassFrame::getDisplayName() {
    return "vitrail";
}

const CBox& CGlassFrame::gone() const {
    return m_gone;
}

CGlassFrame::eRole CGlassFrame::role() const {
    return lifeMs() < 0 ? ROLE_NONE : m_role;
}

PHLWINDOW CGlassFrame::peer() const {
    return m_peer.lock();
}

int CGlassFrame::side() const {
    return m_side;
}
