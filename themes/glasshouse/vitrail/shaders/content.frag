#version 300 es
precision highp float;

in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;

uniform sampler2D tex;
uniform vec2 texSize;
uniform float flipY;
uniform vec4 drawn;
uniform vec4 win;
uniform float radius;
uniform float scale;
uniform float t;
uniform float mode;
uniform vec4 origin;
uniform float span;
uniform vec4 timing;
uniform vec2 cell;
uniform float edge;
uniform float seed;
uniform vec4 lightPos;
uniform vec3 gold;
uniform vec3 hot;
uniform vec3 jewel0;
uniform vec3 jewel1;
uniform vec3 jewel2;
uniform vec3 leadColor;
uniform vec3 dust;
uniform vec4 front;
uniform float ink;
uniform vec3 sepia;
uniform vec3 leaf;
uniform float fire;
uniform float came;

#include "lib/math.glsl"

#include "lib/hash.glsl"

#include "lib/noise.glsl"

float release(vec2 p) {
    vec2 x = p / scale * 0.022;
    float n = 0.55 * vnoise(x) + 0.3 * vnoise(x * 2.9 + 13.1) + 0.15 * vnoise(x * 7.3 + 5.7);
    float y = clamp((p.y - front.x) / max(front.y, 1.0), 0.0, 1.0);
    return mix(front.z, front.w, y) + (n - 0.5) * 90.0;
}

vec4 sampleAt(vec2 p) {
    vec2 uv = p / texSize;
    if (flipY > 0.5) uv.y = 1.0 - uv.y;
    return texture(tex, uv);
}

float perim(vec2 q, vec2 e, float rr) {
    float A = 1.5707963 * rr;
    float lx = 2.0 * e.x;
    float ly = 2.0 * e.y;
    if (abs(q.x) <= e.x)
        return q.y < 0.0 ? q.x + e.x : lx + 2.0 * A + ly + (e.x - q.x);
    if (abs(q.y) <= e.y)
        return q.x > 0.0 ? lx + A + (q.y + e.y) : 2.0 * lx + 3.0 * A + ly + (e.y - q.y);
    vec2 d = abs(q) - e;
    if (q.x > 0.0 && q.y < 0.0) return lx + atan(d.x, d.y + 1e-5) * rr;
    if (q.x > 0.0) return lx + A + ly + atan(d.y, d.x + 1e-5) * rr;
    if (q.y > 0.0) return 2.0 * lx + 2.0 * A + ly + atan(d.x, d.y + 1e-5) * rr;
    return 2.0 * lx + 3.0 * A + 2.0 * ly + atan(d.y, d.x + 1e-5) * rr;
}

vec4 lightUp(vec4 base, vec3 col, float k) {
    return ink > 0.5 ? mix(base, vec4(col, 1.0), clamp(k, 0.0, 1.0)) : base + vec4(col * k, 0.0);
}

vec4 scorched(vec2 p, vec3 ember) {
    vec2 x = p / scale;
    vec2 xr = mat2(0.8, 0.6, -0.6, 0.8) * x;
    float dt = release(p) + (vnoise(xr * 0.11 + 7.3) - 0.5) * 24.0 - 30.0 * smoothstep(0.8, 0.96, vnoise(xr.yx * 0.06 + 1.9)) - t;
    if (dt > 60.0)
        return sampleAt(p);
    float scorch = (1.0 - smoothstep(10.0, 48.0, dt)) * (ink > 0.5 ? 1.0 : 0.65);
    vec2 haze = vec2(sin(x.y * 0.21 + t * 0.06), cos(x.x * 0.17 + t * 0.05)) * 1.2 * scale * scorch;
    vec4 c = sampleAt(p + haze);
    vec3 straight = c.a > 0.004 ? c.rgb / c.a : vec3(0.0);
    float charred = 1.0 - smoothstep(4.0, 22.0, dt);
    float flick = 0.7 + 0.6 * vnoise(x * 0.05 + vec2(0.0, t * 0.035));
    vec3 rgb = mix(straight, straight * vec3(1.0, 0.74, 0.46) * 0.85, scorch);
    rgb = mix(rgb, sepia, charred * 0.9);
    float alive = clamp(dt / 1.5 + 0.5, 0.0, 1.0);
    float a = mix(c.a, max(c.a, 0.9), charred) * alive;
    vec4 col = vec4(rgb * a, a);
    vec2 cell = floor(x / 2.5);
    float speck = step(0.94, hash(cell)) * charred * (0.5 + 0.5 * sin(t * 0.08 + hash(cell + 1.3) * 6.2832));
    col = lightUp(col, ember, speck * 0.8 * alive * flick);
    col = lightUp(col, mix(ember, hot, 0.25), (1.0 - smoothstep(0.0, 8.0, dt)) * alive * 1.3 * flick);
    col = lightUp(col, hot, exp(-sq(dt / 2.5)) * 1.4 * flick);
    return lightUp(col, ember, (dt < 0.0 ? exp(dt / 8.0) : 0.0) * 0.45 * flick);
}

