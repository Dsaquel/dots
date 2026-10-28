struct GP {
    float sd;
    float d;
    float k;
    float x0;
    float x1;
    float h;
    float lv;
    float psi;
    float kz;
    float off;
    vec2 pc;
    vec2 nr;
    vec2 ends;
    vec2 pops;
    float hot;
    bool ok;
};

GP gpOf(float sd, float k) {
    GP g;
    g.ok = false;
    g.sd = sd;
    g.k = k;
    vec2 e = max(gHG - vec2(radius), vec2(0.0));
    bool arcP = mod(sd, 2.0) > 0.5;
    float c = floor(sd * 0.5 + 0.25);
    float A = 1.5707963 * (radius + SM);
    float len = arcP ? A : 2.0 * (mod(c, 2.0) < 0.5 ? e.x : e.y);
    float n = arcP ? 1.0 : max(1.0, floor(len / pieceLen + 0.5));
    float rel = mod(sd - 2.0 * gM + 8.0, 8.0);
    if (k < -0.5 || k > n - 0.5 || gT >= SLAM || (rel > 2.5 && rel < 5.5))
        return g;
    float seg = len / n;
    g.x0 = k * seg;
    g.x1 = (k + 1.0) * seg;
    float sc = scOf(gLvG);
    if (arcP) {
        vec2 sg = cornerOf(sd);
        g.nr = normalize(sg);
        g.pc = sg * e + sg * 0.70710678 * (radius + sc);
    } else {
        g.nr = normalOf(c);
        g.pc = edgeAt(c, (k + 0.5) * seg, e, gHG) + g.nr * sc;
    }
    g.lv = gLvG;
    g.off = 0.0;
    float dr = 0.0;
    float heave = 0.0;
    g.hot = 0.0;
    if (rel > 1.5 && rel < 6.5) {
        bool flip = dot(dirOf(c), gDir) < 0.0;
        float xn = flip ? len - g.x1 : g.x0;
        float a = gXG + xn;
        if (gNow >= a)
            return g;
        float d = xn + 0.5 * seg;
        g.d = d;
        float dd = clamp(a - gL0, 1.0, DROPD);
        dr = sq(clamp((gNow - a + dd) / dd, 0.0, 1.0));
        g.h = mix(HOVER * hoistOf(d) * waveOf(d), fieldR(a + 0.5 * seg), dr);
        float hsP = mod(c, 2.0) < 0.5 ? gHS.y : gHS.x;
        float hsGP = mod(c, 2.0) < 0.5 ? gHG.y : gHG.x;
        heave = 1.0 - dr;
        g.off = (hsP - dot(gCG, g.nr) - hsGP) * dr;
    } else {
        float lenS = 2.0 * (mod(gM, 2.0) > 0.5 ? e.x : e.y);
        float d = lenS + (arcP ? 0.5 * A : A + min((k + 0.5) * seg, len - (k + 0.5) * seg));
        g.d = d;
        g.h = HOVER * hoistOf(d) * waveOf(d) * windOf() * slamOf();
        heave = slamOf();
        g.hot = pow(1.0 - slamOf(), 2.0);
    }
    float z = g.h / HOVER;
    float up = min(hoistOf(g.d), 1.0);
    g.off += HEAVE * sin(6.2831853 * (g.d / WAVEL - gT / WAVEP)) * up * heave;
    g.ends = arcP ? vec2(2.0) : vec2(k < 0.5 ? 2.0 : 1.0, k > n - 1.5 ? 2.0 : 1.0);
    g.pops = vec2(1.0 - smoothstep(0.0, 0.25, z));
    g.lv = max(g.lv, LIT * smoothstep(0.0, 0.7, max(z, up)));
    g.psi = arcP ? 0.0 : (hash(vec2(sd * 13.0 + k, 3.7)) - 0.5) * 0.08 * z - dot(gDir, vec2(-g.nr.y, g.nr.x)) * HINGE * sin(PI * dr);
    g.kz = 1.0 + POPZ * min(z, 1.4);
    g.ok = true;
    return g;
}

vec2 localOf(GP g, vec2 at) {
    float z = g.h / HOVER;
    vec2 tg = vec2(-g.nr.y, g.nr.x);
    vec2 d = rot(at - g.pc, -g.psi);
    return g.pc + tg * dot(d, tg) / (1.0 - TUCK * z) + g.nr * dot(d, g.nr) / g.kz;
}

