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
    float aspect;
    float tilt;
    float back;
    float front;
    vec2 area;
    float cellX;
    float zScale;
    float speed;
    float gain;
    vec4 tint;
    vec4 fade;
    vec4 pa;
    vec4 pb;
    vec4 pc;
    float sides;
    float soft;
    float hasFloor;
};
layout(binding = 1) uniform sampler2D farTex;
layout(binding = 2) uniform sampler2D nearTex;
layout(binding = 3) uniform sampler2D floorTex;

float caustic(vec2 q, float time)
{
    vec2 p = mod(q * 6.28318, 6.28318) - 250.0;
    vec2 i = p;
    float c = 1.0;
    float inten = 0.005;
    for (int n = 0; n < 4; n++) {
        float tt = time * (1.0 - 3.5 / float(n + 1));
        i = p + vec2(cos(tt - i.x) + sin(tt + i.y), sin(tt - i.y) + cos(tt + i.x));
        float sx = sin(i.x + tt);
        float cy = cos(i.y + tt);
        sx = (sx < 0.0 ? -1.0 : 1.0) * max(abs(sx), 1e-4);
        cy = (cy < 0.0 ? -1.0 : 1.0) * max(abs(cy), 1e-4);
        c += 1.0 / max(length(vec2(p.x / (sx / inten), p.y / (cy / inten))), 1e-4);
    }
    c /= 4.0;
    c = 1.17 - pow(abs(c), 1.4);
    return min(pow(abs(c), 8.0), 1.5);
}

float edge(vec2 uv, vec2 a, vec2 b)
{
    vec2 e = (b - a) * vec2(aspect, 1.0);
    float l = length(e);
    if (l < 1e-5)
        return 1.0;
    vec2 p = (uv - a) * vec2(aspect, 1.0);
    return smoothstep(0.0, soft, (e.x * p.y - e.y * p.x) / l);
}

float inside(vec2 uv)
{
    if (sides < 3.0)
        return 1.0;
    vec2 last = sides > 5.5 ? pc.zw : (sides > 4.5 ? pc.xy : (sides > 3.5 ? pb.zw : pb.xy));
    float m = edge(uv, pa.xy, pa.zw) * edge(uv, pa.zw, pb.xy) * edge(uv, last, pa.xy);
    if (sides > 3.5)
        m *= edge(uv, pb.xy, pb.zw);
    if (sides > 4.5)
        m *= edge(uv, pb.zw, pc.xy);
    if (sides > 5.5)
        m *= edge(uv, pc.xy, pc.zw);
    return m;
}

void main()
{
    vec2 uv = qt_TexCoord0;
    vec4 f = texture(farTex, clamp(farMap.xy + uv * farMap.zw, 0.0, 1.0));
    vec4 n = texture(nearTex, clamp(nearMap.xy + uv * nearMap.zw, 0.0, 1.0)) * hasNear;

    vec2 c0 = (uv - 0.5) * area;
    float cs = cos(tilt);
    float sn = sin(tilt);
    vec2 r = vec2(cs * c0.x + sn * c0.y, -sn * c0.x + cs * c0.y);
    float v = clamp(r.y / max(area.y, 1.0) + 0.5, -0.3, 1.3);
    float depth = 1.0 / max(mix(back, front, v), 0.08);
    vec2 fl = vec2(r.x * depth / max(cellX, 1.0), depth * zScale);
    float time = t * speed;
    float a = caustic(fl + vec2(0.0, time * 0.05), time);
    float b = caustic(fl * 1.31 + vec2(2.7, 1.3), time * 0.83 + 3.0);
    float cst = a * 0.65 + b * 0.5;

    float lum = dot(f.rgb, vec3(0.299, 0.587, 0.114));
    float onFloor = hasFloor > 0.5 ? texture(floorTex, clamp(farMap.xy + uv * farMap.zw, 0.0, 1.0)).r : 1.0;
    vec3 add = f.rgb * (1.0 - n.a) * gain * cst * tint.rgb * smoothstep(0.12, 0.6, lum) * onFloor;

    float m = inside(uv) * smoothstep(0.0, fade.x, uv.x) * (1.0 - smoothstep(1.0 - fade.y, 1.0, uv.x)) * smoothstep(0.0, fade.z, uv.y) * (1.0 - smoothstep(1.0 - fade.w, 1.0, uv.y));
    fragColor = vec4(add * m, 0.0) * qt_Opacity;
}
