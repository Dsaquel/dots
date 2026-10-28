#version 300 es
precision highp float;

uniform mat3 proj;
uniform vec2 target;
uniform vec3 screen;
uniform float kind;
uniform vec4 box;
uniform vec2 grid;
uniform float t;
uniform float base;
uniform float crack;
uniform vec2 born;
uniform vec4 seal;
uniform float seed;
uniform highp sampler2D perm;
uniform vec3 hot;
uniform vec3 dust;
uniform vec3 jewel0;
uniform vec3 jewel1;
uniform vec3 sepia;
uniform vec3 leaf;
uniform float ink;
uniform vec4 hand;
uniform vec4 swing;
uniform float ahead;
uniform float skew[9];
uniform vec4 hull;
uniform vec4 hubs;
uniform vec4 gilt[8];
uniform float gilts;
uniform vec4 gates[4];
uniform float gated;
uniform vec2 glide;
uniform float stride;
uniform vec4 goal;
uniform vec3 ring;
uniform float lanes;
uniform float cooled;

out vec2 v_q;
flat out vec4 v_col;
flat out float v_hard;

const float PI = 3.14159265;
const float EASE = 0.3;
const float SPRAY = 120.0;
const float GILDED = 40.0;
const float SPAN = 0.70710678;
const float WIND = 0.05;
const float ARCED = 40.0;
const float RIMMED = 130.0;
const float FLICK = 16.0;
const float JIT = 10.0;
const float STRIKE = 0.55;
const float CHARGED = 0.9;
const float LINK = 64.0;
const float STRIKES = 3.0;
const float DROPS = 12.0;
const float GRAVITY = 0.0028;

#include "lib/math.glsl"

#include "lib/turn.glsl"

#include "lib/hash.glsl"

vec2 midOf(float iu, float iv) {
    return vec2((iu + iv + 1.0) / grid.x, (iu - iv) / grid.y) * 0.5;
}

vec2 junction(vec2 j) {
    return box.xy + vec2((j.x + j.y) / (2.0 * grid.x), (j.x - j.y) / (2.0 * grid.y)) * box.zw;
}

float hard = 3.2;

void cull() {
    gl_Position = vec4(2.0, 2.0, 2.0, 1.0);
    v_q = vec2(0.0);
    v_col = vec4(0.0);
    v_hard = 3.2;
}

void emit(vec2 pos, vec2 along, float len, float wid, vec3 col, float a, vec2 q) {
    vec2 P = pos + along * q.x * len + vec2(-along.y, along.x) * q.y * wid;
    gl_Position = vec4((proj * vec3((P - screen.xy) * screen.z / target, 1.0)).xy, 0.0, 1.0);
    v_q = q;
    v_col = vec4(col, a);
    v_hard = hard;
}

void fly(vec2 O, vec2 v0, float tau, float life, float wid, vec3 col, float h, vec2 q) {
    float drag = 150.0;
    float fall = 0.00022;
    vec2 pos = O + v0 * drag * (1.0 - exp(-tau / drag)) + vec2(0.0, 0.5 * fall * tau * tau);
    vec2 vel = v0 * exp(-tau / drag) + vec2(0.0, fall * tau);
    float speed = length(vel);
    float fade = pow(1.0 - tau / life, 1.6) * (0.75 + 0.25 * sin(tau * 0.11 + 40.0 * h));
    emit(pos, speed > 1e-4 ? vel / speed : vec2(1.0, 0.0), 3.0 + speed * 22.0, wid, col, fade * smoothstep(0.0, 18.0, tau), q);
}

float turnInv(float f) {
    return sqrt(clamp(f, 0.0, 1.0));
}

vec2 at(vec2 n, float a) {
    return denorm(rot(hand.w * a) * n / (abs(cos(a)) + abs(sin(a))), hubOf(a));
}

float spanOf(vec2 n) {
    return min(length(n) * SPAN, 1.0);
}

float easeOf(float k) {
    return EASE * k + (1.0 - EASE) * k * k;
}

float progress(float r, float at) {
    float go = swing.x + swing.w * r;
    return unit((at - go) / (swing.y - go));
}

float drawnOf(float r, float at) {
    float go = swing.x + swing.w * r;
    return ahead > 0.0 ? 0.0 : (at < go ? smoothstep(ahead, go, at) : 1.0 - smoothstep(0.0, 1.0, progress(r, at)));
}

