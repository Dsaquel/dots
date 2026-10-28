float frontOf(vec2 p) {
    float d = 1e9;
    for (int i = 0; i < 4; ++i) {
        if (float(i) >= gated)
            break;
        vec2 e = gates[i].zw - gates[i].xy;
        vec2 q = p - gates[i].xy;
        d = min(d, length(q - e * clamp(dot(q, e) / max(dot(e, e), 1e-6), 0.0, 1.0)));
    }
    return ring.y + ring.z * (1.0 - pow(1.0 - clamp(d / ring.x, 0.0, 1.0), 1.0 / 3.0));
}
