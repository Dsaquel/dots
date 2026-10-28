#include "translation/Internal.hpp"

namespace Translation {
    double unit(double k) {
        return std::clamp(k, 0.0, 1.0);
    }

    double span(double x, double a, double b) {
        return unit((x - a) / (b - a));
    }

    double soft(double k) {
        k = unit(k);
        return k * k * (3 - 2 * k);
    }

    double dot(const Vector2D& a, const Vector2D& b) {
        return a.x * b.x + a.y * b.y;
    }

    Vector2D unitOf(const Vector2D& v) {
        return v / std::max(v.size(), 1e-9);
    }

    Vector2D bez(const Vector2D& a, const Vector2D& b, const Vector2D& c, const Vector2D& d, double k) {
        const double L = 1 - k;
        return a * (L * L * L) + b * (3 * L * L * k) + c * (3 * L * k * k) + d * (k * k * k);
    }

    SDot blend(const SDot& a, const SDot& b, double k) {
        return {a.at + (b.at - a.at) * k, a.z + (b.z - a.z) * k};
    }

    Vector2D lensOf(const SPath& P) {
        return {P.lens[0], P.lens[1]};
    }

    SDot project(const SPath& P, const SDot& x, double cam) {
        const double D = std::max(x.z + P.lens[2] - cam, 1.0);
        return {lensOf(P) + (x.at - lensOf(P)) * (P.lens[2] / D), D};
    }

    Vector2D pose(const SPath& P, double tau) {
        const double   F = std::clamp((tau - P.times[0]) / P.stride, 0.0, double(POSES - 1));
        const int      I = int(F), J = std::min(I + 1, POSES - 1);
        const Vector2D A{P.poses[2 * I], P.poses[2 * I + 1]}, B{P.poses[2 * J], P.poses[2 * J + 1]};
        return A + (B - A) * (F - I);
    }

    SDot leafAt(const SPath& P, const Vector2D& q, double phi) {
        const bool   LEFT = q.x < P.view[2];
        const double A    = LEFT ? q.x : P.target.x - q.x;
        return {{LEFT ? A * std::cos(phi) : P.target.x - A * std::cos(phi), q.y}, A * std::sin(phi)};
    }

    SDot targetAt(const SPath& P, const Vector2D& q, double phi) {
        return P.forward > 0.5F ? SDot{q, P.lens[3]} : leafAt(P, q, phi);
    }

    Vector2D entryAt(const SPath& P, double tau) {
        const auto C = pose(P, tau);
        return project(P, targetAt(P, P.entry, C.y), C.x).at;
    }

    Vector2D origin(const SPath& P) {
        return {P.shot[0] + P.shot[2] * 0.5, P.shot[1] + P.shot[3] * 0.14};
    }

    Vector2D sighted(const SPath& P) {
        return P.forward > 0.5F ? lensOf(P) + (P.entry - lensOf(P)) * (P.lens[2] / (P.lens[3] + P.lens[2])) : P.entry;
    }

    Vector2D doorway(const SPath& P) {
        const auto A0 = origin(P), E0 = sighted(P);
        return {P.forward > 0.5F ? P.lens[0] : (A0.x + E0.x) / 2, std::clamp(std::min(E0.y - 0.3 * P.target.y, A0.y + 0.05 * P.target.y), 0.12 * P.target.y, 0.5 * P.target.y)};
    }

    double side(const SPath& P) {
        const auto   SIGN = [](double x) { return double((x > 0) - (x < 0)); };
        const double DX   = doorway(P).x - origin(P).x;
        return std::abs(DX) > 0.02 * P.target.x ? SIGN(DX) : SIGN(sighted(P).x - doorway(P).x + 1e-3);
    }

    Vector2D crest(const SPath& P) {
        const auto Q = doorway(P), A0 = origin(P);
        return {Q.x - side(P) * std::min(0.15 * P.target.x, 0.6 * std::abs(Q.x - A0.x)), std::max(0.04 * P.target.y, std::min(A0.y, Q.y) - 0.18 * P.target.y)};
    }

    Vector2D inward(const SPath& P) {
        const Vector2D A{P.seam[0], P.seam[1]}, D = Vector2D{P.seam[2], P.seam[3]} - A, N = unitOf({D.y, -D.x});
        return dot(P.entry - A, N) < 0 ? N * -1 : N;
    }

