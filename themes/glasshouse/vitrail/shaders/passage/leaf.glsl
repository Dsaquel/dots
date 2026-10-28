float fine(float px) {
    return clamp(2.5 / max(px, 1e-3), 0.0, 1.0);
}

vec3 ashlar(vec2 uv, float px, float seed) {
    float course = 0.12 * size.y;
    float len = course * 2.2;
    float row = floor(uv.y / course);
    float x = uv.x / len + 0.5 * mod(row, 2.0);
    vec2 f = vec2(fract(x) * len, fract(uv.y / course) * course);
    float e = min(min(f.x, len - f.x), min(f.y, course - f.y));
    float joint = (1.0 - smoothstep(0.5 * px, 1.5 * px + 1.0, e)) * fine(px);
    vec2 m = uv / (course * 3.1);
    vec2 mi = floor(m);
    vec2 mf = smoothstep(0.0, 1.0, fract(m));
    float mottle = mix(mix(hash(mi), hash(mi + vec2(1.0, 0.0)), mf.x), mix(hash(mi + vec2(0.0, 1.0)), hash(mi + vec2(1.0, 1.0)), mf.x), mf.y);
    vec3 c = stone * (0.88 + 0.12 * hash(vec2(floor(x), row) + seed) + 0.07 * mottle);
    return mix(c, c * 0.62, joint * 0.3);
}

vec3 entrance(int i, vec2 P, float t, vec4 f) {
    float W = size.x;
    float cw = casing;
    float zf = -wall;
    float depth = hallDepth(t);
    float px = max(depth / focal, 1e-3);
    vec3 Qw = vec3(P, doorZ[i] - wall);
    vec3 col = ashlar(P + vec2(37.0 * float(i), 0.0), px, float(i) * 7.0) * hallLight(Qw, vec3(0.0, 0.0, -1.0));
    col *= 1.0 - 0.6 * exp(-max(outline(P), 0.0) / (1.6 * cw));
    if (cheap) {
        float inArch = arch >= 1.0 && P.y < -0.6 * cw && dArc(P) < -cw ? 1.0 : 0.0;
        float onFrame = 1.0 - smoothstep(0.0, cw, outline(P));
        col = mix(col, mix(jewel0, jewel1, 0.3) * 0.5 * (0.6 + 0.9 * kin), inArch);
        col = mix(col, leadBase * 0.6, onFrame * (1.0 - inArch));
        return hallFog(col, depth);
    }
    if (arch >= 1.0 && P.y < -0.6 * cw && dArc(P) < -cw) {
        float zt = zf + 0.42 * wall;
        vec2 Pt = at(zt);
        float pxt = pxOf(tAt(zt) + pathT0);
        float cov = clamp(0.5 - (dArc(Pt) + cw) / pxt, 0.0, 1.0) * clamp(0.5 - (Pt.y + 0.6 * cw) / pxt, 0.0, 1.0);
        float lo = zf;
        float hi = zt;
        for (int k = 0; k < 7; ++k) {
            float m = 0.5 * (lo + hi);
            if (dArc(at(m)) + cw < 0.0)
                lo = m;
            else
                hi = m;
        }
        float dz = 0.5 * (lo + hi);
        vec2 Pi = at(dz);
        vec3 N = vec3(-normalize(Pi - archCentre(Pi)), 0.0);
        vec3 intr = intrados((dz - zf) / (zt - zf), N, vec3(Pi, dz), pxOf(tAt(dz) + pathT0));
        vec4 ty = tympanum(Pt, pxt, zt);
        col = mix(intr, ty.rgb + intr * (1.0 - ty.a), cov);
    }
    col = f.rgb + col * (1.0 - f.a);
    return hallFog(col, depth);
}

vec3 jamb(int i, vec3 Q, float t, bool upright) {
    float W = size.x;
    float H = size.y;
    float depth = hallDepth(t);
    vec3 N = upright ? vec3(Q.x < W * 0.5 ? 1.0 : -1.0, 0.0, 0.0) : vec3(0.0, Q.y < H * 0.5 ? 1.0 : -1.0, 0.0);
    vec3 L = vec3(Q.xy, Q.z - doorZ[i]);
    vec3 c = reveal((L.z + wall) / wall, upright ? Q.y : Q.x, upright ? H : W, N, L, max(depth / focal, 1e-3), hot * doorLight[i] * 0.25);
    return hallFog(c * (0.35 + hallLight(Q, N)), depth);
}

