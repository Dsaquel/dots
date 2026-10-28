#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 farMap;
    float t;
    float seed;
    vec2 area;
    float road;
    float roadW;
    float gain;
    vec4 tint;
};
layout(binding = 1) uniform sampler2D farTex;

float hash(vec2 p)
{
    return fract(sin(dot(p, vec2(127.1, 311.7)) + seed * 17.0) * 43758.5453);
}

float vnoise(vec2 p)
{
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void main()
{
    vec2 uv = qt_TexCoord0;
    vec4 f = texture(farTex, clamp(farMap.xy + uv * farMap.zw, 0.0, 1.0));
    vec2 q = uv * area / vec2(7.0, 2.0);
    float h = vnoise(q);
    float rate = 0.7 + 1.6 * vnoise(q + 9.1);
    float tw = sin(t * rate + h * 6.2832);
    float g = smoothstep(0.86, 1.0, tw) * smoothstep(0.35, 0.75, vnoise(q * vec2(0.5, 1.0) + 3.7));
    float dx = (uv.x - road) / max(roadW, 1e-3);
    float onRoad = exp(-dx * dx);
    float lum = dot(f.rgb, vec3(0.299, 0.587, 0.114));
    float hi = smoothstep(0.25, 0.75, lum);
    float swell = 0.85 + 0.15 * sin(t * 0.5);
    vec3 k = 1.0 + gain * g * hi * (0.35 + 0.65 * onRoad) * swell * tint.rgb;
    vec2 e = abs(uv - 0.5) * 2.0;
    float m = (1.0 - smoothstep(0.75, 1.0, e.x)) * (1.0 - smoothstep(0.6, 1.0, e.y));
    fragColor = vec4(f.rgb * (k - 1.0) * m, 0.0) * qt_Opacity;
}
