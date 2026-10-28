vec4 tympanum(vec2 P, float px, float z) {
    float W = size.x;
    float A = arch;
    float cw = casing;
    vec2 oc = vec2(W * 0.5, -A * 0.47);
    float rho = A * 0.34;
    float dO = length(P - oc);
    float rays = 11.0;
    float sector = (atan(P.x - oc.x, oc.y - P.y) + PI) / (2.0 * PI) * rays * 2.0;
    float si = floor(sector);
    float ring = dO < rho * 1.7 ? 0.0 : (dO < rho * 2.6 ? 1.0 : 2.0);
    float ex = min(min(fract(sector), 1.0 - fract(sector)) * PI / rays * dO, min(abs(dO - rho * 1.7), abs(dO - rho * 2.6)));
    float near_ = exp(-max(dO - rho, 0.0) / (A * 0.42));
    vec3 hue_ = mix(jewel0, jewel1, 0.2 + 0.3 * hash(vec2(si, ring) + 7.0) + 0.25 * ring);
    hue_ = mix(hue_, mix(hot, keyline, 0.45), kin * 0.6 * near_);
    float backlit = (0.3 + 0.7 * near_) * (0.6 + 0.9 * kin);
    vec3 c = hue_ * backlit * (0.9 + 0.2 * hash(vec2(si, ring) + 3.0));
    float lead = 1.0 - smoothstep(0.6 * px, 1.6 * px, ex);
    c = mix(c, cameC, lead);
    if (dO < rho && romLen > 0) {
        vec3 field = mix(jewel0, jewel1, 0.4) * (0.3 + 0.45 * (1.0 - dO / rho));
        float width = numeralWidth();
        float h = min(rho * 0.95, rho * 1.5 / width);
        vec2 q = P - oc;
        float dd = numeral(q, h, width);
        float cov = clamp(0.5 - dd / px, 0.0, 1.0);
        vec3 shadow = field * (1.0 - 0.55 * exp(-max(numeral(q - vec2(0.03, 0.05) * h, h, width), 0.0) / (h * 0.04)));
        c = cov > 0.0 ? mix(shadow, gilt(q, h, width, dd, vec3(P, z), px), cov) : shadow;
    }
    float shade = (0.5 + 0.5 * smoothstep(0.0, 0.18 * A, -(dArc(P) + cw))) * (0.6 + 0.4 * smoothstep(0.0, 0.1 * A, -(P.y + 0.6 * cw)));
    vec4 col = vec4(c * 0.95 * shade, 0.95);
    float rc = 1.0 - smoothstep(cw * 0.32, cw * 0.32 + px, abs(dO - rho));
    if (rc > 0.0)
        col = over(vec4(molding((dO - rho) / (cw * 0.64) + 0.5, cw * 0.64, vec3(0.0, 0.0, -1.0), vec3(normalize(P - oc), 0.0), vec3(P, z), px, 0.0), 1.0) * rc, col);
    return col;
}

float outline(vec2 P) {
    float W = size.x;
    float H = size.y;
    float cw = casing;
    vec2 dd = abs(P - vec2(W * 0.5, 0.5 * (H + 0.8 * cw))) - vec2(W * 0.5 + 1.25 * cw, 0.5 * (H + 0.8 * cw) + (arch >= 1.0 ? 0.0 : 0.6 * cw));
    float b = length(max(dd, 0.0)) + min(max(dd.x, dd.y), 0.0);
    return P.y < 0.0 && arch >= 1.0 ? min(b, max(dArc(P), abs(P.x - W * 0.5) - aHalf)) : b;
}

