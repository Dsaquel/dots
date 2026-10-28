#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float t;
    float seed;
    float count;
    vec2 area;
    vec2 drift;
    float wander;
    float blink;
    float duty;
    float size;
    float halo;
    vec4 colA;
    vec4 colB;
    float mixB;
    vec4 beam;
    float beamAmt;
    float edge;
    float power;
};

vec2 hash2(float n)
{
    return fract(sin(vec2(n * 127.1 + seed * 74.7, n * 269.5 + seed * 183.3)) * 43758.5453);
}

void main()
{
    vec2 px = qt_TexCoord0 * area;
    vec3 acc = vec3(0.0);
    for (int i = 0; i < 16; i++) {
        float fi = float(i);
        if (fi >= count)
            break;
        vec2 h = hash2(fi + 1.0);
        vec2 g = hash2(fi + 31.0);
        vec2 p = h * area + drift * (0.55 + 0.9 * g.x) * t;
        p += wander * vec2(sin(t * (0.19 + 0.21 * g.y) + fi * 2.1), cos(t * (0.15 + 0.17 * g.x) + fi * 1.3));
        p = mod(p, area);
        float ph = fract(t / (blink * (0.7 + 0.6 * g.y)) + h.x);
        float on = smoothstep(0.0, duty * 0.35, ph) * (1.0 - smoothstep(duty * 0.45, duty, ph));
        if (beamAmt > 0.0) {
            float b = sin(dot(p, beam.xy) / max(beam.z, 1.0) * 6.2832);
            on *= mix(1.0, smoothstep(0.35, 0.95, b), beamAmt);
        }
        vec2 d = px - p;
        float r2 = dot(d, d);
        float glow = exp(-r2 / max(size * size, 0.01)) + 0.28 * exp(-r2 / max(halo * halo, 0.01));
        acc += mix(colA.rgb, colB.rgb, step(1.0 - mixB, g.x)) * glow * on;
    }
    vec2 e = min(px, area - px);
    float fade = smoothstep(0.0, edge, min(e.x, e.y));
    fragColor = vec4(acc * power * fade, 0.0) * qt_Opacity;
}