float leafT(int i, bool left, vec3 ro, vec3 rd, out vec3 hit) {
    float W = size.x;
    float H = size.y;
    float len = left ? doorSeam[i] : W - doorSeam[i];
    float sp = sin(doorPhi[i]);
    float cp = cos(doorPhi[i]);
    vec3 hinge = vec3(left ? 0.0 : W, 0.0, 0.0);
    vec3 n = left ? vec3(sp, 0.0, -cp) : vec3(-sp, 0.0, -cp);
    float den = dot(rd, n);
    if (abs(den) < 1e-5)
        return -1.0;
    float t = dot(hinge - ro, n) / den;
    if (t <= 0.0)
        return -1.0;
    vec3 Q = ro + rd * t;
    float a = dot(Q - hinge, vec3(left ? cp : -cp, 0.0, sp));
    float m = 2.0 * max(hallDepth(t) / focal, 1.0) / max(abs(den), 0.05);
    if (a < -m || a > len + m || Q.y < -m || Q.y > H + m)
        return -1.0;
    hit = vec3(a, Q.y, t);
    return t;
}

vec4 leafShade(int i, bool left, vec3 hit, vec3 rd) {
    float W = size.x;
    float H = size.y;
    float a = hit.x;
    float y = hit.y;
    float ang = doorPhi[i];
    float sp = sin(ang);
    float cp = cos(ang);
    float len = left ? doorSeam[i] : W - doorSeam[i];
    vec3 n = left ? vec3(sp, 0.0, -cp) : vec3(-sp, 0.0, -cp);
    vec3 run = vec3(left ? cp : -cp, 0.0, sp);
    vec3 Q = vec3(left ? 0.0 : W, y, 0.0) + run * a;
    float depth = hallDepth(hit.z);
    float px = max(depth / focal, 1e-3);
    float cosv = clamp(abs(dot(rd, n)), 0.03, 1.0);
    float tilt = clamp(abs(dot(camF, n)), 0.03, 1.0);
    float sx = px / tilt;
    float cov = clamp(0.5 + min(min(a, len - a) / sx, min(y, H - y) / px), 0.0, 1.0);
    if (cov <= 0.0)
        return vec4(0.0);
    vec2 src = vec2(left ? a : W - a, y);
    float lod = clamp(log2(max(px, 1.0)) + 0.5 * log2(1.0 / tilt) + blurK * abs(depth - focus) / max(focus, 1.0) + lodBias, 0.0, 7.0);
    float shown = smoothstep(0.0, 1.0, doorReveal[i]);
    float open_ = 1.0 - smoothstep(0.3, 1.0, ang);
    vec4 c = shown * shotOf(doorSlot[i], src / texSize, lod);
    c.rgb *= 1.0 + swell * doorReveal[i] * (1.0 - doorReveal[i]);
    if (doorPaper[i] > 0.001)
        c = over(c, textureLod(paper, src / texSize, lod) * doorPaper[i]);
    c *= open_;
    float away = smoothstep(0.0, 0.07 * rest, abs(depth - rest));
    float k = glass * max(smoothstep(0.0, 0.55, ang), 0.55 * away);
    vec4 col = c;
    if (k > 0.001) {
        vec3 nf = dot(rd, n) < 0.0 ? n : -n;
        vec3 V = -rd;
        float fres = 0.04 + 0.96 * pow(1.0 - cosv, 5.0);
        vec3 R = reflect(rd, nf);
        float band = exp(-sq((R.x * 0.85 - R.y * 0.3 - 0.18) / 0.12));
        vec3 sky = mix(fogColor * (ink > 0.5 ? 0.45 : 1.6), mix(hot, vec3(1.0), 0.3) * 0.7, smoothstep(-0.5, 0.6, -R.y));
        vec3 env = sky * 0.5 + mix(hot, vec3(1.0), 0.55) * band;
        vec3 L = normalize(lampL - Q);
        float nh = max(dot(nf, normalize(L + V)), 0.0);
        float spec = pow(nh, 900.0) * 0.28 + pow(nh, 80.0) * 0.018;
        float ed = min(min(a, len - a), min(y, H - y));
        float rim = min(a, min(y, H - y));
        float bandW = 0.05 * H;
        float inBand = (1.0 - smoothstep(bandW - 0.7 * sx, bandW + 0.7 * sx, rim)) * smoothstep(0.0, 2.0 * sx, len - a) * (1.0 - smoothstep(0.55, 1.15, ang));
        vec2 gi;
        float ex = lattice(vec2(a, y), vec2(bandW * 0.7, bandW), gi);
        vec3 tint = jewelOf(hash(gi + (left ? 0.0 : 31.0) + float(i) * 5.0)) * (0.55 + 0.45 * hash(gi + 2.0));
        float sheet = k * mix(0.05, 0.34, inBand) * (1.0 - 0.6 * c.a * (1.0 - inBand));
        col = over(c * (1.0 - 0.6 * inBand * k), vec4(mix(edgeGlass * 0.35, tint, inBand) * sheet, sheet));
        float lines = (1.0 - smoothstep(0.6 * sx, 1.6 * sx, ex)) * inBand + (1.0 - smoothstep(0.5 * sx, 1.5 * sx, abs(rim - bandW))) * smoothstep(bandW, bandW + 2.0 * sx, len - a);
        col = over(vec4(came, 1.0) * clamp(lines, 0.0, 1.0) * k * 0.85 * fine(sx * 0.5), col);
        col.rgb += (env * fres * 0.9 + mix(hot, vec3(1.0), 0.4) * spec) * k * (ink > 0.5 ? 0.3 : 1.0);
        float edgeOn = smoothstep(0.02, 0.22, ang);
        float stile = 7.0;
        if (ed < stile + 1.5 * sx && edgeOn > 0.0) {
            float sc = (1.0 - smoothstep(stile - 0.5 * px, stile + 0.5 * px, ed)) * edgeOn;
            vec3 T = ed == a ? run : (ed == len - a ? -run : vec3(0.0, ed == y ? 1.0 : -1.0, 0.0));
            col = over(vec4(molding(ed / stile, stile, n, T, Q, px, 0.0), 1.0) * sc, col);
            col.rgb += keyline * exp(-sq((ed - stile - 0.6 * px) / (0.9 * px))) * 0.4 * edgeOn;
        }
        float leak = sin(PI * clamp(ang / 0.55, 0.0, 1.0)) * glass;
        col.rgb += mix(hot, vec3(1.0), 0.35) * leak * (exp(-(len - a) / (10.0 * px)) * 0.55 + exp(-(len - a) / (90.0 * px)) * 0.16);
    }
    col.rgb = mix(col.rgb, fogColor * col.a, fogOf(depth));
    return col * cov;
}

