#include "frame/Internal.hpp"
#include "life/Life.hpp"
#include <hyprland/src/desktop/view/window/Window.hpp>
#include <hyprland/src/desktop/view/window/WindowPresentation.hpp>

#include <algorithm>
#include <cmath>
#include <optional>
#include <random>

namespace Frame {
    void start(PHLANIMVAR<float>& clock, float ms) {
        clock->setConfig(clockOf(ms));
        clock->setValueAndWarp(0.F);
        *clock = 1.F;
    }

    std::mt19937 g_dice{std::random_device{}()};

    int beforeOf(int o, const std::array<int, 2>& n) {
        return (o > 0 ? n[0] : 0) + (o > 1 ? n[1] : 0) + (o > 2 ? n[0] : 0);
    }

    float stepOf(float c) {
        return PACE / std::sqrt(1 + 2 * c * PACE / RAMP);
    }

    float pauseOf(int o, const std::array<int, 2>& n) {
        return o > 2 ? BREATH : TURN * stepOf(float(beforeOf(o + 1, n) - 1));
    }

    float landOf(int o, int j, const std::array<int, 2>& n) {
        const float C = float(beforeOf(o, n) + j);
        return BUILD_T0 + RAMP * (std::sqrt(1 + 2 * C * PACE / RAMP) - 1) + (o > 0 ? pauseOf(0, n) : 0) + (o > 1 ? pauseOf(1, n) : 0) + (o > 2 ? pauseOf(2, n) : 0);
    }

    float runOf(const std::array<int, 2>& n) {
        return landOf(3, n[1] - 1, n) + pauseOf(3, n) - BUILD_T0;
    }

    Vector2D lightOf(const PHLWINDOW& w) {
        const auto M = w->m_monitor.lock();
        return M ? worldLight(M, pal()) + M->m_position : boxOf(w).middle() - Vector2D{0.0, 1e4};
    }
}

using namespace Frame;

void CGlassFrame::focus(bool on, double at, float wait, const PHLWINDOW& from, double fromAt) {
    const auto W = m_window.lock();
    m_f0         = shownFocus();
    m_on         = on;
    m_focusAt    = on ? secondsAlive() : m_focusAt;
    m_at         = at;
    m_wait       = on ? wait : 0.F;
    m_from       = from;
    m_fromAt     = fromAt;
    m_plateIn    = FLIGHT + std::min(SPREAD, LETTER * float(std::max<size_t>(m_letters, 1) - 1));
    const SRing RING(boxOf(W), W->presentation().rounding());
    const auto  CORNERS = RING.corners();
    const auto  LEFT    = [on](float v0, float wait, float in, float out) { return on ? wait + (1.F - v0) * in : v0 * out; };
    m_span              = std::max({on ? (m_f0.level < 1.F ? LEVEL_IN : 0.F) : (m_f0.level > 0.F ? LEVEL_OUT : 0.F), LEFT(m_f0.crest, 0, CREST_IN, CREST_OUT),
                                    LEFT(m_f0.plate, PLATE_DELAY, m_plateIn, PLATE_OUT), from ? m_wait + FADE : 0.F});
    for (int q = 0; q < 4; ++q) {
        m_stagger[q] = on ? STAGGER * float(RING.circ(CORNERS[q], at) / std::max(1.0, RING.per / 2)) : 0.F;
        m_span       = std::max(m_span, LEFT(m_f0.plant[q], m_stagger[q], PLANT_IN, PLANT_OUT));
    }
    m_span = m_span < 1.F ? 0.F : std::ceil(m_span);
    if (m_span > 0.F)
        start(m_light, m_span);
    else
        m_light->setValueAndWarp(1.F);
    if (from && std::ranges::find(g_glass->lanterns, m_window) == g_glass->lanterns.end())
        g_glass->lanterns.emplace_back(m_window);
}

void CGlassFrame::relight(bool on) {
    const auto W = m_window.lock();
    if (m_on != on && validMapped(W))
        focus(on, SRing(boxOf(W), W->presentation().rounding()).u(lightOf(W)), 0);
}

void CGlassFrame::handoff(const PHLWINDOW& from, const PHLWINDOW& to, const std::optional<CBox>& gone) {
    if (from == to)
        return;
    auto* const PREV = from && validMapped(from) ? of(from) : nullptr;
    auto* const NEXT = to && validMapped(to) ? of(to) : nullptr;
    const bool  PAIR = PREV && NEXT && from->m_monitor == to->m_monitor && from->m_workspace == to->m_workspace;
    if (PREV && PREV->m_on)
        PREV->focus(false, 0, 0);
    if (!NEXT)
        return;
    if (NEXT->m_role == ROLE_BORN && NEXT->lifeMs() >= 0) {
        NEXT->m_on   = true;
        NEXT->m_f0   = {1, 1, 1, {1, 1, 1, 1}};
        NEXT->m_wait = 0;
        NEXT->m_span = 0;
        NEXT->m_light->setValueAndWarp(1.F);
        return;
    }
    const auto  B = boxOf(to);
    const SRing RING(B, to->presentation().rounding());
    if (PAIR) {
        const auto   A    = boxOf(from);
        const SRing  OLD(A, from->presentation().rounding());
        const bool   HIGH = from->isFloating() || to->isFloating();
        const double TO = HIGH ? RING.ex : RING.u(toward(B, A)), FROM = HIGH ? OLD.ex : OLD.u(toward(A, B));
        const auto   HOP = OLD.at(FROM, cameOf(from, A)).distance(RING.at(TO, cameOf(to, B)));
        NEXT->focus(true, TO, std::clamp(float(HOP) * 0.5F + 40.F, 40.F, CARRY), from, FROM);
    } else
        NEXT->focus(true, RING.u(gone ? toward(B, *gone) : lightOf(to)), 0);
}

