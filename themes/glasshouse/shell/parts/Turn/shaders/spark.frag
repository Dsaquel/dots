VARYING vec2 vC;
VARYING float vA;
VARYING float vG;
void MAIN()
{
    float r2 = dot(vC, vC);
    float core = exp(-r2 * 6.0);
    float halo = exp(-r2 * 1.6) * 0.35;
    vec3 c = mix(warm.rgb, hot.rgb, core) * (core * 2.4 + halo) * vA;
    FRAGCOLOR = vec4(c, 0.0);
}
