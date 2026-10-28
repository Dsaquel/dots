#include "passage/Internal.hpp"
#include "core/Ease.hpp"

namespace Passage {
    V3 operator+(V3 a, V3 b) {
        return {a.x + b.x, a.y + b.y, a.z + b.z};
    }

    V3 operator-(V3 a, V3 b) {
        return {a.x - b.x, a.y - b.y, a.z - b.z};
    }

    V3 operator*(V3 a, float k) {
        return {a.x * k, a.y * k, a.z * k};
    }

    float dot(V3 a, V3 b) {
        return a.x * b.x + a.y * b.y + a.z * b.z;
    }

    V3 cross(V3 a, V3 b) {
        return {a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x};
    }

    V3 norm(V3 a) {
        return a * (1.F / std::sqrt(dot(a, a)));
    }

    float ramp(float x) {
        return x * x * x - x * x * x * x / 2.F;
    }

    SLeg legOf(float s0, float v0, float s1) {
        const float N = std::abs(s1 - s0);
        SLeg        l{.s0 = s0, .v0 = v0, .s1 = s1};
        l.T  = FIRST + NEXT * std::max(N - 1.F, 0.F);
        l.ta = l.td = std::min(RAMP, l.T * 0.42F);
        l.vc        = (s1 - s0 - 0.5F * l.ta * v0) / (l.T - 0.5F * (l.ta + l.td));
        return l;
    }

    std::pair<float, float> along(const SLeg& l, float t) {
        if (t >= l.T)
            return {l.s1, 0.F};
        const float T  = std::max(t, 0.F);
        const float P1 = l.s0 + l.v0 * l.ta + (l.vc - l.v0) * l.ta * 0.5F;
        if (T < l.ta) {
            const float X = T / l.ta;
            return {l.s0 + l.v0 * T + (l.vc - l.v0) * l.ta * ramp(X), l.v0 + (l.vc - l.v0) * smooth(X)};
        }
        if (T < l.T - l.td)
            return {P1 + l.vc * (T - l.ta), l.vc};
        const float Y = (T - (l.T - l.td)) / l.td;
        return {P1 + l.vc * (l.T - l.ta - l.td) + l.vc * l.td * (Y - ramp(Y)), l.vc * (1.F - smooth(Y))};
    }

    std::array<float, 2> poseOf(const SFlight& f, const PHLMONITOR& monitor, float s) {
        const float F   = FOCAL * float(monitor->m_pixelSize.y);
        const float CAM = (s - std::min(f.leg.s0, f.leg.s1)) * SPACING * F;
        return {CAM, OPEN * (1.F - std::pow(1.F - unit(CAM / (0.78F * F)), 2.2F))};
    }

    SPose lookAt(V3 eye, V3 target) {
        const V3 F = norm(target - eye);
        const V3 R = norm(cross({0, 1, 0}, F));
        return {eye, R, cross(F, R), F};
    }

