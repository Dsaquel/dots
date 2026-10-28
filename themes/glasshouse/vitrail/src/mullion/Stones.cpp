#include "mullion/Internal.hpp"

namespace Mullion {
    float outBack(float k) {
        const float X = unit(k) - 1.F;
        return 1.F + 2.70158F * X * X * X + 1.70158F * X * X;
    }

    float blinkAt(float t, float boom) {
        const float K = (t - boom + CHARGE) / CHARGE;
        return smooth(span(K, 0, 0.06F)) * (1.F - smooth(span(K, 0.22F, 0.28F))) + smooth(span(K, 0.5F, 0.56F)) * (1.F - smooth(span(K, 0.72F, 0.78F)));
    }

    Vector2D turn(const Vector2D& v, double a) {
        return {v.x * std::cos(a) - v.y * std::sin(a), v.x * std::sin(a) + v.y * std::cos(a)};
    }

    bool lostCorner(int side, int q) {
        return q == side || q == (side + 1) % 4;
    }

    int quarterOf(const SPiece& pc, const CBox& box) {
        if (pc.kind == SPiece::FLOWER)
            return pc.quarter;
        const auto   C    = box.middle();
        const bool   LEFT = pc.origin.x < C.x, TOP = pc.origin.y < C.y;
        return TOP ? (LEFT ? 0 : 1) : (LEFT ? 3 : 2);
    }

    std::vector<CBox> veilOf(const SScene& s) {
        std::vector<CBox> out;
        bool              later = false;
        for (const auto& o : scenes) {
            if (o.get() == &s) {
                later = true;
                continue;
            }
            if (o->released || o->monitor != s.monitor || o->r.intersection(s.r).empty())
                continue;
            if (!later) {
                if (ms(*o) < o->boom + SPLIT + 70)
                    out.push_back(o->upright ? CBox{o->mid - o->gutter, o->j0.y, 2 * o->gutter, o->j1.y - o->j0.y} : CBox{o->j0.x, o->mid - o->gutter, o->j1.x - o->j0.x, 2 * o->gutter});
                continue;
            }
            std::array<double, 4> grow;
            for (int k = 0; k < 4; ++k)
                grow[k] = std::abs(edgeOf(o->r, k) - edgeOf(s.r, k)) < 3 ? CGlassFrame::MARGIN : s.gutter;
            out.push_back({o->r.x - grow[3], o->r.y - grow[0], o->r.w + grow[1] + grow[3], o->r.h + grow[0] + grow[2]});
        }
        return out;
    }

    std::array<float, 4> meltAt(const SScene& s, float t, double lo, double hi) {
        const double TOP = std::max(hi, 0.0);
        if (s.melt) {
            if (t < EXPAND0) {
                const double WAVE = s.lost * (1 - span(t, CRACK0 - 10, CRACK0 + 80));
                return {float(std::max(TOP, WAVE)), float(s.lost + 2), 1.1F * span(t, CRACK0 - 10, CRACK0 + 40), 1e5F};
            }
            return {float(TOP), float(TOP + 190), 1.2F * (1.F - span(t, s.lap0 - 10, s.lap0 + 150)), 70.F};
        }
        if (t < CRACK1 + 30) {
            const double TIP = s.lost * (1 - span(t, CRACK0 - 15, CRACK1 - 15));
            return {float(TIP), float(std::min(lo, s.lost + 2)), 1.4F * (1.F - span(t, CRACK1 - 15, CRACK1 + 30)), 26.F};
        }
        return {float(TOP), float(TOP + 70), 0.9F * (1.F - span(t, s.lap0, s.lap0 + 120)), 24.F};
    }

    std::array<float, 4> lapAt(const SScene& s, float t) {
        const double FRONT = (t - s.lap0) * s.lapSpeed;
        return {float(FRONT), float(FRONT - 360), 1.7F * (1.F - span(t, s.lap0 + SWEEP - 40, s.lap0 + SWEEP + 60)), 90.F};
    }

