vec2 uvOf(vec2 p) {
    return (p - box.xy) / box.zw * grid;
}

vec2 latOf(vec2 p) {
    vec2 uv = uvOf(p);
    return vec2(uv.x + uv.y, uv.x - uv.y);
}

vec2 knot(vec2 j) {
    return box.xy + 0.5 * vec2(j.x + j.y, j.x - j.y) / grid * box.zw;
}

float slope() {
    return length(grid / box.zw);
}

float bandOf(vec2 p) {
    vec2 uv = uvOf(p);
    return uv.y - abs(fract(uv.x + 0.5) - 0.5);
}

float courseOf(float k) {
    return clamp(floor(k), 0.0, grid.y - 1.0);
}

float hullOf(vec2 p) {
    return sdRound(p - box.xy - 0.5 * box.zw, 0.5 * box.zw, radius);
}

float within(vec2 p, float c) {
    float k = bandOf(p);
    float top = c < 0.5 ? 1e6 : (k - c) / slope();
    float bottom = c > grid.y - 1.5 ? 1e6 : (c + 1.0 - k) / slope();
    return min(min(top, bottom), -hullOf(p));
}

vec2 middleOf(float c) {
    return vec2(box.x + 0.5 * box.z, box.y + 0.5 * (max(c, 0.0) + min(c + 1.5, grid.y)) / grid.y * box.w);
}

vec2 castOf(vec2 m) {
    return normalize(vec2(0.6 * clamp((m.x - lamp.x) / (0.5 * box.z), -1.0, 1.0), 1.0));
}
