vec4 slabLook(float fx, float seg, float xp, float id, vec3 jewel, float arcK, float sB, float s, vec2 g, vec2 p, float pl, float lv, vec2 ends, vec2 pop) {
    float hwv = hwOf(lv);
    float b0 = 1.0;
    float b1 = offset - hwv;
    float sb = 0.5 * (b0 + b1);
    float bw = max(b1 - b0, 0.5);
    float ca = call.a;
    vec2 tg = vec2(g.y, -g.x);
    bool first = fx < 0.5 * seg;
    float xj = first ? fx : fx - seg;
    float pk = first ? pop.x : pop.y;
    vec4 col = vec4(0.0);
    col.rgb += (jewel * 0.7 + pool * pl * 0.6) * lv * exp(-max(sB - offset - hwv, 0.0) / 6.0) * step(offset, sB) * 0.35;
    col.rgb += (jewel * 0.6 + pool * 0.5 + hi * 0.15) * lv * exp(min(s, 0.0) / 4.0) * step(s, 0.0) * (0.1 + 0.12 * pl);
    col.rgb += call.rgb * ca * exp(-max(sB - offset - hwv, 0.0) / 7.0) * step(offset, sB) * 0.9;
    float bandShape = clamp(sB - b0 + 0.5, 0.0, 1.0) * clamp(b1 - sB + 0.5, 0.0, 1.0);
    if (bandShape > 0.0) {
        float streak = 0.9 + 0.2 * vnoise(vec2(xp * 0.07 + id * 3.1, (sB - sb) * 0.3 + id));
        float across = (sB - sb) / (bw * 0.5);
        vec3 amber = jewelC - (1.0 - unlit) * 0.6 * dot(jewelC, vec3(0.2126, 0.7152, 0.0722));
        vec3 dk = mix(jewel * unlit, amber, arcK) * streak + sky * 0.16 * smoothstep(-0.2, 1.0, across) * (0.6 + 0.4 * streak);
        vec3 br = tame(jewel * (1.0 + 0.3 * pl) * streak + jewel * jewel * 0.35 + pool * pl * 0.1);
        vec3 glass = mix(mix(dk, br, lv), call.rgb * (0.9 + 0.3 * streak), ca * 0.65);
        col = vec4(glass, 1.0) * bandShape * 0.95 + col * (1.0 - bandShape * 0.95);
    }
    float dp = 1e5;
    if (abs(ends.x - 1.0) < 0.5)
        dp = fx;
    if (abs(ends.y - 1.0) < 0.5)
        dp = min(dp, seg - fx);
    float pr = (bw * 0.5 + 0.15) * pk;
    float pd = length(vec2(dp, sB - sb));
    float pearlCov = pr > 0.05 ? clamp(pr - pd + 0.5, 0.0, 1.0) : 0.0;
    if (pearlCov > 0.0) {
        float nz = sqrt(max(1.0 - sq(pd / pr), 0.0));
        vec2 pv = (tg * xj + g * (sB - sb)) / pr;
        vec3 pc = metal(normalize(vec3(pv * 0.9, nz + 0.05)), p, nz, pl) * mix(1.05, 1.25, lv);
        pc += call.rgb * ca * (0.5 + 0.6 * nz);
        col = vec4(pc, 1.0) * pearlCov + col * (1.0 - pearlCov);
    }
    float le = 1e5;
    if (ends.x > 1.5)
        le = fx;
    if (ends.y > 1.5)
        le = min(le, seg - fx);
    float lead = max(clamp(1.05 - abs(sB - b0), 0.0, 1.0), clamp(1.1 - le, 0.0, 1.0) * bandShape);
    if (lead > 0.0)
        col = vec4(metal(vec3(0.0, 0.0, 1.0), p, 0.7, pl) * 0.55, 1.0) * lead + col * (1.0 - lead);
    float dc = sB - offset;
    float cov = clamp(hwv + 0.5 - abs(dc), 0.0, 1.0);
    float br = (hwv + mix(0.5, 0.9, lv)) * pk;
    float bd = length(vec2(min(fx, seg - fx), dc));
    float beadCov = br > 0.05 ? clamp(br - bd + 0.5, 0.0, 1.0) : 0.0;
    float shape = max(cov, beadCov);
    if (shape > 0.0) {
        float bead = step(cov, beadCov);
        vec2 dv = bead > 0.5 ? (tg * xj + g * dc) / br : g * clamp(dc / max(hwv, 0.5), -1.0, 1.0);
        float h = sqrt(max(1.0 - dot(dv, dv), 0.0));
        col = vec4(metal(normalize(vec3(dv / max(h, 0.2) * 1.1, 1.0)), p, h, pl) * (1.0 + 0.15 * bead), 1.0) * shape + col * (1.0 - shape);
    }
    return col;
}

vec4 cabLook(vec2 q, vec2 cq, vec2 p, float pl, float lv, float big, float got, vec4 col) {
    float cd = length(q - cq);
    float ca = call.a;
    float cr = (3.4 + 0.8 * lv + 2.4 * ca) * big;
    if (cd > cr + 1.5)
        return col;
    vec3 amber = jewelC - (1.0 - unlit) * 0.6 * dot(jewelC, vec3(0.2126, 0.7152, 0.0722));
    float cabCov = clamp(cr - cd + 0.5, 0.0, 1.0);
    float nz = sqrt(max(1.0 - sq(cd / cr), 0.0));
    vec3 cc = mix(amber * 1.1, jewelC * 1.25, lv) * (0.55 + 0.45 * nz) + vec3(1.0) * pow(nz, 12.0) * 0.5;
    cc = mix(cc, call.rgb * (0.9 + 0.6 * nz), ca * 0.85) + jewelC * got * 0.3 * nz;
    float ring = clamp(0.9 + 0.5 - abs(cd - cr), 0.0, 1.0);
    vec3 rc = metal(normalize(vec3((q - cq) / max(cd, 1e-3) * 0.6, 1.0)), p, 0.8, pl);
    col = vec4(cc, 1.0) * cabCov + col * (1.0 - cabCov);
    return vec4(rc, 1.0) * ring + col * (1.0 - ring);
}

vec4 ringLook(vec2 q, vec2 hs, float kick, vec2 p, float pl, float lv, vec2 pop, float got, out vec4 pm) {
    vec2 e = max(hs - vec2(radius), vec2(0.0));
    float s = sdRoundBox(q, hs, radius);
    pm = perimNear(q, hs);
    if (s + kick < -12.0 || s + kick > offset + hwOn + 18.0)
        return vec4(0.0);
    float side = pm.y;
    float x = pm.z;
    float len = pm.w;
    bool arc = mod(side, 2.0) > 0.5;
    float n = arc ? 1.0 : max(1.0, floor(len / pieceLen + 0.5));
    float seg = len / n;
    float k = min(floor(x / seg), n - 1.0);
    vec3 jewel = arc ? jewelC : (mod(k + side * 0.5, 2.0) < 1.0 ? jewelA : jewelB);
    vec2 ends = arc ? vec2(2.0) : vec2(k < 0.5 ? 2.0 : 1.0, k > n - 1.5 ? 2.0 : 1.0);
    vec4 col = slabLook(x - k * seg, seg, x, side * 97.0 + k, jewel, arc ? 1.0 : 0.0, s + kick, s, gradOf(q, hs), p, pl, lv, ends, pop);
    return cabLook(q, sign(q) * (e + vec2(radius + offset - 0.5) * 0.70710678), p, pl, lv, 1.0 + 0.3 * got, got, col);
}
