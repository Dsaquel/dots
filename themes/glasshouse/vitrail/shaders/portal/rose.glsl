float glyph(vec2 g, float id) {
    vec4 h = vec4(hash(vec2(id, 1.3)), hash(vec2(id, 4.7)), hash(vec2(id, 8.9)), hash(vec2(id, 2.1)));
    float d = 1e3;
    if (h.x < 0.75)
        d = min(d, sdSegment(g, vec2(0.55, 1.0), vec2(0.55, -1.0)));
    if (h.y < 0.5)
        d = min(d, abs(length(g - vec2(-0.25, -0.15)) - 0.42));
    else
        d = min(d, sdSegment(g, vec2(-0.75, 0.55), vec2(0.25, -0.85)));
    if (h.z < 0.45)
        d = min(d, sdSegment(g, vec2(-0.75, 0.0), vec2(0.55, 0.0)));
    else if (h.z < 0.75)
        d = min(d, sdSegment(g, vec2(0.55, -1.0), vec2(-0.05, -0.65)));
    else
        d = min(d, sdSegment(g, vec2(-0.2, 1.0), vec2(-0.2, -0.2)));
    if (h.w > 0.7)
        d = min(d, length(g - vec2(-0.55, -0.75)) - 0.12);
    return d;
}

vec3 leadOf(float ridge, float warm) {
    return mix(leadLow * 0.6 + vec3(0.035, 0.035, 0.045), leadHi * 0.32, pow(ridge, 4.0) * 0.45) + leadHi * pow(ridge, 30.0) * 0.28 + fire(0.5) * warm * pow(ridge, 2.0) * 0.3;
}

vec3 giltOf(float ridge, float glint) {
    return gold * (0.35 + 0.65 * ridge) + mix(gold, vec3(1.0, 0.95, 0.8), 0.6) * glint;
}
