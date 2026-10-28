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
uniform float reveal;
uniform float seed;
uniform vec3 hot;
uniform vec3 gold;
uniform vec3 leadLow;
uniform vec3 leadBase;
uniform vec3 leadHi;
uniform vec3 sepia;
uniform vec3 leaf;
uniform float ink;
uniform vec4 gates[4];
uniform float gated;
uniform vec2 glide;
uniform vec3 lanes;

const float PI = 3.14159265;
const float EASE = 0.3;
const float SPAN = 0.70710678;
const float WIND = 0.05;
const float LIP = 40.0;
const float WELL = 50.0;
const float NEAR = 80.0;
const float HUB = 140.0;
const float GRAIN = 90.0;
const float DRIFT = 0.55;
const float FLOW = 0.0035;
const float CURRENT = 0.3;
const float WEFT = 2.2;
const float THROAT = 40.0;
const float DRAINED = 150.0;

#include "lib/math.glsl"

float hash(vec2 p) {
    vec3 q = fract(vec3(p.xyx) * 0.1031 + seed * 0.618);
    q += dot(q, q.yzx + 33.33);
    return fract((q.x + q.y) * q.z);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
    float sum = 0.0;
    float amp = 0.5;
    for (int i = 0; i < 4; ++i) {
        sum += amp * noise(p);
        p = mat2(1.6, 1.2, -1.2, 1.6) * p + 7.3;
        amp *= 0.5;
    }
    return sum / 0.9375;
}

#include "lib/turn.glsl"

float easeOf(float k) {
    return EASE * k + (1.0 - EASE) * k * k;
}

float progress(float r, float at) {
    float go = times.x + lag * min(r, 1.0);
    return unit((at - go) / (times.y - go));
}

