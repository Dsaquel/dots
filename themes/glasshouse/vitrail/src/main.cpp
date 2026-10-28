#include "core/Assets.hpp"
#include "enfilade/Enfilade.hpp"
#include "frame/Frame.hpp"
#include "frame/FramePass.hpp"
#include "life/Life.hpp"
#include "mullion/Mullion.hpp"
#include "glaze/Glaze.hpp"
#include "passage/Passage.hpp"
#include "translation/Translation.hpp"
#include "core/globals.hpp"
#include "core/Gl.hpp"

#include <hyprland/src/desktop/view/window/Window.hpp>
#include <hyprland/src/desktop/view/window/WindowPresentation.hpp>
#include <hyprland/src/workspace/HLWorkspace.hpp>
#include <hyprland/src/desktop/state/WindowState.hpp>
#include <hyprland/src/desktop/state/FocusState.hpp>
#include <hyprland/src/event/EventBus.hpp>
#include <hyprland/src/ipc/s2/S2.hpp>
#include <hyprland/src/managers/eventLoop/EventLoopManager.hpp>
#include <hyprland/src/render/OpenGL.hpp>
#include <hyprland/src/render/Renderer.hpp>
#include <hyprland/src/render/decorations/DecorationPositioner.hpp>
#include <hyprland/src/debug/log/Logger.hpp>
#include <hyprland/src/config/ConfigValue.hpp>
#include <hyprutils/memory/Casts.hpp>

#include <algorithm>
#include <format>
#include <functional>
#include <optional>
#include <ranges>
#include <stdexcept>
#include <utility>

extern "C" {
#include <lua.h>
#include <lauxlib.h>
}

using GEO = Desktop::View::IGeometric;

[[gnu::used]] static const char ABI[] = "vitrail-abi " GIT_COMMIT_HASH "_aq_" AQUAMARINE_VERSION "_hu_" HYPRUTILS_VERSION "_hg_" HYPRGRAPHICS_VERSION "_hc_" HYPRCURSOR_VERSION
                                         "_hlg_" HYPRLANG_VERSION;

APICALL EXPORT std::string PLUGIN_API_VERSION() {
    return HYPRLAND_API_VERSION;
}

static UP<SEventLoopDoLaterLock> g_drain, g_unswipe;

std::string worldName() {
    return g_glass->worldOverride.empty() ? std::string{g_glass->world->value()} : g_glass->worldOverride;
}

float worldIndex() {
    return worldName() == "light" ? 1.F : 0.F;
}

float secondsAlive() {
    return std::chrono::duration<float>(std::chrono::steady_clock::now() - g_glass->born).count();
}

static std::string addressOf(const PHLWINDOW& w) {
    return w ? std::format("{:x}", rc<uintptr_t>(w.get())) : std::string{};
}

void announce(const std::string& data) {
    IPC::Socket2::sock()->postEvent({"vitrail", data});
    LOG(Log::DEBUG, "[vitrail] {}", data);
}

void settleDim(const PHLWINDOW& w) {
    static auto PSTRENGTH = CConfigValue<Config::FLOAT>("decoration:dim_strength");
    static auto PENABLED  = CConfigValue<Config::INTEGER>("decoration:dim_inactive");
    const bool  LIT       = w == Desktop::focusState()->window() || w->m_ruleApplicator->noDim().valueOrDefault() || !*PENABLED;
    w->presentation().warpDimPercent(LIT ? 0.F : *PSTRENGTH);
}

static double areaOf(const Vector2D& v) {
    return v.x * v.y;
}

static double shrunk(const PHLWINDOW& w) {
    return areaOf(w->sizeAnimation()->begun()) - areaOf(w->sizeAnimation()->goal());
}

static auto tiledNeighbours(const PHLWORKSPACE& ws, const PHLWINDOW& self) {
    return Desktop::windowState()->windows() | std::views::filter([ws, self](const PHLWINDOW& w) {
               return w != self && validMapped(w) && !w->isFloating() && w->m_workspace == ws && w->sizeAnimation()->isBeingAnimated();
           });
}

static PHLWINDOW giverOf(const PHLWINDOW& born) {
    const CBox REACH = born->geometricBox(GEO::GEOMETRIC_GOAL).expand(64.0);
    auto       near  = tiledNeighbours(born->m_workspace, born) | std::views::filter([&REACH](const PHLWINDOW& w) {
                    return shrunk(w) > 0 && !REACH.intersection(w->geometricBox(GEO::GEOMETRIC_GOAL)).empty();
                });
    const auto IT    = std::ranges::max_element(near, {}, shrunk);
    return IT == std::ranges::end(near) ? PHLWINDOW{} : *IT;
}

