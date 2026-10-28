#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 box;
    vec4 win;
    float radius;
    float offset;
    float hwOff;
    float hwOn;
    float pieceLen;
    vec4 lightPos;
    vec4 pool;
    vec4 base;
    vec4 hi;
    vec4 low;
    vec4 sky;
    vec4 jewelA;
    vec4 jewelB;
    vec4 jewelC;
    vec4 pearl;
    vec4 hot;
    float unlit;
    float specGain;
    float shininess;
    vec4 lit;
    vec4 laid;
    vec4 gap;
    vec4 seal;
    vec4 call;
    vec4 occ0;
    vec4 occ1;
    vec4 occ2;
    vec4 occ3;
    float occRadius;
};

const float SM = 3.5;

float sdRoundBox(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b + vec2(r);
    return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

float covered(vec2 p, vec4 r) {
    if (r.z < 1.0) return 0.0;
    vec2 hs = r.zw * 0.5;
    return clamp(0.5 - sdRoundBox(p - r.xy - hs, hs, occRadius), 0.0, 1.0);
}

float circ(float a, float b, float per) {
    float d = abs(a - b);
    return min(d, per - d);
}

float sq(float x) {
    return x * x;
}

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 x) {
    vec2 i = floor(x);
    vec2 f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

vec4 perim(vec2 q, vec2 e, float rr) {
    float A = 1.5707963 * rr;
    float lx = 2.0 * e.x;
    float ly = 2.0 * e.y;
    if (abs(q.x) <= e.x) {
        if (q.y < 0.0) return vec4(q.x + e.x, 0.0, q.x + e.x, lx);
        return vec4(lx + 2.0 * A + ly + (e.x - q.x), 4.0, e.x - q.x, lx);
    }
    if (abs(q.y) <= e.y) {
        if (q.x > 0.0) return vec4(lx + A + (q.y + e.y), 2.0, q.y + e.y, ly);
        return vec4(2.0 * lx + 3.0 * A + ly + (e.y - q.y), 6.0, e.y - q.y, ly);
    }
    vec2 d = abs(q) - e;
    if (q.x > 0.0 && q.y < 0.0) return vec4(lx + atan(d.x, d.y + 1e-5) * rr, 1.0, atan(d.x, d.y + 1e-5) * rr, A);
    if (q.x > 0.0) return vec4(lx + A + ly + atan(d.y, d.x + 1e-5) * rr, 3.0, atan(d.y, d.x + 1e-5) * rr, A);
    if (q.y > 0.0) return vec4(2.0 * lx + 2.0 * A + ly + atan(d.x, d.y + 1e-5) * rr, 5.0, atan(d.x, d.y + 1e-5) * rr, A);
    return vec4(2.0 * lx + 3.0 * A + 2.0 * ly + atan(d.y, d.x + 1e-5) * rr, 7.0, atan(d.y, d.x + 1e-5) * rr, A);
}

vec3 metal(vec3 n, vec2 p, float h, float pl) {
    vec3 L = normalize(vec3(lightPos.xy - p, lightPos.z));
    vec3 H = normalize(L + vec3(0.0, 0.0, 1.0));
    float diff = max(dot(n, L), 0.0);
    float spec = pow(max(dot(n, H), 0.0), shininess);
    float env = clamp(0.5 + 0.5 * n.y, 0.0, 1.0);
    vec3 envc = mix(low.rgb, sky.rgb, smoothstep(0.15, 0.95, env));
    vec3 col = base.rgb * (0.3 + 0.7 * diff) * mix(0.62, 1.0, h);
    col = mix(col, envc * base.rgb * 1.5, 0.3 * (1.0 - diff * 0.5));
    col += hi.rgb * spec * specGain * (0.3 + 0.7 * pl);
    col += pool.rgb * pl * (0.3 + 0.8 * diff + 1.1 * spec);
    return col;
}

void main() {
    vec2 p = qt_TexCoord0 * box;
    vec2 hs = win.zw * 0.5;
    vec2 q = p - win.xy - hs;
    float s = sdRoundBox(q, hs, radius);
    if (s < -12.0 || s > offset + hwOn + 18.0) {
        fragColor = vec4(0.0);
        return;
    }
    vec2 e = max(hs - vec2(radius), vec2(0.0));
    float rr = radius + SM;
    float per = 4.0 * (e.x + e.y) + 6.2831853 * rr;
    vec4 pm = perim(q, e, rr);
    float u = pm.x;
    float side = pm.y;
    float x = pm.z;
    float len = pm.w;
    bool arc = mod(side, 2.0) > 0.5;

    float lk = smoothstep(0.0, 1.0, clamp((lit.y - circ(u, lit.x, per)) / 90.0, 0.0, 1.0));
    float on = mix(lit.z, lit.w, lk);
    float dla = circ(u, laid.x, per);
    float dg = circ(u, gap.x, per);
    float shown = clamp(laid.y - dla + 0.5, 0.0, 1.0) * clamp(dg - gap.y + 0.5, 0.0, 1.0);
    float tip = laid.z * exp(-sq((laid.y - dla) / 6.0)) * step(dla, laid.y + 3.0) + gap.z * exp(-sq((dg - gap.y) / 6.0)) * step(gap.y - 3.0, dg);

    float hw = mix(hwOff, hwOn, on);
    float b0 = 1.0;
    float b1 = offset - hw;
    float sb = 0.5 * (b0 + b1);
    float bw = max(b1 - b0, 0.5);

    float n = arc ? 1.0 : max(1.0, floor(len / pieceLen + 0.5));
    float seg = len / n;
    float k = min(floor(x / seg), n - 1.0);
    float fx = x - k * seg;
    float id = side * 97.0 + k;
    float dj = min(fx, seg - fx);
    float uj = fx < seg - fx ? u - fx : u + seg - fx;

    vec2 dd = vec2(dFdx(s), dFdy(s));
    float gl = length(dd);
    vec2 g = gl > 1e-5 ? dd / gl : vec2(0.0, -1.0);
    vec2 lp = lightPos.xy - p;
    float pl = exp(-dot(lp, lp) / max(lightPos.w * lightPos.w, 1.0));

    float dSeal = circ(uj, seal.x, per);
    float heat = seal.z * (dSeal <= seal.y ? exp(-(seal.y - dSeal) / 110.0) : exp(-sq((dSeal - seal.y) / 10.0)));

    vec4 col = vec4(0.0);

    float halo = on * shown * exp(-max(s - offset - hw, 0.0) / 6.0) * step(offset, s) * 0.45;
    vec3 jewel = arc ? jewelC.rgb : (mod(k + side * 0.5, 2.0) < 1.0 ? jewelA.rgb : jewelB.rgb);
    col.rgb += (jewel * 0.7 + pool.rgb * pl * 0.6) * halo;
    float rim = on * shown * exp(s / 4.0) * step(s, 0.0) * (0.1 + 0.12 * pl);
    col.rgb += (jewel * 0.6 + pool.rgb * 0.5 + hi.rgb * 0.15) * rim;
    col.rgb += call.rgb * call.a * shown * exp(-max(s - offset - hw, 0.0) / 7.0) * step(offset, s) * 0.9;

    float bandCov = clamp(s - b0 + 0.5, 0.0, 1.0) * clamp(b1 - s + 0.5, 0.0, 1.0) * shown;
    if (bandCov > 0.0) {
        float streak = 0.82 + 0.36 * vnoise(vec2(x * 0.07 + id * 3.1, (s - sb) * 0.7 + id));
        float across = (s - sb) / (bw * 0.5);
        vec3 dark = jewel * unlit * streak + sky.rgb * 0.16 * smoothstep(-0.2, 1.0, across) * (0.6 + 0.4 * streak);
        vec3 bright = jewel * (1.0 + 0.85 * pl) * streak + jewel * jewel * 0.35 + pool.rgb * pl * 0.22;
        vec3 glass = mix(mix(dark, bright, on), call.rgb * (0.9 + 0.3 * streak), call.a * 0.65);
        col = vec4(glass, 1.0) * bandCov * 0.95 + col * (1.0 - bandCov * 0.95);
    }

    float pr = bw * 0.5 + 0.15;
    float dp = 1e5;
    if (!arc) {
        if (k > 0.5) dp = fx;
        if (k < n - 1.5) dp = min(dp, seg - fx);
    }
    float pd = length(vec2(dp, s - sb));
    float pearlCov = clamp(pr - pd + 0.5, 0.0, 1.0) * shown;
    if (pearlCov > 0.0) {
        float nz = sqrt(max(1.0 - sq(pd / pr), 0.0));
        vec3 pc = pearl.rgb * mix(unlit * 1.25, 1.1, on) * (0.6 + 0.4 * nz) + pearl.rgb * pow(nz, 6.0) * 0.35 * (0.4 + 0.6 * on);
        pc += call.rgb * call.a * (0.5 + 0.6 * nz);
        col = vec4(pc, 1.0) * pearlCov + col * (1.0 - pearlCov);
    }

    float lead = clamp(0.55 + 0.5 - abs(s - b0), 0.0, 1.0);
    lead = max(lead, clamp(0.6 + 0.5 - min(x, len - x), 0.0, 1.0) * clamp(s - b0 + 0.5, 0.0, 1.0) * clamp(b1 - s + 0.5, 0.0, 1.0));
    lead = max(lead, clamp(0.7 + 0.5 - abs(pd - pr), 0.0, 1.0) * step(s, b1 + 0.5) * step(b0 - 0.5, s));
    lead *= shown;
    if (lead > 0.0) {
        vec3 lc = metal(vec3(0.0, 0.0, 1.0), p, 0.7, pl) * 0.8;
        col = vec4(lc, 1.0) * lead + col * (1.0 - lead);
    }

    float dc = s - offset;
    float cov = clamp(hw + 0.5 - abs(dc), 0.0, 1.0);
    float bd = length(vec2(dj, dc));
    float br = hw + mix(0.5, 0.9, on);
    float beadCov = clamp(br - bd + 0.5, 0.0, 1.0);
    float camC = max(cov, beadCov) * shown;
    if (camC > 0.0) {
        float bead = step(cov, beadCov);
        float uu = bead > 0.5 ? clamp(bd / br, 0.0, 1.0) : clamp(dc / max(hw, 0.5), -1.0, 1.0);
        float h = sqrt(max(1.0 - uu * uu, 0.0));
        float slope = -uu / max(h, 0.2);
        vec3 nrm = normalize(vec3(-g * slope * 1.8, 1.0));
        vec3 mc = metal(nrm, p, h, pl) * (1.0 + 0.15 * bead);
        col = vec4(mc, 1.0) * camC + col * (1.0 - camC);
    }

    vec2 cq = sign(q) * (e + vec2(radius + offset - 0.5) * 0.70710678);
    float cd = length(q - cq);
    float cr = 3.4 + 0.8 * on + 2.4 * call.a;
    float cabCov = clamp(cr - cd + 0.5, 0.0, 1.0) * shown;
    if (cabCov > 0.0 || cd < cr + 1.5) {
        float nz = sqrt(max(1.0 - sq(cd / cr), 0.0));
        vec3 cc = jewelC.rgb * mix(unlit * 1.4, 1.25, on) * (0.55 + 0.45 * nz) + vec3(1.0) * pow(nz, 12.0) * 0.5;
        cc = mix(cc, call.rgb * (0.9 + 0.6 * nz), call.a * 0.85);
        float ring = clamp(0.9 + 0.5 - abs(cd - cr), 0.0, 1.0) * shown;
        vec3 rc = metal(normalize(vec3((q - cq) / max(cd, 1e-3) * 0.6, 1.0)), p, 0.8, pl);
        col = vec4(cc, 1.0) * cabCov + col * (1.0 - cabCov);
        col = vec4(rc, 1.0) * ring + col * (1.0 - ring);
    }

    float joint = max(clamp(br + 2.0 - bd, 0.0, 1.0), max(pearlCov, clamp(1.6 - min(x, len - x), 0.0, 1.0) * bandCov));
    float glowJ = exp(-sq(bd) / 30.0);
    col.rgb += hot.rgb * heat * (joint * 1.4 + glowJ * 0.6) * shown;
    col.rgb += hot.rgb * tip * (max(bandCov, camC) * 1.2 + exp(-sq(s - sb) / 18.0) * 0.5);

    float o = max(max(covered(p, occ0), covered(p, occ1)), max(covered(p, occ2), covered(p, occ3)));
    fragColor = col * (1.0 - o) * qt_Opacity;
}
