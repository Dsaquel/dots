VARYING vec2 vUV;

float thump(float x)
{
    return x <= 0.0 ? 0.0 : (1.0 - exp(-x / 0.012)) * exp(-x / 0.10);
}

float flare(float x)
{
    return x <= 0.0 ? 0.0 : (1.0 - exp(-x / 0.01)) * exp(-x / 0.07);
}

float beatAt(int k)
{
    if (k == 0) return beatsA.x;
    if (k == 1) return beatsA.y;
    if (k == 2) return beatsA.z;
    if (k == 3) return beatsA.w;
    if (k == 4) return beatsB.x;
    return beatsB.y;
}

float durAt(int k)
{
    if (k == 0) return durA.x;
    if (k == 1) return durA.y;
    if (k == 2) return durA.z;
    if (k == 3) return durA.w;
    if (k == 4) return durB.x;
    return durB.y;
}

float richAt(int k)
{
    if (k == 0) return 0.50;
    if (k == 1) return 0.12;
    if (k == 2) return 0.11;
    if (k == 3) return 0.10;
    if (k == 4) return 0.09;
    return 0.08;
}

vec3 capped(vec3 c, float m)
{
    float k = max(max(c.r, c.g), c.b);
    return k > m ? c * (m / k) : c;
}

void MAIN()
{
    vec4 a = texture(art, vUV);
    float cov = a.r;
    float td = a.g;
    float cls = a.b;
    int grp = int(floor(a.a * 8.0 + 0.5));
    vec2 q = vec2(vUV.x - 0.5, 0.5 - vUV.y) * 1024.0;
    float rn = length(q) / 494.0;

    float prog = draw;
    float hw = 0.02;
    float dur = 0.0;
    if (grp == 1) {
        dur = knockDur;
        prog = (t - knockT) / dur;
        hw = 0.045;
    } else if (grp >= 2) {
        dur = durAt(grp - 2);
        prog = (t - beatAt(grp - 2) - 0.012) / dur;
        hw = 0.045;
    }
    float shown = smoothstep(td - 0.004, td + 0.001, prog);
    float hq = (prog - td) / hw;
    float head = exp(-hq * hq) * step(td, prog + 0.002) * cov;
    float ink = grp >= 1 ? exp(-max(prog - td, 0.0) * dur / 0.12) * shown * cov : 0.0;

    vec4 f = texture(fill, vUV);
    float fc = texture(fillc, vUV).r;
    int fg = int(floor(f.a * 8.0 + 0.5));
    float fm = max(max(f.r, f.g), f.b);
    vec3 side = fm > 0.02 ? f.rgb / fm : core.rgb;

    float x = t - rn * waveT;
    float hl = 0.25 * thump(x - touchT);
    float fl2 = 0.3 * flare(x - touchT);
    float rich = 0.0;
    for (int k = 0; k < 6; k++) {
        float xb = x - beatAt(k);
        hl += (0.8 + 0.08 * float(k)) * thump(xb);
        fl2 += (0.8 + 0.08 * float(k)) * flare(xb);
        rich += richAt(k) * smoothstep(0.0, 0.1, xb);
    }
    float calmF = 1.0 - smoothstep(holdT - 0.05, holdT + 0.01, t);
    hl *= hlK * calmF;
    fl2 *= hlK * calmF;
    int own = grp >= 2 ? grp : fg;
    float ob = own >= 2 ? beatAt(own - 2) : 1.0e4;
    float oflare = thump(x - ob) * hlK * calmF;
    float hk = clamp(hl, 0.0, 1.0);
    float hb = hl / (1.0 + 0.6 * hl);

    float hp = t < snapT ? clamp((t - holdT) / (snapT - holdT), 0.0, 1.0) : 0.0;
    float dw = (rn - (1.0 - hp)) / 0.22;
    float inw = hp > 0.0 ? exp(-dw * dw) * (0.5 + 0.5 * hp) : 0.0;
    float heartK = grp == 1 || fg == 1 ? 1.0 + 1.6 * hp * hp : 1.0;

    vec3 pen = mix(halo.rgb, core.rgb, cov * cov);
    vec3 base = grp == 0 ? mix(pen, side * leadC, leadT * rich) : pen;
    vec3 hc = hlMode > 0.5 && hlMode < 1.5 ? side : hlCol.rgb;
    vec3 lineCol = mix(base, hc, 0.7 * hk) * (1.0 + hlGain * hb + 0.45 * oflare) * (1.0 + 0.6 * inw) * heartK;
    float sign = grp >= 1 ? signK : 1.0;
    vec3 lines = capped(lineCol * level * sign * (0.5 + 0.5 * cls), lineCap) * cov * shown;

    vec4 gw = texture(glow, vUV);
    int gg = int(floor(gw.b * 8.0 + 0.5));
    float wrote = gg >= 2 ? clamp((t - beatAt(gg - 2) - 0.012) / durAt(gg - 2), 0.0, 1.0) : 0.0;
    float tight = 1.0 + 1.8 * hp;
    float aura = (pow(max(gw.r, 1.0e-4), tight) * smoothstep(0.85, 1.0, draw) + pow(max(gw.g, 1.0e-4), tight) * wrote)
               * (glowRest * (1.0 + 1.5 * hp) + glowBeat * fl2 / (1.0 + 0.6 * fl2)) * (1.0 - 0.8 * cov) * (1.0 - auraLit * rich);
    vec3 auraCol = mix(mix(halo.rgb, side, auraT * rich), hc, 0.4 + 0.6 * hk);
    vec3 c = lines + hot.rgb * head * headK + mix(hot.rgb, hc, 0.5) * ink * 1.4 + auraCol * aura * level;

    float lit = rich;
    float fo = 0.0;
    if (fg == 1) {
        lit = max(lit, smoothstep(0.0, 0.08, t - knockT));
    } else if (fg >= 2) {
        lit = min(1.0, rich + 0.22 * smoothstep(0.0, 0.1, x - beatAt(fg - 2)));
        fo = thump(x - beatAt(fg - 2)) * hlK * calmF;
    }
    vec3 glassC = f.rgb * fillI * lit * (1.0 + fillWave * hb + fillOwn * fo + 0.3 * inw + 0.1 * hp) * heartK;
    c += capped(glassC, fillCap) * fc;
    FRAGCOLOR = vec4(c * fade, fillOp * lit * fc * fade);
}
