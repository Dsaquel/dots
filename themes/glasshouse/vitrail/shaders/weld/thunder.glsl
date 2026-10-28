float around(vec2 q, vec2 size) {
    vec2 d = min(q, size - q);
    if (d.y < d.x)
        return q.y < 0.5 * size.y ? q.x : 2.0 * size.x + size.y - q.x;
    return q.x > 0.5 * size.x ? size.x + q.y : 2.0 * (size.x + size.y) - q.y;
}

void link(float k, float along, float sd, float seg, float lit) {
    vec2 key = vec2(k, 1000.0);
    float age = t - lit;
    vec4 g = hash4(key * 1.618 + 3.1);
    float dt = FLICK + JIT * g.x;
    float b = floor(t / dt + g.y);
    float tb = max((b - g.y) * dt, lit);
    vec4 hb = hash4(key + vec2(7.13 * b, -3.71 * b) + 0.5);
    bool struck = g.z > CHARGED && hb.y < STRIKE;
    float e = (1.0 - smoothstep(0.4 * RIMMED, RIMMED, age)) * (hb.x < DARKS ? 0.2 : 0.65 + 0.6 * hb.z) * (struck ? 1.8 : 1.0) * (0.7 + 0.3 * exp(-(t - tb) / 6.0)) + 1.4 * exp(-age / 10.0);
    arc(key, b, tb, along * scale, -sd, seg * scale, seg * scale, seg * scale, e, hb, struck);
}

void rim(vec2 p, float lit) {
    vec2 q = p - win.xy;
    float sd = sdRoundBox(q - 0.5 * win.zw, 0.5 * win.zw, radius);
    if (abs(sd) > REACH * scale || t < lit || t > lit + RIMMED)
        return;
    float total = 2.0 * (win.z + win.w) / scale;
    float m = max(floor(total / LINK + 0.5), 4.0);
    float seg = total / m;
    float s = around(q, win.zw) / scale;
    float k = floor(s / seg);
    float f = s - k * seg;
    float side = f > 0.5 * seg ? 1.0 : -1.0;
    link(mod(k, m), f, sd, seg, lit);
    link(mod(k + side, m), f - side * seg, sd, seg, lit);
}

vec4 thunder(vec2 p, float lit) {
    rim(p, lit);
    vec2 n = ((turn > 0.5 ? source(p) : p) - frame.xy) / frame.zw;
    float inside = clamp(0.5 - sdRoundBox(p - win.xy - 0.5 * win.zw, 0.5 * win.zw, radius), 0.0, 1.0);
    if (inside > 0.0 && (turn < 0.5 || (n.x >= 0.0 && n.y >= 0.0 && n.x <= 1.0 && n.y <= 1.0))) {
        float c0 = core;
        float h0 = halo;
        vec2 g = vec2(n.x * grid.x + n.y * grid.y, n.x * grid.x - n.y * grid.y);
        vec2 f = floor(g);
        vec2 r = floor(g + 0.5);
        crackle(vec2(r.x, f.y), vec2(r.x, f.y + 1.0), vec2(2.0 * r.x + 1.0, f.y), p);
        crackle(vec2(f.x, r.y), vec2(f.x + 1.0, r.y), vec2(2.0 * f.x, r.y), p);
        float age = t - ignite(r);
        if (age > 0.0)
            flare(p - junction(r), 1.8 * exp(-age / 18.0) * (lanes > 0.5 ? laneOf(junction(r).x) : 1.0));
        core = c0 + (core - c0) * inside;
        halo = h0 + (halo - h0) * inside;
    }
    vec3 volt = ink > 0.5 ? mix(leaf, vec3(1.0), 0.25) : mix(mix(jewel0, jewel1, 0.5), vec3(1.0), 0.3);
    vec4 shone = vec4(vec3(1.0) * min(core, 2.5) * 1.3 + volt * min(halo, 2.5) * 1.6, 0.0);
    float ac = clamp(core * 1.4, 0.0, 0.95);
    float ag = clamp(halo * 1.1, 0.0, 0.8);
    vec4 inked = vec4(mix(sepia, keyline, 0.2) * ac, ac) + vec4(leaf * ag, ag) * (1.0 - ac);
    vec4 c = knee > 0.5 ? texture(under, p / underSize) : vec4(1.0);
    float l = c.a > 0.004 ? dot(c.rgb / c.a, vec3(0.299, 0.587, 0.114)) : 1.0;
    return mix(shone, inked, ink * smoothstep(0.35, 0.6, l));
}
