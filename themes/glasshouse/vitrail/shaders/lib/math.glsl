float sq(float x) {
    return x * x;
}

float unit(float x) {
    return clamp(x, 0.0, 1.0);
}

float sdRoundBox(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b + vec2(r);
    return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}
