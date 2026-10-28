#include "translation/Internal.hpp"

namespace Translation {
    enum class eShift : uint8_t {
        GROW,
        SHRINK,
        SLIDE,
        MOVE,
    };

    bool within(const CBox& a, const CBox& b) {
        return a.x >= b.x - 6 && a.y >= b.y - 6 && a.x + a.w <= b.x + b.w + 6 && a.y + a.h <= b.y + b.h + 6;
    }

    eShift shiftOf(const CBox& was, const CBox& now) {
        if (within(was, now))
            return eShift::GROW;
        if (within(now, was))
            return eShift::SHRINK;
        return std::abs(now.w - was.w) <= 6 && std::abs(now.h - was.h) <= 6 ? eShift::SLIDE : eShift::MOVE;
    }

    int axisOf(const CBox& was, const CBox& now) {
        const bool W = std::abs(now.w - was.w) > 6, H = std::abs(now.h - was.h) > 6;
        return W == H ? -1 : W ? 0 : 1;
    }

    std::optional<SRelay> relayOf(const std::vector<PHLWINDOW>& moved, const std::vector<CBox>& was) {
        const auto WS = moved.empty() ? nullptr : moved[0]->m_workspace;
        if (moved.size() < 2 || std::ranges::any_of(moved, [&WS](const PHLWINDOW& w) { return w->isFloating() || w->m_workspace != WS; }))
            return std::nullopt;
        const auto NOW = moved | std::views::transform([](const PHLWINDOW& w) { return w->geometricBox(GEO::GEOMETRIC_GOAL); }) | std::ranges::to<std::vector>();
        const CBox U = hullOf(was), V = hullOf(NOW);
        if (std::abs(U.x - V.x) > 6 || std::abs(U.y - V.y) > 6 || std::abs(U.w - V.w) > 6 || std::abs(U.h - V.h) > 6)
            return std::nullopt;
        const auto ALL     = std::views::iota(size_t{0}, moved.size());
        const auto SHIFT   = ALL | std::views::transform([&](size_t i) { return shiftOf(was[i], NOW[i]); }) | std::ranges::to<std::vector>();
        const auto OF      = [&](auto&& keep) { return ALL | std::views::filter([&](size_t i) { return keep(SHIFT[i]); }) | std::ranges::to<std::vector>(); };
        const auto SHRINKS = OF([](eShift s) { return s == eShift::SHRINK; });
        const auto AWAY    = OF([](eShift s) { return s == eShift::MOVE || s == eShift::SLIDE; });
        const bool KEEPS   = AWAY.empty();
        const auto TAKEN   = [&](size_t i, size_t m) {
            const CBox X = NOW[i].intersection(was[m]);
            return X.empty() ? 0.0 : X.w * X.h;
        };
        const auto GROWS = [&](size_t m) {
            return ALL | std::views::filter([&](size_t i) {
                       return SHIFT[i] == eShift::GROW && TAKEN(i, m) > 0.1 * was[m].w * was[m].h && (!KEEPS || axisOf(was[i], NOW[i]) != axisOf(was[m], NOW[m]));
                   }) |
                std::ranges::to<std::vector>();
        };
        const auto LEFT = (KEEPS ? SHRINKS : AWAY) | std::views::filter([&](size_t m) { return !GROWS(m).empty() && (!KEEPS || axisOf(was[m], NOW[m]) >= 0); }) |
            std::ranges::to<std::vector>();
        if (LEFT.size() != 1 || (KEEPS && SHRINKS.size() != 1) || std::ranges::any_of(AWAY, [&](size_t i) { return i != LEFT[0] && SHIFT[i] != eShift::SLIDE; }))
            return std::nullopt;
        const size_t M    = LEFT[0];
        const size_t R    = std::ranges::max(GROWS(M), {}, [&](size_t i) { return TAKEN(i, M); });
        const auto   GIVE = KEEPS ? SHRINKS.end() : std::ranges::find_if(SHRINKS, [&](size_t i) { return within(NOW[M], was[i]); });
        SRelay       out{.mover    = moved[M],
                         .receiver = moved[R],
                         .giver    = GIVE == SHRINKS.end() ? nullptr : moved[*GIVE],
                         .from     = was[M],
                         .room     = GIVE == SHRINKS.end() ? CBox{} : was[*GIVE],
                         .arrives  = !KEEPS};
        for (const auto& w : moved)
            if (w != out.mover && w != out.receiver && w != out.giver)
                out.rest.push_back(w);
        return out;
    }

    std::optional<std::pair<std::array<float, 4>, double>> gateOf(const CBox& o, const CBox& n) {
        const auto LO = [](const CBox& x, int axis) { return axis ? x.y : x.x; };
        const auto HI = [](const CBox& x, int axis) { return axis ? x.y + x.h : x.x + x.w; };
        for (int axis = 0; axis < 2; ++axis) {
            const bool FORE = HI(o, axis) <= LO(n, axis) + 6;
            if (!FORE && HI(n, axis) > LO(o, axis) + 6)
                continue;
            const CBox&  A  = FORE ? o : n;
            const CBox&  B  = FORE ? n : o;
            const double AT = (HI(A, axis) + LO(B, axis)) / 2, X0 = std::max(LO(o, 1 - axis), LO(n, 1 - axis)), X1 = std::min(HI(o, 1 - axis), HI(n, 1 - axis));
            if (X1 - X0 >= 24)
                return std::pair{axis ? std::array{float(X0), float(AT), float(X1), float(AT)} : std::array{float(AT), float(X0), float(AT), float(X1)}, LO(B, axis) - HI(A, axis)};
        }
        return std::nullopt;
    }

