float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 x) {
    vec2 i = floor(x);
    vec2 f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

vec4 perim(vec2 q, vec2 e, float rr) {
    float A = 1.5707963 * rr;
    float lx = 2.0 * e.x;
    float ly = 2.0 * e.y;
    if (abs(q.x) <= e.x) {
        if (q.y < 0.0) return vec4(q.x + e.x, 0.0, q.x + e.x, lx);
        return vec4(lx + 2.0 * A + ly + (e.x - q.x), 4.0, e.x - q.x, lx);
    }
    if (abs(q.y) <= e.y) {
        if (q.x > 0.0) return vec4(lx + A + (q.y + e.y), 2.0, q.y + e.y, ly);
        return vec4(2.0 * lx + 3.0 * A + ly + (e.y - q.y), 6.0, e.y - q.y, ly);
    }
    vec2 d = abs(q) - e;
    if (q.x > 0.0 && q.y < 0.0) return vec4(lx + atan(d.x, d.y + 1e-5) * rr, 1.0, atan(d.x, d.y + 1e-5) * rr, A);
    if (q.x > 0.0) return vec4(lx + A + ly + atan(d.y, d.x + 1e-5) * rr, 3.0, atan(d.y, d.x + 1e-5) * rr, A);
    if (q.y > 0.0) return vec4(2.0 * lx + 2.0 * A + ly + atan(d.x, d.y + 1e-5) * rr, 5.0, atan(d.x, d.y + 1e-5) * rr, A);
    return vec4(2.0 * lx + 3.0 * A + 2.0 * ly + atan(d.y, d.x + 1e-5) * rr, 7.0, atan(d.y, d.x + 1e-5) * rr, A);
}

vec2 bricks() {
    return max(vec2(1.0), floor(2.0 * max(win.zw * 0.5 - vec2(radius), vec2(0.0)) / pieceLen + 0.5));
}

float countOf(float o, vec2 nb) {
    return mod(o, 2.0) < 0.5 ? nb.x : nb.y;
}

float orderOf(float side) {
    float h = floor(side * 0.5 + 0.25);
    return build.w > 0.0 ? h : mod(4.0 - h, 4.0);
}

float beforeOf(float o, vec2 nb) {
    return (o > 0.5 ? nb.x : 0.0) + (o > 1.5 ? nb.y : 0.0) + (o > 2.5 ? nb.x : 0.0);
}

float stepAt(float c) {
    return PACE / sqrt(1.0 + 2.0 * c * PACE / RAMP);
}

float pauseOf(float o, vec2 nb) {
    return o > 2.5 ? BREATH : TURN * stepAt(beforeOf(o + 1.0, nb) - 1.0);
}

float restOf(float o, vec2 nb) {
    return (o > 0.5 ? pauseOf(0.0, nb) : 0.0) + (o > 1.5 ? pauseOf(1.0, nb) : 0.0) + (o > 2.5 ? pauseOf(2.0, nb) : 0.0);
}

float chainLand(float o, float j, vec2 nb) {
    return T0 + RAMP * (sqrt(1.0 + 2.0 * (beforeOf(o, nb) + j) * PACE / RAMP) - 1.0) + restOf(o, nb);
}

float landAt(float c, vec2 nb) {
    float o = c < nb.x - 0.5 ? 0.0 : (c < nb.x + nb.y - 0.5 ? 1.0 : (c < 2.0 * nb.x + nb.y - 0.5 ? 2.0 : 3.0));
    return chainLand(o, c - beforeOf(o, nb), nb);
}

float headAt(float A, vec2 nb) {
    float h = -1.0;
    for (int i = 0; i < 4; ++i) {
        float o = float(i);
        float t = A - T0 - restOf(o, nb);
        float c = t * (1.0 + 0.5 * t / RAMP) / PACE;
        float end = beforeOf(o, nb) + countOf(o, nb) - 1.0;
        if (t < 0.0 || c < beforeOf(o, nb) - 1e-3)
            break;
        h = min(floor(c + 1e-3), end);
        if (c < end)
            break;
    }
    return h;
}

vec2 turnOf(float corner, vec2 nb) {
    float o = orderOf(build.w > 0.0 ? corner - 1.0 : mod(corner + 1.0, 8.0));
    return vec2(chainLand(o, countOf(o, nb) - 1.0, nb), pauseOf(o, nb));
}

float landOf(float side, float k, float n) {
    if (mod(side, 2.0) > 0.5)
        return SPEND;
    if (build.z < 0.5)
        return T0C + RUNC * (k + 1.0) / max(n, 1.0);
    return chainLand(orderOf(side), build.w > 0.0 ? k : n - 1.0 - k, build.yz);
}
