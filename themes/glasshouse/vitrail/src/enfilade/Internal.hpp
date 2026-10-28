#pragma once

#include "enfilade/Enfilade.hpp"
#include "frame/Frame.hpp"
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
#include <hyprland/src/desktop/state/FocusState.hpp>
#include <hyprland/src/state/WorkspaceState.hpp>
#include <hyprland/src/managers/SessionLockManager.hpp>
#include <hyprland/src/animation/AnimationManager.hpp>
#include <hyprland/src/render/Renderer.hpp>
#include <hyprland/src/render/OpenGL.hpp>
#include <hyprland/src/render/Framebuffer.hpp>
#include <hyprland/src/render/pass/PassElement.hpp>
#include <hyprland/src/output/Monitor.hpp>

#include <algorithm>
#include <array>
#include <chrono>
#include <cmath>
#include <ranges>

using namespace Render::GL;
using Gl::SProgram;

namespace Enfilade {
    constexpr float TAIL = 150, FOCAL = 1.4F, START = 0.46F, OPEN = 1.25F, ARCH = 0.2F, CASING = 34, REVEAL = 0.18F, RECOIL = 0.24F;
    constexpr int   MOTES = 260 + 8 * 24 * 3, SEATS = 8;

    struct SMove {
        PHLMONITORREF                         monitor;
        PHLWORKSPACEREF                       from, to, next;
        bool                                  forward = true;
        std::vector<SP<Render::IFramebuffer>> fromShots, toShots;
        SP<Render::IFramebuffer>              farFB, doorFB, liveFB;
        UP<SMove>                             before;
        PHLANIMVAR<float>                     clock;
        float                                 seam = 0, t = 0;
        std::array<float, 4 * SEATS>          seats = {};
        std::vector<PHLWINDOWREF>             arrivals;
        bool                                  landed = false, held = false, forced = false, pyre = false, lit = false;
    };

    inline std::vector<UP<SMove>> moves;

    extern SProgram doorsProgram;
    extern SProgram moteProgram;

    float                lengthOf(const SMove& m);
    float                ms(const SMove& m);
    SMove*               moveOn(const PHLMONITOR& monitor);
    bool                 onScreens(const PHLMONITOR& monitor);
    void                 release(SMove& m);
    void                 unhold(SMove& m);
    void                 reveal(SMove& m);
    void                 hush(const PHLMONITOR& monitor);
    void                 land(SMove& m);
    void                 start(SMove& m, const PHLMONITOR& MON);
    std::array<float, 2> strideOf(bool forward, float t, float depth, float focal);
    std::array<float, 2> poseOf(const SMove& m, float t, float depth);
    void                 prepare(SMove& m, const PHLMONITOR& monitor);
    void                 drawPlanes(SMove& m, float t, const PHLMONITOR& monitor);
    void                 blaze(SMove& m, const PHLMONITOR& monitor);
    void                 drawMotes(SMove& m, float t, const PHLMONITOR& monitor);
}
