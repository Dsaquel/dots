float knotOf(vec2 key, float b, float i) {
    return 2.0 * hash4(key * vec2(1.37, 0.71) + vec2(3.17 * i + 11.3 * b, 5.9 * b - 1.13 * i)).x - 1.0;
}

vec2 zig(vec2 key, float b, float s, float span) {
    float x = s / span;
    float i = floor(x);
    float a = knotOf(key, b, i);
    float c = knotOf(key, b, i + 1.0);
    return vec2(mix(a, c, x - i), (c - a) / span);
}

vec2 pathOf(vec2 key, float b, float along, float len, float amp) {
    float env = sqrt(sin(PI * clamp(along / max(len, 1.0), 0.0, 1.0)));
    vec2 z = zig(key, b, along, ZAG * scale) + 0.35 * zig(key + 7.7, b, along, 0.37 * ZAG * scale);
    return amp * scale * env * z;
}

float laneOf(float x) {
    float u = (x - frame.x) / frame.z;
    float m = 0.0;
    for (int k = 0; k < 8; ++k) {
        if (float(k) >= lanes)
            break;
        float c = (float(k) + 0.5 + 0.6 * (fract(sin(float(k) * 12.9898 + seed * 78.233) * 43758.5453) - 0.5)) / lanes;
        m = max(m, exp(-sq((u - c) * grid.x / 0.6)));
    }
    return m;
}

bool fed(vec2 c, float tc, vec2 o) {
    float lit[4];
    float n = 0.0;
    for (int i = 0; i < 4; ++i) {
        lit[i] = ignite(c + stepOf(i));
        n += lit[i] < tc ? 1.0 : 0.0;
    }
    float k = floor(hash4(c * vec2(0.917, 1.311) + 23.0).x * n);
    for (int i = 0; i < 4; ++i) {
        if (lit[i] >= tc)
            continue;
        if (k < 0.5)
            return all(equal(c + stepOf(i), o));
        k -= 1.0;
    }
    return false;
}
