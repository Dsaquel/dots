float settleOf() {
    float y = 0.0;
    for (int i = 0; i < 32; ++i) {
        float c = float(i);
        if (c >= grid.y)
            break;
        float x = t - landOf(c);
        y += x > 0.0 && x < SETTLED ? sin(PI * x / SETTLED) : 0.0;
    }
    return SETTLE * scale * min(y, 1.0);
}

vec4 seated(vec2 p) {
    float c = courseOf(bandOf(p));
    float land = landOf(c);
    float cov = unit(0.5 - hullOf(p));
    if (t < land || cov <= 0.0)
        return vec4(0.0);
    vec2 q = p - vec2(0.0, settleOf());
    float strength = mix(1.0, LEADED, unit((t - land) / COOLED));
    vec4 col = over(leadOf(q, strength, 0.0, exp(-(t - land) / 16.0), GLOSS), tap(q));
    return flush(over(beadOf(q, strength), col), cov);
}

vec4 frameOf(vec2 p, vec4 acc) {
    float z = 1.0 - easeOf((t - seat.w) / (weld.x - seat.w));
    vec2 C = box.xy + 0.5 * box.zw;
    vec2 O = castOf(C) * FRAMECAST * scale * z;
    float b = (1.0 + 4.0 * z) * scale;
    float sa = 0.0;
    for (int i = 0; i < 4; ++i) {
        vec2 q = p - O + b * vec2(i % 2 == 0 ? -0.5 : 0.5, i < 2 ? -0.5 : 0.5);
        sa += tap(q).a * (1.0 - unit(0.5 - hullOf(q)));
    }
    sa *= 0.25 * umbra.a * 2.0 * smoothstep(0.0, 0.15, z);
    acc = over(vec4(umbra.rgb * sa, sa), acc);
    vec2 q = C + (p - C) / (1.0 + FRAMEPOP * z);
    vec4 rim = tap(q) * (1.0 - unit(0.5 - hullOf(q)));
    shine += 0.4 * z * rim.a;
    return over(flush(rim, 1.0), acc);
}

vec4 flying(vec2 p, float c, vec4 acc) {
    float land = landOf(c);
    float start = land - fallOf(c);
    if (t < start || t >= land)
        return acc;
    float z = 1.0 - easeOf((t - start) / (land - start));
    float s = 1.0 + pop * z;
    vec2 A = middleOf(c);
    vec2 D = vec2(0.0, -DROP * scale * z);
    float b = (1.0 + BLUR * z) * scale;
    float a = umbra.a * smoothstep(-b, b, within(p - D - castOf(A) * CAST * scale * z, c));
    acc = over(vec4(umbra.rgb * a, a), acc);
    vec2 p0 = A + (p - A - D) / s;
    float cov = unit(0.5 + within(p0, c) * s);
    if (cov <= 0.0)
        return acc;
    vec2 n;
    float ex = edgeOf(p0, n);
    float rim = within(p0, c);
    float bevel = exp(-max(rim, 0.0) / (2.5 * scale)) * z;
    float facing = rim < ex + 0.5 ? dot(n, normalize(lamp - A)) : 0.0;
    vec4 col = tap(p0);
    col.rgb *= 1.0 + NEAR * z - 0.35 * bevel * max(-facing, 0.0);
    shine += 0.9 * bevel * max(facing, 0.0);
    col = over(leadOf(p0, 1.0, 0.0, 0.0, 3.0 * GLOSS * z), col);
    return over(flush(col, cov), acc);
}
