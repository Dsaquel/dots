#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 at;
    vec2 screen;
    vec2 pixels;
    float zoom;
    float dark;
};
layout(binding = 1) uniform sampler2D frame;

void main() {
    vec2 q = qt_TexCoord0 * 2.0 - 1.0;
    float r = length(q);
    if (r > 1.0) { fragColor = vec4(0.0); return; }
    float px = pixels.x / screen.x;
    vec2 rel = q * 0.82 * zoom;
    vec2 cell = floor(at * px + rel + 0.5);
    vec2 f = at * px + rel + 0.5 - cell;
    vec3 c = texture(frame, (cell + 0.5) / pixels).rgb;
    float grid = step(f.x, 0.06) + step(f.y, 0.06);
    c = mix(c, c * 0.7 + 0.08, clamp(grid, 0.0, 1.0) * 0.5);
    vec2 centre = floor(at * px + 0.5);
    if (cell == centre) {
        float b = max(step(f.x, 0.12) + step(0.88, f.x), step(f.y, 0.12) + step(0.88, f.y));
        c = mix(c, dark > 0.5 ? vec3(1.0) : vec3(0.1), clamp(b, 0.0, 1.0));
    }
    float lens = smoothstep(0.82, 0.8, r);
    vec2 hq = q - vec2(-0.35, -0.4);
    c += vec3(1.0) * exp(-dot(hq, hq) * 9.0) * 0.18 * lens;
    c *= 1.0 - 0.35 * smoothstep(0.55, 0.82, r) * lens;
    if (r > 0.8) {
        float u = (r - 0.8) / 0.2;
        vec3 n = normalize(vec3(q / r * cos(u * 3.14159) * 1.5, sin(u * 3.14159) + 0.2));
        float diff = max(dot(n, normalize(vec3(-0.5, -0.6, 0.8))), 0.0);
        float spec = pow(max(dot(n, normalize(vec3(-0.25, -0.3, 1.0))), 0.0), 30.0);
        vec3 gold = vec3(0.79, 0.6, 0.31) * (0.3 + 0.8 * diff) + vec3(1.0, 0.96, 0.82) * spec;
        c = gold;
    }
    float a = smoothstep(1.0, 0.97, r);
    fragColor = vec4(c * a, a) * qt_Opacity;
}
