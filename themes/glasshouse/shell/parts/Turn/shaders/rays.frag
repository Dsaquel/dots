void MAIN()
{
    vec2 uv = INPUT_UV;
    vec3 base = texture(INPUT, uv).rgb;
    if (power <= 0.0 && impAmt <= 0.0) {
        FRAGCOLOR = vec4(base, 1.0);
        return;
    }
    vec2 d = (uv - center) * (density / 48.0);
    vec3 acc = vec3(0.0);
    float w = 1.0;
    vec2 p = uv;
    for (int i = 0; i < 48; i++) {
        p -= d;
        vec3 s = texture(INPUT, p).rgb;
        acc += max(s - vec3(threshold), vec3(0.0)) * w;
        w *= falloff;
    }
    vec3 c = base + acc * (power / 48.0) * tint.rgb;
    float lum = dot(min(c, vec3(1.0)), vec3(0.299, 0.587, 0.114));
    float k = smoothstep(0.16, 0.40, lum);
    if (impInv > 0.5)
        k = 1.0 - k;
    vec3 two = mix(impInk.rgb, impGold.rgb, k);
    FRAGCOLOR = vec4(mix(c, two, impAmt), 1.0);
}
