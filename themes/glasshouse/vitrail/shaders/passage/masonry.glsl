vec3 lit(vec3 n, vec3 Q, float ao) {
    vec3 L = normalize(lampL - Q);
    vec3 V = normalize(o - Q);
    float diff = max(dot(n, L), 0.0);
    float spec = pow(max(dot(n, normalize(L + V)), 0.0), 36.0);
    float sky = clamp(0.5 - 0.5 * n.y, 0.0, 1.0);
    if (inHall)
        return (leadBase * hallLight(Q + vec3(0.0, 0.0, zDoor), n) * mix(0.8, 1.1, sky) + leadHi * spec * 0.35) * ao;
    return (leadLow * 0.45 + leadBase * (0.3 + diff) * mix(0.75, 1.15, sky) + leadHi * spec * 0.8) * ao;
}

vec3 molding(float a, float w, vec3 N, vec3 T, vec3 Q, float px, float rich) {
    float h = profile(a, rich);
    float dh = clamp((profile(a + 0.008, rich) - profile(a - 0.008, rich)) / 0.016, -8.0, 8.0);
    vec3 c = lit(normalize(N - T * dh * 0.45), Q, mix(0.5, 1.0, h));
    float rim = 1.0 - smoothstep(0.0, 1.6 * px, min(a, 1.0 - a) * w);
    return mix(c, inked(), rim * 0.7);
}

vec4 block(vec2 P, vec2 lo, vec2 hi, float bev, float px, vec3 Q) {
    vec2 c = (lo + hi) * 0.5;
    vec2 dd = abs(P - c) - (hi - lo) * 0.5;
    float cov = clamp(0.5 - max(dd.x, dd.y) / px, 0.0, 1.0);
    if (cov <= 0.0)
        return vec4(0.0);
    float e = min(-dd.x, -dd.y);
    vec2 dir = -dd.x < -dd.y ? vec2(sign(P.x - c.x), 0.0) : vec2(0.0, sign(P.y - c.y));
    vec3 n = e < bev ? normalize(vec3(dir * 0.85, -1.0)) : vec3(0.0, 0.0, -1.0);
    vec3 col = lit(n, Q, 1.0);
    col += keyline * exp(-sq((e - bev) / max(px, 0.6))) * 0.18;
    col = mix(col, inked(), (1.0 - smoothstep(0.0, 1.4 * px, e)) * 0.6);
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
        vec3 L3 = normalize(lampL - Q);
        float diff = max(dot(jn, L3), 0.0);
        float spec = pow(max(dot(jn, normalize(L3 + normalize(o - Q))), 0.0), 60.0);
        vec3 jewel = jewel1 * (0.45 + 0.9 * diff) + mix(hot, vec3(1.0), 0.5) * spec * 0.9;
        col = mix(col, jewel, jcov);
        col = mix(col, inked(), clamp(0.9 - abs(dj - jr) / px, 0.0, 1.0) * 0.8);
    }
    col = mix(col, inked(), (1.0 - smoothstep(0.0, 1.4 * px, e)) * 0.6);
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
    bool arched = arch >= 1.0;
    vec4 col = vec4(0.0);
    if (arched && P.y < px && abs(L) < aHalf + px) {
        float dd = dArc(P);
        float cov = clamp(0.5 - max(dd, -cw - dd) / px, 0.0, 1.0) * clamp(0.5 - P.y / px, 0.0, 1.0);
        if (cov > 0.0) {
            vec2 C = archCentre(P);
            vec2 g = normalize(P - C);
            vec3 c = molding(-dd / cw, cw, N, vec3(-g, 0.0), Q, px, rich);
            float th = abs(atan(P.y - C.y, P.x - C.x) - atan(-arch - aYc, W * 0.5 - C.x)) * aR;
            float step_ = 2.3 * cw;
            float f = (th - 0.85 * cw) / step_;
            float dj = min(fract(f), 1.0 - fract(f)) * step_ * (aR + dd) / aR;
            float groove = (1.0 - smoothstep(0.05 * cw, 0.05 * cw + px, dj)) * step(0.0, f);
            c *= (0.9 + 0.18 * hash(vec2(floor(f), sign(L) + 3.0))) * mix(1.0, 0.35, groove);
            col = vec4(c, 1.0) * cov;
        }
    }
    {
        float sd = max(abs(P.y + 0.3 * cw) - 0.3 * cw, abs(L) - (W * 0.5 + cw));
        float cov = clamp(0.5 - sd / px, 0.0, 1.0);
        if (cov > 0.0) {
            vec3 c = molding((P.y + 0.6 * cw) / (0.6 * cw), 0.6 * cw, N, vec3(0.0, 1.0, 0.0), Q, px, 0.0);
            col = over(vec4(c, 1.0) * cov, col);
        }
    }
    for (int s = 0; s < 2; ++s) {
        bool right = s == 1;
        float a = right ? (W + cw - P.x) / cw : (P.x + cw) / cw;
        float sd = max(abs(a - 0.5) * cw - 0.5 * cw, max(-P.y - (arched ? 0.0 : 0.6 * cw), P.y - H - 0.6 * cw));
        float cov = clamp(0.5 - sd / px, 0.0, 1.0);
        if (cov > 0.0) {
            vec3 c = molding(a, cw, N, vec3(right ? -1.0 : 1.0, 0.0, 0.0), Q, px, rich);
            col = over(vec4(c, 1.0) * cov, col);
        }
    }
    {
        float sd = max(abs(P.y - H - 0.3 * cw) - 0.3 * cw, abs(L) - (W * 0.5 + cw));
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
    return arched ? over(keystone(P, px, Q), col) : col;
}

