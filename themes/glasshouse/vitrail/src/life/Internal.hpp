#pragma once

#include "life/Life.hpp"
#include "frame/Frame.hpp"
#include "core/Gl.hpp"
#include "mullion/Mullion.hpp"
#include "core/Palette.hpp"
#include "core/Ring.hpp"
#include "core/Ease.hpp"
#include "core/globals.hpp"

#include <hyprland/src/desktop/view/window/Window.hpp>
#include <hyprland/src/desktop/view/window/WindowPresentation.hpp>
#include <hyprland/src/desktop/view/window/WindowEffectsController.hpp>
#include <hyprland/src/render/transformer/TransformerList.hpp>
#include <hyprland/src/workspace/HLWorkspace.hpp>
#include <hyprland/src/desktop/state/WindowState.hpp>
#include <hyprland/src/desktop/state/FadingOutState.hpp>
#include <hyprland/src/desktop/rule/windowRule/WindowRuleApplicator.hpp>
#include <hyprland/src/config/shared/animation/AnimationTree.hpp>
#include <hyprland/src/animation/AnimationManager.hpp>
#include <hyprland/src/render/Renderer.hpp>
#include <hyprland/src/render/OpenGL.hpp>
#include <hyprland/src/output/Monitor.hpp>
#include <hyprland/src/output/MonitorResources.hpp>
#include <hyprland/src/state/MonitorState.hpp>
#include <hyprland/src/managers/fullscreen/FullscreenController.hpp>

#include <algorithm>
#include <array>
#include <cmath>
#include <chrono>
#include <ranges>

using namespace Render::GL;
using Gl::SProgram;

namespace Life {
    extern SProgram contentProgram;
    extern SProgram pieceProgram;
    extern SProgram grainProgram;
    extern SProgram sliverProgram;
    extern SProgram portalProgram;
    extern SProgram emberProgram;

    struct STimer {
        bool                                  on    = g_glass->debug->value() > 1;
        std::chrono::steady_clock::time_point start = (on ? glFinish() : void(), std::chrono::steady_clock::now());

        ~STimer() {
            if (!on)
                return;
            glFinish();
            g_glass->lifeNs += std::chrono::duration_cast<std::chrono::nanoseconds>(std::chrono::steady_clock::now() - start).count();
            ++g_glass->lifeTimed;
        }
    };

    constexpr float SLAM = 380, SPARKS = 9, SPRAY = 400, FOLD = 80, ANIM = 389, CLAP = 55, SLOT = 72, CUE_GAP = 18, SHOCKV = 9, SHOCKW = 60, SHOCKA = 10, SHOCKIN = 8, FLUSH = 12;
    constexpr float BORN_END = 450, RECEIVER_END = 470, LANDED = 3, BITE = 0.4F, SHADE = 64;
    constexpr float JOLT = 11, ECHO = 4.5F, FADE = 1500, FAINT = 0.75F, LAG = 15, WAVE = 20, SHUDDER = 220, DAMP = 27, BEAT = 60;

    struct SFlight {
        Vector2D a, b;
        CBox     box;
        double   radius = 8, at = 0, off = 4.6;
        int      count  = 2;
        float    seed   = 0;
    };

    struct SContent {
        SP<Render::ITexture> tex;
        Vector2D             texSize;
        CBox                 drawn, win;
        float                radius = 8, t = 0, mode = 0, span = 1, edge = 1e5F, seed = 0, fire = 0, came = 9.5F;
        std::array<float, 4> origin = {0, 0, 0, 0}, timing = {0, 1, 1, 0}, front = {0, 1, 1e9F, 1e9F};
        Vector2D             cell = {48, 72};
    };

    struct SJolt {
        PHLWINDOWREF                          window;
        Vector2D                              dir;
        float                                 amp = 0;
        std::chrono::steady_clock::time_point at;
    };

    inline std::vector<SJolt> g_jolts;

    Vector2D                                           lightPx(const PHLMONITOR& m);
    void                                               drawFlight(const SFlight& f, float t, const PHLMONITOR& m);
    Vector2D                                           sideSeg(const CBox& g, int side, double came, bool start);
    double                                             cameFor(const PHLWINDOW& w, const CBox& b);
    void                                               drawContent(const SContent& c, const PHLMONITOR& m);
    void                                               straighten(const SP<Render::IFramebuffer>& out, const CBox& win, float radius, const PHLMONITOR& m);
    void                                               drawGrains(const SP<Render::ITexture>& tex, const Vector2D& texSize, const CBox& box, float t, const std::array<float, 4>& front, float seed, const PHLMONITOR& m, const CBox& win, float radius, bool fire);
    void                                               drawSlivers(const CBox& box, const CBox& win, float radius, const std::array<float, 4>& front, float came, float t, float seed, const PHLMONITOR& m);
    SP<Hyprutils::Animation::SAnimationPropertyConfig> pace(const std::string& leaf, const std::string& curve, float ms);
    void                                               retime(const PHLWINDOW& w, const std::string& leaf, const std::string& curve = "vitrailPace", float ms = LIFE);
    void                                               restore(const SRetimed& r);
    float                                              landsIn(const PHLWINDOW& w);
    float                                              paceFor(float end, float land);
    void                                               dropLens(const PHLWINDOW& w);
    void                                               give(const SP<CGhost>& g, const PHLWINDOW& receiver, float arrive = GIVEN, bool voiced = false);
}
