#include "life/Internal.hpp"

namespace Life {
    std::array<double, 4> hash4(double x, double y, double seed) {
        const auto fr = [](double v) { return v - std::floor(v); };
        std::array<double, 4> q = {fr(x * 0.1031 + seed * 0.618), fr(y * 0.1030 + seed * 0.618), fr(x * 0.0973 + seed * 0.618), fr(y * 0.1099 + seed * 0.618)};
        const double D = q[0] * (q[3] + 33.33) + q[1] * (q[2] + 33.33) + q[2] * (q[0] + 33.33) + q[3] * (q[1] + 33.33);
        for (auto& v : q)
            v += D;
        return {fr((q[0] + q[1]) * q[2]), fr((q[0] + q[2]) * q[1]), fr((q[1] + q[2]) * q[3]), fr((q[2] + q[3]) * q[0])};
    }

    struct SPose {
        Vector2D pos, out;
        double   len = 0;
        float    tumble = 0, lift = 1, k = 0, t0 = 0, t1 = 0;
        bool     live = false;
    };

    SPose poseOf(const SFlight& f, int i, float t) {
        const SRing  RING(f.box, f.radius);
        const double HALF = RING.per / 2;
        const auto   H   = hash4(i * 3.0 + 1.0, i * 7.0 + 5.0, f.seed);
        const double FR  = (i + 0.5) / f.count;
        const auto   M   = (f.a + f.b) / 2;
        auto         dS  = f.b - f.a;
        const double SEG = std::max(1.0, std::hypot(dS.x, dS.y));
        dS               = dS / SEG;
        const Vector2D RC{RING.cx, RING.cy};
        const double   SLOT = SEG / f.count;
        const auto     S    = f.a + (f.b - f.a) * FR;
        auto           sOut = Vector2D{-dS.y, dS.x};
        if ((RC - S).x * sOut.x + (RC - S).y * sOut.y < 0)
            sOut = sOut * -1;
        const auto     TAN  = RING.at(f.at + 0.5, f.off) - RING.at(f.at - 0.5, f.off);
        const double   SIGN = (S - M).x * TAN.x + (S - M).y * TAN.y >= 0 ? 1 : -1;
        const double   J    = std::floor(std::abs(FR - 0.5) * f.count);
        const double   D    = (J + 0.5) / std::max(f.count * 0.5, 1.0) * HALF;
        const double   U    = f.at + SIGN * D;
        const Vector2D p0 = S, o0 = sOut, p1 = RING.at(U, f.off), o1 = RING.normal(U);
        const double   l0 = SLOT * 0.92, l1 = std::min(SLOT, 80.0) * 0.92;
        const float    t0 = float(10 + 70 * std::abs(2 * FR - 1));
        const float    t1 = std::max(float(60 + 360 * (1 - std::sqrt(std::max(0.0, 1 - D / (HALF + 20))))), t0 + 130.F);
        SPose ps;
        if (t < t0 || t >= t1)
            return ps;
        const float K    = unit((t - t0) / std::max(t1 - t0, 1.F));
        const float E    = outCubic(K);
        double      rot  = std::atan2(o0.x * o1.y - o0.y * o1.x, o0.x * o1.x + o0.y * o1.y);
        const bool  FLIP = std::abs(rot) > M_PI / 2;
        if (FLIP)
            rot = rot > 0 ? rot - M_PI : rot + M_PI;
        const double TURNS = (FLIP ? M_PI : 0) + (H[3] > 0.45 ? 2 * M_PI : 0);
        ps.tumble          = float(TURNS * K * K * (3 - 2 * K));
        const double A     = std::atan2(o0.y, o0.x) + rot * E + (H[1] - 0.5) * 0.6 * std::sin(M_PI * K);
        ps.out             = {std::cos(A), std::sin(A)};
        const auto   CH    = p1 - p0;
        const double CL    = std::hypot(CH.x, CH.y);
        const auto   PERP  = CL > 1e-3 ? Vector2D{-CH.y / CL, CH.x / CL} : Vector2D{0, -1};
        const auto   CTRL  = (p0 + p1) / 2 + PERP * ((0.22 * CL + 24) * (H[2] > 0.5 ? 1 : -1));
        const auto   Q0 = p0 + (CTRL - p0) * E, Q1 = CTRL + (p1 - CTRL) * E;
        ps.pos             = Q0 + (Q1 - Q0) * E;
        ps.lift            = 1.F + 0.75F * float(std::sin(M_PI * std::min(K * 1.15, 1.0)));
        ps.len             = (l0 + (l1 - l0) * E) * ps.lift;
        ps.k               = K;
        ps.t0              = t0;
        ps.t1              = t1;
        ps.live            = true;
        return ps;
    }

    Vector2D lightPx(const PHLMONITOR& m) {
        return worldLightOn(m) * m->m_scale;
    }

    void drawPiece(const SPose& ps, int i, float t, float opacity, const PHLMONITOR& m) {
        const double S   = m->m_scale;
        const double EXT = ps.len / 2 + 40;
        const auto   BOX = CBox{ps.pos.x - EXT, ps.pos.y - EXT, 2 * EXT, 2 * EXT}.scale(S).round();
        const auto   AREA = Gl::areaOf(BOX, std::nullopt);
        if (!AREA || !Gl::ready(pieceProgram))
            return;
        auto&       p = pieceProgram;
        const auto& P = pal();
        g_pHyprOpenGL->useShader(p.shader);
        if (p.stamp.first != &P) {
            p.stamp = {&P, 0};
            Gl::rgb(p, "base", P.metalBase);
            Gl::rgb(p, "hi", P.metalHi);
            Gl::rgb(p, "low", P.metalLow);
            Gl::rgb(p, "sky", P.metalSky);
            Gl::rgb(p, "pearl", P.pearl);
            Gl::rgb(p, "hot", P.hot);
            Gl::rgb(p, "sepia", hue().sepia);
            Gl::rgb(p, "leaf", hue().leaf);
            glUniform1f(p["ink"], hue().inked);
        }
        const auto L = lightPx(m);
        glUniform4f(p["drawn"], AREA->drawn.x, AREA->drawn.y, AREA->drawn.w, AREA->drawn.h);
        glUniform2f(p["pos"], ps.pos.x * S, ps.pos.y * S);
        glUniform2f(p["out2"], ps.out.x, ps.out.y);
        glUniform1f(p["len"], ps.len * S);
        glUniform1f(p["tumble"], ps.tumble);
        glUniform1f(p["lift"], ps.lift);
        glUniform1f(p["fresh"], std::exp(-(t - ps.t0) / 70.F));
        glUniform1f(p["land"], std::exp(-std::pow((ps.t1 - t) / 26.F, 2.F)));
        glUniform1f(p["fade"], 1.F);
        glUniform1f(p["haloGain"], 0.55F);
        glUniform1f(p["landGain"], 0.45F);
        glUniform1f(p["scale"], S);
        glUniform1f(p["opacity"], opacity);
        Gl::rgb(p, "jewel", i % 2 == 0 ? P.jewelA : P.jewelB);
        glUniform4f(p["lightPos"], L.x, L.y, 520.F * S, 640.F * S);
        Gl::paint(p, *AREA);
    }

    void drawFlight(const SFlight& f, float t, const PHLMONITOR& m) {
        for (int i = 0; i < f.count; ++i) {
            for (const auto& [lag, alpha] : std::initializer_list<std::pair<float, float>>{{8.F, 0.3F}, {0.F, 1.F}})
                if (const auto POSE = poseOf(f, i, t - lag); POSE.live)
                    drawPiece(POSE, i, t - lag, alpha, m);
        }
    }
}
