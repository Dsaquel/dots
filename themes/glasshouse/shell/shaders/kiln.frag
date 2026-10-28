#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float t;
};

void main() {
    vec2 p = qt_TexCoord0;
    float a = 0.0;
    for (int i = 0; i < 1024; i++) {
        p = fract(p * 1.37 + vec2(sin(t + float(i)), cos(t * 0.7 + a)));
        a += length(p - 0.5);
    }
    fragColor = vec4(0.0, 0.0, 0.0, step(1e9, a)) * qt_Opacity;
}
