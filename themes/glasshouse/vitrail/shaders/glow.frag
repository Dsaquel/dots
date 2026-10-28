#version 300 es
precision highp float;

in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;

uniform vec3 tint;
uniform float core;
uniform float intensity;
uniform float opacity;

void main() {
    vec2 d = v_texcoord * 2.0 - 1.0;
    float r = length(d);
    float halo = exp(-r * r * 4.0) * (1.0 - smoothstep(0.85, 1.0, r));
    float c = exp(-r * r / max(core * core, 1e-4));
    fragColor = vec4(tint * (halo * 0.6 + c * 1.4) * intensity * opacity, 0.0);
}