    std::optional<SPose> lostPose(const SLost& b, float t, const SRing& RING) {
        if (t < b.pop || t >= b.back)
            return std::nullopt;
        const double   UC   = (b.u0 + b.u1) / 2;
        const Vector2D SLOT = RING.at(UC, ACROSS), OUT = RING.normal(UC), TAN{-OUT.y, OUT.x};
        const float    H1 = noise(b.seed, 1.3F), H2 = noise(b.seed, 2.9F), H3 = noise(b.seed, 4.1F);
        const float    KP   = span(t, b.pop, b.pop + 200);
        const float    KB   = span(t, b.back - FLY, b.back);
        const float    E    = std::pow(KB, 1.7F);
        const double   BOB  = 2.5 * std::sin(t * 0.007 + b.seed * 9) * KP;
        const double   KICKED = 9 * std::sin(M_PI * std::min(1.0, KP * 2.5));
        const Vector2D HOV  = SLOT + OUT * (KICKED - HOVER * (0.7 + 0.6 * H1) * outCubic(KP) + BOB) + TAN * ((H2 - 0.5) * 14 * outCubic(KP));
        const double   TILT = ((H3 - 0.5) * 0.5 * outCubic(KP) + 0.04 * std::sin(t * 0.005 + b.seed * 3) * KP) * (1 - E);
        return SPose{.pos     = HOV + (SLOT - HOV) * E,
                     .out     = turn(OUT, TILT),
                     .len     = b.u1 - b.u0,
                     .tumble  = float((H1 - 0.5) * 1.6 * outCubic(KP) * (1 - E)),
                     .lift    = 1.F + 0.25F * float(std::sin(M_PI * KP)) * (1.F - E) + 0.15F * KB,
                     .fresh   = std::exp(-(t - b.pop) / 60.F) + 0.8F * E,
                     .opacity = 1.F,
                     .tone    = b.tone};
    }

    Vector2D stoneAt(const SScene& s, const SStone& st, float t, double& tilt) {
        const double LEAN = st.wing * (s.upright ? 0.42 : 0.35);
        if (t >= st.land) {
            tilt                = 0;
            const Vector2D DOWN = (st.slot - st.from) / std::max(1.0, st.slot.distance(st.from));
            return st.slot - DOWN * (2.5 * std::exp(-(t - st.land) / 16.0) * std::cos((t - st.land) * 0.16));
        }
        if (t >= st.drop) {
            const double E = std::pow(span(t, st.drop, st.land), 1.7F);
            tilt           = LEAN * (1 - E);
            return st.from + (st.slot - st.from) * E;
        }
        const double AMP = 0.3 + 1.2 * span(t, st.spawn + FORM, st.drop);
        tilt             = LEAN + 0.04 * std::sin(t * 0.05 + st.seed * 5) * AMP;
        return st.from + Vector2D{std::sin(t * 0.083 + st.seed * 13) * AMP, std::cos(t * 0.097 + st.seed * 7) * AMP * 0.6};
    }

    void drawStones(const SScene& s, float t, const PHLMONITOR& m) {
        const auto G = s.giver.lock(), B = s.born.lock();
        if (!G || !B)
            return;
        const float OUT = 1.F - span(t, s.boom + SPLIT, s.boom + SPLIT + 70);
        if (OUT <= 0)
            return;
        const double AX   = s.upright ? s.b.x : s.b.y;
        const double GOFF = (edgeOf(boxOf(G).translate(-m->m_position), s.side) - s.mid) * AX;
        const double NOFF = (edgeOf(boxOf(B).translate(-m->m_position), (s.side + 2) % 4) - s.mid) * AX;
        const float  KSP  = outBack(span(t, s.boom, s.boom + SPLIT));
        const float  LC   = t < s.boom ? 0.F : std::exp(-(t - s.boom) / 160.F);
        const float  BLINK = blinkAt(t, s.boom);
        for (const auto& ST : s.stones) {
            if (t < ST.spawn)
                continue;
            const bool DIVING = t >= ST.drop && t < ST.land;
            for (const auto& [LAG, ALPHA] : std::initializer_list<std::pair<float, float>>{{0.F, 1.F}, {10.F, 0.4F}, {20.F, 0.18F}}) {
                const float TT = t - LAG;
                if (LAG > 0 && (!DIVING || TT < ST.drop))
                    continue;
                double       tilt   = 0;
                const auto   C      = stoneAt(s, ST, TT, tilt);
                const float  KF     = span(TT, ST.spawn, ST.spawn + FORM);
                const float  LANDED = TT >= ST.land ? std::exp(-(TT - ST.land) / 110.F) : 0.F;
                const float  HEAT   = LAG > 0 ? 0.F : BLINK;
                const float  GLEAM  = 0.85F + 0.15F * std::sin(TT * 0.09F + ST.seed * 3);
                const double SQ     = TT >= ST.land ? 1 - 0.07 * std::exp(-(TT - ST.land) / 25.0) : 1;
                for (const int H : {-1, 1}) {
                    const double OFF = H < 0 ? -HALF + (GOFF + ACROSS + HALF) * KSP : HALF + (NOFF - ACROSS - HALF) * KSP;
                    drawBrick(SPose{.pos     = C + turn(s.b, tilt) * OFF,
                                    .out     = turn(s.b * double(-H), tilt),
                                    .len     = s.len * (0.35 + 0.65 * outBack(KF)) * SQ,
                                    .lift    = TT < ST.land ? 1.18F * GLEAM : 1.F,
                                    .fresh   = 1.2F * (1.F - KF) + (DIVING ? 0.5F : 0.F) + std::max(LC, 0.6F * HEAT),
                                    .land    = std::max({LANDED, LC, HEAT}),
                                    .opacity = ALPHA * outCubic(KF) * OUT,
                                    .tone    = ST.tone},
                              m);
                }
            }
        }
    }

