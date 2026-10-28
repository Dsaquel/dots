float streak(vec2 d, vec2 dir, float len, float w) {
    float along = dot(d, dir);
    float across = dot(d, vec2(-dir.y, dir.x));
    return exp(-sq(across / w)) * exp(-sq(max(abs(along) - len * 0.5, 0.0) / w));
}

void impactMain(vec2 p) {
    vec2 d = p - impact.xy;
    float age = impact.z;
    float kind = impact.w;
    vec2 ax = impactAxis.xy;
    vec2 px = vec2(-ax.y, ax.x);
    float size = impactAxis.w * scale;
    float r = length(d);
    float hs = impact.x * 0.0131 + impact.y * 0.0173;
    if (kind < 0.5) {
        add(mix(hot, vec3(1.0), 0.6), exp(-sq(r / (8.0 * scale))) * exp(-age / 45.0) * 1.7);
        for (int i = 0; i < 12; ++i) {
            float fi = float(i);
            vec3 h = vec3(hash(vec2(fi, hs)), hash(vec2(fi + 3.3, hs)), hash(vec2(fi + 7.1, hs)));
            float sgn = i % 2 == 0 ? 1.0 : -1.0;
            vec2 dir = normalize(px * sgn * (0.6 + 0.6 * h.x) - ax * (0.1 + 0.55 * h.y));
            float life = 200.0 + 140.0 * h.z;
            if (age > life)
                continue;
            float reach = (16.0 + 30.0 * h.z) * scale * (1.0 - exp(-age / 60.0));
            vec2 at = dir * reach + vec2(0.0, 0.00016 * age * age * scale);
            float m = exp(-dot(d - at, d - at) / sq((1.3 + 1.1 * h.x) * scale)) * (1.0 - age / life);
            add(dust * 1.1 + hot * 0.35, m);
        }
    } else if (kind < 1.5) {
        float fade = exp(-age / 55.0);
        float star = exp(-sq(d.x / (1.0 * scale)) - abs(d.y) / (8.0 * scale)) + exp(-sq(d.y / (1.0 * scale)) - abs(d.x) / (8.0 * scale));
        float rz = (3.0 + 18.0 * (1.0 - exp(-age / 28.0))) * scale;
        add(mix(hot, vec3(1.0), 0.6), star * fade * 1.6 + exp(-sq(r / (2.6 * scale))) * fade * 1.6);
        add(hot, exp(-sq((r - rz) / (1.2 * scale))) * exp(-age / 80.0) * 0.8);
    } else if (kind < 2.5) {
        float s = sin(PI * clamp(age / 240.0, 0.0, 1.0));
        float len = (3.0 + 13.0 * s) * scale;
        float star = exp(-sq(d.x / (0.9 * scale)) - abs(d.y) / len) + exp(-sq(d.y / (0.9 * scale)) - abs(d.x) / len);
        add(mix(hot, vec3(1.0), 0.5), (star * 1.1 + exp(-sq(r / (2.2 * scale))) * 1.3) * s);
    } else if (kind < 3.5) {
        add(mix(hot, vec3(1.0), 0.4), exp(-sq(r / (5.0 * scale))) * exp(-age / 35.0) * 1.3);
        for (int i = 0; i < 7; ++i) {
            float fi = float(i);
            vec3 h = vec3(hash(vec2(fi, hs + 1.1)), hash(vec2(fi + 2.2, hs)), hash(vec2(fi + 4.4, hs)));
            float a = (h.x - 0.5) * 2.4;
            vec2 dir = vec2(ax.x * cos(a) - ax.y * sin(a), ax.x * sin(a) + ax.y * cos(a));
            float life = 140.0 + 120.0 * h.y;
            if (age > life)
                continue;
            float k = age / life;
            vec2 at = dir * (20.0 + 46.0 * h.z) * scale * (1.0 - exp(-age / 55.0)) + vec2(0.0, 0.0002 * age * age * scale);
            add(mix(hot, vec3(1.0), 0.3), streak(d - at, dir, (5.0 + 6.0 * h.y) * scale * (1.0 - k), 0.8 * scale) * sq(1.0 - k) * 1.6);
        }
    } else if (kind < 4.5) {
        float k = clamp(age / 520.0, 0.0, 1.0);
        add(mix(hot, vec3(1.0), 0.7), exp(-sq(r / (0.07 * size))) * exp(-age / 60.0) * 2.0);
        add(hot, exp(-sq(r / (0.22 * size))) * exp(-age / 110.0) * 0.45);
        float rz = size * (0.06 + 0.9 * (1.0 - exp(-age / 90.0)));
        add(mix(hot, jewel1, 0.3), exp(-sq((r - rz) / (1.4 * scale))) * sq(1.0 - k) * 0.6);
        for (int i = 0; i < 14; ++i) {
            float fi = float(i);
            vec3 h = vec3(hash(vec2(fi, hs + 5.5)), hash(vec2(fi + 6.6, hs)), hash(vec2(fi + 8.8, hs)));
            float a = 2.0 * PI * (fi + h.x) / 14.0;
            vec2 dir = vec2(cos(a), sin(a));
            float life = 220.0 + 200.0 * h.y;
            if (age > life)
                continue;
            float kk = age / life;
            vec2 at = dir * size * (0.15 + 0.4 * h.z) * (1.0 - exp(-age / 70.0)) + vec2(0.0, 0.00025 * age * age * scale);
            add(mix(hot, vec3(1.0), 0.4), streak(d - at, dir, (6.0 + 8.0 * h.y) * scale * (1.0 - kk), 0.9 * scale) * sq(1.0 - kk) * 1.5);
        }
    } else if (kind < 5.5) {
        float br = max(size, 1.0);
        float core = 1.0 - smoothstep(br - scale, br + 0.5 * scale, r);
        float wob = 0.5 + 0.5 * sin(t * 0.05 + hs * 40.0);
        add(mix(hot, vec3(1.0), 0.55), core * (1.2 + 0.3 * wob) + exp(-sq(r / (br * 2.6))) * 0.9);
        add(hot, exp(-r / (br * 3.0)) * 0.25);
    } else if (kind < 6.5) {
        float k = clamp(age / FORM, 0.0, 1.0);
        vec2 local = vec2(dot(d, px), dot(d, ax));
        for (int i = 0; i < 9; ++i) {
            float fi = float(i);
            vec3 h = vec3(hash(vec2(fi, hs + 2.2)), hash(vec2(fi + 4.4, hs)), hash(vec2(fi + 9.9, hs)));
            float a = 2.0 * PI * (fi / 9.0 + h.x) + 2.4 * k * (h.y > 0.5 ? 1.0 : -1.0);
            float rad = pow(1.0 - k, 1.4) * (22.0 + 22.0 * h.z) * scale;
            vec2 at = vec2(cos(a) * rad * 0.7, sin(a) * rad * 1.6 + (h.y - 0.5) * 30.0 * scale * (1.0 - k));
            float m = exp(-dot(local - at, local - at) / sq((1.0 + 0.8 * k) * scale)) * (0.3 + 1.2 * k);
            add(mix(hot, mix(jewel0, jewel1, h.z), 0.45), m * 1.3);
        }
        float shine = smoothstep(0.7, 1.0, k) * (1.0 - smoothstep(1.0, 1.15, age / FORM));
        float star = exp(-sq(d.x / (0.9 * scale)) - abs(d.y) / (14.0 * scale)) + exp(-sq(d.y / (0.9 * scale)) - abs(d.x) / (14.0 * scale));
        add(mix(hot, vec3(1.0), 0.6), star * shine * 1.4);
    } else {
        float run = clamp(age / SEAM, 0.0, 1.0);
        float cool = clamp((age - SEAM) / (WELD - SEAM), 0.0, 1.0);
        float along = dot(d, ax);
        float across = dot(d, px);
        float reach = max(size, 1.0) * scale;
        float torch = mix(-reach, reach, 1.0 - sq(1.0 - run));
        float fused = exp(-sq(across / ((0.8 + 0.9 * run) * scale))) * smoothstep(-reach - scale, -reach + 0.5 * scale, along) * (1.0 - smoothstep(torch - scale, torch + scale, along));
        float spark = exp(-(sq(along - torch) + sq(across)) / (3.0 * scale * scale)) * (1.0 - smoothstep(0.8, 1.0, run));
        float aura = exp(-(sq(along) + sq(across)) / (40.0 * scale * scale)) * smoothstep(0.0, SEAM, age);
        vec3 fire = mix(mix(hot, vec3(1.0), 0.7), hot * 0.6, smoothstep(0.0, 0.6, cool));
        add(fire, fused * 2.2 * sq(1.0 - cool));
        add(hot, aura * 0.8 * sq(1.0 - cool));
        add(vec3(1.0), spark * 2.6);
        float tp = clamp((age - 0.3 * SEAM) / 90.0, 0.0, 1.0);
        float swell = (2.0 + 3.0 * tp) * scale;
        add(mix(hot, jewel0, 0.3), exp(-sq((r - swell) / (0.9 * scale))) * tp * sq(1.0 - cool) * 0.9);
        for (int j = 0; j < 3; ++j) {
            float fj = float(j);
            float sa = age - fj * SEAM / 3.0;
            float life = 140.0 + 60.0 * hash(vec2(hs, fj + 0.3));
            if (sa < 0.0 || sa > life)
                continue;
            vec2 o = ax * mix(-reach, reach, 1.0 - sq(1.0 - fj / 3.0));
            float a = PI * (0.25 + 0.5 * hash(vec2(hs + 1.7, fj)));
            vec2 dir = px * cos(a) * (j % 2 == 0 ? 1.0 : -1.0) + ax * sin(a) * 0.4;
            dir = normalize(dir);
            vec2 dv = d - o - dir * (0.2 * sa * (1.0 - 0.5 * sa / life)) * scale;
            add(mix(hot, vec3(1.0), 0.5), exp(-sq(dot(dv, dir) / (2.4 * scale)) - sq(dot(dv, vec2(-dir.y, dir.x)) / scale)) * sq(1.0 - sa / life) * 1.6);
        }
    }
    fragColor = finish(impactAxis.z);
}