    Vector2D crossing(const SPath& P) {
        const Vector2D A{P.seam[0], P.seam[1]}, D = Vector2D{P.seam[2], P.seam[3]} - A, A0 = origin(P);
        const double   LEN = std::max(D.size(), 1.0);
        const Vector2D AIM{(A0.x + P.entry.x) / 2, std::clamp(std::min(P.entry.y - 0.3 * P.target.y, A0.y + 0.05 * P.target.y), 0.12 * P.target.y, 0.5 * P.target.y)};
        return A + D / LEN * std::clamp(dot(AIM - A, D / LEN), 0.1 * LEN, 0.9 * LEN);
    }

    Vector2D arc(const SPath& P, const Vector2D& Q) {
        const auto     A0 = origin(P), N = inward(P);
        const Vector2D C  = Q - N * std::min(0.15 * P.target.x, 0.6 * std::abs(dot(Q - A0, N)));
        return std::abs(N.x) > 0.5 ? Vector2D{C.x, std::max(0.04 * P.target.y, std::min(A0.y, Q.y) - 0.18 * P.target.y)} : C;
    }

    bool pinned(const SPath& P, const Vector2D& q) {
        return P.bridge > 0.5F || q.x < 0 || q.y < 0 || q.x > P.target.x || q.y > P.target.y;
    }

    SDot lifted(const SPath& P, const std::array<float, 3>& q) {
        const Vector2D Q{q[0], q[1]};
        return {lensOf(P) + (Q - lensOf(P)) / q[2], (pinned(P, Q) ? P.view[0] : pose(P, P.turn[0]).x) + P.lens[2] / q[2] - P.lens[2]};
    }

    SDot wakeAt(const SPath& P, double tau) {
        const double         F = unit((tau - P.turn[2]) / std::max(P.turn[0] - P.turn[2], 1.F)) * (WAKE - 1);
        const int            I = int(F), J = std::min(I + 1, WAKE - 1);
        std::array<float, 3> q = {};
        for (size_t k = 0; k < 3; ++k)
            q[k] = float(P.wake[I][k] + (P.wake[J][k] - P.wake[I][k]) * (F - I));
        return lifted(P, q);
    }

    SDot turnedAt(const SPath& P, double tau) {
        const auto&    h = P.wake.back();
        const Vector2D HD{h[0], h[1]}, C = pose(P, tau), E = entryAt(P, tau), L = lensOf(P);
        const SDot     H  = lifted(P, h);
        const Vector2D TO = E - HD;
        const double   K  = span(tau, P.turn[0], P.times[1]), PACE = P.heading.size();
        const double   KS = P.nave > 0.5F ? 1 - (1 - K) * (1 - K) : K * (0.6 + 0.4 * K);
        const double   BEND = PACE > 1e-3 && TO.size() > 1e-3 ? std::pow(0.5 + 0.5 * dot(P.heading, TO) / (PACE * TO.size()), 2) : 0;
        const Vector2D D1 = HD + P.heading * (BEND * std::min((P.times[1] - P.turn[0]) / 1.8, 0.35 * TO.size() / std::max(PACE, 1e-3)));
        const Vector2D S  = bez(HD, D1, E + (D1 - E) * 0.35, E, KS);
        const double   Z  = H.z + (targetAt(P, P.entry, C.y).z - H.z) * (1 - std::pow(1 - K, 3));
        const SDot     X{L + (S - L) * ((Z + P.lens[2] - C.x) / P.lens[2]), Z};
        return pinned(P, HD) ? blend({L + (S - L) / h[2], H.z}, X, K * K) : X;
    }

    SDot headAt(const SPath& P, double tau) {
        if (P.turn[3] > 0.5F)
            return turnedAt(P, tau);
        const bool     BRIDGE = P.bridge > 0.5F;
        const double   ZS     = BRIDGE ? P.view[0] : P.forward > 0.5F ? 0 : P.lens[3];
        const Vector2D A0 = origin(P), Q = BRIDGE ? crossing(P) : doorway(P), P2 = BRIDGE ? arc(P, Q) : crest(P), L = lensOf(P);
        const double   RISE = P.times[0] + RISEN;
        if (tau < RISE)
            return {bez(A0, {A0.x + (Q.x - A0.x) * 0.1, P2.y}, P2, Q, span(tau, BORN, RISE)), ZS};
        const auto     C  = pose(P, tau);
        const double   K  = span(tau, RISE, P.times[1]), SC = BRIDGE ? 1 : P.lens[2] / (ZS + P.lens[2] - pose(P, RISE).x);
        const double   KS = P.nave > 0.5F ? 1 - (1 - K) * (1 - K) : K * (0.6 + 0.4 * K);
        const Vector2D D0 = L + (Q - L) * SC, E = entryAt(P, tau);
        const Vector2D D1 = BRIDGE ? Q + unitOf(Q - P2) * std::min(0.5 * (Q - P2).size(), 0.25 * (E - Q).size()) : D0 + (Q - P2) * (0.5 * SC);
        const Vector2D S  = bez(D0, D1, E + ((BRIDGE ? Q : D1) - E) * 0.35, E, KS);
        const double   UP = BRIDGE ? pose(P, RISE).x : ZS, Z = UP + (targetAt(P, P.entry, C.y).z - UP) * (1 - std::pow(1 - K, 3));
        const SDot     X{L + (S - L) * ((Z + P.lens[2] - C.x) / P.lens[2]), Z};
        return BRIDGE ? blend({S, P.view[0]}, X, K * K) : X;
    }

