#version 300 es
precision highp float;

in vec2 v_uv;
in vec2 v_n;
in vec2 v_lat;
flat in vec4 v_shard;
flat in vec4 v_glow;
flat in vec3 v_size;
flat in float v_edge;
in vec2 v_new;
in float v_front;
flat in vec2 v_mix;
flat in vec4 v_lift;
in vec2 v_out;
in vec2 v_ray;
layout(location = 0) out vec4 fragColor;

uniform sampler2D tex;
uniform vec2 texSize;
uniform sampler2D copy;
uniform vec2 copySize;
uniform float mixing;
uniform vec4 shot;
uniform float radius;
uniform float ghost;
uniform vec3 leadBase;
uniform vec3 leadHi;
uniform vec3 leadLow;
uniform vec3 keyline;
uniform vec3 hot;
uniform vec3 jewel0;
uniform vec3 jewel1;
uniform vec3 jewel2;
uniform vec3 sepia;
uniform float ink;
uniform float mode;
uniform float ready;
uniform vec3 stream;
uniform float t;
uniform float ahead;
uniform float rift;
uniform float layer;

const float PI = 3.14159265;
const float CAME = 1.7;
const float FRONT = 0.3;
const float UMBRA = 0.8;
const vec3 SUN = vec3(-0.45, -0.6, 0.66);

#include "lib/math.glsl"

#include "lib/lead.glsl"

vec3 jewelOf(float h) {
    return h < 0.34 ? jewel0 : (h < 0.67 ? jewel1 : jewel2);
}

