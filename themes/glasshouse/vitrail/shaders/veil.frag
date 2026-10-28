#version 300 es
precision highp float;

in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;

uniform sampler2D tex;
uniform highp sampler2D perm;
uniform vec2 texSize;
uniform vec4 drawn;
uniform vec4 win;
uniform vec2 grid;
uniform float t;
uniform float base;
uniform float reveal;
uniform float turn;
uniform vec2 pivot;
uniform vec3 ring;
uniform float copy;
uniform vec4 gates[4];
uniform float gated;

#include "lib/front.glsl"

void main() {
    vec2 p = drawn.xy + v_texcoord * drawn.zw;
    if (copy > 0.5) {
        fragColor = texture(tex, p / texSize);
        return;
    }
    vec2 n = (p - win.xy) / win.zw;
    if (n.x < 0.0 || n.y < 0.0 || n.x > 1.0 || n.y > 1.0) {
        fragColor = vec4(0.0);
        return;
    }
    if (turn > 0.5 || gated > 0.5) {
        float land = gated > 0.5 ? frontOf(p) : ring.y + ring.z * (1.0 - pow(1.0 - clamp(length(p - pivot) / ring.x, 0.0, 1.0), 1.0 / 3.0));
        fragColor = texture(tex, p / texSize) * smoothstep(land, land + 0.5 * reveal, t);
        return;
    }
    float nu = grid.x + grid.y;
    vec2 g = vec2(n.x * grid.x + n.y * grid.y, n.x * grid.x - n.y * grid.y);
    vec2 at = clamp(floor(g) + vec2(0.0, grid.y), vec2(0.0), vec2(nu - 1.0));
    vec4 q = texelFetch(perm, ivec2(at), 0);
    float land = q.x < 0.0 ? base : base + q.w;
    fragColor = texture(tex, p / texSize) * smoothstep(land, land + 0.5 * reveal, t);
}
