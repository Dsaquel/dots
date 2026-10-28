VARYING vec2 vUV;
float hash(vec2 p)
{
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}
void MAIN()
{
    vec4 ck = texture(cracks, vUV);
    float dpx = ck.r * 24.0;
    float lead = step(0.75, ck.b);
    float line = (exp(-dpx * dpx / 1.6) + exp(-dpx / 4.0) * 0.12) * lead;
    float n = hash(floor(vUV * vec2(96.0, 54.0)));
    float keep = 1.0 - smoothstep(n - 0.08, n, dissolve);
    FRAGCOLOR = vec4(tint.rgb * line * power * keep, 0.0);
}
