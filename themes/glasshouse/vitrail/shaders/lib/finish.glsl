void add(vec3 tint, float e) {
    L += tint * e;
    E += e;
}

vec4 finish(float gain) {
    if (ink < 0.5)
        return vec4(L * gain, 0.0);
    float a = clamp(E * gain * 0.55, 0.0, 0.88);
    vec3 c = E > 1e-4 ? L / E : leaf;
    return vec4(mix(leaf, c * leaf * 1.4, 0.3) * a, a);
}
