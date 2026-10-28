#version 300 es
precision highp float;

in vec4 v_col;
in float v_glow;
uniform float ink;
layout(location = 0) out vec4 fragColor;

void main() {
    float r = length(gl_PointCoord - 0.5) * 2.0;
    float m = (1.0 - smoothstep(0.3, 1.0, r)) * 0.75 + exp(-r * r * 9.0) * 0.6;
    float a = v_col.a * min(m, 1.0);
    fragColor = vec4(v_col.rgb * (1.0 - 0.3 * ink * smoothstep(0.5, 0.95, r)) * a, a * (1.0 - 0.8 * v_glow));
}
