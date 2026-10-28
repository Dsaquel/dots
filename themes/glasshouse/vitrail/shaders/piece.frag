#version 300 es
precision highp float;

in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;

uniform vec4 drawn;
uniform vec2 pos;
uniform vec2 out2;
uniform float len;
uniform float tumble;
uniform float lift;
uniform float fresh;
uniform float land;
uniform float fade;
uniform float haloGain;
uniform float landGain;
uniform float scale;
uniform float opacity;
uniform vec3 jewel;
uniform vec3 base;
uniform vec3 hi;
uniform vec3 low;
uniform vec3 sky;
uniform vec3 pearl;
uniform vec3 hot;
uniform vec4 lightPos;
uniform float ink;
uniform vec3 sepia;
uniform vec3 leaf;

vec3 metalShade(vec3 n, vec2 p, float h) {
    vec3 L = normalize(vec3(lightPos.xy - p, lightPos.z));
    vec3 H = normalize(L + vec3(0.0, 0.0, 1.0));
    float diff = max(dot(n, L), 0.0);
    float spec = pow(max(dot(n, H), 0.0), 30.0);
    float env = clamp(0.5 + 0.5 * n.y, 0.0, 1.0);
    vec3 envc = mix(low, sky, smoothstep(0.15, 0.95, env));
    vec3 col = base * (0.3 + 0.7 * diff) * mix(0.62, 1.0, h);
    col = mix(col, envc * base * 1.5, 0.3 * (1.0 - diff * 0.5));
    return col + hi * spec * 1.1;
}

void main() {
    vec2 p = drawn.xy + v_texcoord * drawn.zw;
    float WIDTH = 9.4 * scale;
    vec2 along = vec2(-out2.y, out2.x);
    float wdt = WIDTH * lift;
    float ct = cos(tumble);
    vec2 dd = p - pos;
    float lx = dot(dd, along);
    float ly = dot(dd, out2);
    float act = max(abs(ct), 0.12);
    float qx = max(abs(lx) - len * 0.5, 0.0);
    float qy = max(abs(ly) - wdt * act * 0.5, 0.0);
    float glow = exp(-(qx * qx + qy * qy) / (60.0 * scale * scale * lift)) * (lift - 1.0) * haloGain * fade;
    vec4 halo = vec4((jewel * 0.8 + hot * 0.3) * glow, 0.0);
    if (ink > 0.5) {
        vec2 sd = dd - vec2(1.5, 4.0) * scale * lift;
        float sx = max(abs(dot(sd, along)) - len * 0.5, 0.0);
        float sy = max(abs(dot(sd, out2)) - wdt * act * 0.5, 0.0);
        halo = vec4(sepia, 1.0) * exp(-(sx * sx + sy * sy) / (10.0 * scale * scale * lift)) * 0.4 * fade;
    }
    float c = ly / act * sign(ct + 1e-4) / lift;
    if (abs(lx) > len * 0.5 + scale || abs(c) > WIDTH * 0.5 + scale) {
        fragColor = halo * opacity;
        return;
    }
    float sl = c + WIDTH * 0.5;
    float cov = clamp((len * 0.5 - abs(lx)) / lift + 0.5, 0.0, 1.0) * clamp(WIDTH * 0.5 + 0.5 - abs(c), 0.0, 1.0) * clamp(act * 3.0, 0.0, 1.0);
    vec3 n3 = normalize(vec3(out2 * sin(tumble), ct));
    vec3 L = normalize(vec3(lightPos.xy - pos, lightPos.z));
    float facing = max(dot(n3, L), 0.0);
    vec3 col;
    float cameW = 2.4 * scale;
    if (sl > WIDTH - cameW) {
        float u2 = clamp((sl - (WIDTH - cameW * 0.5)) / (cameW * 0.5), -1.0, 1.0);
        float hh = sqrt(max(1.0 - u2 * u2, 0.0));
        vec3 nm = normalize(vec3(out2 * (-u2 / max(hh, 0.25)) * 1.6 * ct + out2 * sin(tumble), ct));
        col = metalShade(nm, p, hh);
    } else if (sl < 1.2 * scale) {
        col = metalShade(n3, p, 0.7) * 0.8;
    } else {
        float gx = (sl - 1.2 * scale) / (WIDTH - cameW - 1.2 * scale);
        float streak = 0.85 + 0.3 * fract(sin(dot(floor(vec2(lx / lift, sl) / scale * 0.5), vec2(12.9898, 78.233))) * 43758.5453);
        col = jewel * (0.95 + 0.6 * facing) * streak + jewel * jewel * 0.3;
        col += hi * pow(facing, 24.0) * 0.8;
        col *= 0.9 + 0.2 * gx;
        float pr = (WIDTH - cameW - 1.2 * scale) * 0.5;
        float pd = length(vec2(len * 0.5 / lift - abs(lx) / lift - pr - 0.6 * scale, sl - 1.2 * scale - pr));
        if (pd < pr + 0.6 * scale) {
            float nz = sqrt(max(1.0 - pd * pd / (pr * pr), 0.0));
            col = mix(metalShade(n3, p, 0.7) * 0.8, pearl * (0.75 + 0.35 * nz + 0.4 * pow(nz, 6.0)), clamp(pr - pd + 0.5, 0.0, 1.0));
        }
    }
    float rim = 1.0 - smoothstep(0.0, 1.6 * scale, min((len * 0.5 - abs(lx)) / lift, WIDTH * 0.5 - abs(c)));
    float body = sl > WIDTH - cameW || sl < 1.2 * scale ? 1.0 : 0.82;
    if (ink > 0.5) {
        col *= mix(vec3(1.0), jewel, body < 1.0 ? 0.5 : 0.0);
        col = mix(col, sepia, rim * 0.85);
        col = mix(col, mix(leaf, hot, 0.5), clamp(fresh * 0.5 + land * landGain * 1.4, 0.0, 1.0) * (1.0 - rim));
        fragColor = (vec4(col, 1.0) * cov * fade + halo * (1.0 - cov)) * opacity;
        return;
    }
    col += hot * (rim * (0.35 + 1.0 * fresh) + land * landGain);
    fragColor = (vec4(col * body, body) * cov * fade + vec4(jewel * (1.0 - body) * 0.6 * cov, 0.0) + halo * (1.0 - cov)) * opacity;
}
