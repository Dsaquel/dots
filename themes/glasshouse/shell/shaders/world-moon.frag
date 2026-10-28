#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 farMap;
    vec4 nearMap;
    float hasNear;
    float t;
    float seed;
    vec2 area;
    vec2 origin;
    vec2 dir;
    float len;
    vec4 beams;
    vec4 widths;
    vec4 pool;
    vec4 moon;
    float air;
    float sheen;
    float dust;
    float hasCut;
};
layout(binding = 1) uniform sampler2D farTex;
layout(binding = 2) uniform sampler2D nearTex;
layout(binding = 3) uniform sampler2D cutTex;

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

vec2 hash2(float n)
{
    return fract(sin(vec2(n * 127.1 + seed * 74.7, n * 269.5 + seed * 183.3)) * 43758.5453);
}

float band(float x, float c, float w)
{
    float d = abs(x - c) / max(w, 1.0);
    return 1.0 - smoothstep(0.45, 1.0, d);
}

void main()
{
    vec2 uv = qt_TexCoord0;
    vec4 f = texture(farTex, clamp(farMap.xy + uv * farMap.zw, 0.0, 1.0));
    vec2 nuv = clamp(nearMap.xy + uv * nearMap.zw, 0.0, 1.0);
    vec4 n = texture(nearTex, nuv) * hasNear;
    vec3 c = n.rgb + f.rgb * (1.0 - n.a);
    float cut = hasCut > 0.5 ? texture(cutTex, nuv).a : n.a;
    vec2 px = uv * area;

    float breath = 0.5 + 0.5 * sin(t * 0.661);
    float cloud = 0.72 + 0.28 * noise(t * 0.13 + 7.0);
    float b = mix(0.5, 1.0, breath) * cloud;

    vec2 nrm = vec2(dir.y, -dir.x);
    vec2 rel = px - origin;
    float along = dot(rel, dir);
    float across = dot(rel, nrm);
    float v = along / max(len, 1.0);
    float ends = smoothstep(0.0, 0.18, v) * (1.0 - smoothstep(0.78, 1.04, v));
    float spread = 1.0 + 0.35 * clamp(v, 0.0, 1.0);
    float rays = 0.62 + 0.38 * noise(across * 0.045 + t * 0.03) * (0.55 + 0.45 * noise(across * 0.13 - t * 0.05 + 3.0));
    float beam = band(across, beams.x * spread, widths.x * spread) * (0.88 + 0.12 * sin(t * 0.37))
               + band(across, beams.y * spread, widths.y * spread) * (0.88 + 0.12 * sin(t * 0.29 + 2.1)) * 0.8
               + band(across, beams.z * spread, widths.z * spread) * (0.88 + 0.12 * sin(t * 0.43 + 4.2)) * 0.6;
    float shaft = beam * rays * ends;

    float sp = 0.0;
    for (int i = 0; i < 12; i++) {
        float fi = float(i);
        vec2 h = hash2(fi + 1.0);
        vec2 g = hash2(fi + 31.0);
        vec2 p = h * area + vec2(2.0 + 4.0 * g.x, 5.0 + 5.0 * g.y) * t;
        p += 10.0 * vec2(sin(t * (0.21 + 0.2 * g.y) + fi), cos(t * (0.17 + 0.15 * g.x) + fi * 1.7));
        p = mod(p, area);
        float tw = 0.5 + 0.5 * sin(t * (1.1 + g.x) + fi * 2.7);
        vec2 d = px - p;
        sp += (exp(-dot(d, d) / 1.4) + 0.25 * exp(-dot(d, d) / 9.0)) * tw;
    }

    vec2 q = (px - pool.xy) / max(pool.zw, vec2(1.0));
    float pl = exp(-dot(q, q) * 1.5);

    float lift = clamp(air * shaft * b + sheen * pl * b + dust * sp * beam * ends * (0.4 + 0.6 * b), 0.0, 1.0);
    vec3 add = moon.rgb * lift * (1.0 - c) * (1.0 - cut);

    vec2 e = abs(uv - 0.5) * 2.0;
    float m = (1.0 - smoothstep(0.86, 1.0, e.x)) * (1.0 - smoothstep(0.86, 1.0, e.y));
    fragColor = vec4(add * m, 0.0) * qt_Opacity;
}
