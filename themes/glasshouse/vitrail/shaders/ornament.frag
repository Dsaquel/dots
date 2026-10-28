#version 300 es
precision highp float;

in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;

uniform mat3 toItem;
uniform vec4 layers;
uniform float hasEmblem;
uniform float opacity;
uniform float texel;
uniform sampler2D glowTex;
uniform sampler2D glassTex;
uniform sampler2D leadTex;
uniform sampler2D giltTex;
uniform sampler2D grainTex;
uniform sampler2D emblemTex;
uniform vec4 gParam[2];
uniform vec2 gLight[2];
uniform vec3 mBase[2];
uniform vec3 mHi[2];
uniform vec3 mLow[2];
uniform vec3 mSky[2];
uniform vec4 mParam[2];
uniform vec2 mLight[2];
uniform vec4 emRect;
uniform vec3 emBase;
uniform vec3 emHi;
uniform vec3 emLow;
uniform vec2 grainScale;
uniform float grow;
uniform sampler2D partTex;
uniform vec4 partAxis[4];
uniform vec4 partTime[4];
uniform vec3 spark;
uniform vec4 bloom;
uniform float forming;

const float PI = 3.14159265;
const float PETAL = 1.25663706;

vec4 glassAt(sampler2D map, vec2 at, vec2 uv, int i, bool additive, float gain) {
    vec4 g = texture(map, at);
    if (g.a < 0.003) return vec4(0.0);
    vec3 base = g.rgb / g.a;
    float grain = gParam[i].w;
    float n = texture(grainTex, fract(uv * grainScale)).r;
    vec2 d = uv - gLight[i];
    float r = gParam[i].z;
    float fall = exp(-dot(d, d) / max(r * r, 1e-4));
    float power = gParam[i].x * gain;
    float lum = gParam[i].y + power * fall;
    vec3 col = base * lum * (1.0 - grain + 2.0 * grain * n);
    col += base * base * power * fall * fall * 0.45;
    return additive ? vec4(col * g.a, 0.0) : vec4(col * g.a, g.a);
}

vec4 glass(sampler2D map, vec2 uv, int i, bool additive, float gain) {
    return glassAt(map, uv, uv, i, additive, gain);
}

vec4 emboss(sampler2D map, vec2 uv, int i) {
    vec4 t = texture(map, uv);
    float a = t.a;
    if (a < 0.003) return vec4(0.0);
    vec2 tx = vec2(texel);
    float h00 = texture(map, uv - tx).r;
    float h10 = texture(map, uv + vec2(0.0, -tx.y)).r;
    float h20 = texture(map, uv + vec2(tx.x, -tx.y)).r;
    float h01 = texture(map, uv + vec2(-tx.x, 0.0)).r;
    float h21 = texture(map, uv + vec2(tx.x, 0.0)).r;
    float h02 = texture(map, uv + vec2(-tx.x, tx.y)).r;
    float h12 = texture(map, uv + vec2(0.0, tx.y)).r;
    float h22 = texture(map, uv + tx).r;
    float hx = 0.25 * (h20 + 2.0 * h21 + h22 - h00 - 2.0 * h01 - h02);
    float hy = 0.25 * (h02 + 2.0 * h12 + h22 - h00 - 2.0 * h10 - h20);
    float metal = mParam[i].x;
    float depth = mParam[i].z;
    vec3 n = normalize(vec3(-hx * depth, hy * depth, 1.0));
    vec3 p = vec3(uv.x, 1.0 - uv.y, t.r * 0.015);
    vec3 lp = vec3(mLight[i].x, 1.0 - mLight[i].y, mParam[i].w);
    vec3 L = normalize(lp - p);
    vec3 V = vec3(0.0, 0.0, 1.0);
    vec3 H = normalize(L + V);
    float diff = max(dot(n, L), 0.0);
    float spec = pow(max(dot(n, H), 0.0), mParam[i].y);
    vec3 R = reflect(-V, n);
    float env = clamp(0.5 + 0.5 * R.y, 0.0, 1.0);
    vec3 envc = mix(mLow[i], mSky[i], smoothstep(0.2, 0.9, env));
    float ao = mix(0.55, 1.0, smoothstep(0.0, 0.6, t.r));
    vec3 col = mBase[i] * (0.22 + 0.78 * diff) * ao;
    col = mix(col, envc * mBase[i] * 1.6, metal * 0.35 * (1.0 - diff * 0.5));
    col += mHi[i] * spec * (0.35 + 0.9 * metal);
    return vec4(col * a, a);
}

