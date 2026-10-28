#version 300 es
precision highp float;

in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;

uniform sampler2D tex;
uniform vec2 texSize;
uniform vec4 drawn;
uniform vec4 win;
uniform float radius;
uniform float scale;
uniform float t;
uniform float husk;
uniform float seed;
uniform vec3 hot;
uniform vec3 keyline;
uniform float ink;

#include "lib/math.glsl"

#include "lib/hash.glsl"

#include "lib/noise.glsl"

void main() {
    vec2 p = drawn.xy + v_texcoord * drawn.zw;
    vec2 hs = win.zw * 0.5;
    float outside = clamp(sdRoundBox(p - win.xy - hs, hs, radius) + 0.5, 0.0, 1.0);
    vec4 c = texture(tex, p / texSize);
    if (outside <= 0.0 || c.a < 0.002)
        discard;
    vec2 x = p / scale * 0.03;
    float n = 0.55 * vnoise(x) + 0.3 * vnoise(x * 2.7 + 7.1) + 0.15 * vnoise(x * 6.3 + 3.3);
    float th = clamp(t / husk, 0.0, 1.0) * 1.15 - 0.05;
    vec4 col = c * smoothstep(th, th + 0.05, n);
    col.rgb += (ink > 0.5 ? keyline : hot) * (1.4 * exp(-sq((n - th) / 0.035)) + 0.5 * exp(-t / 50.0)) * c.a;
    fragColor = col * outside;
}
