#include "mullion/Internal.hpp"

namespace Mullion {
    float noise(float x, float y) {
        const float V = std::sin(x * 12.9898F + y * 78.233F) * 43758.5453F;
        return V - std::floor(V);
    }

    double edgeOf(const CBox& box, int side) {
        return side == 0 ? box.y : side == 1 ? box.x + box.w : side == 2 ? box.y + box.h : box.x;
    }

    float ms(const SScene& s) {
        const float R = s.clock ? s.clock->value() * s.real : s.real;
        return s.from + R * s.rate < s.boom ? s.from + R * s.rate : s.boom + R - (s.boom - s.from) / s.rate;
    }

    bool claimed(const SScene& s, const PHLWINDOW& w) {
        const auto IT = std::ranges::find_if(scenes, [&s](const UP<SScene>& o) { return o.get() == &s; });
        return w && IT != scenes.end() && std::any_of(IT + 1, scenes.end(), [&w](const UP<SScene>& o) { return !o->released && (o->born.lock() == w || o->giver.lock() == w); });
    }

    double layAt(const SScene& s, float t) {
        const double F = s.reach * (1 - std::pow(1 - span(t, EXPAND0, EXPAND1), 2.0));
        return std::clamp(s.gutter + F - LAG, 0.0, s.straight) + (s.lost - s.straight) * inOutCubic(span(t, EXPAND1 - 20, EXPAND1 + CLOSE));
    }

    std::pair<double, double> cutAt(const SScene& s, float t) {
        if (s.melt) {
            const double HI = t < EXPAND0 ? s.lost * inOutCubic(span(t, CRACK0 + 30, CRACK1)) : s.lost - layAt(s, t);
            return {0.0, HI > 0.5 ? HI : -1.0};
        }
        double lo = s.lost + 1, hi = -1;
        for (const auto& b : s.bricks) {
            if (t >= b.pop)
                lo = std::min(lo, b.d0);
            if (t < b.back)
                hi = std::max(hi, b.d1);
        }
        return {lo, hi};
    }

    double nearest(const Vector2D& c, const CBox& box) {
        return c.distance(Vector2D{std::clamp(c.x, box.x, box.x + box.w), std::clamp(c.y, box.y, box.y + box.h)});
    }

    double farthest(const Vector2D& c, const CBox& box) {
        return std::ranges::max(std::array{c.distance(box.pos()), c.distance(box.pos() + Vector2D{box.w, 0.0}), c.distance(box.pos() + Vector2D{0.0, box.h}), c.distance(box.pos() + box.size())});
    }

    void carve(const CBox& box, const PHLMONITOR& m) {
        auto& rd   = Gl::ctx->m_data;
        CBox  over = box.copy().scale(m->m_scale).round();
        rd.renderModif.applyToBox(over);
        over.translate(Gl::nudge);
        rd.damage.subtract(over);
    }

    double farOf(const SScene& s) {
        return farthest((s.j0 + s.j1) / 2, s.r) + 40;
    }

    double waveAt(const SScene& s, float age) {
        return farOf(s) * outCubic(age / SHOCK) + SPEED * std::max(age, 0.F);
    }

    bool idle(const PHLWINDOW& w) {
        auto* const F = CGlassFrame::of(w);
        return F && !F->m_lens && validMapped(w) && !w->isHidden() && !w->isFloating() && !Translation::carries(w) && !Mullion::holds(w) &&
            !Fullscreen::controller()->isFullscreen(w) && !w->positionAnimation()->isBeingAnimated() && !w->sizeAnimation()->isBeingAnimated();
    }
}
