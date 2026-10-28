#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 winRect;
    vec4 breakA;
    vec4 breakB;
    vec4 rimColor;
    vec2 lightAt;
    vec2 texel;
    float rim;
    float feather;
};
layout(binding = 1) uniform sampler2D her;
layout(binding = 2) uniform sampler2D win;

float ell(vec2 uv, vec4 e) {
    vec2 d = (uv - e.xy) / max(e.zw, vec2(1e-4));
    return 1.0 - smoothstep(1.0 - feather, 1.0, length(d));
}

void main() {
    vec2 uv = qt_TexCoord0;
    vec4 c = texture(her, uv);
    if (c.a < 0.002) {
        fragColor = vec4(0.0);
        return;
    }
    vec2 wuv = winRect.xy + uv * winRect.zw;
    float inWin = (wuv.x < 0.0 || wuv.y < 0.0 || wuv.x > 1.0 || wuv.y > 1.0) ? 0.0 : texture(win, wuv).r;
    float keep = max(inWin, max(ell(uv, breakA), ell(uv, breakB)));
    float s = 0.0;
    for (int i = 0; i < 8; i++) {
        float a = float(i) * 0.7853982;
        s += texture(her, uv + vec2(cos(a), sin(a)) * texel * 5.0).a;
    }
    float edge = clamp(c.a - s / 8.0, 0.0, 1.0);
    vec2 d = uv - lightAt;
    float near = exp(-dot(d, d) * 3.0);
    vec3 col = c.rgb + rimColor.rgb * edge * rim * (0.35 + 0.65 * near) * c.a;
    fragColor = vec4(col, c.a) * keep * qt_Opacity;
}
