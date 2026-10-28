#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 size;
    float frost;
    float melt;
    vec4 rect;
    float cut;
    float lift;
    float dim;
    float taken;
    vec4 hover;
    float hoverA;
    float score;
    float record;
    float gild;
    float time;
    float unit;
    float dark;
    vec4 light;
};
layout(binding = 1) uniform sampler2D frame;

float hash2(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash2(i), hash2(i + vec2(1, 0)), u.x), mix(hash2(i + vec2(0, 1)), hash2(i + vec2(1, 1)), u.x), u.y);
}
float fbm(vec2 p) {
    float v = 0.0, a = 0.5;
    for (int i = 0; i < 4; i++) { v += a * noise(p); p = p * 2.07 + 3.3; a *= 0.5; }
    return v;
}
float sdBox(vec2 p, vec2 b) {
    vec2 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

vec3 came(float d, float w, vec2 grad, vec3 base, vec3 hi) {
    float u = clamp(d / w, 0.0, 1.0);
    float h = sin(u * 3.14159);
    vec3 n = normalize(vec3(grad * cos(u * 3.14159) * 1.4, 1.0));
    float spec = pow(max(dot(n, normalize(vec3(-0.5, -0.6, 0.9))), 0.0), 22.0);
    return base * (0.45 + 0.55 * h) + hi * spec;
}

void main() {
    vec2 uv = qt_TexCoord0;
    vec2 p = uv * size;

    float drip = 0.0;
    if (melt > 0.0) {
        float col = noise(vec2(p.x / (14.0 * unit), 0.5));
        drip = melt * melt * (30.0 + 120.0 * col) * unit * smoothstep(0.0, 1.0, uv.y + 0.3);
    }
    vec2 sp = p - vec2(0.0, drip);

    vec2 c = rect.xy + rect.zw * 0.5;
    float inRect = rect.z > 0.0 ? sdBox(p - c, rect.zw * 0.5) : 1e5;
    float onPane = cut > 0.0 && taken < 0.5 ? step(inRect, 0.0) : 0.0;
    float outside = 1.0 - onPane;

    vec2 mid = size * 0.5;
    float dc = length(p - mid);
    float front = frost * length(size) * 0.62;
    float ragged = dc + (noise(p / (30.0 * unit)) - 0.5) * 40.0 * unit + (noise(p / (7.0 * unit)) - 0.5) * 9.0 * unit;
    float behind = smoothstep(front + 24.0 * unit, front - 24.0 * unit, ragged);
    float waveLine = (exp(-pow((ragged - front) / (5.0 * unit), 2.0)) + 0.35 * exp(-max(front - ragged, 0.0) / (40.0 * unit)) * step(ragged, front)) * (1.0 - frost * frost) * step(0.001, frost);
    vec2 bend = (p - mid) / max(dc, 1.0) * waveLine * 5.0 * unit;

    vec2 grabP = onPane > 0.5 ? p + vec2(lift, lift) : sp - bend;
    vec3 base = texture(frame, clamp(grabP / size, vec2(0.0005), vec2(0.9995))).rgb;

    vec2 ev = min(uv, 1.0 - uv) * size;
    float corner = length(max(vec2(220.0 * unit) - ev, 0.0)) / (220.0 * unit);
    float rim = fbm(p / (34.0 * unit));
    float ferns = smoothstep(0.55, 1.15, corner + (rim - 0.5) * 0.5) * behind;
    vec2 dir = normalize(vec2(uv.x < 0.5 ? 1.0 : -1.0, uv.y < 0.5 ? 1.0 : -1.0));
    vec2 fq = vec2(dot(p, dir), dot(p, vec2(-dir.y, dir.x))) / unit;
    float streak = fbm(fq * vec2(0.05, 0.22)) * 0.6 + fbm(fq * vec2(0.21, 0.07) + 9.0) * 0.4;
    float crystal = pow(smoothstep(0.45, 0.85, streak), 2.0) * ferns;
    float edgeGlint = exp(-min(ev.x, ev.y) / (2.5 * unit)) * behind;

    vec3 cold = dark > 0.5 ? vec3(0.78, 0.86, 1.0) : vec3(1.0, 0.9, 0.95);
    vec3 col3 = base;
    float sheet = behind * outside;
    col3 = mix(col3, col3 * mix(vec3(1.0), cold, 0.45) * 0.95 + light.rgb * 0.025, 0.8 * sheet);
    col3 += cold * (ferns * 0.07 + crystal * 0.32 + edgeGlint * 0.3) * outside;
    col3 += mix(cold, vec3(1.0), 0.5) * waveLine * (0.35 + 0.65 * noise(p / (2.0 * unit))) * 0.6;
    float band = (uv.x + uv.y * 0.55) - (fract(time * 0.07) * 3.0 - 1.0);
    col3 += cold * exp(-band * band * 260.0) * 0.06 * sheet;
    col3 *= 1.0 - 0.5 * dim * outside;

    if (cut > 0.0 && taken < 0.5) {
        float sh = sdBox(p - c - vec2(lift * 0.6, lift * 1.4), rect.zw * 0.5);
        float shadow = smoothstep(10.0 * unit, -2.0 * unit, sh) * step(0.0, inRect) * cut;
        col3 *= 1.0 - 0.45 * shadow;
    }

    float a = 1.0;
    vec3 leadBase = dark > 0.5 ? vec3(0.23, 0.24, 0.31) : vec3(0.36, 0.3, 0.33);
    vec3 leadHi = dark > 0.5 ? vec3(0.82, 0.86, 1.0) : vec3(1.0, 0.93, 0.86);
    vec3 gold = vec3(0.86, 0.66, 0.32);
    leadBase = mix(leadBase, gold * 0.8, gild);
    leadHi = mix(leadHi, vec3(1.0, 0.95, 0.75), gild);

    float leadA = 0.0;
    vec3 leadC = vec3(0.0);
    if (rect.z > 0.0 && cut > 0.0) {
        vec2 pc = p - c + vec2(lift, lift) * onPane;
        float d = sdBox(pc, rect.zw * 0.5);
        float w = 5.0 * unit;
        if (d > -0.5 * unit && d < w) {
            vec2 g = normalize(vec2(abs(pc.x) > rect.z * 0.5 ? sign(pc.x) : 0.0, abs(pc.y) > rect.w * 0.5 ? sign(pc.y) : 0.0) + 1e-4);
            float pulse = record > 0.5 ? 0.5 + 0.5 * sin(time * 4.0 - (pc.x + pc.y) / (40.0 * unit)) : 0.0;
            leadC = came(d + 0.5 * unit, w + 0.5 * unit, g, leadBase, leadHi) + vec3(0.9, 0.12, 0.2) * pulse * 0.6 * record;
            leadA = smoothstep(w, w - 1.2 * unit, d) * smoothstep(-0.5 * unit, 0.3 * unit, d - 0.5 * unit * record) * min(cut * 2.0, 1.0);
        }
        vec2 h = rect.zw * 0.5 + vec2(2.5 * unit);
        for (int i = 0; i < 4; i++) {
            vec2 k = vec2(i == 0 || i == 3 ? -h.x : h.x, i < 2 ? -h.y : h.y);
            vec2 q = (pc - k) / (6.0 * unit);
            float r = dot(q, q);
            if (r < 1.0) {
                vec3 n = normalize(vec3(q, sqrt(1.0 - r)));
                float s = pow(max(dot(n, normalize(vec3(-0.4, -0.5, 0.8))), 0.0), 30.0);
                vec3 bead = mix(leadBase * 1.3, leadHi * 0.8, n.z * 0.4) + leadHi * s * 1.2;
                float ba = smoothstep(1.0, 0.82, r) * smoothstep(0.0, 0.5, cut - 0.3);
                leadC = mix(leadC, bead, ba);
                leadA = max(leadA, ba);
            }
        }
    }
    if (score > 0.0 && rect.z > 0.0) {
        float d = abs(inRect);
        float glit = 0.6 + 0.4 * noise(vec2((p.x + p.y) / (3.0 * unit), time * 30.0));
        vec3 hot = mix(vec3(1.0), light.rgb, 0.35);
        float core = exp(-d * d / (0.5 * unit * unit));
        float halo = exp(-d / (5.0 * unit));
        col3 += hot * (core * 1.1 + halo * 0.25) * glit * score;
    }
    if (hoverA > 0.0 && hover.z > 0.0) {
        vec2 hc = hover.xy + hover.zw * 0.5;
        vec2 ph = p - hc;
        float d = sdBox(ph, hover.zw * 0.5);
        float w = 3.4 * unit;
        if (d > 0.0 && d < w) {
            vec2 g = normalize(vec2(abs(ph.x) > hover.z * 0.5 ? sign(ph.x) : 0.0, abs(ph.y) > hover.w * 0.5 ? sign(ph.y) : 0.0) + 1e-4);
            vec3 hl = came(d, w, g, leadBase, leadHi);
            float ha = smoothstep(w, w - unit, d) * hoverA;
            col3 = mix(col3, hl, ha);
        }
        float glint = exp(-d * d / (0.6 * unit * unit)) * (0.55 + 0.45 * sin(time * 3.0 + (ph.x - ph.y) / (60.0 * unit)));
        col3 += mix(cold, light.rgb, 0.3) * glint * hoverA * 0.7;
        if (d < 0.0)
            col3 = mix(col3, col3 * 1.08 + cold * 0.05, hoverA);
    }
    col3 = mix(col3, leadC, leadA);

    if (record > 0.0) {
        a = mix(1.0, leadA, record);
        col3 = mix(col3, leadC, record * step(0.001, leadA));
    }
    if (melt > 0.0) {
        float n = fbm(p / (60.0 * unit)) * 0.6 + noise(p / (6.0 * unit)) * 0.4;
        float keep = smoothstep(0.0, 0.12, n - melt * 1.25 + 0.15 * (1.0 - uv.y));
        a *= keep;
    }
    fragColor = vec4(col3 * a, a) * qt_Opacity;
}
