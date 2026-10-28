void main() {
    int id = gl_VertexID;
    int corner = id - (id / 6) * 6;
    float cell = float(id / 6);
    float nu = grid.x + grid.y;
    float iu = mod(cell, nu);
    float iw = floor(cell / nu);
    float iv = iw - grid.y;
    vec2 c = 1.0 / grid;
    vec2 mid = midOf(iu, iv);
    int k = corner < 3 ? corner : (corner == 3 ? 0 : corner - 2);
    vec2 d = vec2(k == 1 || k == 2 ? 1.0 : 0.0, k >= 2 ? 1.0 : 0.0);
    vec2 rel = vec2(c.x * (d.x + d.y - 1.0), c.y * (d.x - d.y)) * 0.5;
    vec2 n = mid + rel;
    vec4 h = hash4(vec2(iu, iv));
    vec2 size = box.zw;
    float tt = t - trail;
    float tilt = (h.x > 0.5 ? 1.0 : -1.0) * TILT * (0.6 + 0.4 * h.y);

    vec2 X;
    vec2 dir = vec2(0.0, 1.0);
    float th = 0.0;
    float s = 1.0;
    float squash = 0.0;
    float alpha = 1.0;
    float stain = 0.0;
    float lead = 1.0;
    float glint = 0.0;
    float flash = 0.0;
    float sheen = 0.0;
    float sweep = 0.0;
    float edge = 0.0;
    float front = 0.0;
    float lift = 0.0;
    vec2 arm = rel * size;
    vec2 D = box.xy + n * size;
    vec2 mixed = vec2(0.0);
    float shade = fract(h.x * 7.13 + h.y * 3.7);
    if (mode < 0.5) {
        vec2 off = abs(mid - clamp(mid, 0.0, 1.0)) / c;
        if (2.0 * (off.x + off.y) >= 1.0) {
            cull();
            return;
        }
        vec2 S = box.xy + mid * size;
        vec2 away = S - (box.xy + 0.5 * size);
        float r = length(away);
        vec2 u = r > 1.0 ? away / r : vec2(cos(2.0 * PI * h.w), sin(2.0 * PI * h.w));
        float tc = crack * unit(r / max(0.5 * length(size), 1.0));
        float age = tt - tc;
        float e = outCubic(age / 70.0);
        float fall = max(age - 20.0 - 60.0 * h.z, 0.0);
        X = S + u * ((4.0 + 8.0 * h.w) * e + 0.06 * fall) + vec2(0.0, 0.006 * fall * fall);
        th = tilt * e + (h.x > 0.5 ? 1.0 : -1.0) * 0.004 * fall;
        s = mix(1.0, HANG, e);
        alpha = 1.0 - unit((age - 120.0) / 200.0);
        stain = 0.35 * e;
        lead = smoothstep(tc - 4.0, tc + 12.0, tt);
        glint = 2.2 * exp(-sq((tt - tc) / 16.0));
    } else if (mode > 2.5) {
        vec4 q = texelFetch(perm, ivec2(int(iu), int(iw)), 0);
        float go = base + q.y;
        bool moving = t >= go && t < swing.y;
        if (q.x < 0.0 || (parity > -0.5 && abs(mod(iu + iv + 2.0 * grid.y, 2.0) - parity) > 0.5) || (layer > 0.5 && (!moving || tt < go))) {
            cull();
            return;
        }
        vec2 S = box.xy + mid * box.zw;
        vec2 E = goal.xy + mid * goal.zw;
        float k = unit((tt - go) / max(swing.y - go, 1.0));
        float u = q.w + (1.0 - q.w) * k * k;
        vec2 way = length(E - S) > 1.0 ? E - S : goal.xy + 0.5 * goal.zw - box.xy - 0.5 * box.zw + vec2(1e-3, 0.0);
        dir = normalize(way);
        float tc = riftOf(S, h.w);
        lift = climbOf(tc, go, swing.y, tt);
        float drawn = ahead > 0.0 ? 0.0 : (tt < go ? smoothstep(tc, go, tt) : 1.0 - smoothstep(0.0, 1.0, k));
        float loose = smoothstep(tc + 6.0, tc + 36.0, tt) * (1.0 - smoothstep(swing.y - 60.0, swing.y, tt));
        float flight = sin(PI * u);
        X = mix(S, E, u) - dir * DRAW * drawn + (h.zw - 0.5) * 3.0 * loose + vec2(-dir.y, dir.x) * ARC * (2.0 * h.y - 1.0) * flight;
        th = tilt * (0.05 * loose + 0.35 * flight);
        float ti = tt - swing.y;
        if (ti > 0.0) {
            X -= dir * KICK * exp(-ti / 28.0) * sin(0.11 * ti);
            squash = 0.07 * exp(-ti / 30.0);
        } else
            squash = BREATH * drawn - SMEAR * sin(PI * u);
        int gi = int(q.x + 0.5) - 1;
        vec2 cut = 0.5 * (box.zw + goal.zw) * c;
        vec2 A = X;
        vec2 nrm = dir;
        float through = unit((tt - go) / REFIRE);
        if (gi >= 0) {
            vec2 slide = glide * (1.0 - easeOf(unit((tt - swing.x) / (swing.y - swing.x))));
            A = gates[gi].xy + slide;
            vec2 e = gates[gi].zw - gates[gi].xy;
            nrm = normalize(vec2(-e.y, e.x));
            nrm *= dot(E - gates[gi].xy, nrm) < 0.0 ? -1.0 : 1.0;
            float reach = 0.5 * max(abs(nrm.x) * cut.x, abs(nrm.y) * cut.y);
            float r0 = clamp(dot(gates[gi].xy + glide - S, nrm), 0.0, reach);
            float r1 = clamp(dot(E - gates[gi].xy, nrm), 1.0, reach);
            through = unit((dot(X - A, nrm) + r0) / (r0 + r1));
        }
        float open = ahead > 0.0 ? 1.0 : smoothstep(go, go + 20.0, tt);
        float live = 1.0 - smoothstep(swing.y - 6.0, swing.y + 30.0, tt);
        float sc = gi >= 0 ? smoothstep(0.0, 1.0, through) : u;
        size = mix(box.zw, goal.zw, sc);
        arm = rel * size;
        float throat = sin(PI * through);
        s = (1.0 - (1.0 - PINCH) * throat) * (1.0 - SHRINK * sin(PI * u)) * (1.0 - BREATH * drawn);
        float tg = frontOf(E);
        float tf = base + q.z;
        edge = 1.0;
        alpha = 1.0 - smoothstep(tg + 0.25 * reveal, tg + reveal, t);
        stain = (ink > 0.5 ? 0.55 : 0.9) * sqrt(sin(PI * u)) * step(go, tt) * (1.0 - step(swing.y, tt));
        glint = 0.8 * exp(-sq((tt - go) / 14.0)) * step(swing.x, go) + 0.6 * exp(-sq((tt - tf - 16.0) / 8.0)) + MOLTEN * throat;
        sweep = 2.6 * through - 0.3;
        sheen = GLOSS * step(go, tt) * (1.0 - step(swing.y, tt));
        if (ti >= 0.0)
            flash = 0.5 * exp(-ti / 22.0) + (t >= tg ? 1.4 * exp(-(t - tg) / 22.0) + 0.5 * exp(-(t - tg) / 110.0) : 0.0);
        vec2 P = X + arm * s;
        vec2 seam = gi >= 0 ? P - A : vec2(dot(P - X, nrm) + (0.5 * max(abs(nrm.x) * cut.x, abs(nrm.y) * cut.y) + 3.0) * (2.0 * through - 1.0), 0.0);
        front = ((gi >= 0 ? dot(seam, nrm) : seam.x) - SHUT * (1.0 - open)) * screen.z;
        mixed = vec2(open * live, gi >= 0 ? throat * live : 0.0);
        D = E + arm * s;
        shade = mod(iu + iv + 2.0 * grid.y, 2.0);
    } else if (mode > 1.5) {
        vec4 q = texelFetch(perm, ivec2(int(iu), int(iw)), 0);
        float tr = base + q.y;
        float tl = base + q.z;
        float tg = base + q.w;
        bool moving = q.x > 0.5 && t >= tr && t < tl;
        if (q.x < 0.0 || (layer > 0.5 ? !moving || tt < tr : layer > -0.5 && moving)) {
            cull();
            return;
        }
        vec2 S = box.xy + mid * size;
        vec2 V = S + arm;
        float ti = tt - tl;
        float back = ti > 0.0 ? RECOIL * exp(-ti / 28.0) * sin(0.11 * ti) : 0.0;
        float ac = angleOf(spanOf(S), tt) - back;
        float u = clamp(ac / (0.5 * PI), 0.0, 1.0);
        X = at(S, ac);
        arm = at(V, angleOf(spanOf(V), tt) - back) - X;
        D = at(V, 0.5 * PI);
        vec2 fore = at(S, ac + 0.02) - at(S, ac - 0.02);
        dir = length(fore) > 1e-3 ? normalize(fore) : dir;
        vec2 ax = at(S + vec2(0.5 * c.x * size.x, 0.0), ac) - X;
        vec2 ay = at(S + vec2(0.0, 0.5 * c.y * size.y), ac) - X;
        front = dot(arm, dir) / max(max(abs(dot(ax, dir)), abs(dot(ay, dir))), 1.0);
        float tc = riftOf(S, h.w);
        lift = climbOf(tc, swing.x + swing.z * spanOf(S) + CLIMB * (0.5 + h.z), tl, tt);
        float loose = smoothstep(tc + 6.0, tc + 36.0, tt) * (1.0 - smoothstep(tl - 70.0, tl, tt));
        float flight = sin(PI * u);
        X += (h.zw - 0.5) * (3.0 + 10.0 * flight) * loose;
        th = tilt * (0.05 + 0.2 * flight) * loose;
        float tf = flush.w * clamp(dot(S - hand.xy, flush.xy) / max(flush.z, 1.0), 0.0, 1.0);
        s = 1.0 - SHRINK * max(sin(PI * u), LOOSE * smoothstep(tf, tf + 30.0, tt) * (1.0 - u));
        edge = 1.0;
        alpha = 1.0 - smoothstep(tg + 0.25 * reveal, tg + reveal, t);
        stain = 0.18 * smoothstep(tf, tf + 30.0, tt);
        glint = exp(-sq((tt - tf) / 12.0)) + 0.5 * exp(-sq((t - tg) / 16.0));
        if (tt >= tl) {
            mixed.x = 1.0;
            flash = 0.5 * exp(-ti / 22.0) + (t >= tg ? 1.4 * exp(-(t - tg) / 22.0) + 0.5 * exp(-(t - tg) / 110.0) : 0.0);
        } else if (tt >= tr) {
            mixed = vec2(smoothstep(0.1, 0.9, u), 1.0);
            stain = ink > 0.5 ? stain : 0.4;
            glint += 0.9 * exp(-sq((tt - tr) / 14.0)) + MOLTEN * sin(PI * u);
            sweep = 2.6 * u - 0.3;
            sheen = GLOSS;
        }
    } else {
        vec4 q = texelFetch(perm, ivec2(int(iu), int(iw)), 0);
        float tf = base + q.y;
        if (q.x < 0.0 || tt < tf) {
            cull();
            return;
        }
        float si = floor(q.x * 0.5);
        float su = mod(si, nu);
        float sv = floor(si / nu) - grid.y;
        vec2 S = box.xy + midOf(su, sv) * size;
        vec2 H = box.xy + mid * size;
        vec2 K = box.xy + (mod(q.x, 2.0) > 0.5 ? midOf(su, iv) : midOf(iu, sv)) * size;
        float tl = base + q.z;
        float ts = base + q.w;
        float L1 = length(K - S);
        float L2 = length(H - K);
        float tk = tl + (ts - tl) * (L1 < 0.5 ? 0.0 : 0.3 + 0.3 * L1 / max(L1 + L2, 1.0));
        bool moving = t >= tl && t < ts;
        if (trail > 0.0 ? tt < tk || t >= ts : (layer > 0.5) != moving) {
            cull();
            return;
        }
        dir = L2 > 0.5 ? (H - K) / L2 : (L1 > 0.5 ? (K - S) / L1 : vec2(0.0, 1.0));
        float kf = unit((tt - tf) / born.x);
        float grow = mix(born.y, 1.0, outBack(kf));
        alpha = (born.y < 0.5 ? outCubic(1.6 * kf) : 1.0) * (1.0 - smoothstep(ts + 0.25 * reveal, ts + reveal, t));
        stain = (moving ? 0.4 : 0.22) * (1.0 - smoothstep(ts - 60.0, ts, tt));
        lead = smoothstep(0.2, 0.8, kf);
        glint = (born.y < 0.5 ? 1.3 * exp(-sq((kf - 0.85) / 0.12)) : 0.0) + (tt < ts ? (moving ? 0.55 : 0.22 + 0.12 * sin(tt * 0.021 + 6.0 * h.w)) : 0.0);
        if (tt < tl) {
            float amp = 0.4 + 1.2 * kf;
            X = S + vec2(sin(tt * 0.083 + 13.0 * h.z), 0.6 * cos(tt * 0.097 + 7.0 * h.w)) * amp;
            th = tilt * grow + 0.04 * sin(tt * 0.05 + 5.0 * h.z);
            s = HANG * grow;
        } else if (tt < tk) {
            float e = outCubic((tt - tl) / max(tk - tl, 1.0));
            X = mix(S, K, e);
            th = tilt;
            s = HANG;
        } else if (tt < ts) {
            float e = sq((tt - tk) / max(ts - tk, 1.0));
            X = mix(K, H, e);
            th = tilt * (1.0 - e);
            s = mix(HANG, 1.0, e);
            sweep = 2.6 * e - 0.3;
            sheen = 0.35;
        } else {
            float ti = tt - ts;
            X = H - dir * 3.0 * exp(-ti / 16.0) * cos(0.16 * ti);
            squash = 0.07 * exp(-ti / 25.0);
            flash = 1.6 * exp(-ti / 22.0) + 0.5 * exp(-ti / 110.0);
        }
    }

    vec2 side = vec2(-dir.y, dir.x);
    vec2 r = arm * s;
    r = rot(th) * (dir * dot(r, dir) * (1.0 - squash) + side * dot(r, side) * (1.0 + 0.5 * squash));
    float cw = c.x * size.x * s;
    float ch = c.y * size.y * s;
    float span = cw * ch / sqrt(cw * cw + ch * ch);
    bool umbra = layer < -0.5;
    float roll = 2.0 * PI * fract(3.7 * h.y + h.z) + th;
    vec2 axis = vec2(cos(roll), sin(roll));
    vec2 slope = vec2(-axis.y, axis.x);
    float tip = TIP * (0.45 + 0.55 * h.w) * (h.x > 0.5 ? 1.0 : -1.0) * (0.75 + 0.25 * sin(0.012 * tt + 6.283 * h.z)) * lift;
    float height = RISE * (0.55 + 0.45 * h.z) * lift;
    float rb = dot(r, slope);
    vec2 r3 = axis * dot(r, axis) + slope * rb * cos(tip);
    float blur = SOFT + BLUR * lift;
    float grow = umbra ? 1.0 + 4.0 * blur / max(span, 1.0) : 1.0;
    float w = umbra ? 1.0 : 1.0 - (height + rb * sin(tip)) / EYE;
    vec2 P = umbra ? X + r3 * grow + CAST * height / RISE : eye + (X + r3 - eye) / w;
    gl_Position = vec4((proj * vec3((P - screen.xy) * screen.z / target, 1.0)).xy * w, 0.0, w);

    if (trail > 0.0) {
        glint = 0.0;
        flash = 0.0;
    }
    v_lift = vec4(lift, -slope * sin(tip), blur);
    v_out = r3;
    v_ray = (P - eye) / EYE;
    v_uv = mode > 2.5 ? shot.xy + mid * shot.zw + r * screen.z : shot.xy + n * shot.zw;
    v_n = mid + rel * grow;
    v_lat = 0.5 + (d - 0.5) * grow;
    v_shard = vec4(shade, span, sweep, sheen);
    v_glow = vec4(stain, lead, glint, flash);
    v_size = vec3(size, alpha);
    v_edge = edge;
    v_new = (D - screen.xy) * screen.z;
    v_front = front;
    v_mix = mixed;
}
