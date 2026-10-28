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
    float sweep;
    float aspect;
    vec4 base;
    vec4 hi;
    vec4 low;
    vec4 sky;
};
layout(binding = 1) uniform sampler2D heightMap;

void main() {
    vec2 uv = qt_TexCoord0;
    vec4 t = texture(heightMap, uv);
    float a = t.a;
    if (a < 0.003) { fragColor = vec4(0.0); return; }
    float h00 = texture(heightMap, uv - texel).r;
    float h10 = texture(heightMap, uv + vec2(0.0, -texel.y)).r;
    float h20 = texture(heightMap, uv + vec2(texel.x, -texel.y)).r;
    float h01 = texture(heightMap, uv + vec2(-texel.x, 0.0)).r;
    float h21 = texture(heightMap, uv + vec2(texel.x, 0.0)).r;
    float h02 = texture(heightMap, uv + vec2(-texel.x, texel.y)).r;
    float h12 = texture(heightMap, uv + vec2(0.0, texel.y)).r;
    float h22 = texture(heightMap, uv + texel).r;
    float hx = 0.25 * (h20 + 2.0 * h21 + h22 - h00 - 2.0 * h01 - h02);
    float hy = 0.25 * (h02 + 2.0 * h12 + h22 - h00 - 2.0 * h10 - h20);
    vec3 n = normalize(vec3(-hx * depth, hy * depth, 1.0));
    vec3 p = vec3(uv.x * aspect, 1.0 - uv.y, t.r * 0.015);
    vec3 lp = vec3(light.x * aspect, 1.0 - light.y, lightZ);
    vec3 L = normalize(lp - p);
    vec3 V = vec3(0.0, 0.0, 1.0);
    vec3 H = normalize(L + V);
    float diff = max(dot(n, L), 0.0);
    vec3 dn = abs(dFdx(n)) + abs(dFdy(n));
    float a2 = min(2.0 / (shininess + 2.0) + min(dot(dn, dn), 0.3), 1.0);
    float sh = max(2.0 / a2 - 2.0, 1.0);
    float spec = pow(max(dot(n, H), 0.0), sh) * (sh + 2.0) / (shininess + 2.0);
    vec3 R = reflect(-V, n);
    float env = clamp(0.5 + 0.5 * R.y, 0.0, 1.0);
    vec3 envc = mix(low.rgb, sky.rgb, smoothstep(0.2, 0.9, env));
    float ao = mix(0.55, 1.0, smoothstep(0.0, 0.6, t.r));
    vec3 col = base.rgb * (0.22 + 0.78 * diff) * ao;
    col = mix(col, envc * base.rgb * 1.6, metal * 0.35 * (1.0 - diff * 0.5));
    col += hi.rgb * spec * (0.35 + 0.9 * metal);
    float d = (uv.x * aspect + (1.0 - uv.y) * 0.6) - sweep * (aspect + 0.6);
    col += hi.rgb * exp(-d * d * 180.0) * (0.25 + spec * 1.5) * smoothstep(0.05, 0.5, t.r);
    fragColor = vec4(col * a, a) * qt_Opacity;
}
