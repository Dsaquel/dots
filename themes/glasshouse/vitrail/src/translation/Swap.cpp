#include "translation/Internal.hpp"

namespace Translation {
    std::optional<SSwap> swapOf(const std::vector<PHLWINDOW>& moved, const std::vector<CBox>& was) {
        const auto WS = moved.empty() ? nullptr : moved[0]->m_workspace;
        if (moved.size() < 2 || std::ranges::any_of(moved, [&WS](const PHLWINDOW& w) { return w->isFloating() || w->m_workspace != WS; }))
            return std::nullopt;
        const auto NOW = moved | std::views::transform([](const PHLWINDOW& w) { return w->geometricBox(GEO::GEOMETRIC_GOAL); }) | std::ranges::to<std::vector>();
        const CBox U = hullOf(was), V = hullOf(NOW);
        if (std::abs(U.x - V.x) > 6 || std::abs(U.y - V.y) > 6 || std::abs(U.w - V.w) > 6 || std::abs(U.h - V.h) > 6 ||
            std::ranges::count_if(std::views::iota(size_t{0}, moved.size()), [&](size_t i) { return !was[i].containsPoint(NOW[i].middle()); }) < 2 ||
            std::ranges::any_of(Desktop::windowState()->windows(), [&](const PHLWINDOW& x) {
                return !std::ranges::contains(moved, x) && validMapped(x) && !x->isHidden() && !x->isFloating() && x->m_workspace == WS &&
                    x->geometricBox(GEO::GEOMETRIC_GOAL).overlaps(U.copy().expand(-6));
            }))
            return std::nullopt;
        SSwap out{.hull = U, .windows = moved};
        if (moved.size() == 2) {
            const auto A = splitOf(was[0], was[1], U), B = splitOf(NOW[0], NOW[1], U);
            if (!A || !B || A->axis != B->axis || A->first == B->first)
                return std::nullopt;
            out.gates  = {B->axis == 0 ? std::array{float(B->at), float(U.y), float(B->at), float(U.y + U.h)} : std::array{float(U.x), float(B->at), float(U.x + U.w), float(B->at)}};
            out.glide  = B->axis == 0 ? Vector2D{A->at - B->at, 0.0} : Vector2D{0.0, A->at - B->at};
            out.gutter = A->gap;
            return out;
        }
        const auto LO = [](const CBox& x, int axis) { return axis ? x.y : x.x; };
        const auto HI = [](const CBox& x, int axis) { return axis ? x.y + x.h : x.x + x.w; };
        for (int axis = 0; axis < 2; ++axis)
            for (const auto& A : NOW)
                for (const auto& B : NOW) {
                    const double GAP = LO(B, axis) - HI(A, axis), X0 = std::max(LO(A, 1 - axis), LO(B, 1 - axis)) - GAP / 2, X1 = std::min(HI(A, 1 - axis), HI(B, 1 - axis)) + GAP / 2;
                    const double AT  = (HI(A, axis) + LO(B, axis)) / 2;
                    if (GAP < -6 || GAP > 120 || X1 - X0 < 24)
                        continue;
                    out.gutter    = GAP;
                    const auto ON = std::ranges::find_if(out.gates, [&](const std::array<float, 4>& g) {
                        return std::abs((axis ? g[1] : g[0]) - AT) < 6 && (axis ? g[1] == g[3] : g[0] == g[2]) && (axis ? g[0] : g[1]) <= X1 + 1 && (axis ? g[2] : g[3]) >= X0 - 1;
                    });
                    if (ON != out.gates.end()) {
                        (*ON)[axis ? 0 : 1] = std::min((*ON)[axis ? 0 : 1], float(X0));
                        (*ON)[axis ? 2 : 3] = std::max((*ON)[axis ? 2 : 3], float(X1));
                    } else if (out.gates.size() < GATES)
                        out.gates.push_back(axis ? std::array{float(X0), float(AT), float(X1), float(AT)} : std::array{float(AT), float(X0), float(AT), float(X1)});
                }
        return out.gates.empty() ? std::nullopt : std::optional{out};
    }

    int crossingOf(const SCarry& c, const Vector2D& s, const Vector2D& d) {
        int    best  = -1;
        double first = 2;
        for (size_t i = 0; i < c.gates.size(); ++i) {
            const auto&    G = c.gates[i];
            const Vector2D A{G[0], G[1]}, E = Vector2D{G[2], G[3]} - A, R = d - s, W = A - s;
            const double   DEN = R.x * E.y - R.y * E.x;
            if (std::abs(DEN) < 1e-9)
                continue;
            const double U = (W.x * E.y - W.y * E.x) / DEN, V = (W.x * R.y - W.y * R.x) / DEN;
            if (U >= 0 && U <= 1 && V >= 0 && V <= 1 && U < first) {
                first = U;
                best  = int(i);
            }
        }
        return best;
    }

