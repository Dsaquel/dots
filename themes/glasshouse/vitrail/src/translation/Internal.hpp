#pragma once

#include "translation/Translation.hpp"
#include "enfilade/Enfilade.hpp"
#include "frame/Frame.hpp"
#include "core/Gl.hpp"
#include "life/Life.hpp"
#include "mullion/Mullion.hpp"
#include "core/Palette.hpp"
#include "core/Ring.hpp"
#include "core/globals.hpp"

#include <hyprland/src/desktop/view/window/Window.hpp>
#include <hyprland/src/desktop/view/window/WindowPresentation.hpp>
#include <hyprland/src/desktop/view/window/WindowEffectsController.hpp>
#include <hyprland/src/render/transformer/TransformerList.hpp>
#include <hyprland/src/workspace/HLWorkspace.hpp>
#include <hyprland/src/desktop/state/WindowState.hpp>
#include <hyprland/src/desktop/state/FocusState.hpp>
#include <hyprland/src/layout/LayoutManager.hpp>
#include <hyprland/src/managers/SessionLockManager.hpp>
#include <hyprland/src/managers/fullscreen/FullscreenController.hpp>
#include <hyprland/src/animation/AnimationManager.hpp>
#include <hyprland/src/render/Renderer.hpp>
#include <hyprland/src/render/OpenGL.hpp>
#include <hyprland/src/render/Framebuffer.hpp>
#include <hyprland/src/render/pass/PassElement.hpp>
#include <hyprland/src/render/transformer/Transformer.hpp>
#include <hyprland/src/output/Monitor.hpp>
#include <hyprland/src/state/MonitorState.hpp>

#include <algorithm>
#include <array>
#include <cmath>
#include <format>
#include <optional>
#include <ranges>
#include <span>
#include <utility>
#include <vector>

using namespace Render::GL;
using Gl::SProgram;
using GEO = Desktop::View::IGeometric;

namespace Translation {
    extern SProgram quarryProgram;
    extern SProgram huskProgram;
    extern SProgram veilProgram;
    extern SProgram sparkProgram;
    extern SProgram weldProgram;
    extern SProgram ashProgram;
    extern SProgram infuseProgram;
    extern SProgram strikeProgram;
    extern SProgram pivotProgram;
    extern SProgram poolProgram;
    extern SProgram gateProgram;

    enum class eKind : uint8_t {
        TRANSLATE,
        RELEAD,
        PIVOT,
        SWAP,
    };

    enum eSpark : uint8_t {
        CRACKS,
        FORMS,
        SLAMS,
        WELDS,
        TIPS,
        BURST,
        GILT,
        WHIP,
        STREAM,
        ZIP,
        BREACH,
        FLARE,
        MEND,
    };

    constexpr float  CRACK = 80, BROKEN = 420, HUSKED = 240, SHED = 120, SHIFTED = 110;
    constexpr float  POP = 50, POPPED = 20, LEAVE = 30, SPREAD = 140, FORM = 120, FORMING = 90, FORMED = 140;
    constexpr float  DASH = 90, DASHED = 70, REVEAL = 90, GAP = 20, CUE = 170;
    constexpr float  WAVE = 120, SEAM = 90, WELD = 280, MOTE = 620;
    constexpr float  CLOCK = 3000, SHUT = 1e9F, HUSH = 0.2F, TAKEN = 0.15F, SWAP = 0.8F;
    constexpr int    ROUNDS = 10;
    constexpr double MOVED = 48, RESIZED = 0.2;
    constexpr float  HOLD = 200, STRETCH = 180, PYRE = 1500, LEAD = 0, BURNED = 300, ARRIVE = 320, EMBERS = 60, LEAP = 280, RISEN = 60, HALT = 1e5F;
    constexpr float  GATHERED = 480, RELEASED = 345, JOINED = 60, BORN = 20, LAG = 300, DRAIN = 90, STRUNG = 180;
    constexpr float  PACKED = 80, QUENCHED = 480, STRUCK = 480, JOLTED = 120, KICK = 0.019F, SPEAR = 60, WAIT = 80, RELAYED = 1.5F;
    constexpr int    LEADS = 8;
    constexpr int    MOTES = 7000, TRAIL = 3, POSES = 48, WAKE = 24;
    constexpr std::array<std::array<float, 3>, 4> PASSES = {{{0.F, 0.F, 1.F}, {1.F, 28.F, 0.15F}, {1.F, 14.F, 0.35F}, {1.F, 0.F, 1.F}}};
    constexpr float  FLUSH = 40, SWING = 40, TWIST = 50, SLAM = 300, SHOCK = 140, REGLAZE = 60, LIFT = 70, SEATING = 320, DIMMING = 384, SEATED = 480, SETTLED = 560;
    constexpr float  WAVED = 60, SEAMED = 40, COOLED = 130, EASE = 0.3F, WIND = 0.05F, BREAK = 110, RIFT = 85, HALO = 110, DUSTED = 900, BREACHED = 420, FLARED = 380, ARCING = 140, REACH = 30, ZAPPED = 12, ROOM = 40, RIM = 8, REWOUND = 50, FAN = 100, BOW = 30, FRESH = 60, REVERSED = 80;
    constexpr int    SPRAY = 120, BURSTS = 48, GILDED = 40, GILTS = 8, WHIPS = 160, SKEWS = 9, GATES = 4, STREAMS = 160, ZIPS = 96, BREACHES = 240, FLARES = 180, STRIKES = 3, DROPS = 12, LINKS = 128;
    constexpr std::array<std::array<float, 3>, 4> TRAILS = {{{0.F, 0.F, 1.F}, {1.F, 8.F, 0.1F}, {1.F, 4.F, 0.2F}, {1.F, 0.F, 1.F}}};
    constexpr std::array<std::array<float, 3>, 3> WEAVE  = {{{1.F, 8.F, 0.07F}, {1.F, 4.F, 0.15F}, {0.F, 0.F, 1.F}}};
    constexpr std::array<std::array<float, 3>, 1> UMBRA  = {{{-1.F, 0.F, 1.F}}};

