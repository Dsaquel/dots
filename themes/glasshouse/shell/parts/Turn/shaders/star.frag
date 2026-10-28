VARYING vec2 vUV;
void MAIN()
{
    vec2 p = (vUV - 0.5) * 2.0;
    float r = length(p);
    float core = exp(-r * r * 180.0) * 6.0 + exp(-r * 9.0) * 0.8;
    float sx = exp(-abs(p.y) * 160.0) * exp(-abs(p.x) * 2.6);
    float sy = exp(-abs(p.x) * 160.0) * exp(-abs(p.y) * 2.6);
    vec2 q = vec2(p.x + p.y, p.x - p.y) * 0.7071;
    float dg = (exp(-abs(q.y) * 220.0) * exp(-abs(q.x) * 6.0) + exp(-abs(q.x) * 220.0) * exp(-abs(q.y) * 6.0)) * 0.35;
    FRAGCOLOR = vec4(tint.rgb * (core + (sx + sy) * 1.6 + dg) * power, 0.0);
}
