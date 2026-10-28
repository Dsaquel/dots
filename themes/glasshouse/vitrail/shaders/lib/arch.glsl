float hash(vec2 p) {
    vec3 q = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    q += dot(q, q.yzx + 33.33);
    return fract((q.x + q.y) * q.z);
}

float bump(float a, float c, float r) {
    return sqrt(max(1.0 - sq((a - c) / r), 0.0));
}

float profile(float a, float rich) {
    float bead = 0.35 + 0.65 * sin(PI * clamp(a, 0.0, 1.0));
    float ogee = 0.5 * smoothstep(0.0, 0.08, a) + 0.5 * bump(a, 0.44, 0.18) - 0.2 * bump(a, 0.7, 0.07) + 0.1 * bump(a, 0.83, 0.04) - 0.35 * smoothstep(0.9, 1.0, a);
    return mix(bead, ogee, rich);
}

vec4 tap(sampler2D s, vec2 px) {
    return texture(s, px / texSize);
}

float lattice(vec2 l, vec2 cell, out vec2 gi) {
    vec2 g = vec2(l.x / cell.x + l.y / cell.y, l.x / cell.x - l.y / cell.y);
    gi = floor(g);
    vec2 gf = g - gi;
    return min(min(gf.x, 1.0 - gf.x), min(gf.y, 1.0 - gf.y)) * min(cell.x, cell.y) * 0.70710678;
}

float richOf(float w, float px) {
    return smoothstep(10.0, 30.0, w / px);
}

vec2 archCentre(vec2 P) {
    return vec2(size.x * 0.5 + (P.x < size.x * 0.5 ? aK : -aK), aYc);
}

float dArc(vec2 P) {
    return length(P - archCentre(P)) - aR;
}
