#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 box;
    vec4 pane;
    float radius;
    float chamfer;
    float hollow;
    vec2 tailA;
    vec2 tailB;
    vec2 tailC;
    vec2 tailW;
    float tailOn;
    float rim;
    float band;
    float inner;
    float header;
    vec4 headTop;
    vec4 headBottom;
    vec4 bodyTop;
    vec4 bodyBottom;
    vec4 jewelA;
    vec4 corner;
    float jewel;
    float cornerGlow;
    float glassAlpha;
    vec4 base;
    vec4 hi;
    vec4 low;
    vec4 sky;
    float shine;
    float metalness;
    vec4 gold;
    float goldMix;
    vec2 lightPos;
    float lightZ;
    vec4 lightColor;
    float lightPower;
    float lightRadius;
    float sweep;
    vec4 sweepColor;
    float flash;
    float haloSize;
    float shadow;
    float spill;
    float shade;
    float lift;
    float grain;
    float grainSize;
};
layout(binding = 1) uniform sampler2D grainTex;

const float PI = 3.14159265;

float sdRoundBox(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b + vec2(r);
    return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

float sdGem(vec2 p, vec2 b, float c) {
    vec2 q = abs(p);
    float bx = max(q.x - b.x, q.y - b.y);
    float cut = (q.x + q.y - (b.x + b.y - c)) * 0.70710678;
    return max(bx, cut);
}

// exact distance to a quadratic Bezier (Inigo Quilez) and the parameter of the nearest point;
// every pow() gets a non-negative base (NVIDIA returns NaN otherwise)
float sdBezier(vec2 pos, vec2 A, vec2 B, vec2 C, out float tt) {
    vec2 a = B - A;
    vec2 b = A - 2.0 * B + C;
    vec2 c = a * 2.0;
    vec2 d = A - pos;
    float kk = 1.0 / max(dot(b, b), 1e-3);
    float kx = kk * dot(a, b);
    float ky = kk * (2.0 * dot(a, a) + dot(d, b)) / 3.0;
    float kz = kk * dot(d, a);
    float p = ky - kx * kx;
    float q = kx * (2.0 * kx * kx - 3.0 * ky) + kz;
    float h = q * q + 4.0 * p * p * p;
    float res;
    if (h >= 0.0) {
        h = sqrt(h);
        vec2 x = (vec2(h, -h) - q) * 0.5;
        vec2 uv = sign(x) * pow(abs(x), vec2(1.0 / 3.0));
        float t = clamp(uv.x + uv.y - kx, 0.0, 1.0);
        vec2 e = d + (c + b * t) * t;
        res = dot(e, e);
        tt = t;
    } else {
        float z = sqrt(-p);
        float v = acos(clamp(q / (p * z * 2.0), -1.0, 1.0)) / 3.0;
        float m = cos(v);
        float n = sin(v) * 1.732050808;
        vec3 t = clamp(vec3(m + m, -n - m, n - m) * z - kx, 0.0, 1.0);
        vec2 e1 = d + (c + b * t.x) * t.x;
        vec2 e2 = d + (c + b * t.y) * t.y;
        float r1 = dot(e1, e1);
        float r2 = dot(e2, e2);
        res = min(r1, r2);
        tt = r1 < r2 ? t.x : t.y;
    }
    return sqrt(res);
}

float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / max(k, 1e-3), 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

float boxShape(vec2 p) {
    vec2 hb = pane.zw * 0.5;
    vec2 q = p - pane.xy - hb;
    return chamfer > 0.0 ? sdGem(q, hb, chamfer) : sdRoundBox(q, hb, min(radius, min(hb.x, hb.y)));
}

float shape(vec2 p) {
    float s = boxShape(p);
    if (tailOn > 0.02) {
        float t;
        vec2 B = mix(tailA, tailB, tailOn);
        vec2 C = mix(tailA, tailC, tailOn);
        float d = sdBezier(p, tailA, B, C, t) - mix(tailW.x, tailW.y, t) * (0.35 + 0.65 * tailOn);
        s = smin(s, d, 8.0 * tailOn);
    }
    return s;
}

vec3 metalLit(vec3 n, vec3 L, float h, vec3 b, vec3 hiC, vec3 lowC, vec3 skyC) {
    float diff = max(dot(n, L), 0.0);
    float spec = pow(max(dot(n, normalize(L + vec3(0.0, 0.0, 1.0))), 0.0), shine);
    vec3 R = reflect(vec3(0.0, 0.0, -1.0), n);
    float env = clamp(0.5 - 0.5 * R.y, 0.0, 1.0);
    vec3 envc = mix(lowC, skyC, smoothstep(0.2, 0.9, env));
    vec3 col = b * (0.2 + 0.8 * diff) * mix(0.5, 1.0, h);
    col = mix(col, envc * b * 1.6, metalness * 0.35 * (1.0 - diff * 0.5));
    return col + hiC * spec * (0.35 + 0.9 * metalness) * h;
}

vec3 came(float e, float e0, float w, vec2 g, vec3 L, vec3 b, vec3 hiC, vec3 lowC, vec3 skyC) {
    vec3 m = vec3(0.0);
    for (int k = -1; k <= 1; k++) {
        float uu = clamp((e - e0 + float(k) * 0.33) / max(w, 0.5), 0.0, 1.0);
        m += metalLit(normalize(vec3(g * cos(uu * PI) * 1.8, 1.0)), L, sin(uu * PI), b, hiC, lowC, skyC);
    }
    return m / 3.0;
}

void main() {
    vec2 p = qt_TexCoord0 * box;
    float s = shape(p);
    float sb = boxShape(p);
    float cov = clamp(0.5 - s, 0.0, 1.0);

    vec3 jglow = vec3(0.0);
    if (band > 0.0 && jewel > 0.0 && cornerGlow > 0.0) {
        vec2 hb0 = pane.zw * 0.5;
        vec2 q0 = p - pane.xy - hb0;
        vec2 sg0 = vec2(q0.x < 0.0 ? -1.0 : 1.0, q0.y < 0.0 ? -1.0 : 1.0);
        float rr0 = min(radius, min(hb0.x, hb0.y));
        vec2 J0 = sg0 * (hb0 - vec2(rr0)) + sg0 * 0.70710678 * (rr0 - rim - band * 0.5);
        vec2 dj = q0 - J0;
        jglow = corner.rgb * cornerGlow * exp(-dot(dj, dj) / (jewel * jewel * 0.55));
    }

    float margin = min(min(p.x, box.x - p.x), min(p.y, box.y - p.y));
    float fade = smoothstep(0.0, 8.0, margin);
    float sh = 0.0;
    vec3 haloC = vec3(0.0);
    if (s > -1.0 && (shadow > 0.0 || flash > 0.0 || spill > 0.0)) {
        float s2 = shadow > 0.0 ? shape(p - vec2(0.0, 5.0)) : 1e4;
        sh = shadow * exp(-max(s2, 0.0) / 7.0) * (1.0 - cov) * fade;
        haloC = (gold.rgb * flash * 0.8 + jewelA.rgb * spill) * exp(-max(s, 0.0) / max(haloSize, 1.0)) * (1.0 - cov) * fade;
    }
    haloC += jglow * (1.0 - cov) * fade;
    if (cov < 0.002) {
        fragColor = vec4(haloC, sh) * qt_Opacity;
        return;
    }

    float edge = -s;
    float eb = -sb;
    bool tail = eb < 0.0;
    vec3 L = normalize(vec3(lightPos - p, lightZ));
    float dl = length(p - lightPos);
    float fall = exp(-dl * dl / max(lightRadius * lightRadius, 1.0));
    float bandIn = rim + band;
    float fieldIn = band > 0.0 ? bandIn + inner : rim;

    vec2 g = vec2(0.0, -1.0);
    vec2 gb = vec2(0.0, -1.0);
    const float E = 0.7;
    if (edge < rim + 1.5) {
        g = vec2(shape(p + vec2(E, 0.0)) - shape(p - vec2(E, 0.0)), shape(p + vec2(0.0, E)) - shape(p - vec2(0.0, E)));
        g = length(g) > 1e-5 ? normalize(g) : vec2(0.0, -1.0);
    }
    if (abs(eb) < fieldIn + 1.5) {
        gb = vec2(boxShape(p + vec2(E, 0.0)) - boxShape(p - vec2(E, 0.0)), boxShape(p + vec2(0.0, E)) - boxShape(p - vec2(0.0, E)));
        gb = length(gb) > 1e-5 ? normalize(gb) : vec2(0.0, -1.0);
    }

    vec3 gHi = mix(gold.rgb, vec3(1.0), 0.75);
    vec3 gLow = gold.rgb * vec3(0.3, 0.22, 0.12);
    vec3 gSky = mix(gold.rgb, vec3(1.0, 0.96, 0.85), 0.5);
    vec3 mb = mix(base.rgb, gold.rgb, goldMix);
    vec3 hiC = mix(mix(hi.rgb, gHi, goldMix), lightColor.rgb, 0.45 * fall * lightPower);
    vec3 lowC = mix(low.rgb, gLow, goldMix);
    vec3 skyC = mix(sky.rgb, gSky, goldMix);

    float metalCov = 0.0;
    vec3 metal = vec3(0.0);
    float c1 = 1.0 - smoothstep(rim - 0.5, rim + 0.5, edge);
    if (c1 > 0.0) {
        metal = came(edge, 0.0, rim, g, L, mb, hiC, lowC, skyC);
        metalCov = c1;
    }
    if (tailOn > 0.02 && eb > -0.5 && eb < rim + 0.5 && edge > rim - 0.5) {
        float c2 = (1.0 - smoothstep(rim - 0.5, rim + 0.5, eb)) * smoothstep(-0.5, 0.5, eb);
        vec3 m2 = came(eb, 0.0, rim, gb, L, mb, hiC, lowC, skyC);
        metal = mix(metal, m2, c2 * (1.0 - metalCov));
        metalCov = max(metalCov, c2);
    }
    if (band > 0.0 && !tail) {
        float ci = (1.0 - smoothstep(-0.5, 0.5, bandIn - eb)) * (1.0 - smoothstep(bandIn + inner - 0.5, bandIn + inner + 0.5, eb));
        if (ci > 0.0) {
            vec3 m3 = came(eb, bandIn, inner, gb, L, mb * 0.92, hiC, lowC, skyC);
            metal = mix(metal, m3, ci * (1.0 - metalCov));
            metalCov = max(metalCov, ci);
        }
    }
    float yh = pane.y + header;
    if (header > 0.0 && !tail) {
        float hc = (1.0 - smoothstep(0.9, 1.7, abs(p.y - yh))) * smoothstep(fieldIn - 1.0, fieldIn + 0.5, eb);
        if (hc > 0.0) {
            vec3 mh = came(p.y - yh, -1.7, 3.4, vec2(0.0, -1.0), L, mb, hiC, lowC, skyC);
            metal = mix(metal, mh, hc * (1.0 - metalCov));
            metalCov = max(metalCov, hc);
        }
    }

    vec2 hb = pane.zw * 0.5;
    vec2 q = p - pane.xy - hb;
    float jewelCov = 0.0;
    vec3 jewelCol = vec3(0.0);
    if (band > 0.0 && jewel > 0.0) {
        vec2 sg = vec2(q.x < 0.0 ? -1.0 : 1.0, q.y < 0.0 ? -1.0 : 1.0);
        float rr = min(radius, min(hb.x, hb.y));
        vec2 J = sg * (hb - vec2(rr)) + sg * 0.70710678 * (rr - rim - band * 0.5);
        vec2 dq = q - J;
        float rq = jewel * 0.48;
        float best = 1e4;
        vec2 bc = vec2(0.0);
        for (int k = 0; k < 4; k++) {
            float ang = float(k) * 1.5707963 + 0.7853982;
            vec2 c = vec2(cos(ang), sin(ang)) * jewel * 0.42;
            float d = length(dq - c) - rq;
            if (d < best) {
                best = d;
                bc = c;
            }
        }
        float jd = min(best, length(dq) - jewel * 0.36);
        jewelCov = clamp(0.5 - jd, 0.0, 1.0);
        if (jewelCov > 0.0) {
            vec2 rel = (dq - bc) / rq;
            float hh = sqrt(clamp(1.0 - dot(rel, rel), 0.0, 1.0));
            jewelCol = metalLit(normalize(vec3(rel * 1.4, max(hh, 0.25))), L, 0.6 + 0.4 * hh, mb, hiC, lowC, skyC);
            float rc = max(jewel * 0.26, 0.5);
            float cab = length(dq) / rc;
            if (cab < 1.0) {
                float hc = sqrt(clamp(1.0 - cab * cab, 0.0, 1.0));
                vec3 nc = normalize(vec3(dq / rc * 1.2, max(hc, 0.2)));
                float sp = pow(max(dot(nc, normalize(L + vec3(0.0, 0.0, 1.0))), 0.0), 40.0);
                vec3 cg = corner.rgb * (0.55 + 0.75 * hc) * (1.0 + 0.8 * lightPower * fall) + vec3(1.0) * sp * 0.9;
                jewelCol = mix(jewelCol, cg, smoothstep(1.0, 0.75, cab));
            }
        }
    }

    float n = texture(grainTex, fract(p / grainSize)).r;
    vec3 glass;
    float fy = 0.0;
    if (tail) {
        float v = clamp(edge / max(tailW.x, 1.0), 0.0, 1.0);
        glass = jewelA.rgb * (0.7 + 0.5 * sqrt(v));
    } else if (band > 0.0 && eb < bandIn + inner * 0.5) {
        float v = clamp((eb - rim) / max(band, 1.0), 0.0, 1.0);
        glass = jewelA.rgb * (0.62 + 0.5 * sin(v * PI));
    } else {
        bool head = header > 0.0 && p.y < yh;
        fy = head ? clamp((p.y - pane.y) / max(header, 1.0), 0.0, 1.0) : clamp((p.y - (header > 0.0 ? yh : pane.y)) / max(pane.w - header, 1.0), 0.0, 1.0);
        glass = head ? mix(headTop.rgb, headBottom.rgb, fy) : mix(bodyTop.rgb, bodyBottom.rgb, fy);
    }
    glass *= 1.0 - grain + 2.0 * grain * n;
    vec2 hs = (p - (pane.xy + pane.zw * vec2(0.42, 0.3))) / max(pane.zw, vec2(1.0));
    float back = exp(-dot(hs, hs) * 2.2);
    glass *= 0.76 + 0.42 * back + 0.22 * lift + lightPower * fall * (tail || eb < bandIn + inner ? 0.75 : 0.6);
    float dense = band > 0.0 && !tail ? exp(-max(eb - fieldIn, 0.0) / 5.0) * step(fieldIn, eb) : 0.0;
    glass *= 1.0 - 0.32 * dense;
    glass += gold.rgb * flash * 0.14 * (1.0 - 0.6 * fy);

    float bandL = 0.0;
    if (sweep >= 0.0) {
        float al = (p.x - pane.x) + (p.y - pane.y) * 0.45;
        float at = mix(-pane.w * 0.45 - 70.0, pane.z + 70.0, sweep);
        float dd = al - at;
        bandL = exp(-dd * dd / 500.0) * 0.8 + exp(-dd * dd / 12.0) * 0.45;
        glass += sweepColor.rgb * bandL * 0.3;
    }
    metal += hiC * bandL * 0.6;
    metal *= 1.0 + 0.45 * lift;

    float glassA = hollow > 0.5 && edge > rim + 0.6 ? 0.0 : glassAlpha;
    vec3 col = mix(glass, metal, metalCov);
    float a = mix(glassA, 1.0, metalCov);
    col = mix(col, jewelCol + hiC * bandL * 0.5, jewelCov) + jglow * 0.5;
    a = mix(a, 1.0, jewelCov) * max(cov, jewelCov);
    col *= shade;
    fragColor = vec4(col * a + haloC * (1.0 - a), a + sh * (1.0 - a)) * qt_Opacity;
}
