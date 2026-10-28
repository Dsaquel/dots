#version 300 es
precision highp float;
uniform sampler2D tex;
in vec2 v_texcoord;
out vec4 fragColor;

const vec3 MOON   = vec3(1.000, 0.827, 0.663);
const vec3 SHADOW = vec3(0.851, 0.878, 1.000);
const float BLOOM = 0.090;

void main() {
    vec4 c = texture(tex, v_texcoord);
    c.rgb *= mix(SHADOW, MOON, v_texcoord.y);
    float l = dot(c.rgb, vec3(0.2126, 0.7152, 0.0722));
    c.rgb += BLOOM * exp(-l * 42.0);
    fragColor = c;
}
