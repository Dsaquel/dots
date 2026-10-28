vec4 cloud(vec2 q, vec2 e, vec2 hs, vec2 p, float pl, float b0, float b1, float hw, float sc, float hy, inout float shade) {
    vec2 nb = build.yz;
    vec2 ns = bricks();
    float head = -2.0;
    vec2 ld = normalize(p - lightPos.xy + vec2(1e-3));
    vec4 acc = vec4(0.0);
    for (int pass = 0; pass < 2; ++pass) {
        bool flat_ = pass == 0;
        float side = flat_ ? (q.y < 0.0 ? 0.0 : 4.0) : (q.x > 0.0 ? 2.0 : 6.0);
        float x = flat_ ? (q.y < 0.0 ? q.x + e.x : e.x - q.x) : (q.x > 0.0 ? q.y + e.y : e.y - q.y);
        float s = flat_ ? abs(q.y) - hs.y : abs(q.x) - hs.x;
        float roomS = flat_ ? (q.y < 0.0 ? room.x : room.z) : (q.x > 0.0 ? room.y : room.w);
        float inS = roomS - sc - hy - NEAR < 45.0 ? -1.0 : 1.0;
        roomS = inS > 0.0 ? roomS : min(hs.x, hs.y);
        float far_ = inS > 0.0 ? reachOf(roomS, sc, hy) : (build.x < SPEND + SOWG + GATHER ? INQ : sc + INF + 90.0);
        if (inS > 0.0 ? s < -48.0 || s > far_ : s > 48.0 || s < 2.0 * sc - far_ - 40.0)
            continue;
        if (head < -1.5)
            head = headAt(build.x, nb);
        float n = flat_ ? ns.x : ns.y;
        float seg = 2.0 * (flat_ ? e.x : e.y) / n;
        float k = clamp(floor(x / seg), 0.0, n - 1.0);
        float a = side * 0.78539816;
        vec2 along = vec2(cos(a), sin(a));
        vec2 out_ = vec2(sin(a), -cos(a));
        vec2 dl = vec2(dot(ld, along), dot(ld, out_));
        vec4 cs[7];
        float zs[7];
        for (int j = 0; j < 7; ++j) {
            float m = k + float(j - 3);
            cs[j] = vec4(0.0);
            zs[j] = 1e3;
            if (m < -0.5 || m > n - 0.5)
                continue;
            float z;
            cs[j] = bolt(vec2(x, s), side, m, n, seg, sc, hy, mod(m + side * 0.5, 2.0) < 1.0 ? jewelA : jewelB, along, out_, dl, p, pl, b0, b1, hw, nb, head, roomS, inS, shade, z);
            zs[j] = z;
        }
        for (int i = 0; i < 7; ++i) {
            int best = 0;
            float low = 2e3;
            for (int j = 0; j < 7; ++j)
                if (zs[j] < low) {
                    low = zs[j];
                    best = j;
                }
            if (low > 999.0)
                break;
            acc = cs[best] + acc * (1.0 - cs[best].a);
            zs[best] = 2e3;
        }
    }
    return acc;
}

vec3 rays(vec2 q, vec2 e, float s) {
    vec2 sg = vec2(q.x > 0.0 ? 1.0 : -1.0, q.y > 0.0 ? 1.0 : -1.0);
    float corner = q.x > 0.0 ? (q.y < 0.0 ? 1.0 : 3.0) : (q.y > 0.0 ? 5.0 : 7.0);
    float big = abs(corner - (build.w > 0.0 ? 7.0 : 1.0)) < 0.5 ? 1.6 : 1.0;
    vec2 tp = turnOf(corner, build.yz);
    float age = build.x - tp.x - 0.5 * tp.y;
    if (age < 0.0 || age > 320.0 * big)
        return vec3(0.0);
    vec2 d0 = q - sg * (e + vec2(radius + offset - 0.5) * 0.70710678);
    if (dot(d0, d0) > sq(220.0 * big))
        return vec3(0.0);
    vec3 acc = vec3(0.0);
    float base = atan(sg.y, sg.x);
    for (int j = 0; j < 9; ++j) {
        float fj = float(j);
        float hj = hash(vec2(corner * 7.0 + fj, 3.3));
        float life = (180.0 + 120.0 * hj) * big;
        if (age > life)
            continue;
        float th = base + (fj - 4.0) * 0.21 + 0.12 * (hash(vec2(fj, corner)) - 0.5);
        vec2 dir = vec2(cos(th), sin(th));
        vec2 dv = d0 - dir * (0.35 + 0.25 * hj) * big * age * (1.0 - 0.45 * age / life);
        float streak = exp(-sq(dot(dv, dir) / (2.0 + 4.0 * (1.0 - age / life))) - sq(dot(dv, vec2(-dir.y, dir.x)) / 0.9));
        acc += mix(hot, vec3(1.0), 0.55) * streak * sq(1.0 - age / life) * 2.0;
    }
    float ring = exp(-sq((length(d0) - 6.0 - 0.5 * big * age) / (1.5 + 0.02 * age))) * exp(-age / (90.0 * big));
    return acc + mix(hot, vec3(1.0), 0.3) * ring * 0.9 * smoothstep(-2.0, 2.0, s);
}
