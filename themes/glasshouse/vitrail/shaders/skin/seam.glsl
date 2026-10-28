vec4 seamOf(vec2 q, vec2 p, float pl, inout float shade, inout vec3 light) {
    if (gT > CLAPT + CRUMT)
        return vec4(0.0);
    float hsA = mod(gM, 2.0) > 0.5 ? gHS.x : gHS.y;
    float hsAG = mod(gM, 2.0) > 0.5 ? gHG.x : gHG.y;
    float gap = gHG.x < 1.0 ? 0.0 : dot(gCG, gDir) - hsAG - hsA;
    float gp = max(gap, 0.0);
    float along = dot(q, gDir) - hsA;
    float hsP = mod(gM, 2.0) > 0.5 ? gHS.y : gHS.x;
    float across = abs(dot(q, vec2(-gDir.y, gDir.x)));
    if (along < -60.0 || along > gp + 60.0 || across > hsP + offset + 50.0)
        return vec4(0.0);
    float lift = CLAPH * outBack(gT / 45.0);
    float slide = max(0.5 * gp - scOf(on), 0.0) * smoothstep(5.0, CLAPT, gT) - OPEN * sin(PI * clamp(gT / CLAPT, 0.0, 1.0));
    float u = clamp((gT - CLAPT) / CRUMT, 0.0, 1.0);
    vec4 acc = crumbled(q, vec2(0.0), gHS, 2.0 * gM, gDir * slide, on, 0.0, lift, u, p, pl, shade);
    if (gHG.x > 1.0)
        acc = over(crumbled(q, gCG, gHG, mod(2.0 * gM + 4.0, 8.0), gDir * (max(-gap, 0.0) - slide), max(gLvG, LIT * smoothstep(0.0, 35.0, gT)), 1.0, lift, u, p, pl, shade), acc);
    float fl = gT < CLAPT ? exp(-sq((gT - CLAPT) / 7.0)) : exp(-(gT - CLAPT) / 32.0);
    if (fl > 0.003) {
        float dl = along - 0.5 * gp;
        float reach = clamp(hsP + 4.0 - across + 0.5, 0.0, 1.0);
        float glint = pow(vnoise(vec2(across * 0.11, gT * 0.05)), 6.0) * 5.0;
        light += flareOf() * (exp(-sq(dl / 3.5)) * (1.2 + glint) + exp(-abs(dl) / 10.0) * 0.4) * fl * reach;
    }
    return acc;
}

vec4 afterR(vec2 q, vec2 p, float pl, inout float shade, inout vec3 light) {
    float age = gT - SLAM;
    vec2 e = max(gHS - vec2(radius), vec2(0.0));
    float s = sdRoundBox(q, gHS, radius);
    if (s < -60.0 || s > 96.0)
        return vec4(0.0);
    float rr = radius + SM;
    float A = 1.5707963 * rr;
    float per = 4.0 * (e.x + e.y) + 4.0 * A;
    float pv = max(PULSEV, (0.5 * per + PULSEV * REPOP) / 160.0);
    vec4 pm = perimNear(q, gHS);
    float um = gM < 0.5 ? e.x : (gM < 1.5 ? 2.0 * e.x + A + e.y : (gM < 2.5 ? 3.0 * e.x + 2.0 * A + 2.0 * e.y : 4.0 * e.x + 3.0 * A + 3.0 * e.y));
    float du = circ(pm.x, um, per);
    float front = age * pv;
    float decay = exp(-age / PULSET);
    float wave = exp(-sq((du - front) / max(PULSEW, 12.0 * pv))) * decay;
    float rel = mod(pm.y - 2.0 * gM + 8.0, 8.0);
    bool endS = rel < 1.5 || rel > 6.5;
    bool growing = abs(rel - 2.0) < 0.5 || abs(rel - 6.0) < 0.5;
    float kick = KICK * wave + (endS ? 6.0 * exp(-age / 18.0) * cos(age * 0.15) + (scOf(on) - s) * 0.45 * exp(-age / 24.0) : 0.0);
    float repop = du < front ? 0.35 + 0.65 * outBack((front - du) / (pv * REPOP)) : 1.0;
    vec4 col;
    if (growing && du > front) {
        float c = floor(pm.y * 0.5 + 0.25);
        vec2 nrm = normalOf(c);
        float hsP = mod(c, 2.0) < 0.5 ? gHS.y : gHS.x;
        float hsA = mod(gM, 2.0) > 0.5 ? gHS.x : gHS.y;
        float xa = dot(q - nrm * hsP + gDir * (hsA - radius), gDir);
        float lock;
        col = mergedLook(xa, s + kick, s, c, gLf, p, pl, lock);
        col = cabLook(q, sign(q) * (e + vec2(radius + offset - 0.5) * 0.70710678), p, pl, on, 1.0 + 0.3 * wave, wave, col);
    } else {
        vec4 pmL;
        col = ringLook(q, gHS, kick, p, pl, endS ? mix(max(gLvG, LIT), on, smoothstep(0.0, COOL, age)) : on, vec2(repop), wave + (endS ? exp(-age / 30.0) : 0.0), pmL);
    }
    float hwv = hwOf(on);
    float sB = s + kick;
    float bandM = clamp(sB - 0.5, 0.0, 1.0) * clamp(offset - hwv - sB + 0.5, 0.0, 1.0);
    float cameM = clamp(hwv + 0.5 - abs(sB - offset), 0.0, 1.0);
    float hit = endS ? (exp(-age / 16.0) * 0.9 + exp(-age / 110.0) * 0.22) * (1.0 - smoothstep(150.0, 200.0, age)) : 0.0;
    col.rgb = emit(col.rgb, (flareOf() * cameM * 1.1 + col.rgb * bandM * mix(0.8, 1.2, dark)) * (wave + hit));
    if (age < 160.0) {
        float o = offset + hwv;
        float go = 1.0 - exp(-age / 40.0);
        float hsA = mod(gM, 2.0) > 0.5 ? gHS.x : gHS.y;
        float hsT = mod(gM, 2.0) > 0.5 ? gHS.y : gHS.x;
        float reach = smoothstep(hsA - 90.0, hsA - 45.0, dot(q, gDir)) * (1.0 - smoothstep(hsT + 10.0, hsT + 60.0, abs(dot(q, vec2(-gDir.y, gDir.x))))) * (1.0 - smoothstep(120.0, 160.0, age));
        float ring = exp(-sq((s - o - 3.0 - 44.0 * go) / (3.0 + 0.05 * age))) * exp(-age / 60.0) * reach;
        col = over(col, vec4(mix(jewelC, hot, 0.25), 1.0) * clamp(ring * 0.5, 0.0, 0.5) * dark);
        light += flareOf() * ring * 0.6;
        float dEnd = dot(q, gDir) - hsA;
        float side = 1.0 - smoothstep(hsT - 40.0, hsT, abs(dot(q, vec2(-gDir.y, gDir.x))));
        light += (jewelA + jewelB) * mix(0.3, 0.6, dark) * exp(-sq((dEnd + 3.0 + 36.0 * go) / (4.0 + 0.04 * age))) * exp(-age / 70.0) * side * (1.0 - smoothstep(120.0, 160.0, age));
    }
    return col;
}
