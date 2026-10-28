#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 color;
    float core;
    float intensity;
};

void main() {
    vec2 d = qt_TexCoord0 * 2.0 - 1.0;
    float r = length(d);
    float halo = exp(-r * r * 4.0) * (1.0 - smoothstep(0.85, 1.0, r));
    float c = exp(-r * r / max(core * core, 1e-4));
    vec3 col = color.rgb * (halo * 0.6 + c * 1.4) * intensity;
    fragColor = vec4(col, 0.0) * qt_Opacity;
}
