#language slang 2026
import kitty_custom_shader_types;

static const int STAGE = 4;
static const float STRENGTH = 1.0;
static const float THREAD = 0.16;
static const float DUST = 1.0;
static const float DUST_LIFE = 0.36;
static const float GLINT = 1.0;
static const float GLINT_LIFE = 0.36;
static const float BASELINE = 0.27;
static const int SLOTS = 32;
static const int FIRST = 6;
static const float3 L_TAIL = float3(0.6240, 0.6867, 0.8388);
static const float3 L_DUST = float3(0.6724, 0.6514, 0.8879);
static const float3 S_TAIL = float3(0.6514, 0.3231, 0.0284);
static const float3 S_HONEY = float3(0.9823, 0.6240, 0.1590);
static const float3 S_ROSE = float3(0.8070, 0.1779, 0.3231);
static const float3 S_DUST = float3(0.6514, 0.3231, 0.0284);

static float hash11(float x) { return frac(sin(x * 91.3458) * 47453.5453); }

static float dayOf(KittyCustomShaderData d) {
    float3 bg = d.active_window_background.rgb;
    if (dot(bg, float3(1.0)) <= 0.0) bg = d.background.rgb;
    return smoothstep(0.12, 0.40, dot(bg, float3(0.2126, 0.7152, 0.0722)));
}

static float3 shine(float3 base, float3 c, float a, float day) {
    return lerp(base + c * a, lerp(base, c, saturate(a)), day);
}

static float rectCover(float2 p, float2 lo, float2 hi) {
    float2 o = saturate(min(p + 0.5, hi) - max(p - 0.5, lo));
    return o.x * o.y;
}

static float star(float2 q, float r) {
    float2 a = abs(q);
    float rays = exp(-a.x * a.x) * (1.0 - smoothstep(0.0, r, a.y)) + exp(-a.y * a.y) * (1.0 - smoothstep(0.0, r * 0.72, a.x));
    float d = length(q);
    return saturate(rays * 0.85 + exp(-d * d / 2.2) + exp(-d * d / (r * r * 0.12)) * 0.25);
}

struct Trail {
    float2 lo, hi, head, cell, tail, ptail;
    float len, run;
    bool ok;
};

static float2 tailOf(float4 xs, float4 ys, float2 head, float2 h) {
    float2 t0 = float2(xs.x, ys.x) - float2(h.x, h.y);
    float2 t1 = float2(xs.y, ys.y) - float2(h.x, -h.y);
    float2 t2 = float2(xs.z, ys.z) + float2(h.x, h.y);
    float2 t3 = float2(xs.w, ys.w) + float2(h.x, -h.y);
    float w0 = dot(t0 - head, t0 - head), w1 = dot(t1 - head, t1 - head);
    float w2 = dot(t2 - head, t2 - head), w3 = dot(t3 - head, t3 - head);
    float ws = w0 + w1 + w2 + w3;
    if (ws < 1.0) return head;
    return (t0 * w0 + t1 * w1 + t2 * w2 + t3 * w3) / ws;
}

static Trail trailOf(KittyCustomShaderData d, float2 vp) {
    Trail k;
    float4 e = d.cursor_trail_edge;
    k.ok = e.y > e.x && e.z > e.w && d.cursor_trail_color.a > 0.0;
    k.lo = float2(e.x, e.w) * vp;
    k.hi = float2(e.y, e.z) * vp;
    k.head = (k.lo + k.hi) * 0.5;
    k.cell = max(k.hi - k.lo, float2(1.0));
    float2 h = k.cell * 0.5;
    k.tail = tailOf(d.cursor_trail_corners_x * vp.x, d.cursor_trail_corners_y * vp.y, k.head, h);
    k.ptail = tailOf(d.cursor_trail_prev_corners_x * vp.x, d.cursor_trail_prev_corners_y * vp.y, k.head, h);
    if (dot(d.cursor_trail_prev_corners_x, float4(1.0)) <= 0.0) k.ptail = k.tail;
    k.len = length(k.head - k.tail);
    float2 dh = abs(k.head - k.tail) / max(k.len, 1e-3);
    k.run = k.len - min(h.x / max(dh.x, 1e-3), h.y / max(dh.y, 1e-3));
    return k;
}

