VARYING vec2 vUV;
VARYING float vAge;

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

void MAIN()
{
    float age = t - seatT(UV1, COLOR.b);
    vUV = UV0;
    vAge = age;
    POSITION = rb > 0.5 && age >= 0.0 ? MODELVIEWPROJECTION_MATRIX * vec4(VERTEX, 1.0) : vec4(2.0, 2.0, 2.0, 1.0);
}
