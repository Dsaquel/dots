int candidates(vec4 pm, out vec2 cs[4]) {
    float sd = pm.y;
    int n = 0;
    float rel = mod(sd - 2.0 * gM + 8.0, 8.0);
    vec2 e = max(gHG - vec2(radius), vec2(0.0));
    if (abs(rel - 3.0) < 0.5 || abs(rel - 5.0) < 0.5) {
        float sp = abs(rel - 3.0) < 0.5 ? mod(sd - 1.0, 8.0) : mod(sd + 1.0, 8.0);
        float lp = 2.0 * (mod(floor(sp * 0.5 + 0.25), 2.0) < 0.5 ? e.x : e.y);
        cs[0] = vec2(sp, abs(rel - 3.0) < 0.5 ? max(1.0, floor(lp / pieceLen + 0.5)) - 1.0 : 0.0);
        return 1;
    }
    if (rel > 2.5 && rel < 5.5)
        return 0;
    if (mod(sd, 2.0) > 0.5) {
        cs[0] = vec2(sd, 0.0);
        float sp = mod(sd - 1.0, 8.0);
        float lp = 2.0 * (mod(floor(sp * 0.5 + 0.25), 2.0) < 0.5 ? e.x : e.y);
        cs[1] = vec2(sp, max(1.0, floor(lp / pieceLen + 0.5)) - 1.0);
        cs[2] = vec2(mod(sd + 1.0, 8.0), 0.0);
        return 3;
    }
    float nn = max(1.0, floor(pm.w / pieceLen + 0.5));
    float seg = pm.w / nn;
    float k0 = clamp(floor(pm.z / seg), 0.0, nn - 1.0);
    cs[0] = vec2(sd, k0);
    cs[1] = vec2(sd, k0 - 1.0);
    cs[2] = vec2(sd, k0 + 1.0);
    n = 3;
    if (pm.z < 56.0)
        cs[3] = vec2(mod(sd - 1.0, 8.0), 0.0);
    else if (pm.z > pm.w - 56.0)
        cs[3] = vec2(mod(sd + 1.0, 8.0), 0.0);
    else
        return n;
    return 4;
}

vec4 floatG(vec2 q, vec2 p, float pl, inout float shade, inout vec3 light) {
    if (gT >= SLAM || gHG.x < 1.0)
        return vec4(0.0);
    float sG = sdRoundBox(q - gCG, gHG, radius);
    float sr = 1.2 * 1.45 * HOVER * windOf();
    if (sG < -30.0 - sr || sG > 40.0 + sr)
        return vec4(0.0);
    float hg = HOVER * windOf() * min(gT / UPT, 1.0);
    vec2 cs[4];
    int n = candidates(perimNear(caster(q, hg, flipAt(q, hg)) - gCG, gHG), cs);
    for (int i = 0; i < 4; ++i) {
        if (i >= n)
            break;
        GP g = gpOf(cs[i].x, cs[i].y);
        if (g.ok)
            shadowGP(g, q, shade, light);
    }
    n = candidates(perimNear(unproj(q, hg) - gCG, gHG), cs);
    vec4 cols[4];
    float zs[4];
    for (int i = 0; i < 4; ++i) {
        cols[i] = vec4(0.0);
        zs[i] = 1e3;
        if (i >= n)
            continue;
        GP g = gpOf(cs[i].x, cs[i].y);
        if (!g.ok)
            continue;
        cols[i] = drawGP(g, q, p, pl);
        zs[i] = cols[i].a > 0.0 ? g.h : 1e3;
    }
    vec4 acc = vec4(0.0);
    for (int m = 0; m < 4; ++m) {
        int best = -1;
        float lowest = 2e3;
        for (int j = 0; j < 4; ++j)
            if (zs[j] < lowest) {
                lowest = zs[j];
                best = j;
            }
        if (best < 0 || lowest > 999.0)
            break;
        acc = over(cols[best], acc);
        zs[best] = 2e3;
    }
    return acc;
}

