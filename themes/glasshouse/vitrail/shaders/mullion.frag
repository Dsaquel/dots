#version 300 es
precision highp float;

in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;

uniform sampler2D tex;
uniform vec2 texSize;
uniform vec4 drawn;
uniform float pass;
uniform float scale;
uniform float t;
uniform float seed;
uniform vec4 pane;
uniform float radius;
uniform vec4 ring;
uniform vec4 born;
uniform vec4 seam;
uniform vec4 front;
uniform vec4 reveal;
uniform float onset;
uniform vec2 cell;
uniform vec4 shock;
uniform vec4 lap;
uniform float boom;
uniform float heat;
uniform float fade;
uniform vec4 impact;
uniform vec4 impactAxis;
uniform vec3 hot;
uniform vec3 dust;
uniform vec3 jewel0;
uniform vec3 jewel1;
uniform vec3 jewel2;
uniform vec3 leadColor;
uniform vec3 sepia;
uniform vec3 leaf;
uniform float ink;

const float PI = 3.14159265;
const float CHARGE = 100.0;
const float FORM = 130.0;
const float SEAM = 90.0;
const float WELD = 280.0;
const float SHIMMER = 200.0;

vec3 L = vec3(0.0);
float E = 0.0;

#include "lib/math.glsl"

#include "lib/hash.glsl"

#include "lib/noise.glsl"

#include "mullion/perimeter.glsl"

vec3 jewelOf(float h) {
    return h < 0.34 ? jewel0 : (h < 0.67 ? jewel1 : jewel2);
}

#include "lib/finish.glsl"

#include "mullion/impact.glsl"

