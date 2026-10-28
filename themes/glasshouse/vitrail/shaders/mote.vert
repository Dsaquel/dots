#version 300 es
precision highp float;

uniform mat3 proj;
uniform vec2 target;
uniform vec2 centre;
uniform vec2 size;
uniform float focal;
uniform float depth;
uniform float wall;
uniform float t;
uniform float tEnd;
uniform float back;
uniform float scale;
uniform float casing;
uniform float arch;
uniform float seam;
uniform vec4 seat[8];
uniform vec3 dust;
uniform vec3 hot;
uniform vec3 keyline;
uniform float ink;

out vec4 v_col;
out float v_star;

const float DUST = 260.0;
const float GOLD = 24.0;
const float TRAIL = 3.0;

#include "lib/math.glsl"

float span(float x, float a, float b) {
    return unit((x - a) / (b - a));
}

float inOut(float k) {
    k = unit(k);
    return k < 0.5 ? 4.0 * k * k * k : 1.0 - pow(-2.0 * k + 2.0, 3.0) / 2.0;
}

#include "lib/mote.glsl"

float camAt(float tt) {
    return back > 0.5 ? depth * pow(1.0 - span(tt, 0.0, tEnd), 2.4) : depth * inOut(span(tt, 20.0, tEnd));
}

float archY(float x) {
    float half_ = size.x * 0.5 + casing;
    float yc = (half_ * half_ - arch * arch) / (2.0 * arch) * 1.12;
    float k = (arch * arch + 2.0 * arch * yc - half_ * half_) / (2.0 * half_);
    float r = sqrt(k * k + (arch + yc) * (arch + yc));
    float lx = x - size.x * 0.5;
    float cx = lx < 0.0 ? k : -k;
    return yc - sqrt(max(r * r - (lx - cx) * (lx - cx), 0.0));
}

void place(vec2 pos, float px) {
    gl_Position = vec4((proj * vec3(pos / target, 1.0)).xy, 0.0, 1.0);
    gl_PointSize = px;
}

void main() {
    float id = float(gl_VertexID);
    if (id < DUST) {
        vec4 h = hash4(vec2(id, 17.0));
        vec4 g = hash4(vec2(id, 53.0));
        vec3 X = vec3((h.x * 1.3 - 0.15) * size.x, (h.y * 1.2 - 0.1) * size.y, (0.06 + 0.8 * h.z) * depth);
        X.xy += vec2((g.x - 0.5) * 40.0, -30.0) * (t / 1000.0);
        float d = X.z + focal - camAt(t);
        float env = span(t, 20.0, 110.0) * (1.0 - span(t, tEnd - 130.0, tEnd - 10.0));
        if (d < 90.0 || env <= 0.0) {
            hide();
            return;
        }
        vec2 pos = centre + (X.xy - centre) * focal / d;
        bool star = h.w > 0.9;
        float near = clamp(focal / d, 0.4, 3.2);
        place(pos, (star ? 9.0 : 2.2 + 2.6 * g.y) * near * scale);
        float tw = 0.6 + 0.4 * sin(t * (0.02 + 0.03 * g.z) + g.w * 6.28);
        v_col = vec4(star ? mix(keyline, hot, 0.5) : dust, env * smoothstep(90.0, 300.0, d) * (0.4 + 0.6 * g.x) * tw);
        v_star = star ? 1.0 : 0.0;
        return;
    }
    float r = id - DUST;
    float m = mod(r, TRAIL);
    float j = mod(floor(r / TRAIL), GOLD);
    int k = int(floor(r / (TRAIL * GOLD)));
    if (k > 7 || seat[k].z <= seat[k].x) {
        hide();
        return;
    }
    vec4 h = hash4(vec2(j + 3.0, float(k) + 11.0));
    float launch = (back > 0.5 ? tEnd - 200.0 : tEnd - 270.0) + j * 4.0;
    float tt = t - m * 12.0;
    float f = (tt - launch) / (back > 0.5 ? 180.0 : 230.0);
    if (f < 0.0 || f > 1.0) {
        hide();
        return;
    }
    int c = int(mod(j, 4.0));
    vec2 end = vec2(c == 0 || c == 3 ? seat[k].x : seat[k].z, c < 2 ? seat[k].y : seat[k].w);
    vec2 start;
    if (back > 0.5) {
        start = vec2(seam, end.y + (h.x - 0.5) * 300.0);
    } else {
        float sF = focal / (depth - wall + focal - camAt(launch));
        float sx = end.x + (h.x - 0.5) * 220.0;
        start = centre + (vec2(sx, archY(sx) + casing * 0.5) - centre) * sF;
    }
    vec2 mid = (start + end) * 0.5 + vec2(end.y - start.y, start.x - end.x) * (h.y - 0.5) * 0.35;
    float e = 1.0 - pow(1.0 - f, 2.2);
    vec2 pos = mix(mix(start, mid, e), mix(mid, end, e), e);
    bool star = h.w > 0.8 && m < 0.5;
    place(pos, (star ? 11.0 : 4.0 + 2.4 * h.z) * scale * (m < 0.5 ? 1.0 : 0.75));
    v_col = vec4(mix(keyline, hot, 0.25 + e * 0.6) * 1.3, (m < 0.5 ? 1.0 : (m < 1.5 ? 0.5 : 0.25)) * smoothstep(0.0, 0.12, f) * (0.7 + 0.3 * h.w));
    v_star = star ? 1.0 : 0.0;
}