static float3 veil(float3 c, float2 p, Trail k, KittyCustomShaderData d, float day) {
    float2 axis = k.head - k.tail;
    if (k.len < k.cell.x * 0.75) return c;
    float2 lo = min(k.tail, k.head) - k.cell.y, hi = max(k.tail, k.head) + k.cell.y;
    if (any(p < lo) || any(p > hi)) return c;
    float2 dir = axis / k.len;
    float2 n = float2(-dir.y, dir.x);
    float halfW = abs(dot(k.cell * 0.5, abs(n)));
    float s = saturate(dot(p - k.tail, dir) / k.len);
    float across = abs(dot(p - k.tail, n));
    float body = 1.0 - smoothstep(halfW - 0.75, halfW + 0.75, across);
    float ends = smoothstep(-0.75, 0.75, dot(p - k.tail, dir)) * (1.0 - smoothstep(k.len - 0.75, k.len + 0.75, dot(p - k.tail, dir)));
    float a = body * ends * lerp(0.12, 0.55, pow(s, 1.2)) * STRENGTH;
    a *= 1.0 - rectCover(p, k.lo, k.hi);
    float3 col = lerp(lerp(L_TAIL, d.cursor_color.rgb, s), lerp(S_TAIL, d.cursor_color.rgb, s * s * s), day);
    return shine(c, col, a * lerp(0.8, 1.3, day), day);
}

static float3 thread(float3 c, float2 p, Trail k, KittyCustomShaderData d, float day, float isBg) {
    if (k.run <= 0.0) return c;
    float2 dir = (k.head - k.tail) / k.len;
    float hw0 = k.cell.y * THREAD;
    float pad = (hw0 * 1.6 + 2.0) * 3.0 + 2.0;
    float2 a = k.tail - float2(0.0, k.cell.y * BASELINE);
    float2 e = a + dir * k.run;
    float2 lo = min(a, e) - pad, hi = max(a, e) + pad;
    if (any(p < lo) || any(p > hi)) return c;
    float s = saturate(dot(p - a, dir) / k.run);
    float dist = length(p - (a + dir * k.run * s));
    float hw = lerp(0.35, hw0, pow(s, 1.1));
    float core = 1.0 - smoothstep(hw - 0.7, hw + 0.7, dist);
    float gr = hw * 1.6 + 2.0;
    float glow = exp(-(dist * dist) / (gr * gr));
    float life = smoothstep(0.0, k.cell.x * 0.8, k.run);
    float along = lerp(0.2, 1.0, s) * life * STRENGTH;
    float mask = 1.0 - rectCover(p, k.lo, k.hi);
    float keep = lerp(0.65, 1.0, isBg);
    float3 lcol = lerp(L_TAIL, d.cursor_color.rgb, s * s);
    float3 scol = lerp(S_ROSE, d.cursor_color.rgb, s * s);
    float la = (core * 1.05 + glow * 0.4) * along * mask * keep;
    float sAlong = lerp(0.3, 1.0, s) * life * STRENGTH;
    float3 sun = lerp(c, lerp(S_HONEY, S_TAIL, 0.6), saturate(glow * 0.7 * sAlong * mask * keep));
    sun = lerp(sun, scol, saturate(core * 1.15 * sAlong * mask * keep));
    return lerp(c + lcol * la, sun, day);
}

static float4 texel(KittyTexture tx, int i, float2 vp) {
    return tx.Sample(float2(float(i) + 0.5, 0.5) / vp);
}

struct Births {
    int n;
    float spacing, acc, carry, seed, jump;
    float2 from, to, dir, nrm;
    bool star;
};

