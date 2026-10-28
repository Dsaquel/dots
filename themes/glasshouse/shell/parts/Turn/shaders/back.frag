VARYING vec2 vUV;
vec3 twoTone(vec3 c, float inv)
{
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    float k = smoothstep(thrA, thrB, lum);
    if (inv > 0.5)
        k = 1.0 - k;
    vec3 t = mix(ink.rgb, gold.rgb, k);
    return mix(t, hiCol.rgb, smoothstep(thrB + 0.16, 1.0, lum) * (1.0 - inv));
}
void MAIN()
{
    vec2 iuv = vec2(vUV.x, 1.0 - vUV.y);
    vec2 px = vec2(vUV.x * 1920.0, (1.0 - vUV.y) * 1080.0);
    vec3 a = texture(room, iuv).rgb;
    vec3 b = texture(vid, (px - vframe.xy) / vframe.zw).rgb;
    vec3 c = mix(mix(a, b, mixv), texture(roomA, iuv).rgb, mixr);
    float d = length(px - center);
    float frozen = (1.0 - smoothstep(stopR - 28.0, stopR, d)) * smoothstep(relR - 40.0, relR, d);
    c = mix(c, twoTone(c, 0.0), frozen);
    c = mix(c, c * coolTint.rgb, cool);
    c *= 1.0 - dim;

    FRAGCOLOR = vec4(c * bright, 1.0);
}
