VARYING vec2 vUV;
VARYING vec3 vN;
VARYING float vSeed;
VARYING float vDist;
VARYING float vKind;
VARYING float vPane;
VARYING float vCracked;
VARYING float vB;
VARYING float vLit;
VARYING vec2 vLocal;
VARYING float vAng;

vec3 jewel(float s)
{
    int i = int(floor(fract(s * 7.31) * 6.0));
    if (pal < 0.5) {
        if (i == 0) return vec3(1.00, 0.34, 0.42);
        if (i == 1) return vec3(1.00, 0.74, 0.30);
        if (i == 2) return vec3(0.36, 0.56, 1.00);
        if (i == 3) return vec3(0.34, 0.86, 0.58);
        if (i == 4) return vec3(1.00, 0.50, 0.80);
        return vec3(1.00, 0.90, 0.46);
    }
    if (i == 0) return vec3(0.38, 0.52, 1.00);
    if (i == 1) return vec3(0.72, 0.84, 1.00);
    if (i == 2) return vec3(0.60, 0.48, 1.00);
    if (i == 3) return vec3(0.38, 0.86, 0.96);
    if (i == 4) return vec3(0.88, 0.92, 1.00);
    return vec3(0.48, 0.62, 1.00);
}

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
    vec3 N = normalize(vN);
    if (N.z < 0.0)
        N = -N;
    vec2 px = vec2(vUV.x * 1920.0, (1.0 - vUV.y) * 1080.0);
    float d = length(px - center);

    vec2 suv = FRAGCOORD.xy / vec2(textureSize(SCREEN_TEXTURE, 0));
    vec2 off = N.xy * vec2(1.0, -1.0) * refr;
    vec3 behind;
    behind.r = texture(SCREEN_TEXTURE, suv + off * 1.00).r;
    behind.g = texture(SCREEN_TEXTURE, suv + off * 1.05).g;
    behind.b = texture(SCREEN_TEXTURE, suv + off * 1.10).b;

    vec2 iuv = vec2(vUV.x, 1.0 - vUV.y);
    if (rb > 0.5) {
        vec4 dk = texture(desk, iuv);
        vec4 gn = vec4(dk.rgb + (1.0 - dk.a) * texture(roomA, iuv).rgb, dk.a);
        float aR = gn.a * winR;
        vec3 col = gn.rgb * aR + (1.0 - aR) * behind;
        float bwR = max(fwidth(vB), 1e-5);
        float pxR = vB / bwR;
        vec3 addR = vec3(1.0, 0.99, 0.96) * ((1.0 - smoothstep(0.6, 1.8, pxR)) * 1.5 + exp(-pxR / 3.5) * 0.35) * vLit * rimR;
        vec3 HhR = normalize(vec3(-0.5, 0.7, 0.55));
        float gqR = dot(vLocal, vec2(0.8, 0.6)) * 0.0019 + vAng * 0.45 + vSeed * 3.0;
        float r1 = fract(gqR) - 0.5;
        float r2 = fract(gqR + 0.13) - 0.5;
        addR += vec3(1.0) * (exp(-r1 * r1 * 900.0) + 0.55 * exp(-r2 * r2 * 3000.0)) * pow(max(dot(N, HhR), 0.0), 10.0) * 2.5 * glintR;
        addR += vec3(0.85, 0.92, 1.0) * pow(max(0.0, 1.0 - abs(N.z)), 3.0) * 0.3 * glintR;
        FRAGCOLOR = vec4(col + addR, 1.0);
        return;
    }
    vec3 jw = jewel(vPane);
    float isRose = 1.0 - vKind;
    float st = stained * vCracked * isRose;
    vec3 glassCol = mix(behind, behind * jw * 1.45 + jw * 0.05, st);
    vec3 roseT = vec3(1.0);
    float inR = 0.0;
    if (t < burstT + 0.017) {
        vec2 rd = px - roseC;
        float ca = cos(roseA);
        float sa = sin(roseA);
        vec2 rq = vec2(ca * rd.x + sa * rd.y, -sa * rd.x + ca * rd.y) / roseS;
        vec2 ruv = vec2(rq.x / 1024.0 + 0.5, 0.5 - rq.y / 1024.0);
        vec4 rf = texture(rfill, ruv);
        inR = texture(rfillc, ruv).r * step(abs(rq.x), 511.0) * step(abs(rq.y), 511.0);
        float rm = max(max(rf.r, rf.g), rf.b);
        roseT = rm > 0.02 ? rf.rgb / rm : vec3(1.0);
        float xr = t - length(rq) / 494.0 * waveT;
        float rich = 0.50 * smoothstep(0.0, 0.1, xr - beatsA.x) + 0.12 * smoothstep(0.0, 0.1, xr - beatsA.y)
                   + 0.11 * smoothstep(0.0, 0.1, xr - beatsA.z) + 0.10 * smoothstep(0.0, 0.1, xr - beatsA.w)
                   + 0.09 * smoothstep(0.0, 0.1, xr - beatsB.x) + 0.08 * smoothstep(0.0, 0.1, xr - beatsB.y);
        glassCol = mix(behind, behind * roseT * roseTr + roseT * 0.04, stainR * rich * inR);
    }
    glassCol = mix(glassCol, glassCol * vec3(0.93, 0.98, 1.02) + vec3(0.015, 0.02, 0.03), broken * (1.0 - isRose));

    vec4 g = vec4(texture(glass, iuv).rgb, texture(glassA, iuv).a);
    vec3 pc = g.rgb;
    float a = mix(1.0, g.a * winA, reveal);
    float frozen = (1.0 - smoothstep(stopR - 28.0, stopR, d)) * smoothstep(relR - 40.0, relR, d);
    float eS = (d - stopR) / 22.0;
    float edgeS = exp(-eS * eS);
    float eR = (d - relR) / 18.0;
    float edgeR = exp(-eR * eR);
    pc = mix(pc, twoTone(pc, 0.0), frozen);
    pc = mix(pc, twoTone(pc, 1.0), edgeS * stopOn);
    pc = mix(pc, pc * coolTint.rgb, cool);
    pc *= 1.0 - dim;
    vec3 rgb = pc * a + (1.0 - a) * solid * glassCol;
    float alpha = a + (1.0 - a) * solid;

    vec3 add = hiCol.rgb * (edgeS * stopOn * 1.0 + edgeR * relOn * 0.55);
    float sq = (px.x * 0.55 + px.y) * 0.0012 - sheen;
    add += vec3(1.0, 0.97, 0.9) * (exp(-sq * sq * 260.0) + 0.35 * exp(-sq * sq * 40.0)) * sheenK;

    vec4 ck = texture(cracks, vUV);
    float dpx = ck.r * 24.0;
    float arr = ck.g;
    float lead = step(0.75, ck.b);
    float seenL = front > 0.0 ? step(arr, front) : 0.0;
    float seenW = web > 0.0 ? step(arr, web) : 0.0;
    float tq = (front - arr) / 0.016;
    float tip = exp(-tq * tq) * seenL;
    float calm = 0.3 + 0.7 * smoothstep(60.0, 220.0, d);
    float lineL = exp(-dpx * dpx / 1.3) * seenL * lead;
    float haloL = exp(-dpx / 5.0) * seenL * lead;
    float seenAny = max(seenW, seenL * lead);
    float lineW = (exp(-dpx * dpx / 0.9) * 1.0 + exp(-dpx / 3.0) * 0.15) * seenW * (1.0 - lead) * (1.0 + snapK);
    vec3 leadCol = mix(crackCol.rgb, roseT, leadTint * inR);
    add += (leadCol * lineL * (leadI + tip * 2.5) + mix(haloCol.rgb, roseT, leadTint * inR) * haloL * (crackH + tip * 0.4)) * crackFade * calm;
    add += vec3(1.0) * lineW * webI * crackFade;

    float bw = max(fwidth(vB), 1e-5);
    float pxE = vB / bw;
    float rimL = (1.0 - smoothstep(0.6, 1.8, pxE)) * vLit;
    float rimG = exp(-pxE / 3.5) * vLit * 0.35;
    add += vec3(1.0, 0.99, 0.96) * (rimL * 1.5 + rimG) * rimK;
    vec3 Hh = normalize(vec3(-0.5, 0.7, 0.55));
    float catchF = pow(max(dot(N, Hh), 0.0), 10.0) * 2.5;
    float gq = dot(vLocal, vec2(0.8, 0.6)) * 0.0019 + vAng * 0.45 + vSeed * 3.0;
    float f1 = fract(gq) - 0.5;
    float f2 = fract(gq + 0.13) - 0.5;
    float streak = exp(-f1 * f1 * 900.0) + 0.55 * exp(-f2 * f2 * 3000.0);
    add += vec3(1.0) * streak * catchF * glintK;
    float fres = pow(max(0.0, 1.0 - abs(N.z)), 3.0);
    add += vec3(0.85, 0.92, 1.0) * fres * 0.3 * glintK;

    FRAGCOLOR = vec4(rgb + add, alpha);
}
