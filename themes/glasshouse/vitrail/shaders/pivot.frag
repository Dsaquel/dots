#version 300 es
precision highp float;

in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;

uniform vec4 drawn;
uniform vec4 pair;
uniform vec4 hull;
uniform float corner;
uniform float scale;
uniform float t;
uniform vec4 hand;
uniform vec4 hubs;
uniform vec4 times;
uniform float lag;
uniform float ahead;
uniform float skew[9];
uniform float bar;
uniform vec3 hot;
uniform vec3 jewel1;
uniform vec3 leadLow;
uniform vec3 leadBase;
uniform vec3 leadHi;
uniform vec3 sepia;
uniform vec3 leaf;
uniform float ink;

const float PI = 3.14159265;
const float SPAN = 0.70710678;
const float WIND = 0.05;
const float CAME = 2.4;
const float FLUSH = 40.0;
const float COOL = 120.0;
const float SPARK = 110.0;

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

#include "lib/turn.glsl"

float startOf(float r) {
    return times.x + lag * min(r, 1.0);
}

float progress(float r, float at) {
    float go = startOf(r);
    return unit((at - go) / (times.y - go));
}

float drawnOf(float r, float at) {
    float go = startOf(r);
    return ahead > 0.0 ? 0.0 : (at < go ? smoothstep(ahead, go, at) : 1.0 - smoothstep(0.0, 1.0, progress(r, at)));
}

float angleOf(float r) {
    float f = clamp(r, 0.0, 1.0) * 8.0;
    int i = min(int(f), 7);
    float k = progress(r, t);
    float k0 = progress(r, ahead);
    float e = 1.0 - k * k;
    return 0.5 * PI * (1.0 - e) + mix(skew[i], skew[i + 1], f - float(i)) * e / max(1.0 - k0 * k0, 1e-3) - WIND * drawnOf(r, t);
}

vec2 sourceOf(vec2 p, out float r, out vec2 n) {
    float a = angleOf(length(normOf(p, hubs.xy)) * SPAN);
    for (int i = 0; i < 5; ++i)
        a = angleOf(length(normOf(p, hubOf(a))) * SPAN / fitOf(a));
    n = normOf(p, hubOf(a));
    r = min(length(n) * SPAN / fitOf(a), 1.0);
    return turned(n, -a) / fitOf(a);
}

vec2 tipOf(vec2 d, float rim) {
    vec2 e = d * (1.0 + rim / dot(abs(d), extOf(d, hubs.xy)));
    float a = angleOf(length(e) * SPAN);
    return denorm(turned(e, a) * fitOf(a), hubOf(a));
}

