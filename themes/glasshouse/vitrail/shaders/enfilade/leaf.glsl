vec4 leaf(vec2 p, bool left) {
    float W = size.x;
    float H = size.y;
    float len = left ? seam : W - seam;
    float sp = sin(phi);
    float cp = cos(phi);
    float dx = p.x - centre.x;
    float hx = left ? 0.0 : W;
    float den = left ? dx * sp - focal * cp : dx * sp + focal * cp;
    if (abs(den) < 1e-4)
        return vec4(0.0);
    float a = ((hx - centre.x) * focal - dx * (focal - cam)) / den;
    if (a < 0.0 || a > len)
        return vec4(0.0);
    float d = a * sp + focal - cam;
    if (d < 1.0)
        return vec4(0.0);
    float near = smoothstep(focal * 0.04, focal * 0.3, d);
    float Y = centre.y + (p.y - centre.y) * d / focal;
    if (Y < 0.0 || Y > H)
        return vec4(0.0);
    float px = d / focal;
    vec2 src = vec2(left ? a : W - a, Y);
    vec4 c = tap(doorTex, src);
    float k = smoothstep(0.06, 1.05, phi);
    vec2 gi;
    float ex = lattice(vec2(a, Y), vec2(92.0, 136.0), gi);
    vec3 jewel = jewelOf(hash(gi + (left ? 0.0 : 31.0)));
    vec3 straight = c.a > 0.004 ? c.rgb / c.a : vec3(0.0);
    float lum = dot(straight, vec3(0.299, 0.587, 0.114));
    vec3 stained = mix(straight, jewel * (0.45 + 1.7 * lum) * 1.15 + straight * 0.2, 0.5 * k);
    float glassA = max(c.a, 0.3 * k);
    vec4 col = vec4(stained * c.a + jewel * 0.42 * (glassA - c.a), glassA);
    if (live > 0.5 && live < 1.5)
        col = over(tap(liveTex, src), col);
    float lead = (1.0 - smoothstep(0.6 * px, 1.7 * px, ex)) * k * 0.85;
    col.rgb = mix(col.rgb, (ink > 0.5 ? sepia : mix(leadLow, leadBase, 0.6)) * col.a, lead);

    vec3 Q = vec3(left ? a * cp : W - a * cp, Y, a * sp);
    vec3 n = left ? vec3(sp, 0.0, -cp) : vec3(-sp, 0.0, -cp);
    vec3 Lp = vec3(lightPos.x, Q.y, -focal * 0.55);
    vec3 V = normalize(vec3(centre.x, Q.y, -focal + cam) - Q);
    vec3 Hv = normalize(normalize(Lp - Q) + V);
    float nh = max(dot(n, Hv), 0.0);
    float spec = (pow(nh, 1400.0) * 0.4 + pow(nh, 220.0) * 0.035) * smoothstep(0.18, 0.55, phi) * smoothstep(60.0, 260.0, d);
    col.rgb += mix(hot, vec3(1.0), 0.35) * spec * max(col.a, 0.4) * (ink > 0.5 ? 0.6 : 1.0);

    float edgeOn = smoothstep(0.02, 0.22, phi);
    float ed = min(min(a, len - a), min(Y, H - Y));
    float stile = 7.0;
    if (ed < stile + 1.5 * px && edgeOn > 0.0) {
        float sc = (1.0 - smoothstep(stile - 0.5 * px, stile + 0.5 * px, ed)) * edgeOn;
        vec3 run = left ? vec3(cp, 0.0, sp) : vec3(-cp, 0.0, sp);
        vec3 T = ed == a ? run : (ed == len - a ? -run : vec3(0.0, ed == Y ? 1.0 : -1.0, 0.0));
        col = over(vec4(molding(ed / stile, stile, n, T, Q, px, 0.0), 1.0) * sc, col);
        col.rgb += keyline * exp(-sq((ed - stile - 0.6 * px) / (0.9 * px))) * 0.7 * edgeOn;
    }
    float thick = 9.0 * sp;
    float fe = len - a;
    if (fe < thick) {
        float t0 = fe / max(thick, 1e-3);
        vec3 eg = edgeGlass * (0.7 + 0.6 * t0) + vec3(1.0) * exp(-sq(t0 - 0.15) / 0.01) * 0.25;
        col = vec4(eg, 1.0) * 0.92 + col * 0.08;
    }
    col.rgb += keyline * glint * exp(-fe / (2.2 * px)) * 1.1;
    return col * near;
}
