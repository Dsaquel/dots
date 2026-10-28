#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 nearMap;
    float phase;
    vec2 base;
    vec2 tip;
    vec2 star;
    float aspect;
    vec4 tint;
    float power;
    float hasCut;
    vec2 capA;
    vec2 capB;
    float rows;
};
layout(binding = 1) uniform sampler2D nearTex;
layout(binding = 2) uniform sampler2D cutTex;

float bottle(vec2 uv, vec2 p, vec2 ax, float s)
{
    float across = abs(ax.x * p.y - ax.y * p.x) / max(length(ax), 1e-5) * rows;
    float w = mix(mix(31.0, 16.0, clamp(s / 0.66, 0.0, 1.0)), 12.0, smoothstep(0.62, 0.7, s));
    float neck = (1.0 - smoothstep(w - 1.5, w + 1.0, across)) * (1.0 - smoothstep(0.77, 0.8, s));
    vec2 a = capA * vec2(aspect, 1.0);
    vec2 ab = capB * vec2(aspect, 1.0) - a;
    vec2 q = uv * vec2(aspect, 1.0) - a;
    float k = clamp(dot(q, ab) / max(dot(ab, ab), 1e-5), 0.0, 1.0);
    float cap = 1.0 - smoothstep(19.0, 21.5, length(q - ab * k) * rows);
    return max(neck, cap);
}

void main()
{
    vec2 uv = qt_TexCoord0;
    vec2 nuv = clamp(nearMap.xy + uv * nearMap.zw, 0.0, 1.0);
    vec4 n = texture(nearTex, nuv);

    vec2 ax = (tip - base) * vec2(aspect, 1.0);
    vec2 p = (uv - base) * vec2(aspect, 1.0);
    float s = dot(p, ax) / max(dot(ax, ax), 1e-5);

    float body = bottle(uv, p, ax, s) * (hasCut > 0.5 ? texture(cutTex, nuv).a : 1.0);
    float lum = n.a > 0.01 ? dot(n.rgb / n.a, vec3(0.299, 0.587, 0.114)) : 0.0;
    float hi = smoothstep(0.18, 0.75, lum) * body;
    float pos = mix(-0.1, 1.08, smoothstep(0.0, 0.78, phase));
    float w = (s - pos) / 0.045;
    float band = exp(-w * w) * smoothstep(0.0, 0.12, phase) * (1.0 - smoothstep(0.7, 0.86, phase));

    vec2 d = (uv - star) * vec2(aspect, 1.0) * 40.0;
    float rays = exp(-abs(d.x) * 6.0) * exp(-d.y * d.y * 0.02) + exp(-abs(d.y) * 6.0) * exp(-d.x * d.x * 0.02);
    float core = exp(-dot(d, d) * 0.9);
    float st = smoothstep(0.6, 0.78, phase) * (1.0 - smoothstep(0.8, 1.0, phase));
    vec3 col = tint.rgb * (band * (hi * 1.6 + body * 0.3) + (rays * 0.55 + core) * st);
    fragColor = vec4(col * power, 0.0) * qt_Opacity;
}
