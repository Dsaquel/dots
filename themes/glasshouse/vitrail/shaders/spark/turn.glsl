void turnSparks(float s, vec2 q) {
    float tip = mod(s, 2.0);
    float j = floor(s / 2.0);
    vec4 g = hash4(vec2(j * 1.37 + tip * 5.3, j * 0.71 - tip * 3.1));
    vec3 hotter = ink > 0.5 ? mix(sepia, leaf, 0.7) : mix(hot, vec3(1.0), 0.35);
    if (kind < 4.5) {
        float side = mod(s, 4.0);
        float jc = floor(s / 4.0);
        vec4 gc = hash4(vec2(jc * 1.37 + side * 5.3, jc * 0.71 - side * 3.1));
        vec2 e = vec2(side == 0.0 || side == 3.0 ? 1.0 : -1.0, side < 2.0 ? 1.0 : -1.0);
        float k = turnInv((jc + gc.x) / (0.5 * SPRAY));
        float sent = sentAt(1.0, k);
        float tau = t - sent;
        float life = 90.0 + 110.0 * gc.w;
        if (tau < 0.0 || tau > life || sent < ahead) {
            cull();
            return;
        }
        float a = angleOf(1.0, sent);
        vec2 O = at(e, a);
        vec2 run = 0.5 * (at(e, angleOf(1.0, sent + 1.0)) - at(e, angleOf(1.0, sent - 1.0)));
        vec2 fore = normalize(normalize(run + vec2(1e-4, 0.0)) - normalize(O - hubOf(a)) * 0.45);
        fly(O, rot((gc.y - 0.5) * 1.2) * fore * (0.3 + min(length(run), 14.0) * (0.06 + 0.14 * gc.z)), tau, life, 1.4 + 1.2 * gc.w, hotter, gc.z, q);
        return;
    }
    if (kind < 5.5) {
        float tau = t - swing.y;
        float life = 120.0 + 120.0 * g.w;
        if (tau < 0.0 || tau > life) {
            cull();
            return;
        }
        vec2 O = at(vec2(cos(hand.z + tip * PI), sin(hand.z + tip * PI)), 0.5 * PI);
        fly(O, rot((g.y - 0.5) * 3.6) * -normalize(O - hubs.zw) * (0.18 + 0.45 * g.z), tau, life, 1.4 + 1.0 * g.w, hotter, g.z, q);
        return;
    }
    if (kind > 6.5) {
        vec4 h = hash4(vec2(s * 0.37 + 11.0, s * 1.13 - 5.0));
        vec2 e = vec2(cos(2.0 * PI * h.y), sin(2.0 * PI * h.y));
        vec2 m = e * (0.9 + 0.1 * h.x) / ringOf(e);
        float r = spanOf(m);
        float sent = sentAt(r, turnInv(h.z));
        float tau = t - sent;
        float life = 70.0 + 80.0 * h.w;
        if (tau < 0.0 || tau > life || sent < ahead) {
            cull();
            return;
        }
        float a = angleOf(r, sent);
        vec3 col = ink > 0.5 ? mix(sepia, leaf, 0.6 + 0.3 * h.w) : mix(leaf, mix(hot, vec3(1.0), 0.6), h.w);
        fly(at(m, a), rot((h.x - 0.5) * 0.5) * normalize(at(m, a + 0.02) - at(m, a - 0.02)) * (0.25 + 0.45 * fract(h.w * 7.1)) * (0.5 + h.z), tau, life, 1.1 + 0.9 * h.w, col, h.z, q);
        return;
    }
    float src = floor(s / GILDED);
    if (src >= gilts) {
        cull();
        return;
    }
    vec4 b = gilt[int(src)];
    vec4 h = hash4(vec2(src * 7.3 + s, s * 1.9 - src));
    float tau = t - swing.z * h.x;
    float life = 150.0 + 110.0 * h.w;
    if (tau < 0.0 || tau > life) {
        cull();
        return;
    }
    vec2 rise = vec2((h.w - 0.5) * 0.08, -0.05 - 0.09 * fract(h.x * 7.3));
    vec3 col = ink > 0.5 ? mix(sepia, leaf, 0.7) : mix(leaf, hot, 0.35) * 1.2;
    float r = 1.5 + 1.4 * h.w;
    emit(b.xy + h.yz * b.zw + rise * tau + vec2(0.0, -0.00015 * tau * tau), vec2(1.0, 0.0), r, r, col, pow(1.0 - tau / life, 1.4) * (0.5 + 0.7 * fract(h.y * 5.1)) * smoothstep(0.0, 12.0, tau), q);
}

void gateSparks(float s, vec2 q) {
    vec4 h = hash4(vec2(s * 0.731 + 3.1, s * 1.297 - 7.3));
    float count = max(gated, 1.0);
    vec4 G = gates[int(mod(s, count))];
    vec2 e = G.zw - G.xy;
    vec2 n = normalize(vec2(-e.y, e.x) + vec2(1e-6, 0.0));
    float side = mod(floor(s / count), 2.0) < 0.5 ? 1.0 : -1.0;
    vec3 col = ink > 0.5 ? mix(sepia, leaf, 0.6 + 0.3 * h.w) : mix(mix(hot, vec3(1.0), 0.45), leaf, 0.35 * h.z);
    float start = max(swing.x, ahead);
    if (kind < 8.5) {
        float sent = start + 20.0 + (swing.y - start - 30.0) * h.x;
        float tau = t - sent;
        float life = 70.0 + 90.0 * h.w;
        if (tau < 0.0 || tau > life) {
            cull();
            return;
        }
        float k = unit((sent - start) / (swing.y - start));
        vec2 O = G.xy + glide * (1.0 - easeOf(k)) + e * (0.5 + 0.45 * (2.0 * h.y - 1.0)) + n * side * (h.z - 0.5) * 10.0;
        float pace = stride * (EASE + 2.0 * (1.0 - EASE) * k) / (swing.y - swing.x);
        fly(O, n * side * pace * (0.45 + 0.4 * h.z) + normalize(e) * (h.w - 0.5) * 0.3, tau, life, 1.1 + 0.9 * h.w, col, h.z, q);
        return;
    }
    float tau = t - swing.y - 6.0 * h.x;
    float life = 90.0 + 130.0 * h.w;
    if (tau < 0.0 || tau > life) {
        cull();
        return;
    }
    fly(G.xy + e * h.y, rot((h.x - 0.5) * 1.6) * n * side * (0.25 + 0.55 * h.z), tau, life, 1.2 + 1.0 * h.w, col, h.z, q);
}
