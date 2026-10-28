#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 box;
    vec2 origin;
    vec2 view;
    vec4 v01;
    vec4 v23;
    vec4 v45;
    vec4 v67;
    float count;
    float heat;
    float rim;
    float glint;
    float flash;
    float seam;
    vec4 hot;
    vec4 tint;
};
layout(binding = 1) uniform sampler2D picture;

vec2 vert(int i) {
    if (i == 0) return v01.xy;
    if (i == 1) return v01.zw;
    if (i == 2) return v23.xy;
    if (i == 3) return v23.zw;
    if (i == 4) return v45.xy;
    if (i == 5) return v45.zw;
    if (i == 6) return v67.xy;
    return v67.zw;
}

void main() {
    vec2 p = qt_TexCoord0 * box;
    int n = int(count + 0.5);
    float inside = 1e4;
    for (int i = 0; i < 8; i++) {
        if (i >= n)
            break;
        vec2 a = vert(i);
        vec2 b = vert(i + 1 < n ? i + 1 : 0);
        vec2 e = b - a;
        float len = max(length(e), 1e-4);
        inside = min(inside, (e.x * (p.y - a.y) - e.y * (p.x - a.x)) / len);
    }
    float cov = clamp(inside + 0.5, 0.0, 1.0);
    if (cov <= 0.0) {
        fragColor = vec4(0.0);
        return;
    }
    vec3 c = texture(picture, clamp((origin + p) / view, vec2(0.0), vec2(1.0))).rgb;
    float inn = max(inside, 0.0);
    float edge = exp(-inn / 0.9);
    float soft = exp(-inn / 6.0);
    vec3 col = c * (1.0 + 0.3 * flash);
    col *= 1.0 - seam * exp(-max(inn - 0.6, 0.0) / 1.6) * max(heat, rim);
    col = mix(col, col * tint.rgb * 1.25, 0.3 * soft * rim);
    col += hot.rgb * (edge * (1.35 * heat + 0.75 * rim) + soft * 0.22 * heat);
    float gd = (p.x + p.y * 0.6) / max(box.x + box.y * 0.6, 1.0) - glint;
    col += hot.rgb * exp(-gd * gd * 80.0) * 0.45 * rim;
    fragColor = vec4(col, 1.0) * cov * qt_Opacity;
}