void CGlassFrame::lift(bool on) {
    if (on && m_role == ROLE_RECEIVER)
        m_role = ROLE_NONE;
    m_liftFrom  = lifted();
    m_liftTo    = on ? 1.F : 0.F;
    m_sealFrom  = -1;
    m_sealWait  = 0;
    m_sealGain  = 0.75F;
    start(m_lift, LIFT);
    start(m_seal, SEAL);
}

void CGlassFrame::echo(double from, float wait) {
    m_sealFrom = from;
    m_sealWait = wait;
    m_sealGain = ECHO;
    start(m_seal, wait + SEAL);
}

void CGlassFrame::call() {
    start(m_call, CALL);
}

void CGlassFrame::born(const PHLWINDOW& giver, int side) {
    m_role      = ROLE_BORN;
    m_peer      = giver;
    m_side      = side;
    m_on        = false;
    m_f0        = {};
    m_span      = 0;
    m_bornPlate = -1;
    m_pace      = 1;
    m_lifeLen   = giver ? 0.F : SMOLDERED;
    m_seed      = std::uniform_real_distribution<float>(0.F, 1.F)(g_dice);
    m_light->setValueAndWarp(1.F);
    start(m_life, giver ? LIFE : SMOLDERED);
}

void CGlassFrame::lend(eRole role, const PHLWINDOW& peer, int side, const CBox& gone, float goneLevel) {
    m_role      = role;
    m_peer      = peer;
    m_side      = side;
    m_gone      = gone;
    m_goneLevel = goneLevel;
    m_lentAt    = secondsAlive();
    m_heldAt    = -1;
    m_landed    = false;
    m_lifeLen   = 0;
    m_pace      = 1;
    m_syncPace  = 1;
    m_syncLead  = 0;
    start(m_life, LIFE);
}

std::array<int, 2> CGlassFrame::bricksOf(const PHLWINDOW& w) {
    const auto   M = w->m_monitor.lock();
    const double S = M ? M->m_scale : 1.0;
    const CBox   B = boxOf(w).translate(M ? -M->m_position : Vector2D{}).scale(S).round().scale(1.0 / S);
    const double R = w->presentation().rounding();
    return {std::max(1, int(std::floor(std::max(0.0, B.w - 2 * R) / PIECE + 0.5))), std::max(1, int(std::floor(std::max(0.0, B.h - 2 * R) / PIECE + 0.5)))};
}

float CGlassFrame::closeMs(const PHLWINDOW& w) {
    return BUILD_T0 + runOf(bricksOf(w));
}

void CGlassFrame::arrive(float wait, bool grand, bool forward) {
    const auto W = m_window.lock();
    m_arriveWait = wait;
    m_bricks     = grand && W ? bricksOf(W) : std::array<int, 2>{};
    m_run        = grand && W ? runOf(m_bricks) : 0;
    m_dir        = forward ? 1.F : -1.F;
    m_seed       = std::uniform_real_distribution<float>(0.F, 1.F)(g_dice);
    if (m_on) {
        m_f0   = {1, 1, 1, {1, 1, 1, 1}};
        m_span = 0;
        m_light->setValueAndWarp(1.F);
    }
    start(m_arrive, wait + (m_run > 0 ? closeAt() + SETTLED : ARRIVAL));
    damageEntire();
    if (m_run <= 0)
        return;
    const auto  N    = m_bricks;
    const int   ALL  = 2 * (N[0] + N[1]);
    std::string cues = std::format("arrive,{:x},forge@{}", reinterpret_cast<uintptr_t>(W.get()), std::lround(wait));
    const float LEVEL = forward ? 1.F : DOWN;
    float       cued  = -1e9F;
    for (int o = 0; o < 4; ++o) {
        const float      TURNED = landOf(o, N[o % 2] - 1, N) + pauseOf(o, N) / 2;
        std::vector<int> heard;
        for (int j = 0; j < N[o % 2]; ++j)
            if (const float T = landOf(o, j, N); T - cued >= CUE_GAP && (o == 3 || TURNED - T >= CUE_GAP)) {
                heard.push_back(j);
                cued = T;
            }
        const int K = int(heard.size());
        for (int k = 0; k < K; ++k) {
            const int M    = K > NOTES ? k : int(std::lround(float(k * (NOTES - 1)) / float(std::max(K - 1, 1))));
            const int NOTE = NOTES - 1 - std::abs(M % (2 * NOTES - 2) - (NOTES - 1));
            cues += std::format(",link-{}-{}@{}@{:.2f}", forward ? o + 1 : 4 - o, forward ? NOTE + 1 : NOTES - NOTE, std::lround(wait + landOf(o, heard[k], N)),
                                LEVEL * (SOFT + (LOUD - SOFT) * float(beforeOf(o, N) + heard[k]) / float(std::max(ALL - 1, 1))));
        }
        if (o < 3) {
            cues += std::format(",turn-{}@{}@{:.2f}", forward ? o + 1 : 2 - o, std::lround(wait + TURNED), LEVEL * (0.55F + 0.15F * float(o)));
            cued = TURNED;
        }
    }
    announce(cues + std::format(",{}@{}@{:.2f}", forward ? "seal" : "seal-down", std::lround(wait + closeAt() + CLOSE_CREST + 0.7F * CREST_DROP), LEVEL));
    echo(SRing(boxOf(W), W->presentation().rounding()).corners()[forward ? 0 : 1], wait + closeAt() - 60);
    m_sealGain = LAP;
}

