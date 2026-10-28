vec2 unproj(vec2 q, float h) {
    vec2 lim = clamp((room.xy - 2.0 - abs(q - gV)) / EDGEW, 0.0, 1.0);
    return gV + (q - gV) * (1.0 - h / DCAM * lim);
}

vec2 castV(vec2 q) {
    vec2 v = (q - gL) / lightPos.z;
    return v * min(1.0, 1.2 / max(length(v), 1e-3));
}

vec2 flipAt(vec2 o, float h) {
    return step(room.xy - 4.0, abs(o + castV(o) * (h + HOVER) - gV));
}

vec2 caster(vec2 q, float h, vec2 flip) {
    return q - castV(q) * h * (1.0 - 2.0 * flip);
}

float hwOf(float lv) {
    return mix(hwOff, hwOn, lv);
}

float scOf(float lv) {
    return 0.5 * (1.0 + offset + hwOf(lv));
}

vec3 flareOf() {
    return mix(jewelC * 1.15, mix(jewelC, hot, 0.2) * 1.25, dark);
}

float hoistOf(float d) {
    return outBack((gT - d / UPV) / UPT);
}

float waveOf(float d) {
    return 1.0 + WAVEA * sin(6.2831853 * (d / WAVEL - gT / WAVEP));
}

float slamOf() {
    float k = clamp((gT - SLAM + SLAMT) / SLAMT, 0.0, 1.0);
    return 1.0 - k * k;
}

float windOf() {
    return 1.0 + WINDUP * smoothstep(WINDT, SLAM - SLAMT, gT);
}

float headOf(float xa) {
    return HEAD * smoothstep(0.0, HEADT, gT) * slamOf() * smoothstep(gNow - RAMPL, gNow, xa);
}

float lastLock() {
    return gNow < gXG || gLG < 1.0 ? -1.0 : min(floor((gNow - gXG) / gSG), gNG - 1.0);
}

float rippleAt(float xa) {
    float kL = lastLock();
    float h = 0.0;
    for (int i = 0; i < 3; ++i) {
        float k = kL - float(i);
        if (k < 0.0)
            break;
        float a = gXG + k * gSG;
        float d = gNow - a;
        h += exp(-sq((xa - a + RIPV * d) / RIPW)) * exp(-d / RIPD);
    }
    return RIPH * h * slamOf();
}

float fieldR(float xa) {
    return headOf(xa) + rippleAt(xa);
}

float visEnd() {
    float kL = lastLock();
    return kL < 0.0 ? min(gNow, gLf) : min(gXG + (kL + 1.0) * gSG, gLf);
}

vec4 pieceAt(float xa) {
    if (xa < gL0) {
        float k = clamp(floor(xa / gS0), 0.0, gN0 - 1.0);
        return vec4(k * gS0, gS0, k, 0.0);
    }
    if (xa < gXG || gLG < 1.0)
        return vec4(gL0, max(gXG - gL0, 0.0), 0.0, 1.0);
    float k = clamp(floor((xa - gXG) / gSG), 0.0, gNG - 1.0);
    return vec4(gXG + k * gSG, gSG, k, 2.0);
}
