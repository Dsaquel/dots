float span(float x, float a, float b) {
    return unit((x - a) / (b - a));
}

float soft(float k) {
    k = unit(k);
    return k * k * (3.0 - 2.0 * k);
}

float burnHash(vec2 p) {
    return fract(sin(dot(p + burnSeed, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 x) {
    vec2 i = floor(x);
    vec2 f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(burnHash(i), burnHash(i + vec2(1.0, 0.0)), f.x), mix(burnHash(i + vec2(0.0, 1.0)), burnHash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float release(vec2 p) {
    vec2 x = (p - (away - fired)) / scale * 0.022;
    float n = 0.55 * vnoise(x) + 0.3 * vnoise(x * 2.9 + 13.1) + 0.15 * vnoise(x * 7.3 + 5.7);
    float y = clamp((p.y - burn.x) / max(burn.y, 1.0), 0.0, 1.0);
    return mix(burn.z, burn.w, y) + (n - 0.5) * 90.0;
}
