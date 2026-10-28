#version 300 es
precision highp float;

in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;

uniform vec4 drawn;
uniform vec4 win;
uniform vec2 came;
uniform float radius;
uniform float scale;
uniform float t;
uniform vec4 times;
uniform vec2 entry;
uniform vec4 lens;
uniform vec4 view;
uniform float forward;
uniform vec2 target;
uniform float seed;
uniform vec3 hot;
uniform vec3 gold;
uniform vec3 jewel0;
uniform vec3 jewel1;
uniform vec3 jewel2;
uniform vec3 leaf;
uniform vec4 cut;
uniform float ink;

const float PI = 3.14159265;
const float TAU = 6.2831853;
const float VEINS = 18.0;
const float FAN = 2.6;
const float PACKED = 80.0;
const float CRACKED = 60.0;
const float FLASHED = 150.0;
const float FADED = 290.0;
const float OPENED = 270.0;

vec3 L = vec3(0.0);
float E = 0.0;

#include "lib/math.glsl"

#include "lib/flat.glsl"

#include "lib/hash.glsl"

float zig(float x, float k) {
    float i = floor(x);
    return mix(hash(vec2(i, k)), hash(vec2(i + 1.0, k)), x - i) - 0.5;
}

#include "lib/finish.glsl"

#include "lib/vein.glsl"

