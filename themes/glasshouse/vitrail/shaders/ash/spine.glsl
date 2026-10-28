float frontAt(float tau) {
    return burn.x + burn.y * span(tau, burn.z, burn.w);
}

vec2 rootAt(float tau) {
    return vec2(shot.x + shot.z * (0.5 + 0.03 * sin(tau * 0.011 + seed)), clamp(frontAt(tau) - 0.04 * shot.w, shot.y + 0.1 * shot.w, shot.y + 0.95 * shot.w));
}

bool pinned(vec2 q) {
    return bridge > 0.5 || q.x < 0.0 || q.y < 0.0 || q.x > target.x || q.y > target.y;
}

vec3 lifted(vec3 q) {
    return vec3(lens.xy + (q.xy - lens.xy) / q.z, (pinned(q.xy) ? view.x : pose(turn.x).x) + lens.z / q.z - lens.z);
}

vec3 wakeAt(float tau) {
    float f = clamp((tau - turn.z) / max(turn.x - turn.z, 1.0), 0.0, 1.0) * float(WAKE - 1);
    int i = int(floor(f));
    return lifted(mix(wake[i], wake[min(i + 1, WAKE - 1)], f - float(i)));
}

vec3 turnedAt(float tau) {
    vec3 h = wake[WAKE - 1];
    vec3 H = lifted(h);
    vec2 c = pose(tau);
    float k = span(tau, turn.x, times.y);
    float ks = nave > 0.5 ? 1.0 - sq(1.0 - k) : k * (0.6 + 0.4 * k);
    vec2 e = entryAt(tau);
    vec2 to = e - h.xy;
    float pace = length(heading);
    float bend = pace > 1e-3 && length(to) > 1e-3 ? sq(0.5 + 0.5 * dot(heading, to) / (pace * length(to))) : 0.0;
    vec2 D1 = h.xy + heading * bend * min((times.y - turn.x) / 1.8, 0.35 * length(to) / max(pace, 1e-3));
    vec2 S = bez(h.xy, D1, e + (D1 - e) * 0.35, e, ks);
    float z = mix(H.z, targetAt(entry, c.y).z, 1.0 - pow(1.0 - k, 3.0));
    vec3 X = vec3(lens.xy + (S - lens.xy) * ((z + lens.z - c.x) / lens.z), z);
    return pinned(h.xy) ? mix(vec3(lens.xy + (S - lens.xy) / h.z, H.z), X, k * k) : X;
}

vec3 headAt(float tau) {
    if (turn.w > 0.5)
        return turnedAt(tau);
    float zS = bridge > 0.5 ? view.x : forward > 0.5 ? 0.0 : lens.w;
    vec2 a0 = origin();
    vec2 Q = bridge > 0.5 ? crossing() : doorway();
    vec2 P2 = bridge > 0.5 ? arc(Q) : crest();
    float rise = times.x + RISEN;
    if (tau < rise) {
        vec2 P1 = vec2(a0.x + (Q.x - a0.x) * 0.1, P2.y);
        return vec3(bez(a0, P1, P2, Q, span(tau, BORN, rise)), zS);
    }
    vec2 c = pose(tau);
    float k = span(tau, rise, times.y);
    float ks = nave > 0.5 ? 1.0 - sq(1.0 - k) : k * (0.6 + 0.4 * k);
    float sc = bridge > 0.5 ? 1.0 : lens.z / (zS + lens.z - pose(rise).x);
    vec2 D0 = lens.xy + (Q - lens.xy) * sc;
    vec2 e = entryAt(tau);
    vec2 D1 = bridge > 0.5 ? Q + normalize(Q - P2) * min(0.5 * length(Q - P2), 0.25 * length(e - Q)) : D0 + (Q - P2) * 0.5 * sc;
    vec2 S = bez(D0, D1, e + ((bridge > 0.5 ? Q : D1) - e) * 0.35, e, ks);
    float z = mix(bridge > 0.5 ? pose(rise).x : zS, targetAt(entry, c.y).z, 1.0 - pow(1.0 - k, 3.0));
    vec3 X = vec3(lens.xy + (S - lens.xy) * ((z + lens.z - c.x) / lens.z), z);
    return bridge > 0.5 ? mix(vec3(S, view.x), X, k * k) : X;
}

vec3 spineAt(float tau, float lag, float now) {
    if (tau >= BORN)
        return turn.w > 0.5 && tau < turn.x ? wakeAt(tau) : headAt(min(tau, times.y - 0.5));
    return mix(turn.w > 0.5 ? wakeAt(BORN) : headAt(BORN), sourceAt(rootAt(now), now), unit((BORN - tau) / max(BORN - (now - lag), 1.0)));
}
