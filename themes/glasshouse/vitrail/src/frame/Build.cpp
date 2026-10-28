#include "frame/Internal.hpp"
#include "life/Life.hpp"
#include "core/Assets.hpp"
#include <hyprland/src/desktop/view/window/Window.hpp>
#include <hyprland/src/desktop/view/window/WindowPresentation.hpp>

#include <algorithm>
#include <cmath>
#include <optional>

#include <hyprland/src/desktop/view/window/Window.hpp>
#include <hyprland/src/desktop/view/window/WindowPresentation.hpp>

using namespace Frame;

namespace Frame {
    float cornerGlow(const Vector2D& light, const Vector2D& at) {
        const auto D = light - at;
        return 0.28F + 0.72F * std::exp(-float(D.x * D.x + D.y * D.y) / (820.F * 820.F));
    }

    bool probing(const PHLWINDOW& w) {
        const std::string P{g_glass->probe->value()};
        return !P.empty() && w->metadata().appID().starts_with(P);
    }
}

std::optional<CGlassPass::SData> CGlassFrame::build(const PHLMONITOR& monitor, float alpha) {
    const auto W = m_window.lock();
    if (!validMapped(W) || !monitor)
        return std::nullopt;
    const float a = alpha;

    know(W);
    const float ARRIVE   = arriveMs();
    const bool  ARRIVING = ARRIVE != NOT_ARRIVING;
    if (ARRIVING && ARRIVE < 0.F)
        return std::nullopt;
    const auto&    P       = pal();
    const double   S       = monitor->m_scale;
    const CBox     WIN     = boxOf(W).translate(-monitor->m_position);
    const CBox     BOX     = WIN.copy().scale(S).round().scale(1.0 / S);
    const bool     COMPACT = W->onSpecialWorkspace() || BOX.w < 360 || BOX.h < 220;
    const float    CAME    = COMPACT ? 7.5F : 9.5F;
    const float    RADIUS  = float(W->presentation().rounding());
    const SRing    RING(BOX, RADIUS);
    const Vector2D LAMP    = worldLight(monitor, P);
    const float    T       = paceMs();
    const auto     PEER    = m_peer.lock();
    const bool     SHARE   = m_role == ROLE_BORN && validMapped(PEER);
    if (SHARE && T >= 0 && T < SET)
        return std::nullopt;
    const double   GAPFULL = RING.half(m_side);
    const bool     RECV    = m_role == ROLE_RECEIVER && T >= 0;
    const auto     GOAL    = W->sizeAnimation()->goal(), FROM = W->sizeAnimation()->begun();
    const float    SYNC    = T < 0 ? T : syncMs();
    const float    FOLDED  = !RECV ? 1.F : (SYNC < SLAM ? 1.F - span(SYNC, 0, FOLD) : span(SYNC, SLAM, SLAM + QUICK));
    const auto     AFLOATS = [&](float seat) { return RECV && m_side % 2 == 1 ? outCubic(span(SYNC, 0, AFLOAT)) * (1.F - std::pow(span(SYNC, seat - SEAT, seat), 2.F)) : 0.F; };
    const SFocus   F       = shownFocus();
    const double   GAP     = m_role == ROLE_RECEIVER ? 0.0 : (GAPFULL + RING.arc / 2 + 24) * (1 - inOutCubic(span(T, SET + 20, LIFE - 20)));
    const auto     layOf   = [&](double u, const Vector2D& at) {
        if (ARRIVING || T < 0)
            return 1.F;
        if (m_role == ROLE_BORN && !SHARE)
            return outCubic(span(T, SET, SET + 90));
        return unit(float((RING.circ(u, RING.mid(m_side)) - GAP) / 24 + 1));
    };

    CGlassPass::SData data{
        .window    = WIN,
        .scale     = float(S),
        .alpha     = a,
        .radius    = RADIUS,
        .offset    = CAME,
        .hwOff     = COMPACT ? 1.F : 1.15F,
        .hwOn      = COMPACT ? 1.7F : 2.2F,
        .level     = F.level,
        .lift      = unit(lifted()),
        .light     = LAMP,
        .pal       = &P,
        .probe     = probing(W),
    };

    if (const float SEALED = m_seal->value(); SEALED < 1.F) {
        const float T = SEALED * (SEAL + m_sealWait) - m_sealWait;
        if (T >= 0)
            data.seal = {float(m_sealFrom < 0 ? RING.ex : m_sealFrom), T < 60 ? -40.F : -40.F + float(RING.per / 2 + 100) * unit((T - 60) / 280), m_sealGain * (1.F - unit((T - 200) / 220)), 0.F};
    }
    if (T >= 0) {
        if (m_role == ROLE_BORN && !SHARE)
            data.athanor = {T, m_seed, 0.F, 0.F};
        else if (m_role == ROLE_RECEIVER) {
            const CBox G    = m_gone.copy().translate(-monitor->m_position);
            data.hinge      = {float(m_side), SYNC, float(GOAL.x), float(GOAL.y)};
            data.grow       = {float(FROM.x), float(FROM.y), m_goneLevel, 0.F};
            data.gone       = {float(G.x), float(G.y), float(G.w), float(G.h)};
            data.reach      = (m_gone.w > 0 ? std::max(0.0, m_side % 2 == 1 ? GOAL.x - BOX.w : GOAL.y - BOX.h) : 0.0) + HOIST;
            data.vanish     = {float(monitor->m_size.x / 2), float(monitor->m_size.y / 2)};
            data.room       = {float(monitor->m_size.x / 2), float(monitor->m_size.y / 2), 0.F, 0.F};
        } else
            data.gap = {float(RING.mid(m_side)), float(GAP), 0.9F * (1.F - span(T, LIFE - 80, LIFE - 20)), 0.F};
    }
    if (ARRIVING && !RECV) {
        data.gap     = {0, -1, 0, 0};
        data.athanor = {-1, 0, 0, 0};
        data.veil    = span(ARRIVE, 0, VEIL_IN);
        data.build   = {ARRIVE, float(m_bricks[0]), float(m_bricks[1]), m_dir};
        if (m_run > 0) {
            const CBox R = monitor->logicalBoxMinusReserved().translate(-monitor->m_position);
            data.room    = {float(BOX.y - R.y), float(R.x + R.w - BOX.x - BOX.w), float(R.y + R.h - BOX.y - BOX.h), float(BOX.x - R.x)};
            data.reach   = REACH;
            data.seed    = m_seed;
        }
    }
    if (const float CALLED = m_call->value(); CALLED < 1.F) {
        const float PULSE = std::fmod(3.F * CALLED, 1.F), WAVE = std::sin(float(M_PI) * PULSE);
        data.call         = WAVE * WAVE * (1.F - 0.35F * CALLED);
    }
    if (const auto CARRIED = lantern(&data.lanternGlow); CARRIED && !data.probe)
        data.lantern = CARRIED->copy().translate(-monitor->m_position);

    if (std::ranges::max(std::array{F.crest, F.plate, F.plant[0], F.plant[1], F.plant[2], F.plant[3]}) > 0.003F && !data.probe) {
        const double GX = BOX.x, GY = BOX.y, GW = BOX.w, GH = BOX.h;
        const float  BY = COMPACT ? 0.72F : 1.F, SIZE = 120 * BY, ANCHOR = 36 * BY;
        const auto   CORNERS = RING.corners();
        const auto   CORNER  = [&](int q) { return Vector2D{q == 0 || q == 3 ? GX - CAME : GX + GW + CAME, q < 2 ? GY - CAME : GY + GH + CAME}; };
        const auto   SOWN    = [&](int q) { return SOW * float(RING.circ(CORNERS[q], RING.u(LAMP)) / std::max(1.0, RING.per / 2)); };
        const float  CREST   = m_run > 0 ? closeAt() + CLOSE_CREST : CREST_AT;
        const float  SOWN0   = m_run > 0 ? CREST : 0.F;
        const auto   GROWN   = [&](int q) {
            return F.plant[q] * (ARRIVING ? span(ARRIVE, SOWN0 + SOWN(q), SOWN0 + SOWN(q) + BLOOM) : layOf(CORNERS[q], CORNER(q))) * (q == m_side || q == (m_side + 1) % 4 ? FOLDED : 1.F);
        };
        for (int q = 0; q < 4; ++q) {
            const float GROW = GROWN(q);
            if (GROW < 0.003F)
                continue;
            const auto   AT    = CORNER(q);
            const double TH    = q * M_PI / 2, CA = std::cos(-TH), SA = std::sin(-TH);
            const auto   D     = LAMP - AT;
            const auto   LOCAL = Vector2D{(ANCHOR + D.x * CA - D.y * SA) / SIZE, (ANCHOR + D.x * SA + D.y * CA) / SIZE};
            const double LX = LOCAL.x - ANCHOR / SIZE, LY = LOCAL.y - ANCHOR / SIZE, N = std::max(1e-3, std::hypot(LX, LY));
            data.pieces.push_back({.kind       = SPiece::FLOWER,
                                   .origin     = AT,
                                   .pivot      = {ANCHOR, ANCHOR},
                                   .size       = SIZE,
                                   .quarter    = q,
                                   .glow       = cornerGlow(LAMP, AT),
                                   .grow       = GROW,
                                   .metalLight = LOCAL,
                                   .glassLight = {0.3 + 0.14 * LX / N, 0.3 + 0.14 * LY / N}});
        }
        if (!P.dark) {
            for (int i = 0; i < 8; ++i) {
                const int    C     = i / 2;
                const auto   AT    = CORNER(C);
                const double REACH = 70 * BY, SX = C == 0 || C == 3 ? 1 : -1, SY = C < 2 ? 1 : -1;
                const float  SEED  = span(GROWN(C), 0.62F + 0.06F * float(i % 2), 0.92F + 0.06F * float(i % 2));
                data.pieces.push_back({.kind       = SPiece::PEARL,
                                       .origin     = i % 2 == 0 ? Vector2D{AT.x + SX * REACH, AT.y} : Vector2D{AT.x, AT.y + SY * REACH},
                                       .pivot      = {4, 4},
                                       .size       = 8,
                                       .scale      = 0.3F + 0.7F * outCubic(SEED),
                                       .opacity    = std::min(1.F, SEED * 2.F),
                                       .metalLight = {0.3, -0.4}});
            }
        }
        if (!COMPACT) {
            const float    DROP = ARRIVING ? span(ARRIVE, CREST, CREST + CREST_DROP) : 1.F;
            const float    FALL = 1.F - std::pow(unit(DROP / 0.7F), 2.F);
            const float    BOB  = DROP > 0.7F ? std::sin(float(M_PI) * (DROP - 0.7F) / 0.3F) * (1.F - (DROP - 0.7F) / 0.3F) : 0.F;
            const float    ZC   = AFLOATS(CREST_SEAT);
            const double   SPAN = FROM.x + (GOAL.x - FROM.x) * inOutCubic(span(SYNC, 30, CREST_SEAT - 20));
            const double   CX   = !RECV || m_side % 2 == 0 ? GX + GW / 2 : (m_side == 3 ? GX + GW - SPAN / 2 : GX + SPAN / 2);
            const Vector2D C{CX, GY - CAME - CREST_RISE * FALL - BUOY * ZC};
            const float    O = outCubic(F.crest) * layOf(RING.ex, C) * (SHARE && T >= 0 ? span(T, SET, SET + 160) : 1.F) * unit(DROP / 0.3F) * (m_side == 0 ? FOLDED : 1.F);
            data.pieces.push_back({.kind       = SPiece::CREST,
                                   .origin     = C,
                                   .pivot      = {26, 26},
                                   .size       = 52,
                                   .scale      = (0.6F + 0.4F * O) * (1.F + 0.35F * FALL - 0.18F * BOB) * (1.F + 0.2F * ZC),
                                   .opacity    = std::min(1.F, O * 1.4F),
                                   .glow       = cornerGlow(LAMP, C) + (ARRIVING ? 1.1F * std::exp(-std::pow((ARRIVE - CREST - 0.7F * CREST_DROP) / 60.F, 2.F)) : 0.F),
                                   .metalLight = (LAMP - C + Vector2D{26, 26}) / 52.0,
                                   .glassLight = {0.4, 0.34},
                                   .mark       = m_mark,
                                   .icon       = m_icon,
                                   .glyph      = m_glyph});
        }
        const float  WRITE = m_run > 0 ? closeAt() + CLOSE_PLATE : PLATE_AT;
        const double MAXW  = std::max(80.0, COMPACT ? GW - 128 : GW / 2 - 64 - 26 - 28);
        const double LEFT  = COMPACT ? 48 : 64;
        const bool   PLATE = !m_app.empty() || !W->metadata().title().empty();
        const auto*  TEXT  = PLATE ? &Assets::plate(m_app, W->metadata().title(), P.dark, MAXW, S) : nullptr;
        const double PW    = TEXT ? std::max(64.0, std::min(TEXT->natural, MAXW)) : 0;
        m_letters          = TEXT ? TEXT->letters.size() : 0;
        const float  LAY   = layOf(std::max(0.0, LEFT + PW / 2 - RADIUS), Vector2D{GX + LEFT + PW / 2, GY - CAME});
        const bool   BORN  = m_role == ROLE_BORN && T >= 0 && F.plate > 0.5F;
        if (BORN && m_bornPlate < 0 && LAY > 0.05F)
            m_bornPlate = T;
        const float  SPREAD_MS = BORN ? std::min(SPREAD, LETTER * float(std::max<size_t>(m_letters, 1) - 1)) : m_plateIn - FLIGHT;
        const float  FLOW      = BORN ? std::max(FLIGHT, std::min(FLIGHT + SPREAD_MS, 440.F - m_bornPlate)) : FLIGHT + SPREAD_MS;
        const float  STREAM    = BORN ? (m_bornPlate < 0 ? 0.F : unit((T - m_bornPlate) / FLOW)) : (ARRIVING ? std::min(F.plate, span(ARRIVE, WRITE, WRITE + m_plateIn)) : F.plate);
        data.plate         = {.on       = PLATE && STREAM > 0.003F,
                              .pos      = {GX + LEFT, GY - CAME - 11 - BUOY * AFLOATS(m_side == 3 ? SLAM : PLATE_SEAT)},
                              .opacity  = (BORN ? 1.F : LAY) * (m_side == 0 ? FOLDED : 1.F),
                              .stream   = STREAM,
                              .flight   = FLOW * FLIGHT / (FLIGHT + SPREAD_MS),
                              .spread   = FLOW * SPREAD_MS / (FLIGHT + SPREAD_MS),
                              .leaving  = !m_on,
                              .maxWidth = MAXW,
                              .app      = m_app,
                              .title    = W->metadata().title()};
    }

    return data;
}

