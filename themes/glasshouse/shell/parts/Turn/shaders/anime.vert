VARYING vec2 vUV;
VARYING vec3 vN;
VARYING float vSeed;
VARYING float vDist;
VARYING float vKind;
VARYING float vPane;
VARYING float vCracked;
VARYING float vB;
VARYING float vLit;
VARYING vec2 vLocal;
VARYING float vAng;

vec3 hash3(float n)
{
    return fract(sin(vec3(n, n + 1.7, n + 3.3)) * vec3(43758.5453, 22578.1459, 19642.3490));
}

float seatT(vec2 cpx, float kind)
{
    vec2 d = cpx - center;
    float r = length(d);
    float g = kind < 0.5 ? (r < 90.0 ? 0.0 : (r < 200.0 ? 1.0 : (r < 380.0 ? 2.0 : (r < 450.0 ? 3.0 : 4.0))))
                         : (r < 610.0 ? 5.0 : (r < 820.0 ? 6.0 : 7.0));
    float ph = fract(atan(d.y, d.x) / 6.2831853 + rbA0 + 1.0);
    float p = clamp(g + ph, 0.0, 8.0);
    return landT - rbSpan * pow(p / 8.0, rbK);
}

mat3 rotm(vec3 a, float g)
{
    float s = sin(g), c = cos(g), oc = 1.0 - c;
    return mat3(oc * a.x * a.x + c, oc * a.x * a.y + a.z * s, oc * a.z * a.x - a.y * s,
                oc * a.x * a.y - a.z * s, oc * a.y * a.y + c, oc * a.y * a.z + a.x * s,
                oc * a.z * a.x + a.y * s, oc * a.y * a.z - a.x * s, oc * a.z * a.z + c);
}

void MAIN()
{
    float seed = COLOR.r;
    float dist = COLOR.g;
    float size = TANGENT.z;
    vec3 h = hash3(seed * 157.31 + 3.1);
    vec3 h2 = hash3(seed * 311.77 + 9.4);
    vec3 c = vec3(UV1.x - 960.0, 540.0 - UV1.y, 0.0);
    vec2 imp = vec2(impact.x - 960.0, 540.0 - impact.y);
    vec2 dir = normalize(c.xy - imp + (h.xy - 0.5) * 40.0 + vec2(0.001, 0.0));
    vec3 axis = normalize(h2 - 0.5 + vec3(0.0, 0.0, 0.25));
    float slow = 1.0 / (0.6 + 0.8 * size);

    float cracked = front > 0.0 ? smoothstep(dist - 0.03, dist + 0.05, front) * (1.0 - COLOR.b) : 0.0;
    float ang = cracked * (h.z - 0.5) * 0.03 + beatE * (h.x - 0.5) * 0.04 * cracked;
    vec3 off = vec3(0.0, 0.0, cracked * (h.y - 0.5) * 8.0);

    off.xy += dir * sep * (1.5 + 4.0 * dist);
    off.z += sep * (h.y - 0.5) * 16.0 + bulge * (20.0 + 30.0 * (1.0 - dist));
    ang += sep * (h.z - 0.5) * 0.05;

    float tb = burstT + dist * spread;
    float u = max(0.0, t - tb);
    float hang = min(u, max(0.0, blastT - tb));
    float pop = 1.0 - exp(-u / 0.05);
    off.xy += dir * (pop * (20.0 + 50.0 * (1.0 - dist)) + hang * (60.0 + 110.0 * h.x) * slow);
    off.z += pop * (30.0 + 70.0 * h.y) + hang * (180.0 + 560.0 * h.z * (1.0 - 0.5 * dist));
    ang += (pop * 0.14 + hang * (0.7 + 1.5 * h.x) * slow) * (h.y > 0.5 ? 1.0 : -1.0);
    float b = max(0.0, t - blastT - dist * 0.08);
    off.xy += dir * (b * b * (2600.0 + 2400.0 * h.x) + b * (520.0 + 420.0 * h.y));
    off.z += b * b * (h.z > 0.7 ? 6500.0 : 1500.0 * h.z) + b * 260.0;
    ang += b * (3.5 + 7.0 * h.y) * slow * (h.x > 0.5 ? 1.0 : -1.0);

    float live = 1.0;
    if (t >= rbFrom) {
        float tau = seatT(UV1, COLOR.b) - t;
        live = tau > 0.0 && tau < rbDur ? 1.0 : 0.0;
        float tA = rbDur - rbSnap - rbHover;
        float kh = tau < rbSnap ? rbHold * tau / rbSnap : (tau < rbSnap + rbHover ? rbHold + (1.0 - rbHold) * (tau - rbSnap) / rbHover : 1.0);
        float ka = clamp((tau - rbSnap - rbHover) / tA, 0.0, 1.0);
        ka *= ka;
        float r = length(UV1 - center);
        vec3 far = vec3(dir * (max(0.0, 1900.0 - r) * (0.9 + 0.3 * h.x) + 300.0), 300.0 + 600.0 * h.z);
        vec3 hov = vec3(dir * (14.0 + 26.0 * h.y), 26.0 + 44.0 * h.z);
        off = far * ka + hov * kh;
        ang = (2.0 + 3.0 * h.y) * slow * (h.x > 0.5 ? 1.0 : -1.0) * ka + (0.16 + 0.18 * h.x) * (h.y > 0.5 ? 1.0 : -1.0) * kh;
        cracked = 0.0;
    }

    mat3 R = rotm(axis, ang);
    vec3 p = R * (VERTEX - c) + c + off;
    vN = R * vec3(0.0, 0.0, 1.0);
    vec3 en = R * vec3(TANGENT.xy, 0.0);
    vec2 L2 = normalize(vec2(-0.55, 0.83));
    float e2 = length(en.xy);
    vLit = e2 > 0.001 ? clamp(dot(en.xy / e2, L2), 0.0, 1.0) : 0.0;
    vB = NORMAL.x;
    vLocal = (VERTEX - c).xy;
    vAng = ang;
    vUV = UV0;
    vSeed = seed;
    vDist = dist;
    vKind = COLOR.b;
    vPane = COLOR.a;
    vCracked = cracked;
    POSITION = live > 0.5 ? MODELVIEWPROJECTION_MATRIX * vec4(p, 1.0) : vec4(2.0, 2.0, 2.0, 1.0);
}
