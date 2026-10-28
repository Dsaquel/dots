#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 box;
    vec4 win;
    float radius;
    vec4 veil;
    vec4 shadow;
    vec2 shadowOffset;
    float shadowBlur;
    vec4 occ0;
    vec4 occ1;
    vec4 occ2;
    vec4 occ3;
    float occRadius;
};

float sdRoundBox(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b + vec2(r);
    return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

float covered(vec2 p, vec4 r) {
    if (r.z < 1.0) return 0.0;
    vec2 hs = r.zw * 0.5;
    return clamp(0.5 - sdRoundBox(p - r.xy - hs, hs, occRadius), 0.0, 1.0);
}

void main() {
    vec2 p = qt_TexCoord0 * box;
    vec2 hs = win.zw * 0.5;
    float s = sdRoundBox(p - win.xy - hs, hs, radius);
    float inside = clamp(0.5 - s, 0.0, 1.0);
    vec4 col = veil * inside;
    if (shadow.a > 0.001) {
        float s2 = sdRoundBox(p - win.xy - hs - shadowOffset, hs, radius);
        float sh = 1.0 - smoothstep(-shadowBlur * 0.5, shadowBlur * 1.25, s2);
        col += shadow * sh * (1.0 - inside);
    }
    float o = max(max(covered(p, occ0), covered(p, occ1)), max(covered(p, occ2), covered(p, occ3)));
    fragColor = col * (1.0 - o) * qt_Opacity;
}
