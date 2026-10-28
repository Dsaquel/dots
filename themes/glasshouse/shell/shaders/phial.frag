#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 size;
    vec4 vial;
    float capH;
    float tilt;
    float lift;
    float capA;
    float form;
    float gone;
    float level;
    vec4 wave;
    float still;
    float boil;
    float time;
    float hasBack;
    float unit;
    float dark;
    vec4 deep;
    vec4 bright;
    vec4 b0; vec4 b1; vec4 b2; vec4 b3; vec4 b4; vec4 b5;
    vec4 b6; vec4 b7; vec4 b8; vec4 b9; vec4 b10; vec4 b11;
    vec4 r0; vec4 r1; vec4 r2; vec4 r3;
};
layout(binding = 1) uniform sampler2D back;

const float PI = 3.14159265;

float hash(float n) { return fract(sin(n * 12.9898) * 43758.5453); }
float hash2(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash2(i), hash2(i + vec2(1, 0)), u.x), mix(hash2(i + vec2(0, 1)), hash2(i + vec2(1, 1)), u.x), u.y);
}
float fbm(vec2 p) {
    float v = 0.0, a = 0.5;
    for (int i = 0; i < 4; i++) { v += a * noise(p); p = p * 2.03 + 7.1; a *= 0.5; }
    return v;
}
float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}
float sdCapsule(vec2 p, vec2 a, vec2 b, float r) {
    vec2 pa = p - a, ba = b - a;
    return length(pa - ba * clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0)) - r;
}
float sdBox(vec2 p, vec2 b, float r) {
    vec2 d = abs(p) - b + r;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - r;
}
mat2 rot(float a) { float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }
vec4 blobAt(int i) {
    if (i == 0) return b0;
    if (i == 1) return b1;
    if (i == 2) return b2;
    if (i == 3) return b3;
    if (i == 4) return b4;
    if (i == 5) return b5;
    if (i == 6) return b6;
    if (i == 7) return b7;
    if (i == 8) return b8;
    if (i == 9) return b9;
    if (i == 10) return b10;
    return b11;
}
vec4 ringAt(int i) {
    if (i == 0) return r0;
    if (i == 1) return r1;
    if (i == 2) return r2;
    return r3;
}

float R() { return vial.z; }
float Hn() { return vial.w; }
float Rn() { return vial.z * 0.56; }
float wall() { return 2.1 * unit; }

float vialSdf(vec2 q) {
    float r = R();
    float body = sdCapsule(q, vec2(0.0, r), vec2(0.0, Hn() - 1.55 * r), r);
    float neck = sdBox(q - vec2(0.0, Hn() - 0.55 * r), vec2(Rn(), 0.55 * r), 0.0);
    return smin(body, neck, 0.32 * r);
}

float capSdf(vec2 c, out float part) {
    float r = Rn() + 4.0 * unit;
    float h = capH;
    float collar = sdBox(c - vec2(0.0, 0.14 * h), vec2(r, 0.14 * h), 1.6 * unit);
    float taper = mix(0.92, 0.7, clamp(c.y / (0.7 * h), 0.0, 1.0));
    float body = sdBox(c - vec2(0.0, 0.46 * h), vec2(r * taper, 0.2 * h), 2.0 * unit);
    float dome = length((c - vec2(0.0, 0.66 * h)) / vec2(1.0, 0.75)) - 0.62 * r;
    float knob = length(c - vec2(0.0, 0.9 * h)) - 0.2 * r;
    float d = min(min(collar, body), min(dome, knob));
    part = knob < 0.0 ? 3.0 : (collar < 0.0 ? 0.0 : (dome < body ? 2.0 : 1.0));
    return d;
}

vec3 gilt(vec3 n, float rough) {
    vec3 base = vec3(0.788, 0.604, 0.306);
    vec3 hi = vec3(1.0, 0.957, 0.812);
    vec3 low = vec3(0.231, 0.141, 0.063);
    vec3 sky = vec3(0.969, 0.875, 0.643);
    vec3 L = normalize(vec3(-0.45, 0.6, 0.8));
    vec3 H = normalize(L + vec3(0.0, 0.0, 1.0));
    float diff = max(dot(n, L), 0.0);
    float spec = pow(max(dot(n, H), 0.0), mix(60.0, 18.0, rough));
    vec3 Rf = reflect(vec3(0.0, 0.0, -1.0), n);
    vec3 env = mix(low, sky, smoothstep(-0.2, 0.7, Rf.y));
    vec3 col = base * (0.25 + 0.75 * diff);
    col = mix(col, env * base * 1.6, 0.4);
    return col + hi * spec * 1.1;
}

