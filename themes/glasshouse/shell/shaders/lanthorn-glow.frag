#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 res;
    vec2 lamp;
    float bloom;
    vec4 warm;
};

void main()
{
    float d = length(qt_TexCoord0 * res - lamp);
    fragColor = vec4(warm.rgb * bloom * (0.9 * exp(-pow(d / 16.0, 2.0)) + 0.32 * exp(-pow(d / 54.0, 2.0))), 0.0) * qt_Opacity;
}
