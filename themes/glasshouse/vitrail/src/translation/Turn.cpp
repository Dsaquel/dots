#include "translation/Internal.hpp"

namespace Translation {
    bool shifted(const CBox& was, const CBox& now) {
        const auto D = now.middle() - was.middle();
        return std::hypot(D.x, D.y) > MOVED || std::abs(now.w - was.w) > RESIZED * was.w || std::abs(now.h - was.h) > RESIZED * was.h;
    }

    bool settledOn(const PHLWORKSPACE& ws) {
        return ws && ws->visible() && !isSpecial(ws) && !Fullscreen::controller()->hasFullscreen(ws) && ws->m_alpha->value() >= 0.999F &&
            !ws->m_alpha->isBeingAnimated() && !ws->m_renderOffset->isBeingAnimated();
    }

    bool turning(const PHLWINDOW& w) {
        const auto IT = flightOf(w);
        return IT != flights.end() && ((*IT)->kind == eKind::PIVOT || (*IT)->kind == eKind::SWAP);
    }

    bool turnable(const PHLWINDOW& w) {
        const auto IT = flightOf(w);
        return CGlassFrame::of(w) && !w->isHidden() && !isPinned(w) && !Fullscreen::controller()->isFullscreen(w) && settledOn(w->m_workspace) &&
            (w->positionAnimation()->isBeingAnimated() || w->sizeAnimation()->isBeingAnimated()) && (IT == flights.end() || (*IT)->kind != eKind::TRANSLATE) &&
            std::ranges::none_of(pyres, [&w](const UP<SPyre>& p) {
                return p->seated >= SHUT && (p->source.lock() == w->m_workspace || p->target.lock() == w->m_workspace || p->aim.lock() == w->m_workspace);
            });
    }

    bool pourable(const PHLWINDOW& w) {
        return turnable(w) && CGlassFrame::of(w)->role() == CGlassFrame::ROLE_NONE && (flightOf(w) == flights.end() || turning(w)) && !Mullion::holds(w) &&
            std::ranges::none_of(g_glass->retimed, [&w](const SRetimed& r) { return r.window.lock() == w; });
    }

    CBox hullOf(const std::vector<CBox>& boxes) {
        double x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9;
        for (const auto& b : boxes) {
            x0 = std::min(x0, b.x);
            y0 = std::min(y0, b.y);
            x1 = std::max(x1, b.x + b.w);
            y1 = std::max(y1, b.y + b.h);
        }
        return {x0, y0, x1 - x0, y1 - y0};
    }

    std::optional<SSplit> splitOf(const CBox& a, const CBox& b, const CBox& u) {
        const auto NEAR  = [](double x, double y) { return std::abs(x - y) < 6; };
        const auto LO    = [](const CBox& x, int axis) { return axis ? x.y : x.x; };
        const auto HI    = [](const CBox& x, int axis) { return axis ? x.y + x.h : x.x + x.w; };
        for (int axis = 0; axis < 2; ++axis) {
            const int ACROSS = 1 - axis;
            if (!NEAR(LO(a, ACROSS), LO(u, ACROSS)) || !NEAR(HI(a, ACROSS), HI(u, ACROSS)) || !NEAR(LO(b, ACROSS), LO(u, ACROSS)) || !NEAR(HI(b, ACROSS), HI(u, ACROSS)))
                continue;
            if (HI(a, axis) <= LO(b, axis) + 6 && LO(b, axis) - HI(a, axis) < 120)
                return SSplit{.axis = axis, .at = (HI(a, axis) + LO(b, axis)) / 2, .gap = LO(b, axis) - HI(a, axis), .first = true};
            if (HI(b, axis) <= LO(a, axis) + 6 && LO(a, axis) - HI(b, axis) < 120)
                return SSplit{.axis = axis, .at = (HI(b, axis) + LO(a, axis)) / 2, .gap = LO(a, axis) - HI(b, axis), .first = false};
        }
        return std::nullopt;
    }

    std::optional<STurn> pairOf(const std::vector<PHLWINDOW>& moved, const std::vector<CBox>& was) {
        if (moved.size() != 2 || moved[0]->isFloating() || moved[1]->isFloating() || moved[0]->m_workspace != moved[1]->m_workspace)
            return std::nullopt;
        const std::vector<CBox> NOW = {moved[0]->geometricBox(GEO::GEOMETRIC_GOAL), moved[1]->geometricBox(GEO::GEOMETRIC_GOAL)};
        const CBox              U = hullOf(was), V = hullOf(NOW);
        if (std::abs(U.x - V.x) > 6 || std::abs(U.y - V.y) > 6 || std::abs(U.w - V.w) > 6 || std::abs(U.h - V.h) > 6)
            return std::nullopt;
        const auto AXIS = [](int axis, bool low) { return (axis ? Vector2D{0, 1} : Vector2D{1, 0}) * (low ? -1.0 : 1.0); };
        const auto A = splitOf(was[0], was[1], U), B = splitOf(NOW[0], NOW[1], U);
        if (!A || !B || A->axis == B->axis)
            return std::nullopt;
        return STurn{.pair   = U,
                     .pivot  = A->axis == 0 ? Vector2D{A->at, B->at} : Vector2D{B->at, A->at},
                     .gutter = A->gap,
                     .sides  = {moved[0], moved[1]},
                     .olds   = {AXIS(A->axis, A->first), AXIS(A->axis, !A->first)},
                     .news   = {AXIS(B->axis, B->first), AXIS(B->axis, !B->first)}};
    }