float lancet(float zl, float y, out float cz) {
    float span = spacing - wall;
    cz = zl < 0.5 * span ? 0.28 * span : 0.72 * span;
    float w = 0.13 * span;
    float u = zl - cz;
    float spring = -0.08 * size.y;
    return y < spring ? length(vec2(u, y - spring)) - w : max(abs(u) - w, y - 0.8 * size.y);
}

vec3 stained(float zl, float y, float cz, float px) {
    vec2 gi;
    float ex = lattice(vec2(zl, y), vec2(90.0, 130.0), gi);
    float sharp = 1.0 - smoothstep(4.0, 14.0, px);
    vec3 t = mix((jewel0 + jewel1 + jewel2) / 3.0 * 0.85, jewelOf(hash(gi + floor(cz))) * (0.6 + 0.5 * hash(gi + 9.0)), sharp);
    return t * (1.0 - 0.85 * (1.0 - smoothstep(0.6 * px, 1.6 * px, ex)) * fine(px));
}

float beamPx = 1.0;

float roomOf(float z) {
    return floor(z / spacing);
}

vec3 beamAt(vec3 Q) {
    float wx = sunDir.x < 0.0 ? size.x + aisle : -aisle;
    float t = (Q.x - wx) / sunDir.x;
    if (t <= 0.0)
        return vec3(0.0);
    vec3 P = Q - sunDir * t;
    if (roomOf(P.z) != roomOf(Q.z) || P.z - roomOf(P.z) * spacing > spacing - wall || Q.z - roomOf(Q.z) * spacing > spacing - wall || P.y < vault)
        return vec3(0.0);
    float cz;
    float zl = P.z - roomOf(P.z) * spacing;
    float sd = lancet(zl, P.y, cz);
    float soft = 4.0 + 0.004 * t;
    float edge = 1.0 - smoothstep(-soft, soft, sd);
    if (edge <= 0.0)
        return vec3(0.0);
    vec3 hue_ = mix(stained(zl, P.y, cz, beamPx + 0.004 * t), jewelOf(hash(vec2(cz, roomOf(P.z)) + 4.0)), 0.5);
    return sun * mix(vec3(1.0), hue_ * 1.8, 0.7) * edge;
}
