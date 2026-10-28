vec2 extOf(vec2 q, vec2 c) {
    return vec2(q.x >= 0.0 ? hull.x + hull.z - c.x : c.x - hull.x, q.y >= 0.0 ? hull.y + hull.w - c.y : c.y - hull.y);
}

vec2 normOf(vec2 p, vec2 c) {
    return (p - c) / extOf(p - c, c);
}

vec2 denorm(vec2 n, vec2 c) {
    return c + n * extOf(n, c);
}

vec2 hubOf(float a) {
    return mix(hubs.xy, hubs.zw, clamp(a / (0.5 * PI), 0.0, 1.0));
}

float fitOf(float a) {
    return 1.0 / (abs(cos(a)) + abs(sin(a)));
}

vec2 turned(vec2 n, float a) {
    float c = cos(a);
    float s = hand.w * sin(a);
    return vec2(n.x * c - n.y * s, n.x * s + n.y * c);
}

float ringOf(vec2 n) {
    return max(abs(n.x), abs(n.y));
}

mat2 rot(float a) {
    return mat2(cos(a), sin(a), -sin(a), cos(a));
}

vec2 stepOf(int i) {
    return i == 0 ? vec2(1.0, 0.0) : i == 1 ? vec2(-1.0, 0.0) : i == 2 ? vec2(0.0, 1.0) : vec2(0.0, -1.0);
}

vec2 landed(vec2 m) {
    vec2 n = normOf(m, hubs.xy);
    return denorm(hand.w * vec2(-n.y, n.x), hubs.zw);
}