std::optional<CBox> CGlassFrame::lantern(float* glow) const {
    const auto  FROM = m_from.lock();
    const auto  W    = m_window.lock();
    const float P = m_light->value(), T = P * m_span;
    if (!m_on || P >= 1.F || m_wait <= 0.F || T >= m_wait + FADE || !validMapped(FROM) || !validMapped(W))
        return std::nullopt;
    const auto     A  = boxOf(FROM), B = boxOf(W);
    const Vector2D P0 = SRing(A, FROM->presentation().rounding()).at(m_fromAt, cameOf(FROM, A)), P1 = SRing(B, W->presentation().rounding()).at(m_at, cameOf(W, B));
    const Vector2D C  = P0 + (P1 - P0) * inOutCubic(T / m_wait);
    if (glow)
        *glow = std::sin(float(M_PI) * std::min(1.F, T / (m_wait + FADE) * 1.15F));
    return CBox{C.x - GLOW / 2, C.y - GLOW / 2, GLOW, GLOW};
}

bool CGlassFrame::damageLantern(const PHLMONITOR& monitor) {
    const auto W = m_window.lock();
    if (!W)
        return false;
    if (W->m_monitor != monitor)
        return true;
    const auto NOW = lantern();
    if (m_lanternDrawn)
        g_pHyprRenderer->damageBox(m_lanternDrawn->copy().expand(2));
    if (NOW)
        g_pHyprRenderer->damageBox(NOW->copy().expand(2));
    const bool LIVE = NOW || m_lanternDrawn;
    m_lanternDrawn  = NOW;
    return LIVE;
}

