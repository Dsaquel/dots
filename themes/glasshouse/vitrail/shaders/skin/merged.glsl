vec4 mergedLook(float xr, float sB, float ys, float c, float vis, vec2 p, float pl, out float lock) {
    lock = 0.0;
    vec4 pc = pieceAt(xr);
    float run = pc.w;
    float n = run < 0.5 ? gN0 : (run < 1.5 ? 1.0 : gNG);
    float seg = run > 0.5 && run < 1.5 ? min(min(gNow, gXG), vis) - gL0 : pc.y;
    if (seg < 0.5)
        return vec4(0.0);
    float fx = xr - pc.x;
    bool flip = dot(dirOf(c), gDir) < 0.0;
    float k = pc.z;
    bool bridgeEnd = run > 0.5 && run < 1.5 && (gNow < gXG || gLG < 1.0);
    vec2 ends = vec2(run < 0.5 && k < 0.5 ? 2.0 : 1.0, (run > 1.5 && k > gNG - 1.5) || bridgeEnd || (run < 0.5 && k > gN0 - 1.5 && gNow < gL0 + 3.0) ? 2.0 : 1.0);
    vec2 pop = vec2(1.0);
    float lv = on;
    if (run < 0.5)
        pop.y = k > gN0 - 1.5 ? max(outBack((gNow - gL0) / 30.0), 1.0 - smoothstep(0.0, CLAPT, gT)) : 1.0;
    else if (run < 1.5)
        pop = vec2(outBack((gNow - gL0) / 30.0), outBack((gNow - gXG) / 46.0));
    else {
        float d = max(gNow - pc.x, 0.0);
        pop = vec2(outBack(d / 46.0), k > gNG - 1.5 ? 1.0 : outBack((gNow - pc.x - pc.y) / 46.0));
        lock = exp(-d / LOCKD);
        lv = mix(max(gLvG, LIT), on, smoothstep(0.0, COOL, d));
    }
    float kp = flip ? n - 1.0 - k : k;
    float xp = run < 0.5 ? (flip ? gL0 - xr : xr) : (run > 1.5 ? (flip ? gLf - xr : xr - gXG) : xr);
    vec3 jewel = mod(kp + c + (run > 0.5 && run < 1.5 ? 1.0 : 0.0), 2.0) < 1.0 ? jewelA : jewelB;
    vec4 col = slabLook(flip ? seg - fx : fx, seg, xp, 2.0 * c * 97.0 + kp + (run > 0.5 && run < 1.5 ? 41.0 : 0.0), jewel, 0.0, sB, ys, vec2(normalOf(c).x, -normalOf(c).y), p, pl, lv, flip ? ends.yx : ends, flip ? pop.yx : pop);
    if (lock > 0.003) {
        float sc = scOf(on);
        float glow = exp(-(sq(fx) + 2.0 * sq(sB - sc)) / 26.0) * 1.6 + exp(-fx / 22.0) * clamp(sB + 0.5, 0.0, 1.0) * clamp(offset + hwOf(lv) - sB + 0.5, 0.0, 1.0) * 0.45;
        col.rgb = emit(col.rgb, flareOf() * glow * lock * max(col.a, 0.3));
    }
    return col;
}

vec4 sideR(vec2 q, float c, vec2 p, float pl, inout float shade) {
    vec2 nrm = normalOf(c);
    float hsP = mod(c, 2.0) < 0.5 ? gHS.y : gHS.x;
    float hsA = mod(gM, 2.0) > 0.5 ? gHS.x : gHS.y;
    vec2 a0 = nrm * hsP - gDir * (hsA - radius);
    float xa = dot(q - a0, gDir);
    float ys = dot(q, nrm) - hsP;
    float vis = visEnd();
    if (ys < -56.0 || ys > 60.0 || xa < -4.0 || xa > vis + 60.0)
        return vec4(0.0);
    float hwv = hwOf(on);
    float sc = scOf(on);
    float h = fieldR(clamp(xa, 0.0, vis));
    if (h > 0.2) {
        vec2 qs = caster(q, h, flipAt(q, h));
        float xs = dot(qs - a0, gDir);
        float ss = sc + (dot(qs, nrm) - hsP - sc) / (1.0 + POPZ * h / HOVER);
        float blur = 0.8 + 0.25 * h;
        float d = max(max(0.6 - ss, ss - offset - hwv), max(-xs, xs - vis));
        shade += (0.26 + 0.24 * smoothstep(offset - hwv - 1.5, offset - hwv + 1.5, ss)) * min(h / HEAD, 1.2) * (1.0 - smoothstep(-blur, blur, d));
    }
    vec2 qq = unproj(q, h);
    h = fieldR(clamp(dot(qq - a0, gDir), 0.0, vis));
    qq = unproj(q, h);
    float xr = dot(qq - a0, gDir);
    if (xr < -0.5 || xr > vis + 0.5)
        return vec4(0.0);
    float sr = sc + (dot(qq, nrm) - hsP - sc) / (1.0 + POPZ * h / HOVER);
    float lock;
    vec4 col = mergedLook(xr, sr, ys, c, vis, p, pl, lock);
    col.rgb *= 1.0 + 0.2 * h / HOVER;
    return col * clamp(vis - xr + 0.5, 0.0, 1.0) * clamp(xr + 0.5, 0.0, 1.0);
}

vec4 clasp(vec2 q, float c, vec2 p, float pl, inout float shade) {
    vec2 nrm = normalOf(c);
    float hsP = mod(c, 2.0) < 0.5 ? gHS.y : gHS.x;
    float hsA = mod(gM, 2.0) > 0.5 ? gHS.x : gHS.y;
    vec2 cq = gDir * (hsA - radius) + nrm * (hsP - radius) + (gDir + nrm) * 0.70710678 * (radius + offset - 0.5);
    if (dot(q - cq, q - cq) > 2304.0)
        return vec4(0.0);
    float h = headOf(gNow);
    float kL = lastLock();
    float dg = max(kL < 0.0 ? gNow - gL0 : gNow - gXG - kL * gSG, 0.0) / LOCKD;
    float dp = kL < 0.0 ? 1e3 : dg + (kL < 0.5 ? gXG - gL0 : gSG) / LOCKD;
    float got = max(dg * exp(1.0 - dg), dp * exp(1.0 - dp));
    float big = (1.0 + 0.45 * h / HEAD) * (1.0 + 0.7 * got);
    vec2 qs = caster(q, h, flipAt(cq, h));
    shade += 0.45 * min(h / HEAD, 1.0) * (1.0 - smoothstep(3.0 * big, 4.5 * big + 0.3 * h, length(qs - cq)));
    vec4 col = cabLook(unproj(q, h), cq, p, pl, on, big, got, vec4(0.0));
    return col;
}