float drawnOf(float r, float at) {
    float go = times.x + lag * min(r, 1.0);
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

vec4 tint(float band, float fine, float heat, float front, float cover) {
    vec3 col;
    float alpha;
    if (ink > 0.5) {
        vec3 bed = mix(mix(leaf, sepia, 0.12), gold, band) + hot * pow(band, 10.0) * 0.3;
        col = mix(bed, mix(gold, hot, 0.7), unit(heat)) + hot * 0.3 * (fine + front);
        alpha = 0.95;
    } else {
        vec3 crust = mix(leadLow, leadBase, band) + leadHi * pow(band, 12.0) * 0.12;
        vec3 molten = mix(gold * 0.7, mix(hot, vec3(1.0), 0.35), smoothstep(0.55, 1.4, heat));
        col = mix(crust, molten, smoothstep(0.05, 0.75, heat)) + hot * 0.4 * front;
        alpha = 0.97;
    }
    return vec4(col, 1.0) * alpha * cover;
}

vec4 woven(vec2 p) {
    vec2 hs = 0.5 * pair.zw;
    float inPair = clamp(0.5 - sdRoundBox(p - pair.xy - hs, hs, corner), 0.0, 1.0);
    vec2 slide = glide * (1.0 - easeOf(unit((t - times.x) / (times.y - times.x))));
    float d = 1e9;
    float g = 1e9;
    float lam = 1.0;
    for (int i = 0; i < 4; ++i) {
        if (float(i) >= gated)
            break;
        vec2 e = gates[i].zw - gates[i].xy;
        vec2 q = p - gates[i].xy;
        d = min(d, length(q - e * unit(dot(q, e) / max(dot(e, e), 1e-6))));
        q -= slide;
        float u = unit(dot(q, e) / max(dot(e, e), 1e-6));
        float gi = length(q - e * u);
        if (gi < g) {
            g = gi;
            lam = 2.0 * u - 1.0;
        }
    }
    float land = times.y + times.z * (1.0 - pow(1.0 - unit(d / times.w), 1.0 / 3.0));
    float cover = smoothstep(0.0, WELL, t) * (1.0 - smoothstep(land, land + 0.5 * reveal, t)) * inPair;
    bool wide = lanes.x > 0.5;
    float x = wide ? p.x : p.y;
    float y = (wide ? p.y : p.x) - lanes.z;
    float yl = y / lanes.y - floor(y / lanes.y + 0.5);
    vec2 q = vec2((x - cos(PI * y / lanes.y) * CURRENT * t * scale) / (WEFT * GRAIN * scale), y / (GRAIN * scale));
    vec2 warp = vec2(fbm(q * 0.35 + vec2(0.0, -0.0015 * t)), fbm(q * 0.35 + vec2(5.2, 1.3 + 0.0015 * t)));
    float field = fbm(q * 0.45 + 1.8 * warp);
    float flow = 3.0 * field - FLOW * t;
    float band = 0.5 + 0.5 * sin(2.0 * PI * flow);
    float vein = exp(-sq((fract(flow) - 0.5) / 0.045));
    float fine = exp(-sq((fract(2.0 * flow + 0.37) - 0.5) / 0.03)) * smoothstep(0.35, 0.75, field);
    float open = smoothstep(times.x - 10.0, times.x + 40.0, t) * (1.0 - smoothstep(times.y, times.y + 60.0, t));
    float seam = exp(-sq((abs(yl) - 0.5) / 0.04)) * open;
    float len = min(ahead > 0.0 ? 1.0 : smoothstep(times.x, times.x + 30.0, t), 1.0 - smoothstep(times.y - 40.0, times.y, t));
    float w = THROAT * scale * (len > 1e-3 ? unit(1.0 - sq(lam / len)) : 0.0) + 6.0 * scale;
    float channel = exp(-sq(g / w)) * open;
    float wall = wide ? min(p.x - pair.x, pair.x + pair.z - p.x) : min(p.y - pair.y, pair.y + pair.w - p.y);
    float drained = exp(-max(wall, 0.0) / (DRAINED * scale)) * smoothstep(110.0, 210.0, t) * (1.0 - smoothstep(times.y - 10.0, times.y + 40.0, t));
    float slam = t >= times.y ? exp(-(t - times.y) / 70.0) : 0.0;
    float veins = 0.8 * vein + 0.5 * fine;
    float heat = veins * (0.5 + 0.5 * open + 0.7 * drained) + 0.15 * seam + 1.5 * channel + 0.2 * drained + 0.4 * slam;
    float front = exp(-sq((t - land) / 18.0)) * step(times.y, t);
    return tint(band, fine, heat, front, cover);
}

float sourceOf(vec2 p) {
    float a = angleOf(length(normOf(p, hubs.xy)) * SPAN);
    for (int i = 0; i < 5; ++i)
        a = angleOf(length(normOf(p, hubOf(a))) * SPAN / fitOf(a));
    return a;
}

void main() {
    vec2 p = drawn.xy + v_texcoord * drawn.zw;
    if (gated > 0.5) {
        fragColor = woven(p);
        return;
    }
    vec2 v = p - hand.xy;
    vec2 hs = 0.5 * pair.zw;
    float inPair = clamp(0.5 - sdRoundBox(p - pair.xy - hs, hs, corner), 0.0, 1.0);
    float a = sourceOf(p);
    vec2 nq = normOf(p, hubOf(a));
    vec2 m = turned(nq, -a) / fitOf(a);
    vec2 axis = vec2(cos(hand.z), sin(hand.z));
    float f = dot(m, vec2(-axis.y, axis.x));
    float bar = abs(f) / max(length(vec2(dFdx(f), dFdy(f))), 1e-7);
    float g = ringOf(m) - 1.0;
    float lip = g / max(length(vec2(dFdx(g), dFdy(g))), 1e-7);
    vec2 q = (denorm(turned(nq, -DRIFT * a), hubOf(a)) - hubOf(a)) / (GRAIN * scale);

    float land = times.y + times.z * (1.0 - pow(1.0 - unit(length(v) / times.w), 1.0 / 3.0));
    float cover = smoothstep(ahead > 0.0 ? 0.0 : ahead, WELL, t) * (1.0 - smoothstep(land, land + 0.5 * reveal, t)) * inPair;
    float turning = smoothstep(times.x - 20.0, times.x + 80.0, t) * (1.0 - smoothstep(times.y, times.y + 100.0, t));
    vec2 warp = vec2(fbm(q * 0.35 + vec2(0.0, -0.0015 * t)), fbm(q * 0.35 + vec2(5.2, 1.3 + 0.0015 * t)));
    float field = fbm(q * 0.45 + 1.8 * warp);
    float flow = 3.0 * field - FLOW * t;
    float band = 0.5 + 0.5 * sin(2.0 * PI * flow);
    float vein = exp(-sq((fract(flow) - 0.5) / 0.045));
    float fine = exp(-sq((fract(2.0 * flow + 0.37) - 0.5) / 0.03)) * smoothstep(0.35, 0.75, field);
    float under = clamp(0.5 - lip, 0.0, 1.0);
    float near = exp(-bar / (NEAR * scale)) * under;
    float edge = exp(-max(lip, 0.0) / (LIP * scale)) * (1.0 - under) * turning;
    float hub = exp(-length(p - hubOf(a)) / (HUB * scale));
    float slam = t >= times.y ? exp(-(t - times.y) / 70.0) : 0.0;
    float cracks = (0.8 * vein + 0.5 * fine) * (0.5 + 0.5 * turning);
    float heat = mix(cracks, 0.8 + 0.3 * vein, under) + 0.5 * near + 0.9 * edge + 0.45 * hub + 0.4 * slam;
    float front = exp(-sq((t - land) / 18.0)) * step(times.y, t);
    fragColor = tint(band, fine, heat, front, cover);
}
