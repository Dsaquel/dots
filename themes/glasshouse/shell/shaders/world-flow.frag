#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 farMap;
    vec4 nearMap;
    float hasNear;
    float hasFloor;
    float t;
    float seed;
    vec2 area;
    float tilt;
    float back;
    float front;
    float radius;
    float lo;
    float hi;
    float amp;
    float cell;
    float speed;
    float gain;
    vec4 tint;
    vec4 fade;
    float aspect;
    vec4 pa;
    vec4 pb;
    vec4 pc;
    float sides;
    float soft;
};
layout(binding = 1) uniform sampler2D farTex;
layout(binding = 2) uniform sampler2D nearTex;
layout(binding = 3) uniform sampler2D floorTex;

const vec3 LUMA = vec3(0.299, 0.587, 0.114);

vec3 room(vec2 uv)
{
    if (hasNear > 0.5)
        return texture(nearTex, clamp(nearMap.xy + uv * nearMap.zw, 0.0, 1.0)).rgb;
    return texture(farTex, clamp(farMap.xy + uv * farMap.zw, 0.0, 1.0)).rgb;
}

vec3 ring(vec2 uv, vec2 px, out vec3 mean)
{
    vec3 s = vec3(0.0);
    vec2 z = vec2(0.0);
    float tot = 0.0;
    for (int i = 0; i < 8; i++) {
        float a = float(i) * 0.785398 + 0.39;
        vec2 o = vec2(cos(a), sin(a)) * px;
        vec3 p = room(uv + o) + room(uv + o * 0.5);
        float l = dot(p, LUMA);
        z += l * vec2(cos(2.0 * a), sin(2.0 * a));
        tot += l;
        s += p;
    }
    mean = s / 16.0;
    float th = 0.5 * atan(z.y, z.x);
    return vec3(cos(th), sin(th), length(z) / max(tot, 1e-3));
}

vec3 line(vec3 c, vec3 mean, float lie, float gate)
{
    float k = 1.0 / (0.05 + dot(mean, LUMA));
    vec3 hp = c - mean;
    return max(hp, vec3(0.0)) * smoothstep(gate, hi, dot(hp, LUMA) * k) * lie;
}

float hash(vec2 p)
{
    return fract(sin(dot(p, vec2(127.1, 311.7)) + seed * 17.3) * 43758.5453);
}

float noise(vec2 p)
{
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
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
    float m = inside(uv) * smoothstep(0.0, fade.x, uv.x) * (1.0 - smoothstep(1.0 - fade.y, 1.0, uv.x)) * smoothstep(0.0, fade.z, uv.y) * (1.0 - smoothstep(1.0 - fade.w, 1.0, uv.y));
    if (m > 0.002 && hasFloor > 0.5)
        m *= texture(floorTex, clamp(nearMap.xy + uv * nearMap.zw, 0.0, 1.0)).r;
    if (m <= 0.002) {
        fragColor = vec4(0.0);
        return;
    }

    vec2 c0 = (uv - 0.5) * area;
    float cs = cos(tilt);
    float sn = sin(tilt);
    vec2 r = vec2(cs * c0.x + sn * c0.y, -sn * c0.x + cs * c0.y);
    float v = clamp(r.y / max(area.y, 1.0) + 0.5, -0.3, 1.3);
    float near = max(mix(back, front, v), 0.08);
    float along = r.x / near / max(cell, 1.0);
    float deep = 3.0 / near;
    float time = t * speed;

    float ph = along * 1.4 - time * 1.2 + 1.4 * noise(vec2(deep * 0.7 + 3.0, time * 0.05));
    float crest = 0.5 + 0.5 * sin(ph);
    float swell = pow(crest, 6.0);
    float slope = cos(ph) * crest * crest * crest;

    float sway = sin(along * 1.7 + deep * 2.3 - time * 1.3) * 0.65 + sin(along * 3.1 - deep * 1.4 - time * 2.1 + 1.7) * 0.35;
    vec2 w = vec2(0.0, (sway * (0.5 + swell) + slope * 1.1) * amp * near);
    vec2 d = vec2(cs * w.x - sn * w.y, sn * w.x + cs * w.y) / max(area, vec2(1.0));

    vec2 px = radius / max(area, vec2(1.0));
    vec2 dir = vec2(cs, sn);
    vec3 c = room(uv);
    vec3 mean;
    vec3 o = ring(uv, px, mean);
    float lie = smoothstep(0.005, 0.02, o.z) * smoothstep(0.55, 0.85, abs(dot(o.xy, dir)));
    vec3 now = line(c, mean, lie, lo);
    vec3 moved = line(room(uv + d), mean, lie, lo * 0.7);

    float lane = noise(vec2(along * 0.35, deep * 4.0));
    float run = fract(along * 0.5 - time * 0.55 + lane * 3.0);
    float pulse = smoothstep(0.0, 0.25, run) * (1.0 - smoothstep(0.35, 0.7, run)) * smoothstep(0.25, 0.6, lane);

    float carry = pulse * 0.5 + swell * 1.6;
    vec3 lit = moved * (1.0 + carry * gain);
    vec3 glow = tint.rgb * dot(moved, LUMA) * carry * gain * 0.6;
    vec3 outc = c - now + lit + glow;

    fragColor = vec4(min(outc, vec3(1.0)) * m, m) * qt_Opacity;
}
