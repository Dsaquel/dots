#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 area;
    vec4 s0;
    vec4 s1;
    vec4 s2;
    vec4 s3;
    vec4 inner;
    vec4 outer;
    float power;
};

vec3 star(vec2 px, vec4 s)
{
    if (s.z < 0.0)
        return vec3(0.0);
    float life = sin(clamp(s.z, 0.0, 1.0) * 3.14159);
    float k = life * life;
    float a = 0.35 * s.z - 0.2;
    vec2 d = px - s.xy;
    vec2 r = vec2(cos(a) * d.x - sin(a) * d.y, sin(a) * d.x + cos(a) * d.y) / max(s.w * (0.55 + 0.45 * life), 0.5);
    float thin = exp(-abs(r.y) * 7.0) * exp(-r.x * r.x * 0.32) + exp(-abs(r.x) * 7.0) * exp(-r.y * r.y * 0.32);
    vec2 r2 = vec2(r.x + r.y, r.x - r.y) * 0.7071;
    float diag = exp(-abs(r2.y) * 12.0) * exp(-r2.x * r2.x * 2.2) + exp(-abs(r2.x) * 12.0) * exp(-r2.y * r2.y * 2.2);
    float core = exp(-dot(r, r) * 10.0);
    float glow = exp(-dot(r, r) * 0.9);
    vec3 halo = outer.rgb * (glow * 0.55 + (thin + diag) * 0.35);
    return (inner.rgb * (thin * 0.85 + core * 1.3 + diag * 0.3) + halo) * k;
}

void main()
{
    vec2 px = qt_TexCoord0 * area;
    vec3 c = star(px, s0) + star(px, s1) + star(px, s2) + star(px, s3);
    fragColor = vec4(c * power, 0.0) * qt_Opacity;
}