    SStage stageOf(const SFlight& f, const PHLMONITOR& monitor) {
        const float    W  = float(monitor->m_pixelSize.x), H = float(monitor->m_pixelSize.y);
        const Vector2D C  = monitor->logicalBoxMinusReserved().translate(-monitor->m_position).scale(monitor->m_scale).middle();
        const float    F  = FOCAL * H;
        const float    CW = CASING * float(monitor->m_scale);
        const float    LO = float(f.rooms.front().id);
        SStage         st;
        switch (f.style) {
            case eStyle::NAVE: {
                const float D   = SPACING * F;
                const float POS = f.s - float(f.from);
                const auto  DEST = f.to.lock();
                const auto  TO   = DEST ? idOf(DEST) : f.from;
                st.cam.eye      = {float(C.x), float(C.y), POS * D - F};
                float near = 0, next = 0, open = 0, zLo = 0, zHi = 0;
                for (size_t i = 0; i < f.rooms.size(); ++i) {
                    const float ORDER = float(f.rooms[i].id) - float(f.from);
                    const float Z     = ORDER * D;
                    const float DIST  = Z - st.cam.eye.z;
                    const float K     = unit((F - DIST) / (0.78F * F));
                    const float SHOWN = f.rooms[i].id == f.from || f.rooms[i].id == TO ? 1.F : 1.F - smooth((DIST - 1.3F * F) / (0.45F * F));
                    st.doors.push_back({.room = i, .z = Z, .phi = OPEN * (1.F - std::pow(1.F - K, 2.2F)), .reveal = SHOWN,
                                        .kindle = std::exp(-std::pow((DIST - 0.35F * F) / (0.7F * F), 2.F)) * f.lift,
                                        .lit    = (0.2F + 0.8F * smooth((2.6F * F - DIST) / (1.2F * F))) * f.lift});
                    if (ORDER == std::floor(POS + 1e-4F)) {
                        near = DIST;
                        open = K;
                    }
                    if (ORDER == std::floor(POS + 1e-4F) + 1.F)
                        next = DIST;
                    zLo = std::min(zLo, Z);
                    zHi = std::max(zHi, Z);
                }
                std::ranges::sort(st.doors, {}, &SDoor::z);
                auto near4 = st.doors | std::views::filter([&](const SDoor& d) { return d.reveal > 0.001F && d.z - st.cam.eye.z > -0.6F * D && imageOf(f, f.rooms[d.room]); }) |
                    std::views::take(SLOTS);
                int slot = 0;
                for (auto& d : near4)
                    d.slot = slot++;
                for (auto& d : st.doors)
                    d.light = (0.55F * d.reveal * (d.slot >= 0 ? 1.F : 0.F) + 0.35F * f.rooms[d.room].paper + 0.3F * d.kindle) * f.lift;
                st.focus = next > 0 ? near + (next - near) * smooth(open * 1.4F) : near;
                st.zoom  = std::abs(f.v) * D * EXPOSURE / std::max(st.focus, 0.3F * F);
                st.lens  = F / (1.F + WARP * smooth(std::abs(f.v) / 0.005F));
                st.boxLo = {-AISLE * W, -ARCH * W - 0.4F * H, zLo - F};
                st.boxHi = {(1.F + AISLE) * W, H + 1.6F * CW, zHi};
                break;
            }
            case eStyle::GALLERY: {
                const float PITCH = W * (1.F + GAP) + 2.F * CW;
                const float PULL  = F * std::min(0.55F + 0.4F * (f.reach - 1.F), 1.9F) * f.lift;
                const float YAW   = 0.09F * std::clamp(f.v / 0.0045F, -1.F, 1.F) * f.lift;
                const V3    EYE   = {(f.s - LO) * PITCH + float(C.x), float(C.y) - 0.08F * PULL, -F - PULL};
                st.cam            = {EYE, {std::cos(YAW), 0, -std::sin(YAW)}, {0, 1, 0}, {std::sin(YAW), 0, std::cos(YAW)}};
                for (size_t i = 0; i < f.rooms.size(); ++i) {
                    const V3 O = {(float(f.rooms[i].id) - LO) * PITCH, 0, 0};
                    st.places.push_back({.room = i, .origin = O, .depth = dot(O + V3{W / 2, H / 2, 0} - EYE, st.cam.f)});
                }
                st.focus   = F + PULL;
                st.sweep   = {-f.v * PITCH * EXPOSURE * F / (F + PULL), 0.0};
                st.boxLo   = {(float(f.first) - LO - 1.F) * PITCH, -0.2F * H, -F * 3.2F};
                st.boxHi   = {(float(f.last) - LO + 2.F) * PITCH, 1.2F * H, -0.25F * F};
                break;
            }
            case eStyle::LANTERN: {
                const int   N    = std::clamp(f.last - f.first + 1, 3, 10);
                const float STEP = 2.F * float(M_PI) / float(N);
                const float A    = (W / 2 + PILLAR * W + 1.3F * CW) / std::tan(float(M_PI) / float(N));
                const float PULL = F * std::min(0.62F + 0.2F * (f.reach - 1.F), 1.6F) * f.lift;
                const V3    MID  = {W / 2, float(C.y), A};
                st.cam           = lookAt({float(C.x), float(C.y) - 0.06F * PULL, -F - PULL}, {float(C.x), float(C.y), A * f.lift});
                for (size_t i = 0; i < f.rooms.size(); ++i) {
                    const float PSI  = (float(f.rooms[i].id) - f.s) * STEP;
                    const V3    X    = {std::cos(PSI), 0, std::sin(PSI)};
                    const V3    Z    = {-std::sin(PSI), 0, std::cos(PSI)};
                    const V3    FACE = V3{W / 2, 0, A} - Z * A;
                    const bool  BACK = dot(st.cam.eye - FACE, Z) > 0;
                    st.places.push_back({.room = i, .origin = FACE - X * (W / 2), .x = X, .z = Z, .dim = BACK ? 0.42F : 1.F, .depth = dot(FACE + V3{0, H / 2, 0} - st.cam.eye, st.cam.f)});
                }
                st.focus = F + PULL;
                st.sweep = {-f.v * STEP * A * EXPOSURE * F / (F + PULL), 0.0};
                st.glow  = MID;
                st.glowR = A * 0.75F;
                st.boxLo = {W / 2 - 1.6F * A, -0.3F * H, -0.6F * A};
                st.boxHi = {W / 2 + 1.6F * A, 1.3F * H, 2.6F * A};
                break;
            }
        }
        st.floor = H + (f.style == eStyle::LANTERN ? 0.35F * H : 1.6F * CW);
        for (auto& p : st.places) {
            p.frame  = smooth(std::abs(p.depth - F) / (0.07F * F));
            p.kindle = std::exp(-std::pow((p.depth - 0.35F * F) / (0.7F * F), 2.F)) * f.lift;
        }
        std::ranges::sort(st.places, [](const SPlace& a, const SPlace& b) { return a.depth > b.depth; });
        return st;
    }

