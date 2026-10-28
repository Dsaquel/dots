#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float level;
    float vTop;
    float paintTop;
    float vBottom;
    float wave;
    float phase;
    float bubbles;
    float time;
    float grey;
    float warm;
    float swirl;
    float cloud;
    float boost;
    float wash;
    float aspect;
    float texelV;
    vec4 washColor;
};
layout(binding = 1) uniform sampler2D fullTex;
layout(binding = 2) uniform sampler2D emptyTex;
layout(binding = 3) uniform sampler2D maskTex;

float hash(float n) { return fract(sin(n * 12.9898) * 43758.5453); }

void main() {
    vec2 uv = qt_TexCoord0;
    vec4 e = texture(emptyTex, uv);
    float m = texture(maskTex, uv).r;
    float surf = vBottom - clamp(level, 0.0, 1.0) * (vBottom - vTop);
    float s = surf + wave * (sin(uv.x * 17.0 + phase) + 0.5 * sin(uv.x * 29.0 - phase * 1.63));
    float below = smoothstep(s - texelV, s + texelV, uv.y);
    float col0 = max(vBottom - s, 1e-4);
    float paintH = vBottom - paintTop;
    vec2 q = vec2(uv.x, s < paintTop ? vBottom - (vBottom - uv.y) * paintH / col0 : uv.y);
    if (swirl > 0.001) {
        float a = swirl * 0.03;
        q.x += a * sin(uv.y * 21.0 + time * 2.9);
        q.y += a * 0.5 * cos(uv.x * 17.0 - time * 2.1);
    }
    vec4 f = texture(fullTex, q);
    float k = m * below;
    vec4 col = mix(e, f, k);
    vec3 c = col.rgb;
    float l = dot(c, vec3(0.299, 0.587, 0.114));
    c = mix(c, vec3(l) * 0.5 + 0.03 * col.a, grey * k);
    c = mix(c, c * vec3(1.22, 0.86, 0.62) + vec3(0.07, 0.02, 0.0) * col.a, warm * k);
    c = mix(c, mix(c, vec3(l) * 1.05 + 0.05 * col.a, 0.6), cloud * k);
    c = mix(c, washColor.rgb * (l * 0.6 + 0.5 * col.a), wash * k);
    c += boost * k * (c * 0.5 + 0.06 * col.a);
    c += k * c * 0.12;
    float dm = (uv.y - s) / (texelV * 1.6);
    float men = exp(-dm * dm) * m * step(0.02, level);
    c += vec3(0.92, 0.96, 1.0) * men * 0.5 * (1.0 - grey * 0.7) * col.a;
    if (bubbles > 0.001) {
        for (int i = 0; i < 10; i++) {
            float fi = float(i);
            float bx = 0.22 + 0.56 * hash(fi * 3.7 + 1.0);
            float sp = 0.35 + 0.45 * hash(fi * 7.1 + 2.0);
            float t0 = fract(time * sp + hash(fi * 5.3));
            float by = mix(vBottom - 0.05, s + 0.03, t0);
            float r = 0.022 + 0.018 * hash(fi * 9.2);
            float d = length(vec2((uv.x - bx) * aspect, uv.y - by));
            float ring = smoothstep(r, r * 0.72, d) * (0.45 + 0.55 * smoothstep(r * 0.4, r * 0.8, d));
            c += vec3(1.0, 0.98, 0.95) * ring * bubbles * m * below * 0.75 * col.a * (1.0 - t0 * 0.4);
        }
    }
    float air = m * (1.0 - below);
    fragColor = vec4(c * (1.0 - 0.46 * air), col.a * (1.0 - 0.6 * air)) * qt_Opacity;
}
