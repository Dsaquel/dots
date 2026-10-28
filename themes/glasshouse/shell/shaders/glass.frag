#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 light;
    float radius;
    float power;
    float ambient;
    float aspect;
    float additive;
    float grain;
    vec2 grainScale;
    vec4 tint;
};
layout(binding = 1) uniform sampler2D glassMap;
layout(binding = 2) uniform sampler2D grainTex;

void main() {
    vec2 uv = qt_TexCoord0;
    vec4 g = texture(glassMap, uv);
    if (g.a < 0.003) { fragColor = vec4(0.0); return; }
    vec3 base = g.rgb / g.a;
    float n = texture(grainTex, uv * grainScale).r;
    vec2 d = vec2((uv.x - light.x) * aspect, uv.y - light.y);
    float fall = exp(-dot(d, d) / max(radius * radius, 1e-4));
    float lum = ambient + power * fall;
    vec3 col = base * lum * (1.0 - grain + 2.0 * grain * n) * tint.rgb;
    col += base * base * power * fall * fall * 0.45;
    fragColor = additive > 0.5 ? vec4(col * g.a, 0.0) * qt_Opacity : vec4(col * g.a, g.a) * qt_Opacity;
}
