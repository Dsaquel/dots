#pragma once

#include "glaze/Glaze.hpp"
#include "enfilade/Enfilade.hpp"
#include "core/Gl.hpp"
#include "core/Palette.hpp"
#include "passage/Passage.hpp"
#include "core/Ring.hpp"
#include "translation/Translation.hpp"
#include "core/Ease.hpp"
#include "core/globals.hpp"

#include <hyprland/src/desktop/view/window/Window.hpp>
#include <hyprland/src/desktop/view/window/WindowPresentation.hpp>
#include <hyprland/src/workspace/HLWorkspace.hpp>
#include <hyprland/src/desktop/state/WindowState.hpp>
#include <hyprland/src/state/WorkspaceState.hpp>
#include <hyprland/src/managers/SessionLockManager.hpp>
#include <hyprland/src/managers/fullscreen/FullscreenController.hpp>
#include <hyprland/src/animation/AnimationManager.hpp>
#include <hyprland/src/render/Renderer.hpp>
#include <hyprland/src/render/OpenGL.hpp>
#include <hyprland/src/render/Framebuffer.hpp>
#include <hyprland/src/render/pass/PassElement.hpp>
#include <hyprland/src/output/Monitor.hpp>

#include <algorithm>
#include <array>
#include <cmath>
#include <format>
#include <ranges>
#include <utility>

using namespace Render::GL;
using Gl::SProgram;

namespace Glaze {
    constexpr size_t PANES = 6;
    constexpr float  FIRST = 100, SPAN = 220, RATIO = 0.25F, SLAM = FIRST + SPAN, FRAMED = 250, SHOCK = 140, RING = 100, ARCED = 150, TAIL = SLAM + 600;
    constexpr float  LIFT = 40, LIFTED = 190, RISEN = 0.5F, CLIMB = 110, HIDDEN = 360;
    constexpr float  VEIL = 330, VEILED = 470, UNVEIL = 200, UNVEILED = 320;
    constexpr float  BEAT = 18, LIFTBEAT = 16, WELD = 8, GILD = SHOCK - 10;
    constexpr float  JOLT = 9.8F, JOLTED = 220, SWAY = 55, PERIOD = 60, ECHO = 0.33F, LAG = 14;
    constexpr float  POP = 0.1F, OVERHANG = 60, SHOT = 2, COOLED = 420;
    constexpr double REACH = 110, SPILL = 380, BOLTED = 30, COURSES = 7, LOW = 56;
    constexpr int    MEND = 12, SPLASH = 13, SPLASHES = 24, DROPS = 12, STRIKES = 3, LINKS = 128;

    void rest(const PHLWORKSPACE& ws, const Vector2D& applied);

    struct SPane {
        PHLWINDOWREF             window;
        SP<Render::IFramebuffer> shot;
        CBox                     box, area;
        Vector2D                 grid;
        float                    radius = 0;
    };

    struct SSheet {
        PHLMONITORREF      monitor;
        PHLWORKSPACEREF    workspace, jolted;
        std::vector<SPane> panes;
        bool               shows = true, back = false, live = false;
        float              from = 0, seed = 0, level = 0, haze = 0, veil = 0, v0 = 0, f0 = 0;
        Vector2D           jolt, echo;
        PHLANIMVAR<float>  clock;

        ~SSheet() {
            rest(workspace.lock(), jolt);
            rest(jolted.lock(), echo);
        }
    };

    inline std::vector<UP<SSheet>> sheets;

    extern SProgram glazeProgram;
    extern SProgram boltProgram;
    extern SProgram spatterProgram;

    float   ms(const SSheet& s);
    bool    heading(const SSheet& s);
    float   veiled(const SSheet& s, float t);
    CBox    reachOf(const CBox& a);
    SSheet* sheetOf(const PHLWORKSPACE& ws);
    void    damage(const SSheet& s);
    void    dim(const PHLMONITOR& m);
    void    settle(SSheet& s);
    void    jolt(SSheet& s, float t, const PHLMONITOR& m);
    void    play(SSheet& s, bool shows, float from, bool back, bool heard);
    void    handBack(SSheet& s);
    void    fly(const PHLWORKSPACE& ws, const PHLMONITOR& monitor, bool shows);
    void    drawGlass(const SSheet& s, size_t i, float t, const PHLMONITOR& m);
    void    drawBolt(const SSheet& s, size_t i, float t, const PHLMONITOR& m);
    void    drawSpatter(const SSheet& s, size_t i, float t, const PHLMONITOR& m);
}
