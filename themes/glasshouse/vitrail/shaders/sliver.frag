#version 300 es
precision highp float;

in vec2 v_q;
flat in vec4 v_col;
flat in vec2 v_dim;
layout(location = 0) out vec4 fragColor;

void main() {
    float x = clamp(v_q.x / v_dim.x, -1.0, 1.0);
    float cov = clamp(v_dim.y * (1.0 - 0.85 * x * x) - abs(v_q.y) + 0.5, 0.0, 1.0) * clamp(v_dim.x - abs(v_q.x) + 0.5, 0.0, 1.0);
    fragColor = vec4(v_col.rgb, 1.0) * v_col.a * cov;
}
