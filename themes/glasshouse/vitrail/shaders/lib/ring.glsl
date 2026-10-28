float ringAt(float k, float lo) {
    float u = clamp((k - OPEN0) / (OPEN1 - OPEN0), 0.0, 1.0);
    return lo * mix(SMALL, WIDE, 1.0 - pow(1.0 - u, 4.0));
}

float lapsAt(float k) {
    k = clamp(k, 0.0, SEAT);
    return k < SLING ? k / SLING : 1.0 + (k - SLING) / SPIN;
}

float mouthAt(float k, float lo) {
    return ringAt(k, lo) * (1.0 + WREATH * smoothstep(LOCK, SWALLOW, k));
}

float turnAt(float k) {
    k = clamp(k / SEAT, 0.0, 1.0);
    return PI * (k - 0.3 * k * k) / 0.7;
}

vec3 fire(float h) {
    vec3 c = mix(vec3(0.38, 0.05, 0.01), vec3(0.96, 0.34, 0.05), smoothstep(0.0, 0.35, h));
    c = mix(c, mix(jewelC, vec3(1.0, 0.66, 0.16), 0.6), smoothstep(0.3, 0.65, h));
    c = mix(c, mix(hot, vec3(1.0, 0.86, 0.5), 0.5), smoothstep(0.6, 0.95, h));
    return mix(c, vec3(1.0, 0.97, 0.88), smoothstep(0.95, 1.4, h));
}
