#version 300 es
precision highp float;

in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;

uniform vec2 box;
uniform float radius;
uniform float rim;
uniform vec3 glassTop;
uniform vec3 glassBottom;
uniform float glassAlpha;
uniform vec3 base;
uniform vec3 hi;
uniform vec3 low;
uniform vec2 lightPos;
uniform float lightZ;
uniform float innerLine;
uniform vec3 innerColor;
uniform float grain;
uniform vec2 grainScale;
uniform sampler2D grainTex;
uniform sampler2D textTex;
uniform vec4 textRect;
uniform float opacity;
uniform vec3 head;
uniform vec3 headColor;

#include "lib/math.glsl"

void main() {
    vec2 p = v_texcoord * box;
    vec2 hs = box * 0.5 - vec2(0.5);
    float s = sdRoundBox(p - box * 0.5, hs, radius);
    float cov = clamp(0.5 - s, 0.0, 1.0);
    if (cov < 0.002) {
        fragColor = vec4(0.0);
        return;
    }
    float n = texture(grainTex, fract(v_texcoord * grainScale)).r;
    vec3 glass = mix(glassTop, glassBottom, smoothstep(0.0, 1.0, v_texcoord.y));
    float d = length(p - lightPos);
    glass *= (0.86 + 0.28 * exp(-d * d / max(box.x * box.x * 0.5, 1.0))) * (1.0 - grain + 2.0 * grain * n);
    float edge = -s;
    float u = clamp(edge / max(rim, 0.5), 0.0, 1.0);
    float rimCov = 1.0 - smoothstep(rim - 0.5, rim + 0.5, edge);
    vec2 g = vec2(dFdx(s) / dFdx(p.x), -dFdy(s) / dFdy(p.y));
    float gl = length(g);
    g = gl > 1e-5 ? g / gl : vec2(0.0, -1.0);
    float h = sin(u * 3.14159);
    float slope = cos(u * 3.14159);
    vec3 nr = normalize(vec3(g * slope * 1.6, 1.0));
    vec3 L = normalize(vec3(lightPos - p, lightZ));
    float diff = max(dot(nr, L), 0.0);
    float spec = pow(max(dot(nr, normalize(L + vec3(0.0, 0.0, 1.0))), 0.0), 28.0);
    vec3 metal = base * (0.32 + 0.68 * diff) * mix(0.7, 1.0, h) + hi * spec * 0.9;
    metal = mix(metal, low, 0.25 * (1.0 - h));
    metal += headColor * head.z * 2.2 * exp(-sq((p.x - head.x) / head.y)) * (0.4 + 0.6 * h);
    vec3 col = mix(glass, metal, rimCov);
    float il = innerLine * clamp(1.0 - abs(edge - rim - 2.0), 0.0, 1.0);
    col = mix(col, innerColor, il);
    float a = mix(glassAlpha, 1.0, rimCov) * cov;
    vec4 pane = vec4(col * a, a);
    vec2 tuv = (p - textRect.xy) / textRect.zw;
    vec4 text = tuv.x >= 0.0 && tuv.y >= 0.0 && tuv.x <= 1.0 && tuv.y <= 1.0 ? texture(textTex, tuv) : vec4(0.0);
    fragColor = (text * cov + pane * (1.0 - text.a * cov)) * opacity;
}