vec3 reveal(float w, float along, float len, vec3 N, vec3 Q, float px, vec3 bounce) {
    vec3 T = vec3(0.0, 0.0, 1.0);
    vec3 c;
    if (w < 0.2) {
        c = molding(w / 0.2, 0.2 * wall, N, T, Q, px, richOf(0.2 * wall, px));
    } else if (w > 0.86) {
        c = molding((w - 0.86) / 0.14, 0.14 * wall, N, T, Q, px, 0.0);
    } else {
        vec2 gi;
        float ex = lattice(vec2(along, w * wall), vec2(56.0, 84.0), gi);
        vec3 g = mix(leadLow, leadBase, 0.45) * 0.8 + jewelOf(hash(gi + 41.0 + N.x * 7.0 + N.y * 13.0)) * (ink > 0.5 ? 0.14 : 0.07) * (0.8 + 0.4 * hash(gi + 5.1));
        g += bounce * (0.25 + 0.6 * w);
        float diff = max(dot(N, normalize(lampL - Q)), 0.0);
        float lead = (1.0 - smoothstep(0.6 * px, 1.6 * px, ex)) * 0.45;
        c = mix(g * (0.7 + 0.6 * diff), ink > 0.5 ? sepia : leadLow, lead);
    }
    c *= mix(0.4, 1.0, smoothstep(0.0, 0.08 * size.y, min(along, len - along))) * (1.0 - 0.3 * smoothstep(0.75, 1.0, w));
    float key = max(2.2 * px, 1.0);
    c += keyline * (exp(-sq(w * wall / key)) * 0.55 + exp(-sq((1.0 - w) * wall / key)) * 0.45);
    return c;
}

vec3 intrados(float w, vec3 N, vec3 Q, float px) {
    vec3 T = vec3(0.0, 0.0, 1.0);
    float depth_ = 0.42 * wall;
    float h = 0.5 + 0.5 * bump(w, 0.3, 0.22) + 0.35 * bump(w, 0.74, 0.16);
    float dh = clamp((0.5 * (bump(w + 0.01, 0.3, 0.22) - bump(w - 0.01, 0.3, 0.22)) + 0.35 * (bump(w + 0.01, 0.74, 0.16) - bump(w - 0.01, 0.74, 0.16))) / 0.02, -8.0, 8.0);
    vec3 c = lit(normalize(N - T * dh * 0.3), Q, mix(0.45, 1.0, h)) * (1.0 - 0.45 * w);
    return c + keyline * exp(-sq(w * depth_ / max(2.2 * px, 1.0))) * 0.6;
}
