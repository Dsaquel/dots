vec3 eye() {
    return vec3(centre, cam - focal);
}

vec3 lamp() {
    return vec3(centre + (lightPos.xy - centre) * 2.5, -focal * 0.55);
}

vec3 lit(vec3 n, vec3 Q, float ao) {
    vec3 L = normalize(lamp() - Q);
    vec3 V = normalize(eye() - Q);
    float diff = max(dot(n, L), 0.0);
    float spec = pow(max(dot(n, normalize(L + V)), 0.0), 36.0);
    float sky = clamp(0.5 - 0.5 * n.y, 0.0, 1.0);
    return (leadLow * 0.45 + leadBase * (0.3 + diff) * mix(0.75, 1.15, sky) + leadHi * spec * 0.8) * ao;
}

vec3 molding(float a, float w, vec3 N, vec3 T, vec3 Q, float px, float rich) {
    float h = profile(a, rich);
    float dh = clamp((profile(a + 0.008, rich) - profile(a - 0.008, rich)) / 0.016, -8.0, 8.0);
    vec3 c = lit(normalize(N - T * dh * 0.45), Q, mix(0.5, 1.0, h));
    float rim = 1.0 - smoothstep(0.0, 1.6 * px, min(a, 1.0 - a) * w);
    return mix(c, ink > 0.5 ? sepia : leadLow, rim * 0.7);
}
