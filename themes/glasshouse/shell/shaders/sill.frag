#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 box;
    vec4 sprite;
    vec4 cell;
    float mirror;
    float seat;
    vec4 reveal;
    vec4 hot;
    vec4 shade;
    vec4 shadeColor;
    vec4 ground;
    vec4 occ0;
    vec4 occ1;
    vec4 occ2;
    vec4 occ3;
    float occRadius;
    float split;
};
layout(binding = 1) uniform sampler2D atlas;

vec4 frameAt(vec2 p) {
    vec2 q = (p - sprite.xy) / max(sprite.zw, vec2(1.0));
    if (q.x <= 0.0 || q.y <= 0.0 || q.x >= 1.0 || q.y >= 1.0)
        return vec4(0.0);
    if (mirror > 0.5)
        q.x = 1.0 - q.x;
    vec2 uv = cell.xy + q * cell.zw;
    if (split <= 0.0)
        return texture(atlas, uv);
    float a = texture(atlas, uv + vec2(0.0, split)).r;
    vec3 c = texture(atlas, uv).rgb;
    return vec4(vec3(c.r, min(c.g, max(c.r, c.b)), c.b) * a, a);
}

float sdRoundBox(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b + vec2(r);
    return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

float covered(vec2 p, vec4 r) {
    if (r.z < 1.0)
        return 0.0;
    vec2 hs = r.zw * 0.5;
    return clamp(0.5 - sdRoundBox(p - r.xy - hs, hs, occRadius), 0.0, 1.0);
}

float hash(vec2 q) {
    return fract(sin(dot(q, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 q) {
    vec2 i = floor(q);
    vec2 f = fract(q);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float inside(float y) {
    return y <= seat ? reveal.x - (seat - y) : reveal.y - (y - seat);
}

void main() {
    vec2 p = qt_TexCoord0 * box;
    vec4 c = frameAt(p);
    float a0 = c.a;
    float e = inside(p.y) - (0.65 * noise(p / 9.0) + 0.35 * noise(p / 3.0)) * 16.0;
    float vis = clamp(e + 0.5, 0.0, 1.0);
    float grain = 0.35 + 1.3 * hash(floor(p / 2.0));
    float line = exp(-abs(e - 1.0) / 2.2) * grain;
    float tint = exp(-max(e, 0.0) / max(reveal.w, 0.5)) * vis;
    c *= vis;
    c.rgb += hot.rgb * hot.a * reveal.z * (line + 0.3 * tint) * a0;

    float sh = 0.0;
    vec2 g = p - ground.xy;
    if (shade.w > 0.0 && p.y > seat && g.x > 0.0 && g.y > 0.0 && g.x < ground.z && g.y < ground.w) {
        vec2 s = p - shade.xy;
        float r = shade.z;
        float a = frameAt(s).a * 0.2;
        a += (frameAt(s + vec2(r, 0.0)).a + frameAt(s - vec2(r, 0.0)).a + frameAt(s + vec2(0.0, r)).a + frameAt(s - vec2(0.0, r)).a) * 0.12;
        a += (frameAt(s + vec2(r, r) * 0.7).a + frameAt(s - vec2(r, r) * 0.7).a + frameAt(s + vec2(r, -r) * 0.7).a + frameAt(s - vec2(r, -r) * 0.7).a) * 0.08;
        sh = a * shade.w * smoothstep(seat, seat + 6.0, p.y);
    }
    vec4 o = c + vec4(shadeColor.rgb, 1.0) * sh * (1.0 - c.a);

    float hold = max(max(covered(p, occ0), covered(p, occ1)), max(covered(p, occ2), covered(p, occ3)));
    fragColor = o * (1.0 - hold) * qt_Opacity;
}
