#version 300 es
precision highp float;

in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;

uniform sampler2D textTex;
uniform vec2 box;
uniform vec4 textRect;
uniform vec2 cols;
uniform float opacity;
uniform float glint;
uniform vec3 hot;

void main() {
    vec2 t = v_texcoord * box + textRect.xy;
    if (t.x < cols.x || t.x >= cols.y) {
        fragColor = vec4(0.0);
        return;
    }
    vec2 uv = t / textRect.zw;
    vec4 c = uv.x >= 0.0 && uv.y >= 0.0 && uv.x <= 1.0 && uv.y <= 1.0 ? texture(textTex, uv) : vec4(0.0);
    fragColor = vec4(mix(c.rgb, hot * c.a, glint), c.a) * opacity;
}
