void riftSparks(float s, vec2 q) {
    vec4 h = hash4(vec2(s * 0.913 + 1.7, s * 1.371 - 4.2));
    vec3 hotter = ink > 0.5 ? mix(sepia, leaf, 0.7) : mix(hot, vec3(1.0), 0.4);
    vec3 magic = ink > 0.5 ? mix(sepia, leaf, 0.45 + 0.4 * h.y) : mix(mix(jewel0, jewel1, h.y), vec3(1.0), 0.35) * 1.3;
    if (kind < 11.5) {
        bool flare = kind > 10.5;
        vec2 n;
        vec2 O = rimOf(flare ? hull : box, h.x, n);
        float sent = flare ? ringAt(O) + 6.0 * h.y : ahead + 6.0 + 50.0 * h.y * h.y;
        float tau = t - sent;
        float life = (flare ? 150.0 : 170.0) + 190.0 * h.w;
        if (tau < 0.0 || tau > life) {
            cull();
            return;
        }
        vec2 along = vec2(-n.y, n.x);
        if (h.z < 0.65) {
            fly(O, rot((h.z - 0.32) * 1.6) * n * (0.35 + 0.9 * h.z) + along * (h.w - 0.5) * 0.3, tau, life, 1.6 + 1.8 * h.w, flare ? hotter : mix(hotter, magic, 0.25), h.y, q);
            return;
        }
        float drift = (22.0 + 70.0 * h.w) * (1.0 - exp(-tau / 140.0));
        vec2 P = O + n * drift + along * (h.y - 0.5) * 24.0 * (1.0 - exp(-tau / 200.0)) + vec2(0.0, -0.035 * tau);
        float r = 1.4 + 1.8 * fract(h.w * 7.3);
        emit(P, vec2(1.0, 0.0), r, r, magic, pow(1.0 - tau / life, 1.3) * (0.55 + 0.45 * sin(tau * 0.045 + 40.0 * h.y)) * smoothstep(0.0, 20.0, tau) * 1.2, q);
        return;
    }
    float nj = grid.x + grid.y + 1.0;
    float per = STRIKES * DROPS;
    float leads = 2.0 * nj * nj;
    float seg = floor(s / per);
    float w = s - seg * per;
    float kb = floor(w / DROPS);
    float p = w - kb * DROPS;
    vec2 key;
    vec2 O;
    float tb;
    float b;
    if (seg < leads) {
        float s2 = floor(seg / 2.0);
        float dir = seg - 2.0 * s2;
        vec2 a = vec2(mod(s2, nj), floor(s2 / nj) - grid.y);
        vec2 z = a + (dir < 0.5 ? vec2(1.0, 0.0) : vec2(0.0, 1.0));
        key = vec2(2.0 * a.x + dir, a.y);
        vec2 A = posOf(a);
        vec2 Z = posOf(z);
        float ta = ringAt(A);
        float tz = ringAt(Z);
        float to = min(ta, tz);
        float tc = max(ta, tz);
        vec4 g = hash4(key * 1.618 + 3.1);
        float dt = FLICK + JIT * g.x;
        b = floor(to / dt + g.y) + kb;
        tb = max((b - g.y) * dt, to);
        vec4 hb = hash4(key + vec2(7.13 * b, -3.71 * b) + 0.5);
        O = tz < ta ? mix(Z, A, hb.w * unit((tb - to) / max(tc - to, 1.0))) : mix(A, Z, hb.w * unit((tb - to) / max(tc - to, 1.0)));
        vec2 on = (O - goal.xy) / goal.zw;
        if (t < tb || tb > tc + ARCED || g.z <= CHARGED || hb.y >= STRIKE || on.x < 0.0 || on.y < 0.0 || on.x > 1.0 || on.y > 1.0 || (lanes > 0.5 && laneOf(O.x) < 0.35) ||
            !fed(tz < ta ? a : z, tc, tz < ta ? z : a)) {
            cull();
            return;
        }
    } else {
        float total = 2.0 * (goal.z + goal.w);
        float m = max(floor(total / LINK + 0.5), 4.0);
        float twin = seg - leads;
        float k = floor(twin / 2.0);
        key = vec2(k, 1000.0);
        vec4 g = hash4(key * 1.618 + 3.1);
        float dt = FLICK + JIT * g.x;
        vec2 n;
        b = floor((ringAt(rimOf(goal, (k + 0.5) / m, n)) - 20.0) / dt + g.y) + kb + STRIKES * (twin - 2.0 * k);
        vec4 hb = hash4(key + vec2(7.13 * b, -3.71 * b) + 0.5);
        O = rimOf(goal, (k + hb.w) / m, n);
        float lit = ringAt(O);
        tb = max((b - g.y) * dt, lit);
        if (k >= m || t < tb || tb >= (b + 1.0 - g.y) * dt || tb > lit + RIMMED || g.z <= CHARGED || hb.y >= STRIKE) {
            cull();
            return;
        }
    }
    spatter(O, t - tb, key, b, p, q);
}

void splash(float s, vec2 q) {
    vec4 h = hash4(vec2(s * 0.613 + 9.1, s * 1.177 - 2.3));
    vec4 r = hash4(vec2(s * 1.931 - 4.4, s * 0.287 + 6.6));
    float tau = t - ring.y - 5.0 * r.w;
    float life = cooled * (0.6 + 0.4 * r.x);
    if (tau < 0.0 || tau > life) {
        cull();
        return;
    }
    bool corner = h.x < 0.4;
    float side = (corner ? h.y : h.z) < 0.5 ? -1.0 : 1.0;
    vec2 O = goal.xy + vec2(goal.z * (corner ? 0.5 + 0.5 * side : 0.06 + 0.88 * h.y), goal.w);
    float a = side * (corner ? 0.7 + 0.8 * h.w : 0.25 + 1.3 * h.w);
    vec2 v0 = (0.18 + 0.42 * r.y * r.y) * vec2(sin(a), cos(a)) + vec2(0.0, -0.12 - 0.12 * r.z);
    vec2 vel;
    vec2 P = thrown(O, v0, 100.0 + 130.0 * r.z, tau, vel);
    float heat = exp(-tau / (110.0 + 120.0 * r.w));
    float speed = length(vel);
    float fade = smoothstep(0.0, 3.0, tau) * (1.0 - smoothstep(0.7 * life, life, tau));
    hard = 5.0;
    emit(P, speed > 1e-4 ? vel / speed : vec2(1.0, 0.0), 1.2 + speed * 18.0, (ink > 0.5 ? 1.5 : 1.2) * (1.0 + 0.45 * r.w), ink > 0.5 ? mix(sepia, leaf, heat) : glowOf(heat),
         (ink > 0.5 ? 0.8 + 0.2 * heat : 0.45 + 1.1 * heat) * fade, q);
}
