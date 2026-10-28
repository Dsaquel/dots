void ring(vec2 p) {
    float sd = hullOf(p);
    if (sd < -2.0 * scale || sd > (RIM + 30.0) * scale)
        return;
    float a = (t - frontOf(p)) / weld.z;
    if (a < 0.0 || a > 1.0)
        return;
    float r = (HEM + RIM * (1.0 - sq(1.0 - a))) * scale;
    float d = abs(sd - r);
    float fade = (1.0 - a) * smoothstep(0.0, 0.06, a);
    core += exp(-sq(d / ((1.1 + 0.5 * ink) * scale))) * fade * 1.6 * (1.0 - ink);
    halo += (exp(-sq(d / (3.0 * scale))) * 0.8 + exp(-d / (8.0 * scale)) * 0.15) * fade * (1.0 - 0.6 * ink);
}

vec4 ringInk(vec2 p) {
    if (ink < 0.5)
        return vec4(0.0);
    float sd = hullOf(p);
    float a = (t - frontOf(p)) / weld.z;
    if (a < 0.0 || a > 1.0)
        return vec4(0.0);
    float x = sd - (HEM + RIM * (1.0 - sq(1.0 - a))) * scale;
    float fade = (1.0 - a) * smoothstep(0.0, 0.06, a);
    float body = unit(BODY * scale + 0.5 - abs(x)) * fade;
    float keyline = unit(KEYLINE * scale + 0.5 - abs(x - (BODY + 0.5 * KEYLINE) * scale)) * fade;
    vec4 rim = vec4(sepia, 1.0) * keyline * 0.9;
    return over(vec4(mix(leaf, gold, 0.4), 1.0) * body * 0.95, rim);
}

vec4 overlay(vec2 p) {
    vec4 acc = vec4(0.0);
    float cov = unit(0.5 - hullOf(p));
    if (cov > 0.0) {
        float tg = frontOf(p);
        float gone = 1.0 - smoothstep(tg + DISSOLVE, tg + DISSOLVED, t);
        float strength = mix(1.0, LEADED, unit((t - landOf(courseOf(bandOf(p)))) / COOLED)) * gone;
        vec2 flash = flashOf(p);
        vec4 layer = leadOf(p, strength, (flash.x + flash.y) * gone * clamp(box.w / grid.y / (100.0 * scale), 0.4, 1.0), 0.0, GLOSS);
        halo += BASE * flash.x + BLOOM * gatedOf(frontOf(knot(floor(latOf(p)) + 0.5)));
        acc = flush(over(beadOf(p, strength), layer), cov);
    }
    ring(p);
    return over(flush(ringInk(p), 1.0), acc);
}