static auto growersOf(const SClosing& gone) {
    return tiledNeighbours(gone.workspace.lock(), gone.window.lock()) | std::views::filter([&gone](const PHLWINDOW& w) {
               return shrunk(w) < 0 && !gone.box.intersection(w->geometricBox(GEO::GEOMETRIC_GOAL)).empty();
           });
}

static PHLWINDOW receiverOf(const SClosing& gone) {
    auto       near = growersOf(gone);
    const auto IT   = std::ranges::min_element(near, {}, shrunk);
    return IT == std::ranges::end(near) ? PHLWINDOW{} : *IT;
}

static void attach(const PHLWINDOW& w) {
    if (validMapped(w) && !w->backend().traits().suggestsNoBorder && !CGlassFrame::of(w))
        w->presentation().addDecoration(makeShared<CGlassFrame>(w));
}

static void eachFrame(const std::function<void(const PHLWINDOW&, CGlassFrame*)>& fn) {
    std::ranges::for_each(Desktop::windowState()->windows(), [&fn](const PHLWINDOW& w) {
        if (const auto FRAME = CGlassFrame::of(w))
            fn(w, FRAME);
    });
}

static void onOpen(const PHLWINDOW& w) {
    Translation::hush();
    attach(w);
    if (const auto FRAME = CGlassFrame::of(w))
        FRAME->prepare();
    const auto GIVER = giverOf(w);
    Life::open(w, GIVER);
    announce(std::format("open,{},{},{}", addressOf(w), Mullion::holds(w) ? "mullion" : GIVER ? "share" : "alone", addressOf(GIVER)));
}

static void onFrame();

static void onClose(const PHLWINDOW& w) {
    Translation::hush();
    Life::close(w);
    g_glass->closing.emplace_back(SClosing{.address = addressOf(w), .box = w->geometricBox(GEO::GEOMETRIC_CURRENT), .workspace = w->m_workspace, .window = w});
    g_drain = g_pEventLoopManager->doLaterLock([] { onFrame(); });
}

static void onFrame() {
    if (g_glass->closing.empty())
        return;

    const auto GONE = std::exchange(g_glass->closing, {});
    std::ranges::for_each(GONE, [](const SClosing& c) {
        const auto RECEIVER = receiverOf(c);
        for (const auto& w : growersOf(c))
            if (w != RECEIVER)
                Life::follow(w);
        Life::decide(c.address, RECEIVER);
        announce(std::format("close,{},{},{}", c.address, RECEIVER ? "give" : "alone", addressOf(RECEIVER)));
    });
}

static void onFocus(const PHLWINDOW& target) {
    const auto CLOSING = [](const PHLWINDOW& w) { return std::ranges::find_if(g_glass->closing, [&w](const SClosing& c) { return w && c.window.lock() == w; }); };
    const auto W       = CLOSING(target) != g_glass->closing.end() ? PHLWINDOW{} : target;
    const auto PREV    = g_glass->lastFocus.lock();
    const auto GONE    = CLOSING(PREV);
    CGlassFrame::handoff(PREV, W, GONE != g_glass->closing.end() ? std::optional<CBox>{GONE->box} : std::nullopt);
    eachFrame([&W, &PREV](const PHLWINDOW& x, CGlassFrame* frame) {
        if (x != W && x != PREV)
            frame->relight(false);
    });
    announce(std::format("focus,{},{}", addressOf(PREV), addressOf(W)));
    g_glass->lastFocus = W;
}

static void onLanterns(const PHLMONITOR& monitor) {
    std::erase_if(g_glass->lanterns, [&monitor](const PHLWINDOWREF& w) {
        const auto FRAME = w ? CGlassFrame::of(w.lock()) : nullptr;
        return !FRAME || !FRAME->damageLantern(monitor);
    });
}

static void onReload() {
    Life::curves();
    Render::GL::g_pHyprOpenGL->makeEGLCurrent();
    Assets::clear();
    g_glass->warm = warmGlassPrograms();
    eachFrame([](const PHLWINDOW& w, CGlassFrame* frame) {
        g_pDecorationPositioner->repositionDeco(frame);
        frame->damageEntire();
    });
}

static int luaWorld(lua_State* L) {
    g_glass->worldOverride = luaL_checkstring(L, 1);
    eachFrame([](const PHLWINDOW& w, CGlassFrame* frame) { frame->damageEntire(); });
    return 0;
}

static int luaMullion(lua_State* L) {
    Mullion::style(luaL_checkstring(L, 1));
    return 0;
}

