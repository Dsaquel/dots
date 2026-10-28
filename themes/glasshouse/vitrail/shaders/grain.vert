#version 300 es
precision highp float;

uniform mat3 proj;
uniform vec2 target;
uniform sampler2D tex;
uniform vec2 texSize;
uniform float flipY;
uniform vec4 box;
uniform float grain;
uniform float cols;
uniform float t;
uniform vec4 front;
uniform float seed;
uniform float scale;
uniform vec3 dust;
uniform vec3 sparkColor;
uniform vec2 lightAt;
uniform float ink;
uniform vec3 leaf;
uniform vec3 hot;
uniform vec3 sepia;
uniform float fire;
uniform vec4 win;
uniform float radius;

out vec4 v_col;
out float v_glow;

#include "lib/hash.glsl"

#include "lib/noise.glsl"

float release(vec2 p) {
    vec2 x = p / scale * 0.022;
    float n = 0.55 * vnoise(x) + 0.3 * vnoise(x * 2.9 + 13.1) + 0.15 * vnoise(x * 7.3 + 5.7);
    float y = clamp((p.y - front.x) / max(front.y, 1.0), 0.0, 1.0);
    return mix(front.z, front.w, y) + (n - 0.5) * 90.0;
}

void main() {
    float i = float(gl_VertexID);
    float gx = mod(i, cols);
    float gy = floor(i / cols);
    vec2 s = box.xy + (vec2(gx, gy) + 0.5) * grain;
    vec2 uv = s / texSize;
    if (flipY > 0.5) uv.y = 1.0 - uv.y;
    vec4 c = textureLod(tex, uv, 0.0);
    float tr = release(s);
    float age = t - tr;
    vec4 h = hash4(vec2(gx, gy));
    float life = min(170.0 + 190.0 * h.x, 595.0 - tr);
    vec3 straight = c.rgb / max(c.a, 1e-3);
    float lum = dot(straight, vec3(0.299, 0.587, 0.114));
    vec2 hs = win.zw * 0.5;
    vec2 qq = abs(s - win.xy - hs) - hs + vec2(radius);
    bool lead = fire > 0.5 && length(max(qq, 0.0)) + min(max(qq.x, qq.y), 0.0) - radius > 0.0;
    bool spark = fire > 0.5 ? h.w > (ink > 0.5 ? 0.975 : 0.988) : h.w > (ink > 0.5 ? 0.975 : 0.82) && lum > 0.14;
    if (lead || c.a < 0.03 || age < 0.0 || age > life || life < 20.0 || (ink > 0.5 && h.y > (fire > 0.5 ? 0.1 : 0.3) && !spark)) {
        gl_Position = vec4(2.0, 2.0, 2.0, 1.0);
        gl_PointSize = 1.0;
        v_col = vec4(0.0);
        v_glow = 0.0;
        return;
    }
    float a = age / life;
    float sec = age / 1000.0;
    vec2 toLight = lightAt - s;
    vec2 wind = normalize(mix(vec2(0.0, -1.0), toLight / max(length(toLight), 1.0), 0.3));
    vec2 side = vec2(-wind.y, wind.x);
    float speed = (150.0 + 360.0 * h.z) * scale * (fire > 0.5 && spark ? 1.6 : 1.0);
    vec2 pos = s + wind * (speed * sec + 0.5 * 900.0 * scale * sec * sec) + side * ((h.y - 0.5) * 220.0 * scale * sec + sin(sec * 16.0 + h.w * 6.2832) * 12.0 * scale * a);
    gl_Position = vec4((proj * vec3(pos / target, 1.0)).xy, 0.0, 1.0);
    float flick = 0.65 + 0.35 * sin(sec * 46.0 + h.y * 6.2832);
    float cooled = spark ? smoothstep(0.3, 1.0, a) : smoothstep(0.0, 0.1, a);
    if (ink > 0.5) {
        float turn = abs(sin(sec * 22.0 + h.y * 6.2832));
        vec3 flake = spark ? mix(leaf, hot, 0.6) : mix(leaf * (1.2 + 0.15 * h.z), hot, pow(turn, 6.0) * 0.9);
        if (fire > 0.5)
            flake = spark ? mix(hot, leaf, cooled) : mix(leaf * 1.2, sepia, smoothstep(0.1, 0.5, a));
        gl_PointSize = grain * (1.2 - 0.6 * a) * (0.75 + 0.5 * h.z) * (spark ? 1.9 : 2.1 * (0.35 + 0.65 * turn));
        v_col = vec4(mix(straight, flake, 0.75 + 0.25 * smoothstep(0.0, 0.4, a)), c.a * (spark ? 1.0 : 0.85) * pow(1.0 - a, 1.2));
        v_glow = 0.0;
        return;
    }
    if (fire > 0.5) {
        float weight = spark ? 1.0 : 0.4 * mix(0.25, 1.0, smoothstep(0.06, 0.45, lum));
        vec3 ash = vec3(0.2, 0.19, 0.2) * (0.6 + 0.5 * lum);
        gl_PointSize = grain * (1.2 - 0.6 * a) * (0.75 + 0.5 * h.z) * (spark ? 1.7 : 1.0);
        v_col = vec4(spark ? mix(hot, sparkColor, 0.45 + 0.55 * cooled) * (0.9 + 0.5 * flick) : mix(sparkColor * 0.8, ash, cooled), c.a * weight * pow(1.0 - a, 1.4));
        v_glow = spark ? 1.0 : 0.6 * (1.0 - cooled);
        return;
    }
    gl_PointSize = grain * (1.2 - 0.6 * a) * (0.75 + 0.5 * h.z) * (spark ? 1.9 : 1.0);
    float glow = smoothstep(0.0, 0.4, a);
    float weight = spark ? 1.0 : mix(0.1, 0.8, smoothstep(0.06, 0.45, lum));
    vec3 col = mix(straight, spark ? sparkColor : dust, glow) * (1.0 + (spark ? 1.6 : 0.4) * glow);
    v_col = vec4(col, c.a * weight * pow(1.0 - a, 1.4));
    v_glow = spark ? 1.0 : glow;
}
