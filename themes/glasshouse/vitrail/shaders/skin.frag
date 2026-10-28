#version 300 es
precision highp float;

in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;

uniform vec2 box;
uniform vec4 win;
uniform float radius;
uniform float offset;
uniform float hwOff;
uniform float hwOn;
uniform float pieceLen;
uniform vec4 lightPos;
uniform vec3 pool;
uniform vec3 base;
uniform vec3 hi;
uniform vec3 low;
uniform vec3 sky;
uniform vec3 jewelA;
uniform vec3 jewelB;
uniform vec3 jewelC;
uniform vec3 pearl;
uniform vec3 hot;
uniform float unlit;
uniform float specGain;
uniform float shininess;
uniform float on;
uniform vec4 laid;
uniform vec4 gap;
uniform vec4 athanor;
uniform vec4 seal;
uniform vec4 build;
uniform vec4 room;
uniform float seed;
uniform vec4 cut;
uniform vec4 melt;
uniform vec4 call;
uniform vec4 veil;
uniform vec4 shadow;
uniform vec2 shadowOffset;
uniform float shadowBlur;
uniform float alpha;
uniform float probe;
uniform vec4 hinge;
uniform vec4 grow;
uniform vec4 gone;
uniform vec2 vanish;
uniform float dark;

const float SM = 3.5;
const float PI = 3.14159265;
const float SPEND = 25.0;
const float POP = 90.0;
const float T0 = 230.0;
const float BREATH = 50.0;
const float PACE = 30.0;
const float RAMP = 70.0;
const float TURN = 3.0;
const float GATHER = 160.0;
const float SOWG = 70.0;
const float DIVE = 60.0;
const float WIND = 55.0;
const float CALLW = 200.0;
const float NEAR = 16.0;
const float OUTF = 170.0;
const float FROM = 150.0;
const float QUAD = 335.0;
const float INF = 120.0;
const float INQ = 260.0;
const float SHOCK = 1.4;
const float CLEAR = 0.72;
const float TRAIL = 40.0;
const float SEAM = 90.0;
const float WELD = 280.0;
const float JOLT = 150.0;
const float T0C = 70.0;
const float RUNC = 250.0;
const float DRIFT = 0.7;
const float AIRC = 44.0;
const float FLY = 100.0;
const float SETTLE = 25.0;
const float SURGE = 1.4;
const float SLAM = 380.0;
const float DCAM = 1400.0;
const float HOVER = 26.0;
const float POPZ = 0.8;
const float TUCK = 0.05;
const float WALLW = 12.0;
const float UPV = 12.0;
const float UPT = 90.0;
const float WAVEA = 0.32;
const float WAVEL = 420.0;
const float WAVEP = 210.0;
const float HEAD = 10.0;
const float HEADT = 60.0;
const float RAMPL = 160.0;
const float DROPD = 100.0;
const float LOCKD = 36.0;
const float RIPH = 8.0;
const float RIPV = 1.5;
const float RIPW = 20.0;
const float RIPD = 240.0;
const float WINDT = 250.0;
const float WINDUP = 0.8;
const float SLAMT = 36.0;
const float CLAPH = 12.0;
const float CLAPT = 55.0;
const float CRUMT = 120.0;
const float PULSEV = 20.0;
const float PULSEW = 44.0;
const float PULSET = 170.0;
const float KICK = 6.0;
const float REPOP = 60.0;
const float COOL = 170.0;
const float LIT = 0.85;
const float GLINT = 0.3;
const float HEAVE = 5.0;
const float HINGE = 0.14;
const float OPEN = 10.0;
const float EDGEW = 60.0;
const float SEAT = 360.0;
const float COOLING = 130.0;
const float LIFE = 600.0;

#include "lib/math.glsl"

float circ(float a, float b, float per) {
    float d = abs(a - b);
    return min(d, per - d);
}

#include "skin/brick.glsl"

#include "skin/metal.glsl"

#include "skin/bolt.glsl"

#include "skin/cloud.glsl"

float gM = -1.0;
float gT = 0.0;
float gL0 = 1.0;
float gLf = 1.0;
float gLG = 0.0;
float gXG = 1.0;
float gNow = 1.0;
float gLvG = 0.0;
float gN0 = 1.0;
float gS0 = 72.0;
float gNG = 1.0;
float gSG = 72.0;
vec2 gDir = vec2(0.0);
vec2 gV = vec2(0.0);
vec2 gL = vec2(0.0);
vec2 gCG = vec2(0.0);
vec2 gHG = vec2(0.0);
vec2 gHS = vec2(0.0);

#include "skin/edge.glsl"

#include "skin/wave.glsl"

#include "skin/look.glsl"

#include "skin/merged.glsl"

#include "skin/gp.glsl"

#include "skin/floating.glsl"

#include "skin/seam.glsl"

vec3 fire(float h) {
    vec3 c = mix(vec3(0.38, 0.05, 0.01), vec3(0.96, 0.34, 0.05), smoothstep(0.0, 0.35, h));
    c = mix(c, mix(jewelC, vec3(1.0, 0.66, 0.16), 0.6), smoothstep(0.3, 0.65, h));
    c = mix(c, mix(hot, vec3(1.0, 0.86, 0.5), 0.5), smoothstep(0.6, 0.95, h));
    return mix(c, vec3(1.0, 0.97, 0.88), smoothstep(0.95, 1.4, h));
}

#include "skin/main.glsl"
