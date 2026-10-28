#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 texel;
    vec2 light;
    float depth;
    float shininess;
    float aspect;
    vec4 rect;
    float glint;
    float glintWidth;
    float sweep;
    float gain;
    float rest;
};
layout(binding = 1) uniform sampler2D heightMap;
layout(binding = 2) uniform sampler2D colorMap;

void main() {
    vec2 uv = qt_TexCoord0;
    vec4 t = texture(heightMap, uv);
    if (t.a < 0.01) { fragColor = vec4(0.0); return; }
    float hx = texture(heightMap, uv + vec2(texel.x, 0.0)).r - texture(heightMap, uv - vec2(texel.x, 0.0)).r;
    float hy = texture(heightMap, uv + vec2(0.0, texel.y)).r - texture(heightMap, uv - vec2(0.0, texel.y)).r;
    vec3 n = normalize(vec3(-hx * depth, hy * depth, 1.0));
    vec3 L = normalize(vec3((light.x - uv.x) * aspect, uv.y - light.y, 0.9));
    vec3 H = normalize(L + vec3(0.0, 0.0, 1.0));
    float spec = pow(max(dot(n, H), 0.0), max(shininess, 1.0));
    float band = 0.0;
    if (rect.z > 0.0) {
        vec2 g = rect.xy + uv * rect.zw;
        float d = (g.x + (1080.0 - g.y) * 0.42 - glint) / max(glintWidth, 1.0);
        band = exp(-d * d) + 0.35 * exp(-d * d * 0.12);
    }
    float e = (uv.x * aspect + (1.0 - uv.y) * 0.6) - sweep * (aspect + 0.6);
    band += exp(-e * e * 180.0);
    vec4 c = texture(colorMap, uv);
    vec3 base = c.a > 0.003 ? c.rgb / c.a : vec3(0.0);
    vec3 tint = mix(vec3(1.0), base * 1.5 + 0.25, 0.65);
    vec3 col = tint * (band * gain * (0.2 + 1.8 * spec) + rest * spec) * t.a;
    fragColor = vec4(col, 0.0) * qt_Opacity;
}
