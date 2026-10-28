VARYING vec2 vUV;
void MAIN()
{
    vec2 p = (vUV - 0.5) * vec2(3840.0, 2160.0);
    float d = length(p);
    float q = (d - radius) / thick;
    float ring = exp(-q * q) * 1.0 + exp(-abs(d - radius) / (thick * 6.0)) * 0.25;
    FRAGCOLOR = vec4(tint.rgb * ring * power, 0.0);
}