float angleOf(float r, float at) {
    float f = r * 8.0;
    int i = min(int(f), 7);
    float k = progress(r, at);
    float k0 = progress(r, ahead);
    float e = 1.0 - k * k;
    return 0.5 * PI * (1.0 - e) + mix(skew[i], skew[i + 1], f - float(i)) * e / max(1.0 - k0 * k0, 1e-3) - WIND * drawnOf(r, at);
}

float sentAt(float r, float k) {
    float go = swing.x + swing.w * r;
    return go + (swing.y - go) * k;
}

#include "spark/turn.glsl"

#include "spark/rim.glsl"

#include "spark/spatter.glsl"

#include "spark/rift.glsl"

void main() {
    int id = gl_VertexID;
    int corner = id - (id / 6) * 6;
    int k = corner < 3 ? corner : (corner == 3 ? 0 : corner - 2);
    vec2 q = vec2(k == 1 || k == 2 ? 1.0 : -1.0, k >= 2 ? 1.0 : -1.0);
    float s = float(id / 6);
    if (kind > 12.5) {
        splash(s, q);
        return;
    }
    if (kind > 9.5) {
        riftSparks(s, q);
        return;
    }
    if (kind > 7.5) {
        gateSparks(s, q);
        return;
    }
    if (kind > 3.5) {
        turnSparks(s, q);
        return;
    }
    float nu = grid.x + grid.y;
    vec2 c = 1.0 / grid;
    vec2 size = box.zw;
    vec2 C = box.xy + 0.5 * size;
    vec3 spark = ink > 0.5 ? mix(sepia, leaf, 0.7) : mix(hot, vec3(1.0), 0.35);

    if (kind < 0.5) {
        float iu = mod(s, nu);
        float iv = floor(s / nu) - grid.y;
        vec2 mid = midOf(iu, iv);
        vec2 off = abs(mid - clamp(mid, 0.0, 1.0)) / c;
        vec4 g = hash4(vec2(iv + 17.0, iu - 5.0));
        if (2.0 * (off.x + off.y) >= 1.0 || g.x > 0.55) {
            cull();
            return;
        }
        vec2 S = box.xy + mid * size;
        vec2 O = box.xy + (mid - vec2(0.0, 0.5 * c.y)) * size;
        float tau = t - crack * unit(length(S - C) / max(0.5 * length(size), 1.0));
        float life = 140.0 + 130.0 * g.w;
        if (tau < 0.0 || tau > life) {
            cull();
            return;
        }
        vec2 away = O - C;
        vec2 u = length(away) > 1.0 ? normalize(away) : vec2(cos(2.0 * PI * g.y), sin(2.0 * PI * g.y));
        fly(O, rot((g.y - 0.5) * 1.4) * u * (0.15 + 0.45 * g.z), tau, life, 1.4 + 1.2 * g.w, spark, g.z, q);
        return;
    }

    if (kind < 2.5) {
        float cell = floor(s / 3.0);
        float j = s - 3.0 * cell;
        float iu = mod(cell, nu);
        float iw = floor(cell / nu);
        vec4 p = texelFetch(perm, ivec2(int(iu), int(iw)), 0);
        if (p.x < 0.0) {
            cull();
            return;
        }
        vec4 g = hash4(vec2(iu * 3.1 + j, iw - j * 1.7));
        float si = floor(p.x * 0.5);
        float su = mod(si, nu);
        float sv = floor(si / nu) - grid.y;
        float iv = iw - grid.y;
        vec2 S = box.xy + midOf(su, sv) * size;
        if (kind < 1.5) {
            float kf = (t - base - p.y) / born.x;
            if (kf < 0.0 || kf > 1.0) {
                cull();
                return;
            }
            float a = 2.0 * PI * (j / 3.0 + g.x) + 2.4 * kf * (g.y > 0.5 ? 1.0 : -1.0);
            vec2 u = vec2(cos(a), sin(a));
            float rim = 0.5 / (abs(u.x) / (c.x * size.x) + abs(u.y) / (c.y * size.y));
            float rad = rim * (0.25 + 0.67 * kf) + pow(1.0 - kf, 1.4) * (22.0 + 22.0 * g.z);
            vec3 col = ink > 0.5 ? mix(sepia, leaf, 0.5 + 0.5 * g.z) : mix(hot, mix(jewel0, jewel1, g.z), 0.45);
            emit(S + u * rad, vec2(1.0, 0.0), 1.3 + 0.8 * kf, 1.3 + 0.8 * kf, col, (0.3 + 1.0 * kf) * (1.0 - smoothstep(0.75, 1.0, kf)), q);
            return;
        }
        vec2 H = box.xy + midOf(iu, iv) * size;
        vec2 K = box.xy + (mod(p.x, 2.0) > 0.5 ? midOf(su, iv) : midOf(iu, sv)) * size;
        float L1 = length(K - S);
        float L2 = length(H - K);
        vec2 dir = L2 > 0.5 ? (H - K) / L2 : (L1 > 0.5 ? (K - S) / L1 : vec2(0.0, 1.0));
        vec2 side = vec2(-dir.y, dir.x);
        float edge = 0.5 * length(c * size);
        vec2 hit = H + dir * 0.5 * edge;
        float ti = t - base - p.w;
        if (j < 0.5) {
            if (ti < 0.0 || ti > 150.0) {
                cull();
                return;
            }
            float kp = ti / 150.0;
            vec3 col = ink > 0.5 ? sepia : mix(hot, dust, 0.5);
            emit(hit + dir * (2.0 + 6.0 * (1.0 - exp(-ti / 28.0))), side, edge * 0.35 * (0.7 + 0.3 * kp), 1.5 + 4.0 * kp, col, 0.55 * sq(1.0 - kp), q);
            return;
        }
        float life = 110.0 + 50.0 * g.z;
        if (ti < 0.0 || ti > life) {
            cull();
            return;
        }
        vec2 v0 = side * (j < 1.5 ? 1.0 : -1.0) * (0.2 + 0.25 * g.y) - dir * (0.05 + 0.1 * g.z);
        fly(hit + side * (g.x - 0.5) * edge * 0.6, v0, ti, life, 1.3 + 0.8 * g.w, ink > 0.5 ? leaf : hot, g.w, q);
        return;
    }

    float nj = nu + 1.0;
    float s4 = floor(s / 4.0);
    float j = s - 4.0 * s4;
    vec2 a = vec2(mod(s4, nj), floor(s4 / nj) - grid.y);
    vec2 J = junction(a);
    vec2 B = junction(a + (mod(j, 2.0) < 0.5 ? vec2(1.0, 0.0) : vec2(0.0, 1.0)));
    vec4 g = hash4(vec2(a.x * 1.37 + j, a.y * 2.11 - j));
    float tw = seal.x + seal.y * unit(length(J - C) / (0.5 * length(size)));
    float tb = seal.x + seal.y * unit(length(B - C) / (0.5 * length(size)));
    if (tb < tw) {
        vec2 x = J;
        J = B;
        B = x;
        tw = tb;
    }
    vec2 seg = B - J;
    vec2 O;
    float tau;
    float life;
    if (j < 1.5) {
        float run = 0.1 + 0.6 * g.x;
        O = J + seg * (1.0 - sq(1.0 - run));
        tau = t - tw - seal.z * run;
        life = 140.0 + 60.0 * g.w;
    } else {
        O = J + seg * g.y;
        tau = t - tw - seal.z * (0.3 + 0.9 * g.x);
        life = 380.0 + 240.0 * g.z;
    }
    vec2 on = (O - box.xy) / size;
    if (tau < 0.0 || tau > life || on.x < 0.0 || on.y < 0.0 || on.x > 1.0 || on.y > 1.0) {
        cull();
        return;
    }
    if (j < 1.5) {
        vec2 u = normalize(seg);
        fly(O, vec2(-u.y, u.x) * (g.y > 0.5 ? 1.0 : -1.0) * (0.15 + 0.3 * g.z) + u * 0.08, tau, life, 1.2 + 0.8 * g.w, ink > 0.5 ? leaf : mix(hot, vec3(1.0), 0.5), g.z, q);
        return;
    }
    vec2 rise = vec2((g.w - 0.5) * 0.1, -0.03 - 0.05 * fract(g.x * 7.3));
    vec3 col = ink > 0.5 ? mix(sepia, leaf, 0.6) : mix(dust, hot, 0.5) * 1.3;
    float r = 2.2 + 1.2 * g.w;
    emit(O + rise * tau + vec2(0.0, 0.0003 * tau * tau), vec2(1.0, 0.0), r, r, col, pow(1.0 - tau / life, 1.5) * (0.4 + 0.8 * fract(g.y * 5.1)) * smoothstep(0.0, 30.0, tau), q);
}
