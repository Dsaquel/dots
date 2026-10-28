#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 res;
    vec2 palm;
    vec2 shake;
    float zoom;
    float hold;
    float imp;
    float inv;
    float thrA;
    float thrB;
    float vig;
    float ringR;
    float ringW;
    float ringI;
    float ringD;
    float split;
    float ab;
    float blur;
    float flash;
    float flashR;
    float sparkT;
    float sparkI;
    float lines;
    float seed;
    vec4 ink;
    vec4 gold;
    vec4 hot;
    vec4 warm;
};
layout(binding = 1) uniform sampler2D src;
layout(binding = 2) uniform sampler2D frz;

float hash(float n) { return fract(sin(n * 91.7 + 13.1) * 43758.5453); }

float vnoise(float x)
{
    float i = floor(x);
    float f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    return mix(hash(i), hash(i + 1.0), f);
}

vec3 fetch(vec2 q)
{
    vec2 uv = q / res;
    uv = 1.0 - abs(1.0 - abs(uv));
    if (hold > 0.5)
        return texture(frz, uv).rgb;
    return texture(src, uv).rgb;
}

vec3 sparks(vec2 p, float t)
{
    vec3 acc = vec3(0.0);
    for (int i = 0; i < 26; i++) {
        float fi = float(i);
        float h1 = hash(fi * 1.31 + 0.7);
        float h2 = hash(fi * 2.17 + 1.9);
        float h3 = hash(fi * 3.53 + 4.1);
        float h4 = hash(fi * 5.11 + 2.3);
        float tt = t - 0.04 * h2 * h2;
        float life = 0.35 + 0.5 * h3;
        if (tt <= 0.0 || tt > life)
            continue;
        float ang = 6.28318 * (fi + 0.9 * h1) / 26.0;
        vec2 dv = vec2(cos(ang), sin(ang));
        float v = 900.0 + 2600.0 * h4;
        float kk = 1.8 + 2.2 * h2;
        float r0 = 50.0 + 50.0 * h1;
        float t2 = max(0.0, tt - 0.045);
        float s1 = r0 + v * (1.0 - exp(-kk * tt)) / kk;
        float s0 = r0 + v * (1.0 - exp(-kk * t2)) / kk;
        vec2 g = vec2(0.0, 900.0 + 700.0 * h3);
        vec2 a1 = palm + dv * s1 + g * tt * tt;
        vec2 a0 = palm + dv * s0 + g * t2 * t2;
        vec2 e = a1 - a0;
        vec2 ap = p - a0;
        float hl = clamp(dot(ap, e) / max(dot(e, e), 0.001), 0.0, 1.0);
        float dist = length(ap - e * hl);
        float u = tt / life;
        float w = (0.8 + 1.4 * h4) * (0.3 + 0.7 * hl);
        float trail = exp(-dist * dist / (w * w)) * (0.1 + 0.9 * hl * hl);
        float hd = length(p - a1);
        float head = exp(-hd * hd / (4.0 + 5.0 * h4)) * 1.4 + exp(-hd / (5.0 + 4.0 * h4)) * 0.35;
        vec3 col = mix(warm.rgb, mix(hot.rgb, vec3(1.0), 0.5), hl);
        acc += (col * trail + mix(hot.rgb, vec3(1.0), 0.7) * head) * (1.0 - u * u) * (0.6 + 0.8 * h4);
    }
    return acc;
}

float speedLines(vec2 d, float r, float sd)
{
    float a = atan(d.y, d.x) / 6.28318 + 0.5;
    float n = 96.0;
    float f = a * n;
    float id = floor(f);
    float h = hash(id + sd * 17.0);
    float wa = 0.06 + 0.22 * h;
    float lane = abs(fract(f) - 0.5);
    float wedge = 1.0 - smoothstep(wa * 0.5, wa * 0.5 + 0.08, lane);
    float inner = 520.0 + 420.0 * hash(id * 3.1 + sd);
    float m = smoothstep(inner, inner + 300.0, r);
    return wedge * m * step(0.55, hash(id * 5.7 + sd));
}

void main()
{
    vec2 p = qt_TexCoord0 * res;
    vec2 ctr = res * 0.5;
    vec2 q = ctr + (p - shake - ctr) / zoom;
    vec2 d = q - palm;
    float r = length(d);
    vec2 dir = d / max(r, 1.0);
    float ang = atan(d.y, d.x);

    float wob = 0.75 + 0.5 * vnoise(ang * 5.0 + 3.0) * vnoise(ang * 11.0 + 17.0 + ringR * 0.004);
    float x = (r - ringR) / (ringW * (0.7 + 0.6 * wob));
    float disp = ringD * wob * x * exp(-x * x);
    vec3 c;
    if (blur > 0.0005) {
        c = vec3(0.0);
        for (int i = 0; i < 8; i++) {
            vec2 b = q - dir * (blur * r * float(i) / 7.0);
            c.r += fetch(b - dir * (disp * (1.0 + split) + ab * r)).r;
            c.g += fetch(b - dir * disp).g;
            c.b += fetch(b - dir * (disp * (1.0 - split) - ab * r)).b;
        }
        c /= 8.0;
    } else if (abs(disp) > 0.05 || ab > 0.0) {
        c.r = fetch(q - dir * (disp * (1.0 + split) + ab * r)).r;
        c.g = fetch(q - dir * disp).g;
        c.b = fetch(q - dir * (disp * (1.0 - split) - ab * r)).b;
    } else {
        c = fetch(q);
    }

    if (imp > 0.5) {
        float lum = dot(min(c, vec3(1.0)), vec3(0.299, 0.587, 0.114));
        float k = smoothstep(thrA, thrB, lum);
        if (inv > 0.5)
            k = 1.0 - k;
        c = mix(ink.rgb, gold.rgb, k);
    }

    if (vig > 0.0)
        c *= 1.0 - vig * smoothstep(260.0, 1150.0, length(p - shake - ctr));

    if (ringI > 0.0) {
        float core = exp(-x * x * 2.5) * wob;
        float front = exp(-max(0.0, x) * 1.6) * step(0.0, x) * 0.25 + exp(-max(0.0, -x) * 1.4) * step(x, 0.0) * 0.16;
        c += (mix(hot.rgb, vec3(1.0), 0.35) * core + gold.rgb * front) * ringI;
    }
    if (flash > 0.0) {
        float fl = exp(-(r * r) / (flashR * flashR)) + 0.25 * exp(-r / (flashR * 2.0));
        float sx = exp(-abs(d.y) / 1.5) * exp(-abs(d.x) / (flashR * 5.0));
        float sy = exp(-abs(d.x) / 1.5) * exp(-abs(d.y) / (flashR * 3.0));
        c += mix(hot.rgb, vec3(1.0), 0.6) * flash * (fl + 0.9 * sx + 0.6 * sy);
    }
    if (sparkT > 0.0)
        c += sparks(q, sparkT) * sparkI;
    if (lines > 0.0)
        c = mix(c, mix(hot.rgb, vec3(1.0), 0.5), speedLines(d, r, seed) * lines);

    fragColor = vec4(c, 1.0) * qt_Opacity;
}