void main() {
    vec2 size = v_size.xy;
    float wd = -sdRoundBox((v_n - 0.5) * size, size * 0.5, radius);
    if (layer < -0.5) {
        float soft = v_lift.w;
        float rim = min(min(min(v_lat.x, 1.0 - v_lat.x), min(v_lat.y, 1.0 - v_lat.y)) * v_shard.y, wd);
        float a = UMBRA * smoothstep(-soft, soft, rim) * smoothstep(0.0, 0.2, v_lift.x) * (1.0 - 0.2 * v_lift.x) * v_size.z;
        fragColor = ink > 0.5 ? vec4(sepia * 0.3 * a, 0.75 * a) : vec4(0.0, 0.0, 0.0, a);
        return;
    }
    float clip = clamp(0.5 + wd / max(fwidth(wd), 1e-3), 0.0, 1.0);
    if (clip <= 0.0)
        discard;
    if (mode > 2.5 && ghost < 0.99) {
        float rim = min(min(v_lat.x, 1.0 - v_lat.x), min(v_lat.y, 1.0 - v_lat.y)) * v_shard.y;
        float trail = exp(-max(rim, 0.0) / 6.0) * 0.5 + 0.3;
        vec3 heat = mix(keyline, hot, 0.5);
        fragColor = (ink > 0.5 ? vec4(heat * 0.7, 0.7) : vec4(heat, 0.0)) * trail * clip * v_size.z * ghost;
        return;
    }
    vec2 uv = v_edge > 0.5 ? clamp(v_uv, shot.xy + 0.5, shot.xy + shot.zw - 0.5) : v_uv;
    vec4 c = texture(tex, uv / texSize);
    float front = 1.0 + FRONT - v_mix.x * (2.0 + 2.0 * FRONT);
    float fresh = mixing * (mode > 2.5 ? ready * smoothstep(-1.5, 1.5, v_front) : smoothstep(front - FRONT, front + FRONT, v_front));
    if (fresh > 0.0)
        c = mix(c, texture(copy, v_new / copySize), fresh);
    vec3 jewel = mode > 2.5 ? stream * (0.8 + 0.4 * v_shard.x) : jewelOf(v_shard.x);
    vec3 straight = c.a > 0.004 ? c.rgb / c.a : vec3(0.0);
    float lum = dot(straight, vec3(0.299, 0.587, 0.114));
    float stain = v_glow.x;
    vec3 glass = ink > 0.5 ? jewel * (0.6 + 0.45 * lum) : jewel * (0.75 + 1.4 * lum) + straight * 0.3;
    vec3 stained = mix(straight, mode > 2.5 ? glass : jewel * (0.45 + 1.7 * lum) * 1.15 + straight * 0.2, 0.5 * stain);
    float glassA = max(c.a, 0.3 * stain);
    vec4 col = vec4(stained * c.a + jewel * 0.42 * (glassA - c.a), glassA);
    float ex = min(min(min(v_lat.x, 1.0 - v_lat.x), min(v_lat.y, 1.0 - v_lat.y)) * v_shard.y, wd);
    float fw = max(fwidth(ex), 1e-3);
    bool rifting = mode > 1.5 && ahead <= 0.0;
    float tr = ahead + rift * pow(clamp(wd / max(0.5 * min(size.x, size.y), 1.0), 0.0, 1.0), 0.8) + 52.0 * (0.7 * noiseOf(v_n * size / 70.0) + 0.3 * noiseOf(v_n * size / 19.0) - 0.5);
    float cracked = rifting ? smoothstep(tr, tr + 6.0, t) : 1.0;
    float tip = rifting ? exp(-sq((t - tr - 3.0) / 6.0)) : 0.0;
    float lead = (1.0 - smoothstep(CAME - fw, CAME + fw, ex)) * v_glow.y * cracked;
    col = mix(col, vec4(molding(0.5 + 0.5 * ex / CAME), 1.0), lead);
    col.rgb += keyline * exp(-sq((ex - CAME - 0.6) / 0.7)) * 0.4 * v_glow.y * cracked * col.a;
    float scar = 1.0 - smoothstep(CAME - fw, CAME + 1.5 + fw, ex);
    vec3 rent = ink > 0.5 ? mix(keyline, sepia, 0.3) : mix(hot, vec3(1.0), 0.55);
    col.rgb = ink > 0.5 ? mix(col.rgb, rent * col.a, clamp(tip * scar, 0.0, 1.0)) : col.rgb + rent * tip * (2.0 * scar + 0.35 * exp(-ex / 2.5)) * max(col.a, scar);
    col.rgb += mix(keyline, hot, 0.5) * (v_glow.z * 0.75 * exp(-ex / 2.2) + v_glow.w * 0.32 * exp(-ex / 3.0)) * max(col.a, lead);
    col.rgb += mix(keyline, vec3(1.0), 0.5) * v_glow.w * 0.05 * col.a;
    float sheen = exp(-sq((v_lat.x + v_lat.y - v_shard.z) / 0.22));
    col.rgb += mix(hot, vec3(1.0), 0.35) * v_shard.w * sheen * max(col.a, 0.4) * (ink > 0.5 ? 0.6 : 1.0);
    if (mode > 2.5) {
        float seam = exp(-sq(v_front / 2.2)) * v_mix.x;
        float halo = exp(-abs(v_front) / 30.0) * v_mix.y;
        vec3 fire = ink > 0.5 ? mix(keyline, sepia, 0.35) : mix(hot, vec3(1.0), 0.6);
        vec3 forge = ink > 0.5 ? keyline : mix(keyline, hot, 0.6);
        col.rgb = ink > 0.5 ? mix(col.rgb, fire * col.a, clamp(0.8 * seam + 0.3 * halo + 0.25 * v_mix.y, 0.0, 1.0))
                            : col.rgb + (fire * (1.8 * seam + 0.5 * halo) + forge * 0.55 * v_mix.y) * max(col.a, 0.5);
    } else
        col.rgb += mix(keyline, hot, 0.6) * mixing * v_mix.y * exp(-sq((v_front - front) / (0.3 * FRONT))) * max(col.a, 0.5) * (ink > 0.5 ? 0.3 : 0.45);
    if (v_lift.x > 0.0) {
        vec3 sun = normalize(SUN);
        vec3 normal = vec3(v_lift.yz, sqrt(max(1.0 - dot(v_lift.yz, v_lift.yz), 0.0)));
        float spec = pow(max(dot(normal, normalize(sun + normalize(vec3(-v_ray, 1.0)))), 0.0), 60.0);
        float bevel = exp(-max(ex, 0.0) / 2.2) * v_lift.x;
        float facing = dot(v_out / max(length(v_out), 1e-3), normalize(sun.xy));
        vec3 shine = mix(hot, vec3(1.0), ink > 0.5 ? 0.4 : 0.6);
        col.rgb *= 1.0 + 0.6 * (dot(normal, sun) - sun.z) - 0.5 * bevel * max(-facing, 0.0);
        col.rgb += shine * (0.6 * bevel * max(facing, 0.0) + 0.45 * spec * v_lift.x) * col.a;
    }
    fragColor = col * clip * v_size.z * ghost;
}
