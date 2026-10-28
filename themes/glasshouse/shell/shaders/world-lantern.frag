#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 farMap;
    vec4 nearMap;
    float hasNear;
    vec2 center;
    float aspect;
    float t;
    float seed;
    float reach;
    float gain;
    float boost;
    float flicker;
    vec4 warm;
    vec4 hot;
    float bloom;
    float pulse;
};
layout(binding = 1) uniform sampler2D farTex;
layout(binding = 2) uniform sampler2D nearTex;

float hash(float n)
{
    return fract(sin(n * 127.1 + seed * 311.7) * 43758.5453);
}

float noise(float x)
{
    float i = floor(x);
    float f = fract(x);
    return mix(hash(i), hash(i + 1.0), f * f * (3.0 - 2.0 * f));
}

void main()
{
    vec2 uv = qt_TexCoord0;
    vec4 f = texture(farTex, clamp(farMap.xy + uv * farMap.zw, 0.0, 1.0));
    vec4 n = texture(nearTex, clamp(nearMap.xy + uv * nearMap.zw, 0.0, 1.0)) * hasNear;
    vec3 c = n.rgb + f.rgb * (1.0 - n.a);

    float wander = noise(t * 1.3) - 0.5;
    float shiver = noise(t * 5.3 + 17.0) - 0.5;
    float gutter = smoothstep(0.8, 1.0, noise(t * 0.43 + 41.0));
    float flame = 0.95 * wander + 0.5 * shiver - 0.9 * gutter;
    float orb = 0.5 * sin(t * 1.9) + 0.25 * (noise(t * 0.7 + 3.0) - 0.5);
    float fl = flicker * mix(flame, orb, pulse);

    vec2 d = (uv - center) * vec2(aspect, 1.0);
    float r2 = dot(d, d);
    float light = exp(-r2 / max(reach * reach, 1e-5) * 2.4);
    vec3 k = 1.0 + light * (boost + gain * fl) * warm.rgb;

    vec2 e = abs(uv - 0.5) * 2.0;
    float m = (1.0 - smoothstep(0.78, 1.0, e.x)) * (1.0 - smoothstep(0.78, 1.0, e.y));
    float a = max(0.0, 1.0 - min(k.r, min(k.g, k.b)));
    float b = exp(-r2 / max(bloom * bloom, 1e-6)) * (0.55 + 0.45 * (1.0 + fl)) * 0.32;
    fragColor = vec4(c * max(k + a - 1.0, 0.0) * m + hot.rgb * b, a * m) * qt_Opacity;
}
