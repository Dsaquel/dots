#pragma once

#include "passage/Passage.hpp"
#include "core/Gl.hpp"
#include "core/Palette.hpp"
#include "translation/Translation.hpp"
#include "core/globals.hpp"
#include "core/Ring.hpp"

#include <hyprland/src/desktop/view/window/Window.hpp>
#include <hyprland/src/desktop/view/window/WindowPresentation.hpp>
#include <hyprland/src/workspace/HLWorkspace.hpp>
#include <hyprland/src/desktop/state/WindowState.hpp>
#include <hyprland/src/desktop/state/FocusState.hpp>
#include <hyprland/src/state/MonitorState.hpp>
#include <hyprland/src/state/WorkspaceState.hpp>
#include <hyprland/src/animation/AnimationManager.hpp>
#include <hyprland/src/render/Renderer.hpp>
#include <hyprland/src/render/OpenGL.hpp>
#include <hyprland/src/render/Framebuffer.hpp>
#include <hyprland/src/render/gl/GLFramebuffer.hpp>
#include <hyprland/src/render/pass/PassElement.hpp>
#include <hyprland/src/output/Monitor.hpp>

#include <EGL/egl.h>

#include <algorithm>
#include <array>
#include <chrono>
#include <cmath>
#include <iterator>
#include <map>
#include <optional>
#include <ranges>

using namespace Render::GL;
using Gl::SProgram;

namespace Passage {
    constexpr float FOCAL = 1.4F, SPACING = 1.17F, WALL = 0.18F, ARCH = 0.2F, CASING = 34, OPEN = 1.32F, GAP = 0.14F, PILLAR = 0.03F;
    constexpr float FIRST = 480, NEXT = 165, RAMP = 230, FADE = 90, EXPOSURE = 4, FOG = 0.00042F, BLUR = 2.2F, VEIL = 0.5F, AISLE = 0.32F, WARP = 0.1F, ENTRY = 220, HOLD = 1000, EYE = 260;
    constexpr int   DUSTS = 460, REACH = 9, DOORS = 10, SLOTS = 4;
    constexpr SRGB  HAZE_DARK = hex(0x1a2042), HAZE_LIGHT = hex(0xeadfca), VEIL_DARK = hex(0x05060f), VEIL_LIGHT = hex(0x3a2a1e);
    constexpr SRGB  STONE_DARK = hex(0x5c4c46), STONE_LIGHT = hex(0xcbbca3), PAVING_DARK = hex(0x101220), PAVING_LIGHT = hex(0xd6c6aa);
    constexpr SRGB  AMBIENT_DARK = hex(0x1c2142), AMBIENT_LIGHT = hex(0x7d7163), FLAME_DARK = hex(0xffb35c), FLAME_LIGHT = hex(0xffd79a);
    constexpr SRGB  NIGHT = hex(0x0b0e21), CAME_DARK = hex(0x07080f), MOON_DARK = hex(0x7d92ff), SUN_LIGHT = hex(0xffdca0);
    constexpr SRGB  SCREEN_DARK = hex(0x9fb2ff), SCREEN_LIGHT = hex(0xfff3dc);

    enum class eStyle : uint8_t {
        NAVE,
        GALLERY,
        LANTERN,
    };

    struct V3 {
        float x = 0, y = 0, z = 0;
    };

    V3    operator+(V3 a, V3 b);
    V3    operator-(V3 a, V3 b);
    V3    operator*(V3 a, float k);
    float dot(V3 a, V3 b);
    V3    norm(V3 a);

    struct SFull {
        CRegion damage;
        CBox    clip;

        SFull(const PHLMONITOR& monitor) {
            auto& rd   = Gl::ctx->m_data;
            damage     = rd.damage.copy();
            clip       = rd.clipBox;
            rd.damage  = CRegion{0, 0, monitor->m_pixelSize.x, monitor->m_pixelSize.y};
            rd.clipBox = {};
        }

        ~SFull() {
            auto& rd   = Gl::ctx->m_data;
            rd.damage  = damage;
            rd.clipBox = clip;
        }
    };

    struct SPose {
        V3 eye, r{1, 0, 0}, u{0, 1, 0}, f{0, 0, 1};
    };

    struct SPlace {
        size_t room = 0;
        V3     origin, x{1, 0, 0}, y{0, 1, 0}, z{0, 0, 1};
        float  phi = 0, frame = 1, dim = 1, depth = 0, kindle = 0;
        bool   doors = false, mirrored = false;
    };