void main() {
    vec2 p = drawn.xy + v_texcoord * drawn.zw;
    vec2 v = p - hand.xy;
    vec2 nq;
    float rq;
    vec2 m = sourceOf(p, rq, nq);
    float ks = progress(rq, t);
    float spin = t > startOf(rq) && t < times.y ? 2.0 * ks : 0.0;
    float age = t - times.y;
    vec3 fire = ink > 0.5 ? leaf : hot;

    vec2 hs = 0.5 * pair.zw;
    float sd = sdRoundBox(p - pair.xy - hs, hs, corner);
    float ax = abs(sd);
    float inPair = clamp(0.5 - sd, 0.0, 1.0);
    float rel = mod(mod(hand.w * (atan(nq.y, nq.x) - 0.25 * PI), 2.0 * PI), 0.5 * PI);
    float go = startOf(1.0);
    float passed = go + (times.y - go) * sqrt(unit(rel / (0.5 * PI)));
    float molten = t >= passed ? exp(-(t - passed) / COOL) : 0.0;
    vec2 axis = vec2(cos(hand.z), sin(hand.z));
    float tf = FLUSH * unit(abs(dot(v, vec2(-axis.y, axis.x))) / max(abs(axis.y) * hs.x + abs(axis.x) * hs.y, 1.0));
    float flush = exp(-sq((t - tf) / 12.0));
    float handover = 1.0 - smoothstep(times.y + 80.0, times.y + 160.0, t);
    float came = clamp(CAME * scale + 0.5 - ax, 0.0, 1.0) * handover;
    add(fire, exp(-sq(ax / (2.2 * scale))) * (0.8 * molten + 0.9 * flush) * handover);
    add(hot, exp(-sq(ax / (7.0 * scale))) * (0.25 * molten + 0.25 * flush) * handover);

    float f = dot(m, vec2(-axis.y, axis.x));
    vec2 T0 = tipOf(axis, 0.5 * (pair.z - hull.z));
    vec2 T1 = tipOf(-axis, 0.5 * (pair.z - hull.z));
    float swinging = smoothstep(times.x - 10.0, times.x + 10.0, t) * (1.0 - step(times.y, t));
    add(mix(fire, vec3(1.0), 0.4), (exp(-dot(p - T0, p - T0) / sq(9.0 * scale)) + exp(-dot(p - T1, p - T1) / sq(9.0 * scale))) * swinging * (0.8 + 0.6 * spin));
    float a1 = angleOf(1.0);
    float grind = 0.0;
    for (int i = 0; i < 4; ++i) {
        vec2 C = denorm(turned(vec2(i == 0 || i == 3 ? 1.0 : -1.0, i < 2 ? 1.0 : -1.0), a1) * fitOf(a1), hubOf(a1)) - p;
        grind += exp(-dot(C, C) / sq(11.0 * scale)) + 0.35 * exp(-length(C) / (28.0 * scale));
    }
    add(mix(fire, vec3(1.0), 0.5), grind * smoothstep(times.x + 10.0, times.x + 60.0, t) * (1.0 - step(times.y, t)) * (0.7 + 0.8 * progress(1.0, t)));

    float along = dot(m, axis);
    float across = f / max(length(vec2(dFdx(f), dFdy(f))), 1e-7);
    float within = clamp(0.5 - sdRoundBox(denorm(m, hubs.xy) - pair.xy - hs, hs, corner), 0.0, 1.0);
    float gone = 1.0 - smoothstep(times.y + 90.0, times.y + 170.0, t);
    float body = clamp(bar + 0.5 - abs(across), 0.0, 1.0) * within * gone;
    float lead = across * hand.w * sign(along);
    float far = sqrt(unit(abs(along)));
    add(mix(fire, vec3(1.0), 0.3), within * exp(-sq((lead - bar) / (1.6 * scale))) * far * spin * 0.9);
    add(fire, within * step(bar, lead) * exp(min(bar - lead, 0.0) / (7.0 * scale)) * far * spin * 0.35);
    add(hot, within * step(lead, -bar) * exp(min(lead + bar, 0.0) / (60.0 * scale)) * far * spin * 0.12);
    float heat = exp(-abs(t) / 30.0) + (age >= 0.0 ? exp(-age / 80.0) : 0.0);
    add(hot, exp(-sq(across / (8.0 * scale))) * within * heat * 0.3 * gone);

    if (age >= 0.0) {
        float d0 = length(p - T0);
        float d1 = length(p - T1);
        add(mix(fire, vec3(1.0), 0.6), (exp(-sq(d0 / (16.0 * scale))) + exp(-sq(d1 / (16.0 * scale)))) * exp(-age / 50.0) * 2.2);
        float rz = (4.0 + 40.0 * (1.0 - exp(-age / 40.0))) * scale;
        add(fire, (exp(-sq((d0 - rz) / (2.0 * scale))) + exp(-sq((d1 - rz) / (2.0 * scale)))) * exp(-age / 70.0) * 0.9);
        float dc = length(v);
        add(mix(fire, vec3(1.0), 0.5), exp(-sq(dc / (26.0 * scale))) * exp(-age / 60.0) * 1.4);
        float kb = unit(age / times.z);
        float wave = times.w * (1.0 - pow(1.0 - kb, 3.0));
        float w = 1.0 - smoothstep(0.55, 1.0, kb);
        add(mix(hot, jewel1, 0.35), exp(-sq((dc - wave) / (9.0 * scale))) * w * 0.38 * inPair);
        add(hot, exp(-sq((dc - wave + 3.0 * scale) / (1.6 * scale))) * w * 0.5 * inPair);
        add(mix(hot, vec3(1.0), 0.6), (exp(-sq(ax / (2.0 * scale))) + exp(-sq(across / (3.0 * scale))) * within) * exp(-sq((dc - wave) / (14.0 * scale))) * w * 1.3);
        add(mix(hot, jewel1, 0.35), exp(-sq((dc - wave) / (9.0 * scale))) * w * 0.8 * (1.0 - inPair) * exp(-sd / (60.0 * scale)));
    }
    vec2 d1 = turned(axis, 0.5 * PI);
    vec2 o1 = p - hubs.zw;
    float u1 = abs(dot(o1, d1));
    float w1 = abs(dot(o1, vec2(-d1.y, d1.x)));
    float room = min(abs(dot(extOf(d1, hubs.zw), d1)), abs(dot(extOf(-d1, hubs.zw), d1)));
    float reach = ahead > 0.0 ? 0.0 : smoothstep(ahead + 20.0, times.x + 20.0, t);
    float span = max(reach * min(SPARK * scale, 0.6 * room), 1e-3);
    float k1 = progress(1.0, t);
    float guide = (0.5 + 0.9 * k1 * k1) * (1.0 - smoothstep(times.y - 10.0, times.y + 40.0, t)) * inPair * gone;
    float edge = u1 / span + w1 / (3.0 * scale);
    float halo = u1 / (1.3 * span) + w1 / (7.0 * scale);
    add(mix(fire, vec3(1.0), 0.4), (pow(unit(1.0 - edge), 2.0) * 1.4 + pow(unit(1.0 - halo), 3.0) * 0.3) * guide * (ink > 0.5 ? 1.8 : 1.0));

    float charge = ahead > 0.0 ? 0.0 : 0.5 * smoothstep(ahead, 0.0, t);
    aura(p, sd, max(charge, smoothstep(times.x - 40.0, times.x + 60.0, t)) * (1.0 - smoothstep(times.y + 30.0, times.y + 200.0, t)), fire);

    vec4 glow = finish(1.0);
    vec4 rod = vec4(mix(molding(0.5 + 0.5 * across / bar), fire, unit(heat * 0.8)), 1.0) * body;
    vec4 rim = vec4(mix(molding(0.5 + 0.5 * sd / (CAME * scale)), fire, unit(molten + flush) * 0.7), 1.0) * came;
    fragColor = glow + (rod + rim * (1.0 - rod.a)) * (1.0 - glow.a);
}
