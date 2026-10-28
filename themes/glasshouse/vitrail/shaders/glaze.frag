#version 300 es
precision highp float;

in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;

uniform sampler2D tex;
uniform vec2 texSize;
uniform vec4 drawn;
uniform vec4 box;
uniform float radius;
uniform vec2 grid;
uniform float t;
uniform float rising;
uniform float live;
uniform float scale;
uniform float ink;
uniform float pop;
uniform vec4 seat;
uniform vec4 lift;
uniform vec4 weld;
uniform vec2 lamp;
uniform vec3 lampHue;
uniform vec3 leadLow;
uniform vec3 hot;
uniform vec3 gold;
uniform vec3 sepia;
uniform vec3 leaf;
uniform vec4 umbra;

const float PI = 3.14159265;
const float CAME = 1.7;
const float DARK = 0.65;
const float LEADED = 0.4;
const float COOLED = 80.0;
const float FALLS = 1.6;
const float FALLMIN = 40.0;
const float FALLMAX = 96.0;
const float DROP = 12.0;
const float CAST = 14.0;
const float BLUR = 8.0;
const float NEAR = 0.12;
const float BEAD = 2.2;
const float SETTLE = 1.0;
const float SETTLED = 30.0;
const float FRAMEPOP = 0.03;
const float FRAMECAST = 10.0;
const float UNSEAT = 0.3;
const float POPPED = 30.0;
const float CRACK = 60.0;
const float SPRING = 0.015;
const float JUMP = 6.0;
const float LOFT = 0.08;
const float RISE = 56.0;
const float FADE = 25.0;
const float UNFRAMED = 90.0;
const float UNLIFT = 10.0;
const float HEM = 2.0;
const float RIM = 24.0;
const float DISSOLVE = 10.0;
const float DISSOLVED = 30.0;
const float BODY = 1.5;
const float KEYLINE = 1.2;
const float GLOSS = 0.09;
const float BLOOM = 0.03;
const float BASE = 0.085;

float core = 0.0;
float halo = 0.0;
float shine = 0.0;
float inked = 0.0;

#include "lib/math.glsl"

#include "glaze/base.glsl"

#include "glaze/lattice.glsl"

#include "glaze/timing.glsl"

#include "glaze/came.glsl"

#include "glaze/seat.glsl"

#include "glaze/live.glsl"

#include "glaze/rise.glsl"

void main() {
    vec2 p = drawn.xy + v_texcoord * drawn.zw;
    inked = ink * (hullOf(p) < 0.0 ? smoothstep(0.35, 0.6, lumaOf(tap(p))) : 1.0);
    if (rising > 0.5) {
        fragColor = hidden(p);
        return;
    }
    if (live > 0.5) {
        fragColor = overlay(p);
        return;
    }
    vec4 acc = seated(p);
    if (t >= seat.w)
        acc = frameOf(p, acc);
    for (int i = 0; i < 32; ++i) {
        if (float(i) >= grid.y)
            break;
        acc = flying(p, float(i), acc);
    }
    fragColor = acc;
}
