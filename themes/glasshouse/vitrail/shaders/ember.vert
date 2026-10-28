#version 300 es
precision highp float;

uniform mat3 proj;
uniform vec2 target;
uniform float t;
uniform vec4 box;
uniform float radius;
uniform float came;
uniform float scale;
uniform float count;
uniform float seed;
uniform vec3 jewelA;
uniform vec3 jewelB;
uniform vec3 jewelC;
uniform vec3 hot;
uniform vec3 sepia;
uniform float ink;

out vec2 v_q;
flat out vec4 v_col;
flat out vec2 v_dim;
flat out vec4 v_glow;

const float PI = 3.14159265;
const float TAU = 6.2831853;
const float SEAT = 360.0;
const float SLING = 60.0;
const float SPIN = 110.0;
const float OPEN0 = 70.0;
const float OPEN1 = 220.0;
const float LOCK = 230.0;
const float SWALLOW = 295.0;
const float SQUARE = 280.0;
const float SMALL = 0.12;
const float WIDE = 0.38;
const float WREATH = 0.4;
const float TAIL = 0.16;
const float CARRY = 0.3;
const float DRAG = 160.0;
const float G = 0.0022;
const float END = 1200.0;
const float IRIS = 22.0;
const int HEAD = 0;
const int RING = 1;
const int FUR = 2;
const int GRIND = 3;
const int DUST = 4;
const int BURST = 5;
const int IGNITE = 6;

#include "lib/hash.glsl"

#include "lib/ring.glsl"

float morphAt(float k) {
    float u = clamp((k - SQUARE) / (SEAT - SQUARE), 0.0, 1.0);
    return u * u;
}

#include "lib/math.glsl"

float reachAt(vec2 dir, float k, vec2 hc, float lo) {
    vec2 a = abs(dir) + 1e-4;
    return mix(mouthAt(k, lo), min(hc.x / a.x, hc.y / a.y), morphAt(k));
}

float shapeAt(vec2 q, float k, vec2 hc, float rc, float lo) {
    return k >= SEAT ? sdRoundBox(q, hc, rc) : mix(length(q) - mouthAt(k, lo), sdRoundBox(q, hc, rc), morphAt(k));
}

vec2 flown(vec2 p0, vec2 v0, float age, float fall) {
    vec2 vt = vec2(0.0, G * scale * DRAG * fall);
    return p0 + vt * age + (v0 - vt) * DRAG * (1.0 - exp(-age / DRAG));
}

void cull() {
    gl_Position = vec4(2.0, 2.0, 2.0, 1.0);
    v_q = vec2(0.0);
    v_col = vec4(0.0);
    v_dim = vec2(1.0);
    v_glow = vec4(0.0);
}

