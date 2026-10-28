void hide() {
    gl_Position = vec4(2.0, 2.0, 2.0, 1.0);
    gl_PointSize = 1.0;
    v_col = vec4(0.0);
    v_star = 0.0;
}

vec3 project(vec3 X, float cam) {
    float d = max(X.z + lens.z - cam, 1.0);
    return vec3(lens.xy + (X.xy - lens.xy) * (lens.z / d), d);
}

vec2 pose(float tau) {
    float f = clamp((tau - times.x) / stride, 0.0, float(POSES - 1));
    int i = int(floor(f));
    return mix(poses[i], poses[min(i + 1, POSES - 1)], f - float(i));
}

vec3 leafAt(vec2 q, float phi) {
    bool left = q.x < view.z;
    float a = left ? q.x : target.x - q.x;
    return vec3(left ? a * cos(phi) : target.x - a * cos(phi), q.y, a * sin(phi));
}

vec3 sourceAt(vec2 q, float tau) {
    return bridge > 0.5 ? vec3(q, view.x) : forward > 0.5 ? leafAt(q, pose(tau).y) : vec3(q, lens.w);
}

vec3 targetAt(vec2 q, float phi) {
    return forward > 0.5 ? vec3(q, lens.w) : leafAt(q, phi);
}

vec2 entryAt(float tau) {
    vec2 c = pose(tau);
    return project(targetAt(entry, c.y), c.x).xy;
}
