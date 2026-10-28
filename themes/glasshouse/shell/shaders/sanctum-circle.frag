#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 winRect;
    vec4 tint;
    vec4 glowTint;
    float outerAngle;
    float innerAngle;
    float intensity;
};
layout(binding = 1) uniform sampler2D outer;
layout(binding = 2) uniform sampler2D outerGlow;
layout(binding = 3) uniform sampler2D inner;
layout(binding = 4) uniform sampler2D innerGlow;
layout(binding = 5) uniform sampler2D win;

vec2 turn(vec2 p, float a) {
    float c = cos(a);
    float s = sin(a);
    return vec2(c * p.x + s * p.y, -s * p.x + c * p.y) + 0.5;
}

void main() {
    vec2 uv = qt_TexCoord0;
    vec2 p = uv - 0.5;
    vec2 uo = turn(p, outerAngle);
    vec2 ui = turn(p, innerAngle);
    float a = min(1.0, texture(outer, uo).a + texture(inner, ui).a);
    float g = texture(outerGlow, uo).a + texture(innerGlow, ui).a;
    vec2 wuv = winRect.xy + uv * winRect.zw;
    float m = (wuv.x < 0.0 || wuv.y < 0.0 || wuv.x > 1.0 || wuv.y > 1.0) ? 0.0 : texture(win, wuv).r;
    vec3 col = (tint.rgb * a + glowTint.rgb * g * 0.45) * intensity * m;
    fragColor = vec4(col, 0.0) * qt_Opacity;
}
