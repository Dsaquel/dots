vec4 hall(vec3 ro, vec3 rd, float t0, out vec3 surf, out float tSurf, out int kind) {
    float W = size.x;
    float H = size.y;
    pathT0 = t0;
    vec4 acc = vec4(0.0);
    surf = vec3(0.0);
    kind = NONE;
    float tx = exitOf(ro.x, rd.x, -aisle, W + aisle);
    float ty = exitOf(ro.y, rd.y, vault, floorY);
    float tBox = min(tx, ty);
    tSurf = tBox;
    for (int i = 0; i < DOORS; ++i) {
        if (i >= doorsN)
            break;
        float zi = doorZ[i];
        if (zi <= ro.z + 0.01)
            continue;
        float tf = (zi - wall - ro.z) / rd.z;
        if (tf >= tBox)
            break;
        rom = doorRoman[i];
        romLen = doorRomanLen[i];
        kin = doorKindle[i];
        zDoor = zi;
        o = ro - vec3(0.0, 0.0, zi);
        d = rd;
        lampL = lamp - vec3(0.0, 0.0, zi);
        if (doorLit[i] > 0.001 && !cheap) {
            vec4 lamp_ = vec4(0.0);
            vec3 glow_ = vec3(0.0);
            for (int k = 0; k < pair; ++k) {
                float tk;
                vec4 l = lantern(i, k, ro, rd, min(tf, tBox), tk);
                lamp_ = lamp_.a > 0.0 ? lamp_ : l;
                glow_ += halo(i, k, ro, rd, min(tf, tBox));
            }
            acc = over(acc, lamp_);
            acc.rgb += glow_ * (1.0 - acc.a);
            if (acc.a > 0.996)
                return acc;
        }
        if (tf > 0.0) {
            vec2 P = ro.xy + rd.xy * tf;
            archInit();
            bool walled = P.x <= 0.0 || P.x >= W || P.y <= 0.0 || P.y >= H;
            float pxf = max(hallDepth(tf) / focal, 1e-3);
            vec4 f = (walled && !cheap) || (!walled && min(min(P.x, W - P.x), min(P.y, H - P.y)) < 2.0 * pxf) ? facade(P, pxf, -wall) : vec4(0.0);
            if (walled) {
                surf = entrance(i, P, tf, f);
                tSurf = tf;
                kind = WALLED;
                return acc;
            }
            if (f.a > 0.0)
                acc = over(acc, vec4(hallFog(f.rgb / f.a, hallDepth(tf)) * f.a, f.a));
        }
        float td = (zi - ro.z) / rd.z;
        float jx = exitOf(ro.x, rd.x, 0.0, W);
        float jy = exitOf(ro.y, rd.y, 0.0, H);
        float tj = min(jx, jy);
        if (tj < td) {
            surf = jamb(i, ro + rd * tj, tj, jx < jy);
            tSurf = tj;
            kind = JAMB;
            return acc;
        }
        vec3 hl;
        vec3 hr;
        float tl = leafT(i, true, o, rd, hl);
        float tr = leafT(i, false, o, rd, hr);
        bool leftFirst = tl > 0.0 && (tr < 0.0 || tl <= tr);
        for (int k = 0; k < pair; ++k) {
            bool left = (k == 0) == leftFirst;
            if ((left ? tl : tr) > 0.0)
                acc = over(acc, leafShade(i, left, left ? hl : hr, rd));
        }
        if (acc.a > 0.996)
            return acc;
    }
    vec3 Q = ro + rd * tBox;
    float depth = hallDepth(tBox);
    float px = max(depth / focal, 1e-3) / max(abs(ty < tx ? rd.y : rd.x), 0.05);
    vec3 c;
    if (ty < tx && rd.y > 0.0) {
        kind = FLOORED;
        float tile = size.x * 0.25;
        vec2 g = vec2(Q.x + tile * 0.5, Q.z) / tile;
        vec2 gf = abs(fract(g) - 0.5) * tile;
        float e = tile * 0.5 - max(gf.x, gf.y);
        float grout = (1.0 - smoothstep(0.6 * px, 1.6 * px + 1.5, e)) * fine(px);
        vec3 base = paving * (0.9 + 0.16 * hash(floor(g) + 11.0));
        beamPx = px * 2.5;
        c = mix(base, keyline * 0.35 + base * 0.4, grout * 0.6) * (hallLight(Q, vec3(0.0, -1.0, 0.0)) + beamAt(Q) * max(sunDir.y, 0.0) * 1.6);
    } else if (ty < tx) {
        kind = VAULTED;
        c = stone * 0.4 * hallLight(Q, vec3(0.0, 1.0, 0.0));
    } else {
        kind = SIDED;
        vec3 N = vec3(rd.x > 0.0 ? -1.0 : 1.0, 0.0, 0.0);
        float zl = Q.z - roomOf(Q.z) * spacing;
        float cz;
        float sd = zl < spacing - wall ? lancet(zl, Q.y, cz) : 1e4;
        beamPx = px * 2.5;
        c = ashlar(vec2(Q.z, Q.y), px, 3.0) * (hallLight(Q, N) + beamAt(Q) * max(dot(N, -sunDir), 0.0));
        float win = clamp(0.5 - sd / px, 0.0, 1.0);
        if (win > 0.0) {
            float lit_ = N.x * sunDir.x > 0.0 ? 1.0 : 0.5;
            vec3 g = stained(zl, Q.y, cz, px) * glaze * lit_ * (0.75 + 0.5 * smoothstep(0.8 * H, -0.3 * H, Q.y));
            c = mix(c, g, win);
        }
        float band = (1.0 - smoothstep(0.5 * casing, 0.5 * casing + px, sd)) * (1.0 - win);
        c = mix(c, leadBase * 0.7 * hallLight(Q, N), band * 0.85);
        c += keyline * exp(-sq(sd / max(1.2 * px, 1.0))) * 0.3 * fine(px);
    }
    surf = hallFog(c, depth);
    return acc;
}

