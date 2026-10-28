#version 300 es
precision highp float;

uniform mat3 proj;
uniform vec2 target;
uniform vec4 win;
uniform float radius;
uniform vec4 front;
uniform float came;
uniform float t;
uniform float scale;
uniform float seed;
uniform float count;
uniform vec3 gold;
uniform vec3 hot;

out vec2 v_q;
flat out vec4 v_col;
flat out vec2 v_dim;

#include "lib/hash.glsl"

#include "lib/noise.glsl"

float release(vec2 p) {
    vec2 x = p / scale * 0.022;
    float n = 0.55 * vnoise(x) + 0.3 * vnoise(x * 2.9 + 13.1) + 0.15 * vnoise(x * 7.3 + 5.7);
    float y = clamp((p.y - front.x) / max(front.y, 1.0), 0.0, 1.0);
    return mix(front.z, front.w, y) + (n - 0.5) * 90.0;
}

vec2 ringAt(float u, float out_, vec2 c, vec2 e, float rr, float per) {
    float lx = 2.0 * e.x;
    float ly = 2.0 * e.y;
    float A = 1.5707963 * rr;
    float R = radius + out_;
    float k = mod(u, per);
    if (k < lx) return c + vec2(k - e.x, -e.y - R);
    k -= lx;
    if (k < A) return c + vec2(e.x + R * sin(k / rr), -e.y - R * cos(k / rr));
    k -= A;
    if (k < ly) return c + vec2(e.x + R, k - e.y);
    k -= ly;
    if (k < A) return c + vec2(e.x + R * cos(k / rr), e.y + R * sin(k / rr));
    k -= A;
    if (k < lx) return c + vec2(e.x - k, e.y + R);
    k -= lx;
    if (k < A) return c + vec2(-e.x - R * sin(k / rr), e.y + R * cos(k / rr));
    k -= A;
    if (k < ly) return c + vec2(-e.x - R, e.y - k);
    k -= ly;
    return c + vec2(-e.x - R * cos(k / rr), -e.y - R * sin(k / rr));
}

void main() {
    int id = gl_VertexID / 6;
    int k = gl_VertexID - id * 6;
    vec2 corner = vec2(k == 1 || k == 2 || k == 4 ? 1.0 : -1.0, k == 2 || k == 4 || k == 5 ? 1.0 : -1.0);
    vec4 h = hash4(vec2(float(id), 3.7));
    vec2 hs = win.zw * 0.5;
    vec2 c = win.xy + hs;
    vec2 e = max(hs - vec2(radius), vec2(0.0));
    float rr = radius + 3.5 * scale;
    float per = 4.0 * (e.x + e.y) + 6.2831853 * rr;
    float u = (float(id) + 0.2 + 0.6 * h.x) / count * per;
    float off = came * scale;
    vec2 at = ringAt(u, off, c, e, rr, per);
    float age = t - release(at) - 10.0 - 40.0 * h.y;
    float life = 220.0 + 100.0 * h.z;
    if (age < 0.0 || age > life) {
        gl_Position = vec4(2.0, 2.0, 2.0, 1.0);
        v_q = vec2(0.0);
        v_col = vec4(0.0);
        v_dim = vec2(1.0);
        return;
    }
    float sec = age / 1000.0;
    vec2 tang = normalize(ringAt(u + scale, off, c, e, rr, per) - ringAt(u - scale, off, c, e, rr, per));
    vec2 nrm = vec2(tang.y, -tang.x);
    vec2 pos = at + (nrm * (70.0 + 90.0 * h.w) + tang * (h.x - 0.5) * 70.0) * scale * sec + vec2(0.0, 220.0 * scale * sec * sec);
    float spin = (h.z - 0.5) * 3.0 * sec + (h.w - 0.5) * 0.3;
    vec2 axis = mat2(cos(spin), sin(spin), -sin(spin), cos(spin)) * tang;
    float phase = sec * (5.0 + 7.0 * h.x);
    float face = abs(cos(phase));
    float len = (11.0 + 12.0 * h.x) * scale;
    float wid = (1.5 + 1.0 * h.y) * scale * max(face, 0.08);
    vec2 q = corner * vec2(len + scale, wid + scale);
    gl_Position = vec4((proj * vec3((pos + axis * q.x + vec2(-axis.y, axis.x) * q.y) / target, 1.0)).xy, 0.0, 1.0);
    v_q = q;
    v_dim = vec2(len, wid);
    float glint = pow(abs(sin(phase * 2.0 + h.y * 3.0)), 6.0);
    v_col = vec4(mix(gold * (0.95 + 0.35 * face), hot, clamp(exp(-age / 60.0) * 0.8 + glint * 0.8, 0.0, 1.0)),
                 smoothstep(0.0, 20.0, age) * (1.0 - smoothstep(0.55, 1.0, age / life)) * (0.7 + 0.3 * face));
}
