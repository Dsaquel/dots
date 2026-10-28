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
    vec3 h = hash3(seed * 97.13 + 1.9);
    vec2 s = vec2(UV1.x - 960.0, 540.0 - UV1.y);
    float u = t - landT - COLOR.b;
    vec3 p = vec3(s, 30.0);
    float size = 0.0;
    float a = 0.0;
    if (u > 0.0 && u < COLOR.a) {
        float ang = h.x * 6.2832;
        float sp = COLOR.g < 0.5 ? 520.0 + 1500.0 * h.y * h.y : 30.0 + 90.0 * h.y;
        float dd = sp * (1.0 - exp(-4.0 * u)) / 4.0;
        float life = u / COLOR.a;
        p = vec3(s + dd * vec2(cos(ang), sin(ang)) + vec2(0.0, -220.0 * u * u), 40.0 + 260.0 * h.z * u);
        size = (COLOR.g < 0.5 ? 1.5 + 2.8 * h.z : 1.0 + 1.6 * h.z) * (1.0 - 0.6 * life);
        a = (1.0 - smoothstep(0.55, 1.0, life)) * (COLOR.g < 0.5 ? 1.0 : 0.6 + 0.4 * sin(u * (20.0 + 25.0 * h.x) + h.y * 30.0));
    }
    vC = UV0;
    vA = a;
    vG = COLOR.g;
    POSITION = MODELVIEWPROJECTION_MATRIX * vec4(p + vec3(UV0 * size * 2.2, 0.0), 1.0);
}
