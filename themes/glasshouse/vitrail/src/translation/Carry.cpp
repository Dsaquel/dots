#include "translation/Internal.hpp"

#include <random>

namespace Translation {
    float ms(const SCarry& c) {
        return c.ahead + (c.clock ? c.clock->value() * CLOCK : CLOCK);
    }

    float ms(const SPyre& p) {
        return p.base + (p.clock ? p.clock->value() * PYRE : PYRE);
    }

    float weldOf(const SCarry& c) {
        return c.base + c.last + GAP;
    }

    float endOf(const SCarry& c) {
        return c.kind == eKind::PIVOT || c.kind == eKind::SWAP ? SLAM + SHOCK + DUSTED : std::max(c.kind == eKind::TRANSLATE ? BROKEN : 0.F, weldOf(c) + WAVE + 1.2F * SEAM + MOTE);
    }

    void bindPerm(int unit, GLuint tex) {
        glActiveTexture(GL_TEXTURE0 + unit);
        glBindTexture(GL_TEXTURE_2D, tex);
        glActiveTexture(GL_TEXTURE0);
    }

    void upload(SCarry& c, int nu, const std::vector<std::array<float, 4>>& texels) {
        g_pHyprOpenGL->makeEGLCurrent();
        if (!c.perm)
            glGenTextures(1, &c.perm);
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, c.perm);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA32F, nu, nu, 0, GL_RGBA, GL_FLOAT, texels.data());
        glBindTexture(GL_TEXTURE_2D, 0);
    }

    void plan(SCarry& c) {
        c.lattice           = latticeOf(c.goal);
        const int  GX       = int(c.lattice.x), GY = int(c.lattice.y), NU = GX + GY;
        const bool FORMS_IN = c.kind == eKind::TRANSLATE;
        const auto MID      = [GX, GY](int iu, int iv) { return Vector2D{(iu + iv + 1) / (2.0 * GX), (iu - iv) / (2.0 * GY)}; };
        const auto PX       = [&c](const Vector2D& n) { return Vector2D{n.x * c.goal.w, n.y * c.goal.h}; };
        std::vector<int> homes;
        for (int i = 0; i < NU * NU; ++i)
            if (const auto M = MID(i % NU, i / NU - GY); M.x >= 0 && M.x <= 1 && M.y >= 0 && M.y <= 1)
                homes.push_back(i);
        std::mt19937                          rng{uint32_t(c.seed * 7919.F) + 1};
        std::uniform_real_distribution<float> roll;
        std::vector<int>                      at(size_t(NU * NU), -1), start(size_t(NU * NU), -1);
        for (const int H : homes)
            at[size_t(H)] = H;
        for (int round = 0; round < ROUNDS; ++round) {
            const bool ALONG = roll(rng) < 0.5F;
            const int  SIDE  = roll(rng) < 0.5F ? 0 : 1;
            for (const int P : homes) {
                const int LANE = ALONG ? P % NU : P / NU, Q = ALONG ? P + 1 : P + NU;
                if (LANE % 2 == SIDE && LANE + 1 < NU && at[size_t(Q)] >= 0 && roll(rng) < SWAP)
                    std::swap(at[size_t(P)], at[size_t(Q)]);
            }
        }
        for (const int P : homes)
            start[size_t(at[size_t(P)])] = P;
        std::vector<std::array<float, 4>> texels(size_t(NU * NU), {-1.F, 0.F, 0.F, 0.F});
        c.first = SHUT;
        c.last  = 0;
        for (const int H : homes) {
            const int   S = start[size_t(H)];
            const int   HU = H % NU, HV = H / NU - GY, SU = S % NU, SV = S / NU - GY;
            const auto  KU = MID(HU, SV), KV = MID(SU, HV), HALF = Vector2D{0.5, 0.5};
            const bool  VFIRST = HU != SU && (HV == SV || PX(KV - HALF).size() < PX(KU - HALF).size());
            const auto  K      = VFIRST ? KV : KU;
            const auto  LEN    = PX(K - MID(SU, SV)).size() + PX(MID(HU, HV) - K).size();
            const float BORN   = FORMS_IN ? FORMING * roll(rng) : -POPPED * roll(rng) - c.delay;
            const float GO     = std::max((FORMS_IN ? FORMED : LEAVE) + SPREAD * roll(rng), BORN + (FORMS_IN ? FORM : POP));
            const float LAND   = GO + DASH + DASHED * float(std::sqrt(LEN / 1000));
            texels[size_t(H)]  = {float(2 * S + (VFIRST ? 1 : 0)), BORN, GO, LAND};
            c.first            = std::min(c.first, LAND);
            c.last             = std::max(c.last, LAND);
        }
        upload(c, NU, texels);
    }

    CBox hullOf(const SCarry& c) {
        return c.pair.copy().expand(-RIM);
    }

    Vector2D extOf(const SCarry& c, const Vector2D& q, const Vector2D& hub) {
        const CBox U = hullOf(c);
        return {q.x >= 0 ? U.x + U.w - hub.x : hub.x - U.x, q.y >= 0 ? U.y + U.h - hub.y : hub.y - U.y};
    }

    Vector2D normOf(const SCarry& c, const Vector2D& p) {
        const Vector2D Q = p - c.hubs[0], E = extOf(c, Q, c.hubs[0]);
        return {Q.x / E.x, Q.y / E.y};
    }

    Vector2D landOf(const SCarry& c, const Vector2D& p) {
        const Vector2D N = normOf(c, p), R = Vector2D{-N.y, N.x} * c.sense, E = extOf(c, R, c.hubs[1]);
        return c.hubs[1] + Vector2D{R.x * E.x, R.y * E.y};
    }

    float easeOf(float k) {
        return EASE * k + (1 - EASE) * k * k;
    }

    float soft(float k) {
        const float X = std::clamp(k, 0.F, 1.F);
        return X * X * (3.F - 2.F * X);
    }

    float ringAge(const SCarry& c, double d) {
        return SHOCK * (1.F - std::cbrt(1.F - float(std::clamp(d / c.far, 0.0, 1.0))));
    }

    double nearest(const std::vector<std::array<float, 4>>& gates, const Vector2D& p) {
        double d = 1e9;
        for (const auto& G : gates) {
            const Vector2D A{G[0], G[1]}, E = Vector2D{G[2], G[3]} - A, Q = p - A;
            const double   U = std::clamp((Q.x * E.x + Q.y * E.y) / std::max(E.x * E.x + E.y * E.y, 1e-9), 0.0, 1.0);
            d                = std::min(d, (Q - E * U).size());
        }
        return d;
    }

    void bindGates(Gl::SProgram& p, const SCarry& c, const Vector2D& origin, double scale) {
        std::array<float, 4 * GATES> out = {};
        const size_t                 N   = std::min<size_t>(c.gates.size(), GATES);
        for (size_t i = 0; i < 4 * N; ++i)
            out[i] = float((c.gates[i / 4][i % 4] - (i % 2 ? origin.y : origin.x)) * scale);
        glUniform4fv(p["gates"], GATES, out.data());
        glUniform1f(p["gated"], float(N));
        glUniform2f(p["glide"], c.glide.x * scale, c.glide.y * scale);
    }

    float progressOf(float r, float t) {
        const float GO = SWING + TWIST * r;
        return std::clamp((t - GO) / (SLAM - GO), 0.F, 1.F);
    }

    float angleOf(const SCarry& c, float r, float t) {
        const float F = std::clamp(r, 0.F, 1.F) * (SKEWS - 1);
        const int   I = std::min(int(F), SKEWS - 2);
        const float K = progressOf(r, t), K0 = progressOf(r, c.ahead), GO = SWING + TWIST * r, E = 1 - K * K;
        const float DRAWN = c.ahead > 0 ? 0.F : t < GO ? soft((t - c.ahead) / (GO - c.ahead)) : 1 - soft(K);
        return float(M_PI_2) * (1 - E) + std::lerp(c.skew[I], c.skew[I + 1], F - float(I)) * E / std::max(1 - K0 * K0, 1e-3F) - WIND * DRAWN;
    }

    void planTurn(SCarry& c) {
        c.lattice           = c.grid;
        const int  GX       = int(c.lattice.x), GY = int(c.lattice.y), NU = GX + GY;
        const auto MID      = [GX, GY](int iu, int iv) { return Vector2D{(iu + iv + 1) / (2.0 * GX), (iu - iv) / (2.0 * GY)}; };
        std::vector<std::array<float, 4>> texels(size_t(NU * NU), {-1.F, 0.F, 0.F, 0.F});
        c.first = SHUT;
        c.last  = 0;
        for (int i = 0; i < NU * NU; ++i) {
            const auto M = MID(i % NU, i / NU - GY);
            if (M.x < 0 || M.x > 1 || M.y < 0 || M.y > 1)
                continue;
            const Vector2D S  = c.source.pos() + Vector2D{M.x * c.source.w, M.y * c.source.h};
            texels[size_t(i)] = {1.F, c.ahead > 0 ? c.ahead : SWING + TWIST * float(std::min(normOf(c, S).size() * M_SQRT1_2, 1.0)), SLAM, SLAM + ringAge(c, (landOf(c, S) - c.pivot).size())};
            c.first           = std::min(c.first, texels[size_t(i)][3]);
            c.last            = std::max(c.last, texels[size_t(i)][3]);
        }
        upload(c, NU, texels);
    }
}
