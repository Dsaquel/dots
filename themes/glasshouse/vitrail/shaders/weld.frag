#version 300 es
precision highp float;

in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;

uniform highp sampler2D perm;
uniform vec4 drawn;
uniform vec4 win;
uniform vec2 grid;
uniform float radius;
uniform float scale;
uniform float t;
uniform float base;
uniform vec4 seal;
uniform vec3 hot;
uniform vec3 keyline;
uniform vec3 jewel0;
uniform vec3 jewel1;
uniform vec3 leadLow;
uniform vec3 leadBase;
uniform vec3 leadHi;
uniform vec3 sepia;
uniform vec3 leaf;
uniform float ink;
uniform float turn;
uniform vec4 frame;
uniform vec4 hull;
uniform vec4 hand;
uniform vec4 hubs;
uniform vec3 ring;
uniform vec4 gates[4];
uniform float gated;
uniform float bolt;
uniform float seed;
uniform float lanes;
uniform sampler2D under;
uniform vec2 underSize;
uniform float knee;

const float PI = 3.14159265;
const float CAME = 1.7;
const float ARCED = 40.0;
const float RIMMED = 130.0;
const float FLICK = 16.0;
const float JIT = 10.0;
const float ZAG = 7.0;
const float AMP = 3.5;
const float STRIKE = 0.55;
const float CHARGED = 0.9;
const float DARKS = 0.45;
const float LINK = 64.0;
const float REACH = 26.0;

vec3 L = vec3(0.0);
float E = 0.0;
float came = 0.0;
float mold = 0.5;
float core = 0.0;
float halo = 0.0;

#include "lib/math.glsl"

float outBack(float k) {
    k = clamp(k, 0.0, 1.0) - 1.0;
    return 1.0 + 2.70158 * k * k * k + 1.70158 * k * k;
}

#include "lib/finish.glsl"

#include "lib/lead.glsl"

#include "lib/turn.glsl"

vec2 source(vec2 p) {
    vec2 n = normOf(p, hubs.zw);
    return denorm(hand.w * vec2(n.y, -n.x), hubs.xy);
}

#include "lib/front.glsl"

vec2 junction(vec2 j) {
    vec2 m = frame.xy + vec2((j.x + j.y) / (2.0 * grid.x), (j.x - j.y) / (2.0 * grid.y)) * frame.zw;
    return turn > 0.5 ? landed(m) : m;
}

float ignite(vec2 j) {
    if (gated > 0.5)
        return frontOf(junction(j));
    if (turn > 0.5)
        return ring.y + ring.z * (1.0 - pow(1.0 - clamp(length(junction(j) - hand.xy) / ring.x, 0.0, 1.0), 1.0 / 3.0));
    return seal.x + seal.y * clamp(length(junction(j) - win.xy - 0.5 * win.zw) / (0.5 * length(win.zw)), 0.0, 1.0);
}

#include "lib/hash.glsl"

#include "weld/path.glsl"

#include "weld/arc.glsl"

#include "weld/thunder.glsl"

#include "weld/seam.glsl"

void main() {
    vec2 p = drawn.xy + v_texcoord * drawn.zw;
    float lit = gated > 0.5 ? frontOf(p) : ring.y + ring.z * (1.0 - pow(1.0 - clamp(length(p - hand.xy) / ring.x, 0.0, 1.0), 1.0 / 3.0));
    if (bolt > 0.5) {
        fragColor = thunder(p, lit);
        return;
    }
    float inside = clamp(0.5 - sdRoundBox(p - win.xy - 0.5 * win.zw, 0.5 * win.zw, radius), 0.0, 1.0);
    float gone = (1.0 - smoothstep(seal.x + seal.y + seal.z, seal.x + seal.y + seal.w, t)) * (turn > 0.5 || gated > 0.5 ? 1.0 - smoothstep(lit + 30.0, lit + 90.0, t) : 1.0);
    if (inside <= 0.0 || gone <= 0.0) {
        fragColor = vec4(0.0);
        return;
    }
    vec2 n = ((turn > 0.5 ? source(p) : p) - frame.xy) / frame.zw;
    if (turn > 0.5 && (n.x < 0.0 || n.y < 0.0 || n.x > 1.0 || n.y > 1.0)) {
        fragColor = vec4(0.0);
        return;
    }
    vec2 g = vec2(n.x * grid.x + n.y * grid.y, n.x * grid.x - n.y * grid.y);
    vec2 f = floor(g);
    vec2 r = floor(g + 0.5);
    seam(vec2(r.x, f.y), vec2(r.x, f.y + 1.0), vec2(r.x - 1.0, f.y), vec2(r.x, f.y), p);
    seam(vec2(f.x, r.y), vec2(f.x + 1.0, r.y), vec2(f.x, r.y - 1.0), vec2(f.x, r.y), p);

    vec2 J = junction(r);
    float d = length(p - J);
    float age = t - ignite(r);
    float pearl = 0.0;
    if (age > 0.0) {
        float tp = clamp((age - 0.3 * seal.z) / 90.0, 0.0, 1.0);
        float cool = clamp((age - seal.z) / (seal.w - seal.z), 0.0, 1.0);
        float pr = (CAME + 1.2) * scale * outBack(tp);
        pearl = clamp(pr - d + 0.5, 0.0, 1.0);
        add(mix(hot, vec3(1.0), 0.7), exp(-sq(d / (3.0 * scale))) * exp(-age / 45.0) * 1.5);
        add(mix(hot, vec3(1.0), 0.5), pearl * sq(1.0 - cool) * 1.1);
        add(mix(hot, jewel0, 0.3), exp(-sq((d - (2.0 + 3.0 * tp) * scale) / (0.9 * scale))) * tp * sq(1.0 - cool) * 0.9);
    }
    float bead = sqrt(max(1.0 - sq(d / max((CAME + 1.2) * scale, 1e-3)), 0.0));
    vec3 lc = mix(molding(mold), molding(0.5) * (0.8 + 0.5 * bead), pearl);
    vec4 lead = vec4(lc, 1.0) * max(came, pearl);
    vec4 glow = finish(inside * gone * (turn > 0.5 || gated > 0.5 ? 0.45 : 1.0));
    fragColor = glow + lead * inside * gone * (1.0 - glow.a);
}
