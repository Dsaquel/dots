#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 texel;
    vec2 light;
    float lightZ;
    float depth;
    float shininess;
    float metal;
    float aspect;
    vec4 base;
    vec4 hi;
    vec4 low;
    vec4 sky;
    vec4 rect;
    float glint;
    float glintWidth;
    float glintGain;
    vec4 glintColor;
};
layout(binding = 1) uniform sampler2D heightMap;

vec3 lit(vec2 q, float h) {
    vec2 e = 0.5 * texel;
    float tl = texture(heightMap, q - e).r;
    float tr = texture(heightMap, q + vec2(e.x, -e.y)).r;
    float bl = texture(heightMap, q + vec2(-e.x, e.y)).r;
    float br = texture(heightMap, q + e).r;
    float hx = tr + br - tl - bl;
    float hy = bl + br - tl - tr;
    vec3 n = normalize(vec3(-hx * depth, hy * depth, 1.0));
    vec3 p = vec3(q.x * aspect, 1.0 - q.y, h * 0.015);
    vec3 lp = vec3(light.x * aspect, 1.0 - light.y, lightZ);
    vec3 L = normalize(lp - p);
    vec3 H = normalize(L + vec3(0.0, 0.0, 1.0));
    float diff = max(dot(n, L), 0.0);
    float spec = pow(max(dot(n, H), 0.0), max(shininess, 1.0));
    vec3 R = reflect(vec3(0.0, 0.0, -1.0), n);
    float env = clamp(0.5 + 0.5 * R.y, 0.0, 1.0);
    vec3 envc = mix(low.rgb, sky.rgb, smoothstep(0.2, 0.9, env));
    float ao = mix(0.55, 1.0, smoothstep(0.0, 0.6, h));
    vec3 col = base.rgb * (0.22 + 0.78 * diff) * ao;
    col = mix(col, envc * base.rgb * 1.6, metal * 0.35 * (1.0 - diff * 0.5));
    col += hi.rgb * spec * (0.35 + 0.9 * metal);
    vec2 g = rect.xy + q * rect.zw;
    float s = g.x + (1080.0 - g.y) * 0.42;
    float d = (s - glint) / max(glintWidth, 1.0);
    float band = exp(-d * d) + 0.35 * exp(-d * d * 0.12);
    col += glintColor.rgb * band * glintGain * (0.3 + 0.5 * diff + 1.4 * spec) * smoothstep(0.02, 0.45, h);
    return col;
}

void main() {
    vec2 uv = qt_TexCoord0;
    vec4 t = texture(heightMap, uv);
    float a = t.a;
    if (a < 0.003) { fragColor = vec4(0.0); return; }
    vec2 o = 0.25 * texel;
    vec3 col = 0.25 * (lit(uv - o, t.r) + lit(uv + vec2(o.x, -o.y), t.r) + lit(uv + vec2(-o.x, o.y), t.r) + lit(uv + o, t.r));
    fragColor = vec4(col * a, a) * qt_Opacity;
}
