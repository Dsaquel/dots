#pragma once

#include <hyprland/src/desktop/view/window/Window.hpp>
#include <hyprland/src/desktop/view/window/WindowPresentation.hpp>
#include <hyprland/src/workspace/HLWorkspace.hpp>
#include <hyprland/src/helpers/math/Math.hpp>

#include <algorithm>
#include <array>
#include <cmath>

struct SRing {
    double cx, cy, hx, hy, ex, ey, r, rr, arc, per;

    SRing(const CBox& b, double radius) :
        cx(b.x + b.w / 2), cy(b.y + b.h / 2), hx(b.w / 2), hy(b.h / 2), ex(std::max(0.0, b.w / 2 - radius)), ey(std::max(0.0, b.h / 2 - radius)), r(radius),
        rr(radius + 3.5), arc(M_PI / 2 * rr), per(4 * (ex + ey) + 4 * arc) {}

    double u(const Vector2D& p) const {
        const double QX = p.x - cx, QY = p.y - cy, LX = 2 * ex, LY = 2 * ey;
        if (std::abs(QX) <= ex)
            return QY < 0 ? QX + ex : LX + 2 * arc + LY + (ex - QX);
        if (std::abs(QY) <= ey)
            return QX > 0 ? LX + arc + (QY + ey) : 2 * LX + 3 * arc + LY + (ey - QY);
        const double DX = std::abs(QX) - ex, DY = std::abs(QY) - ey;
        if (QX > 0 && QY < 0)
            return LX + std::atan2(DX, DY + 1e-5) * rr;
        if (QX > 0)
            return LX + arc + LY + std::atan2(DY, DX + 1e-5) * rr;
        if (QY > 0)
            return 2 * LX + 2 * arc + LY + std::atan2(DX, DY + 1e-5) * rr;
        return 2 * LX + 3 * arc + 2 * LY + std::atan2(DY, DX + 1e-5) * rr;
    }

    Vector2D at(double u, double out) const {
        const double LX = 2 * ex, LY = 2 * ey, R = r + out;
        double       t  = std::fmod(std::fmod(u, per) + per, per);
        const auto   TH = [this](double d) { return d / rr; };
        if (t < LX)
            return {cx - ex + t, cy - hy - out};
        if ((t -= LX) < arc)
            return {cx + ex + R * std::sin(TH(t)), cy - ey - R * std::cos(TH(t))};
        if ((t -= arc) < LY)
            return {cx + hx + out, cy - ey + t};
        if ((t -= LY) < arc)
            return {cx + ex + R * std::cos(TH(t)), cy + ey + R * std::sin(TH(t))};
        if ((t -= arc) < LX)
            return {cx + ex - t, cy + hy + out};
        if ((t -= LX) < arc)
            return {cx - ex - R * std::sin(TH(t)), cy + ey + R * std::cos(TH(t))};
        if ((t -= arc) < LY)
            return {cx - hx - out, cy + ey - t};
        t -= LY;
        return {cx - ex - R * std::cos(TH(t)), cy - ey - R * std::sin(TH(t))};
    }

    double circ(double a, double b) const {
        const double D = std::fmod(std::abs(a - b), std::max(1.0, per));
        return std::min(D, per - D);
    }

    std::array<double, 4> corners() const {
        return {per - arc / 2, 2 * ex + arc / 2, 2 * ex + arc + 2 * ey + arc / 2, 4 * ex + 2 * arc + 2 * ey + arc / 2};
    }

    double mid(int side) const {
        return std::array<double, 4>{ex, 2 * ex + arc + ey, 3 * ex + 2 * arc + 2 * ey, 4 * ex + 3 * arc + 3 * ey}[std::clamp(side, 0, 3)];
    }

    Vector2D normal(double u) const {
        const auto T = at(u + 0.5, 0) - at(u - 0.5, 0);
        const auto L = std::max(1e-6, std::hypot(T.x, T.y));
        return {T.y / L, -T.x / L};
    }

    double half(int side) const {
        return (side % 2 == 0 ? ex : ey) + arc / 2;
    }
};


using WORKSPACEID                           = int64_t;
inline constexpr WORKSPACEID WORKSPACE_INVALID = -1;

inline WORKSPACEID idOf(const PHLWORKSPACE& ws) {
    const auto N = ws ? ws->numberedID() : std::nullopt;
    return N ? WORKSPACEID(*N) : WORKSPACE_INVALID;
}

inline bool isSpecial(const PHLWORKSPACE& ws) {
    return ws->type() == Workspace::eWorkspaceType::SPECIAL;
}

inline bool isPinned(const PHLWINDOW& w) {
    return bool(w->m_state & Desktop::View::WINDOW_STATE_PINNED);
}

inline Vector2D shiftOf(const PHLWINDOW& w) {
    const auto WS = w->m_workspace;
    return (WS && !isPinned(w) ? WS->m_renderOffset->value() : Vector2D{}) + w->presentation().floatingOffset();
}

inline CBox boxOf(const PHLWINDOW& w) {
    return w->getWindowMainSurfaceBox().translate(shiftOf(w));
}

inline constexpr double CELL_W = 78, CELL_H = 112;

inline Vector2D latticeOf(const CBox& box, double cell = CELL_H) {
    return {std::clamp(std::round(box.w / (cell * CELL_W / CELL_H)), 2.0, 40.0), std::clamp(std::round(box.h / cell), 2.0, 30.0)};
}

inline Vector2D latticeOf(const CBox& from, const CBox& to) {
    if (from.w <= 0 || from.h <= 0 || to.w <= 0 || to.h <= 0)
        return latticeOf(to);
    const double RATIO = std::sqrt(from.w / from.h * to.w / to.h) * from.h / from.w, GX = std::sqrt(from.w * from.h / (CELL_W * CELL_H * RATIO));
    return {std::clamp(std::round(GX), 2.0, 40.0), std::clamp(std::round(GX * RATIO), 2.0, 30.0)};
}

inline Vector2D toward(const CBox& a, const CBox& b) {
    const auto   C = a.middle();
    const double X = std::clamp(C.x, b.x, b.x + b.w), Y = std::clamp(C.y, b.y, b.y + b.h);
    return {std::clamp(X, a.x, a.x + a.w), std::clamp(Y, a.y, a.y + a.h)};
}

inline int facing(const CBox& g, const CBox& n) {
    if (n.x >= g.x + g.w - 2)
        return 1;
    if (n.x + n.w <= g.x + 2)
        return 3;
    if (n.y >= g.y + g.h - 2)
        return 2;
    if (n.y + n.h <= g.y + 2)
        return 0;
    return -1;
}
