float ringAt(vec2 p) {
    float d = 1e9;
    for (int i = 0; i < 4; ++i) {
        if (float(i) >= gated)
            break;
        vec2 e = gates[i].zw - gates[i].xy;
        vec2 g = p - gates[i].xy;
        d = min(d, length(g - e * unit(dot(g, e) / max(dot(e, e), 1e-6))));
    }
    d = gated > 0.5 ? d : length(p - hand.xy);
    return ring.y + ring.z * (1.0 - pow(1.0 - unit(d / ring.x), 1.0 / 3.0));
}

vec2 rimOf(vec4 b, float a, out vec2 n) {
    float x = a * 2.0 * (b.z + b.w);
    if (x < b.z) {
        n = vec2(0.0, -1.0);
        return b.xy + vec2(x, 0.0);
    }
    x -= b.z;
    if (x < b.w) {
        n = vec2(1.0, 0.0);
        return b.xy + vec2(b.z, x);
    }
    x -= b.w;
    if (x < b.z) {
        n = vec2(0.0, 1.0);
        return b.xy + vec2(b.z - x, b.w);
    }
    n = vec2(-1.0, 0.0);
    return b.xy + vec2(0.0, b.w - x + b.z);
}

float laneOf(float x) {
    float u = (x - goal.x) / goal.z;
    float m = 0.0;
    for (int k = 0; k < 8; ++k) {
        if (float(k) >= lanes)
            break;
        float c = (float(k) + 0.5 + 0.6 * (fract(sin(float(k) * 12.9898 + seed * 78.233) * 43758.5453) - 0.5)) / lanes;
        m = max(m, exp(-sq((u - c) * grid.x / 0.6)));
    }
    return m;
}

vec2 posOf(vec2 j) {
    vec2 m = junction(j);
    return gated > 0.5 ? m : landed(m);
}

bool fed(vec2 c, float tc, vec2 o) {
    float lit[4];
    float n = 0.0;
    for (int i = 0; i < 4; ++i) {
        lit[i] = ringAt(posOf(c + stepOf(i)));
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

vec3 glowOf(float heat) {
    vec3 c = mix(vec3(0.35, 0.03, 0.0), vec3(1.0, 0.25, 0.04), smoothstep(0.05, 0.3, heat));
    c = mix(c, vec3(1.0, 0.62, 0.18), smoothstep(0.25, 0.5, heat));
    c = mix(c, vec3(1.0, 0.9, 0.55), smoothstep(0.45, 0.75, heat));
    return mix(c, vec3(1.0, 0.98, 0.92), smoothstep(0.7, 1.0, heat));
}