    std::optional<CBox> boundsOf(const SPlace& pl, const SRoom& room, const SStage& st, const PHLMONITOR& monitor) {
        const float    W = float(monitor->m_pixelSize.x), H = float(monitor->m_pixelSize.y);
        const float    F  = FOCAL * H;
        const float    CW = CASING * float(monitor->m_scale);
        const Vector2D C  = monitor->logicalBoxMinusReserved().translate(-monitor->m_position).scale(monitor->m_scale).middle();
        const float    SWING = pl.doors ? std::max(room.seam, W - room.seam) * std::sin(pl.phi) : 0.F;
        double         x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9;
        for (const float LX : {-5.F * CW, W + 5.F * CW})
            for (const float LY : {-ARCH * W - 5.F * CW, H + 5.F * CW})
                for (const float LZ : {-WALL * H, SWING + 1.F}) {
                    V3 W3 = pl.origin + pl.x * LX + pl.y * LY + pl.z * LZ;
                    if (pl.mirrored)
                        W3.y = 2.F * st.floor - W3.y;
                    const V3    P   = W3 - st.cam.eye;
                    const float Z   = dot(P, st.cam.f);
                    if (Z < 1.F)
                        return CBox{{}, monitor->m_pixelSize};
                    const double SX = C.x + dot(P, st.cam.r) * F / Z, SY = C.y + dot(P, st.cam.u) * F / Z;
                    x0 = std::min(x0, SX);
                    y0 = std::min(y0, SY);
                    x1 = std::max(x1, SX);
                    y1 = std::max(y1, SY);
                }
        x0 = std::max(std::floor(x0) - 2, 0.0);
        y0 = std::max(std::floor(y0) - 2, 0.0);
        x1 = std::min(std::ceil(x1) + 2, monitor->m_pixelSize.x);
        y1 = std::min(std::ceil(y1) + 2, monitor->m_pixelSize.y);
        if (x1 <= x0 || y1 <= y0)
            return std::nullopt;
        return CBox{x0, y0, x1 - x0, y1 - y0};
    }
}
