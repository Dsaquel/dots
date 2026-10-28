VARYING vec2 vUV;
void MAIN()
{
    vec2 d = vUV - 0.5;
    float r = length(d) * 2.0;
    float g = exp(-r * r * 9.0) * 1.6 + exp(-r * 3.2) * 0.5;
    FRAGCOLOR = vec4(tint.rgb * g * power, 0.0);
}
