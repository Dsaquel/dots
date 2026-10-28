vec4 shotOf(int slot, vec2 uv, float lod) {
    if (slot == 0)
        return textureLod(shot0, uv, lod);
    if (slot == 1)
        return textureLod(shot1, uv, lod);
    if (slot == 2)
        return textureLod(shot2, uv, lod);
    if (slot == 3)
        return textureLod(shot3, uv, lod);
    return vec4(0.0);
}

float exitOf(float p, float v, float lo, float hi) {
    return v > 1e-6 ? (hi - p) / v : (v < -1e-6 ? (lo - p) / v : 1e9);
}

float hallDepth(float t) {
    return depthOf(pathT0 + t);
}

vec3 hallFog(vec3 c, float depth) {
    return mix(c, fogColor, fogOf(depth));
}

vec3 lanternAt(int i, int side) {
    return vec3(side == 0 ? -3.4 * casing : size.x + 3.4 * casing, 0.36 * size.y, doorZ[i] - wall - 0.9 * casing);
}

vec3 hallLight(vec3 Q, vec3 N) {
    vec3 L = lamp - Q;
    float dl = length(L);
    vec3 c = ambient + mix(hot, vec3(1.0), 0.35) * 0.12 * max(dot(N, L / dl), 0.0) / (1.0 + sq(dl / (2.4 * rest)));
    for (int i = 0; i < DOORS; ++i) {
        if (i >= doorsN)
            break;
        float reach = 1.0 - smoothstep(1.8 * rest, 2.8 * rest, abs(doorZ[i] - Q.z));
        if (reach <= 0.0)
            continue;
        vec3 G = vec3(clamp(Q.xy, vec2(0.0), size), doorZ[i]) - Q;
        float dg = max(length(G), 1.0);
        c += screenTint * doorLight[i] * 1.4 * reach * max(dot(N, G / dg), 0.0) / (1.0 + sq(dg / (0.5 * rest)));
        if (Q.z > doorZ[i] - wall + 1.0 || doorLit[i] < 0.001)
            continue;
        for (int k = 0; k < 2; ++k) {
            vec3 F = lanternAt(i, k) - Q;
            float df = max(length(F), 1.0);
            c += flame * doorLit[i] * lanternGain * reach * max(dot(N, F / df) * 0.8 + 0.2, 0.0) / (1.0 + sq(df / (0.4 * rest)));
        }
    }
    return c;
}

vec4 lantern(int i, int k, vec3 ro, vec3 rd, float tMax, out float tHit) {
    tHit = -1.0;
    vec3 C = lanternAt(i, k);
    float t = (C.z - ro.z) / rd.z;
    if (t <= 0.0 || t >= tMax)
        return vec4(0.0);
    vec2 q = ro.xy + rd.xy * t - C.xy;
    float cw = casing;
    float px = max(hallDepth(t) / focal, 1e-3);
    float lit_ = doorLit[i];
    float body = max(abs(q.x) - 0.42 * cw * (1.0 - 0.25 * sq(q.y / cw)), abs(q.y) - 0.78 * cw);
    float cap = max(abs(q.x) - 0.5 * cw * (1.0 - 0.6 * clamp((-q.y - 0.78 * cw) / (0.32 * cw), 0.0, 1.0)), abs(q.y + 0.94 * cw) - 0.16 * cw);
    float foot = max(abs(q.x) - 0.36 * cw, abs(q.y - 0.86 * cw) - 0.1 * cw);
    float chain = max(abs(q.x) - 0.05 * cw, abs(q.y + 1.6 * cw) - 0.5 * cw);
    float metal = min(min(cap, foot), chain);
    float cb = clamp(0.5 - body / px, 0.0, 1.0);
    float cm = clamp(0.5 - metal / px, 0.0, 1.0);
    float cov = max(cb, cm);
    if (cov <= 0.0)
        return vec4(0.0);
    tHit = t;
    float core = exp(-dot(q, q) / sq(0.32 * cw));
    float pane = 1.0 - smoothstep(0.6 * px, 1.6 * px, abs(q.x));
    vec3 glassC = flame * (0.35 + 0.65 * lit_) * (0.55 + 0.45 * (1.0 - abs(q.y) / cw)) + mix(flame, vec3(1.0), 0.6) * core * (0.4 + 1.6 * lit_);
    glassC = mix(glassC, glassC * 0.45, pane * 0.6);
    vec3 metalC = leadLow * 1.2 + keyline * 0.25 * (0.4 + 0.6 * lit_) * (0.5 + 0.5 * sin(q.x / cw * 3.0 + 1.0));
    vec3 c = mix(glassC * cb, metalC, cm);
    return vec4(hallFog(c, hallDepth(t)), 1.0) * cov;
}

vec3 halo(int i, int k, vec3 ro, vec3 rd, float tMax) {
    vec3 C = lanternAt(i, k);
    float t = dot(C - ro, rd);
    if (t <= 0.0 || t > tMax || doorLit[i] < 0.001)
        return vec3(0.0);
    float r = length(ro + rd * t - C) / casing;
    float g = 0.5 * exp(-sq(r / 1.3)) + 0.16 * exp(-r / 4.5);
    return flame * doorLit[i] * g * (1.0 - fogOf(hallDepth(t)) * 0.7);
}
