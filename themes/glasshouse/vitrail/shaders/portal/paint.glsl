float sdSegment(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a;
    vec2 ba = b - a;
    return length(pa - ba * clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0));
}

float line(float d, float w) {
    return clamp(w - abs(d) + 0.5, 0.0, 1.0);
}

vec3 emit(vec3 b, vec3 e) {
    vec3 t_ = min(b, vec3(1.0));
    vec3 u = t_ + e;
    vec3 h = max(0.3 + 0.2 * u / max(max(max(u.r, u.g), u.b), 1e-3) - 0.5 * t_, 1e-3);
    return b + min(e, h) + h * max(e - h, 0.0) / max(e, h);
}
