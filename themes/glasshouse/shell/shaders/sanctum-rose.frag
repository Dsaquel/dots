#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float gain;
    float gloss;
    float dim;
    float pale;
    float bloom;
    float spin;
    float tick;
    float sweep;
    float glint;
    float glintWidth;
    vec2 zone;
    vec4 rect;
    vec4 levelsA;
    vec4 levelsB;
    vec4 levelsC;
    vec4 flaresA;
    vec4 flaresB;
    vec4 flaresC;
    vec4 cool;
    vec4 hot;
};
layout(binding = 1) uniform sampler2D petalMap;
layout(binding = 2) uniform sampler2D glowMap;
layout(binding = 3) uniform sampler2D goldMap;

float pick(vec4 a, vec4 b, vec4 c, int i) {
    vec4 v = i < 4 ? a : (i < 8 ? b : c);
    int j = i - (i / 4) * 4;
    return j == 0 ? v.x : (j == 1 ? v.y : (j == 2 ? v.z : v.w));
}

void main() {
    vec2 uv = qt_TexCoord0;
    vec2 p = uv - 0.5;
    float ang = atan(p.x, -p.y);
    int i = int(mod(floor(ang / 6.2831853 * 10.0 + 0.5), 10.0));
    float on = clamp(pick(levelsA, levelsB, levelsC, i), 0.0, 1.0);
    float fl = pick(flaresA, flaresB, flaresC, i);
    vec4 g = texture(petalMap, uv);
    vec4 h = texture(glowMap, uv);
    vec4 m = texture(goldMap, uv);
    vec3 base = g.a > 0.003 ? g.rgb / g.a : vec3(0.0);
    vec3 gb = h.a > 0.003 ? h.rgb / h.a : vec3(0.0);
    vec3 gc = m.a > 0.003 ? m.rgb / m.a : vec3(0.0);
    vec3 lit = base * gain + base * base * gloss;
    float y = dot(base, vec3(0.299, 0.587, 0.114));
    vec3 rest = mix(vec3(y), base, pale) * dim * cool.rgb;
    vec3 col = mix(rest, lit, on);
    col = col * (1.0 + 0.55 * fl) + hot.rgb * (0.12 * fl * fl);
    vec3 glow = gb * h.a * (bloom * (0.08 + 0.3 * on) + 0.85 * fl) * (1.0 - 0.8 * g.a);
    float r = length(p) * 2.0;
    float d = mod(ang - spin + 3.14159265, 6.2831853) - 3.14159265;
    float spot = tick * exp(-d * d / 0.018) * smoothstep(0.6, 0.72, r) * (1.0 - smoothstep(0.97, 1.0, r));
    float e = (uv.x + (1.0 - uv.y) * 0.6) - sweep * 1.6;
    float band = exp(-e * e * 180.0);
    if (rect.z > 0.0) {
        vec2 s = rect.xy + uv * rect.zw;
        float q = (s.x + (1080.0 - s.y) * 0.42 - glint) / max(glintWidth, 1.0);
        band += exp(-q * q) + 0.35 * exp(-q * q * 0.12);
    }
    vec3 tint = mix(vec3(1.0), gc * 1.5 + 0.25, 0.65);
    band *= smoothstep(zone.x - 0.01, zone.x + 0.01, r) * (1.0 - smoothstep(zone.y - 0.01, zone.y + 0.01, r));
    vec3 gold = tint * m.a * (band * 0.7 + spot * 1.4);
    fragColor = vec4(col * g.a + glow + gold, g.a) * qt_Opacity;
}
