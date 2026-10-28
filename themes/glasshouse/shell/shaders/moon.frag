#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float phase;
    vec4 lit;
    vec4 dark;
};

void main() {
    vec2 p = qt_TexCoord0 * 2.0 - 1.0;
    float r = length(p);
    float disc = smoothstep(1.0, 0.9, r);
    float hw = sqrt(max(0.0, 1.0 - p.y * p.y));
    float xt = hw * cos(phase * 6.2831853);
    float soft = 0.09;
    float on = phase < 0.5 ? smoothstep(xt - soft, xt + soft, p.x) : smoothstep(-xt + soft, -xt - soft, p.x);
    vec2 m1 = p - vec2(-0.28, -0.22);
    vec2 m2 = p - vec2(0.18, -0.05);
    vec2 m3 = p - vec2(-0.05, 0.36);
    float maria = 0.16 * exp(-dot(m1, m1) * 9.0) + 0.12 * exp(-dot(m2, m2) * 14.0) + 0.09 * exp(-dot(m3, m3) * 18.0);
    vec3 lc = lit.rgb * (0.92 - maria - 0.12 * r * r);
    vec3 dc = dark.rgb + lit.rgb * 0.035 * (1.0 - maria * 2.0);
    vec3 col = mix(dc, lc, on);
    col += lit.rgb * smoothstep(0.78, 1.0, r) * on * 0.25;
    fragColor = vec4(col * disc, disc) * qt_Opacity;
}