float surfaceAt(float x, float ys, float halfIn) {
    float u = clamp(x / max(halfIn, 1.0), -1.0, 1.0);
    float y = ys + wave.x * u + wave.y * cos(PI * u) + 0.45 * unit * sin(x * 0.21 / unit + time * 2.3) * (1.0 - still);
    for (int i = 0; i < 4; i++) {
        vec4 r = ringAt(i);
        if (r.z <= 0.0) continue;
        float dx = abs(x - r.x) / unit;
        y += r.z * unit * exp(-r.y * 3.0) * sin(dx * 0.9 - r.y * 18.0) * exp(-dx * 0.12) * smoothstep(0.0, 0.08, r.y);
    }
    y += boil * 1.8 * unit * sin(x * 0.7 / unit + time * 19.0) * sin(x * 0.29 / unit - time * 13.0);
    y += wave.w * unit * sin(x * 0.55 / unit - wave.z * 2.0);
    float edge = halfIn - abs(x);
    y += (1.0 - 0.6 * still) * 2.6 * unit * exp(-max(edge, 0.0) / (2.2 * unit)) * smoothstep(0.0, 0.03, level);
    return y;
}

float blobField(vec2 q, out vec2 nearest, out float rad) {
    float d = 1e5;
    nearest = vec2(0.0);
    rad = 0.0;
    float best = 1e5;
    for (int i = 0; i < 12; i++) {
        vec4 b = blobAt(i);
        if (b.z <= 0.0) continue;
        vec2 v = q - b.xy;
        float a = atan(v.y, v.x);
        float wob = 1.0 + 0.09 * sin(3.0 * a + b.w) * (1.0 - still) + 0.05 * sin(5.0 * a - b.w * 1.7) * (1.0 - still);
        vec2 s = v / vec2(1.0 - 0.08 * (1.0 - still), 1.0 + 0.1 * (1.0 - still));
        float di = length(s) - b.z * wob;
        if (di < best) { best = di; nearest = b.xy; rad = b.z; }
        d = smin(d, di, 3.2 * unit);
    }
    return d;
}

vec4 over(vec4 top, vec4 under) { return top + under * (1.0 - top.a); }
float cover(float dist, float w) { return clamp(0.5 - dist / w, 0.0, 1.0); }

vec4 mote(vec2 p, vec2 c, float r, vec3 col, float a) {
    float d = length(p - c);
    float k = exp(-d * d / (r * r)) + 0.35 * exp(-d / (3.0 * r));
    return vec4(col, 1.0) * k * a;
}

vec4 shard(vec2 p, vec2 c, float r, float ang, vec3 col, float a) {
    vec2 v = rot(ang) * (p - c);
    float d = abs(v.x) / r + abs(v.y) / (0.45 * r);
    float body = smoothstep(1.0, 0.7, d);
    float edge = smoothstep(1.05, 0.95, d) - smoothstep(0.95, 0.75, d);
    return vec4(col * (0.4 + 0.9 * edge), 0.55 + 0.45 * edge) * body * a;
}

