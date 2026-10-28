#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 size;
    vec2 origin;
    vec2 screen;
    float radius;
    float power;
    float dim;
    float solid;
    float blurOn;
};
layout(binding = 1) uniform sampler2D src;
layout(binding = 2) uniform sampler2D bg;

#define SMOOTHING_CONSTANT (3.1415926535897932384626433832795 / 5.34665792551)

float coverage(vec2 p)
{
    vec2 q = abs(p - size * 0.5) - (size * 0.5 - radius) + vec2(1.0) / size;
    if (radius <= 0.0 || q.x + q.y <= radius)
        return 1.0;
    float e = max(power, 1.0);
    float dist = pow(pow(max(q.x, 0.0), e) + pow(max(q.y, 0.0), e), 1.0 / e);
    if (dist > radius + SMOOTHING_CONSTANT)
        return 0.0;
    return 1.0 - smoothstep(0.0, 1.0, (dist - radius + SMOOTHING_CONSTANT) / (SMOOTHING_CONSTANT * 2.0));
}

void main()
{
    vec2 p = qt_TexCoord0 * size;
    float cov = coverage(p);
    if (solid > 0.5) {
        fragColor = vec4(cov) * qt_Opacity;
        return;
    }
    vec4 c = texture(src, qt_TexCoord0);
    if (blurOn > 0.5)
        c = vec4(c.rgb + (1.0 - c.a) * texture(bg, (origin + p) / screen).rgb, 1.0);
    c = vec4(c.rgb * (1.0 - dim), 1.0 - (1.0 - c.a) * (1.0 - dim));
    fragColor = c * cov * qt_Opacity;
}
