#version 300 es
precision highp float;

uniform mat3 proj;
uniform vec2 target;
uniform vec3 screen;
uniform vec4 shot;
uniform vec4 box;
uniform vec2 grid;
uniform float t;
uniform float base;
uniform float mode;
uniform float layer;
uniform float trail;
uniform float crack;
uniform vec2 born;
uniform float reveal;
uniform float seed;
uniform vec4 hull;
uniform vec4 hand;
uniform vec4 hubs;
uniform vec3 swing;
uniform float ahead;
uniform float skew[9];
uniform vec4 flush;
uniform float ink;
uniform highp sampler2D perm;
uniform vec4 goal;
uniform vec4 gates[4];
uniform float gated;
uniform vec2 glide;
uniform vec3 ring;
uniform float parity;
uniform float rift;
uniform vec2 eye;

out vec2 v_uv;
out vec2 v_n;
out vec2 v_lat;
flat out vec4 v_shard;
flat out vec4 v_glow;
flat out vec3 v_size;
flat out float v_edge;
out vec2 v_new;
out float v_front;
flat out vec2 v_mix;
flat out vec4 v_lift;
out vec2 v_out;
out vec2 v_ray;

const float PI = 3.14159265;
const float HANG = 0.92;
const float TILT = 0.25;
const float BOW = 0.07;
const float EASE = 0.3;
const float SPAN = 0.70710678;
const float SHRINK = 0.06;
const float LOOSE = 0.5;
const float RECOIL = 0.012;
const float WIND = 0.05;
const float MOLTEN = 0.35;
const float GLOSS = 0.15;
const float PINCH = 0.8;
const float REFIRE = 60.0;
const float KICK = 4.0;
const float DRAW = 20.0;
const float BREATH = 0.06;
const float ARC = 16.0;
const float SMEAR = 0.06;
const float SHUT = 60.0;
const float RISE = 80.0;
const float EYE = 1100.0;
const float POP = 55.0;
const float SINK = 120.0;
const float UNSEAT = 0.3;
const float CLIMB = 40.0;
const float TIP = 0.42;
const float BLUR = 8.0;
const float SOFT = 0.8;
const vec2 CAST = vec2(12.0, 18.0);

#include "lib/math.glsl"

float outCubic(float k) {
    k = unit(k);
    return 1.0 - (1.0 - k) * (1.0 - k) * (1.0 - k);
}

float outBack(float k) {
    k = unit(k) - 1.0;
    return 1.0 + 2.70158 * k * k * k + 1.70158 * k * k;
}

#include "lib/turn.glsl"

#include "lib/hash.glsl"

#include "quarry/motion.glsl"

#include "quarry/cull.glsl"

#include "quarry/main.glsl"