    struct SCarry {
        PHLWINDOWREF                window;
        PHLMONITORREF               from;
        CBox                        source, shot, goal;
        Vector2D                    grid, lattice;
        float                       radius = 8, seed = 0, opened = SHUT, delay = 0, base = SHUT, first = 0, last = 0;
        GLuint                      perm = 0;
        CBox                        pair;
        Vector2D                    pivot, oldDir, glide;
        std::array<Vector2D, 2>     hubs;
        float                       sweep = 0, sense = 1, far = 1, gutter = 0, ahead = 0, fresh = 0;
        std::array<float, SKEWS>    skew = {};
        bool                        lead = false;
        int                         rank = 0;
        std::vector<std::array<float, 4>> gilt, gates, cells;
        std::optional<CGlassPass::SData>  ornate;
        SP<Render::IFramebuffer>    snapshot;
        Render::IWindowTransformer* veil = nullptr;
        PHLANIMVAR<float>           clock;
        eKind                       kind  = eKind::TRANSLATE;
        bool                        armed = false, framed = false, landed = false, cued = false, bed = true, seats = true;

        ~SCarry() {
            if (!perm)
                return;
            g_pHyprOpenGL->makeEGLCurrent();
            glDeleteTextures(1, &perm);
        }
    };

    struct SBefore {
        PHLWINDOWREF                     window;
        CBox                             box;
        SP<Render::IFramebuffer>         shot;
        std::optional<CGlassPass::SData> ring;
    };

    class CShroud : public Gl::CTransformer {
      public:
        virtual Render::SWindowTransformBuffer transform(Render::CRenderContext& ctx, const Render::SWindowTransformBuffer& in, const Render::SWindowTransformContext& context) override {
            if (!in.framebuffer || !in.framebuffer->getTexture())
                return in;
            auto guard = g_pHyprRenderer->bindTempFB(ctx, in.framebuffer);
            g_pHyprRenderer->disableScissor();
            glClearColor(0.F, 0.F, 0.F, 0.F);
            glClear(GL_COLOR_BUFFER_BIT);
            return in;
        }
    };

    inline void strip(const PHLWINDOW& w, CShroud*& t) {
        if (w && t) {
            Gl::drop(w, t);
            g_pHyprRenderer->damageWindow(w);
        }
        t = nullptr;
    }

    struct SPyre {
        PHLWINDOWREF                             window, giver;
        PHLMONITORREF                            monitor, from, past;
        PHLWORKSPACEREF                          source, target, aim, held;
        CBox                                     box, shot, slot;
        Vector2D                                 entry, heading, fired;
        float                                    radius = 8;
        SP<Render::IFramebuffer>                 snapshot;
        SP<CGhost>                               ghost;
        std::vector<SBefore>                     before, aimed;
        std::array<std::array<float, 3>, WAKE>   wake = {};
        std::vector<std::array<float, 5>>        leads;
        std::array<float, 4>                     cut = {}, lens = {};
        std::vector<float>                       poses;
        Vector2D                                 recoil, jolt;
        PHLWORKSPACEREF                          jolted;
        PHLANIMVAR<float>                        clock;
        WORKSPACEID                              origin = WORKSPACE_INVALID, aimOrigin = WORKSPACE_INVALID;
        int                                      side   = -1;
        float                                    seed = 0, doors = SHUT, seated = SHUT, base = 0, draft = HOLD, turned = SHUT, lagged = LAG, waked = 0, spurred = SHUT;
        float                                    stride = Enfilade::STRIDE;
        bool                                     armed = false, forward = true, alone = false, walks = true, aimWalks = true, flies = false;
        CShroud*                                 shroud = nullptr;

