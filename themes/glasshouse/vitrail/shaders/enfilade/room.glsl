vec4 room(vec2 p) {
    float W = size.x;
    float H = size.y;
    float cw = casing;
    float zf = depth - wall;
    float zt = zf + 0.42 * wall;
    float df = zf + focal - cam;
    float db = depth + focal - cam;
    float dt = zt + focal - cam;
    vec2 v = (p - centre) / focal;
    vec2 Pf = centre + v * df;
    vec2 Pb = centre + v * db;
    float pxf = df / focal;
    float pxb = db / focal;
    vec4 far = vec4(0.0);
    vec4 deep = vec4(0.0);
    if (Pf.x > 0.0 && Pf.x < W && Pf.y > 0.0 && Pf.y < H) {
        float ex = v.x < 0.0 ? -centre.x / v.x : (v.x > 0.0 ? (W - centre.x) / v.x : 1e9);
        float ey = v.y < 0.0 ? -centre.y / v.y : (v.y > 0.0 ? (H - centre.y) / v.y : 1e9);
        float dz = clamp(min(ex, ey), df, db);
        vec2 Ph = centre + v * dz;
        bool upright = ex < ey;
        vec3 N = upright ? vec3(v.x < 0.0 ? 1.0 : -1.0, 0.0, 0.0) : vec3(0.0, v.y < 0.0 ? 1.0 : -1.0, 0.0);
        vec3 bounce = tap(farTex, clamp(Ph, vec2(6.0), size - 6.0)).rgb;
        vec3 rev = reveal((dz - df) / (db - df), upright ? Ph.y : Ph.x, upright ? H : W, N, vec3(Ph, dz - focal + cam), dz / focal, bounce);
        vec2 inner = min(Pb, size - Pb);
        float edge = min(inner.x, inner.y);
        float farCov = clamp(edge / pxb + 0.5, 0.0, 1.0);
        far = (live > 1.5 ? over(tap(liveTex, Pb), tap(farTex, Pb)) : tap(farTex, Pb)) * farCov;
        deep = mix(vec4(rev, 1.0), vec4(0.0, 0.0, 0.0, 0.42 * exp(-max(edge, 0.0) / (0.035 * H))), farCov);
    } else if (Pf.y < -0.6 * cw && dArc(Pf) < -cw) {
        vec2 Pt = centre + v * dt;
        float pxt = dt / focal;
        float cov = clamp(0.5 - (dArc(Pt) + cw) / pxt, 0.0, 1.0) * clamp(0.5 - (Pt.y + 0.6 * cw) / pxt, 0.0, 1.0);
        float lo = df;
        float hi = dt;
        for (int i = 0; i < 7; ++i) {
            float m = 0.5 * (lo + hi);
            if (dArc(centre + v * m) + cw < 0.0)
                lo = m;
            else
                hi = m;
        }
        float dz = 0.5 * (lo + hi);
        vec2 Pi = centre + v * dz;
        vec3 N = vec3(-normalize(Pi - archCentre(Pi)), 0.0);
        vec3 intr = intrados((dz - df) / (dt - df), N, vec3(Pi, dz - focal + cam), dz / focal);
        deep = mix(vec4(intr, 1.0), tympanum(Pt, pxt, zt), cov);
    } else {
        deep = vec4(0.0, 0.0, 0.0, 0.2 * exp(-max(outline(Pf), 0.0) / (1.2 * cw)));
    }
    return over(facade(Pf, pxf, zf) * casingAlpha, over(deep * casingAlpha, far));
}
