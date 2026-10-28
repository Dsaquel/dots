#version 300 es
precision highp float;

in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;

uniform vec4 drawn;
uniform float t;
uniform vec4 times;
uniform vec2 entry;
uniform vec4 spear;
uniform float scale;
uniform vec4 lens;
uniform vec4 view;
uniform float forward;
uniform vec2 target;
uniform vec4 leads[8];
uniform float rounds[8];
uniform float count;
uniform float seed;
uniform vec3 hot;
uniform vec3 gold;
uniform vec3 jewel0;
uniform vec3 jewel1;
uniform vec3 jewel2;
uniform vec3 leaf;
uniform float ink;

const float PACKED = 80.0;
const float RING = 6.0;
const float BAND = 4.6;

vec3 L = vec3(0.0);
float E = 0.0;

#include "lib/math.glsl"

#include "lib/flat.glsl"

#include "lib/hash.glsl"

#include "lib/finish.glsl"

void main() {
    vec2 p = drawn.xy + v_texcoord * drawn.zw;
    vec3 fq = flatOf(p);
    vec2 q = fq.xy;
    float x = t - times.y;
    float d = length(q - entry);
    float H = target.y;
    vec3 white = ink > 0.5 ? vec3(1.0, 0.98, 0.92) : mix(hot, vec3(1.0), 0.6);
    vec3 flare = ink > 0.5 ? jewel1 : gold;
    vec3 line = ink > 0.5 ? mix(jewel1, leaf, 0.45) : gold;

    float frame = 0.0;
    float inside = 0.0;
    float lattice = 0.0;
    vec3 jewel = jewel1;
    for (int i = 0; i < 8; ++i) {
        if (float(i) >= count)
            break;
        vec4 b = leads[i];
        vec2 hw = b.zw * 0.5;
        float sw = sdRoundBox(q - b.xy - hw, hw, rounds[i]);
        frame = max(frame, exp(-sq((sw - BAND * scale) / (1.8 * scale))));
        float in1 = clamp(0.5 - sw, 0.0, 1.0);
        if (in1 > inside) {
            inside = in1;
            vec2 cell = vec2(44.0, 66.0) * scale;
            vec2 lr = q - b.xy;
            vec2 g = vec2(lr.x / cell.x + lr.y / cell.y, lr.x / cell.x - lr.y / cell.y);
            vec2 f = fract(g);
            float seam = min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y)) * min(cell.x, cell.y) * 0.7071;
            lattice = 1.0 - smoothstep(0.4 * scale, 1.6 * scale, seam);
            float h = hash(floor(g));
            jewel = h < 0.34 ? jewel0 : (h < 0.67 ? jewel1 : jewel2);
        }
    }
    frame *= fq.z;
    inside *= fq.z;

    float pk = span(t, times.y - PACKED, times.y);
    float near = x < 0.0 ? pk * pk : exp(-x / 90.0);
    vec2 ab = spear.xy - spear.zw;
    float along = clamp(dot(p - spear.zw, ab) / max(dot(ab, ab), 1.0), 0.0, 1.0);
    float ds = length(p - spear.zw - ab * along);
    float thick = mix(1.0, 6.0, along) * scale;
    float lit = pow(pk, 1.5) * (x < 0.0 ? 1.0 : exp(-x / 30.0)) * along;
    add(white, exp(-sq(ds / thick)) * lit * 1.5);
    add(flare, exp(-sq(ds / (4.0 * thick))) * lit * 0.4);
    float pool = exp(-d / (mix(0.55, 0.16, pk) * H));
    add(flare, near * pool * ((x < 0.0 ? 0.22 : 0.06) + 0.5 * frame + 0.35 * lattice * inside) * fq.z);
    if (ink > 0.5 && x < 0.0) {
        add(white, pk * pk * exp(-d / (0.45 * H)) * 0.45);
        add(line, pk * exp(-sq((d - (1.0 - pk) * 0.5 * H) / (2.2 * scale))) * 1.2);
    }
    add(white, near * exp(-sq(d / (mix(0.2, 0.05, pk) * H))) * 0.35 * fq.z);

    if (x >= 0.0) {
        float R = RING * scale * x;
        float fade = exp(-x / 420.0);
        float front = exp(-sq((d - R) / (2.2 * scale)));
        float band = exp(-sq((d - R) / (18.0 * scale)));
        float wake = step(d, R) * exp(-(R - d) / (70.0 * scale));
        float open = 1.0 - 0.45 * inside;
        vec2 rd = (q - entry) / max(d, 1e-3);
        float glint = 0.0;
        for (int i = 0; i < 4; ++i) {
            float a = seed + float(i) * 0.7854;
            glint += exp(-sq(abs(dot(rd, vec2(-sin(a), cos(a)))) * d / (1.4 * scale))) * exp(-d / ((i % 2 == 0 ? 0.15 : 0.08) * H));
        }
        add(white, exp(-x / 14.0) * 0.07 + exp(-x / 30.0) * 2.6 * exp(-d / (0.04 * H)) * (1.0 - smoothstep(0.14 * H, 0.24 * H, d)));
        add(ink > 0.5 ? mix(white, line, 0.55) : white, exp(-x / 30.0) * glint * (1.0 - smoothstep(0.2 * H, 0.3 * H, d)));
        add(flare, exp(-x / 80.0) * exp(-d / (0.1 * H)) * 0.55 * (1.0 - smoothstep(0.25 * H, 0.38 * H, d)));
        add(line, exp(-x / 70.0) * exp(-sq((d - 0.07 * H) / (0.035 * H))) * 0.7 * ink);
        add(white, front * fade * 0.85 * open);
        add(line, exp(-sq((d - R + 3.0 * scale) / (1.6 * scale))) * fade * 0.6 * open * ink);
        add(flare, (band * 0.3 + wake * 0.12) * fade * open);
        add(mix(flare, jewel, 0.4), inside * exp(-sq((d - R) / (32.0 * scale))) * fade * 0.18);
        add(flare, lattice * inside * exp(-sq((d - R) / (22.0 * scale))) * fade * 1.1);
        float passed = x - d / (RING * scale);
        add(mix(flare, white, 0.5), frame * exp(-sq((d - R) / (26.0 * scale))) * fade * 2.4);
        add(flare, frame * step(0.0, passed) * exp(-passed / 170.0) * 0.55 * fade);
    }

    float gone = 1.0 - span(x, 300.0, 480.0);
    float dim = ink > 0.5 || x >= 0.0 ? 0.0 : 0.3 * (0.55 + 0.45 * smoothstep(0.05 * H, 0.7 * H, d)) * pk * pk;
    L *= gone;
    E *= gone;
    if (ink < 0.5) {
        fragColor = vec4(L, dim);
        return;
    }
    float a = clamp(E * 1.1, 0.0, 0.95);
    vec3 c = mix(E > 1e-4 ? L / E : flare, white, smoothstep(0.5, 1.6, E));
    fragColor = vec4(c * a, a);
}
