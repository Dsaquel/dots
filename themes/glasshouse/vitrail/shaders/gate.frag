#version 300 es
precision highp float;

in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;

uniform vec4 drawn;
uniform vec4 pair;
uniform float corner;
uniform float scale;
uniform float t;
uniform vec4 times;
uniform float ahead;
uniform float bar;
uniform vec4 gates[4];
uniform float gated;
uniform vec2 glide;
uniform vec3 hot;
uniform vec3 gold;
uniform vec3 jewel1;
uniform vec3 leadLow;
uniform vec3 leadBase;
uniform vec3 leadHi;
uniform vec3 sepia;
uniform vec3 leaf;
uniform float ink;

const float EASE = 0.3;
const float PI = 3.14159265;
const float FLUSH = 40.0;
const float MELT = 30.0;
const float THROAT = 40.0;
const float CORE = 4.0;
const float ZIP = 40.0;
const float COOL = 110.0;
const float CAME = 2.4;
const float ROOM = 40.0;

vec3 L = vec3(0.0);
float E = 0.0;

#include "lib/math.glsl"

#include "lib/finish.glsl"

#include "lib/lead.glsl"

void aura(vec2 p, float beyond, float energy, vec3 fire) {
    if (energy <= 0.0 || beyond <= 0.0)
        return;
    vec2 q = p / (34.0 * scale);
    float f = 0.65 * noiseOf(q + vec2(0.0, -0.006 * t)) + 0.35 * noiseOf(2.3 * q + vec2(0.004 * t, 0.0));
    float flame = exp(-beyond / ((8.0 + 60.0 * f * f) * scale));
    float vein = exp(-sq((fract(3.0 * f - 0.002 * t) - 0.5) / 0.05)) * exp(-beyond / (30.0 * scale));
    add(mix(fire, jewel1, 0.25 + 0.35 * f), (0.55 * flame * (0.3 + 0.7 * f) + 0.35 * vein) * energy);
}

float easeOf(float k) {
    return EASE * k + (1.0 - EASE) * k * k;
}

