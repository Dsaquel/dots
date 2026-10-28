vec4 bolt(vec2 b, float side, float m, float n, float seg, float sc, float hy, vec3 jewel, vec2 along, vec2 out_, vec2 dl, vec2 p, float pl, float b0, float b1, float hw, vec2 nb, float head, float roomS, float inS, inout float shade, out float z) {
    z = 1e3;
    float A = build.x;
    float o = orderOf(side);
    float j = build.w > 0.0 ? m : n - 1.0 - m;
    float c = beforeOf(o, nb) + j;
    float land = chainLand(o, j, nb);
    float born = SPEND + SOWG * c / (2.0 * (nb.x + nb.y));
    if (A < born || A >= land)
        return vec4(0.0);
    float id = side * 97.0 + m;
    float rid = id + 61.7 * seed;
    vec4 h = vec4(hash(vec2(rid, 2.7)), hash(vec2(rid, 8.1)), hash(vec2(rid, 5.3)), hash(vec2(rid, 1.9)));
    float row = hash(vec2(rid, 3.9));
    float len = n * seg;
    float slotX = (m + 0.5) * seg;
    float prog = clamp((A - T0) / (chainLand(3.0, nb.y - 1.0, nb) - T0), 0.0, 1.0);
    float nearS = sc + hy + NEAR;
    float open_ = smoothstep(30.0, 60.0, roomS - nearS);
    float farS = mix(roomS + 2.6 * hy + 8.0, max(min(sc + (inS > 0.0 ? OUTF : INF), roomS - 1.7 * hy - 4.0), nearS), open_);
    float lim = clamp((roomS - 1.7 * hy - 2.0 - nearS) / 14.0, 0.25, 1.0);
    float depth = mix(nearS, farS, mix(1.0, (0.06 + 0.94 * row) * (1.0 - 0.25 * prog), open_));
    float low = min(nearS, roomS - hy);
    float perch = mix(low + (roomS + 0.5 * hy - low) * row, depth, open_);
    float dive = DIVE + 0.25 * (perch - sc);
    float tau = land - A;
    float kf = clamp(1.0 - tau / dive, 0.0, 1.0);
    float e = kf * kf * kf;
    float wu = clamp((tau - dive) / WIND, 0.0, 1.0);
    float wind = 1.0 - wu * wu * wu;
    float call = clamp(1.0 - (tau - dive - WIND) / CALLW, 0.0, 1.0);
    float loose = 1.0 - kf;
    float coil = wind * loose;
    float steady = 1.0 - 0.5 * wind;
    float g = clamp((A - born) / GATHER, 0.0, 1.0);
    float gu = g - 1.0;
    float ge = 1.0 + 2.2 * gu * gu * gu + 1.2 * gu * gu;
    float spread = inS * (slotX - 0.5 * len) / max(0.5 * len, 1.0) * min(depth - sc, 90.0) * 0.5 + (h.x - 0.5) * mix(0.5, 0.9, open_) * seg;
    vec2 hover = vec2(slotX + spread, mix(depth, perch, call * call));
    vec2 from = vec2(slotX + 1.6 * spread + 30.0 * (h.y - 0.5), min(depth + FROM, (inS > 0.0 ? QUAD : INQ) - 2.0 * hy));
    vec2 slot = vec2(slotX, sc);
    vec2 pull = normalize(vec2(hover.x - slotX, max(hover.y - sc, 0.0) + 2.0)) * (18.0 + 8.0 * h.z) * mix(0.5, 1.0, open_) * wind;
    vec2 bm = vec2(b.x, sc + inS * (b.y - sc));
    vec2 near_ = abs(bm - mix(mix(from, hover, ge) + pull, slot, e));
    if (near_.x > 0.85 * seg + 110.0 || near_.y > 0.3 * seg + 2.0 * hy + 140.0)
        return vec4(0.0);
    float kick = 0.0;
    float spin = 0.0;
    for (int i = 0; i < 3; ++i) {
        float cs = head - float(i);
        if (cs < 0.0)
            break;
        float d = (c - cs) * seg;
        float age = A - landAt(cs, nb) - d / SHOCK;
        if (age < 0.0)
            continue;
        float amp = exp(-d / 220.0 - age / 110.0);
        kick += 8.0 * amp * sin(age * 0.05);
        spin += 0.45 * amp * sin(age * 0.035 + 1.0);
    }
    for (int i = 0; i < 3; ++i) {
        float oc = float(i);
        float cc = beforeOf(oc + 1.0, nb);
        if (c < cc - 0.5)
            break;
        float d = (c - cc + 1.0) * seg;
        float age = A - chainLand(oc, countOf(oc, nb) - 1.0, nb) - 0.5 * pauseOf(oc, nb) - d / (2.5 * SHOCK);
        if (age < 0.0)
            continue;
        float amp = exp(-d / 1400.0 - age / 170.0);
        kick += 13.0 * amp * sin(age * 0.04);
        spin += 0.8 * amp * sin(age * 0.03);
    }
    vec2 drift = vec2((3.0 + 6.0 * open_) * sin(A * 0.0041 + rid * 2.1) + 1.5 * sin(A * 0.0097 + rid), (2.5 + 7.0 * open_) * lim * sin(A * 0.0057 + rid * 1.3)) * loose;
    vec2 tremor = vec2(sin(A * 0.31 + rid * 3.1), sin(A * 0.27 + rid * 1.9)) * 1.4 * call * call * loose;
    vec2 pre = mix(from, hover, ge) + pull + drift + tremor + vec2(0.0, kick * lim);
    vec2 at = mix(pre, slot, e);
    float rock = ((0.35 + 0.55 * h.z) * sin(A * (0.0035 + 0.003 * h.w) + rid * 2.7) + spin) * loose * steady + (1.0 - ge) * 9.0 * (h.w - 0.5);
    float yaw = 0.55 * sin(A * 0.0027 + rid * 1.1) * loose * steady + (1.0 - ge) * 2.5 * (h.x - 0.5);
    float tilt = (mix(0.35, 0.9, open_) * (h.y - 0.5) + (0.07 + 0.1 * open_) * sin(A * 0.006 + rid)) * (1.0 - e) * steady + (1.0 - ge) * 1.4 * (h.z - 0.5);
    float lift = (mix(0.18, 0.55, h.w) * mix(0.45, 1.0, open_) * (1.0 - 0.3 * call) + (0.3 - 0.15 * open_) * wind + 0.012 * abs(kick)) * (1.0 - e) + 1.3 * sq(1.0 - g);
    float sig = 1.0 + lift;
    float cr = cos(rock);
    vec2 fold = vec2(max(abs(cos(yaw)), 0.22) * mix(0.74, 1.0, e) * (1.0 + 0.12 * coil), (cr < 0.0 ? -1.0 : 1.0) * max(abs(cr), 0.1) * (1.0 - 0.22 * coil));
    vec2 ha = vec2(0.5 * seg - 1.0, hy) * sig * abs(fold);
    vec2 r = (bm - at) * vec2(1.0, inS);
    vec2 trav = (kf > 0.0 ? (slot - pre) * e : (hover - from) * min(ge, 1.0)) * vec2(1.0, inS);
    float reach = min(TRAIL * (kf > 0.0 ? kf : sq(1.0 - g)), length(trav));
    vec2 tc = abs(vec2(cos(tilt), sin(tilt)));
    vec2 box_ = vec2(tc.x * ha.x + tc.y * ha.y, tc.y * ha.x + tc.x * ha.y) + 36.0 + reach;
    if (abs(r.x) > box_.x || abs(r.y) > box_.y)
        return vec4(0.0);
    mat2 R = mat2(cos(tilt), sin(tilt), -sin(tilt), cos(tilt));
    vec2 lr = R * r;
    float sh = max(0.3 * reach, 1.0);
    vec2 v = reach < 1.0 ? vec2(0.0, 1.0) : R * normalize(trav);
    vec2 wd = 1.0 + abs(v) * (sh - 1.0);
    vec2 ce = lr + v * 0.5 * (sh - 1.0);
    vec2 cx = max(min(ce + 0.5 * wd, ha) - max(ce - 0.5 * wd, -ha), 0.0) / wd;
    vec2 ls = clamp(ce, -ha, ha);
    float sd = sdBrick(ls, ha);
    float alpha = smoothstep(0.0, 0.3, g);
    float cov = cx.x * cx.y * alpha;
    float off = min(4.0 + 34.0 * lift, 24.0);
    float blur = 1.5 + 9.0 * lift;
    shade += 0.4 * clamp(lift / 0.5, 0.0, 1.0) * alpha * (1.0 - smoothstep(-blur, blur, sdBrick(R * (r - dl * off), ha))) * (1.0 - cov);
    vec2 l = ls / (sig * fold);
    vec2 od = (along * sin(tilt) + out_ * cos(tilt)) * sign(fold.y);
    vec4 c4 = pane(l + vec2(0.5 * seg, sc), m * seg, seg, jewel, id, vec2(od.x, -od.y), 1.0 / (sig * abs(fold)), p, pl, b0, b1, hw);
    vec3 L = normalize(vec3(lightPos.xy - p, lightPos.z));
    vec3 nrm = normalize(vec3(along * (sin(yaw) + 0.6 * l.x / seg) + out_ * sin(rock), abs(cr) * cos(yaw)));
    float face = 0.7 + 0.3 * max(dot(nrm, L), 0.0);
    vec3 H = normalize(L + vec3(0.0, 0.0, 1.0));
    float glint = max(pow(max(dot(nrm, H), 0.0), 60.0) - pow(H.z, 60.0), 0.0) * 1.6;
    float edge = smoothstep(0.42, 0.12, abs(cr));
    float rim = 1.0 - smoothstep(0.0, 2.0, -sd);
    float heat = 0.45 * call * call * call + 0.6 * e + 0.4 * exp(-(A - born) / 70.0);
    c4.a = mix(c4.a, 1.0, max(max(rim, e), edge));
    vec3 lit = mix(c4.rgb * face, metal(vec3(0.0, 0.0, 1.0), p, 0.7, pl) * 0.85, edge);
    c4.rgb = emit(lit, mix(hot, vec3(1.0), 0.55) * glint * 1.3 * (1.0 - edge));
    c4.rgb = mix(c4.rgb, hot * 1.4, rim * min(heat, 0.8)) + hot * 0.14 * min(heat, 1.0);
    cov *= c4.a;
    z = lift + 1e-3 * c;
    return vec4(c4.rgb, 1.0) * cov;
}