void CGlassFrame::damageMotion(const PHLMONITOR& monitor) {
    const auto W = m_window.lock();
    if (!validMapped(W) || W->m_monitor != monitor)
        return;
    const bool MOVING = m_light->isBeingAnimated() || m_lift->isBeingAnimated() || m_seal->isBeingAnimated() || m_call->isBeingAnimated() || m_life->isBeingAnimated() ||
        m_arrive->isBeingAnimated() || m_hold->isBeingAnimated();
    if (m_still)
        g_pHyprRenderer->damageBox(m_stillBox.copy().expand(MARGIN + 2));
    if (!MOVING && !m_moving)
        return;
    const float T      = m_light->value() * m_span;
    const bool  VEILED = (m_light->isBeingAnimated() && T <= std::max(LEVEL_IN, LEVEL_OUT) + 20) || m_lift->isBeingAnimated() || m_life->isBeingAnimated() || m_arrive->isBeingAnimated() || !MOVING;
    m_moving           = MOVING;
    const CBox B = boxOf(W), OUT = B.copy().expand(reachNow() + 2), IN = B.copy().expand(-22);
    if (VEILED || IN.w < 1 || IN.h < 1) {
        g_pHyprRenderer->damageBox(OUT);
        return;
    }
    const double C = MARGIN + 98;
    for (const auto& box : {CBox{OUT.x, OUT.y, OUT.w, IN.y - OUT.y}, CBox{OUT.x, IN.y + IN.h, OUT.w, OUT.y + OUT.h - IN.y - IN.h}, CBox{OUT.x, IN.y, IN.x - OUT.x, IN.h},
                            CBox{IN.x + IN.w, IN.y, OUT.x + OUT.w - IN.x - IN.w, IN.h}, CBox{OUT.x, OUT.y, C, C}, CBox{OUT.x + OUT.w - C, OUT.y, C, C},
                            CBox{OUT.x, OUT.y + OUT.h - C, C, C}, CBox{OUT.x + OUT.w - C, OUT.y + OUT.h - C, C, C}})
        g_pHyprRenderer->damageBox(box);
}