        ~SPyre() {
            strip(window.lock(), shroud);
            if (const auto WS = jolted.lock(); WS && jolt != Vector2D{} && !WS->m_renderOffset->isBeingAnimated())
                WS->m_renderOffset->setValueAndWarp({});
            if (const auto G = giver.lock(); G && (!walks || flies) && seated >= SHUT) {
                G->positionAnimation()->warp();
                G->sizeAnimation()->warp();
            }
        }
    };

    struct SCopy {
        PHLMONITORREF            monitor;
        SP<Render::IFramebuffer> fb;
    };

    inline std::vector<UP<SCarry>> flights;
    inline std::vector<UP<SPyre>>  pyres;
    inline std::vector<SCopy>      copies;
    inline float                   hushed = 0, takenAt = -1;

    inline auto flightOf(const PHLWINDOW& w) {
        return std::ranges::find_if(flights, [&w](const UP<SCarry>& c) { return !c->landed && c->window.lock() == w; });
    }

    struct SPath {
        Vector2D                               target, away, entry, came, heading;
        std::array<float, 4>                   lens = {}, view = {}, times = {}, slot = {}, seam = {}, shot = {}, burn = {}, turn = {};
        std::vector<float>                     poses;
        std::array<std::array<float, 3>, WAKE> wake = {};
        float                                  stride = 1, forward = 1, alone = 0, bridge = 0, scale = 1, burnSeed = 0, nave = 0;
    };

    struct SDot {
        Vector2D at;
        double   z = 0;
    };

    struct SSplit {
        int    axis = 0;
        double at = 0, gap = 0;
        bool   first = true;
    };

    struct STurn {
        CBox                     pair;
        Vector2D                 pivot;
        double                   gutter = 0;
        std::array<PHLWINDOW, 2> sides;
        std::array<Vector2D, 2>  olds, news;
    };

    struct SSwap {
        CBox                              hull;
        std::vector<PHLWINDOW>            windows;
        std::vector<std::array<float, 4>> gates;
        Vector2D                          glide;
        double                            gutter = 0;
    };

    struct SRelay {
        PHLWINDOW              mover, receiver, giver;
        CBox                   from, room;
        std::vector<PHLWINDOW> rest;
        bool                   arrives = true;
    };

    struct SFell {
        PHLWINDOW                window;
        PHLMONITOR               monitor;
        SP<Render::IFramebuffer> snapshot;
        CBox                     box;
    };

    float ms(const SCarry& c);
    float ms(const SPyre& p);
    float weldOf(const SCarry& c);
    float endOf(const SCarry& c);
    void bindPerm(int unit, GLuint tex);
    void upload(SCarry& c, int nu, const std::vector<std::array<float, 4>>& texels);
    void plan(SCarry& c);
    CBox hullOf(const SCarry& c);
    float easeOf(float k);
    float soft(float k);
    float ringAge(const SCarry& c, double d);
    double nearest(const std::vector<std::array<float, 4>>& gates, const Vector2D& p);
    void bindGates(Gl::SProgram& p, const SCarry& c, const Vector2D& origin, double scale);
    float progressOf(float r, float t);
    float angleOf(const SCarry& c, float r, float t);
    void planTurn(SCarry& c);

    SP<Render::IFramebuffer> copyOf(const PHLMONITOR& m, bool make);
    bool touches(const SCarry& c, const PHLMONITOR& m);
    void unveil(SCarry& c);
    std::string addressOf(const PHLWINDOW& w);
    SCarry* launch(const PHLWINDOW& w, const PHLMONITOR& mon, const SP<Render::IFramebuffer>& snap, eKind kind, const std::optional<CBox>& was = std::nullopt);
    SP<Render::IFramebuffer> shoot(const PHLWINDOW& w, eShot kind = eShot::SKINNED);

    void drawFrame(const SCarry& c, const PHLWINDOW& w, const PHLMONITOR& m);
    void drawSeat(const PHLWINDOW& w, float t, const PHLMONITOR& m);
    void drawLift(const SCarry& c, float t);
    void drawHusk(const SCarry& c, float t, const PHLMONITOR& m);
    void project(Gl::SProgram& p, const PHLMONITOR& m);
    void strokes(Gl::SProgram& p, const Gl::SArea& area, int count);
    size_t depthOf(const PHLWINDOW& w);
    std::optional<Gl::SArea> areaBelow(const CBox& phys, const PHLWINDOW& w, const PHLMONITOR& m);
    void drawQuarries(const SCarry& c, const PHLWINDOW& w, float t, const PHLMONITOR& m, bool shuffled, std::span<const std::array<float, 3>> layers, float parity = -1);