vec4 portal() {
    float W = size.x;
    float H = size.y;
    float cw = casing;
    if (d.z <= 1e-4 || o.z >= 0.0)
        return vec4(0.0);
    float zf = -wall;
    float zt = zf + 0.42 * wall;
    bool front = o.z < zf;
    float z0 = front ? zf : o.z;
    vec2 P0 = at(z0);
    float depth0 = depthOf(tAt(z0));
    float px0 = max(depth0 / focal, 1e-3);
    vec4 deep = vec4(0.0);
    if (P0.x > 0.0 && P0.x < W && P0.y > 0.0 && P0.y < H) {
        float ex = d.x < 0.0 ? o.z - o.x * d.z / d.x : (d.x > 0.0 ? o.z + (W - o.x) * d.z / d.x : 1e9);
        float ey = d.y < 0.0 ? o.z - o.y * d.z / d.y : (d.y > 0.0 ? o.z + (H - o.y) * d.z / d.y : 1e9);
        float zh = min(ex, ey);
        if (zh < 0.0) {
            bool upright = ex < ey;
            float dz = max(zh, z0);
            vec2 Ph = at(dz);
            vec3 N = upright ? vec3(d.x < 0.0 ? 1.0 : -1.0, 0.0, 0.0) : vec3(0.0, d.y < 0.0 ? 1.0 : -1.0, 0.0);
            vec3 bounce = filled > 0.5 ? texture(tex, clamp(Ph, vec2(6.0), size - 6.0) / texSize, 6.0).rgb : vec3(0.0);
            float th = tAt(dz);
            vec3 rev = reveal((dz - zf) / -zf, upright ? Ph.y : Ph.x, upright ? H : W, N, vec3(Ph, dz), pxOf(th), bounce);
            deep = vec4(mix(rev, fogColor, fogOf(depthOf(th))), 1.0);
        } else {
            vec2 Pb = at(0.0);
            vec2 inner = min(Pb, size - Pb);
            deep = vec4(0.0, 0.0, 0.0, 0.42 * exp(-max(min(inner.x, inner.y), 0.0) / (0.035 * H)) * (1.0 - smoothstep(0.0, 0.7, phi * doors)));
        }
    } else if (front && arch >= 1.0 && P0.y < -0.6 * cw && dArc(P0) < -cw) {
        vec2 Pt = at(zt);
        float pxt = pxOf(tAt(zt));
        float cov = clamp(0.5 - (dArc(Pt) + cw) / pxt, 0.0, 1.0) * clamp(0.5 - (Pt.y + 0.6 * cw) / pxt, 0.0, 1.0);
        float lo = zf;
        float hi = zt;
        for (int i = 0; i < 7; ++i) {
            float m = 0.5 * (lo + hi);
            if (dArc(at(m)) + cw < 0.0)
                lo = m;
            else
                hi = m;
        }
        float dz = 0.5 * (lo + hi);
        vec2 Pi = at(dz);
        vec3 N = vec3(-normalize(Pi - archCentre(Pi)), 0.0);
        vec3 intr = intrados((dz - zf) / (zt - zf), N, vec3(Pi, dz), pxOf(tAt(dz)));
        deep = mix(vec4(intr, 1.0), tympanum(Pt, pxt, zt), cov);
    } else if (front) {
        deep = vec4(0.0, 0.0, 0.0, 0.2 * exp(-max(outline(P0), 0.0) / (1.2 * cw)));
    }
    bool inner = P0.x > 0.3 * cw && P0.x < W - 0.3 * cw && P0.y > 0.3 * cw && P0.y < H - 0.9 * cw;
    vec4 col = over(front && !inner ? facade(P0, px0, zf) : vec4(0.0), deep);
    col.rgb = mix(col.rgb, fogColor * col.a, fogOf(depth0));
    return col * smoothstep(rest * 0.02, rest * 0.12, depth0);
}