    SDot spineAt(const SPath& P, double tau) {
        return P.turn[3] > 0.5F && tau < P.turn[0] ? wakeAt(P, tau) : headAt(P, std::min(tau, P.times[1] - 0.5));
    }

    double lagOf(const SPath& P, double tt) {
        const double GROW = P.turn[1] + (STRUNG - P.turn[1]) * soft(span(tt, P.turn[0], P.turn[0] + 160));
        return P.turn[3] > 0.5F ? GROW + (DRAIN - GROW) * soft(span(tt, P.times[1] - 160, P.times[1] - 40)) : LAG + (DRAIN - LAG) * soft(span(tt, P.times[0] + 60, P.times[1] - 60));
    }

    Vector2D cameOf(const SPyre& p) {
        const Vector2D AWAY = awayOf(p);
        return p.turned < SHUT ? Vector2D{p.wake.back()[0], p.wake.back()[1]} : p.shot.middle() + AWAY;
    }

    void track(SPyre& p) {
        const auto LAND = p.monitor.lock();
        p.lens          = Enfilade::lens(LAND);
        p.stride        = Enfilade::length(LAND);
        p.poses         = std::views::iota(0, POSES) | std::views::transform([&](int i) { return Enfilade::pose(LAND, p.forward, p.walks ? float(i) * p.stride / float(POSES - 1) : p.stride); }) |
            std::views::join | std::ranges::to<std::vector>();
    }

    SPath pathOf(const SPyre& p, float t) {
        const auto     LAND = p.monitor.lock(), SRC = p.from.lock();
        const auto     FRONT = p.ghost ? p.ghost->front(BURNED) : std::array<float, 5>{0.F, 1.F, 20.F, BURNED, 0.F};
        const auto     VIEW  = Enfilade::view(LAND);
        const float    REST  = (p.doors >= SHUT) != p.forward ? p.lens[3] : 0.F;
        const Vector2D AWAY  = awayOf(p);
        const auto     SEAM  = SRC == LAND ? std::nullopt : seamOf(SRC, LAND).transform([&LAND](const CBox& b) { return b.copy().translate(-LAND->m_position).scale(LAND->m_scale); });
        const bool     TURNED = p.turned < SHUT;
        return {
            .target   = LAND->m_pixelSize,
            .away     = AWAY,
            .entry    = p.entry,
            .came     = cameOf(p),
            .heading  = p.heading,
            .lens     = p.lens,
            .view     = {VIEW ? (*VIEW)[0] : REST, VIEW ? (*VIEW)[1] : 0.F, VIEW ? (*VIEW)[2] : 0.F, VIEW ? 1.F : 0.F},
            .times    = timesOf(p, t),
            .slot     = {float(p.slot.x), float(p.slot.y), float(p.slot.w), float(p.slot.h)},
            .seam     = {SEAM ? float(SEAM->x) : 0.F, SEAM ? float(SEAM->y) : 0.F, SEAM ? float(SEAM->x + SEAM->w) : 0.F, SEAM ? float(SEAM->y + SEAM->h) : 0.F},
            .shot     = {float(p.shot.x + AWAY.x), float(p.shot.y + AWAY.y), float(p.shot.w), float(p.shot.h)},
            .burn     = {FRONT[0] + float(AWAY.y), FRONT[1], FRONT[2], FRONT[3]},
            .turn     = {TURNED ? p.turned : 0.F, p.lagged, p.waked, TURNED ? 1.F : 0.F},
            .poses    = p.poses,
            .wake     = p.wake,
            .stride   = p.stride / float(POSES - 1),
            .forward  = p.forward ? 1.F : 0.F,
            .alone    = p.alone ? 1.F : 0.F,
            .bridge   = SRC != LAND || !p.walks ? 1.F : 0.F,
            .scale    = float(LAND->m_scale),
            .burnSeed = FRONT[4],
            .nave     = p.flies ? 1.F : 0.F,
        };
    }
}
