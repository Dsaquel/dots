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
        vec3 glass = jewelOf(hash(gi + 41.0 + N.x * 7.0 + N.y * 13.0)) * (ink > 0.5 ? 0.42 : 0.2) * (0.8 + 0.4 * hash(gi + 5.1));
        glass += bounce * 0.35 * w;
        float diff = max(dot(N, normalize(lamp() - Q)), 0.0);
        float lead = 1.0 - smoothstep(0.6 * px, 1.6 * px, ex);
        c = mix(glass * (0.75 + 0.5 * diff), ink > 0.5 ? sepia : leadLow * 1.5 + leadBase * 0.3, lead);
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

vec4 tympanum(vec2 P, float px, float z) {
    float W = size.x;
    float A = arch;
    float cw = casing;
    vec2 gi;
    float ex = lattice(P - vec2(0.0, -A), vec2(70.0, 104.0), gi);
    vec3 glass = jewelOf(hash(gi + 7.0)) * (0.26 + 0.14 * hash(gi + 2.3));
    vec2 oc = vec2(W * 0.5, -A * 0.46);
    float rho = A * 0.3;
    float dO = length(P - oc);
    if (dO < rho) {
        float ang = atan(P.y - oc.y, P.x - oc.x);
        float sector = floor((ang + PI) / (PI / 3.0));
        float petal = abs(cos(3.0 * ang)) * rho * 0.82;
        float heart = rho * 0.3;
        glass = dO < heart ? mix(keyline, hot, 0.4) * 0.85 : jewelOf(fract(sector * 0.37 + 0.11)) * (0.75 + 0.35 * (1.0 - dO / rho));
        ex = min(abs(dO - petal), abs(dO - heart));
        ex = min(ex, abs(fract((ang + PI) / (PI / 3.0)) - 0.5) * (PI / 3.0) * dO + step(dO, heart) * 1e3);
    }
    float lead = 1.0 - smoothstep(0.6 * px, 1.6 * px, ex);
    vec3 c = mix(glass, ink > 0.5 ? sepia : leadLow * 1.5 + leadBase * 0.3, lead);
    float shade = (0.5 + 0.5 * smoothstep(0.0, 0.18 * A, -(dArc(P) + cw))) * (0.6 + 0.4 * smoothstep(0.0, 0.1 * A, -(P.y + 0.6 * cw)));
    vec4 col = vec4(c * 0.92 * shade, 0.92);
    float rc = 1.0 - smoothstep(cw * 0.32, cw * 0.32 + px, abs(dO - rho));
    if (rc > 0.0)
        col = over(vec4(molding((dO - rho) / (cw * 0.64) + 0.5, cw * 0.64, vec3(0.0, 0.0, -1.0), vec3(normalize(P - oc), 0.0), vec3(P, z), px, 0.0), 1.0) * rc, col);
    return col;
}

float outline(vec2 P) {
    float W = size.x;
    float H = size.y;
    float cw = casing;
    vec2 d = abs(P - vec2(W * 0.5, 0.5 * (H + 0.8 * cw))) - vec2(W * 0.5 + 1.25 * cw, 0.5 * (H + 0.8 * cw));
    float box = length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
    return P.y < 0.0 ? min(box, max(dArc(P), abs(P.x - W * 0.5) - aHalf)) : box;
}
