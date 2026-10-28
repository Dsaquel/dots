vec2 thrown(vec2 O, vec2 v0, float drag, float tau, out vec2 vel) {
    vec2 vt = vec2(0.0, GRAVITY * drag);
    float k = exp(-tau / drag);
    vel = vt + (v0 - vt) * k;
    return O + vt * tau + (v0 - vt) * drag * (1.0 - k);
}

void spatter(vec2 O, float tau, vec2 key, float b, float p, vec2 q) {
    vec4 hs = hash4(key * 0.733 + vec2(2.9 * b + 4.1, 7.7 - 1.9 * b));
    float drops = 3.0 + floor(5.99 * hs.x);
    if (p > 9.5 && cooled > 0.5) {
        cull();
        return;
    }
    if (p > 9.5) {
        float i = p - 10.0;
        vec4 r = hash4(key * 0.57 + vec2(5.1 * b + 13.3 * i, 3.3 * i + b));
        float life = 350.0 + 400.0 * r.x;
        if (i > 0.5 && hs.y < 0.5 || tau > life) {
            cull();
            return;
        }
        vec2 P = O + vec2((r.z - 0.5) * 30.0 * (1.0 - exp(-tau / 300.0)) + 2.5 * sin(0.006 * tau + 6.283 * r.w), -18.0 * (1.0 - exp(-tau / 120.0)) + 0.00003 * tau * tau);
        float heat = exp(-tau / 40.0);
        float fade = smoothstep(0.0, 20.0, tau) * (1.0 - smoothstep(0.5 * life, life, tau));
        float rr = 0.8 + 1.0 * r.w;
        hard = 2.5;
        emit(P, vec2(1.0, 0.0), rr, rr, ink > 0.5 ? sepia : mix(dust * 0.22, hot, heat), ink > 0.5 ? 0.45 * fade : (0.25 + 1.5 * heat) * fade, q);
        return;
    }
    float i = p < 7.5 ? p : p - 8.0;
    vec4 r = hash4(key * 1.13 + vec2(3.3 * b + 17.1 * i, 5.7 * i - 1.1 * b));
    vec4 r2 = hash4(key * 0.91 + vec2(2.3 * b - 9.1 * i, 4.9 * i + 2.1 * b + 31.0));
    float life = cooled > 0.5 ? cooled * (0.6 + 0.4 * r.w) : 250.0 + 350.0 * r.w;
    float ts = 35.0 + 120.0 * r2.y;
    bool split = i < 1.5 && r2.x < 0.6 && ts < 0.75 * life;
    float shard = p > 7.5 ? -1.0 : 1.0;
    if (split)
        life = min(life, ts + 60.0 + 120.0 * r2.w);
    if (i >= drops || tau > life || (p > 7.5 && (!split || tau < ts))) {
        cull();
        return;
    }
    float a = 6.283 * r.x;
    vec2 v0 = (0.15 + 0.75 * r.y * r.y) * vec2(cos(a), sin(a)) + vec2(0.0, -0.1);
    float drag = 90.0 + 140.0 * r.z;
    vec2 vel;
    vec2 P = thrown(O, v0, drag, split ? min(tau, ts) : tau, vel);
    float burst = 0.0;
    if (split && tau > ts) {
        vec2 kick = vec2(-vel.y, vel.x) * (0.4 + 1.2 * r2.z) * shard - 0.15 * vel + 0.04 * shard * vec2(cos(9.0 * r2.w), sin(9.0 * r2.w));
        P = thrown(P, vel + kick, 0.8 * drag, tau - ts, vel);
        burst = 2.0 * exp(-(tau - ts) / 8.0);
    }
    float heat = exp(-tau / (90.0 + 140.0 * r.z));
    float speed = length(vel);
    float fade = smoothstep(0.0, 3.0, tau) * (1.0 - smoothstep(0.7 * life, life, tau));
    hard = 5.0;
    emit(P, speed > 1e-4 ? vel / speed : vec2(1.0, 0.0), 1.2 + speed * 18.0, (ink > 0.5 ? 1.5 : 1.1) * (1.0 + 0.45 * r.w) * (split && tau > ts ? 0.8 : 1.0), ink > 0.5 ? mix(sepia, leaf, heat) : glowOf(heat),
         (ink > 0.5 ? 0.8 + 0.2 * heat : 0.45 + 1.1 * heat) * fade * (1.0 + burst), q);
}
