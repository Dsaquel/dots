#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 box;
    vec2 impact;
    float spread;
    float heat;
    float scar;
    float shift;
    float seed;
    vec4 hot;
    vec4 cool;
};
layout(binding = 1) uniform sampler2D src;

const float PI = 3.14159265;
const float TAU = 6.2831853;
const int RAYS = 11;

float hash(float n) {
    return fract(sin(n * 127.1 + seed * 311.7) * 43758.5453);
}

float vnoise(float x) {
    float i = floor(x);
    float f = fract(x);
    return mix(hash(i), hash(i + 1.0), f * f * (3.0 - 2.0 * f));
}

float baseAngle(int k) {
    float fk = float(k);
    return (fk + 0.8 * (hash(fk + 1.0) - 0.5)) * TAU / float(RAYS) + seed * 2.3;
}

float rayAngle(int k, float r) {
    float fk = float(k);
    return baseAngle(k) + 0.22 * (vnoise(r * 0.04 + fk * 7.0) - 0.5) + 0.07 * (vnoise(r * 0.23 + fk * 3.0) - 0.5);
}

float wrapAngle(float a) {
    return a - TAU * floor((a + PI) / TAU);
}

void main() {
    vec2 p = qt_TexCoord0 * box;
    vec2 d = p - impact;
    float r = length(d);
    float th = r > 1e-3 ? atan(d.y, d.x) : 0.0;
    float maxR = length(max(impact, box - impact));
    float front = spread * maxR;

    float best = 1e4;
    int sector = 0;
    float lastDa = 1e4;
    for (int k = 0; k < RAYS; k++) {
        float len = maxR * (0.3 + 0.7 * hash(float(k) + 9.0));
        float da = wrapAngle(th - rayAngle(k, r));
        if (abs(da) < PI * 0.5 && r < min(len, front))
            best = min(best, r * abs(sin(da)));
        if (da >= 0.0 && da < lastDa) {
            lastDa = da;
            sector = k;
        }
    }
    float fs = float(sector);
    float ringD = 1e4;
    int ring = 0;
    for (int j = 0; j < 2; j++) {
        float fj = float(j);
        float R = box.y * (0.42 + 0.5 * fj + 0.32 * hash(fs * 3.0 + fj * 17.0));
        R += 3.0 * (vnoise(th * 9.0 + fs + fj * 5.0) - 0.5);
        if (hash(fs * 5.0 + fj * 11.0) < (j == 0 ? 0.7 : 0.4) && R < front)
            ringD = min(ringD, abs(r - R));
        if (r > R)
            ring = j + 1;
    }
    float dist = min(best, ringD);

    float piece = fs * 3.0 + float(ring);
    float inside = smoothstep(front + 2.0, front - 2.0, r);
    vec2 off = (vec2(hash(piece + 21.0), hash(piece + 37.0)) - 0.5) * 2.0 * shift * inside;
    vec4 c = texture(src, clamp((p + off) / box, vec2(0.0), vec2(1.0)));
    float tilt = (hash(piece + 53.0) - 0.5) * 0.24 * inside * step(0.01, shift);
    c.rgb *= 1.0 + tilt;

    float line = (1.0 - smoothstep(0.3, 1.2, dist)) * inside;
    float halo = exp(-dist * dist / 8.0) * inside;
    float nearImpact = 0.55 + 0.45 * exp(-r / max(box.y * 1.2, 1.0));
    vec3 add = hot.rgb * (line * 1.4 + halo * 0.45) * heat * nearImpact + cool.rgb * line * scar * (1.0 - heat) * 0.8;
    float a = c.a;
    c.rgb *= 1.0 - 0.4 * halo * scar * (1.0 - heat);
    fragColor = vec4(c.rgb + add * a, a) * qt_Opacity;
}
