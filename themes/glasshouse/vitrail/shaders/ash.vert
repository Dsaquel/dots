#version 300 es
precision highp float;

uniform mat3 proj;
uniform vec2 target;
uniform sampler2D tex;
uniform vec2 texSize;
uniform vec4 shot;
uniform float t;
uniform vec4 burn;
uniform float burnSeed;
uniform float scale;
uniform vec4 lens;
uniform vec4 view;
uniform float forward;
uniform float alone;
uniform float bridge;
uniform vec4 seam;
uniform vec2 away;
uniform vec2 fired;
uniform float spurred;
uniform float nave;
uniform vec4 frame;
uniform vec4 times;
uniform vec4 slot;
uniform vec2 entry;
uniform vec2 came;
uniform vec4 turn;
uniform vec3 wake[24];
uniform vec2 heading;
uniform vec2 poses[48];
uniform float stride;
uniform float seed;
uniform float haste;
uniform vec3 hot;
uniform vec3 gold;
uniform vec3 leaf;
uniform vec3 sepia;
uniform vec3 jewel0;
uniform vec3 jewel1;
uniform vec3 jewel2;
uniform float ink;

out vec4 v_col;
out float v_star;

const float PI = 3.14159265;
const float TAU = 6.2831853;
const float TRAIL = 3.0;
const float STEP = 6.0;
const int POSES = 48;
const int WAKE = 24;
const float LAG = 300.0;
const float DRAIN = 90.0;
const float STRUNG = 180.0;
const float SPUR = 40.0;
const float GATHER = 170.0;
const float WIDTH = 52.0;
const float DRIFT = 0.35;
const float WAVE = 0.55;
const float SPIN = 0.004;
const float SWIRL = 0.5;
const float SPREAD = 130.0;
const float VEINS = 18.0;
const float FAN = 2.6;
const float RISEN = 60.0;
const float BORN = 20.0;
const float SLING = 60.0;
const float SMALL = 0.12;
const float FLY = 60.0;
const float PACKED = 80.0;
const float PACK = 0.6;

#include "lib/math.glsl"

#include "ash/burn.glsl"

#include "lib/hash.glsl"

#include "ash/lens.glsl"

#include "ash/route.glsl"

#include "ash/spine.glsl"

#include "lib/vein.glsl"

#include "ash/entry.glsl"

