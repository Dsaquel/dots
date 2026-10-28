#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float t;
    float start;
    float spread;
    float span;
    float rest;
    float lit;
    float flare;
    float glow;
    float grain;
    vec2 grainScale;
};
layout(binding = 1) uniform sampler2D lightMap;
layout(binding = 2) uniform sampler2D glowMap;
layout(binding = 3) uniform sampler2D orderMap;
layout(binding = 4) uniform sampler2D grainTex;

void main() {
    vec2 uv = qt_TexCoord0;
    vec4 o = texture(orderMap, uv);
    float k = clamp((t - start - spread * o.r) / span, 0.0, 1.0);
    float on = k * k * (3.0 - 2.0 * k);
    float b = sin(3.14159265 * k);
    b *= b;
    vec4 c = texture(lightMap, uv);
    vec4 g = texture(glowMap, uv);
    vec3 col = vec3(0.0);
    if (c.a > 0.003) {
        vec3 base = c.rgb / c.a;
        float n = texture(grainTex, uv * grainScale).r;
        float lum = mix(rest, lit, on) + flare * b;
        col = base * lum * (1.0 - grain + 2.0 * grain * n) + base * base * (0.22 * on + 0.5 * flare * b);
    }
    vec3 gb = g.a > 0.003 ? g.rgb / g.a : vec3(0.0);
    vec3 add = gb * g.a * glow * (on + 1.6 * b) * o.b;
    fragColor = vec4(col * c.a + add * (1.0 - 0.7 * c.a), c.a) * qt_Opacity;
}
