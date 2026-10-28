vec2 bez(vec2 a, vec2 b, vec2 c, vec2 d, float k) {
    float l = 1.0 - k;
    return l * l * l * a + 3.0 * l * l * k * b + 3.0 * l * k * k * c + k * k * k * d;
}

vec2 origin() {
    return shot.xy + shot.zw * vec2(0.5, 0.14);
}

vec2 sighted() {
    return forward > 0.5 ? lens.xy + (entry - lens.xy) * (lens.z / (lens.w + lens.z)) : entry;
}

vec2 doorway() {
    vec2 a0 = origin();
    vec2 e0 = sighted();
    float x = forward > 0.5 ? lens.x : mix(a0.x, e0.x, 0.5);
    return vec2(x, clamp(min(e0.y - 0.3 * target.y, a0.y + 0.05 * target.y), 0.12 * target.y, 0.5 * target.y));
}

float side() {
    float dx = doorway().x - origin().x;
    return abs(dx) > 0.02 * target.x ? sign(dx) : sign(sighted().x - doorway().x + 1e-3);
}

vec2 crest() {
    vec2 Q = doorway();
    return vec2(Q.x - side() * min(0.15 * target.x, 0.6 * abs(Q.x - origin().x)), max(0.04 * target.y, min(origin().y, Q.y) - 0.18 * target.y));
}

vec2 inward() {
    vec2 d = seam.zw - seam.xy;
    vec2 n = normalize(vec2(d.y, -d.x));
    return dot(entry - seam.xy, n) < 0.0 ? -n : n;
}

vec2 crossing() {
    vec2 d = seam.zw - seam.xy;
    float len = max(length(d), 1.0);
    vec2 a0 = origin();
    vec2 aim = vec2(mix(a0.x, entry.x, 0.5), clamp(min(entry.y - 0.3 * target.y, a0.y + 0.05 * target.y), 0.12 * target.y, 0.5 * target.y));
    return seam.xy + d / len * clamp(dot(aim - seam.xy, d / len), 0.1 * len, 0.9 * len);
}

vec2 arc(vec2 Q) {
    vec2 a0 = origin();
    vec2 n = inward();
    vec2 P = Q - n * min(0.15 * target.x, 0.6 * abs(dot(Q - a0, n)));
    return abs(n.x) > 0.5 ? vec2(P.x, max(0.04 * target.y, min(a0.y, Q.y) - 0.18 * target.y)) : P;
}
