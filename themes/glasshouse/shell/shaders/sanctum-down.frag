#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 texel;
};
layout(binding = 1) uniform sampler2D src;

void main() {
    vec2 uv = qt_TexCoord0;
    vec4 c = texture(src, uv + vec2(-texel.x, -texel.y)) + texture(src, uv + vec2(texel.x, -texel.y))
           + texture(src, uv + vec2(-texel.x, texel.y)) + texture(src, uv + texel);
    fragColor = c * 0.25 * qt_Opacity;
}
