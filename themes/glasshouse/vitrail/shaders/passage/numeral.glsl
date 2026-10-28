float box(vec2 p, vec2 b) {
    vec2 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0);
}

float seg(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a;
    vec2 ba = b - a;
    return length(pa - ba * clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0));
}

float glyphW(int g) {
    return g == 1 ? 0.36 : (g == 2 ? 0.88 : 0.84);
}

float glyph(int g, vec2 q, float h) {
    float w = h * 0.075;
    float s = w * 0.5;
    float sh = h * 0.035;
    float hy = h * 0.5;
    if (g == 1) {
        float dd = box(q, vec2(w, hy));
        dd = min(dd, box(q - vec2(0.0, -hy + sh), vec2(h * 0.17, sh)));
        return min(dd, box(q - vec2(0.0, hy - sh), vec2(h * 0.17, sh)));
    }
    if (g == 2) {
        float dd = min(seg(q, vec2(-0.3 * h, -hy), vec2(0.0, hy)) - w, seg(q, vec2(0.3 * h, -hy), vec2(0.0, hy)) - s);
        dd = max(dd, abs(q.y) - hy);
        dd = min(dd, box(q - vec2(-0.3 * h, -hy + sh), vec2(h * 0.13, sh)));
        return min(dd, box(q - vec2(0.3 * h, -hy + sh), vec2(h * 0.11, sh)));
    }
    float dd = min(seg(q, vec2(-0.29 * h, -hy), vec2(0.29 * h, hy)) - w, seg(q, vec2(0.29 * h, -hy), vec2(-0.29 * h, hy)) - s);
    dd = max(dd, abs(q.y) - hy);
    dd = min(dd, box(q - vec2(-0.29 * h, -hy + sh), vec2(h * 0.12, sh)));
    dd = min(dd, box(q - vec2(0.29 * h, -hy + sh), vec2(h * 0.12, sh)));
    dd = min(dd, box(q - vec2(-0.29 * h, hy - sh), vec2(h * 0.12, sh)));
    return min(dd, box(q - vec2(0.29 * h, hy - sh), vec2(h * 0.12, sh)));
}

float numeralWidth() {
    float total = -0.1;
    for (int i = 0; i < 8; ++i) {
        if (i >= romLen)
            break;
        total += glyphW((rom >> (2 * i)) & 3) + 0.1;
    }
    return total;
}

float numeral(vec2 q, float h, float width) {
    float x = -width * h * 0.5;
    float dd = 1e9;
    for (int i = 0; i < 8; ++i) {
        if (i >= romLen)
            break;
        int g = (rom >> (2 * i)) & 3;
        float w = glyphW(g) * h;
        dd = min(dd, glyph(g, q - vec2(x + w * 0.5, 0.0), h));
        x += w + 0.1 * h;
    }
    return dd;
}

vec3 gilt(vec2 q, float h, float width, float dd, vec3 Q, float px) {
    float e = max(0.7 * px, h * 0.01);
    vec2 g = vec2(numeral(q + vec2(e, 0.0), h, width) - numeral(q - vec2(e, 0.0), h, width), numeral(q + vec2(0.0, e), h, width) - numeral(q - vec2(0.0, e), h, width)) / (2.0 * e);
    float bevel = 1.0 - smoothstep(0.0, h * 0.05, -dd);
    vec3 n = normalize(vec3(g * bevel * 0.9, -1.0));
    vec3 L = normalize(lampL - Q);
    vec3 V = normalize(o - Q);
    float diff = max(dot(n, L), 0.0);
    float spec = pow(max(dot(n, normalize(L + V)), 0.0), 48.0);
    vec3 base = keyline;
    return base * (0.32 + 0.85 * diff) * (0.85 + 0.4 * kin) + mix(hot, vec3(1.0), 0.45) * spec * (1.1 + 0.8 * kin);
}
