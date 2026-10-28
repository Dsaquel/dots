float popOf(float c) {
    return outBack((t - CRACK * pow(1.0 - unit(abs(middleOf(c).y - box.y - 0.5 * box.w) / (0.5 * box.w)), 0.8)) / POPPED);
}

float climbOf(float c) {
    float k = unit((t - leaveOf(c)) / lift.w);
    return 0.45 * k + 0.55 * k * k;
}

vec2 liftOf(vec2 p, float c, float up, float climb) {
    vec2 A = middleOf(c);
    vec2 C = box.xy + 0.5 * box.zw;
    vec2 q = A + (p - A + vec2(0.0, RISE * scale * climb)) / (1.0 + LOFT * climb);
    return C + (q - C + vec2(0.0, JUMP * scale * up)) / (1.0 + SPRING * up);
}

vec4 course(vec2 p, float c) {
    float up = popOf(c);
    float climb = climbOf(c);
    float h = UNSEAT * up + (1.0 - UNSEAT) * climb;
    vec2 p0 = liftOf(p, c, up, climb);
    float rim = within(p0, c);
    float cov = unit(0.5 + rim * (1.0 + LOFT * h));
    if (cov <= 0.0)
        return vec4(0.0);
    vec2 n;
    float ex = edgeOf(p0, n);
    float bevel = exp(-max(rim, 0.0) / (2.5 * scale)) * climb;
    float facing = rim < ex + 0.5 ? dot(n, normalize(lamp - middleOf(c))) : 0.0;
    vec4 col = tap(p0);
    col.rgb *= 1.0 + NEAR * h - 0.3 * bevel * max(-facing, 0.0);
    shine += 0.6 * bevel * max(facing, 0.0);
    float tl = crackOf(p0);
    float lit = 0.9 * exp(-sq((t - tl) / 9.0));
    float front = smoothstep(tl - 3.0, tl + 2.0, t) * (1.0 - smoothstep(tl + 4.0, tl + 16.0, t));
    float going = smoothstep(leaveOf(c) - 30.0, leaveOf(c), t);
    col = over(leadOf(p0, max(front, going), lit, 0.0, GLOSS * (1.0 + 2.0 * climb)), col);
    return flush(col, cov);
}

vec4 unframe(vec2 p) {
    float k = easeOf(t / UNFRAMED);
    float a = 1.0 - smoothstep(0.2, 1.0, t / UNFRAMED);
    if (a <= 0.0)
        return vec4(0.0);
    vec2 C = box.xy + 0.5 * box.zw;
    vec2 q = C + (p - C + vec2(0.0, UNLIFT * scale * k)) / (1.0 + 0.015 * k);
    float rim = 1.0 - unit(0.5 - hullOf(q));
    core += 0.6 * exp(-sq(t / 9.0)) * exp(-max(hullOf(q), 0.0) / (3.0 * scale)) * rim;
    return flush(tap(q) * rim * a, 1.0);
}

vec4 hidden(vec2 p) {
    vec4 acc = unframe(p);
    for (int i = 0; i < 32; ++i) {
        float c = float(i);
        if (c >= grid.y)
            break;
        float age = t - leaveOf(c);
        if (age >= lift.w)
            continue;
        float h = UNSEAT * popOf(c) + (1.0 - UNSEAT) * climbOf(c);
        float fade = 1.0 - smoothstep(lift.w - FADE, lift.w, age);
        vec2 A = middleOf(c);
        float b = (1.0 + BLUR * h) * scale;
        float a = umbra.a * smoothstep(-b, b, within(p + vec2(0.0, RISE * scale * climbOf(c) + JUMP * scale) - castOf(A) * CAST * scale * h, c)) * smoothstep(0.0, 0.15, h) * fade * 0.5;
        acc = over(vec4(umbra.rgb * a, a), acc);
        acc = over(course(p, c) * fade, acc);
    }
    return acc;
}
