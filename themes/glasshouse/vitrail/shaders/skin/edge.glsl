vec4 over(vec4 a, vec4 b) {
    return a + b * (1.0 - a.a);
}

vec2 rot(vec2 v, float a) {
    float c = cos(a);
    float s = sin(a);
    return vec2(c * v.x - s * v.y, s * v.x + c * v.y);
}

float outBack(float k) {
    float u = clamp(k, 0.0, 1.0) - 1.0;
    return 1.0 + 2.70158 * u * u * u + 1.70158 * u * u;
}

vec2 normalOf(float c) {
    return c < 0.5 ? vec2(0.0, -1.0) : (c < 1.5 ? vec2(1.0, 0.0) : (c < 2.5 ? vec2(0.0, 1.0) : vec2(-1.0, 0.0)));
}

vec2 dirOf(float c) {
    return c < 0.5 ? vec2(1.0, 0.0) : (c < 1.5 ? vec2(0.0, 1.0) : (c < 2.5 ? vec2(-1.0, 0.0) : vec2(0.0, -1.0)));
}

vec2 cornerOf(float a) {
    return a < 2.0 ? vec2(1.0, -1.0) : (a < 4.0 ? vec2(1.0, 1.0) : (a < 6.0 ? vec2(-1.0, 1.0) : vec2(-1.0, -1.0)));
}

vec2 edgeAt(float c, float x, vec2 e, vec2 hs) {
    return c < 0.5 ? vec2(x - e.x, -hs.y) : (c < 1.5 ? vec2(hs.x, x - e.y) : (c < 2.5 ? vec2(e.x - x, hs.y) : vec2(-hs.x, e.y - x)));
}

vec2 gradOf(vec2 q, vec2 hs) {
    vec2 w = abs(q) - hs + vec2(radius);
    vec2 gq = sign(q) * (min(w.x, w.y) > 0.0 ? normalize(w) : (w.x > w.y ? vec2(1.0, 0.0) : vec2(0.0, 1.0)));
    return vec2(gq.x, -gq.y);
}

vec4 perimNear(vec2 q, vec2 hs) {
    vec2 w = abs(q) - hs + vec2(radius);
    if (max(w.x, w.y) < 0.0)
        q = w.x > w.y ? vec2((q.x >= 0.0 ? 1.0 : -1.0) * hs.x, q.y) : vec2(q.x, (q.y >= 0.0 ? 1.0 : -1.0) * hs.y);
    return perim(q, max(hs - vec2(radius), vec2(0.0)), radius + SM);
}
