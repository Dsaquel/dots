#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 crop;
    vec4 rim;
    vec2 grainScale;
    float reveal;
    float shade;
    float grain;
};
layout(binding = 1) uniform sampler2D portrait;
layout(binding = 2) uniform sampler2D arch;
layout(binding = 3) uniform sampler2D grainTex;

void main() {
    vec2 uv = qt_TexCoord0;
    vec4 w = texture(arch, uv);
    if (w.a < 0.003) { fragColor = vec4(0.0); return; }
    vec3 c = texture(portrait, crop.xy + uv * crop.zw).rgb;
    float inner = clamp(w.r, 0.0, 1.0);
    float lit = clamp(reveal * 1.45 - uv.y * 0.45, 0.0, 1.0);
    lit = lit * lit * (3.0 - 2.0 * lit);
    float n = texture(grainTex, fract(uv * grainScale)).r;
    vec3 col = c * mix(1.0 - shade, 1.0, sqrt(inner)) * (1.0 - grain + 2.0 * grain * n);
    float edge = 1.0 - inner;
    col += rim.rgb * edge * edge * edge * 0.16 * lit;
    col *= mix(0.16, 1.0, lit);
    fragColor = vec4(col * w.a, w.a) * qt_Opacity;
}
