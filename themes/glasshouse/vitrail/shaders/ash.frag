#version 300 es
precision highp float;

in vec4 v_col;
in float v_star;
uniform float ink;
layout(location = 0) out vec4 fragColor;

void main() {
    vec2 q = (gl_PointCoord - 0.5) * 2.0;
    float r = length(q);
    float m = v_star > 1.5 ? exp(-r * r * 4.0) * step(r, 1.0)
            : v_star > 0.5 ? exp(-r * r * 14.0) * 1.3 + (exp(-q.x * q.x * 120.0) * exp(-abs(q.y) * 2.6) + exp(-q.y * q.y * 120.0) * exp(-abs(q.x) * 2.6)) * 0.8
                           : (1.0 - smoothstep(0.3, 1.0, r)) * 0.75 + exp(-r * r * 9.0) * 0.6;
    float a = v_col.a * min(m, 1.6);
    fragColor = ink > 0.5 ? vec4(v_col.rgb * min(a, 1.0), min(a, 1.0) * 0.9) : vec4(v_col.rgb * a, 0.0);
}
