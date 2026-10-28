#pragma once

#include "mullion/Mullion.hpp"
#include "frame/Frame.hpp"
#include "frame/FramePass.hpp"
#include "core/Gl.hpp"
#include "core/Palette.hpp"
#include "core/Ring.hpp"
#include "translation/Translation.hpp"
#include "core/Ease.hpp"
#include "core/globals.hpp"

#include <hyprland/src/desktop/view/window/Window.hpp>
#include <hyprland/src/desktop/view/window/WindowPresentation.hpp>
#include <hyprland/src/workspace/HLWorkspace.hpp>
#include <hyprland/src/desktop/state/WindowState.hpp>
#include <hyprland/src/animation/AnimationManager.hpp>
#include <hyprland/src/config/shared/animation/AnimationTree.hpp>
#include <hyprland/src/managers/fullscreen/FullscreenController.hpp>
#include <hyprland/src/render/Renderer.hpp>
#include <hyprland/src/render/OpenGL.hpp>
#include <hyprland/src/render/Framebuffer.hpp>
#include <hyprland/src/render/pass/PassElement.hpp>
#include <hyprland/src/output/Monitor.hpp>

#include <algorithm>
#include <array>
#include <cmath>
#include <optional>
#include <utility>
#include <vector>

using namespace Render::GL;
using Gl::SProgram;
using GEO = Desktop::View::IGeometric;

namespace Mullion {
    constexpr float  CRACK0 = 50, CRACK1 = 270, EXPAND0 = 270, EXPAND1 = 660, CELL = 240, CLOSE = 70, SWEEP = 240, FORM = 130, HANG = 70, DIVE = 55, SETTLED = 25, SPLIT = 150,
                     SHOCK = 460, SETTLE = 480, RECOIL = 340, FLY = 120, CHARGE = 100, RUSH = 400, RUN = 80, DAWN = 140;
    constexpr double PIECE_LEN = 72, LAG = 30, ACROSS = 4.6, HALF = 4.7, HOVER = 24, KICK = 7, ABOVE = 58, ASIDE = 30, SPEED = 1.5, JOLT = 9, FADE = 420, SKIP = 0.75;

    enum eKind : uint8_t {
        SLAM,
        ZAP,
        GLINT,
        SPARKS,
        BURST,
        BEAD,
        FORMING,
        WELDING,
    };

    constexpr std::array<float, 8> LIVES = {340, 170, 240, 260, 520, 1e9F, FORM + 20, 300};

    inline bool melting = false;

    struct SLost {
        double u0 = 0, u1 = 0, d0 = 0, d1 = 0;
        float  pop = 0, back = 0, seed = 0;
        int    tone = 0;
    };

    struct SStone {
        Vector2D slot, from;
        float    spawn = 0, drop = 0, land = 0, seed = 0;
        int      tone = 0, wing = 0;
    };

    struct SStruck {
        PHLWINDOWREF window;
        Vector2D     dir;
        float        at = 0, strength = 0;
        bool         kicked = false;
    };

    struct SScene {
        PHLWINDOWREF                     born, giver;
        PHLMONITORREF                    monitor;
        PHLWORKSPACEREF                  workspace;
        int                              side = 1;
        bool                             upright = true, melt = false, kicked = false, plateLost = false, released = false;
        CBox                             r, n;
        Vector2D                         a, b, j0, j1;
        double                           mid = 0, gutter = 16, radius = 8, came = 8, farN = 0, lost = 0, straight = 0, reach = 0, len = 72, lapSpeed = 1, cornerD = 0;
        float                            dawn = 1e9F, wither = 1e9F, bloom = 1e9F, lap0 = 0, ignite = 0, boom = 0, end = 0, seed = 0, settled = -1, from = 0, rate = 1, real = 0, pace = 1, heat = 0;
        SP<Render::IFramebuffer>         still;
        std::optional<CGlassPass::SData> ring;
        std::vector<SLost>               bricks;
        std::vector<SStone>              stones;
        std::vector<SStruck>             struck;
        PHLANIMVAR<float>                clock;
    };

    struct SPose {
        Vector2D pos, out;
        double   len    = PIECE_LEN;
        float    tumble = 0, lift = 1, fresh = 0, land = 0, opacity = 1;
        int      tone   = 0;
    };

    struct SImpact {
        Vector2D at, axis = {0, -1};
        float    birth = 0, strength = 1, size = 60;
        eKind    kind  = ZAP;
    };

    inline std::vector<UP<SScene>> scenes;

    extern SProgram paneProgram;
    extern SProgram brickProgram;

    float                    noise(float x, float y);
    double                   edgeOf(const CBox& box, int side);
    float                    ms(const SScene& s);
    bool                     claimed(const SScene& s, const PHLWINDOW& w);
    double                   layAt(const SScene& s, float t);
    std::pair<double, double> cutAt(const SScene& s, float t);
    double                   nearest(const Vector2D& c, const CBox& box);
    double                   farthest(const Vector2D& c, const CBox& box);
    void                     carve(const CBox& box, const PHLMONITOR& m);
    double                   waveAt(const SScene& s, float age);
    bool                     idle(const PHLWINDOW& w);

    void stampPane();
    void drawPane(const SScene& s, float t, int pass, const PHLMONITOR& m);
    void drawImpact(const SScene& s, const SImpact& im, float t, const PHLMONITOR& m);
    void drawStruck(const SScene& s, float t, const PHLMONITOR& m);
    void drawBrick(const SPose& ps, const PHLMONITOR& m);

    void drawRelease(const SScene& s, const PHLMONITOR& m);
    void paint(const SScene& s, float t, const PHLMONITOR& m);

    bool early(const SScene& s);
    void cue(const SScene& s);
    void kick(const PHLWINDOW& w, const Vector2D& by, float pace);
    void strike(SScene& s, const PHLMONITOR& m);
    void hurry(const PHLWINDOW& giver, const CBox& R);
    bool tiles(const PHLWINDOW& born, const PHLWINDOW& giver, int side, const CBox& R, const Vector2D& AT);
    SScene* raise(const PHLWINDOW& born, const PHLWINDOW& giver, int side, CGlassPass::SData&& ring, const SP<Render::IFramebuffer>& still, float lead = 0, float pace = 1);
}