vec4 pane(bool left, out float tHit) {
    tHit = -1.0;
    float W = size.x;
    float H = size.y;
    bool split = doors > 0.5;
    if (!split && !left)
        return vec4(0.0);
    float len = split ? (left ? seam : W - seam) : W;
    float ang = split ? phi : 0.0;
    float sp = sin(ang);
    float cp = cos(ang);
    vec3 hinge = vec3(left ? 0.0 : W, 0.0, 0.0);
    vec3 U = vec3(left ? cp : -cp, 0.0, sp);
    vec3 n = left ? vec3(sp, 0.0, -cp) : vec3(-sp, 0.0, -cp);
    float den = dot(d, n);
    if (abs(den) < 1e-5)
        return vec4(0.0);
    float t = dot(hinge - o, n) / den;
    if (t <= 1.0)
        return vec4(0.0);
    vec3 Q = o + d * t;
    float a = dot(Q - hinge, U);
    float y = Q.y;
    if (a < 0.0 || a > len || y < 0.0 || y > H)
        return vec4(0.0);
    tHit = t;
    float depth = depthOf(t);
    float px = max(depth / focal, 1e-3);
    vec2 src = vec2(left ? a : W - a, y);
    float lod = clamp(blurK * abs(depth - focus) / max(focus, 1.0), 0.0, 4.5);
    vec4 c = filled > 0.5 ? texture(tex, src / texSize, lod + (mirror > 0.0 ? 1.5 : 0.0)) : vec4(0.0);
    float k = glass * (split ? max(smoothstep(0.0, 0.55, ang), 0.55 * frame) : frame);
    vec4 col = c;
    if (k > 0.001) {
        vec3 nf = den < 0.0 ? n : -n;
        vec3 V = -d;
        float cosv = clamp(abs(dot(V, n)), 0.0, 1.0);
        float fres = 0.04 + 0.96 * pow(1.0 - cosv, 5.0);
        vec3 R = reflect(d, nf);
        float band = exp(-sq((R.x * 0.85 - R.y * 0.3 - 0.18) / 0.12));
        vec3 sky = mix(fogColor * (ink > 0.5 ? 0.45 : 1.6), mix(hot, vec3(1.0), 0.3) * 0.7, smoothstep(-0.5, 0.6, -R.y));
        vec3 env = sky * 0.5 + mix(hot, vec3(1.0), 0.55) * band;
        vec3 L = normalize(lampL - Q);
        vec3 Hv = normalize(L + V);
        float nh = max(dot(nf, Hv), 0.0);
        float spec = pow(nh, 900.0) * 0.28 + pow(nh, 80.0) * 0.018;
        vec2 gi;
        float ex = lattice(vec2(a, y), vec2(96.0, 140.0), gi);
        vec3 tint = jewelOf(hash(gi + (left ? 0.0 : 31.0)));
        float sheet = k * (ink > 0.5 ? 0.07 : 0.12);
        col = over(c, vec4(mix(edgeGlass, tint, 0.55) * 0.5 * sheet, sheet));
        float leadLine = (1.0 - smoothstep(0.6 * px, 1.7 * px, ex)) * k * (1.0 - c.a) * 0.8;
        col = over(vec4(ink > 0.5 ? sepia : leadLow * 1.3 + leadBase * 0.4, 1.0) * leadLine, col);
        col.rgb += (env * fres * 0.9 + mix(hot, vec3(1.0), 0.4) * spec) * k * (ink > 0.5 ? 0.3 : 1.0);
        if (split) {
            float edgeOn = smoothstep(0.02, 0.22, ang);
            float ed = min(min(a, len - a), min(y, H - y));
            float stile = 7.0;
            if (ed < stile + 1.5 * px && edgeOn > 0.0) {
                float sc = (1.0 - smoothstep(stile - 0.5 * px, stile + 0.5 * px, ed)) * edgeOn;
                vec3 run = left ? vec3(cp, 0.0, sp) : vec3(-cp, 0.0, sp);
                vec3 T = ed == a ? run : (ed == len - a ? -run : vec3(0.0, ed == y ? 1.0 : -1.0, 0.0));
                col = over(vec4(molding(ed / stile, stile, n, T, Q, px, 0.0), 1.0) * sc, col);
                col.rgb += keyline * exp(-sq((ed - stile - 0.6 * px) / (0.9 * px))) * 0.7 * edgeOn;
            }
            float leak = sin(PI * clamp(ang / 0.55, 0.0, 1.0)) * glass;
            col.rgb += mix(hot, vec3(1.0), 0.35) * leak * (exp(-(len - a) / (10.0 * px)) * 0.55 + exp(-(len - a) / (90.0 * px)) * 0.16);
            float thick = 6.0 * sp;
            float fe = len - a;
            if (fe < thick) {
                float t0 = fe / max(thick, 1e-3);
                vec3 eg = mix(edgeGlass, tint, 0.4) * (0.45 + 0.4 * t0) + mix(hot, vec3(1.0), 0.5) * exp(-sq(t0 - 0.15) / 0.01) * 0.25;
                col = vec4(eg, 1.0) * 0.55 + col * 0.45;
            }
        }
    }
    col.rgb = mix(col.rgb, fogColor * col.a, fogOf(depth));
    return col * smoothstep(rest * 0.04, rest * 0.26, depth) * dim;
}

vec4 room(vec2 p) {
    vec3 ray = camF * focal + camR * (p.x - centre.x) + camU * (p.y - centre.y);
    rawLen = length(ray);
    vec3 dir = ray / rawLen;
    vec3 from = eye;
    float floorT = 0.0;
    if (mirror > 0.0) {
        if (dir.y <= 1e-4)
            return vec4(0.0);
        floorT = (mirror - eye.y) / dir.y;
        from.y = 2.0 * mirror - eye.y;
        dir.y = -dir.y;
    }
    vec3 rel = from - origin;
    o = vec3(dot(rel, axisX), dot(rel, axisY), dot(rel, axisZ));
    d = vec3(dot(dir, axisX), dot(dir, axisY), dot(dir, axisZ));
    vec3 lr = lamp - origin;
    lampL = vec3(dot(lr, axisX), dot(lr, axisY), dot(lr, axisZ));
    float tl;
    float tr;
    vec4 L = pane(true, tl);
    vec4 R = pane(false, tr);
    vec4 col = tl > tr ? over(R, L) : over(L, R);
    if (frame > 0.001) {
        archInit();
        col = over(portal() * frame * dim, col);
    }
    if (mirror > 0.0) {
        float lift_ = clamp((mirror - at(0.0).y) / size.y, 0.0, 2.0);
        float grazing = 0.35 + 0.65 * pow(1.0 - clamp(dir.y * -1.0, 0.0, 1.0), 4.0);
        col *= sheen * grazing * exp(-lift_ * 1.8) * smoothstep(rest * 0.05, rest * 0.3, depthOf(floorT));
    }
    return col;
}
