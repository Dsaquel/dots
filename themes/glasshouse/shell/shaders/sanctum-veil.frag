#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 shadow;
    vec4 body;
    vec4 light;
    vec4 field;
    vec4 haze;
    float detail;
    float aspect;
};
layout(binding = 1) uniform sampler2D world;
layout(binding = 2) uniform sampler2D broad;

float hash(vec2 p) {
    vec3 q = fract(p.xyx * 0.1031);
    q += dot(q, q.yzx + 33.33);
    return fract((q.x + q.y) * q.z);
}

vec3 ramp(float l) {
    return l < body.a ? mix(shadow.rgb, body.rgb, (l - shadow.a) / (body.a - shadow.a))
                      : mix(body.rgb, light.rgb, (l - body.a) / (light.a - body.a));
}

void main() {
    vec2 uv = qt_TexCoord0;
    const vec3 luma = vec3(0.299, 0.587, 0.114);
    float l = dot(texture(world, uv).rgb, luma);
    float m = dot(texture(broad, uv).rgb, luma);
    float k = field.w * (l - m) / (m + 0.05);
    float t = k * inversesqrt(1.0 + k * k);
    vec2 d = vec2((uv.x - 0.5) * aspect, uv.y - 0.5);
    float v = smoothstep(0.3, 1.1, length(d) * 1.2);
    vec2 h = vec2((uv.x - haze.x) * aspect / haze.z, (uv.y - haze.y) / haze.w);
    float f = mix(field.x, field.y, v) + field.z * exp(-dot(h, h));
    float n = (hash(gl_FragCoord.xy) + hash(gl_FragCoord.xy + vec2(47.0, 17.0)) - 1.0) / 255.0;
    vec3 c = max(ramp(f * (1.0 + detail * t)), vec3(0.0)) + vec3(n);
    fragColor = vec4(c, 1.0) * qt_Opacity;
}
