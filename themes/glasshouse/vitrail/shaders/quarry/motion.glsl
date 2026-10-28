vec2 midOf(float iu, float iv) {
    return vec2((iu + iv + 1.0) / grid.x, (iu - iv) / grid.y) * 0.5;
}

vec2 at(vec2 p, float a) {
    return denorm(rot(hand.w * a) * normOf(p, hubs.xy) * fitOf(a), hubOf(a));
}

float easeOf(float k) {
    return EASE * k + (1.0 - EASE) * k * k;
}

float progress(float r, float t) {
    float go = swing.x + swing.z * r;
    return unit((t - go) / (swing.y - go));
}

float drawnOf(float r, float at) {
    float go = swing.x + swing.z * r;
    return ahead > 0.0 ? 0.0 : (at < go ? smoothstep(ahead, go, at) : 1.0 - smoothstep(0.0, 1.0, progress(r, at)));
}

float riftOf(vec2 S, float j) {
    if (ahead > 0.0)
        return -1e9;
    vec2 inset = min(S - box.xy, box.xy + box.zw - S);
    return ahead + rift * pow(unit(min(inset.x, inset.y) / max(0.5 * min(box.z, box.w), 1.0)), 0.8) + 12.0 * (j - 0.5);
}

float angleOf(float r, float t) {
    float f = clamp(r, 0.0, 1.0) * 8.0;
    int i = min(int(f), 7);
    float k = progress(r, t);
    float k0 = progress(r, ahead);
    float e = 1.0 - k * k;
    return 0.5 * PI * (1.0 - e) + mix(skew[i], skew[i + 1], f - float(i)) * e / max(1.0 - k0 * k0, 1e-3) - WIND * drawnOf(r, t);
}

float spanOf(vec2 p) {
    return min(length(normOf(p, hubs.xy)) * SPAN, 1.0);
}

float liftOf(float tc, float tl, float at) {
    float up = ahead > 0.0 ? 1.0 : outBack(unit((at - tc) / POP));
    return up * (1.0 - pow(1.0 - unit((tl - at) / SINK), 1.6));
}

float climbOf(float tc, float go, float tl, float at) {
    if (ahead > 0.0)
        return liftOf(tc, tl, at);
    float up = UNSEAT * outBack(unit((at - tc) / POP)) + (1.0 - UNSEAT) * smoothstep(tc + 0.5 * POP, go, at);
    return up * (1.0 - pow(1.0 - unit((tl - at) / SINK), 1.6));
}

float frontOf(vec2 p) {
    float d = 1e9;
    for (int i = 0; i < 4; ++i) {
        if (float(i) >= gated)
            break;
        vec2 e = gates[i].zw - gates[i].xy;
        vec2 q = p - gates[i].xy;
        d = min(d, length(q - e * unit(dot(q, e) / max(dot(e, e), 1e-6))));
    }
    return ring.y + ring.z * (1.0 - pow(1.0 - unit(d / ring.x), 1.0 / 3.0));
}