static Births birthsOf(Trail k, KittyCustomShaderData d, float4 h0) {
    Births b;
    b.jump = k.ok ? max(h0.r * 4096.0, k.len) : 0.0;
    b.star = k.ok && b.jump > k.cell.x * 8.0 && k.len < k.cell.x * 0.6;
    b.n = 0;
    b.acc = 0.0;
    b.carry = k.ok ? h0.g : 0.0;
    b.spacing = 1.0;
    b.seed = float(d.frame_counter % 4096u) * 17.13;
    b.from = k.ptail;
    b.to = k.tail;
    b.dir = float2(1.0, 0.0);
    b.nrm = float2(0.0, 1.0);
    if (!k.ok) return b;
    float2 sw = k.tail - k.ptail;
    float sl = length(sw);
    if (sl < 1e-3) {
        b.acc = b.carry;
        return b;
    }
    b.dir = sw / sl;
    b.nrm = float2(-b.dir.y, b.dir.x);
    b.spacing = max(max(k.cell.x * (b.jump < k.cell.x * 2.0 ? 0.3 : 1.3), b.jump / 16.0), 3.0) / DUST;
    float n = b.carry + sl / b.spacing;
    b.n = min(int(floor(n)), 8);
    b.acc = b.n == 8 ? 0.0 : frac(n);
    return b;
}

static float2 birthAt(Births b, int r, Trail k) {
    float fr = float(r);
    float along = (fr + 1.0 - b.carry + (hash11(b.seed + fr * 1.3) - 0.5) * 0.5) * b.spacing;
    float across = (hash11(b.seed + fr * 5.1) - 0.5) * k.cell.y * 0.24;
    float down = k.cell.y * (BASELINE + 0.08 + 0.1 * hash11(b.seed + fr * 2.3));
    return b.from + b.dir * along + b.nrm * across - float2(0.0, down);
}

static float4 dustStep(float2 p, float2 vp, Trail k, KittyTextures t, KittyCustomShaderData d) {
    int ix = int(p.x);
    if (p.y > 1.0 || ix >= FIRST + SLOTS) return float4(0.0, 0.0, 0.0, 1.0);
    float dt = clamp(d.timestamp - d.last_rendered_at, 0.0, 0.1);
    float fade = dt / DUST_LIFE;
    float4 h0 = texel(t.persist, 0, vp);
    Births b = birthsOf(k, d, h0);
    if (ix == 0) return float4(b.star ? 0.0 : b.jump / 4096.0, b.acc, k.ok ? k.cell.y / 256.0 : h0.b, 1.0);
    if (ix == 1) {
        float4 s = texel(t.persist, 1, vp);
        if (b.star) return float4(saturate(float2(k.hi.x + k.cell.x * 0.2, k.hi.y - k.cell.y * 0.05) / vp), 1.0, 1.0);
        return float4(s.rg, max(s.b - dt / GLINT_LIFE, 0.0), 1.0);
    }
    if (ix == 4 || ix == 5) return k.ok ? float4(saturate((ix == 4 ? k.lo : k.hi) / vp), 0.0, 1.0) : texel(t.persist, ix, vp);
    if (ix < FIRST) {
        float2 lo = float2(1e9), hi = float2(-1e9);
        for (int j = 0; j < SLOTS; j++) {
            float4 s = texel(t.persist, FIRST + j, vp);
            if (s.b > fade) {
                lo = min(lo, s.rg * vp);
                hi = max(hi, s.rg * vp);
            }
        }
        if (b.n > 0) {
            float m = b.spacing * 0.3 + k.cell.y;
            lo = min(lo, min(b.from, b.to) - m);
            hi = max(hi, max(b.from, b.to) + m);
        }
        float reach = DUST_LIFE * 30.0 + 10.0;
        return float4(saturate((ix == 2 ? lo - reach : hi + reach) / vp), 0.0, 1.0);
    }
    float4 s = texel(t.persist, ix, vp);
    if (s.b > fade) return float4(s.rg, s.b - fade, 1.0);
    int rank = 0;
    for (int j = 0; j < SLOTS; j++) {
        if (FIRST + j >= ix) break;
        if (texel(t.persist, FIRST + j, vp).b <= fade) rank++;
    }
    if (rank < b.n) return float4(saturate(birthAt(b, rank, k) / vp), 1.0, 1.0);
    return float4(0.0, 0.0, 0.0, 1.0);
}