bool CGlassFrame::sounding() const {
    const float A = arriveMs();
    return m_run > 0 && A != NOT_ARRIVING && A < closeAt() + CLOSE_CREST + 0.7F * CREST_DROP;
}

float CGlassFrame::arriveMs() const {
    return m_arrive->isBeingAnimated() ? m_arrive->value() * (m_arriveWait + (m_run > 0 ? closeAt() + SETTLED : ARRIVAL)) - m_arriveWait : NOT_ARRIVING;
}

float CGlassFrame::closeAt() const {
    return BUILD_T0 + m_run;
}

double CGlassFrame::reachNow() const {
    return MARGIN + (m_run > 0 && arriveMs() != NOT_ARRIVING ? REACH : 0);
}

void CGlassFrame::hold(SP<Render::IFramebuffer> still, const CBox& box, float wait) {
    m_still    = std::move(still);
    m_stillBox = box;
    m_holdWait = wait;
    start(m_hold, wait + LET_GO);
}

void CGlassFrame::keep(float wait) {
    if (held() < 1.F)
        return;
    m_holdWait = wait;
    start(m_hold, wait + LET_GO);
}

float CGlassFrame::held() const {
    return m_still ? 1.F - span(m_hold->value() * (m_holdWait + LET_GO), m_holdWait, m_holdWait + LET_GO) : 0.F;
}

const SP<Render::IFramebuffer>& CGlassFrame::still() const {
    return m_still;
}

void CGlassFrame::release() {
    m_still.reset();
}

float CGlassFrame::lifeMs() const {
    return m_role == ROLE_NONE || !m_life->isBeingAnimated() ? -1.F : m_life->value() * (m_lifeLen > 0 ? m_lifeLen : LIFE);
}

float CGlassFrame::paceMs() const {
    const float T = lifeMs();
    return T < 0 ? T : T * m_pace;
}

float CGlassFrame::syncMs() const {
    const float T = lifeMs();
    return T < 0 ? T : (T + m_syncLead) * m_syncPace;
}

void CGlassFrame::pace(float k) {
    m_pace = k;
}

bool CGlassFrame::settle() {
    const auto W = m_window.lock();
    if (m_role != ROLE_RECEIVER || lifeMs() < 0 || !validMapped(W))
        return false;
    const auto AWAY   = [](const auto& v) { return std::max(std::abs(v->value().x - v->goal().x), std::abs(v->value().y - v->goal().y)); };
    const bool MOVING = std::max(AWAY(W->sizeAnimation()), AWAY(W->positionAnimation())) > SETTLE_PX;
    const bool CAPPED = m_heldAt >= 0 && secondsAlive() - m_heldAt > HOLD;
    if (m_landed || !MOVING || CAPPED || syncMs() <= SLAM - 1) {
        m_landed = m_landed || syncMs() >= SLAM;
        return MOVING && !m_landed && !CAPPED;
    }
    m_heldAt   = m_heldAt < 0 ? secondsAlive() : m_heldAt;
    m_lifeLen  = (AFTER + 1) / m_syncPace;
    m_syncLead = (SLAM - 1) / m_syncPace;
    start(m_life, m_lifeLen);
    g_pHyprRenderer->damageBox(m_gone.copy().expand(MARGIN + 64));
    return true;
}

void CGlassFrame::sync(float pace, float lead) {
    m_syncPace = pace;
    m_syncLead = lead;
    m_lifeLen  = std::max(LIFE, (SLAM + AFTER) / pace - lead);
    start(m_life, m_lifeLen);
}

void CGlassFrame::hasten(float k) {
    m_lifeLen = 0;
    start(m_life, LIFE / k);
}