void main() {
    vec2 p = drawn.xy + v_texcoord * drawn.zw;
    vec3 fq = flatOf(p);
    vec2 q = fq.xy;
    vec2 hs = win.zw * 0.5;
    float inWin = clamp(0.5 - sdRoundBox(q - win.xy - hs, hs, radius), 0.0, 1.0) * fq.z;
    float x = t - times.y;
    if (inWin <= 0.0 || x < -PACKED || x > max(FADED, times.z + OPENED + 150.0 - times.y)) {
        fragColor = vec4(0.0);
        return;
    }
    vec2 far = max(abs(win.xy - entry), abs(win.xy + win.zw - entry));
    float reach = max(length(far), 1.0);
    vec2 rel = q - entry;
    float r = length(rel);
    float base = fanBase();
    float ang = atan(rel.y, rel.x);
    vec3 white = ink > 0.5 ? vec3(1.0, 0.98, 0.92) : mix(hot, vec3(1.0), 0.6);
    vec3 flare = ink > 0.5 ? jewel1 : gold;
    vec3 line = ink > 0.5 ? mix(jewel1, leaf, 0.45) : gold;

    vec2 cell = vec2(44.0, 66.0) * scale;
    vec2 lr = q - win.xy;
    vec2 g = vec2(lr.x / cell.x + lr.y / cell.y, lr.x / cell.x - lr.y / cell.y);
    vec2 f = fract(g);
    float seam = min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y)) * min(cell.x, cell.y) * 0.7071;
    float leading = 1.0 - smoothstep(0.4 * scale, 1.8 * scale, seam);
    float hh = hash(floor(g));
    vec3 jewel = hh < 0.34 ? jewel0 : (hh < 0.67 ? jewel1 : jewel2);

    float pk = span(x, -PACKED, 0.0);
    float near = x < 0.0 ? pk * pk : exp(-x / 90.0);
    float pool = exp(-r / (mix(0.6, 0.18, pk) * reach));
    add(flare, near * pool * (leading * 0.9 + (1.0 - leading) * 0.06));
    add(mix(flare, jewel, 0.5), near * pool * (1.0 - leading) * 0.1);
    if (x >= 0.0) {
        float near0 = floor((mod(ang - base + PI, TAU) - PI) / FAN * 0.5 * VEINS + 0.5 * VEINS);
        float hair = 0.0;
        float hot0 = 0.0;
        for (int i = -3; i <= 3; ++i) {
            float j = near0 + float(i);
            if (j < 0.0 || j > VEINS - 1.0)
                continue;
            float len = veinReach(j, base, win);
            float lag = 8.0 * veinHash(j, 9.0);
            if (r < len) {
                float rc = len * (1.0 - sq(1.0 - span(x, lag, lag + CRACKED)));
                float jag = zig(r / (14.0 * scale), j + seed) * 8.0 * scale / max(r, 24.0 * scale);
                float d0 = abs(mod(ang - veinBend(j, base, r, reach, len, 0.0) - jag + PI, TAU) - PI) * r;
                float d1 = abs(mod(ang - veinBend(j, base, r, reach, len, 1.0) - jag * 1.3 + PI, TAU) - PI) * r;
                float forked = smoothstep(0.3, 0.5, r / len);
                float crack = max(exp(-sq(d0 / (0.75 * scale))), exp(-sq(d1 / (0.6 * scale))) * forked);
                float cracked = smoothstep(rc + 2.0 * scale, rc - 6.0 * scale, r) * (1.0 - smoothstep(0.92, 1.0, r / len));
                float born = lag + CRACKED * (1.0 - sqrt(max(1.0 - r / len, 0.0)));
                hair = max(hair, crack * cracked);
                hot0 = max(hot0, crack * cracked * exp(-max(x - born, 0.0) / 40.0));
            }
            float k1 = j + 1.0;
            if (i == 3 || k1 > VEINS - 1.0 || r > 0.24 * reach)
                continue;
            float len1 = veinReach(k1, base, win);
            for (int w = 0; w < 3; ++w) {
                float ring = reach * (0.045 + 0.06 * float(w) + 0.008 * float(w * w));
                if (veinHash(j + 0.5, float(w) + 11.0) < 0.3)
                    continue;
                float ra = ring * (0.85 + 0.3 * veinHash(j, float(w) + 13.0));
                float rb = ring * (0.85 + 0.3 * veinHash(k1, float(w) + 13.0));
                float aa = veinBend(j, base, ra, reach, len, 0.0);
                float bb = veinBend(k1, base, rb, reach, len1, 0.0);
                vec2 pa = entry + ra * vec2(cos(aa), sin(aa));
                vec2 ba = entry + rb * vec2(cos(bb), sin(bb)) - pa;
                float dw = length(q - pa - ba * clamp(dot(q - pa, ba) / max(dot(ba, ba), 1.0), 0.0, 1.0));
                float wb = lag + CRACKED * (1.0 - sqrt(max(1.0 - ring / len, 0.0))) + 6.0;
                float web = exp(-sq(dw / (0.6 * scale))) * step(wb, x);
                hair = max(hair, web);
                hot0 = max(hot0, web * exp(-(x - wb) / 50.0));
            }
        }

        float cutLine = 0.0;
        if (cut.w > cut.z) {
            bool upright = cut.x > 0.5;
            float along = upright ? q.y : q.x;
            float at = upright ? entry.y : entry.x;
            float across = (upright ? q.x : q.y) - cut.y + zig(along / (18.0 * scale), 7.1 + seed) * 4.0 * scale;
            float run = 1.0 - sq(1.0 - span(x, 0.0, max(times.z - times.y, 1.0)));
            float span0 = at - cut.z;
            float span1 = cut.w - at;
            float reachCut = along < at ? span0 * run : span1 * run;
            float onCut = step(abs(along - at), reachCut + 1.0) * step(cut.z, along) * step(along, cut.w);
            float bridgeD = length(vec2((upright ? q.x : q.y) - clamp(upright ? q.x : q.y, min(cut.y, upright ? entry.x : entry.y), max(cut.y, upright ? entry.x : entry.y)), along - at));
            float bridgeOn = exp(-sq(bridgeD / (1.2 * scale))) * span(x, 0.0, 8.0);
            float open = 1.0 - span(t, times.z + OPENED, times.z + OPENED + 150.0);
            cutLine = max(exp(-sq(across / (1.2 * scale))) * onCut, bridgeOn) * open;
        }

        float well = exp(-sq(r / (26.0 * scale))) * (1.5 * exp(-x / 60.0));
        add(white, hot0 * 1.6 + cutLine * (1.4 * exp(-x / 120.0) + 0.5) + well);
        add(line, hair * 0.3 * (1.0 - span(x, 60.0, FLASHED)));
        add(flare, exp(-r / (0.15 * reach)) * exp(-x / 100.0) * 0.15);
    }
    L *= inWin;
    E *= inWin;
    if (ink < 0.5) {
        fragColor = vec4(L * 0.9, 0.0);
        return;
    }
    float a = clamp(E * 0.85, 0.0, 0.92);
    vec3 c = mix(E > 1e-4 ? L / E : flare, white, smoothstep(0.5, 1.6, E));
    fragColor = vec4(c * a, a);
}
