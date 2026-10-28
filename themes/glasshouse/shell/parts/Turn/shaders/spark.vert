VARYING vec2 vC;
VARYING float vA;
VARYING float vG;

vec3 hash3(float n)
{
    return fract(sin(vec3(n, n + 1.7, n + 3.3)) * vec3(43758.5453, 22578.1459, 19642.3490));
}

void MAIN()
{
    float seed = COLOR.r;
    float grp = COLOR.g;
    vec3 h = hash3(seed * 97.13 + 1.9);
    vec2 s = vec2(UV1.x - 960.0, 540.0 - UV1.y);
    vec2 c = vec2(impact.x - 960.0, 540.0 - impact.y);
    vec3 p = vec3(s, 30.0);
    float size = 0.0;
    float a = 0.0;
    if (grp < 0.5) {
        float u = (t - chargeOff - COLOR.b) / COLOR.a;
        if (u > 0.0 && u < 1.0) {
            vec2 d = s - c;
            float r = length(d) * pow(1.0 - u, 1.6);
            float ang = atan(d.y, d.x) + u * (1.4 + 1.2 * h.x) * (h.y > 0.5 ? 1.0 : -1.0);
            p = vec3(c + r * vec2(cos(ang), sin(ang)), 70.0);
            size = (1.6 + 2.6 * h.z) * (0.4 + u);
            a = smoothstep(0.0, 0.15, u) * (1.0 - smoothstep(0.7, 0.95, u)) * 1.3 * charge;
        }
    } else if (grp < 1.5) {
        float u = t - burstT - COLOR.b;
        if (u > 0.0 && u < COLOR.a) {
            float ang = h.x * 6.2832;
            float sp = 700.0 + 2400.0 * h.y * h.y;
            float k = 3.2;
            float dd = sp * (1.0 - exp(-k * u)) / k;
            p = vec3(s + dd * vec2(cos(ang), sin(ang)) + vec2(0.0, -260.0 * u * u), 60.0 + 900.0 * (h.z - 0.3) * u);
            size = 1.6 + 4.2 * h.z * (1.0 - u / COLOR.a);
            a = (1.0 - u / COLOR.a) * 0.85;
        }
    } else if (grp > 2.5) {
        float dd = length(s - c);
        float born = dd / 1400.0 * 0.3;
        float rel = relT + dd / 1400.0 * 0.35;
        if (t > born && t < rel + 0.5) {
            p = vec3(s + vec2(0.0, (t - born) * 6.0 * (h.x - 0.5)), COLOR.b);
            size = (0.8 + 1.9 * h.y) * COLOR.a;
            a = (0.55 + 0.45 * sin(t * (2.0 + 3.0 * h.x) + h.y * 30.0)) * 1.3 * smoothstep(born, born + 0.08, t) * (1.0 - smoothstep(rel, rel + 0.45, t)) * motes;
        }
    } else {
        float u = t - burstT - COLOR.b;
        if (u > 0.0 && u < 3.0) {
            vec2 dir = normalize(s - c + (h.xy - 0.5) * 80.0 + vec2(0.001, 0.0));
            float hang = min(u, blastT - burstT);
            float b = max(0.0, t - blastT - h.z * 0.1);
            p = vec3(s + dir * (hang * (40.0 + 80.0 * h.x) + b * b * (2600.0 + 2600.0 * h.y) + b * 400.0), 20.0 + hang * 260.0 * h.z + b * b * 5000.0 * h.x);
            size = 0.9 + 1.8 * h.y;
            a = (0.5 + 0.5 * sin(t * (18.0 + 30.0 * h.x) + h.y * 40.0)) * 1.6 * smoothstep(0.0, 0.05, u) * (1.0 - smoothstep(0.4, 0.9, b));
        }
    }
    vC = UV0;
    vA = a;
    vG = grp;
    POSITION = MODELVIEWPROJECTION_MATRIX * vec4(p + vec3(UV0 * size * 2.2, 0.0), 1.0);
}
