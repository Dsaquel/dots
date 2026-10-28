#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 texel;
    vec4 base;
    vec4 hi;
    vec4 low;
    vec2 light;
    float depth;
    float detail;
};
layout(binding = 1) uniform sampler2D src;

float height(vec2 uv) {
    vec4 c = texture(src, uv);
    float lum = c.a > 0.004 ? dot(c.rgb / c.a, vec3(0.299, 0.587, 0.114)) : 0.0;
    return c.a * (1.0 - detail + detail * lum);
}

void main() {
    vec2 uv = qt_TexCoord0;
    float a = texture(src, uv).a;
    if (a < 0.004) { fragColor = vec4(0.0); return; }
    float hc = height(uv);
    float hx = height(uv + vec2(texel.x, 0.0)) - height(uv - vec2(texel.x, 0.0));
    float hy = height(uv + vec2(0.0, texel.y)) - height(uv - vec2(0.0, texel.y));
    vec3 n = normalize(vec3(-hx * depth, -hy * depth, 1.0));
    vec3 L = normalize(vec3(light - uv, 0.7));
    float diff = max(dot(n, L), 0.0);
    float spec = pow(max(dot(n, normalize(L + vec3(0.0, 0.0, 1.0))), 0.0), 22.0);
    vec3 col = base.rgb * (0.35 + 0.75 * diff) + hi.rgb * spec * 0.9;
    col = mix(low.rgb, col, smoothstep(0.0, 0.5, hc + 0.2));
    fragColor = vec4(col * a, a) * qt_Opacity;
}
