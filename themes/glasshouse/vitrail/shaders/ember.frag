#version 300 es
precision highp float;

in vec2 v_q;
flat in vec4 v_col;
flat in vec2 v_dim;
flat in vec4 v_glow;
uniform float ink;
layout(location = 0) out vec4 fragColor;

void main() {
    vec2 a = abs(v_q);
    float d = v_glow.a > 0.0 ? (a.x * v_dim.y + a.y * v_dim.x - v_dim.x * v_dim.y) / length(v_dim) : length(vec2(max(a.x - (v_dim.x - v_dim.y), 0.0), v_q.y)) - v_dim.y;
    float body = clamp(0.5 - d, 0.0, 1.0);
    float cov = body * v_col.a;
    float head = 0.3 + 0.7 * smoothstep(-v_dim.x, v_dim.x, v_q.x);
    if (ink > 0.5) {
        vec2 u = v_q / v_dim;
        vec3 core = mix(v_col.rgb, vec3(1.0, 0.84, 0.42), v_glow.a * 0.7 * exp(-6.0 * dot(u, u)));
        float halo = v_glow.a * 0.75 * exp(-max(d, 0.0) / (0.8 * v_dim.y)) * (1.0 - body) * v_col.a;
        fragColor = vec4(core, 1.0) * cov + vec4(v_glow.rgb, 1.0) * halo;
    } else
        fragColor = vec4(v_col.rgb * cov * head, 0.0);
}
