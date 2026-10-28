#version 300 es
precision highp float;

in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;

uniform sampler2D tex;
uniform vec2 texSize;
uniform vec4 drawn;
uniform vec4 foot;
uniform float radius;
uniform float came;
uniform float scale;
uniform float t;
uniform float seed;
uniform float pass;
uniform vec2 lamp;
uniform vec3 gold;
uniform vec3 hot;
uniform vec3 jewelA;
uniform vec3 jewelB;
uniform vec3 jewelC;
uniform vec3 leadLow;
uniform vec3 leadHi;
uniform vec3 sepia;
uniform vec3 leaf;
uniform float ink;

const float PI = 3.14159265;
const float TAU = 6.2831853;
const float SEAT = 360.0;
const float SLING = 60.0;
const float IRIS = 22.0;
const float SPIN = 110.0;
const float OPEN0 = 70.0;
const float OPEN1 = 220.0;
const float LOCK = 230.0;
const float SWALLOW = 295.0;
const float SQUARE = 280.0;
const float SMALL = 0.12;
const float WIDE = 0.38;
const float WREATH = 0.4;
const float PETALS = 28.0;
const float RUNE = 26.0;
const float DRIFT = 0.0012;
const float TAIL = 0.22;
const float FLASH = 40.0;
const float BAR = 3.8;
const float GEM = 8.0;
const float RING = 2.6;
const float RUNG = 160.0;
const float SWEEP = 14.0;
const float CLEARING = 110.0;
const float MELT = 30.0;
const float CHAR = 16.0;

#include "lib/math.glsl"

#include "lib/hash.glsl"

#include "lib/noise.glsl"

#include "portal/paint.glsl"

#include "lib/ring.glsl"

float morphAt(float k) {
    return sq(clamp((k - SQUARE) / (SEAT - SQUARE), 0.0, 1.0));
}

vec4 sampled(vec2 at) {
    vec2 uv = at / texSize;
    return uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0 ? vec4(0.0) : texture(tex, uv);
}

vec4 over(vec4 top, vec4 bottom) {
    return top + bottom * (1.0 - top.a);
}

#include "portal/rose.glsl"

#include "portal/main.glsl"
