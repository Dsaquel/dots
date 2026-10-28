#version 300 es
precision highp float;

in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;

uniform sampler2D farTex;
uniform sampler2D doorTex;
uniform sampler2D liveTex;
uniform float live;
uniform vec2 texSize;
uniform vec4 drawn;
uniform float mode;
uniform vec2 centre;
uniform vec2 size;
uniform float focal;
uniform float cam;
uniform float depth;
uniform float wall;
uniform float phi;
uniform float seam;
uniform float farAlpha;
uniform float casingAlpha;
uniform float glint;
uniform float arch;
uniform float casing;
uniform float scale;
uniform vec4 lightPos;
uniform vec3 leadBase;
uniform vec3 leadHi;
uniform vec3 leadLow;
uniform vec3 keyline;
uniform vec3 hot;
uniform vec3 jewel0;
uniform vec3 jewel1;
uniform vec3 jewel2;
uniform vec3 edgeGlass;
uniform vec3 sepia;
uniform float ink;

const float PI = 3.14159265;

#include "lib/math.glsl"

vec4 over(vec4 top, vec4 under) {
    return top + under * (1.0 - top.a);
}

vec3 jewelOf(float h) {
    return h < 0.34 ? jewel0 : (h < 0.67 ? jewel1 : jewel2);
}

float aHalf;
float aYc;
float aK;
float aR;

void archInit() {
    aHalf = size.x * 0.5 + casing;
    aYc = (aHalf * aHalf - arch * arch) / (2.0 * arch) * 1.12;
    aK = (arch * arch + 2.0 * arch * aYc - aHalf * aHalf) / (2.0 * aHalf);
    aR = sqrt(aK * aK + sq(arch + aYc));
}

#include "lib/arch.glsl"

#include "enfilade/light.glsl"

#include "enfilade/facade.glsl"

#include "enfilade/opening.glsl"

#include "enfilade/room.glsl"

#include "enfilade/leaf.glsl"

void main() {
    vec2 p = drawn.xy + v_texcoord * drawn.zw;
    if (mode < 0.5) {
        fragColor = tap(farTex, p);
        return;
    }
    archInit();
    vec4 col = farAlpha > 0.001 ? room(p) * farAlpha : vec4(0.0);
    col = over(leaf(p, true), col);
    col = over(leaf(p, false), col);
    fragColor = col;
}
