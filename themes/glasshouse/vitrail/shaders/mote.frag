#version 300 es
precision highp float;

in vec4 v_col;
in float v_star;
uniform float ink;
layout(location = 0) out vec4 fragColor;

void main() {
    vec2 q = (gl_PointCoord - 0.5) * 2.0;
    float r = length(q);
    float m = v_star > 0.5 ? exp(-r * r * 16.0) * 1.3 + (exp(-q.x * q.x * 140.0) * exp(-abs(q.y) * 3.0) + exp(-q.y * q.y * 140.0) * exp(-abs(q.x) * 3.0)) * 0.8
                           : (1.0 - smoothstep(0.35, 1.0, r)) * 0.8 + exp(-r * r * 8.0) * 0.5;
    float a = v_col.a * min(m, 1.6);
    fragColor = vec4(v_col.rgb * a, a * 0.85 * ink);
}
