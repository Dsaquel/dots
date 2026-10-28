float veinHash(float j, float k) {
    return fract(sin(j * 12.9898 + k * 4.1414 + seed * 78.233) * 43758.5453);
}

float veinSide(float j) {
    return (j + 0.5 + 0.35 * (veinHash(j, 0.0) - 0.5)) / VEINS * 2.0 - 1.0;
}

float fanBase() {
    vec2 d = entry - came;
    return length(d) > 1.0 ? atan(d.y, d.x) : 0.5 * PI;
}

float roomOf(float th, vec4 box) {
    vec2 d = vec2(cos(th), sin(th));
    vec2 room = (mix(box.xy, box.xy + box.zw, step(0.0, d)) - entry) / (d + vec2(d.x >= 0.0 ? 1e-4 : -1e-4, d.y >= 0.0 ? 1e-4 : -1e-4));
    return max(min(room.x, room.y), 1.0);
}

float veinAngle(float j, float base) {
    return base + veinSide(j) * FAN;
}

float veinReach(float j, float base, vec4 box) {
    float s = veinSide(j);
    return roomOf(veinAngle(j, base), box) * (0.5 + 0.5 * sqrt(veinHash(j, 1.0))) * (1.0 - 0.35 * s * s);
}

float veinBend(float j, float base, float r, float reach, float len, float fork) {
    return veinAngle(j, base) + (veinSide(j) * 0.25 + (veinHash(j, 2.0) - 0.5) * 0.25) * r / reach +
        (5.0 + 10.0 * veinHash(j, 3.0)) * scale / max(r, 40.0 * scale) * sin(r / ((60.0 + 60.0 * veinHash(j, 4.0)) * scale) + j * 2.1) +
        fork * (veinHash(j, 5.0) > 0.5 ? 1.0 : -1.0) * (0.22 + 0.22 * veinHash(j, 7.0)) * smoothstep(0.3 + 0.3 * veinHash(j, 8.0), 0.95, r / len);
}
