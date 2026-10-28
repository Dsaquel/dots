#version 300 es
precision highp float;

in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;

uniform float mode;
uniform sampler2D tex;
uniform vec2 texSize;
uniform vec4 drawn;

uniform vec3 eye;
uniform vec3 camR;
uniform vec3 camU;
uniform vec3 camF;
uniform vec2 centre;
uniform float focal;
uniform float rest;

uniform vec3 origin;
uniform vec3 axisX;
uniform vec3 axisY;
uniform vec3 axisZ;
uniform vec2 size;
uniform float wall;
uniform float casing;
uniform float arch;
uniform float phi;
uniform float seam;
uniform float doors;
uniform float frame;
uniform int roman;
uniform int romanLen;
uniform float glass;
uniform float fogK;
uniform float focus;
uniform float blurK;
uniform float dim;
uniform float filled;
uniform float mirror;
uniform float kindle;
uniform float sheen;
uniform vec3 lamp;

uniform vec3 fogColor;
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

uniform vec2 vanish;
uniform float zoomBlur;
uniform vec2 sweep;
uniform float fade;
uniform float rays;
uniform float bloom;
uniform float bloomCut;
uniform float shoulder;
uniform vec3 adapt;
uniform sampler2D goal;
uniform vec4 veil;
uniform float ground;
uniform vec2 glowAt;
uniform float glowR;
uniform vec4 glow;

const float PI = 3.14159265;

#include "lib/math.glsl"

vec4 over(vec4 top, vec4 under) {
    return top + under * (1.0 - top.a);
}

vec3 jewelOf(float h) {
    return h < 0.34 ? jewel0 : (h < 0.67 ? jewel1 : jewel2);
}

vec3 inked() {
    return ink > 0.5 ? sepia : leadLow;
}

vec3 o;
vec3 d;
float rawLen;
vec3 lampL;
int rom;
int romLen;
float kin;
bool inHall = false;
float zDoor;
vec3 cameC;

vec3 hallLight(vec3 Q, vec3 N);

float tAt(float z) {
    return (z - o.z) / d.z;
}

vec2 at(float z) {
    return o.xy + d.xy * tAt(z);
}

float depthOf(float t) {
    return t * focal / rawLen;
}

float pxOf(float t) {
    return max(depthOf(t) / focal, 1e-3);
}

float fogOf(float depth) {
    return 1.0 - exp(-max(depth - rest, 0.0) * fogK);
}

float aHalf;
float aYc;
float aK;
float aR;

void archInit() {
    float A = max(arch, 1.0);
    aHalf = size.x * 0.5 + casing;
    aYc = (aHalf * aHalf - A * A) / (2.0 * A) * 1.12;
    aK = (A * A + 2.0 * A * aYc - aHalf * aHalf) / (2.0 * aHalf);
    aR = sqrt(aK * aK + sq(A + aYc));
}

#include "lib/arch.glsl"

#include "passage/masonry.glsl"

#include "passage/numeral.glsl"

#include "passage/portal.glsl"


const int DOORS = 10;
uniform int doorsN;
uniform float doorZ[DOORS];
uniform float doorPhi[DOORS];
uniform float doorSeam[DOORS];
uniform float doorReveal[DOORS];
uniform float doorPaper[DOORS];
uniform float doorKindle[DOORS];
uniform float doorLight[DOORS];
uniform float doorLit[DOORS];
uniform int doorRoman[DOORS];
uniform int doorRomanLen[DOORS];
uniform int doorSlot[DOORS];
uniform sampler2D shot0;
uniform sampler2D shot1;
uniform sampler2D shot2;
uniform sampler2D shot3;
uniform sampler2D paper;
uniform float spacing;
uniform float aisle;
uniform float vault;
uniform float floorY;
uniform vec3 stone;
uniform vec3 paving;
uniform vec3 ambient;
uniform vec3 flame;
uniform vec3 screenTint;
uniform vec3 came;
uniform vec3 sunDir;
uniform vec3 sun;
uniform float glaze;
uniform float haze;
uniform float lanternGain;
uniform float swell;
uniform float polish;

float pathT0;
float lodBias;
bool cheap = false;
int pair;

#include "passage/lantern.glsl"

#include "passage/leaf.glsl"