vec4 gilding(vec2 p, vec2 hs, vec3 ember) {
    vec2 c0 = win.xy + hs;
    vec2 e = max(hs - vec2(radius), vec2(0.0));
    float u = perim(p - c0, e, radius + 3.5 * scale);
    float s = sdRoundBox(p - c0, hs, radius);
    float lit = t - release(p);
    float edge = s - came * scale;
    float age = lit - max(edge, 0.0) / scale * 0.6;
    vec4 c = sampleAt(p) * step(0.5 * scale, s);
    vec3 straight = c.a > 0.004 ? c.rgb / c.a : vec3(0.0);
    float metal = smoothstep(0.08, 0.3, dot(straight, vec3(0.299, 0.587, 0.114))) * c.a;
    float peel = 25.0 + 40.0 * vnoise(vec2(u / (46.0 * scale), 3.1));
    vec3 foil = ember * (0.8 + 0.4 * vnoise(p / (2.5 * scale)));
    vec4 col = vec4(mix(c.rgb, foil * c.a, smoothstep(0.0, 10.0, age) * metal * 0.85), c.a) * (1.0 - smoothstep(peel - 15.0, peel + 15.0, age));
    col = lightUp(col, ember, c.a * step(0.0, age) * exp(-max(age, 0.0) / 40.0) * 0.7);
    float line = exp(-sq(edge / (1.1 * scale))) * (lit > -1.0 ? exp(-max(lit, 0.0) / 12.0) : 0.0);
    col = lightUp(col, mix(ember, hot, 0.4), line * 1.3);
    float tip = exp(-sq(lit / 5.0)) * (0.8 * exp(-sq(edge / (7.0 * scale))) + exp(-sq(edge / (1.1 * scale))));
    return lightUp(col, mix(hot, vec3(1.0), 0.4), tip * 1.4);
}

