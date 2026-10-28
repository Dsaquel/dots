float hashOf(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noiseOf(vec2 x) {
    vec2 i = floor(x);
    vec2 f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hashOf(i), hashOf(i + vec2(1.0, 0.0)), f.x), mix(hashOf(i + vec2(0.0, 1.0)), hashOf(i + vec2(1.0, 1.0)), f.x), f.y);
}

vec3 molding(float across) {
    float h = sin(PI * clamp(across, 0.0, 1.0));
    vec3 c = mix(leadLow, leadBase * 1.1, h) + leadHi * pow(h, 12.0) * 0.2;
    return ink > 0.5 ? mix(c, sepia, 0.55) : c;
}