    void drawLost(const SScene& s, float t, const PHLMONITOR& m) {
        const SRing RING(s.r, s.radius);
        if (!s.melt)
            for (const auto& b : s.bricks)
                for (const auto& [LAG, ALPHA] : std::initializer_list<std::pair<float, float>>{{0.F, 1.F}, {14.F, 0.35F}, {28.F, 0.15F}}) {
                    if (LAG > 0 && (t >= b.back || t - LAG < b.back - FLY))
                        continue;
                    if (auto ps = lostPose(b, t - LAG, RING)) {
                        ps->opacity = ALPHA;
                        drawBrick(*ps, m);
                    }
                }
    }

    void drawBricks(const SScene& s, float t, const PHLMONITOR& m) {
        drawStones(s, t, m);
        const float AGE = t - s.boom;
        if (AGE < 0 || AGE > 420)
            return;
        for (int i = 0; i < 2; ++i) {
            const double   SPIN = i == 0 ? 1 : -1;
            const Vector2D OUT  = s.a * (i == 0 ? -1.0 : 1.0);
            const Vector2D J    = (i == 0 ? s.j0 : s.j1) - OUT * (s.came - ACROSS);
            drawBrick(SPose{.pos     = J + OUT * (16 * (1 - std::exp(-AGE / 60.0))) + Vector2D{0.0, 0.0011 * AGE * AGE} + s.b * (0.03 * AGE * SPIN),
                            .out     = turn(OUT, AGE * 0.004 * SPIN),
                            .len     = 2 * s.gutter + 1.4 * s.radius,
                            .tumble  = float(AGE * 0.012 * SPIN),
                            .fresh   = std::exp(-AGE / 80.F),
                            .opacity = 1.F - span(AGE, 160, 420),
                            .tone    = 2},
                      m);
        }
    }

    void drawRing(const SScene& s, float t) {
        auto        ring = *s.ring;
        const SRing RING(s.r, s.radius);
        const auto [LO, HI] = cutAt(s, t);
        ring.alpha *= s.dawn < 1e8F ? span(t, s.dawn, s.dawn + DAWN) : 1.F;
        ring.cut            = {float(s.farN), float(LO), float(HI), 0.F};
        ring.melt           = t >= s.lap0 + 30 ? lapAt(s, t) : meltAt(s, t, LO, HI);
        if (t >= s.lap0)
            ring.seal = {float(s.farN), float((t - s.lap0) * s.lapSpeed), 0.95F * (1.F - span(t, s.lap0 + SWEEP, s.lap0 + SWEEP + 160)), 0.F};
        const auto CORNERS = RING.corners();
        for (auto& pc : ring.pieces) {
            if (pc.kind == SPiece::CREST) {
                const float K = span(t, 0, 110);
                pc.opacity *= 1.F - K;
                pc.scale *= 1.F + 0.4F * K;
                continue;
            }
            const int   Q   = quarterOf(pc, s.r);
            const float LAP = s.lap0 + float(RING.circ(CORNERS[Q], s.farN) / s.lapSpeed);
            if (pc.kind == SPiece::FLOWER)
                pc.glow += 1.2F * std::exp(-std::pow((t - LAP) / 60.F, 2.F));
            if (!lostCorner(s.side, Q))
                continue;
            const float K = t < s.bloom ? 1.F - span(t, s.wither, s.wither + 120) : span(t, s.bloom, s.bloom + 260);
            if (pc.kind == SPiece::FLOWER)
                pc.grow *= K;
            else {
                pc.opacity *= K;
                pc.scale *= 0.3F + 0.7F * K;
            }
        }
        if (s.plateLost)
            ring.plate.opacity *= 1.F - span(t, CRACK0, CRACK0 + 150);
        CGlassPass(std::move(ring)).paint();
    }

