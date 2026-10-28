VARYING vec2 vUV;
void MAIN()
{
    vec4 c = texture(t0, vUV) + texture(t1, vUV) + texture(t2, vUV) + texture(t3, vUV) + texture(t4, vUV)
           + texture(t5, vUV) + texture(t6, vUV) + texture(t7, vUV) + texture(t8, vUV) + texture(t9, vUV);
    FRAGCOLOR = vec4(c.rgb * 0.0, 1.0);
}
