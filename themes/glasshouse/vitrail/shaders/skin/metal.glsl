vec3 metal(vec3 n, vec2 p, float h, float pl) {
    vec3 L = normalize(vec3(lightPos.xy - p, lightPos.z));
    vec3 H = normalize(L + vec3(0.0, 0.0, 1.0));
    float diff = max(dot(n, L), 0.0);
    float spec = pow(max(dot(n, H), 0.0), shininess);
    float env = clamp(0.5 + 0.5 * n.y, 0.0, 1.0);
    vec3 envc = mix(low, sky, smoothstep(0.15, 0.95, env));
    vec3 col = base * (0.45 + 0.55 * diff) * mix(0.62, 1.0, h);
    col = mix(col, envc * base * 1.5, 0.3 * (1.0 - diff * 0.5));
    col += hi * spec * specGain * (0.3 + 0.7 * pl);
    col += pool * pl * (0.1 + 0.3 * diff + 0.9 * spec);
    return col;
}

vec3 tame(vec3 c) {
    float m = max(max(c.r, c.g), c.b);
    float t = 1.0 - 0.2 * exp((0.8 - m) / 0.2);
    return m > 0.8 ? mix(c * t / m, vec3(1.0), 0.8 * (1.0 - exp(t - m))) : c;
}

vec3 emit(vec3 b, vec3 e) {
    vec3 t = min(b, vec3(1.0));
    vec3 u = t + e;
    vec3 h = max(0.3 + 0.2 * u / max(max(max(u.r, u.g), u.b), 1e-3) - 0.5 * t, 1e-3);
    return b + min(e, h) + h * max(e - h, 0.0) / max(e, h);
}

float line(float d, float w, float px) {
    float wc = max(w, 0.5 * px);
    return clamp((wc - d) / px + 0.5, 0.0, 1.0) * w / wc;
}

vec4 pane(vec2 l, float x0, float seg, vec3 jewel, float id, vec2 gs, vec2 px, vec2 p, float pl, float b0, float b1, float hw) {
    float sb = 0.5 * (b0 + b1);
    float bw = max(b1 - b0, 0.5);
    float streak = 0.9 + 0.2 * vnoise(vec2((x0 + l.x) * 0.07 + id * 3.1, (l.y - sb) * 0.3 + id));
    float across = (l.y - sb) / (bw * 0.5);
    vec3 dark = jewel * unlit * streak + sky * 0.16 * smoothstep(-0.2, 1.0, across) * (0.6 + 0.4 * streak);
    vec3 bright = tame(jewel * (1.0 + 0.3 * pl) * streak + jewel * jewel * 0.35 + pool * pl * 0.1);
    vec3 col = mix(dark, bright, on);
    float lead = max(line(abs(l.y - b0), 0.55, px.y), line(min(l.x, seg - l.x), 0.6, px.x));
    col = mix(col, metal(vec3(0.0, 0.0, 1.0), p, 0.7, pl) * 0.55, lead);
    float dc = l.y - offset;
    float came = line(abs(dc), hw, px.y);
    float uu = clamp(dc / max(hw, 0.5), -1.0, 1.0);
    float h = sqrt(max(1.0 - uu * uu, 0.0));
    vec3 nrm = normalize(vec3(gs * uu / max(h, 0.2) * 1.1, 1.0));
    return vec4(mix(col, metal(nrm, p, h, pl), came), mix(CLEAR, 1.0, max(lead, came)));
}

float sdBrick(vec2 l, vec2 h) {
    vec2 d = abs(l) - h;
    return length(max(d, vec2(0.0))) + min(max(d.x, d.y), 0.0);
}