const int NONE = 0;
const int WALLED = 1;
const int JAMB = 2;
const int FLOORED = 3;
const int VAULTED = 4;
const int SIDED = 5;

#include "passage/hall.glsl"

void main() {
    vec2 p = drawn.xy + v_texcoord * drawn.zw;
    if (mode < 0.5) {
        fragColor = tap(tex, p);
        return;
    }
    cameC = ink > 0.5 ? sepia : leadLow * 1.5 + leadBase * 0.3;
    if (mode < 1.5) {
        rom = roman;
        romLen = romanLen;
        kin = kindle;
        fragColor = room(p);
        return;
    }
    if (mode < 2.5) {
        float j = hash(p + fract(fade * 7.13)) - 0.5;
        vec2 zoom = (p - vanish) * zoomBlur;
        zoom *= min(1.0, 44.0 / max(length(zoom), 1e-3));
        vec2 streak = zoom + sweep * min(1.0, 30.0 / max(length(sweep), 1e-3));
        int n = int(clamp(length(streak) * (bloom > 0.0 ? 0.75 : 0.5), 1.0, bloom > 0.0 ? 24.0 : 20.0));
        vec4 col = vec4(0.0);
        for (int i = 0; i < 32; ++i) {
            if (i >= n)
                break;
            float k = n == 1 ? 0.0 : (float(i) + 0.5 + j) / float(n) - 0.5;
            col += tap(tex, p + streak * k);
        }
        col /= float(n);
        if (rays > 0.001) {
            vec3 shaft = vec3(0.0);
            float wsum = 0.0;
            int taps = bloom > 0.0 ? 6 : 10;
            for (int i = 0; i < 10; ++i) {
                if (i >= taps)
                    break;
                float k = (float(i) + 0.5 + j) / float(taps);
                vec4 s = bloom > 0.0 ? textureLod(tex, (p + (vanish - p) * k * 0.6) / texSize, 3.5) : tap(tex, p + (vanish - p) * k * 0.6);
                float lum = dot(s.rgb, vec3(0.299, 0.587, 0.114));
                float w = exp(-k * 2.2);
                shaft += s.rgb * smoothstep(0.2, 0.6, lum) * w;
                wsum += w;
            }
            col.rgb += shaft / wsum * rays;
        }
        if (bloom > 0.0) {
            vec2 uv = p / texSize;
            vec3 b = textureLod(tex, uv, 2.5).rgb * 0.45 + textureLod(tex, uv, 4.5).rgb * 0.35 + textureLod(tex, uv, 6.5).rgb * 0.2;
            col.rgb += max(b - bloomCut, 0.0) * bloom;
            col.rgb *= 1.0 - 0.4 * bloom * smoothstep(0.35, 1.25, length((p - centre) / texSize.y));
            vec3 over_ = max(col.rgb - 0.75, 0.0);
            col.rgb = mix(col.rgb, min(col.rgb, vec3(0.75)) + over_ / (1.0 + over_ * 4.0), shoulder);
            col.rgb += (hash(p + 0.37) - 0.5) / 255.0 * col.a;
        }
        if (adapt.y > 0.0) {
            vec3 luma = vec3(0.299, 0.587, 0.114);
            float seen = dot(textureLod(tex, vec2(0.5), 16.0).rgb, luma);
            float want = mix(adapt.x, dot(textureLod(goal, vec2(0.5), 16.0).rgb, luma), adapt.z);
            col.rgb *= mix(1.0, clamp(want / max(seen, 0.004), 0.5, 1.8), adapt.y);
        }
        fragColor = col * fade;
        return;
    }
    if (mode < 3.5) {
        float r = length((p - centre) / texSize);
        float a = veil.a * (0.62 + 0.38 * smoothstep(0.15, 0.85, r));
        float g = glow.a * exp(-sq(length((p - centre) / texSize.y)) / 0.05);
        a = max(a, ground * smoothstep(centre.y, texSize.y * 1.05, p.y));
        fragColor = vec4(veil.rgb * a + glow.rgb * g, a);
        return;
    }
    if (mode < 4.5) {
        float r = length(p - glowAt) / max(glowR, 1.0);
        float a = glow.a * (exp(-r * r * 2.2) * 0.8 + exp(-r * 1.6) * 0.35);
        fragColor = vec4(glow.rgb * a, 0.0);
        return;
    }
    fragColor = nave(p);
}
