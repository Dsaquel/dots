#version 300 es
precision highp float;

uniform mat3 proj;
uniform vec2 target;
uniform vec3 eye;
uniform vec3 camR;
uniform vec3 camU;
uniform vec3 camF;
uniform vec2 centre;
uniform float focal;
uniform float rest;
uniform float fogK;
uniform float t;
uniform float amount;
uniform float scale;
uniform vec3 boxLo;
uniform vec3 boxHi;
uniform vec3 dust;
uniform vec3 hot;
uniform vec3 keyline;
uniform float ink;
uniform int doorsN;
uniform float doorZ[10];
uniform float doorShut[10];
uniform vec2 size;
uniform float wall;

out vec4 v_col;
out float v_star;

#include "lib/mote.glsl"

float seen(vec3 X) {
    float k = 1.0;
    for (int i = 0; i < 10; ++i) {
        if (i >= doorsN)
            break;
        float zf = doorZ[i] - wall;
        if (zf <= eye.z)
            continue;
        if (zf >= X.z)
            break;
        vec2 P = eye.xy + (X.xy - eye.xy) * ((zf - eye.z) / (X.z - eye.z));
        if (P.x < 0.0 || P.x > size.x || P.y < 0.0 || P.y > size.y)
            return 0.0;
        if (doorZ[i] < X.z)
            k *= 1.0 - doorShut[i];
    }
    return k;
}

void main() {
    float id = float(gl_VertexID);
    vec4 h = hash4(vec2(id, 17.0));
    vec4 g = hash4(vec2(id, 53.0));
    vec3 X = mix(boxLo, boxHi, h.xyz);
    X += vec3((g.x - 0.5) * 36.0, -18.0 - 30.0 * g.y, (g.w - 0.5) * 20.0) * (t / 1000.0);
    vec3 rel = X - eye;
    float z = dot(rel, camF);
    if (z < 60.0 || amount <= 0.001) {
        hide();
        return;
    }
    vec2 pos = centre + vec2(dot(rel, camR), dot(rel, camU)) * focal / z;
    float vis = seen(X);
    if (vis <= 0.001) {
        hide();
        return;
    }
    bool star = h.w > 0.94;
    float near = clamp(rest / z, 0.3, 3.5);
    gl_Position = vec4((proj * vec3(pos / target, 1.0)).xy, 0.0, 1.0);
    gl_PointSize = (star ? 8.0 : 2.0 + 2.4 * g.z) * near * scale;
    float fog = exp(-max(z - rest, 0.0) * fogK * 0.7);
    float tw = 0.6 + 0.4 * sin(t * (0.008 + 0.02 * g.w) + g.x * 6.28);
    v_col = vec4(star ? mix(keyline, hot, 0.5) : dust, amount * fog * smoothstep(60.0, 320.0, z) * (0.35 + 0.65 * g.x) * tw * vis);
    v_star = star ? 1.0 : 0.0;
}
