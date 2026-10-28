#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 dir;
    float sigma;
};
layout(binding = 1) uniform sampler2D src;

void main() {
    vec2 uv = qt_TexCoord0;
    float k = -0.5 / max(sigma * sigma, 1e-4);
    vec4 acc = texture(src, uv);
    float sum = 1.0;
    for (int i = 1; i < 24; i += 2) {
        float w1 = exp(float(i * i) * k);
        float w2 = exp(float((i + 1) * (i + 1)) * k);
        float w = w1 + w2;
        vec2 o = dir * ((float(i) * w1 + float(i + 1) * w2) / w);
        acc += (texture(src, uv + o) + texture(src, uv - o)) * w;
        sum += 2.0 * w;
    }
    fragColor = acc / sum * qt_Opacity;
}