vec4 crumbled(vec2 q, vec2 ctr, vec2 hsW, float sv, vec2 mv, float lv, float w, float lift, float u, vec2 p, float pl, inout float shade) {
    vec2 e = max(hsW - vec2(radius), vec2(0.0));
    float hf = lift * (1.0 - u) - 26.0 * u * u;
    vec2 qc = unproj(q, hf) - ctr - mv;
    vec4 pm0 = perimNear(qc, hsW);
    float rel = mod(pm0.y - sv + 8.0, 8.0);
    if (rel > 1.5 && rel < 6.5)
        return vec4(0.0);
    float sc = scOf(lv);
    vec4 acc = vec4(0.0);
    for (int j = -1; j <= 1; ++j) {
        bool arcP = mod(pm0.y, 2.0) > 0.5;
        float n = arcP ? 1.0 : max(1.0, floor(pm0.w / pieceLen + 0.5));
        float seg = pm0.w / n;
        float fs = arcP ? pm0.w : seg / 3.0;
        float f = arcP ? 0.0 : clamp(floor(pm0.z / fs), 0.0, 3.0 * n - 1.0) + float(j);
        if ((arcP && j != 0) || f < -0.5 || f > (arcP ? 0.5 : 3.0 * n - 0.5))
            continue;
        float xc = (f + 0.5) * fs;
        float c = floor(pm0.y * 0.5 + 0.25);
        vec2 sg = cornerOf(pm0.y);
        vec2 nr = arcP ? normalize(sg) : normalOf(c);
        vec2 pc = arcP ? sg * e + sg * 0.70710678 * (radius + sc) : edgeAt(c, xc, e, hsW) + nr * sc;
        vec3 hh = vec3(hash(vec2(f + 31.0 * w + pm0.y * 7.0, 1.3)), hash(vec2(f + 31.0 * w + pm0.y * 7.0, 4.1)), hash(vec2(f + 31.0 * w + pm0.y * 7.0, 8.7)));
        vec2 tg = vec2(-nr.y, nr.x);
        vec2 drift = (tg * (hh.x - 0.5) * 22.0 + nr * (hh.y - 0.3) * 16.0) * 2.0 * (1.0 - sq(1.0 - u)) * min(1.0, fs / 24.0);
        float psi = (hh.z - 0.5) * 3.4 * u;
        float kt = 1.0 - 0.5 * u;
        float kn = (1.0 + 0.3 * max(hf, 0.0) / CLAPH) * kt;
        vec2 d = rot(qc - drift - pc, -psi);
        vec2 l = pc + tg * dot(d, tg) / kt + nr * dot(d, nr) / kn;
        float s = sdRoundBox(l, hsW, radius);
        vec4 pm = perim(l, e, radius + SM);
        if (abs(pm.y - pm0.y) > 0.5 || s < -14.0 || s > offset + hwOf(lv) + 20.0)
            continue;
        float x0 = arcP ? 0.0 : f * fs;
        float cut = arcP ? 1.0 : clamp((pm.z - x0) * kt + 0.5, 0.0, 1.0) * clamp((x0 + fs - pm.z) * kt + 0.5, 0.0, 1.0);
        float k = arcP ? 0.0 : floor(f / 3.0);
        vec3 jewel = arcP ? jewelC : (mod(k + pm.y * 0.5, 2.0) < 1.0 ? jewelA : jewelB);
        vec2 ends = arcP ? vec2(2.0) : vec2(k < 0.5 ? 2.0 : 1.0, k > n - 1.5 ? 2.0 : 1.0);
        vec4 c4 = slabLook(pm.z - k * seg, seg, pm.z, pm.y * 97.0 + k, jewel, arcP ? 1.0 : 0.0, s, s, gradOf(l, hsW), p, pl, lv * (1.0 - u), ends, vec2(1.0)) * cut;
        if (arcP && w > 0.5)
            c4 = cabLook(l, sg * (e + vec2(radius + offset - 0.5) * 0.70710678), p, pl, lv, 1.0, 0.0, c4);
        c4.rgb *= (1.0 + 0.2 * max(hf, 0.0) / CLAPH) * (1.0 - 0.7 * u * u);
        acc = u < 0.02 ? acc + c4 : over(c4 * (1.0 - u * u * u), acc);
    }
    if (hf > 0.5) {
        vec2 qs = caster(q, hf, flipAt(q, hf)) - ctr - mv;
        vec4 pmS = perimNear(qs, hsW);
        float relS = mod(pmS.y - sv + 8.0, 8.0);
        float sS = sdRoundBox(qs, hsW, radius);
        if (relS < 1.5 || relS > 6.5)
            shade += 0.4 * (hf / CLAPH) * (1.0 - u) * (1.0 - smoothstep(-1.5 - 0.3 * hf, 1.5 + 0.3 * hf, max(0.6 - sS, sS - offset - hwOf(lv))));
    }
    return acc;
}
