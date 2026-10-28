#version 300 es
precision highp float;
uniform sampler2D tex;
in vec2 v_texcoord;
out vec4 fragColor;

const vec3 KEY  = vec3(1.000, 0.996, 0.980);
const vec3 FILL = vec3(0.976, 0.992, 1.000);
const float HIGHLIGHT_LIFT = 0.02;

void main() {
    vec4 c = texture(tex, v_texcoord);
    c.rgb *= mix(FILL, KEY, v_texcoord.y);
    c.rgb += HIGHLIGHT_LIFT * smoothstep(0.82, 1.0, c.rgb);
    fragColor = c;
}
