vec4 block(vec2 P, vec2 lo, vec2 hi, float bev, float px, vec3 Q) {
    vec2 c = (lo + hi) * 0.5;
    vec2 d = abs(P - c) - (hi - lo) * 0.5;
    float cov = clamp(0.5 - max(d.x, d.y) / px, 0.0, 1.0);
    if (cov <= 0.0)
        return vec4(0.0);
    float e = min(-d.x, -d.y);
    vec2 dir = -d.x < -d.y ? vec2(sign(P.x - c.x), 0.0) : vec2(0.0, sign(P.y - c.y));
    vec3 n = e < bev ? normalize(vec3(dir * 0.85, -1.0)) : vec3(0.0, 0.0, -1.0);
    vec3 col = lit(n, Q, 1.0);
    col += keyline * exp(-sq((e - bev) / max(px, 0.6))) * 0.18;
    col = mix(col, ink > 0.5 ? sepia : leadLow, (1.0 - smoothstep(0.0, 1.4 * px, e)) * 0.6);
    return vec4(col, 1.0) * cov;
}

vec4 keystone(vec2 P, float px, vec3 Q) {
    float cw = casing;
    float L = P.x - size.x * 0.5;
    float yT = -arch - 0.4 * cw;
    float yB = -arch + 1.4 * cw;
    float k = clamp((P.y - yT) / (yB - yT), 0.0, 1.0);
    float hw = mix(0.85 * cw, 0.5 * cw, k);
    float slant = inversesqrt(1.0 + sq(0.35 * cw / (yB - yT)));
    float side = (hw - abs(L)) * slant;
    float e = min(side, min(P.y - yT, yB - P.y));
    float cov = clamp(0.5 + e / px, 0.0, 1.0);
    if (cov <= 0.0)
        return vec4(0.0);
    float bev = 0.22 * cw;
    vec2 dir = side < min(P.y - yT, yB - P.y) ? vec2(sign(L), 0.2) : vec2(0.0, P.y - yT < yB - P.y ? -1.0 : 1.0);
    vec3 n = e < bev ? normalize(vec3(dir * 0.85, -1.0)) : vec3(0.0, 0.0, -1.0);
    vec3 col = lit(n, Q, 1.0) * 1.08;
    col += keyline * exp(-sq((e - bev) / max(px, 0.6))) * 0.22;
    vec2 jc = vec2(size.x * 0.5, (yT + yB) * 0.5);
    float jr = 0.3 * cw;
    float dj = length(P - jc);
    float jcov = clamp(0.5 + (jr - dj) / px, 0.0, 1.0);
    if (jcov > 0.0) {
        float nz = sqrt(max(1.0 - sq(dj / jr), 0.0));
        vec3 jn = normalize(vec3((P - jc) / jr * 0.9, -max(nz, 0.2)));
        vec3 L3 = normalize(lamp() - Q);
        float diff = max(dot(jn, L3), 0.0);
        float spec = pow(max(dot(jn, normalize(L3 + normalize(eye() - Q))), 0.0), 60.0);
        vec3 jewel = jewel1 * (0.45 + 0.9 * diff) + mix(hot, vec3(1.0), 0.5) * spec * 0.9;
        col = mix(col, jewel, jcov);
        col = mix(col, ink > 0.5 ? sepia : leadLow, clamp(0.9 - abs(dj - jr) / px, 0.0, 1.0) * 0.8);
    }
    col = mix(col, ink > 0.5 ? sepia : leadLow, (1.0 - smoothstep(0.0, 1.4 * px, e)) * 0.6);
    return vec4(col, 1.0) * cov;
}

vec4 facade(vec2 P, float px, float z) {
    float W = size.x;
    float H = size.y;
    float cw = casing;
    vec3 Q = vec3(P, z);
    vec3 N = vec3(0.0, 0.0, -1.0);
    float rich = richOf(cw, px);
    float L = P.x - W * 0.5;
    vec4 col = vec4(0.0);
    if (P.y < px && abs(L) < aHalf + px) {
        float d = dArc(P);
        float cov = clamp(0.5 - max(d, -cw - d) / px, 0.0, 1.0) * clamp(0.5 - P.y / px, 0.0, 1.0);
        if (cov > 0.0) {
            vec2 C = archCentre(P);
            vec2 g = normalize(P - C);
            vec3 c = molding(-d / cw, cw, N, vec3(-g, 0.0), Q, px, rich);
            float th = abs(atan(P.y - C.y, P.x - C.x) - atan(-arch - aYc, W * 0.5 - C.x)) * aR;
            float step_ = 2.3 * cw;
            float f = (th - 0.85 * cw) / step_;
            float dj = min(fract(f), 1.0 - fract(f)) * step_ * (aR + d) / aR;
            float groove = (1.0 - smoothstep(0.05 * cw, 0.05 * cw + px, dj)) * step(0.0, f);
            c *= (0.9 + 0.18 * hash(vec2(floor(f), sign(L) + 3.0))) * mix(1.0, 0.35, groove);
            col = vec4(c, 1.0) * cov;
        }
    }
    {
        float sd = max(abs(P.y + 0.3 * cw) - 0.3 * cw, abs(L) - aHalf);
        float cov = clamp(0.5 - sd / px, 0.0, 1.0);
        if (cov > 0.0) {
            vec3 c = molding((P.y + 0.6 * cw) / (0.6 * cw), 0.6 * cw, N, vec3(0.0, 1.0, 0.0), Q, px, 0.0);
            col = over(vec4(c, 1.0) * cov, col);
        }
    }
    for (int s = 0; s < 2; ++s) {
        bool right = s == 1;
        float a = right ? (W + cw - P.x) / cw : (P.x + cw) / cw;
        float sd = max(abs(a - 0.5) * cw - 0.5 * cw, max(-P.y, P.y - H - 0.6 * cw));
        float cov = clamp(0.5 - sd / px, 0.0, 1.0);
        if (cov > 0.0) {
            vec3 c = molding(a, cw, N, vec3(right ? -1.0 : 1.0, 0.0, 0.0), Q, px, rich);
            col = over(vec4(c, 1.0) * cov, col);
        }
    }
    {
        float sd = max(abs(P.y - H - 0.3 * cw) - 0.3 * cw, abs(L) - aHalf);
        float cov = clamp(0.5 - sd / px, 0.0, 1.0);
        if (cov > 0.0) {
            vec3 c = molding(1.0 - (P.y - H) / (0.6 * cw), 0.6 * cw, N, vec3(0.0, -1.0, 0.0), Q, px, rich * 0.6);
            col = over(vec4(c, 1.0) * cov, col);
        }
    }
    float bev = 0.2 * cw;
    col = over(block(P, vec2(-1.25 * cw, H - 0.8 * cw), vec2(0.15 * cw, H + 0.8 * cw), bev, px, Q), col);
    col = over(block(P, vec2(W - 0.15 * cw, H - 0.8 * cw), vec2(W + 1.25 * cw, H + 0.8 * cw), bev, px, Q), col);
    col = over(block(P, vec2(-1.3 * cw, -1.0 * cw), vec2(0.18 * cw, 0.22 * cw), bev, px, Q), col);
    col = over(block(P, vec2(W - 0.18 * cw, -1.0 * cw), vec2(W + 1.3 * cw, 0.22 * cw), bev, px, Q), col);
    return over(keystone(P, px, Q), col);
}
