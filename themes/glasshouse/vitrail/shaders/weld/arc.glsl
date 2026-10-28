void zap(float d, float e) {
    core += exp(-sq(d / ((ink > 0.5 ? 1.1 : 0.7) * scale))) * e;
    halo += (exp(-d / (2.4 * scale)) * 0.4 + exp(-d / (6.0 * scale)) * 0.06) * e;
}

void flare(vec2 d, float e) {
    float r = dot(d, d) / sq(scale);
    core += exp(-r / 4.0) * e;
    halo += (exp(-sqrt(r) / 4.0) * 0.5 + exp(-sqrt(r) / 6.0) * 0.1) * e;
}

void arc(vec2 key, float b, float tb, float along, float across, float len, float head, float hit, float e, vec4 hb, bool struck) {
    vec2 y = pathOf(key, b, along, len, struck ? 1.4 * AMP : AMP);
    zap(abs(across - y.x) / sqrt(1.0 + y.y * y.y), e * smoothstep(-scale, 0.0, along) * (1.0 - smoothstep(head - 2.0 * scale, head + scale, along)));
    if (hb.z > 0.45) {
        float sb = (0.15 + 0.7 * fract(7.3 * hb.w)) * min(head, len);
        float k = (hb.z > 0.72 ? 1.0 : -1.0) * (0.5 + 1.1 * fract(5.1 * hb.x));
        float lb = (6.0 + 14.0 * fract(3.3 * hb.y)) * scale;
        float q = along - sb;
        if (q > 0.0 && q < lb) {
            float yb = pathOf(key, b, sb, len, AMP).x + k * q + 1.6 * scale * zig(key + 3.3, b, q, 3.0 * scale).x;
            zap(abs(across - yb) / sqrt(1.0 + k * k), 0.7 * e * (1.0 - q / lb));
        }
    }
    if (struck) {
        float sf = hb.w * hit;
        flare(vec2(along - sf, across - pathOf(key, b, sf, len, 1.4 * AMP).x), 4.0 * exp(-(t - tb) / 9.0));
    }
}

void crackle(vec2 ja, vec2 jb, vec2 key, vec2 p) {
    float ta = ignite(ja);
    float tz = ignite(jb);
    vec2 jo = tz < ta ? jb : ja;
    vec2 jc = tz < ta ? ja : jb;
    float to = min(ta, tz);
    float tc = max(ta, tz);
    float age = t - to;
    if (age < 0.0 || t > tc + ARCED || !fed(jc, tc, jo))
        return;
    vec2 A = junction(jo);
    vec2 B = junction(jc);
    float len = length(B - A);
    vec2 u = (B - A) / max(len, 1e-3);
    float along = dot(p - A, u);
    float across = dot(p - A, vec2(-u.y, u.x));
    float lane = lanes > 0.5 ? laneOf(0.5 * (A.x + B.x)) : 1.0;
    if (lane < 0.02 || abs(across) > REACH * scale || along < -REACH * scale || along > len + REACH * scale)
        return;
    vec4 g = hash4(key * 1.618 + 3.1);
    float dt = FLICK + JIT * g.x;
    float b = floor(t / dt + g.y);
    float tb = max((b - g.y) * dt, to);
    vec4 hb = hash4(key + vec2(7.13 * b, -3.71 * b) + 0.5);
    bool struck = g.z > CHARGED && hb.y < STRIKE;
    float e = (1.0 - smoothstep(0.3 * ARCED, ARCED, t - tc)) * (hb.x < DARKS ? 0.12 : 0.6 + 0.6 * hb.z) * (struck ? 1.8 : 1.0) * (0.7 + 0.3 * exp(-(t - tb) / 6.0)) *
        (0.4 + 0.6 * smoothstep(0.15, 0.6, g.z)) * (1.25 - 0.55 * clamp((tc - ring.y) / ring.z, 0.0, 1.0));
    float head = len * clamp(age / max(tc - to, 1.0), 0.0, 1.0);
    arc(key, b, tb, along, across, len, head, len * clamp((tb - to) / max(tc - to, 1.0), 0.0, 1.0), e * lane, hb, struck);
    if (t < tc + 8.0)
        flare(vec2(along - head, across - pathOf(key, b, head, len, AMP).x), 1.6 * lane);
}