    void drawPair(const SScene& s, float t, const PHLMONITOR& m) {
        const float Z = span(t, s.boom + SPLIT, s.boom + SPLIT + 80);
        for (const bool BORN : {false, true}) {
            const auto  W    = (BORN ? s.born : s.giver).lock();
            auto* const F    = W && !claimed(s, W) ? CGlassFrame::of(W) : nullptr;
            auto        data = F ? F->build(m, 1.F) : std::nullopt;
            if (!data)
                continue;
            const int   SEAM = BORN ? (s.side + 2) % 4 : s.side;
            const SRing RG(data->window, data->radius);
            data->lantern.reset();
            data->gap = {float(RG.mid(SEAM)), float((RG.half(SEAM) + RG.arc / 2 + 4) * (1.F - Z)), Z > 0 && Z < 1 ? 0.8F : 0.F, 0.F};
            if (BORN) {
                for (auto& pc : data->pieces) {
                    if (pc.kind == SPiece::CREST) {
                        const float DROP = span(t, s.boom + 60, s.boom + 240);
                        const float FALL = 1.F - std::pow(unit(DROP / 0.7F), 2.F);
                        const float BOB  = DROP > 0.7F ? std::sin(float(M_PI) * (DROP - 0.7F) / 0.3F) * (1.F - (DROP - 0.7F) / 0.3F) : 0.F;
                        pc.origin.y -= 34 * FALL;
                        pc.scale *= 1.F + 0.35F * FALL - 0.18F * BOB;
                        pc.opacity *= unit(DROP / 0.3F);
                        pc.glow += 1.1F * std::exp(-std::pow((DROP - 0.7F) / 0.15F, 2.F));
                        continue;
                    }
                    if (!lostCorner(SEAM, quarterOf(pc, data->window)))
                        continue;
                    const float K = span(t, s.boom + 70, s.boom + 330);
                    if (pc.kind == SPiece::FLOWER)
                        pc.grow *= K;
                    else {
                        pc.opacity *= K;
                        pc.scale *= 0.3F + 0.7F * K;
                    }
                }
                data->plate.stream = std::min(data->plate.stream, span(t, s.boom + 140, s.boom + 500));
            } else {
                const float FADE = 1.F - span(t, s.boom, s.boom + 200);
                data->level      = std::max(data->level, FADE);
                for (auto pc : s.ring->pieces)
                    if (pc.kind != SPiece::CREST && !lostCorner(s.side, quarterOf(pc, s.r)) && FADE > 0) {
                        pc.opacity *= FADE;
                        data->pieces.push_back(pc);
                    }
                if (!s.plateLost && FADE > 0 && s.ring->plate.on) {
                    data->plate = s.ring->plate;
                    data->plate.opacity *= FADE;
                }
            }
            CGlassPass(std::move(*data)).paint();
        }
    }