vec4 nave(vec2 p) {
    vec3 ray = camF * focal + camR * (p.x - centre.x) + camU * (p.y - centre.y);
    rawLen = length(ray);
    vec3 rd = ray / rawLen;
    lodBias = 0.0;
    inHall = true;
    cameC = came;
    archInit();
    pair = doorsN >= 0 ? 2 : 1;
    vec4 acc = vec4(0.0);
    vec3 surf = vec3(0.0);
    float tS = 0.0;
    float fres = 0.0;
    vec3 ro = eye;
    vec3 dir = rd;
    float t0 = 0.0;
    for (int b = 0; b < pair; ++b) {
        vec3 s;
        float t;
        int k;
        vec4 a = hall(ro, dir, t0, s, t, k);
        if (b > 0) {
            surf = mix(surf, a.rgb + s * (1.0 - a.a), fres);
            break;
        }
        acc = a;
        surf = s;
        tS = t;
        if (k != FLOORED || a.a >= 0.996)
            break;
        fres = polish * (0.3 + 0.7 * pow(1.0 - clamp(rd.y, 0.0, 1.0), 4.0));
        vec3 P = eye + rd * t;
        dir = vec3(rd.x, -rd.y, rd.z);
        ro = P + dir;
        t0 = t;
        lodBias = 1.5;
        cheap = true;
    }
    cheap = false;
    vec3 col = acc.rgb + surf * (1.0 - acc.a);
    if (haze > 0.0) {
        float tEnd = min(tS, 5.0 * rest);
        float jit = fract(52.9829189 * fract(dot(p, vec2(0.06711056, 0.00583715))));
        beamPx = 60.0;
        vec3 shaft = vec3(0.0);
        for (int k = 0; k < 5; ++k)
            shaft += beamAt(eye + rd * (tEnd * (float(k) + jit) / 5.0));
        col += shaft * haze * tEnd / 5.0 * (1.0 - 0.6 * acc.a);
    }
    return vec4(col, 1.0);
}
