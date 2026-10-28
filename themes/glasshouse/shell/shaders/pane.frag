#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 box;
    float radius;
    float rim;
    vec4 glassTop;
    vec4 glassBottom;
    vec4 base;
    vec4 hi;
    vec4 low;
    vec2 lightPos;
    float lightZ;
    float innerLine;
    vec4 innerColor;
    float glassAlpha;
    float grain;
    vec2 grainScale;
};
layout(binding = 1) uniform sampler2D grainTex;

float sdRoundBox(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b + vec2(r);
    return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

void main() {
    vec2 p = qt_TexCoord0 * box;
    vec2 hs = box * 0.5 - vec2(0.5);
    float s = sdRoundBox(p - box * 0.5, hs, radius);
    float cov = clamp(0.5 - s, 0.0, 1.0);
    if (cov < 0.002) { fragColor = vec4(0.0); return; }
    float n = texture(grainTex, fract(qt_TexCoord0 * grainScale)).r;
    vec3 glass = mix(glassTop.rgb, glassBottom.rgb, smoothstep(0.0, 1.0, qt_TexCoord0.y));
    float d = length(p - lightPos);
    glass *= (0.86 + 0.28 * exp(-d * d / max(box.x * box.x * 0.5, 1.0))) * (1.0 - grain + 2.0 * grain * n);
    float edge = -s;
    float u = clamp(edge / max(rim, 0.5), 0.0, 1.0);
    float rimCov = 1.0 - smoothstep(rim - 0.5, rim + 0.5, edge);
    vec2 g = vec2(dFdx(s), dFdy(s));
    float gl = length(g);
    g = gl > 1e-5 ? g / gl : vec2(0.0, -1.0);
    float h = sin(u * 3.14159);
    float slope = cos(u * 3.14159);
    vec3 nr = normalize(vec3(g * slope * 1.6, 1.0));
    vec3 L = normalize(vec3(lightPos - p, lightZ));
    float diff = max(dot(nr, L), 0.0);
    float spec = pow(max(dot(nr, normalize(L + vec3(0.0, 0.0, 1.0))), 0.0), 28.0);
    vec3 metal = base.rgb * (0.32 + 0.68 * diff) * mix(0.7, 1.0, h) + hi.rgb * spec * 0.9;
    metal = mix(metal, low.rgb, 0.25 * (1.0 - h));
    vec3 col = mix(glass, metal, rimCov);
    float il = innerLine * clamp(1.0 - abs(edge - rim - 2.0), 0.0, 1.0);
    col = mix(col, innerColor.rgb, il);
    float a = mix(glassAlpha, 1.0, rimCov) * cov;
    fragColor = vec4(col * a, a) * qt_Opacity;
}
