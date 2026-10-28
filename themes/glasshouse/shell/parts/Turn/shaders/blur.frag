#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 srcSize;
    float stage;
    float radius;
    float passes;
    float vibrancy;
    float vibDark;
    float contrast;
    float noise;
    float brightness;
};
layout(binding = 1) uniform sampler2D src;

const float Pr = 0.299;
const float Pg = 0.587;
const float Pb = 0.114;
const float A = 0.93;
const float B = 0.11;
const float C = 0.66;

vec3 gain(vec3 s, float k)
{
    vec3 x = clamp(s, 0.0, 1.0);
    vec3 t = step(0.5, x);
    vec3 y = mix(x, 1.0 - x, t);
    vec3 a = 0.5 * pow(max(2.0 * y, vec3(1e-6)), vec3(k));
    return mix(a, 1.0 - a, t);
}

float doubleCircleSigmoid(float x, float a)
{
    a = clamp(a, 0.0, 1.0);
    if (x <= a)
        return a - sqrt(max(a * a - x * x, 0.0));
    return a + sqrt(max((1.0 - a) * (1.0 - a) - (x - 1.0) * (x - 1.0), 0.0));
}

vec3 rgb2hsl(vec3 col)
{
    float minc = min(col.r, min(col.g, col.b));
    float maxc = max(col.r, max(col.g, col.b));
    float delta = maxc - minc;
    float lum = (minc + maxc) * 0.5;
    float sat = 0.0;
    float hue = 0.0;
    if (lum > 0.0 && lum < 1.0) {
        float mul = lum < 0.5 ? lum : 1.0 - lum;
        sat = delta / (mul * 2.0);
    }
    if (delta > 0.0) {
        vec3 maxv = vec3(maxc);
        vec3 masks = vec3(equal(maxv, col)) * vec3(notEqual(maxv, vec3(col.g, col.b, col.r)));
        vec3 adds = vec3(0.0, 2.0, 4.0) + vec3(col.g - col.b, col.b - col.r, col.r - col.g) / delta;
        hue += dot(adds, masks);
        hue /= 6.0;
        if (hue < 0.0)
            hue += 1.0;
    }
    return vec3(hue, sat, lum);
}

vec3 hsl2rgb(vec3 col)
{
    const float onethird = 1.0 / 3.0;
    const float twothird = 2.0 / 3.0;
    float hue = col.x;
    float sat = col.y;
    float lum = col.z;
    vec3 xt = vec3(0.0);
    if (hue < onethird) {
        xt = vec3(6.0 * (onethird - hue), 6.0 * hue, 0.0);
    } else if (hue < twothird) {
        xt = vec3(0.0, 6.0 * (twothird - hue), 6.0 * (hue - onethird));
    } else {
        xt = vec3(6.0 * (hue - twothird), 0.0, 6.0 * (1.0 - hue));
    }
    xt = min(xt, 1.0);
    vec3 ct = 2.0 * sat * xt + (1.0 - sat);
    return lum >= 0.5 ? (1.0 - lum) * ct + (2.0 * lum - 1.0) : lum * ct;
}

float hash(vec2 p)
{
    vec3 p3 = fract(vec3(p.xyx) * 1689.1984);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

void main()
{
    vec2 uv = qt_TexCoord0;
    vec2 hp = (stage > 1.5 ? 0.25 : 1.0) * radius / srcSize;
    vec4 c;
    if (stage < 0.5) {
        c = texture(src, uv);
        if (contrast != 1.0)
            c.rgb = gain(c.rgb, contrast);
        c.rgb *= max(1.0, brightness);
    } else if (stage < 1.5) {
        vec4 sum = texture(src, uv) * 4.0;
        sum += texture(src, uv - hp);
        sum += texture(src, uv + hp);
        sum += texture(src, uv + vec2(hp.x, -hp.y));
        sum += texture(src, uv - vec2(hp.x, -hp.y));
        c = sum / 8.0;
        if (vibrancy != 0.0) {
            float vd = 1.0 - vibDark;
            vec3 hsl = rgb2hsl(c.rgb);
            float pb = doubleCircleSigmoid(sqrt(c.r * c.r * Pr + c.g * c.g * Pg + c.b * c.b * Pb), 0.8 * vd);
            float b1 = B * vd;
            float boost = hsl.y > 0.0 ? smoothstep(b1 - C * 0.5, b1 + C * 0.5, 1.0 - (pow(max(1.0 - hsl.y * cos(A), 0.0), 2.0) + pow(max(1.0 - pb * sin(A), 0.0), 2.0))) : 0.0;
            float s = clamp(hsl.y + boost * vibrancy / max(passes, 1.0), 0.0, 1.0);
            c = vec4(hsl2rgb(vec3(hsl.x, s, hsl.z)), c.a);
        }
    } else {
        vec4 sum = texture(src, uv + vec2(-hp.x * 2.0, 0.0));
        sum += texture(src, uv + vec2(-hp.x, hp.y)) * 2.0;
        sum += texture(src, uv + vec2(0.0, hp.y * 2.0));
        sum += texture(src, uv + vec2(hp.x, hp.y)) * 2.0;
        sum += texture(src, uv + vec2(hp.x * 2.0, 0.0));
        sum += texture(src, uv + vec2(hp.x, -hp.y)) * 2.0;
        sum += texture(src, uv + vec2(0.0, -hp.y * 2.0));
        sum += texture(src, uv + vec2(-hp.x, -hp.y)) * 2.0;
        c = sum / 12.0;
        if (stage > 2.5) {
            c.rgb += (hash(uv) - 0.5) * noise;
            c.rgb *= min(1.0, brightness);
        }
    }
    fragColor = c * qt_Opacity;
}
