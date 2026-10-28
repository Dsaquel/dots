float easeOf(float k) {
    k = unit(k);
    return 0.3 * k + 0.7 * k * k;
}

float outBack(float k) {
    k = unit(k) - 1.0;
    return 1.0 + 2.70158 * k * k * k + 1.70158 * k * k;
}

float sdRound(vec2 q, vec2 h, float r) {
    vec2 d = abs(q) - h + r;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - r;
}

vec4 over(vec4 top, vec4 under) {
    return top + under * (1.0 - top.a);
}

vec4 tap(vec2 px) {
    return texture(tex, px / texSize);
}

float lumaOf(vec4 c) {
    return c.a > 0.004 ? dot(c.rgb / c.a, vec3(0.299, 0.587, 0.114)) : 0.0;
}