static int luaStats(lua_State* L) {
    const auto S = std::format("passes={} gl_errors={} gl_foreign={} timed={} avg_us={:.1f} life_timed={} life_avg_us={:.1f} enfilade_timed={} enfilade_avg_us={:.1f} enfilade_max_us={:.1f} frames={}", g_glass->passes, g_glass->glErrors,
                               g_glass->glForeign, g_glass->timed, g_glass->timed ? double(g_glass->timedNs) / double(g_glass->timed) / 1000.0 : 0.0, g_glass->lifeTimed,
                               g_glass->lifeTimed ? double(g_glass->lifeNs) / double(g_glass->lifeTimed) / 1000.0 : 0.0, g_glass->enfTimed,
                               g_glass->enfTimed ? double(g_glass->enfNs) / double(g_glass->enfTimed) / 1000.0 : 0.0, double(g_glass->enfMaxNs) / 1000.0,
                               std::ranges::count_if(Desktop::windowState()->windows(), [](const PHLWINDOW& w) { return CGlassFrame::of(w) != nullptr; }));
    lua_pushstring(L, S.c_str());
    return 1;
}

APICALL EXPORT PLUGIN_DESCRIPTION_INFO PLUGIN_INIT(HANDLE handle) {
    PHANDLE = handle;

    if (std::string_view{__hyprland_api_get_hash()} != std::string_view{__hyprland_api_get_client_hash()}) {
        HyprlandAPI::addNotification(PHANDLE, "[vitrail] built for another Hyprland: not loaded, rebuild it", CHyprColor{1.0, 0.2, 0.2, 1.0}, 8000);
        throw std::runtime_error("[vitrail] version mismatch");
    }

    g_glass          = makeUnique<SGlobalState>();
    g_glass->enabled = makeShared<Config::Values::CBoolValue>("plugin:vitrail:enabled", "draw the leaded-glass frames", true);
    g_glass->world   = makeShared<Config::Values::CStringValue>("plugin:vitrail:world", "the world the glass belongs to: dark or light", "dark");
    g_glass->screens = makeShared<Config::Values::CStringValue>("plugin:vitrail:screens", "the outputs and their workspaces, like GLASSHOUSE_SCREENS",
                                                                  "");
    g_glass->assets  = makeShared<Config::Values::CStringValue>("plugin:vitrail:assets", "the glasshouse asset tree (<world>/chrome-*.png, shared/)",
                                                                 "~/.config/quickshell/glasshouse/assets");
    g_glass->probe   = makeShared<Config::Values::CStringValue>("plugin:vitrail:probe", "debug: windows whose class starts with this draw their came as a green line", "");
    g_glass->debug   = makeShared<Config::Values::CIntValue>("plugin:vitrail:debug", "1: check GL errors around every frame pass, 2: also time it (glFinish)", 0);
    g_glass->retime  = makeShared<Config::Values::CBoolValue>("plugin:vitrail:retime", "the windows that open, close or make room move at the glass's pace (600 ms)", true);
    g_glass->enfilade = makeShared<Config::Values::CBoolValue>("plugin:vitrail:enfilade", "a workspace switch walks through glass doors into the next workspace", true);
    g_glass->translation = makeShared<Config::Values::CBoolValue>("plugin:vitrail:translation", "a window taken to another workspace breaks into its leaded quarries, forms again in its new slot, shuffles into order and is welded", true);
    g_glass->relead      = makeShared<Config::Values::CBoolValue>("plugin:vitrail:relead", "windows that change places in a layout are set in their new slots as shuffled leaded quarries, then welded", true);
    g_glass->passage     = makeShared<Config::Values::CStringValue>("plugin:vitrail:passage", "a workspace switch travels through every workspace between: nave, gallery, lantern, or doors (the old enfilade)", "nave");
    g_glass->glaze       = makeShared<Config::Values::CBoolValue>("plugin:vitrail:glaze", "a scratchpad is leaded in place from its own quarries, course by course, slammed and welded; hidden, its quarries lift off and rise away", true);

    for (const auto& value : std::initializer_list<SP<Config::Values::IValue>>{g_glass->enabled, g_glass->world, g_glass->screens, g_glass->assets, g_glass->probe, g_glass->debug, g_glass->retime,
                                                                      g_glass->enfilade, g_glass->translation, g_glass->relead, g_glass->passage, g_glass->glaze})
        HyprlandAPI::addConfigValueV2(PHANDLE, value);
    HyprlandAPI::addLuaFunction(PHANDLE, "vitrail", "world", luaWorld);
    HyprlandAPI::addLuaFunction(PHANDLE, "vitrail", "stats", luaStats);
    HyprlandAPI::addLuaFunction(PHANDLE, "vitrail", "mullion", luaMullion);

    g_glass->listeners = {
        Event::bus()->m_events.window.open.listen([](const PHLWINDOW& w) { onOpen(w); }),
        Event::bus()->m_events.window.openLate.listen([](const PHLWINDOW& w) { Life::late(w); }),
        Event::bus()->m_events.window.close.listen([](const PHLWINDOW& w) { onClose(w); }),
        Event::bus()->m_events.window.moveToWorkspace.listen([](const PHLWINDOW& w, const PHLWORKSPACE& ws) { Translation::take(w, ws); }),
        Event::bus()->m_events.window.active.listen([](const PHLWINDOW& w, Desktop::eFocusReason reason) { onFocus(w); }),
        Event::bus()->m_events.window.floating.listen([](const PHLWINDOW& w) {
            if (const auto FRAME = CGlassFrame::of(w))
                FRAME->lift(w->isFloating());
        }),
        Event::bus()->m_events.window.fullscreen.listen([](const PHLWINDOW& w) { Translation::hush(); }),
        Event::bus()->m_events.monitor.layoutChanged.listen([] { Translation::hush(); }),
        Event::bus()->m_events.workspace.moveToMonitor.listen([](const PHLWORKSPACE& ws, const PHLMONITOR& m) { Translation::hush(); }),
        Event::bus()->m_events.window.urgent.listen([](const PHLWINDOW& w) {
            if (const auto FRAME = CGlassFrame::of(w); FRAME && w != Desktop::focusState()->window())
                FRAME->call();
        }),
        Event::bus()->m_events.window.title.listen([](const PHLWINDOW& w) {
            if (const auto FRAME = CGlassFrame::of(w))
                FRAME->damageEntire();
        }),
        Event::bus()->m_events.config.reloaded.listen([] { onReload(); }),
        Event::bus()->m_events.workspace.active.listen([](const PHLWORKSPACE& ws) {
            if (ws)
                Translation::settle(ws->m_monitor.lock());
            Enfilade::begin(ws);
        }),
        Event::bus()->m_events.workspace.specialActive.listen([](const PHLWORKSPACE& ws, const PHLMONITOR& m) { Glaze::toggle(ws, m); }),
        Event::bus()->m_events.gesture.swipe.begin.listen([](const IPointer::SSwipeBeginEvent&, Event::SCallbackInfo&) { Glaze::swipe(true); }),
        Event::bus()->m_events.gesture.swipe.end.listen([](const IPointer::SSwipeEndEvent&, Event::SCallbackInfo&) { g_unswipe = g_pEventLoopManager->doLaterLock([] { Glaze::swipe(false); }); }),
        Event::bus()->m_events.render.stage.listen([](const Event::SRenderStageEvent& ev) {
            if (!ev.context)
                return;
            Gl::ctx = &ev.context->get();
            if (ev.stage == RENDER_PRE_WINDOWS)
                Life::stage(ev.monitor);
            if (ev.stage == RENDER_POST_WINDOWS) {
                Mullion::stage(ev.monitor);
                Enfilade::stage(ev.monitor);
                Passage::stage(ev.monitor);
                Translation::stage(ev.monitor);
                Glaze::stage(ev.monitor);
            }
        }),
        Event::bus()->m_events.render.preChecks.listen([](const PHLMONITOR& monitor) { Translation::watch(monitor); }),
        Event::bus()->m_events.render.pre.listen([](const PHLMONITOR& monitor) {
            if (!g_glass->warm)
                g_glass->warm = warmGlassPrograms();
            onFrame();
            Life::pre(monitor);
            Mullion::pre(monitor);
            Enfilade::pre(monitor);
            Passage::pre(monitor);
            Translation::pre(monitor);
            Glaze::pre(monitor);
            eachFrame([&monitor](const PHLWINDOW& w, CGlassFrame* frame) { frame->damageMotion(monitor); });
            onLanterns(monitor);
        }),
    };

    Life::curves();
    Life::unpace();
    g_glass->warm = warmGlassPrograms();
    std::ranges::for_each(Desktop::windowState()->windows(), attach);
    g_glass->lastFocus = Desktop::focusState()->window();
    announce("ready");

    return {"vitrail", "Glasshouse leaded-glass window chrome", "glasshouse", "0.2"};
}

APICALL EXPORT void PLUGIN_EXIT() {
    announce("gone");
    g_drain.reset();
    g_unswipe.reset();
    g_glass->listeners.clear();
    Life::exit();
    Mullion::exit();
    Translation::exit();
    Enfilade::exit();
    Passage::exit();
    Glaze::exit();
    g_pHyprRenderer->context().m_pass.removeAllOfType("CGlassPass");
    std::ranges::for_each(Desktop::windowState()->windows(), [](const PHLWINDOW& w) {
        if (const auto FRAME = CGlassFrame::of(w))
            w->presentation().removeDecoration(FRAME);
    });
    destroyGlassPrograms();
    g_glass.reset();
}