void main() {
    vec2 p = qt_TexCoord0 * size;
    vec2 pivot = vial.xy;
    vec2 qq = rot(-tilt) * (p - pivot);
    qq.y = -qq.y;

    float r = R();
    float t = wall();
    float d = vialSdf(qq);
    float Y = clamp(qq.y / Hn(), 0.0, 1.0);

    float grey = still;
    vec3 deepC = mix(deep.rgb, vec3(dot(deep.rgb, vec3(0.3, 0.59, 0.11))) * 0.8 + 0.04, grey);
    vec3 brightC = mix(bright.rgb, vec3(dot(bright.rgb, vec3(0.3, 0.59, 0.11))) * 0.75 + 0.06, grey);

    float dissolve = noise(qq / (5.0 * unit)) * 0.7 + noise(qq / (1.6 * unit)) * 0.3;
    float alive = gone <= 0.0 ? 1.0 : smoothstep(0.0, 0.08, dissolve - (gone * 1.35 - 0.2) - (1.0 - Y) * 0.25 * gone);
    float shape = smoothstep(0.0, 0.5, form - Y * 0.35) * alive;
    float rim = smoothstep(0.0, 0.08, form * 1.9 - Y) * alive;

    float yb = t;
    float yt = Hn() - 0.3 * r;
    float ys = mix(yb + 0.5 * unit, yt, clamp(level, 0.0, 1.0));
    float halfHere = abs(qq.x) - d;
    float halfIn = max(halfHere - t, 1.0);
    float halfS = mix(r, Rn(), smoothstep(Hn() - 1.55 * r, Hn() - 0.9 * r, ys)) - t;
    float surf = surfaceAt(qq.x, ys, halfS);

    float px = length(fwidth(p)) * 0.7071;
    float dS = qq.y - surf;
    float wD = max(fwidth(d), 0.01);
    float wS = max(fwidth(dS), 0.01);
    float outer = cover(d, wD);
    float cavCov = cover(d + t, wD);
    float lvl = clamp(level, 0.0, 1.0);
    float wet = cover(dS, wS) * cavCov * smoothstep(0.0, 0.004, lvl);

    vec2 screenUV = qt_TexCoord0;
    vec4 col = vec4(0.0);

    float glowAmt = (0.25 + 0.75 * lvl) * (1.0 - 0.75 * still) * (1.0 - gone);
    float halo = exp(-max(d, 0.0) / (9.0 * unit)) * (1.0 - outer);
    col = over(vec4(brightC, 1.0) * halo * 0.3 * glowAmt * shape, col);

    vec2 pool = (p - pivot - vec2(0.0, 5.0 * unit)) / vec2(2.9 * r, 0.62 * r);
    float pl = dot(pool, pool);
    if (pl < 4.0) {
        vec2 cp = (p - pivot) / (7.0 * unit) + vec2(tilt * 3.0, 0.0);
        vec2 w = cp;
        for (int i = 0; i < 3; i++) w += vec2(sin(w.y * 1.4 + time * 1.1 + wave.x * 0.1), cos(w.x * 1.2 - time * 0.9));
        float c = pow(0.5 + 0.5 * sin(w.x * 2.1) * sin(w.y * 2.3), 5.0);
        float k = exp(-pl * 1.3) * (0.3 + 2.2 * c) * glowAmt * shape * (0.4 + 0.6 * lvl);
        col = over(vec4(mix(brightC, vec3(1.0), 0.3), 1.0) * k * 0.7, col);
    }

    float edgeW = max(1.2 * unit, px);
    if (d < edgeW && rim > 0.001) {
        float edge = smoothstep(edgeW, 0.0, max(d, 0.0)) * (1.0 - outer);
        vec3 leadC = dark > 0.5 ? vec3(0.2, 0.21, 0.27) : vec3(0.3, 0.25, 0.26);
        col = over(vec4(leadC, 1.0) * edge * rim, col);
    }

    if (d < wD && shape > 0.001) {
        float X = clamp(qq.x / max(halfHere, 1.0), -1.0, 1.0);
        float nz = sqrt(max(1.0 - X * X, 0.0));
        float fres = 0.04 + 0.96 * pow(1.0 - nz, 4.0);
        vec2 suv = clamp(screenUV + rot(tilt) * vec2(-X * 3.5 * unit, 0.0) / size, vec2(0.001), vec2(0.999));
        vec3 seen = texture(back, suv).rgb * hasBack;
        float alpha = hasBack > 0.5 ? 1.0 : 0.0;

        vec3 glassC = seen * (dark > 0.5 ? 0.82 : 0.9) + vec3(0.02, 0.03, 0.05);
        float glassA = max(alpha, 0.18);

        float above = dS / unit;
        vec3 c = mix(glassC, glassC * brightC * 1.3 + brightC * 0.05, 0.25 * glowAmt * exp(-max(above, 0.0) / 30.0));
        float drop = smoothstep(0.84, 0.94, noise(qq / (1.8 * unit) + 3.0)) * smoothstep(2.0, 12.0, above) * (1.0 - still) * smoothstep(0.1, -0.5, X);
        c += vec3(0.9, 0.95, 1.0) * drop * 0.1;
        float a = glassA;

        if (wet > 0.0) {
            vec2 luv = clamp(screenUV + rot(tilt) * vec2(-X * 9.0 * unit, 0.0) / size, vec2(0.001), vec2(0.999));
            vec3 seen = texture(back, luv).rgb * hasBack;
            float depth = clamp((surf - qq.y) / max(Hn() * 0.8, 1.0), 0.0, 1.0);
            float thick = nz;
            vec2 sw = qq / (9.0 * unit) + vec2(0.0, -time * 0.25 * (1.0 - still));
            float swirl = fbm(sw + fbm(sw * 0.7 + time * 0.07) * 1.6);
            vec3 body = mix(brightC, deepC, clamp(0.3 + depth * 0.55 + pow(1.0 - thick, 1.5) * 0.8, 0.0, 1.0));
            float veins = smoothstep(0.52, 0.7, swirl) * (1.0 - still);
            body *= 0.8 + 0.4 * swirl;
            body += brightC * veins * 0.45;
            float core = pow(thick, 4.0) * (1.0 - depth * 0.6) * glowAmt;
            body += mix(brightC, vec3(1.0), 0.25) * core * 0.4;
            float cloud = still * smoothstep(0.35, 0.8, fbm(qq / (6.0 * unit) + vec2(time * 0.03, 0.0)));
            body = mix(body, vec3(0.62, 0.62, 0.66) * (dark > 0.5 ? 0.6 : 0.85), cloud * 0.55);
            float trans = exp(-thick * 2.2) * (1.0 - still * 0.6);
            vec3 lc = mix(body, seen * mix(vec3(1.0), brightC * 1.6, 0.7), trans * 0.2 * alpha);

            vec2 nb;
            float rb;
            float db = blobField(qq, nb, rb);
            float bw = max(0.8 * unit, px);
            float rw = max(1.1 * unit, 1.2 * px);
            if (db < 2.0 * rw) {
                float inside = smoothstep(bw, -bw, db);
                float ringE = exp(-db * db / (rw * rw));
                vec2 rel = (qq - nb) / max(rb, 1.0);
                if (still > 0.5) {
                    vec3 sed = mix(vec3(0.42, 0.42, 0.48), deepC * 0.6 + 0.2, 0.4);
                    lc = mix(lc, sed * (0.8 + 0.4 * noise(qq / (1.8 * unit))), inside * still);
                    lc += vec3(0.7) * ringE * 0.15;
                } else {
                    vec3 inner = mix(brightC * 1.25, vec3(1.0), 0.3) + seen * 0.15;
                    lc = mix(lc, inner, inside * 0.55);
                    lc += mix(vec3(1.0), brightC, 0.25) * ringE * 0.9;
                    float sp = exp(-dot(rel - vec2(-0.35, 0.38), rel - vec2(-0.35, 0.38)) * 40.0);
                    lc += vec3(1.0) * sp * inside * 0.9;
                }
            }

            lc += brightC * exp(-max(-above, 0.0) / 3.0) * 0.25 * (1.0 - still);

            float bottomFocus = exp(-pow((qq.y - yb - 0.35 * r) / (0.35 * r), 2.0) - X * X * 6.0);
            lc += mix(brightC, vec3(1.0), 0.5) * bottomFocus * 0.4 * glowAmt;
            c = mix(c, lc, wet);
            a = mix(a, 1.0, wet);
        }
        float mw = max(1.1 * unit, 1.4 * px);
        c += mix(brightC, vec3(1.0), 0.6) * exp(-dS * dS / (mw * mw)) * (0.7 - 0.4 * still) * cavCov * smoothstep(0.0, 0.004, lvl);

        c = mix(glassC, c, cavCov);
        a = mix(glassA, a, cavCov);

        float tint = dark > 0.5 ? 0.12 : 0.08;
        c = mix(c, vec3(0.75, 0.85, 1.0), tint * fres);
        c += vec3(1.0) * fres * 0.35;
        float wX = px / max(halfHere, 1.0);
        float s1 = exp(-pow((X + 0.58) / max(0.07, 1.2 * wX), 2.0));
        float s2 = exp(-pow((X - 0.74) / max(0.035, 1.2 * wX), 2.0));
        float fadeEnds = smoothstep(0.08, 0.25, Y) * smoothstep(1.02, 0.85, Y);
        c += vec3(1.0, 0.99, 0.96) * (s1 * 0.5 + s2 * 0.3) * fadeEnds;
        c = mix(mix(c, vec3(0.85, 0.9, 1.0), 0.35), c, cavCov);
        a = mix(max(a, 0.65), a, cavCov);

        for (int g = 1; g < 4; g++) {
            float gy = mix(yb + 0.5 * unit, yt, float(g) * 0.25);
            float len = g == 2 ? 0.42 : 0.26;
            float tick = exp(-pow((qq.y - gy) / max(0.55 * unit, 0.75 * px), 2.0)) * smoothstep(-0.98, -0.94, X) * smoothstep(-0.98 + len, -0.98 + len - 0.06, X);
            c = mix(c, vec3(0.93, 0.76, 0.42) * (0.75 + 0.5 * (1.0 - nz)), tick * 0.85 * rim);
        }
        float lead = smoothstep(-0.9 * unit - max(unit, px), -0.9 * unit, d);
        float cw = max(0.9 * unit, px);
        float shoulder = exp(-pow((qq.y - (Hn() - 1.25 * r)) / cw, 2.0));
        float base = exp(-pow((qq.y - 0.42 * r) / cw, 2.0));
        float came = max(lead, max(shoulder, base) * rim);
        float ln = clamp(1.0 - abs(d + 1.4 * unit) / (1.4 * unit), 0.0, 1.0);
        vec3 leadC = mix(vec3(0.16, 0.17, 0.22), vec3(0.62, 0.65, 0.76), pow(ln, 3.0) * (0.5 + 0.5 * (X < 0.0 ? 1.0 : 0.4)));
        if (dark < 0.5) leadC = mix(vec3(0.22, 0.18, 0.2), vec3(0.78, 0.72, 0.7), pow(ln, 3.0));
        c = mix(c, leadC, came * rim);
        a = max(a * shape, came * rim);
        col = over(vec4(c * a, a) * outer, col);
    }

    float part;
    vec2 cq = qq - vec2(0.0, Hn() - 0.42 * r + lift);
    cq = rot(lift * 0.004 / max(unit, 0.01)) * cq;
    float dc = capSdf(cq, part);
    float wC = max(fwidth(dc), 0.01);
    if (dc < wC && capA > 0.001) {
        float rc = Rn() + 4.0 * unit;
        float X = clamp(cq.x / rc, -1.0, 1.0);
        vec3 n = normalize(vec3(X, 0.0, sqrt(max(1.0 - X * X, 0.02))));
        float rough = 0.3;
        if (part == 1.0) {
            float flute = cos(X * PI * 4.5);
            n = normalize(n + vec3(sin(X * PI * 4.5) * 0.35, 0.0, 0.0));
            rough = 0.45 + 0.2 * flute;
        } else if (part == 2.0) {
            vec2 dv = (cq - vec2(0.0, 0.66 * capH)) / (0.62 * rc);
            n = normalize(vec3(dv.x, dv.y * 0.75, sqrt(max(1.0 - dot(dv, dv), 0.05))));
        } else if (part == 0.0) {
            n = normalize(n + vec3(0.0, cos((cq.y / (0.28 * capH)) * PI) * 0.6, 0.0) * 0.5);
            rough = 0.2;
        }
        vec3 g = gilt(n, rough);
        if (part == 3.0) {
            vec2 dv = (cq - vec2(0.0, 0.9 * capH)) / (0.2 * rc);
            vec3 jn = normalize(vec3(dv, sqrt(max(1.0 - dot(dv, dv), 0.0))));
            float js = pow(max(dot(jn, normalize(vec3(-0.4, 0.5, 0.8))), 0.0), 24.0);
            g = mix(deepC, brightC, 0.4 + 0.6 * jn.z) * (0.6 + 0.6 * glowAmt) + vec3(1.0) * js;
        }
        float lit = clamp(1.0 - cq.y / (0.35 * capH), 0.0, 1.0);
        g += brightC * lit * lit * 0.35 * glowAmt;
        float sweep = exp(-pow((cq.x / rc + (cq.y / capH) * 0.6) - (fract(time * 0.18) * 4.0 - 1.5), 2.0) * 30.0);
        g += vec3(1.0, 0.95, 0.8) * sweep * 0.35;
        float edge = cover(dc, wC);
        float ca = edge * capA * alive;
        col = over(vec4(g, 1.0) * ca, col);
    }

    vec3 moteC = mix(brightC, vec3(1.0, 0.92, 0.7), 0.5);
    if (form < 1.0) {
        for (int i = 0; i < 26; i++) {
            float fi = float(i);
            float h1 = hash(fi * 1.7 + 0.3), h2 = hash(fi * 3.1 + 1.1), h3 = hash(fi * 5.3 + 2.7);
            float s0 = h3 * 0.35;
            float s1 = s0 + 0.35 + 0.25 * h1;
            float k = clamp((form - s0) / (s1 - s0), 0.0, 1.0);
            if (k <= 0.0 || k >= 1.0) continue;
            float e = 1.0 - pow(1.0 - k, 3.0);
            vec2 from = vec2(pivot.x + (h1 - 0.5) * size.x * 0.9, size.y + 6.0 * unit);
            float side = h2 < 0.5 ? -1.0 : 1.0;
            float yy = h2 * 1.9;
            yy = fract(yy);
            vec2 local = vec2(side * (yy > 0.82 ? Rn() : r), yy * Hn());
            vec2 to = pivot + rot(tilt) * vec2(local.x, -local.y);
            vec2 at = mix(from, to, e) + vec2(sin(k * 7.0 + fi) * 6.0 * unit * (1.0 - e), 0.0);
            float fade = sin(k * PI);
            if (mod(fi, 3.0) < 0.5)
                col = over(shard(p, at, (3.0 + 3.0 * h1) * unit, fi + k * 6.0, mix(vec3(0.8, 0.9, 1.0), brightC, 0.3), fade), col);
            else
                col = over(mote(p, at, (1.0 + h2) * unit, moteC, fade * 0.9), col);
        }
    }
    if (gone > 0.0) {
        for (int i = 0; i < 22; i++) {
            float fi = float(i);
            float h1 = hash(fi * 2.3 + 0.7), h2 = hash(fi * 4.9 + 1.9), h3 = hash(fi * 7.7 + 0.1);
            float k = clamp((gone - h3 * 0.4) / 0.6, 0.0, 1.0);
            if (k <= 0.0 || k >= 1.0) continue;
            vec2 start = pivot + rot(tilt) * vec2((h1 - 0.5) * 1.6 * r, -ys);
            vec2 at = start + vec2(sin(k * 5.0 + fi) * 7.0 * unit, -(40.0 + 70.0 * h2) * unit * k);
            col = over(mote(p, at, (1.0 + 1.2 * h2) * unit, mod(fi, 4.0) < 0.5 ? vec3(1.0, 0.92, 0.7) : brightC * 1.3, sin(k * PI) * 0.9), col);
        }
    }
    if (boil > 0.0 && gone < 1.0) {
        for (int i = 0; i < 12; i++) {
            float fi = float(i);
            float h1 = hash(fi * 9.1 + 0.2), h2 = hash(fi * 2.9 + 4.1);
            float k = fract(time * (0.45 + 0.4 * h2) + h1);
            vec2 top = pivot + rot(tilt) * vec2((h1 - 0.5) * Rn() * 1.4, -(Hn() + capH * 0.8 - lift));
            vec2 at = top + vec2(sin(k * 6.0 + fi * 2.0) * 5.0 * unit, -k * 55.0 * unit);
            col = over(mote(p, at, (1.4 + 2.5 * k) * unit, mix(vec3(0.95), brightC, 0.3), (1.0 - k) * k * 2.4 * boil * 0.6 * (1.0 - gone)), col);
        }
    }

    fragColor = col * qt_Opacity;
}