void main() {
    int id = gl_VertexID / 6;
    int k = gl_VertexID - id * 6;
    vec2 corner = vec2(k == 1 || k == 2 || k == 4 ? 1.0 : -1.0, k == 2 || k == 4 || k == 5 ? 1.0 : -1.0);
    float fi = float(id);
    vec4 h = hash4(vec2(fi, 3.7));
    float r = fi / count;
    int kind = r < 0.38 ? HEAD : (r < 0.5 ? RING : (r < 0.56 ? FUR : (r < 0.68 ? GRIND : (r < 0.88 ? DUST : (r < 0.99 ? BURST : IGNITE)))));
    float tb = kind == HEAD ? mix(4.0, SEAT, h.y) : (kind == RING ? mix(SLING, SEAT, sqrt(h.y)) : (kind == FUR ? mix(10.0, SEAT, h.y) : (kind == GRIND ? mix(100.0, SEAT - 4.0, sqrt(h.y)) : (kind == DUST ? mix(LOCK, SEAT + 20.0, h.y) : (kind == BURST ? SEAT + 30.0 * h.y * h.y : 45.0 * h.y)))));
    float age = t - tb;
    if (age < 0.0) {
        cull();
        return;
    }
    vec4 g = hash4(vec2(fi, 9.1));
    float linger = kind == BURST || kind == DUST ? 1.0 + 1.6 * g.y * g.y : 1.0;
    float life = kind == HEAD ? 160.0 + 220.0 * g.x : (kind == RING ? 140.0 + 180.0 * g.x : (kind == FUR ? 40.0 + 70.0 * g.x : (kind == GRIND ? 60.0 + 110.0 * g.x : (kind == DUST ? 120.0 + 140.0 * g.x : (kind == BURST ? 90.0 + 130.0 * g.x : 30.0 + 40.0 * g.x))))) * linger;
    if (age > life) {
        cull();
        return;
    }
    vec4 j = hash4(vec2(fi, 5.3));
    vec2 hs = 0.5 * box.zw;
    vec2 c = box.xy + hs;
    vec2 hc = hs + vec2(came);
    float rc = radius + came;
    float lo = min(box.z, box.w);
    float H = lapsAt(tb);
    float lit = min(H, 1.0);
    float trail = -log(1.0 - 0.97 * h.z);
    float f = kind == HEAD ? H - min(TAIL * 0.6 * trail, lit) : (kind == BURST || kind == DUST ? h.z : (kind == IGNITE ? 0.0 : (j.w < 0.15 ? H - h.z * lit : H - min((kind == FUR ? 0.5 : 0.35) * trail, lit))));
    float phi = TAU * f;
    vec2 dir = vec2(-sin(phi), cos(phi));
    vec2 tang = vec2(-cos(phi), -sin(phi));
    float reach = reachAt(dir, tb, hc, lo);
    float R = ringAt(tb, lo);
    vec2 at = c + dir * reach;
    if (kind == DUST) {
        float band = R * WREATH;
        if (tb < SEAT && (reach < R || reach > R + band)) {
            cull();
            return;
        }
        at = c + dir * (tb < SEAT ? reach + 6.0 * j.w * scale : R + j.w * j.w * band);
    }
    float grow = (reachAt(dir, tb + 4.0, hc, lo) - reachAt(dir, tb - 4.0, hc, lo)) / 8.0;
    float a = kind == HEAD ? mix(0.05, 0.9, j.x * j.x) : (kind == BURST ? mix(0.25, 2.9, j.x) : (j.x < 0.8 ? mix(0.05, 1.0, j.x / 0.8) : mix(2.3, 3.0, (j.x - 0.8) / 0.2)));
    float speed = (kind == HEAD ? 0.4 + 2.6 * h.w * h.w : (kind == RING ? 0.15 + 1.2 * h.w * h.w : (kind == BURST ? 0.4 + 2.0 * h.w * h.w : (kind == FUR ? 0.3 + 0.7 * h.w : (kind == GRIND ? 0.6 + 2.2 * h.w * h.w : (kind == DUST ? 0.1 + 0.5 * h.w : 0.3 + 0.7 * h.w)))))) * scale;
    vec2 v0 = (tang * cos(a) + dir * sin(a)) * speed;
    bool shard_ = ink > 0.5 && kind == DUST;
    bool loose = shard_ && g.w < 0.25;
    if (kind == IGNITE) {
        float th = TAU * j.x;
        at = c;
        v0 = vec2(cos(th), sin(th)) * speed;
    } else if (kind == DUST)
        v0 = dir * ((loose ? 1.3 : 0.5) * grow + speed) + tang * (j.x - 0.5) * 0.8 * scale - vec2(0.0, 0.3 * j.y * scale);
    else if (kind == GRIND) {
        float m = morphAt(tb);
        vec2 half_ = hc * mix(mouthAt(tb, lo) / min(hc.x, hc.y), 1.0, m);
        float th = turnAt(tb) * (j.y < 0.5 ? 1.0 : -1.0);
        float om = PI / (0.7 * SEAT) * (1.0 - 0.6 * clamp(tb / SEAT, 0.0, 1.0)) * (j.y < 0.5 ? 1.0 : -1.0);
        vec2 local = vec2(j.z < 0.5 ? -1.0 : 1.0, fract(j.z * 2.0) < 0.5 ? -1.0 : 1.0) * (half_ - vec2(rc * half_.y / hc.y * 0.29));
        vec2 off = mat2(cos(th), sin(th), -sin(th), cos(th)) * local;
        at = c + off;
        if (at.x < 0.0 || at.y < 0.0 || at.x > target.x || at.y > target.y) {
            cull();
            return;
        }
        vec2 swing = om * vec2(-off.y, off.x);
        v0 = normalize(swing + 1e-4) * speed + normalize(off) * (j.x - 0.3) * 0.6 * scale;
    }
    if (kind == HEAD || kind == RING || kind == FUR)
        v0 += dir * grow * (kind == FUR ? 0.5 * CARRY : CARRY);
    float shutter = kind == FUR || kind == DUST ? mix(6.0, 16.0, j.y) : (kind == HEAD || kind == GRIND ? mix(10.0, 30.0, j.y * j.y) : mix(8.0, 22.0, j.y * j.y));
    float fall = loose ? 5.0 : 1.0;
    vec2 p1 = flown(at, v0, age, fall);
    vec2 pb = flown(at, v0, max(age - shutter, 0.0), fall);
    vec2 axis = p1 - pb;
    float w = (shard_ ? 2.4 + 2.6 * j.z * j.z : (kind == DUST ? 1.4 + 2.2 * j.z * j.z : 0.7 + 1.1 * j.z * j.z) * (ink > 0.5 ? 1.3 : 1.0)) * scale;
    float L = min(length(axis), shard_ ? 1.5 * w : 36.0 * scale);
    vec2 along = length(axis) > 1e-3 ? normalize(axis) : tang;
    pb = p1 - along * L;
    float half_ = 0.5 * L + w;
    float pad = scale + (shard_ ? 2.0 * w : 0.0);
    vec2 q = corner * vec2(half_ + pad, w + pad);
    vec2 mid = 0.5 * (pb + p1);
    gl_Position = vec4((proj * vec3((mid + along * q.x + vec2(-along.y, along.x) * q.y) / target, 1.0)).xy, 0.0, 1.0);
    v_q = q;
    v_dim = vec2(half_, w);
    float open_ = clamp((t - SLING) / IRIS, 0.0, 1.0);
    float veiled = smoothstep(-2.0 * scale, -8.0 * scale, min(shapeAt(pb - c, t, hc, rc, lo), shapeAt(p1 - c, t, hc, rc, lo))) * open_;
    float temp = exp(-age / ((70.0 + 150.0 * g.z) * linger)) * (kind == HEAD || kind == BURST || kind == GRIND ? 1.15 : 1.0);
    float fade = smoothstep(0.0, 6.0, age) * (1.0 - smoothstep(mix(0.6, 0.25, (linger - 1.0) / 1.6), 1.0, age / life)) * (1.0 - veiled) * (1.0 - smoothstep(END - 300.0, END, t));
    vec3 shard = j.y < 0.33 ? jewelA : (j.y < 0.66 ? jewelB : jewelC);
    float warm = clamp(temp, 0.0, 1.0);
    v_glow = shard_ ? vec4(mix(vec3(0.6, 0.1, 0.03), vec3(0.95, 0.34, 0.05), warm), max(warm, 1e-3)) : vec4(0.0);
    if (ink > 0.5)
        v_col = shard_ ? vec4(shard * 0.82, fade) :
                         vec4(mix(mix(sepia, vec3(0.74, 0.14, 0.02), clamp(temp * 3.0, 0.0, 1.0)), vec3(0.98, 0.5, 0.06), clamp(temp * 1.2 - 0.3, 0.0, 1.0)), fade * (0.75 + 0.25 * warm));
    else
        v_col = kind == DUST ? vec4(mix(shard * 1.4, fire(0.8), 0.35 * temp) * (0.7 + 0.8 * temp), fade) : vec4(fire(0.1 + (kind == GRIND ? 0.6 : 0.8) * min(temp, 1.0)) * (0.7 + 1.6 * temp) * (0.7 + 0.7 * j.w), fade);
}