void main() {
    float id = float(gl_VertexID);
    float m = mod(id, TRAIL);
    float i = floor(id / TRAIL);
    vec2 g = vec2(mod(i, 64.0), floor(i / 64.0));
    vec4 h = hash4(g);
    vec4 k = hash4(g + 71.3);
    vec4 n = hash4(g + 29.7);
    vec4 o = hash4(g + 13.7);
    vec4 l = hash4(g + 47.9);
    vec2 s = shot.xy + (0.01 + 0.98 * h.xy) * shot.zw;
    vec4 c = textureLod(tex, (s - away) / texSize, 0.0);
    float tr = release(s) - 12.0;
    float tt = t - m * STEP * haste;
    if (c.a < 0.05 || tt < tr) {
        hide();
        return;
    }
    vec3 own = c.rgb / max(c.a, 1e-3);
    vec3 ember = ink > 0.5 ? mix(leaf, sepia, 0.35 + 0.45 * h.z) : mix(gold, hot, 0.1 + 0.45 * h.z * h.z);
    vec3 flare = ink > 0.5 ? leaf : hot;
    bool star = h.w > 0.965;
    bool loose = !star && l.x > 0.9;
    bool mist = !star && !loose && l.z > 0.93;
    bool shed = l.y > 0.88;
    float tw = 0.65 + 0.35 * sin(tt * (0.018 + 0.02 * k.x) + h.y * TAU);
    float trail = m > 0.5 ? 0.5 * pow(1.0 - m / TRAIL, 1.5) : 1.0;

    float age = tt - tr;
    float u0 = pow(span(tr, burn.z - 30.0, burn.w + 10.0), 1.25);
    float now = max(pow(span(tt, burn.z - 30.0, burn.w + 10.0), 1.25), 0.05);
    float u = u0 / now + DRIFT * (k.x - 0.5) * span(age, 0.0, 600.0) * min(1.0, 4.0 * min(u0, 1.0 - u0)) + (shed ? 0.45 * span(age, 120.0, 600.0) : 0.0);
    float grow = turn.y + (STRUNG - turn.y) * soft(span(tt, turn.x, turn.x + 160.0));
    float lag = turn.w > 0.5 ? grow + (DRAIN - grow) * soft(span(tt, times.y - 160.0, times.y - 40.0)) : LAG + (DRAIN - LAG) * soft(span(tt, times.x + 60.0, times.y - 60.0));
    float pack = soft(span(tt, times.y - PACKED, times.y));
    lag *= 1.0 - PACK * pack;
    float tau = tt - min(u, 1.0) * lag;
    float x = tau - times.y;
    float uu = min(u, 1.0);
    float root = unit((BORN - tau) / max(BORN - (tt - lag), 1.0));
    vec3 P0 = spineAt(tau, lag, tt);
    vec3 P1 = spineAt(tau + 5.0, lag, tt);
    vec3 c0 = project(P0, view.x);
    vec2 d2 = project(P1, view.x).xy - c0.xy;
    vec2 tn = length(d2) > 1e-3 ? normalize(d2) : vec2(0.0, -1.0);
    vec2 nn = vec2(-tn.y, tn.x);
    vec3 T = P1 - P0;
    float fore = length(T) > 1e-3 ? abs(dot(normalize(T), normalize(P0 - vec3(lens.xy, view.x - lens.z)))) : 1.0;
    float kk = lens.z / c0.z;
    float girth = (0.2 + 0.8 * soft(uu / 0.12)) * (1.0 - 0.4 * soft((uu - 0.55) / 0.45)) * (1.0 + 1.8 * root * root);
    float wide = WIDTH * scale * kk * girth * (1.0 - 0.45 * pack);
    float R = wide * (loose ? 1.0 + 1.2 * n.x : mist ? 0.5 * n.x : l.z < 0.65 ? 0.38 * min(sqrt(-2.0 * log(1.0 - 0.995 * n.x)), 2.5) : sqrt(n.x));
    float a = TAU * n.y + tt * SPIN * (n.z - 0.5) * 2.0 + 4.0 * uu;
    vec2 body = c0.xy + R * (cos(a) * nn + sin(a) * fore * tn);
    body += nn * sin(TAU * (1.1 * uu - tt / 400.0) + seed) * WAVE * wide * soft(uu / 0.15) * (1.0 - root);
    body += (nn * (vnoise(vec2(uu * 6.0 - tt * 0.004, 3.1)) - 0.5) * 0.7 + tn * (vnoise(vec2(uu * 5.0 - tt * 0.003, 8.7)) - 0.5) * 0.4) * wide;
    body += vec2(sin(tt * (0.006 + 0.004 * k.z) + k.w * TAU), cos(tt * (0.005 + 0.004 * k.y) + k.z * TAU)) * (loose ? 7.0 : 2.5) * scale * kk;

    vec2 drawn = s + vec2((rootAt(tr).x - s.x) * (1.0 - exp(-age / 70.0)) * (0.85 + 0.15 * k.z), 0.0);
    vec3 born = sourceAt(drawn, tr);
    float lift = (30.0 + 70.0 * h.w) * (1.0 - exp(-age / 170.0)) + 0.0009 * age * age;
    vec3 up = born + vec3(sin(age * (0.008 + 0.006 * k.y) + k.w * TAU) * (4.0 + 8.0 * k.z), -lift, 0.0) * scale;
    vec2 free = project(up, view.x).xy;
    float w = max(soft(age / (GATHER * (0.8 + 0.4 * o.z) * (1.0 - 0.35 * span(tr, 100.0, 300.0)))), soft((tt - max(spurred, tr)) / SPUR));
    vec2 pull = body - free;
    vec2 pos = mix(free, body, w) + vec2(-pull.y, pull.x) * sin(PI * w) * (0.08 + 0.1 * k.y) * (k.z > 0.5 ? 1.0 : -1.0);
    float fade = veiled(pos, c0.z) * smoothstep(0.35 * lens.z, 0.7 * lens.z, c0.z) * (1.0 - span(u, 0.95, 1.4));

    float soak = 0.0;
    float dip = 0.0;
    float molten = 0.0;
    float fed = 0.0;
    vec3 jewel = o.x < 0.34 ? jewel0 : o.x < 0.67 ? jewel1 : jewel2;
    if (x > 0.0 && !shed) {
        vec2 far = max(abs(slot.xy - entry), abs(slot.xy + slot.zw - entry));
        float reach = max(length(far), 1.0);
        float xb = tt - times.y;
        float base = fanBase();
        bool vein = l.w < 0.8;
        float j = floor(o.y * VEINS);
        vec2 at;
        if (alone > 0.5) {
            float lit = o.y * SLING;
            float k = span(tt, times.z + lit - FLY, times.z + lit);
            vec2 core = entry + vec2(n.x - 0.5, n.w - 0.5) * (10.0 + 30.0 * (1.0 - k)) * scale;
            at = mix(core, fuseAt(o.y), k * k * (3.0 - 2.0 * k));
            soak = span(tt, times.z + lit, times.z + lit + 25.0);
            fed = 1.0;
        } else {
            float th = vein ? veinAngle(j, base) : base + (o.y - 0.5) * 2.0 * FAN;
            float lead = 0.35 + 0.65 * n.w;
            float full = vein ? veinReach(j, base, slot) : roomOf(th, slot) * (0.3 + 0.4 * n.w);
            float stop = full * (vein ? 0.3 + 0.7 * sqrt(o.z) : 0.15 + 0.85 * sqrt(o.z));
            float r = min(full * grown(xb) * lead, stop) * (1.0 - sq(1.0 - unit(x / 30.0)));
            float settle = SPREAD * (1.0 - pow(1.0 - unit(stop / (full * lead)), 1.0 / 2.4));
            if (!vein)
                r = stop * (1.0 - exp(-x / 45.0));
            float ang = vein ? veinBend(j, base, r, reach, full, step(0.6, o.w)) + (n.x - 0.5) * 0.5 * (4.0 + 0.02 * r) * scale / max(r, 30.0 * scale) : th + SWIRL * r / reach;
            at = entry + r * vec2(cos(ang), sin(ang));
            soak = vein ? max(span(xb, settle + 20.0, settle + 40.0 + 20.0 * l.w), span(xb, 90.0 + 40.0 * l.w, 160.0)) : span(xb, 60.0 + 60.0 * l.w, 140.0 + 80.0 * l.w);
            molten = 1.0;
        }
        vec2 cp = pose(tt);
        vec3 spot = project(targetAt(at, cp.y), view.x);
        vec2 enter = project(targetAt(entry, cp.y), view.x).xy;
        pos = spot.xy + (pos - enter) * (1.0 - span(x, 0.0, alone > 0.5 ? 40.0 : 70.0));
        dip = exp(-x / 60.0);
        fade = 0.7;
        kk = lens.z / spot.z;
    } else if (x > 0.0) {
        fade = 0.0;
    }

    float heat = exp(-age / 90.0);
    float nose = exp(-uu * 7.0);
    float flame = heat * (1.0 - w);
    vec3 coal = ink > 0.5 ? mix(sepia, leaf, 0.3) : mix(gold, gold * gold, 0.6);
    vec3 col = mix(mix(own, ember, ink > 0.5 ? 0.92 : 0.86 + 0.1 * w), flare, max(flame * 0.8, max(0.5 * nose, 0.6 * dip)));
    col = mix(col, coal, 0.75 * max(root, flame * (1.0 - h.z)));
    col = mix(col, ink > 0.5 ? mix(jewel, leaf, 0.5) : mix(jewel, gold, 0.35), 0.6 * soak);
    vec3 spear = ink > 0.5 ? mix(jewel1, vec3(1.0, 0.98, 0.92), 0.25 + 0.5 * h.z) : mix(hot, vec3(1.0), 0.35 + 0.5 * h.z);
    col = mix(col, spear, (ink > 0.5 ? 0.95 * sqrt(pack) : 0.8 * pack) * (1.0 - molten));
    col = mix(col, spear, molten);
    col = mix(col, mix(ember, flare, 0.25 + 0.5 * dip), fed);
    float alpha = (0.85 + 0.7 * flame + 0.5 * nose + 0.9 * root) * (1.0 - 0.35 * uu * (1.0 - root)) * tw * fade * trail * (1.0 - soak) * (loose ? 0.5 : 1.0) * (1.0 + 0.6 * pack * (1.0 - molten));
    float px = (star ? 11.0 : 2.8 + 6.5 * h.y * h.y * h.y) * scale * clamp(mix(1.0, kk, 0.7), 0.45, 1.8) * (1.0 - 0.5 * soak) * (1.0 + 0.9 * max(flame, root)) * (1.0 - 0.35 * fed);
    if (mist) {
        px = max(wide * (1.2 + 0.8 * root), 8.0 * scale) * (1.0 - 0.5 * soak) * (1.0 - 0.35 * pack);
        alpha *= (ink > 0.5 ? 0.1 : 0.13) * (1.0 + root);
    }
    gl_Position = vec4((proj * vec3((pos + frame.xy) / frame.zw, 1.0)).xy, 0.0, 1.0);
    gl_PointSize = min(px, 96.0 * scale);
    v_col = vec4(col, alpha * (ink > 0.5 ? 2.3 : 1.0));
    v_star = star ? 1.0 : mist ? 2.0 : 0.0;
}