void main() {
    vec2 p = drawn.xy + v_texcoord * drawn.zw;
    vec2 hs = 0.5 * pair.zw;
    float sd = sdRoundBox(p - pair.xy - hs, hs, corner);
    float ax = abs(sd);
    float inPair = clamp(0.5 - sd, 0.0, 1.0);
    float age = t - times.y;
    vec3 fire = ink > 0.5 ? leaf : hot;
    vec2 slide = glide * (1.0 - easeOf(unit((t - times.x) / (times.y - times.x))));
    float d = 1e9;
    float lam = 0.0;
    float across = 0.0;
    float span = 1.0;
    for (int i = 0; i < 4; ++i) {
        if (float(i) >= gated)
            break;
        vec2 a = gates[i].xy + slide;
        vec2 e = gates[i].zw - gates[i].xy;
        float l = max(length(e), 1e-3);
        float u = unit(dot(p - a, e) / (l * l));
        float di = length(p - a - e * u);
        if (di < d) {
            d = di;
            lam = 2.0 * u - 1.0;
            across = dot(p - a, vec2(-e.y, e.x) / l);
            span = 0.5 * l;
        }
    }

    float tf = 0.8 * FLUSH * abs(lam);
    float lit = ahead > 0.0 ? 1.0 : smoothstep(tf, tf + 16.0, t);
    float reach = ahead > 0.0 ? 1.0 : smoothstep(times.x, times.x + MELT, t);
    float zipped = smoothstep(times.y - ZIP, times.y, t);
    float len = max(min(reach, 1.0 - zipped), 0.0);
    float shape = len > 1e-3 ? unit(1.0 - sq(lam / len)) : 0.0;
    float w = THROAT * scale * shape * sqrt(len);
    float live = 1.0 - step(times.y, t);
    float core = exp(-sq(d / (CORE * scale)));
    vec4 ribbon = vec4(0.0);
    if (ink > 0.5) {
        float girth = w + CORE * scale * lit;
        float x = across / max(girth, 1e-3);
        float h = sqrt(unit(1.0 - x * x));
        vec3 metal = mix(mix(sepia, leaf, 0.55), gold, smoothstep(0.0, 0.6, h)) + hot * pow(h, 8.0) * 0.55;
        ribbon = vec4(metal, 1.0) * clamp(girth + 0.5 - abs(across), 0.0, 1.0) * live * 0.92 * step(d, girth + 1.0);
        add(fire, exp(-sq(d / (10.0 * scale))) * lit * live * 0.5);
    } else {
        add(mix(fire, vec3(1.0), 0.5), core * lit * live * (1.0 - 0.4 * reach) * 1.1);
        add(fire, exp(-sq(d / (10.0 * scale))) * lit * live * 0.35);
        if (w > 0.5) {
            float lens = exp(-sq(across / w));
            float edge = exp(-sq((abs(across) - w) / (1.8 * scale)));
            add(mix(gold, fire, 0.4), lens * live * 0.22);
            add(mix(fire, vec3(1.0), 0.6), exp(-sq(across / (CORE * scale * (0.7 + 0.6 * shape)))) * live * 1.3);
            add(mix(gold, vec3(1.0), 0.3), edge * live * 0.8 * shape);
        }
    }
    float tip = span * len;
    float pull = exp(-(sq(abs(lam) * span - tip) + sq(across)) / sq(10.0 * scale)) * zipped * live * step(0.02, len);
    add(vec3(1.0), pull * 2.0);

    if (age >= 0.0) {
        add(vec3(1.0), (exp(-sq(d / (3.0 * scale))) * 2.2 + exp(-sq(d / (14.0 * scale))) * 0.7) * exp(-age / 45.0));
        float kb = unit(age / times.z);
        float wave = times.w * (1.0 - pow(1.0 - kb, 3.0));
        float fade = 1.0 - smoothstep(0.55, 1.0, kb);
        add(mix(hot, jewel1, 0.35), exp(-sq((d - wave) / (9.0 * scale))) * fade * 0.38 * inPair);
        add(hot, exp(-sq((d - wave + 3.0 * scale) / (1.6 * scale))) * fade * 0.55 * inPair);
        add(mix(hot, vec3(1.0), 0.6), exp(-sq(ax / (2.0 * scale))) * exp(-sq((d - wave) / (14.0 * scale))) * fade * 1.3);
        add(mix(hot, jewel1, 0.35), exp(-sq((d - wave) / (9.0 * scale))) * fade * 0.8 * (1.0 - inPair) * exp(-sd / (60.0 * scale)));
    }
    float charge = ahead > 0.0 ? 0.0 : 0.5 * smoothstep(ahead, 0.0, t);
    aura(p, sd, max(charge, smoothstep(times.x - 40.0, times.x + 60.0, t)) * (1.0 - smoothstep(times.y + 30.0, times.y + 200.0, t)), fire);
    float wall = smoothstep(0.8, 1.0, d / max(times.w - ROOM * scale, 1.0));
    float hit = age >= 0.0 ? exp(-age / 60.0) : smoothstep(times.y - 50.0, times.y, t) * 0.35;
    add(mix(fire, vec3(1.0), 0.5), exp(-sq(ax / (2.4 * scale))) * wall * hit * 1.6);
    add(fire, exp(-ax / (16.0 * scale)) * wall * hit * 0.5 * inPair);

    float handover = 1.0 - smoothstep(times.y + 80.0, times.y + 160.0, t);
    float solid = smoothstep(0.0, 10.0, age) * handover;
    float body = clamp(bar + 0.5 - d, 0.0, 1.0) * solid;
    float heat = age >= 0.0 ? exp(-age / COOL) : 0.0;
    float came = clamp(CAME * scale + 0.5 - ax, 0.0, 1.0) * handover;
    vec4 glow = finish(1.0);
    vec4 rod = vec4(mix(molding(0.5 + 0.5 * across / bar), fire, unit(heat * 1.1)), 1.0) * body;
    vec4 rim = vec4(mix(molding(0.5 + 0.5 * sd / (CAME * scale)), fire, unit(wall * hit) * 0.8), 1.0) * came;
    vec4 metal = ribbon + rod * (1.0 - ribbon.a);
    metal += rim * (1.0 - metal.a);
    fragColor = glow + metal * (1.0 - glow.a);
}
