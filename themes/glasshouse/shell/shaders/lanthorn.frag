#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 res;
    vec2 lamp;
    float t;
    float span;
    float back;
    float bloom;
    float veil;
    float margin;
    vec4 warm;
    vec4 w0;
    vec4 w1;
    vec4 w2;
    vec4 w3;
    vec4 w4;
    vec4 w5;
    vec4 w6;
    vec4 w7;
    vec4 sA;
    vec4 sB;
};
layout(binding = 1) uniform sampler2D still;
layout(binding = 2) uniform sampler2D room;

float hash(vec2 p)
{
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float vnoise(vec2 p)
{
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

vec4 win(int i)
{
    if (i == 0) return w0;
    if (i == 1) return w1;
    if (i == 2) return w2;
    if (i == 3) return w3;
    if (i == 4) return w4;
    if (i == 5) return w5;
    if (i == 6) return w6;
    return w7;
}

float start(int i)
{
    return i < 4 ? sA[i] : sB[i - 4];
}

float order(vec4 r, vec2 p)
{
    vec2 hole = clamp(lamp, r.xy, r.xy + r.zw);
    vec2 far = vec2(hole.x - r.x < r.x + r.z - hole.x ? r.x + r.z : r.x, hole.y - r.y < r.y + r.w - hole.y ? r.y + r.w : r.y);
    return clamp(0.88 * length(p - hole) / max(length(far - hole), 1.0) + 0.09 * vnoise(p / 70.0) + 0.03 * vnoise(p / 11.0), 0.0, 1.0);
}

void main()
{
    vec2 p = qt_TexCoord0 * res;
    vec3 sc = texture(still, qt_TexCoord0).rgb;
    vec3 rc = texture(room, qt_TexCoord0).rgb;
    int hit = -1;
    bool inner = false;
    for (int i = 0; i < 8; i++) {
        vec4 r = win(i);
        if (r.z <= 0.0)
            continue;
        if (p.x >= r.x - margin && p.y >= r.y - margin && p.x <= r.x + r.z + margin && p.y <= r.y + r.w + margin) {
            hit = i;
            inner = p.x >= r.x && p.y >= r.y && p.x <= r.x + r.z && p.y <= r.y + r.w;
            break;
        }
    }
    float d = length(p - lamp);
    vec3 flame = warm.rgb * bloom * (0.9 * exp(-pow(d / 16.0, 2.0)) + 0.32 * exp(-pow(d / 54.0, 2.0)));
    float pr = 0.0;
    float th = 1.0;
    if (hit >= 0) {
        pr = clamp((t - start(hit)) / span, 0.0, 1.0);
        th = inner ? order(win(hit), p) : (back > 0.5 ? 0.02 + 0.1 * vnoise(p / 23.0) : 0.86 + 0.12 * vnoise(p / 23.0));
    }
    float front = inner ? pow(1.0 - smoothstep(0.0, 0.012, abs(pr - th)), 2.0) : 0.0;
    vec3 seam = mix(warm.rgb, vec3(1.0, 0.94, 0.82), 0.55);
    float lum = dot(sc, vec3(0.299, 0.587, 0.114));
    if (back < 0.5) {
        vec3 c = mix(sc, rc, veil);
        if (hit >= 0) {
            float gone = smoothstep(th - 0.015, th + 0.015, pr);
            vec3 glass = inner ? sc * (1.0 - 0.2 * smoothstep(th - 0.25, th, pr)) : mix(sc, vec3(0.78, 0.8, 0.86) * (0.35 + lum), 0.7 * smoothstep(0.45, 0.86, pr));
            c = mix(glass, rc, gone) + seam * front * 0.7;
        }
        fragColor = vec4(c + flame, 1.0) * qt_Opacity;
    } else {
        float a = veil;
        if (hit >= 0)
            a *= 1.0 - smoothstep(th - 0.015, th + 0.015, pr);
        vec3 glow = seam * front * 0.6 + flame * a;
        fragColor = vec4(rc * a + glow, a) * qt_Opacity;
    }
}