vec4 dart(vec2 b, float side, float m, float land, float seg, float sc, float hy, vec3 jewel, vec2 p, float pl, float b0, float b1, float hw) {
    float kf = (build.x - land + FLY) / FLY;
    if (build.x < 0.0 || kf <= 0.0 || kf >= 1.0)
        return vec4(0.0);
    float id = side * 97.0 + m;
    float t = pow(kf, 1.7);
    vec2 p0 = vec2(-DRIFT * seg + 24.0 * (hash(vec2(id, 2.7)) - 0.5), -AIRC + 12.0 * (hash(vec2(id, 8.1)) - 0.5));
    float sig = 1.0 + 0.45 * (1.0 - t);
    vec2 ha = vec2(0.5 * seg - 1.0, hy) * sig;
    vec2 r = b - vec2(0.5 * seg, sc) - (1.0 - t) * p0;
    vec2 v = normalize(-p0);
    float sh = max(1.0, 15.0 * pow(kf, 0.7) * length(p0) / FLY);
    vec2 wd = 1.0 + abs(v) * (sh - 1.0);
    vec2 ce = r + v * 0.5 * (sh - 1.0);
    vec2 cx = max(min(ce + 0.5 * wd, ha) - max(ce - 0.5 * wd, -ha), 0.0) / wd;
    vec2 ls = clamp(ce, -ha, ha);
    float a = side * 0.78539816;
    vec2 out_ = vec2(sin(a), -cos(a));
    vec4 c4 = pane(ls / sig + vec2(0.5 * seg, sc), m * seg, seg, jewel, id, vec2(out_.x, -out_.y), vec2(1.0 / sig), p, pl, b0, b1, hw);
    float rim = 1.0 - smoothstep(0.0, 2.0, -sdBrick(ls, ha));
    c4.a = mix(c4.a, 1.0, rim);
    c4.rgb = mix(c4.rgb, hot * 1.4, rim * (0.25 + 0.45 * kf)) + hot * 0.12 * kf;
    return vec4(c4.rgb, 1.0) * cx.x * cx.y * c4.a * smoothstep(0.0, 0.2, kf);
}

vec4 flights(float side, float x, float len, float s, float sc, float hy, vec2 p, float pl, float b0, float b1, float hw) {
    float n = max(1.0, floor(len / pieceLen + 0.5));
    float seg = len / n;
    float k = min(floor(x / seg), n - 1.0);
    vec4 acc = vec4(0.0);
    for (int j = 0; j < 4; ++j) {
        float m = k + float(j);
        if (m < -0.5 || m > n - 0.5)
            continue;
        vec4 b = dart(vec2(x - m * seg, s), side, m, landOf(side, m, n), seg, sc, hy, mod(m + side * 0.5, 2.0) < 1.0 ? jewelA : jewelB, p, pl, b0, b1, hw);
        acc = b + acc * (1.0 - b.a);
    }
    return acc;
}

float reachOf(float roomS, float sc, float hy) {
    return build.x < SPEND + SOWG + GATHER ? QUAD : min(sc + OUTF, roomS + 2.6 * hy + 8.0) + 130.0;
}