float height(vec2 uv) {
    vec4 c = texture(emblemTex, uv);
    float lum = c.a > 0.004 ? dot(c.rgb / c.a, vec3(0.299, 0.587, 0.114)) : 0.0;
    return c.a * (0.65 + 0.35 * lum);
}

vec4 emblem(vec2 uv) {
    float a = texture(emblemTex, uv).a;
    if (a < 0.004) return vec4(0.0);
    vec2 t = vec2(1.0 / 44.0);
    float hc = height(uv);
    float hx = height(uv + vec2(t.x, 0.0)) - height(uv - vec2(t.x, 0.0));
    float hy = height(uv + vec2(0.0, t.y)) - height(uv - vec2(0.0, t.y));
    vec3 n = normalize(vec3(-hx * 3.2, -hy * 3.2, 1.0));
    vec3 L = normalize(vec3(vec2(0.25, 0.1) - uv, 0.7));
    float diff = max(dot(n, L), 0.0);
    float spec = pow(max(dot(n, normalize(L + vec3(0.0, 0.0, 1.0))), 0.0), 22.0);
    vec3 col = emBase * (0.35 + 0.75 * diff) + emHi * spec * 0.9;
    col = mix(emLow, col, smoothstep(0.0, 0.5, hc + 0.2));
    return vec4(col * a, a);
}

vec4 over(vec4 top, vec4 under) {
    return top + under * (1.0 - top.a);
}

vec4 piece(vec2 uv, float gain) {
    vec4 col = vec4(0.0);
    if (layers.x > 0.5) col = over(glass(glowTex, uv, 0, true, gain), col);
    if (layers.y > 0.5) col = over(glass(glassTex, uv, 1, false, 1.0), col);
    if (layers.z > 0.5) col = over(emboss(leadTex, uv, 0), col);
    if (layers.w > 0.5) col = over(emboss(giltTex, uv, 1), col);
    if (hasEmblem > 0.5) {
        vec2 eu = (uv - emRect.xy) / (emRect.zw - emRect.xy);
        if (eu.x >= 0.0 && eu.y >= 0.0 && eu.x <= 1.0 && eu.y <= 1.0) col = over(emblem(eu), col);
    }
    return col;
}

mat2 turn(float a) {
    return mat2(cos(a), sin(a), -sin(a), cos(a));
}

bool owned(vec2 src, int k) {
    return src.x >= 0.0 && src.y >= 0.0 && src.x <= 1.0 && src.y <= 1.0 && int(texelFetch(partTex, ivec2(src * vec2(textureSize(partTex, 0))), 0).r * 255.0 / 64.0 + 0.5) == k;
}

float lum(vec4 c) {
    return c.a > 0.004 ? dot(c.rgb / c.a, vec3(0.299, 0.587, 0.114)) : 0.0;
}

vec4 petal(vec2 c, float rs, float centre, float delta, float open, float gain) {
    float th = centre + delta / open;
    vec2 src = c + rs * vec2(cos(th), sin(th));
    if (!owned(src, 0)) return vec4(0.0);
    float own = max(smoothstep(0.15, 0.27, lum(texture(glassTex, src))), texture(leadTex, src).a * step(rs, 0.87 * bloom.z));
    return piece(src, gain) * own;
}