    SCarry* ferry(const SRelay& r, const PHLMONITOR& monitor, const std::pair<std::array<float, 4>, double>& gate, float ahead, const std::vector<float>& cut, const Vector2D& lattice) {
        const auto SNAP = shoot(r.mover, eShot::BARE);
        if (!SNAP)
            return nullptr;
        auto* const c = launch(r.mover, monitor, SNAP, eKind::SWAP, r.from);
        c->opened     = 0;
        c->base       = 0;
        c->framed     = true;
        c->pair       = c->goal.copy().expand(RIM);
        c->gates      = {gate.first};
        c->gutter     = float(gate.second);
        c->lead       = true;
        c->bed        = false;
        c->ahead      = ahead;
        c->lattice    = lattice;
        c->fresh      = std::abs(c->goal.w - c->source.w) > 2 || std::abs(c->goal.h - c->source.h) > 2 ? c->ahead + FRESH : 0.F;
        double far    = 0;
        for (const auto& corner : {c->goal.pos(), c->goal.pos() + Vector2D{c->goal.w, 0.0}, c->goal.pos() + Vector2D{0.0, c->goal.h}, c->goal.pos() + c->goal.size()})
            far = std::max(far, nearest(c->gates, corner));
        c->far = float(far + ROOM);
        planSwap(*c, cut);
        return c;
    }

    void relay(const SRelay& r, const PHLMONITOR& monitor, const PHLWINDOW& focus) {
        const CBox     GOAL    = r.mover->geometricBox(GEO::GEOMETRIC_GOAL);
        const Vector2D LATTICE = latticeOf(CBox{0, 0, (r.from.w + GOAL.w) / 2, (r.from.h + GOAL.h) / 2});
        const auto     WAS     = flightOf(r.mover);
        const SCarry*  OLD     = WAS != flights.end() && (*WAS)->kind == eKind::SWAP && !(*WAS)->bed && ms(**WAS) < SLAM && (*WAS)->lattice == LATTICE && within((*WAS)->source, GOAL) &&
                within(GOAL, (*WAS)->source) ?
             WAS->get() :
             nullptr;
        const auto  CUT   = OLD ? OLD->cells | std::views::transform([OLD](const std::array<float, 4>& q) { return q[0] < 0 ? 0.F : uOf(q, ms(*OLD)); }) | std::ranges::to<std::vector>() :
                                std::vector<float>{};
        const float AHEAD = OLD ? SLAM - std::clamp((SLAM - SWING) * std::ranges::max(CUT), REVERSED, SLAM - SWING) : -BREAK - WAIT;
        const bool  BACK  = OLD != nullptr;
        auto        all   = std::vector{r.mover};
        for (const auto& w : {r.receiver, r.giver})
            if (w)
                all.push_back(w);
        all.insert(all.end(), r.rest.begin(), r.rest.end());
        for (const auto& w : all) {
            unturn(w);
            Mullion::drop(w, w != r.mover);
            if (auto* const F = CGlassFrame::of(w); F && F->role() != CGlassFrame::ROLE_NONE)
                F->lend(CGlassFrame::ROLE_NONE, nullptr, -1);
        }
        for (const auto& [w, BOX] : {std::pair{r.mover, r.from}, std::pair{r.giver, r.room}})
            if (w) {
                w->positionAnimation()->setValue(BOX.pos());
                w->sizeAnimation()->setValue(BOX.size());
            }
        const auto GATE = r.arrives ? gateOf(r.from, GOAL) : std::nullopt;
        if (BACK && GATE)
            std::ranges::for_each(std::array{r.receiver, r.giver}, [AHEAD](const PHLWINDOW& w) { Life::follow(w, SLAM - AHEAD); });
        else
            Life::leave(r.mover, r.receiver, GATE ? SLAM - AHEAD : GIVEN, GATE.has_value());
        auto* const c = GATE ? ferry(r, monitor, *GATE, AHEAD, CUT, LATTICE) : nullptr;
        r.mover->positionAnimation()->warp();
        r.mover->sizeAnimation()->warp();
        if (c)
            c->seats = !r.giver || BACK || !Mullion::open(r.mover, r.giver, facing(r.giver->geometricBox(GEO::GEOMETRIC_GOAL), GOAL), RELAYED);
        else if (r.arrives) {
            Life::open(r.mover, r.giver);
            Life::late(r.mover);
            if (auto* const F = CGlassFrame::of(r.mover); F && F->role() == CGlassFrame::ROLE_BORN && r.mover == focus)
                CGlassFrame::handoff(nullptr, r.mover, std::nullopt);
        }
        std::ranges::for_each(r.rest, [c, AHEAD](const PHLWINDOW& w) { Life::follow(w, c ? SLAM - AHEAD : LIFE); });
        const auto* const F = CGlassFrame::of(r.mover);
        if (c)
            announce(std::format("relay,{},{}sluice@{:.0f},slam@{:.0f},strike@{:.0f}@0.4", addressOf(r.mover), BACK ? "" : "give@0,shatter@0@0.5,", std::max(SWING - AHEAD, 0.F), SLAM - AHEAD,
                                 SLAM + ZAPPED - AHEAD));
        else
            announce(std::format("relay,{},give@0{}", addressOf(r.mover), !F || F->role() != CGlassFrame::ROLE_BORN ? "" : r.giver ? ",share@0" : ",athanor@0"));
    }
}
