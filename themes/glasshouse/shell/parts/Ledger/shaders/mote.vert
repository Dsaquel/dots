VARYING vec2 vC;
VARYING float vA;
VARYING vec2 vSrc;
VARYING float vWarm;

float hash(vec2 p)
{
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float vnoise(vec2 p)
{
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

vec4 win(int i)
{
    if (i == 0) return w0;
    if (i == 1) return w1;
    if (i == 2) return w2;
    if (i == 3) return w3;
    if (i == 4) return w4;
    if (i == 5) return w5;
    if (i == 6) return w6;
    return w7;
}

float start(int i)
{
    return i < 4 ? sA[i] : sB[i - 4];
}

float order(vec4 r, vec2 p)
{
    vec2 hole = clamp(lamp, r.xy, r.xy + r.zw);
    vec2 far = vec2(hole.x - r.x < r.x + r.z - hole.x ? r.x + r.z : r.x, hole.y - r.y < r.y + r.w - hole.y ? r.y + r.w : r.y);
    return clamp(0.88 * length(p - hole) / max(length(far - hole), 1.0) + 0.09 * vnoise(p / 70.0) + 0.03 * vnoise(p / 11.0), 0.0, 1.0);
}

vec2 path(vec2 o, vec2 j, float u)
{
    vec2 to = lamp - o;
    float len = max(length(to), 1.0);
    vec2 n = vec2(-to.y, to.x) / len;
    if (n.y > 0.0)
        n = -n;
    vec2 c = o + to * 0.45 + n * len * (0.16 + 0.22 * j.y) + vec2(0.0, -12.0);
    vec2 b = mix(mix(o, c, u), mix(c, lamp, u), u);
    float a = (j.x > 0.5 ? 1.0 : -1.0) * 1.1 * sin(3.14159 * u) * u;
    vec2 rel = b - lamp;
    return lamp + vec2(cos(a) * rel.x - sin(a) * rel.y, sin(a) * rel.x + cos(a) * rel.y);
}

void MAIN()
{
    float cx = mod(float(INSTANCE_INDEX), grid.x);
    float cy = floor(float(INSTANCE_INDEX) / grid.x);
    vec2 j = vec2(hash(vec2(cx, cy) + 0.37), hash(vec2(cy, cx) + 7.13));
    vec2 o = (vec2(cx, cy) + j) * pitch;
    int hit = -1;
    for (int i = 0; i < 8; i++) {
        vec4 r = win(i);
        if (r.z > 0.0 && o.x >= r.x && o.y >= r.y && o.x <= r.x + r.z && o.y <= r.y + r.w) {
            hit = i;
            break;
        }
    }
    vec2 pos = vec2(-99999.0);
    vec2 along = vec2(1.0, 0.0);
    float stretch = 1.0;
    float size = 0.0;
    vA = 0.0;
    vWarm = 0.0;
    if (hit >= 0 && j.y < 0.5) {
        float life = mlife * (0.8 + 0.4 * j.x);
        float at = start(hit) + order(win(hit), o) * span;
        float e = back > 0.5 ? (t - at + life) / life : (t - at) / life;
        if (e > 0.0 && e < 1.0) {
            float s = e * e * (3.0 - 2.0 * e);
            float u = back > 0.5 ? 1.0 - s : s;
            float du = back > 0.5 ? -0.02 : 0.02;
            pos = path(o, j, u);
            vec2 v = path(o, j, clamp(u + du, 0.0, 1.0)) - pos;
            float sp = length(v);
            along = sp > 0.001 ? v / sp : along;
            stretch = 1.0 + min(sp * 0.1, 1.2);
            size = mix(2.4, 1.1, u) * (0.75 + 0.5 * j.x);
            vA = smoothstep(0.0, 0.12, e) * (1.0 - smoothstep(0.82, 1.0, e)) * (1.0 - smoothstep(0.62, 1.0, u)) * gain * (0.6 + 0.8 * j.y);
            vWarm = back > 0.5 ? smoothstep(0.2, 0.9, u) : smoothstep(0.0, 0.5, u);
        }
    }
    vec2 cr = (UV0 - 0.5) * size * 3.0;
    vec2 q = pos + along * cr.x * stretch + vec2(-along.y, along.x) * cr.y;
    vC = UV0 - 0.5;
    vSrc = o / res;
    POSITION = VIEWPROJECTION_MATRIX * vec4(q.x - res.x * 0.5, res.y * 0.5 - q.y, 0.0, 1.0);
}
