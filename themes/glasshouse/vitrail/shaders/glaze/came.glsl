float edgeOf(vec2 p, out vec2 n) {
    vec2 f = fract(latOf(p)) - 0.5;
    vec2 e = (0.5 - abs(f)) / slope();
    vec2 gr = grid / box.zw;
    n = e.x < e.y ? sign(f.x) * normalize(gr) : sign(f.y) * normalize(vec2(gr.x, -gr.y));
    return min(e.x, e.y);
}

vec4 flush(vec4 layer, float cov) {
    vec3 fire = mix(gold, hot, 0.35);
    vec3 add = vec3(1.0) * (1.0 - exp(-1.2 * core)) + fire * (1.0 - exp(-halo)) * 1.4 + lampHue * (1.0 - exp(-shine));
    vec4 glow = vec4(ink > 0.5 ? mix(leaf, vec3(1.0), 0.25) * (1.4 * (1.0 - exp(-1.2 * core)) + 1.5 * (1.0 - exp(-halo))) + lampHue * (1.0 - exp(-shine)) : add, 0.0);
    float ac = 0.92 * (1.0 - exp(-1.4 * core));
    float ag = 0.8 * (1.0 - exp(-1.2 * halo));
    vec4 drawnInk = vec4(mix(sepia, gold, 0.2) * ac, ac) + vec4(leaf * ag, ag) * (1.0 - ac) + vec4(lampHue * 0.35 * (1.0 - exp(-shine)), 0.0);
    core = 0.0;
    halo = 0.0;
    shine = 0.0;
    return over(mix(glow, drawnInk, inked) * cov, layer * cov);
}

vec4 leadOf(vec2 p, float strength, float lit, float glint, float gloss) {
    if (strength <= 0.0)
        return vec4(0.0);
    vec2 n;
    float d = edgeOf(p, n);
    float w = CAME * scale;
    float cov = (1.0 - smoothstep(w - 0.75, w + 0.75, d)) * strength;
    float facing = max(-dot(n, normalize(lamp - p)), 0.0);
    shine += (sq(facing) * exp(-sq((d - w) / (0.6 * scale))) * gloss + glint * exp(-d / (2.0 * scale)) * 0.45) * strength;
    core += lit * cov * 0.12;
    halo += lit * exp(-d / (3.0 * scale)) * 0.15 * strength;
    return vec4(leadLow * DARK * cov, DARK * cov);
}

vec4 beadOf(vec2 p, float strength) {
    vec2 r = floor(latOf(p) + 0.5);
    vec2 J = knot(r);
    float R = BEAD * scale;
    if (hullOf(J) > -2.0 * R)
        return vec4(0.0);
    float b = floor(bandOf(J) + 0.5);
    float age = t - (b > grid.y - 0.5 ? weld.x : landOf(b));
    if (age < 0.0)
        return vec4(0.0);
    float tg = frontOf(J);
    float gone = live > 0.5 ? 1.0 - smoothstep(tg + DISSOLVE, tg + DISSOLVED, t) : 1.0;
    if (gone <= 0.0)
        return vec4(0.0);
    float d = length(p - J);
    float dab = unit(R + 0.5 - d);
    float heat = exp(-age / 22.0);
    float reflash = live > 0.5 && t >= tg ? 1.5 * exp(-(t - tg) / 18.0) : 0.0;
    core += (1.6 * heat + 0.25 * reflash) * dab * gone;
    halo += (0.6 * heat + 0.5 * reflash) * exp(-d / (4.0 * scale)) * gone;
    shine += exp(-sq(length(p - J - 0.45 * R * normalize(lamp - J)) / (0.7 * scale))) * (0.05 + 0.6 * heat) * gone * max(strength, LEADED);
    float a = DARK * dab * gone * max(strength, LEADED);
    return vec4(leadLow * a, a);
}
