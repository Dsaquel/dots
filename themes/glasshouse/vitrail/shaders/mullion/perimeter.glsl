float circ(float a, float b, float per) {
    float d = mod(abs(a - b), per);
    return min(d, per - d);
}

float perimU(vec2 q, vec2 e, float rr) {
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