    float uOf(const std::array<float, 4>& q, float t) {
        const float K = std::clamp((t - q[1]) / (SLAM - q[1]), 0.F, 1.F);
        return q[3] + (1 - q[3]) * K * K;
    }

    void planSwap(SCarry& c, const std::vector<float>& cut) {
        const int      GX  = int(c.lattice.x), GY = int(c.lattice.y), NU = GX + GY;
        const auto     MID = [GX, GY](int iu, int iv) { return Vector2D{(iu + iv + 1) / (2.0 * GX), (iu - iv) / (2.0 * GY)}; };
        const auto     WAY = c.goal.middle() - c.source.middle();
        const Vector2D T   = WAY.size() > 1 ? unitOf(WAY) : Vector2D{1, 0}, N{-T.y, T.x};
        const std::array CORNERS = {c.source.pos(), c.source.pos() + Vector2D{c.source.w, 0.0}, c.source.pos() + Vector2D{0.0, c.source.h}, c.source.pos() + c.source.size()};
        const auto [T0, T1] = std::ranges::minmax(CORNERS | std::views::transform([&T](const Vector2D& v) { return dot(v, T); }));
        const auto [N0, N1] = std::ranges::minmax(CORNERS | std::views::transform([&N](const Vector2D& v) { return dot(v, N); }));
        std::vector<std::array<float, 4>> texels(size_t(NU * NU), {-1.F, 0.F, 0.F, 0.F});
        c.first = SLAM;
        c.last  = SLAM;
        for (int i = 0; i < NU * NU; ++i) {
            const auto M = MID(i % NU, i / NU - GY);
            if (M.x < 0 || M.x > 1 || M.y < 0 || M.y > 1)
                continue;
            const Vector2D S = c.source.pos() + Vector2D{M.x * c.source.w, M.y * c.source.h}, D = c.goal.pos() + Vector2D{M.x * c.goal.w, M.y * c.goal.h};
            const double   DEPTH = (T1 - dot(S, T)) / std::max(T1 - T0, 1.0), ALONG = 2 * (dot(S, N) - N0) / std::max(N1 - N0, 1.0) - 1;
            texels[size_t(i)] = {float(1 + (c.gates.size() == 1 ? 0 : crossingOf(c, S, D))), cut.empty() ? float(SWING + FAN * DEPTH + BOW * ALONG * ALONG) : c.ahead,
                                 cut.empty() ? float(FLUSH * DEPTH) : 0.F, cut.empty() ? 0.F : 1 - cut[size_t(i)]};
            c.last            = std::max(c.last, SLAM + ringAge(c, nearest(c.gates, D)));
        }
        c.cells = texels;
        upload(c, NU, texels);
    }

