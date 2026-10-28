#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 map;
    vec2 flame;
    float aspect;
    float t;
    float seed;
    float reach;
    float gain;
    float flicker;
    float level;
    vec4 warm;
    vec4 hot;
    float bloom;
};
layout(binding = 1) uniform sampler2D still;

float hash(float n) {
    return fract(sin(n * 127.1 + seed * 311.7) * 43758.5453);
}

float vnoise(float x) {
    float i = floor(x);
    float f = fract(x);
    return mix(hash(i), hash(i + 1.0), f * f * (3.0 - 2.0 * f));
}

void main() {
    vec2 uv = qt_TexCoord0;
    vec3 c = texture(still, map.xy + uv * map.zw).rgb;

    float wander = vnoise(t * 1.3) - 0.5;
    float shiver = vnoise(t * 5.3 + 17.0) - 0.5;
    float gutter = smoothstep(0.8, 1.0, vnoise(t * 0.43 + 41.0));
    float fl = flicker * (0.95 * wander + 0.5 * shiver - 0.9 * gutter);

    vec2 d = (uv - flame) * vec2(aspect, 1.0);
    float r2 = dot(d, d);
    float light = exp(-r2 / max(reach * reach, 1e-5) * 2.4);
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    float lit = smoothstep(0.03, 0.35, lum) * (0.5 + 0.5 * clamp((c.r - c.b) * 3.0 + 0.5, 0.0, 1.0));
    vec3 k = 1.0 + light * gain * fl * warm.rgb * mix(0.35, 1.0, lit);
    vec3 col = c * max(k, vec3(0.0));
    float b = exp(-r2 / max(bloom * bloom, 1e-6)) * (0.55 + 0.45 * (1.0 + fl));
    col += hot.rgb * b * 0.22;

    vec2 e = abs(uv - 0.5) * 2.0;
    float m = (1.0 - smoothstep(0.7, 1.0, e.x)) * (1.0 - smoothstep(0.7, 1.0, e.y));
    fragColor = vec4(mix(c, col, m * level), 1.0) * qt_Opacity;
}
