#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 size;
    vec2 wheel;
    float spin;
    float wheelA;
    float unit;
    vec4 hot;
    vec4 e0; vec4 e1; vec4 e2; vec4 e3; vec4 e4; vec4 e5; vec4 e6; vec4 e7;
};

float hash(float n) { return fract(sin(n * 12.9898) * 43758.5453); }

vec4 emitAt(int i) {
    if (i == 0) return e0;
    if (i == 1) return e1;
    if (i == 2) return e2;
    if (i == 3) return e3;
    if (i == 4) return e4;
    if (i == 5) return e5;
    if (i == 6) return e6;
    return e7;
}

float seg(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a, ba = b - a;
    return length(pa - ba * clamp(dot(pa, ba) / max(dot(ba, ba), 1e-4), 0.0, 1.0));
}

void main() {
    vec2 p = qt_TexCoord0 * size;
    vec3 col = vec3(0.0);
    float a = 0.0;
    for (int i = 0; i < 8; i++) {
        vec4 e = emitAt(i);
        if (e.z < 0.0 || e.z > 0.6) continue;
        if (length(p - e.xy) > 150.0 * unit) continue;
        for (int j = 0; j < 5; j++) {
            float s = float(i * 7 + j) + floor(e.w * 13.0);
            float ang = hash(s * 1.3) * 6.2832;
            float v0 = (60.0 + 190.0 * hash(s * 2.1)) * unit * (0.4 + 0.6 * clamp(e.w, 0.0, 1.5));
            vec2 vel = vec2(cos(ang), sin(ang) - 0.6) * v0;
            float t = e.z;
            bool dust = j >= 3;
            float life = dust ? 0.6 : 0.32;
            if (t > life) continue;
            vec2 g = vec2(0.0, dust ? 120.0 : 520.0) * unit;
            vec2 at = e.xy + vel * t * (dust ? 0.35 : 1.0) + 0.5 * g * t * t;
            vec2 tail = at - (vel + g * t) * (dust ? 0.004 : 0.018);
            float d = seg(p, at, tail);
            float fade = 1.0 - t / life;
            if (dust) {
                float tw = 0.5 + 0.5 * sin(t * 60.0 + s);
                float k = exp(-d * d / (0.5 * unit * unit)) * fade * tw;
                col += vec3(0.85, 0.92, 1.0) * k;
                a += k;
            } else {
                float k = exp(-d * d / (0.35 * unit * unit)) * fade * fade;
                vec3 c = mix(hot.rgb, vec3(1.0), fade * fade);
                col += c * k * 1.4;
                a += k;
                float glow = exp(-d / (3.0 * unit)) * fade * 0.25;
                col += hot.rgb * glow;
                a += glow * 0.5;
            }
        }
    }
    if (wheelA > 0.0) {
        vec2 q = (p - wheel) / unit;
        float r = length(q);
        vec2 hd = vec2(0.55, -0.83);
        float handle = seg(q, vec2(0.0), hd * 22.0) - 2.2;
        if (handle < 0.0 && r > 6.0) {
            float h = clamp(-handle / 2.2, 0.0, 1.0);
            vec3 brass = mix(vec3(0.35, 0.22, 0.09), vec3(0.96, 0.8, 0.5), h);
            col = mix(col, brass, wheelA);
            a = mix(a, 1.0, wheelA);
        }
        if (r < 7.0) {
            float ang = atan(q.y, q.x) + spin;
            float spokes = smoothstep(0.75, 0.95, abs(cos(ang * 3.0)));
            float rim = smoothstep(4.6, 5.4, r);
            vec3 steel = mix(vec3(0.55, 0.58, 0.68), vec3(1.0), rim * 0.6 + 0.3 * spokes);
            vec3 c = mix(steel * (0.5 + 0.5 * spokes), steel, rim);
            float edge = smoothstep(7.0, 6.2, r);
            col = mix(col, c + hot.rgb * 0.3 * rim, edge * wheelA);
            a = mix(a, 1.0, edge * wheelA);
        }
    }
    a = clamp(a, 0.0, 1.0);
    fragColor = vec4(col, a) * qt_Opacity;
}
