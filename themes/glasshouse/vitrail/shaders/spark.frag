#version 300 es
precision highp float;

in vec2 v_q;
flat in vec4 v_col;
flat in float v_hard;
layout(location = 0) out vec4 fragColor;

uniform float ink;

void main() {
    float d = dot(v_q, v_q);
    float i = v_col.a * (v_hard < 0.0 ? smoothstep(1.0, 0.75, sqrt(d)) * (0.7 + 0.3 * d) : exp(-d * v_hard));
    fragColor = ink > 0.5 ? vec4(v_col.rgb * i, i * 0.85) : vec4(v_col.rgb * i * 1.7, 0.0);
}
