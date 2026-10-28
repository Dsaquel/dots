vec3 flatOf(vec2 p) {
    if (view.w < 0.5)
        return vec3(p, 1.0);
    if (forward > 0.5)
        return vec3(lens.xy + (p - lens.xy) * ((lens.w + lens.z - view.x) / lens.z), 1.0);
    float sp = sin(view.y);
    float cp = cos(view.y);
    float dx = p.x - lens.x;
    vec3 best = vec3(0.0);
    float nearest = 1e9;
    for (int s = 0; s < 2; ++s) {
        bool left = s == 0;
        float den = left ? dx * sp - lens.z * cp : dx * sp + lens.z * cp;
        if (abs(den) < 1e-4)
            continue;
        float a = (((left ? 0.0 : target.x) - lens.x) * lens.z - dx * (lens.z - view.x)) / den;
        float d = a * sp + lens.z - view.x;
        if (a < 0.0 || a > (left ? view.z : target.x - view.z) || d < 1.0 || d > nearest)
            continue;
        nearest = d;
        best = vec3(left ? a : target.x - a, lens.y + (p.y - lens.y) * d / lens.z, smoothstep(lens.z * 0.04, lens.z * 0.3, d));
    }
    return best;
}

float span(float x, float a, float b) {
    return clamp((x - a) / (b - a), 0.0, 1.0);
}