void main() {
    vec2 p = drawn.xy + v_texcoord * drawn.zw;
    if (pass > 3.5) {
        vec2 hw = pane.zw * 0.5;
        float sw = sdRoundBox(p - pane.xy - hw, hw, radius);
        float inWin = clamp(0.5 - sw, 0.0, 1.0);
        float d = length(p - shock.xy);
        add(mix(hot, jewel1, 0.35), exp(-sq((d - shock.z) / (9.0 * scale))) * shock.w * 0.38 * inWin);
        add(hot, exp(-sq((d - shock.z + 3.0 * scale) / (1.6 * scale))) * shock.w * 0.5 * inWin);
        add(mix(hot, vec3(1.0), 0.6), exp(-sq((sw - 4.6 * scale) / (2.0 * scale))) * exp(-sq((d - shock.z) / (14.0 * scale))) * shock.w * 1.3);
        fragColor = finish(1.0);
        return;
    }
    if (pass > 2.5) {
        vec2 hb = born.zw * 0.5;
        float inside = clamp(0.5 - sdRoundBox(p - born.xy - hb, hb, radius), 0.0, 1.0);
        vec4 c = texture(tex, p / texSize);
        vec2 dq = p - born.xy;
        vec2 gi = floor(vec2(dq.x / cell.x + dq.y / cell.y, dq.x / cell.x - dq.y / cell.y));
        float a = inside * step(0.004, c.a) * step(1.0 - fade, hash(gi + 7.7) * 0.98 + 0.01);
        fragColor = vec4((c.a > 0.004 ? c.rgb / c.a : vec3(0.0)) * a, a);
        return;
    }
    if (pass > 1.5) {
        impactMain(p);
        return;
    }
    vec2 hs = pane.zw * 0.5;
    vec2 q = p - pane.xy - hs;
    float sd = sdRoundBox(q, hs, radius);
    float inPane = clamp(0.5 - sd, 0.0, 1.0);
    bool upright = seam.x > 0.5;

    float inBorn = 0.0;
    float k = 1e3;
    vec2 bq = p - born.xy;
    vec2 lat = vec2(bq.x / cell.x + bq.y / cell.y, bq.x / cell.x - bq.y / cell.y);
    vec2 gi = floor(lat);
    vec2 gf = lat - gi;
    vec2 cc = gi + 0.5;
    vec2 cen = born.xy + vec2((cc.x + cc.y) * 0.5 * cell.x, (cc.x - cc.y) * 0.5 * cell.y);
    float edgePx = min(min(gf.x, 1.0 - gf.x), min(gf.y, 1.0 - gf.y)) * min(cell.x, cell.y) * 0.7071;
    float h = hash(gi);
    float dist = ((upright ? cen.x : cen.y) - front.x) * front.y;
    vec3 jewel = jewelOf(fract(h * 7.31 + gi.x * 0.37));
    if (bq.x >= 0.0 && bq.y >= 0.0 && bq.x <= born.z && bq.y <= born.w) {
        inBorn = 1.0;
        float y = clamp(dist / max(front.z, 1.0), 0.0, 1.0);
        float tq = reveal.x + (reveal.y - reveal.x) * (1.0 - sqrt(1.0 - y)) + (h - 0.5) * reveal.w;
        k = (t - tq) / reveal.z;
    }

    if (pass < 0.5) {
        vec3 m = vec3(1.0);
        if (inBorn > 0.5 && k > 0.0) {
            float amount = 1.0 - smoothstep(0.12, 0.9, k);
            m = mix(vec3(1.0), clamp(jewel * 1.5 + 0.2, 0.0, 1.0), 0.55 * amount);
            float lead = (1.0 - smoothstep(0.3 * scale, 1.4 * scale, edgePx)) * amount;
            m *= mix(vec3(1.0), (ink > 0.5 ? sepia : leadColor) * 0.8, lead * 0.85);
        }
        fragColor = vec4(m, 1.0);
        return;
    }

    float gone = 0.0;
    vec2 ps = p;
    float pd = ((upright ? p.x : p.y) - front.x) * front.y;
    float lead = front.w;
    float inOld = (1.0 - inBorn) * step(pd, 0.0) * step(0.5, lead);
    float fpOld = lead * clamp((t - onset) / (reveal.x - onset), 0.0, 1.0) - lead;
    float liveOld = smoothstep(onset, onset + 30.0, t) * (1.0 - smoothstep(reveal.x - 30.0, reveal.x + 10.0, t)) * inOld;
    float kOld = -1.0;
    if (inOld > 0.5 && dist + lead >= 0.0) {
        float tq = onset + (reveal.x - onset) * min((dist + lead) / lead, 1.0) + (h - 0.5) * reveal.w;
        kOld = (t - max(tq, onset)) / SHIMMER;
        ps -= (upright ? vec2(front.y, 0.0) : vec2(0.0, front.y)) * exp(-sq((pd - fpOld) / (22.0 * scale))) * liveOld * 6.0 * scale;
    }
    if (shock.w >= 0.0) {
        float d = length(p - shock.xy);
        gone = 1.0 - smoothstep(shock.z - 10.0 * scale, shock.z, d);
        float band = exp(-sq((d - shock.z) / (9.0 * scale))) * shock.w;
        ps -= (p - shock.xy) / max(d, 1.0) * band * 7.0 * scale;
        add(mix(hot, jewel1, 0.35), band * 0.38 * inPane);
        add(hot, exp(-sq((d - shock.z + 3.0 * scale) / (1.6 * scale))) * shock.w * 0.5 * inPane * (1.0 + heat));
    }
    float shown = inPane * (1.0 - gone);
    if (inBorn > 0.5)
        shown *= 1.0 - smoothstep(0.0, 0.14, k);
    vec4 c = texture(tex, ps / texSize);
    vec3 still = c.a > 0.004 ? c.rgb / c.a : vec3(0.0);
    if (kOld > 0.0) {
        float amount = 1.0 - smoothstep(0.12, 0.9, kOld);
        still *= mix(vec3(1.0), clamp(jewel * 1.5 + 0.2, 0.0, 1.0), 0.45 * amount);
        still *= mix(vec3(1.0), (ink > 0.5 ? sepia : leadColor) * 0.8, (1.0 - smoothstep(0.3 * scale, 1.4 * scale, edgePx)) * amount * 0.85);
        if (kOld < 1.0) {
            float flash = exp(-sq((kOld - 0.1) / 0.08));
            add(hot, flash * ((1.0 - smoothstep(0.0, 2.6 * scale, edgePx)) * 0.9 + 0.12) * inPane);
            add(jewel, flash * 0.25 * inPane);
        }
    }
    add(hot, exp(-sq((pd - fpOld) / (4.0 * scale))) * 0.7 * liveOld * inPane);
    add(jewel, exp(-max(fpOld - pd, 0.0) / (30.0 * scale)) * step(pd, fpOld) * 0.12 * liveOld * inPane);
    float a = shown * step(0.004, c.a);
    vec4 col = vec4(still * a, a);

    if (inBorn > 0.5) {
        if (k > 0.0 && k < 1.0) {
            float flash = exp(-sq((k - 0.1) / 0.08));
            float rim = 1.0 - smoothstep(0.0, 2.6 * scale, edgePx);
            add(hot, flash * (rim * 0.9 + 0.12));
            add(jewel, flash * 0.25);
        }
        float u = clamp((t - reveal.x) / (reveal.y - reveal.x), 0.0, 1.0);
        float fp = front.z * (1.0 - sq(1.0 - u));
        float live = step(reveal.x, t) * (1.0 - smoothstep(reveal.y - 40.0, reveal.y + 40.0, t));
        add(hot, exp(-sq((pd - fp) / (4.0 * scale))) * 0.7 * live);
        add(jewel, exp(-max(fp - pd, 0.0) / (30.0 * scale)) * step(pd, fp) * 0.12 * live);
    }

    if (lap.x > 0.001 && inPane > 0.0) {
        float u = perimU(q, ring.xy, ring.z);
        float dd = circ(u, lap.z, lap.w);
        float heat = dd <= lap.y ? exp(-(lap.y - dd) / (260.0 * scale)) : exp(-sq((dd - lap.y) / (30.0 * scale)));
        float edge = exp(-max(-sd, 0.0) / (80.0 * scale));
        vec2 cp = p / (42.0 * scale);
        float n1 = vnoise(cp + vec2(t * 0.0012, -t * 0.0008));
        float n2 = vnoise(cp * 1.4 + vec2(-t * 0.0009, t * 0.0015) + 5.1);
        float caus = pow(1.0 - abs(n1 - n2), 6.0);
        vec3 j = jewelOf(hash(vec2(floor(u / (72.0 * scale)), 2.3)));
        add(j * 0.9 + hot * 0.2, caus * heat * edge * lap.x * 0.6);
        add(hot, heat * edge * lap.x * 0.06);
    }

    if (boom >= 0.0 && t >= boom - CHARGE) {
        float across = (upright ? p.x : p.y) - seam.y;
        float alongP = upright ? p.y : p.x;
        float inSeam = step(seam.z, alongP) * step(alongP, seam.w);
        float kb = (t - boom + CHARGE) / CHARGE;
        float blink = smoothstep(0.0, 0.06, kb) * (1.0 - smoothstep(0.22, 0.28, kb)) + smoothstep(0.5, 0.56, kb) * (1.0 - smoothstep(0.72, 0.78, kb));
        float lc = t < boom ? 0.7 * blink : exp(-(t - boom) / 160.0);
        float release = t < boom ? 0.0 : heat * exp(-(t - boom) / 45.0);
        add(mix(hot, vec3(1.0), 0.5), exp(-sq(across / (8.0 * scale))) * (lc + release) * 1.5 * inSeam);
        add(hot, exp(-abs(across) / (70.0 * scale)) * lc * 0.25 * inSeam);
        if (t > boom && abs(across) < 90.0 * scale) {
            float sp = 7.0 * scale;
            float base = floor((alongP - seam.z) / sp);
            for (int i = 0; i < 22; ++i) {
                float idx = upright ? base + 2.0 - float(i) : base + float(i) - 11.0;
                vec4 h = vec4(hash(vec2(idx, 3.1)), hash(vec2(idx, 5.9)), hash(vec2(idx, 8.3)), hash(vec2(idx, 9.7)));
                float ao = seam.z + (idx + hash(vec2(idx, 1.7))) * sp;
                if (ao < seam.z || ao > seam.w)
                    continue;
                float age = t - boom - h.x * 160.0;
                float life = 380.0 + 240.0 * h.y;
                if (age < 0.0 || age > life)
                    continue;
                vec2 o = upright ? vec2(seam.y + (h.z - 0.5) * 10.0 * scale, ao) : vec2(ao, seam.y);
                vec2 v = upright ? vec2((h.z - 0.5) * 0.2, -0.03 - 0.05 * h.w) : vec2((h.z - 0.5) * 0.09, -0.07 * h.w);
                vec2 at = o + (v * age + vec2(0.0, 0.0003 * age * age)) * scale;
                float m = exp(-dot(p - at, p - at) / sq(1.3 * scale)) * pow(1.0 - age / life, 1.5) * (0.4 + 0.8 * h.w);
                add(mix(dust * 1.2 + hot * 0.2, hot * 1.4, heat), m * (1.0 + heat));
            }
        }
    }

    vec4 g = finish(1.0);
    fragColor = g + col * (1.0 - g.a);
}