    std::vector<SImpact> impactsAt(const SScene& s, float t) {
        std::vector<SImpact> out;
        const SRing          RING(s.r, s.radius);
        for (const auto& J : {s.j0, s.j1})
            out.push_back({.at = J, .birth = 0, .strength = 0.8F, .size = 130, .kind = BURST});
        for (const auto& pc : s.ring->pieces)
            if (pc.kind == SPiece::CREST)
                out.push_back({.at = pc.origin, .birth = 15, .size = 40, .kind = GLINT});
        if (!s.melt)
            for (const auto& b : s.bricks) {
                const double UC = (b.u0 + b.u1) / 2;
                const double UJ = RING.circ(b.u0, s.farN) > RING.circ(b.u1, s.farN) ? b.u0 : b.u1;
                out.push_back({.at = RING.at(UC, s.came), .axis = RING.normal(UC), .birth = b.pop, .strength = 0.8F, .size = 80, .kind = SPARKS});
                out.push_back({.at = RING.at(UJ, 5.5), .axis = RING.normal(UJ), .birth = b.back + SETTLED, .size = 6, .kind = WELDING});
            }
        else {
            const float DONE = EXPAND1 + CLOSE;
            const auto [LO, HI] = cutAt(s, t);
            if (t >= CRACK0 + 30 && t < DONE && HI > 0)
                for (const double SIGN : {-1.0, 1.0})
                    out.push_back({.at = RING.at(s.farN + SIGN * HI, s.came), .strength = 1.F, .size = float(2.5 + 3.5 * std::sqrt(HI / s.lost)), .kind = BEAD});
            out.push_back({.at = RING.at(s.farN, s.came), .birth = DONE, .size = 140, .kind = BURST});
        }
        for (const auto& J : {s.j0, s.j1})
            out.push_back({.at = J, .birth = s.ignite, .size = 40, .kind = ZAP});
        for (const auto& ST : s.stones) {
            const Vector2D HIT = s.upright ? ST.slot + s.a * (s.len / 2) : ST.slot;
            out.push_back({.at = ST.from, .axis = s.a, .birth = ST.spawn, .size = 50, .kind = FORMING});
            out.push_back({.at = HIT, .axis = {0, 1}, .birth = ST.land, .strength = 0.8F, .size = 60, .kind = SLAM});
            out.push_back({.at = HIT, .axis = s.b, .birth = ST.land + SETTLED, .size = 2 * HALF, .kind = WELDING});
        }
        out.push_back({.at = (s.j0 + s.j1) / 2, .birth = s.boom, .strength = 0.9F + 0.5F * s.heat, .size = 150 * (1 + 0.8F * s.heat), .kind = BURST});
        for (const auto& J : {s.j0, s.j1})
            out.push_back({.at = J, .birth = s.boom, .size = 40, .kind = ZAP});
        return out;
    }

    void drawRelease(const SScene& s, const PHLMONITOR& m) {
        const auto G   = s.giver.lock();
        const auto TEX = s.still ? s.still->getTexture() : nullptr;
        if (!G || !TEX || !Gl::ready(paneProgram))
            return;
        const double S    = m->m_scale;
        const CBox   BOX  = boxOf(G).translate(-m->m_position);
        const auto   AREA = Gl::areaOf(BOX.copy().scale(S).round(), std::nullopt);
        if (!AREA)
            return;
        auto& p = paneProgram;
        g_pHyprOpenGL->useShader(p.shader);
        stampPane();
        glUniform4f(p["drawn"], AREA->drawn.x, AREA->drawn.y, AREA->drawn.w, AREA->drawn.h);
        g_pHyprOpenGL->blend(true);
        glUniform1f(p["pass"], 3.F);
        glUniform2f(p["texSize"], s.still->m_size.x, s.still->m_size.y);
        glUniform4f(p["born"], BOX.x * S, BOX.y * S, BOX.w * S, BOX.h * S);
        glUniform1f(p["radius"], G->presentation().rounding() * S);
        glUniform1f(p["fade"], s.settled < 0 ? 1.F : 1.F - span(secondsAlive() - s.settled, 0, 0.2F));
        glUniform2f(p["cell"], 40.F * S, 60.F * S);
        Gl::bindTex(0, TEX);
        Gl::paint(p, *AREA);
        Gl::bindTex(0, nullptr);
    }

    void paint(const SScene& s, float t, const PHLMONITOR& m) {
        g_pHyprOpenGL->blend(true);
        if (t < EXPAND1 + CELL * 1.3F)
            drawPane(s, t, 0, m);
        drawPane(s, t, 1, m);
        auto&         rd     = Gl::ctx->m_data;
        const CRegion DAMAGE = rd.damage.copy();
        for (const auto& V : t < s.boom ? veilOf(s) : std::vector<CBox>{})
            carve(V, m);
        if (t < s.boom)
            drawRing(s, t);
        else
            drawPair(s, t, m);
        drawLost(s, t, m);
        rd.damage = DAMAGE;
        drawBricks(s, t, m);
        for (const auto& im : impactsAt(s, t))
            drawImpact(s, im, t, m);
        drawStruck(s, t, m);
        Gl::unbindAll();
        g_pHyprOpenGL->blend(true);
    }
}