    void unturn(const PHLWINDOW& w) {
        std::erase_if(flights, [&w](const UP<SCarry>& c) {
            if (c->kind == eKind::TRANSLATE || c->window.lock() != w)
                return false;
            unveil(*c);
            return true;
        });
    }

    void turnPair(const STurn& turn, const PHLMONITOR& monitor, const PHLWINDOW& focus) {
        const auto    LEAD   = std::ranges::contains(turn.sides, focus) ? focus : turn.sides[0];
        const auto    SENSE  = [&turn](size_t s) { return -turn.news[s].x * turn.olds[s].y + turn.news[s].y * turn.olds[s].x > 0 ? 1.F : -1.F; };
        const auto    WAS    = flightOf(turn.sides[0]);
        const SCarry* OLD    = WAS != flights.end() && (*WAS)->kind == eKind::PIVOT && (*WAS)->sense == -SENSE(0) && (*WAS)->pivot.distance(turn.pivot) < 2 && ms(**WAS) < SLAM ? WAS->get() : nullptr;
        const float   CUT    = OLD ? ms(*OLD) : 0.F;
        const float   AHEAD  = OLD ? std::min(SWING + (SLAM - SWING) * std::sqrt(std::clamp(1 - angleOf(*OLD, 0, CUT) / float(M_PI_2), 0.F, 1.F)), SLAM - REWOUND) : -BREAK;
        std::array<float, SKEWS> skew = {};
        for (size_t i = 0; OLD && i < skew.size(); ++i) {
            const float R = float(i) / (SKEWS - 1), P = progressOf(R, AHEAD);
            skew[i]       = float(M_PI_2) * (1 - P * P) - angleOf(*OLD, R, CUT);
        }
        const auto           MID = turn.pair.middle();
        std::vector<SCarry*> started;
        double               far = 0;
        for (const auto& corner : {turn.pair.pos(), turn.pair.pos() + Vector2D{turn.pair.w, 0.0}, turn.pair.pos() + Vector2D{0.0, turn.pair.h}, turn.pair.pos() + turn.pair.size()})
            far = std::max(far, corner.distance(turn.pivot));
        for (size_t s = 0; s < 2; ++s) {
            const auto&    w = turn.sides[s];
            const Vector2D O = turn.olds[s], N = turn.news[s];
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
            auto* const c = launch(w, monitor, SNAP, eKind::PIVOT);
            w->positionAnimation()->warp();
            w->sizeAnimation()->warp();
            c->ornate = ORNATE;
            c->goal   = w->geometricBox(GEO::GEOMETRIC_GOAL);
            c->opened = 0;
            c->base   = 0;
            c->framed = true;
            c->pair   = turn.pair.copy().expand(RIM);
            c->pivot  = turn.pivot;
            c->hubs   = O.x != 0 ? std::array{Vector2D{turn.pivot.x, MID.y}, Vector2D{MID.x, turn.pivot.y}} : std::array{Vector2D{MID.x, turn.pivot.y}, Vector2D{turn.pivot.x, MID.y}};
            c->oldDir = O;
            c->sweep  = float(std::atan2(-N.y, -N.x));
            c->sense  = SENSE(s);
            c->far    = float(far + ROOM);
            c->gutter = float(turn.gutter);
            c->lead   = w == LEAD;
            c->ahead  = AHEAD;
            c->skew   = skew;
            c->grid   = latticeOf(c->source, c->goal);
            for (const auto& pc : ORNATE && !OLD ? ORNATE->pieces : std::vector<SPiece>{}) {
                const double R = pc.kind == SPiece::FLOWER ? 30 : 22;
                if (pc.kind != SPiece::PEARL && c->gilt.size() < GILTS)
                    c->gilt.push_back({float(pc.origin.x + monitor->m_position.x - R), float(pc.origin.y + monitor->m_position.y - R), float(2 * R), float(2 * R)});
            }
            if (ORNATE && !OLD && ORNATE->plate.on && c->gilt.size() < GILTS)
                c->gilt.push_back({float(ORNATE->plate.pos.x + monitor->m_position.x), float(ORNATE->plate.pos.y + monitor->m_position.y - 11), float(std::min(ORNATE->plate.maxWidth, 220.0)), 22.F});
            planTurn(*c);
            started.push_back(c);
        }
        for (auto* const c : started) {
            c->clock->setValueAndWarp(0.F);
            *c->clock = 1.F;
        }
        announce(std::format("pivot,{},{}scrape@{:.0f},slam@{:.0f},strike@{:.0f}@0.4", addressOf(LEAD), OLD ? "" : "shatter@0@0.5,", std::max(SWING - AHEAD, 0.F), SLAM - AHEAD, SLAM + ZAPPED - AHEAD));
    }
}
