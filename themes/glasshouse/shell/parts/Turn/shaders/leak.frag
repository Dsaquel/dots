VARYING vec2 vUV;
void MAIN()
{
    vec2 p = (vUV - 0.5) * vec2(1.7778, 1.0) * 2.0;
    float r = length(p);
    float g = 0.55 + 1.6 * exp(-r * r * 3.0);
    FRAGCOLOR = vec4(tint.rgb * g * power, 0.0);
}