vec4 roundel(vec2 uv, float g) {
    vec2 c = bloom.xy;
    float R = bloom.z;
    vec2 d = uv - c;
    float r = length(d);
    float th = atan(d.y, d.x);
    float eB = clamp((g - 0.06) / 0.7, 0.0, 1.0);
    float E = eB * eB * (3.0 - 2.0 * eB);
    float sR = mix(0.5, 1.0, E), open = mix(1.55, 1.0, E), twist = 1.5 * (1.0 - E) * (1.0 - E);
    float sD = min(1.0, sR + 0.14) * mix(0.25, 1.0, smoothstep(0.0, 0.12, g));
    float eR = clamp((g - 0.02) / 0.6, 0.0, 1.0);
    float ER = 1.0 - (1.0 - eR) * (1.0 - eR);
    float seen = smoothstep(0.0, 0.06, g);
    vec4 col = vec4(0.0);
    if (r >= R) {
        float from = abs(mod(th - 0.25 * PI + PI, 2.0 * PI) - PI);
        float reach = PI * ER;
        vec4 ring = (owned(uv, 0) ? piece(uv, 1.0 + 1.5 * forming * (1.0 - ER)) : vec4(0.0)) * (1.0 - smoothstep(reach - 0.06, reach + 0.06, from)) * seen;
        for (int s = -1; s <= 1; s += 2) {
            float at = 0.25 * PI + float(s) * reach;
            vec2 pen = c + vec2(cos(at), sin(at)) * R * 1.2;
            vec2 q = (uv - pen) / texel / 1.6;
            col.rgb += spark * exp(-dot(q, q) / 2.0) * 1.4 * sin(PI * eR) * seen;
        }
        return over(ring, col);
    }
    if (r < R * sD) {
        vec2 src = c + d / sD;
        float rs = r / sD;
        vec4 own = piece(src, 1.0);
        bool bare = rs >= 0.87 * R || (lum(texture(glassTex, src)) < 0.15 && texture(leadTex, src).a < 0.05);
        vec2 far = c + vec2(cos(th), sin(th)) * 0.93 * R;
        vec4 fill = glassAt(glassTex, far, src, 1, false, 1.0);
        col = bare ? own : fill;
    }
    float sP = mix(0.25, 1.0, E);
    if (r < 0.24 * R * sP) {
        vec2 src = c + d / sP;
        col = over(piece(src, 1.0 + 1.5 * forming * (1.0 - E)) * step(length(src - c), 0.24 * R), col);
    }
    float rs = r / sR;
    if (rs > 0.18 * R && rs < 0.9 * R) {
        float a = th - twist - bloom.w - 0.5 * PETAL;
        float k = floor(a / PETAL + 0.5);
        float dk = a - k * PETAL;
        float spread = 0.5 * PETAL * open;
        float gain = 1.0 + 2.4 * forming * (1.0 - E) * seen;
        vec4 petals = vec4(0.0);
        for (int j = -1; j <= 1; ++j) {
            float delta = dk - float(j) * PETAL;
            if (abs(delta) > spread) continue;
            petals = over(petals, petal(c, rs, bloom.w + 0.5 * PETAL + (k + float(j)) * PETAL, delta, open, gain));
        }
        col = over(petals * seen, col);
    }
    return mix(col, piece(uv, 1.0), smoothstep(0.9, 1.0, E) * step(1.0, ER) * step(1.0, sD));
}

vec4 shoot(vec2 uv, int k) {
    float e = clamp((grow - partTime[k].x) / max(partTime[k].y - partTime[k].x, 1e-3), 0.0, 1.0);
    if (e <= 0.0) return vec4(0.0);
    float g = 1.0 - (1.0 - e) * (1.0 - e);
    vec2 base = partAxis[k].xy;
    float L = length(partAxis[k].zw - base);
    vec2 a = (partAxis[k].zw - base) / max(L, 1e-5);
    vec2 n = vec2(-a.y, a.x);
    float swing = -0.55 * partTime[k].z * (1.0 - g) * (1.0 - g);
    vec2 v = turn(swing) * (uv - base);
    float stretch = mix(0.62, 1.0, g), wide = mix(0.6, 1.0, smoothstep(0.0, 0.6, e));
    float along = dot(v, a) / stretch;
    vec2 src = base + a * along + n * dot(v, n) / wide;
    float front = 1.1 * L * g;
    vec2 tip = base + turn(-swing) * a * min(front, L) * stretch;
    vec2 q = (uv - tip) / texel / 2.0;
    float star = exp(-dot(q, q) / 2.2) * 1.3 + (exp(-q.x * q.x / 0.3) * exp(-abs(q.y) / 2.4) + exp(-q.y * q.y / 0.3) * exp(-abs(q.x) / 2.4)) * 0.5;
    vec4 col = vec4(spark * star * sin(PI * e) * (1.0 - 0.6 * e), 0.0);
    if (!owned(src, k)) return col;
    float shown = 1.0 - smoothstep(front - 1.0 * texel, front + 3.0 * texel, along);
    return over(piece(src, 1.0 + 2.2 * forming * sin(PI * e) * (1.0 - 0.5 * e)) * shown * smoothstep(0.0, 0.12, e), col);
}

vec4 grown(vec2 uv) {
    vec4 col = vec4(0.0);
    for (int k = 3; k >= 1; --k)
        col = over(shoot(uv, k), col);
    return over(grow < partTime[0].y ? roundel(uv, grow / partTime[0].y) : (owned(uv, 0) ? piece(uv, 1.0) : vec4(0.0)), col);
}

void main() {
    vec2 uv = (toItem * vec3(v_texcoord, 1.0)).xy;
    if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) {
        fragColor = vec4(0.0);
        return;
    }
    fragColor = (grow < 1.0 ? grown(uv) : piece(uv, 1.0)) * opacity;
}