    void drawSparks(const SCarry& c, const PHLWINDOW& w, float t, const PHLMONITOR& m, eSpark kind);
    void drawRifts(const SCarry& c, const PHLWINDOW& w, float t, const PHLMONITOR& m);
    void drawWeld(const SCarry& c, const PHLWINDOW& w, float t, const PHLMONITOR& m, bool bolt = false);
    void drawHand(const SCarry& c, float t, const PHLMONITOR& m);
    void drawPool(const SCarry& c, const PHLWINDOW& w, float t, const PHLMONITOR& m);
    void drawGate(const SCarry& c, float t, const PHLMONITOR& m);

    std::array<float, 4> timesOf(const SPyre& p, float t);
    std::optional<CBox> seamOf(const PHLMONITOR& a, const PHLMONITOR& b);
    Vector2D awayOf(const SPyre& p);
    bool touches(const SPyre& p, const PHLMONITOR& m);
    void rewire(SPyre& p);
    void cloak(SPyre& p, const PHLWINDOW& w);
    void drawAsh(const SPyre& p, float t, const PHLMONITOR& m);
    void drawInfuse(const SPyre& p, float t, const PHLMONITOR& m);
    void drawStrike(const SPyre& p, float t, const PHLMONITOR& m);

    double soft(double k);
    double dot(const Vector2D& a, const Vector2D& b);
    Vector2D unitOf(const Vector2D& v);
    SDot project(const SPath& P, const SDot& x, double cam);
    SDot spineAt(const SPath& P, double tau);
    double lagOf(const SPath& P, double tt);
    Vector2D cameOf(const SPyre& p);
    void track(SPyre& p);
    SPath pathOf(const SPyre& p, float t);

    bool shifted(const CBox& was, const CBox& now);
    bool turnable(const PHLWINDOW& w);
    bool pourable(const PHLWINDOW& w);
    CBox hullOf(const std::vector<CBox>& boxes);
    std::optional<SSplit> splitOf(const CBox& a, const CBox& b, const CBox& u);
    std::optional<STurn> pairOf(const std::vector<PHLWINDOW>& moved, const std::vector<CBox>& was);
    void unturn(const PHLWINDOW& w);
    void turnPair(const STurn& turn, const PHLMONITOR& monitor, const PHLWINDOW& focus);

    std::optional<SSwap> swapOf(const std::vector<PHLWINDOW>& moved, const std::vector<CBox>& was);
    float uOf(const std::array<float, 4>& q, float t);
    void planSwap(SCarry& c, const std::vector<float>& cut);
    void swapSet(const SSwap& swap, const PHLMONITOR& monitor, const PHLWINDOW& focus);

    std::optional<SRelay> relayOf(const std::vector<PHLWINDOW>& moved, const std::vector<CBox>& was);
    void relay(const SRelay& r, const PHLMONITOR& monitor, const PHLWINDOW& focus);

    bool bare(const PHLWINDOW& w, const PHLWORKSPACE& to);
    bool room(const PHLWINDOW& w, const PHLWORKSPACE& to);
    bool kindles(const PHLWINDOW& w, const PHLWORKSPACE& from, const PHLWORKSPACE& to, const PHLMONITOR& src, const PHLMONITOR& land);
    std::vector<SBefore> capture(const PHLWINDOW& w, const PHLWORKSPACE& to, const PHLMONITOR& mon);
    void kindle(const PHLWINDOW& w, const PHLMONITOR& src, const PHLMONITOR& land, const PHLWORKSPACE& from, const PHLWORKSPACE& to, const SP<Render::IFramebuffer>& snap, std::vector<SBefore>&& before);
    bool kindled(SPyre& p, const PHLMONITOR& mon);
    void stretch(const SPyre& p);
    std::string cuesOf(const SPyre& p, const PHLWINDOW& w, float now, bool rooted);
    void seat(SPyre& p, float t);
    Vector2D kickOf(const SPyre& p, float t);
    void jolt(SPyre& p, float t);
    float gathered(const SPyre& p);
    bool ready(const SPyre& p, float t);
    void land(SPyre& p, const PHLWINDOW& leaving);

    void hurry(const PHLWINDOW& w, const PHLMONITOR& src, const PHLMONITOR& dst);
    bool aim(SPyre& p, const PHLWINDOW& w, const PHLWORKSPACE& to);
    bool tend(SPyre& p, const PHLMONITOR& monitor, std::vector<SFell>& fell, std::vector<std::string>& lit, bool& hushed);
}