    struct SDoor {
        size_t room = 0;
        float  z = 0, phi = 0, reveal = 0, kindle = 0, light = 0, lit = 0;
        int    slot = -1;
    };

    struct SStage {
        SPose               cam;
        std::vector<SPlace> places;
        std::vector<SDoor>  doors;
        float               focus = 0, zoom = 0, floor = 0, lens = 0;
        Vector2D            sweep;
        V3                  boxLo, boxHi, glow;
        float               glowR = 0;
    };

    struct SRoom {
        WORKSPACEID                           id = 0;
        std::vector<SP<Render::IFramebuffer>> shots;
        SP<Render::IFramebuffer>              fb;
        float                                 seam = 0, paper = 0;
        bool                                  shot = false, ready = false;
    };

    struct SLeg {
        float s0 = 0, v0 = 0, s1 = 0, T = 0, ta = 0, td = 0, vc = 0;
    };

    struct SFlight {
        PHLMONITORREF                         monitor;
        PHLWORKSPACEREF                       to, held, next;
        eStyle                                style = eStyle::NAVE;
        bool                                  forced = false, pyre = false, hold = false, lit = false;
        std::vector<SRoom>                    rooms;
        SLeg                                  leg;
        PHLANIMVAR<float>                     clock;
        SP<Render::IFramebuffer>              canvas, paper, live, ember;
        float                                 s = 0, v = 0, lift = 0, reach = 1, t = 0, age = 0, dt = 0, adapted = -1;
        uint64_t                              serial = 0;
        int                                   first = 1, last = 5, frames = 0;
        WORKSPACEID                           from = 0, shown = 0;
        std::chrono::steady_clock::time_point tick = std::chrono::steady_clock::now();
        std::optional<std::chrono::steady_clock::time_point> begin;
    };

    inline std::vector<UP<SFlight>> flights;
    inline uint64_t                 serials = 0;

    struct SIris {
        GLuint                  fbo = 0;
        std::array<GLuint, 2>   pbo{};
        std::array<uint64_t, 2> sent{};
        size_t                  at = 0;
    };

    inline std::map<MONITORID, SIris> irises;

    extern SProgram hallProgram;
    extern SProgram dustProgram;

    void primeHall();
    bool hallReady();
    std::optional<eStyle> styleNow();
    std::pair<int, int> rangeOf(const PHLMONITOR& monitor);
    std::pair<int, int> romanOf(WORKSPACEID id);
    SFlight* flightOn(const PHLMONITOR& monitor);
    float seamOf(const PHLMONITOR& monitor, const PHLWORKSPACE& ws);
    void shoot(SRoom& r, const PHLMONITOR& monitor);
    void hide(const PHLWORKSPACE& ws);
    void show(const PHLWORKSPACE& ws, float alpha);
    void mipmap(const SP<Render::IFramebuffer>& fb);
    SP<Render::IFramebuffer> canvas(const PHLMONITOR& monitor);
    void develop(SRoom& r, const PHLMONITOR& monitor);
    void release(SFlight& f);
    void back(SFlight& f, const PHLMONITOR& monitor);
    SP<Render::IFramebuffer> imageOf(const SFlight& f, const SRoom& r);
    void blaze(SFlight& f, const PHLMONITOR& monitor);
    SLeg legOf(float s0, float v0, float s1);
    std::pair<float, float> along(const SLeg& l, float t);
    std::array<float, 2> poseOf(const SFlight& f, const PHLMONITOR& monitor, float s);
    SStage stageOf(const SFlight& f, const PHLMONITOR& monitor);
    std::optional<CBox> boundsOf(const SPlace& pl, const SRoom& room, const SStage& st, const PHLMONITOR& monitor);
    void drawFlight(SFlight& f, const PHLMONITOR& monitor);
    void advance(SFlight& f, const PHLMONITOR& monitor);
    void gaze(SFlight& f, const PHLMONITOR& monitor);
    void clockOn(SFlight& f, const PHLMONITOR& monitor);
    void furnish(SFlight& f, const PHLMONITOR& monitor, WORKSPACEID lo, WORKSPACEID hi);
    void shootNext(SFlight& f, const PHLMONITOR& monitor);
    void land(SFlight& f);
    void sight(SFlight& f, const PHLMONITOR& monitor, const PHLWORKSPACE& to);
    void turn(SFlight& f, const PHLMONITOR& monitor, const PHLWORKSPACE& to);
}
