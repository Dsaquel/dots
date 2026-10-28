float veiled(vec2 p, float d) {
    if (view.w < 0.5 || (bridge > 0.5 && (p.x < 0.0 || p.y < 0.0 || p.x > target.x || p.y > target.y)))
        return 1.0;
    float sp = sin(view.y);
    float cp = cos(view.y);
    float dx = p.x - lens.x;
    float m = 1.0;
    for (int s = 0; s < 2; ++s) {
        bool left = s == 0;
        float den = left ? dx * sp - lens.z * cp : dx * sp + lens.z * cp;
        if (abs(den) < 1e-4)
            continue;
        float a = (((left ? 0.0 : target.x) - lens.x) * lens.z - dx * (lens.z - view.x)) / den;
        float e = a * sp + lens.z - view.x;
        float Y = lens.y + (p.y - lens.y) * e / lens.z;
        if (a >= 0.0 && a <= (left ? view.z : target.x - view.z) && e > 1.0 && e < d - 2.0 && Y >= 0.0 && Y <= target.y)
            m = min(m, mix(1.0, 0.3, smoothstep(lens.z * 0.04, lens.z * 0.3, e)));
    }
    return m;
}

float grown(float x) {
    return 1.0 - pow(1.0 - unit(x / SPREAD), 2.4);
}

vec2 fuseAt(float f) {
    float a = TAU * f;
    return entry + SMALL * min(slot.z, slot.w) * vec2(-sin(a), cos(a));
}