void main() {
    vec2 p = drawn.xy + v_texcoord * drawn.zw;
    vec4 c = sampleAt(p);
    vec2 hs = win.zw * 0.5;
    float inWin = clamp(0.5 - sdRoundBox(p - win.xy - hs, hs, radius), 0.0, 1.0);

    if (mode > 4.5) {
        float d = dot(origin.xy - p, origin.zw);
        float x = (d - t * timing.x) / timing.y;
        float k = t < 0.0 || abs(x) > 3.0 ? 0.0 : timing.z * exp(-t / 150.0) * exp(-d / (1600.0 * scale)) * smoothstep(0.0, 30.0 * scale, d) * smoothstep(0.0, 30.0 * scale, span - d);
        if (k <= 0.01) {
            fragColor = c;
            return;
        }
        float g = exp(-x * x);
        vec2 dv = origin.zw * (-2.33 * x * g * k);
        vec4 cm = sampleAt(p + dv);
        float ch = 0.15 * (1.0 - ink);
        vec4 o = vec4(sampleAt(p + dv * (1.0 + ch)).r, cm.g, sampleAt(p + dv * (1.0 - ch)).b, cm.a);
        fragColor = o + vec4(hot * 0.12 * g * k / timing.z * o.a, 0.0);
        return;
    }

    if (mode > 3.5) {
        fragColor = t > 0.5 && inWin >= 0.5 && c.a > 0.0 ? vec4(c.rgb / c.a, c.a) : c;
        return;
    }

    if (mode > 2.5 && fire > 0.5) {
        vec2 hw = win.zw * 0.5;
        float s = sdRoundBox(p - win.xy - hw, hw, radius);
        vec3 ember = ink > 0.5 ? leaf : gold;
        fragColor = s <= 0.5 * scale ? scorched(p, ember) : gilding(p, hw, ember);
        return;
    }

    if (mode > 2.5) {
        float tr = release(p);
        float alive = clamp((tr - t) / 3.0 + 0.5, 0.0, 1.0);
        if (ink > 0.5) {
            float dt = tr - t;
            float keyline = 1.0 - smoothstep(1.4, 2.8, dt);
            float gilt = 1.0 - smoothstep(5.0, 7.0, dt);
            float ember = 1.0 - smoothstep(0.0, 30.0, dt);
            vec3 rgb = c.rgb * mix(vec3(1.0), leaf / max(max(leaf.r, leaf.g), leaf.b), 0.6 * ember);
            rgb = mix(rgb, mix(leaf, hot, 0.25 * hash(floor(p / (5.0 * scale)))) * c.a, gilt * 0.92);
            rgb = mix(rgb, sepia * c.a, keyline * 0.92);
            fragColor = vec4(rgb, c.a) * alive;
            return;
        }
        float seam = 1.0 - smoothstep(0.0, 10.0, tr - t);
        float warm = 1.0 - smoothstep(0.0, 45.0, tr - t);
        vec3 glow = ((dust * 0.6 + hot * 0.4) * seam * seam + dust * warm * 0.04) * c.a;
        fragColor = c * alive + vec4(glow * alive, 0.0);
        return;
    }

    if (inWin <= 0.0) {
        fragColor = mode > 1.5 ? vec4(0.0) : c;
        return;
    }

    vec3 straight = c.a > 0.004 ? c.rgb / c.a : vec3(0.0);
    float lum = dot(straight, vec3(0.299, 0.587, 0.114));

    vec2 rel = p - win.xy;
    vec2 g = vec2(rel.x / cell.x + rel.y / cell.y, rel.x / cell.x - rel.y / cell.y);
    vec2 gi = floor(g);
    vec2 gf = g - gi;
    vec2 cc = gi + 0.5;
    vec2 cen = win.xy + vec2((cc.x + cc.y) * 0.5 * cell.x, (cc.x - cc.y) * 0.5 * cell.y);
    float edgePx = min(min(gf.x, 1.0 - gf.x), min(gf.y, 1.0 - gf.y)) * min(cell.x, cell.y) * 0.7071;
    float h = hash(gi);
    float dist = max(dot(cen - origin.xy, origin.zw), 0.0);
    float y = clamp(dist / max(span, 1.0), 0.0, 1.0);
    float sel = fract(h * 7.31 + gi.x * 0.37);
    vec3 jewel = sel < 0.34 ? jewel0 : (sel < 0.67 ? jewel1 : jewel2);
    vec2 lp = lightPos.xy - cen;
    float lit = 0.75 + 0.5 * exp(-dot(lp, lp) / 640000.0);

    if (mode < 1.5) {
        float tq = mix(timing.x, timing.y - timing.z, y) + (h - 0.5) * timing.w;
        float k = clamp((t - tq) / timing.z, 0.0, 1.0);
        bool ahead = k <= 0.0;
        float pane = ahead ? 0.1 : 1.0 - smoothstep(0.1, 0.8, k);
        float flash = ahead ? 0.0 : exp(-sq((k - 0.14) / 0.1));
        float a = max(c.a, (ahead ? 0.1 : 0.5) * pane);
        if (ink > 0.5) {
            vec3 sun = straight * mix(vec3(1.0), min(jewel * (0.5 + 0.55 * lit), vec3(1.0)), 0.8 * pane);
            float came = (1.0 - smoothstep(0.3 * scale, 1.7 * scale, edgePx)) * (ahead ? 0.12 : 1.0 - smoothstep(0.35, 0.9, k));
            sun = mix(sun, sepia, came * 0.85);
            float gilt = (1.0 - smoothstep(1.2 * scale, 3.4 * scale, edgePx)) * (1.0 - came);
            sun = mix(sun, mix(leaf, hot, 0.45 * flash), clamp(flash * (gilt * 0.9 + 0.12), 0.0, 1.0));
            fragColor = vec4(sun * a, a) * inWin + c * (1.0 - inWin);
            return;
        }
        vec3 col = mix(straight, straight * 0.82 + jewel * lit * 0.32, 0.6 * pane);
        float lead = (1.0 - smoothstep(0.2 * scale, 1.3 * scale, edgePx)) * (ahead ? 0.12 : 1.0 - smoothstep(0.35, 0.9, k));
        col = mix(col, leadColor, lead * 0.75);
        float rim = 0.55 * (1.0 - smoothstep(0.0, 2.6 * scale, edgePx)) + 0.12;
        col += hot * flash * rim + jewel * flash * 0.18;
        fragColor = vec4(col * a, a) * inWin + c * (1.0 - inWin);
        return;
    }

    float craze = smoothstep(0.0, 70.0, t + h * 30.0);
    float tq = mix(timing.y - timing.z, timing.x, y) + (h - 0.5) * timing.w;
    float kt = clamp((t - tq) / timing.z, 0.0, 1.0);
    float kg = max(clamp((dist - edge) / (1.2 * max(cell.x, cell.y)), 0.0, 1.0), clamp((20.0 * scale - edge) / (10.0 * scale), 0.0, 1.0));
    float k = max(kt, kg);
    float covered = smoothstep(0.3, 0.6, (dist - edge) / max(cell.x, cell.y));
    float taken = max(max(kg, kt * covered), smoothstep(500.0, 600.0, t));
    float shrink = 1.0 - smoothstep(0.25, 1.0, taken);
    float inside = clamp(edgePx - (1.0 - shrink) * min(cell.x, cell.y) * 0.36 + 0.5, 0.0, 1.0);
    float tint = smoothstep(0.0, 0.35, k);
    if (ink > 0.5) {
        float burn = smoothstep(0.4, 0.95, taken) * (1.0 - smoothstep(0.95, 1.0, taken));
        vec3 sun = straight * mix(vec3(1.0), min(jewel * (0.5 + 0.55 * lit), vec3(1.0)), 0.82 * tint);
        sun = mix(sun, mix(leaf, hot, 0.3 * burn), burn * 0.6);
        float crack = (1.0 - smoothstep(0.0, 1.3 * scale, edgePx)) * craze * (1.0 - smoothstep(0.2, 0.5, k));
        sun = mix(sun, leaf * 0.9, crack * 0.8);
        float rim = edgePx - (1.0 - shrink) * min(cell.x, cell.y) * 0.36;
        sun = mix(sun, sepia, (1.0 - smoothstep(0.5 * scale, 2.0 * scale, rim)) * smoothstep(0.2, 0.4, k) * 0.9);
        float a = mix(c.a, 0.94, tint);
        fragColor = vec4(sun * a, a) * inside * (1.0 - smoothstep(0.85, 1.0, taken)) * inWin;
        return;
    }
    vec3 stained = jewel * (0.55 + 0.9 * lum) * lit;
    float a = mix(c.a, 0.92, tint);
    vec4 col = vec4(mix(straight, stained, tint) * a, a);
    col.rgb += hot * smoothstep(0.4, 0.95, taken) * (1.0 - smoothstep(0.95, 1.0, taken)) * 0.8 * a;
    float lead = (1.0 - smoothstep(0.0, 1.4 * scale, edgePx)) * craze * (1.0 - smoothstep(0.2, 0.5, k));
    col = mix(col, vec4(leadColor, 1.0), lead * 0.85);
    col *= inside * (1.0 - smoothstep(0.85, 1.0, taken));
    fragColor = col * inWin;
}
