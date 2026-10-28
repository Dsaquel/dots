VARYING vec2 vUV;
VARYING float vAge;

void MAIN()
{
    vec2 px = vec2(vUV.x * 1920.0, (1.0 - vUV.y) * 1080.0);
    vec2 iuv = vec2(vUV.x, 1.0 - vUV.y);
    vec4 dk = texture(desk, iuv);
    vec3 wA = texture(roomA, iuv).rgb;
    vec4 g = vec4(dk.rgb + (1.0 - dk.a) * wA, dk.a);
    vec3 room = mix(mix(texture(roomL, iuv).rgb, texture(vid, (px - vframe.xy) / vframe.zw).rgb, mixv), wA, mixr);
    room = mix(room, room * coolTint.rgb, cool);

    float sq = (px.x * 0.55 + px.y) * 0.0012 - sweep;
    float printed = smoothstep(0.02, 0.10, -sq);
    float a = mix(g.a * winP, 1.0, printed);
    vec3 rgb = g.rgb * a + room * (1.0 - a);

    vec4 ck = texture(cracks, vUV);
    float dpx = ck.r * 24.0;
    float lead = step(0.75, ck.b);
    float lineL = exp(-dpx * dpx / 1.3) * lead;
    float haloL = exp(-dpx / 5.0) * lead;
    float lineW = (exp(-dpx * dpx / 0.9) + exp(-dpx / 3.0) * 0.15) * (1.0 - lead);
    float fl = exp(-vAge / flashTau) * flashI;
    float kL = (fl + jointsL) * jointsOn;
    float kW = (fl * 0.6 + jointsW) * jointsOn;
    vec3 add = (crackCol.rgb * lineL * 1.2 + haloCol.rgb * haloL * 0.2) * kL + edgeCol.rgb * lineW * kW;
    float s2 = sq + 0.034;
    add += glintCol.rgb * (exp(-sq * sq * 1400.0) + 0.45 * exp(-s2 * s2 * 5000.0) + 0.16 * exp(-sq * sq * 60.0)) * glintK;

    FRAGCOLOR = vec4(rgb + add, 1.0);
}