    void swapSet(const SSwap& swap, const PHLMONITOR& monitor, const PHLWINDOW& focus) {
        const auto  LEAD = std::ranges::contains(swap.windows, focus) ? focus : swap.windows[0];
        const auto  NEAR = [](const CBox& a, const CBox& b) { return std::abs(a.x - b.x) < 6 && std::abs(a.y - b.y) < 6 && std::abs(a.w - b.w) < 6 && std::abs(a.h - b.h) < 6; };
        double      mw = 0, mh = 0;
        for (const auto& w : swap.windows) {
            mw += boxOf(w).w / double(swap.windows.size());
            mh += boxOf(w).h / double(swap.windows.size());
        }
        const Vector2D             LATTICE = latticeOf(CBox{0, 0, mw, mh});
        std::vector<const SCarry*> olds;
        for (const auto& w : swap.windows) {
            const auto IT = flightOf(w);
            olds.push_back(IT != flights.end() && (*IT)->kind == eKind::SWAP && ms(**IT) < SLAM && (*IT)->lattice == LATTICE && NEAR((*IT)->source, w->geometricBox(GEO::GEOMETRIC_GOAL)) ?
                               IT->get() :
                               nullptr);
        }
        const bool                      REWIND = std::ranges::none_of(olds, [](const SCarry* o) { return o == nullptr; });
        std::vector<std::vector<float>> cuts(swap.windows.size());
        float                           reach = 0;
        for (size_t i = 0; REWIND && i < olds.size(); ++i) {
            cuts[i] = olds[i]->cells | std::views::transform([&](const std::array<float, 4>& q) { return q[0] < 0 ? 0.F : uOf(q, ms(*olds[i])); }) | std::ranges::to<std::vector>();
            reach   = std::max(reach, std::ranges::max(cuts[i]));
        }
        const float AHEAD = REWIND ? SLAM - std::clamp((SLAM - SWING) * reach, REVERSED, SLAM - SWING) : -BREAK;
        Vector2D    glide = swap.glide;
        if (REWIND && !olds[0]->gates.empty()) {
            const float START = std::max(SWING, olds[0]->ahead), K = std::clamp((ms(*olds[0]) - START) / (SLAM - START), 0.F, 1.F);
            glide = Vector2D{olds[0]->gates[0][0] - swap.gates[0][0], olds[0]->gates[0][1] - swap.gates[0][1]} + olds[0]->glide * (1 - easeOf(K));
        }
        double far = 0;
        for (const auto& corner : {swap.hull.pos(), swap.hull.pos() + Vector2D{swap.hull.w, 0.0}, swap.hull.pos() + Vector2D{0.0, swap.hull.h}, swap.hull.pos() + swap.hull.size()})
            far = std::max(far, nearest(swap.gates, corner));
        std::vector<SCarry*> started;
        int                  rank = 1;
        for (size_t i = 0; i < swap.windows.size(); ++i) {
            const auto& w = swap.windows[i];
            unturn(w);
            Mullion::drop(w);
            if (auto* const F = CGlassFrame::of(w); F && F->role() != CGlassFrame::ROLE_NONE)
                F->lend(CGlassFrame::ROLE_NONE, nullptr, -1);
            for (auto* const v : {&w->positionAnimation(), &w->sizeAnimation()})
                if ((*v)->isBeingAnimated())
                    (*v)->setValue((*v)->begun());
            auto* const F      = CGlassFrame::of(w);
            const auto  ORNATE = F ? F->build(monitor, 1.F) : std::nullopt;
            const auto  SNAP   = shoot(w, eShot::BARE);
            if (!SNAP)
                continue;
            auto* const c = launch(w, monitor, SNAP, eKind::SWAP);
            w->positionAnimation()->warp();
            w->sizeAnimation()->warp();
            c->ornate  = ORNATE;
            c->goal    = w->geometricBox(GEO::GEOMETRIC_GOAL);
            c->opened  = 0;
            c->base    = 0;
            c->framed  = true;
            c->pair    = swap.hull.copy().expand(RIM);
            c->gates   = swap.gates;
            c->glide   = glide;
            c->far     = float(far + ROOM);
            c->gutter  = float(swap.gutter);
            c->lead    = w == LEAD;
            c->rank    = w == LEAD ? 0 : rank++;
            c->ahead   = AHEAD;
            c->lattice = LATTICE;
            c->fresh   = std::abs(c->goal.w - c->source.w) > 2 || std::abs(c->goal.h - c->source.h) > 2 ? AHEAD + FRESH : 0.F;
            for (const auto& pc : ORNATE && !REWIND ? ORNATE->pieces : std::vector<SPiece>{}) {
                const double R = pc.kind == SPiece::FLOWER ? 30 : 22;
                if (pc.kind != SPiece::PEARL && c->gilt.size() < GILTS)
                    c->gilt.push_back({float(pc.origin.x + monitor->m_position.x - R), float(pc.origin.y + monitor->m_position.y - R), float(2 * R), float(2 * R)});
            }
            if (ORNATE && !REWIND && ORNATE->plate.on && c->gilt.size() < GILTS)
                c->gilt.push_back({float(ORNATE->plate.pos.x + monitor->m_position.x), float(ORNATE->plate.pos.y + monitor->m_position.y - 11), float(std::min(ORNATE->plate.maxWidth, 220.0)), 22.F});
            planSwap(*c, REWIND ? cuts[i] : std::vector<float>{});
            started.push_back(c);
        }
        for (auto* const c : started) {
            c->clock->setValueAndWarp(0.F);
            *c->clock = 1.F;
        }
        announce(std::format("swap,{},{}sluice@{:.0f},slam@{:.0f},strike@{:.0f}@0.4", addressOf(LEAD), REWIND ? "" : "shatter@0@0.5,", std::max(SWING - AHEAD, 0.F), SLAM - AHEAD, SLAM + ZAPPED - AHEAD));
    }
}
