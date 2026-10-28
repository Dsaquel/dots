float landOf(vec2 cell) {
    float nu = grid.x + grid.y;
    vec2 w = cell + vec2(0.0, grid.y);
    if (w.x < 0.0 || w.y < 0.0 || w.x > nu - 1.0 || w.y > nu - 1.0)
        return 1e9;
    vec4 q = texelFetch(perm, ivec2(w), 0);
    return q.x < 0.0 ? 1e9 : base + (gated > 0.5 ? seal.x : turn > 0.5 ? q.z : q.w);
}

void seam(vec2 ja, vec2 jb, vec2 ca, vec2 cb, vec2 p) {
    vec2 A = junction(ja);
    vec2 B = junction(jb);
    float ta = ignite(ja);
    float tb = ignite(jb);
    if (tb < ta) {
        vec2 x = A;
        A = B;
        B = x;
        ta = tb;
    }
    float len = length(B - A);
    vec2 u = (B - A) / max(len, 1e-3);
    float along = dot(p - A, u);
    float across = dot(p - A, vec2(-u.y, u.x));
    float ax = abs(across);
    float within = smoothstep(-1.5 * scale, 0.0, along) * smoothstep(-1.5 * scale, 0.0, len - along);
    float la = landOf(ca);
    float lb = landOf(cb);
    float first = min(la, lb);
    float cov = clamp(CAME * scale + 0.5 - ax, 0.0, 1.0) * within * smoothstep(first, first + 40.0, t);
    if (cov > came) {
        came = cov;
        mold = 0.5 + 0.5 * across / (CAME * scale);
    }
    float slam = (t >= la ? exp(-(t - la) / 110.0) : 0.0) + (t >= lb ? exp(-(t - lb) / 110.0) : 0.0);
    add(hot, exp(-sq(ax / (2.2 * scale))) * within * slam * 0.3);
    float age = t - ta;
    float cool = clamp((age - seal.z) / (seal.w - seal.z), 0.0, 1.0);
    float flank = exp(-sq((ax - (CAME + 0.8) * scale) / (0.9 * scale))) * within;
    add(keyline, flank * (0.9 * exp(-sq(age / 45.0)) + 0.15 * step(0.0, age) * (1.0 - cool)));
    if (age <= 0.0 || age >= seal.w)
        return;
    float run = clamp(age / seal.z, 0.0, 1.0);
    float torch = len * (1.0 - sq(1.0 - run));
    float since = t - ta - seal.z * (1.0 - sqrt(1.0 - clamp(along / max(len, 1.0), 0.0, 1.0)));
    float behind = step(0.0, since) * within;
    float heat = behind * exp(-since / 55.0);
    float bead = exp(-sq(ax / ((0.8 + 0.7 * heat) * scale)));
    float spark = exp(-(sq(along - torch) + sq(across)) / (3.0 * scale * scale)) * (1.0 - smoothstep(0.8, 1.0, run));
    vec3 fire = mix(hot * 0.6, mix(hot, vec3(1.0), 0.7), heat);
    add(fire, bead * behind * (1.5 * heat + 0.2 * sq(1.0 - cool)));
    add(hot, exp(-sq(ax / (6.0 * scale))) * heat * 0.3);
    add(vec3(1.0), spark * 2.2 * (turn > 0.5 || gated > 0.5 ? 0.0 : 1.0));
}
