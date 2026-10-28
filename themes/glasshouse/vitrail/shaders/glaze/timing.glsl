float beatOf(float c, vec4 at) {
    return at.x + at.y * (1.0 - pow(at.z, c / max(grid.y - 1.0, 1.0))) / (1.0 - at.z);
}

float landOf(float c) {
    return beatOf(c, seat);
}

float fallOf(float c) {
    return clamp(FALLS * (c < 0.5 ? landOf(1.0) - landOf(0.0) : landOf(c) - landOf(c - 1.0)), FALLMIN, FALLMAX);
}

float leaveOf(float c) {
    return beatOf(c, lift);
}

float frontOf(vec2 p) {
    return weld.x + weld.y * (1.0 - pow(1.0 - unit((box.y + box.w - p.y) / (weld.w * box.w)), 1.0 / 3.0));
}

float crackOf(vec2 p) {
    vec2 q = abs(p - box.xy - 0.5 * box.zw) / (0.5 * box.zw);
    return CRACK * pow(1.0 - unit(max(q.x, q.y)), 0.8);
}

float gatedOf(float tg) {
    return smoothstep(tg - 6.0, tg, t) * (1.4 * exp(-max(t - tg, 0.0) / 22.0) + 0.5 * exp(-max(t - tg, 0.0) / 110.0));
}

vec2 flashOf(vec2 p) {
    float ti = t - weld.x;
    if (ti < 0.0)
        return vec2(0.0);
    return vec2(0.5 * exp(-ti / 22.0), gatedOf(frontOf(p)));
}
