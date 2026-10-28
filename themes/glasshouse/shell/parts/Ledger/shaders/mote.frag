VARYING vec2 vC;
VARYING float vA;
VARYING vec2 vSrc;
VARYING float vWarm;

void MAIN()
{
    float r2 = dot(vC, vC) * 4.0;
    float core = exp(-r2 * 5.0);
    float halo = exp(-r2 * 1.5) * 0.35;
    vec3 own = back > 0.5 ? vec3(0.93, 0.86, 0.72) : texture(still, vSrc).rgb + vec3(0.04);
    vec3 c = mix(own, warm.rgb, vWarm);
    FRAGCOLOR = vec4(c * (core * 1.6 + halo) * vA, 0.0);
}