static float3 dustShow(float3 c, float4 b, KittyCustomShaderData d, float day) {
    float3 bg = d.active_window_background.rgb;
    float keep = lerp(0.55, 1.0, 1.0 - smoothstep(0.02, 0.10, length(c - bg)));
    float r = b.r * STRENGTH * keep, g = b.g * STRENGTH;
    if (r + g <= 0.0) return c;
    float3 lite = c + L_DUST * r * 1.15 + d.cursor_color.rgb * g * 0.7;
    float3 paint = lerp(lerp(c, S_DUST, saturate(r * 2.0)), S_ROSE, saturate(g * 1.6));
    return lerp(lite, paint, day);
}

static float3 dust(float3 c, float2 p, float2 vp, KittyTextures t, KittyCustomShaderData d, float day) {
    float2 uv = p / vp;
    float4 lo = texel(t.persist, 2, vp), hi = texel(t.persist, 3, vp), st = texel(t.persist, 1, vp);
    float r = 0.0, g = 0.0;
    if (all(uv >= lo.xy) && all(uv <= hi.xy)) {
        float reach = DUST_LIFE * 30.0 + 10.0;
        for (int j = 0; j < SLOTS; j++) {
            float4 s = texel(t.persist, FIRST + j, vp);
            float2 at = s.rg * vp;
            if (s.b <= 0.0 || any(abs(p - at) > reach)) continue;
            float fj = float(j);
            float h1 = hash11(s.r * 913.7 + s.g * 331.9 + fj * 7.31);
            float h2 = hash11(h1 * 57.1 + fj);
            float h3 = hash11(h2 * 31.7 + fj);
            float h4 = hash11(h3 * 17.3 + fj);
            float age = (1.0 - s.b) * DUST_LIFE;
            float2 m = at + float2((h2 - 0.5) * 12.0, -lerp(22.0, 12.0, day) * (0.7 + 0.6 * h3)) * age;
            float rad = (1.0 + 1.3 * h1 * h1) * (0.6 + 0.4 * s.b) * lerp(1.0, 1.3, day);
            float q = length(p - m) / rad;
            float spot = exp(-q * q) * smoothstep(0.0, 1.0, s.b) * smoothstep(0.0, 0.025, age) * (0.8 + 0.2 * h4);
            if (h4 < 0.22) g = g + spot * 0.9 * (1.0 - g);
            else r = r + spot * (1.0 - r);
        }
    }
    if (st.b > 0.0) {
        float rs = texel(t.persist, 0, vp).b * 256.0 * 0.55 * (0.8 + 0.2 * st.b);
        float2 q = p - st.rg * vp;
        if (all(abs(q) < rs + 4.0)) r = max(r, star(q, rs) * GLINT * st.b * st.b);
    }
    if (r + g <= 0.0) return c;
    float hide = 1.0 - rectCover(p, texel(t.persist, 4, vp).rg * vp, texel(t.persist, 5, vp).rg * vp);
    return dustShow(c, float4(r, g, 0.0, 0.0) * hide, d, day);
}

public float4
fragment_main(float4 color, KittyTextures t, KittyCustomShaderData d) {
    float2 vp = max(float2(d.viewport_size_pixels) * t.viewport.zw, float2(1.0));
    float2 full = max(float2(d.viewport_size_pixels), float2(1.0));
    float2 p = t.pos * vp;
    float day = dayOf(d);
    if (STAGE == 3) return t.a.Sample((floor(p) + 0.5) / full);
    Trail k = trailOf(d, full);
    if (STAGE == 2) return dustStep(p, full, k, t, d);
    float3 bg = d.active_window_background.rgb;
    float isBg = 1.0 - smoothstep(0.02, 0.10, length(color.rgb - bg));
    if (STAGE == 0) return k.ok ? float4(veil(color.rgb, p, k, d, day), color.a) : color;
    float3 c = dust(color.rgb, p, full, t, d, day);
    if (k.ok) c = thread(c, p, k, d, day, isBg);
    return float4(c, color.a);
}