vec4 topOf(GP g, vec2 l, vec2 p, float pl) {
    vec2 e = max(gHG - vec2(radius), vec2(0.0));
    float s = sdRoundBox(l, gHG, radius);
    vec4 pm = perim(l, e, radius + SM);
    float hwv = hwOf(g.lv);
    if (abs(pm.y - g.sd) > 0.5 || s < -14.0 || s > offset + hwv + 20.0)
        return vec4(0.0);
    bool arcP = mod(g.sd, 2.0) > 0.5;
    float cut = clamp((pm.z - g.x0) * g.kz + 0.5, 0.0, 1.0) * clamp((g.x1 - pm.z) * g.kz + 0.5, 0.0, 1.0);
    vec3 jewel = arcP ? jewelC : (mod(g.k + g.sd * 0.5, 2.0) < 1.0 ? jewelA : jewelB);
    vec4 col = slabLook(pm.z - g.x0, g.x1 - g.x0, pm.z, g.sd * 97.0 + g.k, jewel, arcP ? 1.0 : 0.0, s, s, gradOf(l, gHG), p, pl, g.lv, g.ends, vec2(g.ends.x > 1.5 ? 1.0 : g.pops.x, g.ends.y > 1.5 ? 1.0 : g.pops.y)) * cut;
    if (arcP)
        col = cabLook(l, cornerOf(g.sd) * (e + vec2(radius + offset - 0.5) * 0.70710678), p, pl, g.lv, 1.0, 0.0, col);
    return col;
}

vec4 drawGP(GP g, vec2 q, vec2 p, float pl) {
    float z = g.h / HOVER;
    vec2 sh = gCG + g.nr * g.off;
    vec2 l0 = localOf(g, unproj(q, g.h) - sh);
    float s0 = sdRoundBox(l0, gHG, radius);
    float hw0 = hwOf(g.lv);
    vec4 col = s0 < -15.0 || s0 > offset + hw0 + 21.0 ? vec4(0.0) : topOf(g, l0, p, pl);
    if (col.a <= 0.0 && (s0 < -WALLW * z - 1.0 || s0 > offset + hw0 + WALLW * z + 1.0))
        return col;
    col.rgb *= 1.0 + 0.18 * z;
    col.rgb = emit(col.rgb, flareOf() * g.hot * 0.9 * col.a);
    col.rgb = emit(col.rgb, (hi * 0.5 + pool * 0.6) * pow(max(sin(6.2831853 * (g.d / WAVEL - gT / WAVEP)), 0.0), 6.0) * GLINT * min(z, 1.0) * col.a);
    if (col.a > 0.98 || z < 0.04)
        return col;
    vec2 wdir = normalize(normalize(gV - g.pc - sh + vec2(1e-3)) * 0.6 - g.nr);
    float hwv = hwOf(g.lv);
    for (int w = 1; w <= 2; ++w) {
        vec2 l = localOf(g, unproj(q - wdir * WALLW * mix(0.6, 1.0, dark) * z * float(w) * 0.5, g.h) - sh);
        vec4 pm = perim(l, max(gHG - vec2(radius), vec2(0.0)), radius + SM);
        float s = sdRoundBox(l, gHG, radius);
        float inB = abs(pm.y - g.sd) < 0.5 ? clamp(s - 0.5, 0.0, 1.0) * clamp(offset + hwv + 0.5 - s, 0.0, 1.0) * clamp((pm.z - g.x0) * g.kz + 0.5, 0.0, 1.0) * clamp((g.x1 - pm.z) * g.kz + 0.5, 0.0, 1.0) : 0.0;
        if (inB <= 0.0)
            continue;
        vec3 jewel = mod(g.sd, 2.0) > 0.5 ? jewelC : (mod(g.k + g.sd * 0.5, 2.0) < 1.0 ? jewelA : jewelB);
        float lead = smoothstep(offset - hwv - 1.0, offset - hwv + 0.5, s);
        vec3 wc = mix(mix(jewel * 0.6 + base * 0.25, base * 0.55 + low * 0.2, lead), mix(jewel * 0.3 + low * 0.35, base * 0.35 + low * 0.4, lead), dark) * (0.75 + 0.45 * pl) * (0.8 + 0.25 * float(w));
        col = over(col, vec4(wc, 1.0) * inB * 0.94);
    }
    return col;
}

void shadowGP(GP g, vec2 q, inout float shade, inout vec3 light) {
    float z = g.h / HOVER;
    if (z < 0.03)
        return;
    vec2 l = localOf(g, caster(q, g.h, flipAt(gCG + g.pc + g.nr * g.off, g.h)) - gCG - g.nr * g.off);
    vec4 pm = perimNear(l, gHG);
    if (abs(pm.y - g.sd) > 0.5)
        return;
    float s = sdRoundBox(l, gHG, radius);
    float hwv = hwOf(g.lv);
    float blur = 1.2 + 0.32 * g.h;
    float d = max(max(0.6 - s, s - offset - hwv), max(g.x0 - pm.z, pm.z - g.x1));
    float cov = (1.0 - smoothstep(-blur, blur, d)) * smoothstep(0.0, 0.3, z);
    float lead = smoothstep(offset - hwv - 1.5, offset - hwv + 1.5, s);
    shade += cov * (0.2 + 0.28 * lead) * min(z, 1.3);
    vec3 jewel = mod(g.sd, 2.0) > 0.5 ? jewelC : (mod(g.k + g.sd * 0.5, 2.0) < 1.0 ? jewelA : jewelB);
    light += jewel * cov * (1.0 - lead) * 0.16 * dark * min(z, 1.3);
}
