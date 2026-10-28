void main() {
    vec2 p = v_texcoord * box;
    vec2 hs = win.zw * 0.5;
    vec2 q = p - win.xy - hs;
    float s = sdRoundBox(q, hs, radius);
    if (probe > 0.5) {
        fragColor = vec4(0.0, 1.0, 0.0, 1.0) * clamp(1.0 - abs(s - offset), 0.0, 1.0) * alpha;
        return;
    }
    float inside = clamp(0.5 - s, 0.0, 1.0);
    vec4 under = veil * inside;
    if (shadow.a > 0.001) {
        float s2 = sdRoundBox(q - shadowOffset, hs, radius);
        under += shadow * (1.0 - smoothstep(-shadowBlur * 0.5, shadowBlur * 1.25, s2)) * (1.0 - inside);
    }
    bool grand = build.z > 0.5 && build.x >= 0.0;
    bool hinging = hinge.x >= 0.0;
    bool forging = athanor.x >= 0.0;
    if (s < (build.x < 0.0 ? (hinging ? -60.0 : -12.0) : (grand ? -INQ - 40.0 : -70.0)) || s > (build.x < 0.0 ? (hinging ? 1e4 : offset + hwOn + 18.0) : (grand ? 1e4 : 70.0))) {
        fragColor = under * alpha;
        return;
    }
    vec2 e = max(hs - vec2(radius), vec2(0.0));
    float hw = mix(hwOff, hwOn, on);
    float b0 = 1.0;
    float b1 = offset - hw;
    float sc = 0.5 * (b0 + offset + hw);
    float hy = 0.5 * (offset + hw - b0) + 0.5;
    vec2 lp = lightPos.xy - p;
    float pl = exp(-dot(lp, lp) / max(lightPos.w * lightPos.w, 1.0));
    if (hinging) {
        gM = hinge.x;
        gT = hinge.y;
        gDir = normalOf(gM);
        gHS = hs;
        gHG = 0.5 * gone.zw;
        gCG = gone.xy + gHG - win.xy - hs;
        bool horiz = mod(gM, 2.0) > 0.5;
        gL0 = max((horiz ? grow.x : grow.y) - 2.0 * radius, 1.0);
        gLf = max((horiz ? hinge.z : hinge.w) - 2.0 * radius, gL0);
        gLG = clamp((horiz ? gone.z : gone.w) - 2.0 * radius, 0.0, gLf - gL0);
        gXG = gLf - gLG;
        gN0 = max(1.0, floor(gL0 / pieceLen + 0.5));
        gS0 = gL0 / gN0;
        gNG = max(1.0, floor(gLG / pieceLen + 0.5));
        gSG = gLG / gNG;
        gNow = 2.0 * max((horiz ? hs.x : hs.y) - radius, 0.0);
        gLvG = grow.z;
        gV = vanish - win.xy - hs;
        gL = lightPos.xy - win.xy - hs;
        float sG = sdRoundBox(q - gCG, gHG, radius);
        if (s > 96.0 && (sG < -90.0 || sG > 96.0)) {
            fragColor = under * alpha;
            return;
        }
        float shade = 0.0;
        vec3 light = vec3(0.0);
        vec3 glow = vec3(0.0);
        vec4 col = vec4(0.0);
        if (gT < SLAM) {
            vec4 pmR = perim(q, e, radius + SM);
            float rel = mod(pmR.y - 2.0 * gM + 8.0, 8.0);
            if (rel > 2.5 && rel < 5.5)
                col = ringLook(q, hs, 0.0, p, pl, on, vec2(1.0), 0.0, pmR);
            col = over(sideR(q, mod(gM + 1.0, 4.0), p, pl, shade), col);
            col = over(sideR(q, mod(gM + 3.0, 4.0), p, pl, shade), col);
            col = over(seamOf(q, p, pl, shade, glow), col);
            col = over(floatG(q, p, pl, shade, light), col);
            col = over(clasp(q, mod(gM + 1.0, 4.0), p, pl, shade), col);
            col = over(clasp(q, mod(gM + 3.0, 4.0), p, pl, shade), col);
        } else
            col = afterR(q, p, pl, shade, light);
        col.rgb += light * (1.0 - col.a) * dark;
        col = over(vec4(mix(jewelC, hot, 0.25), 1.0) * clamp(dot(glow, vec3(0.3333)) * 0.7, 0.0, 0.75) * dark, col);
        col.rgb = emit(col.rgb, glow * 0.4 * dark);
        col = over(vec4(mix(jewelC, low, 0.3), 1.0) * clamp(dot(light + glow, vec3(0.3333)) * 0.9, 0.0, 0.85) * (1.0 - dark), col);
        under += vec4(0.0, 0.0, 0.0, min(shade, 0.6) * (1.0 - under.a));
        fragColor = (col + under * (1.0 - col.a)) * alpha;
        return;
    }
    if (grand && (s > offset + hw + 24.0 || s < -48.0)) {
        float shade = 0.0;
        vec4 col = s > max(reachOf(q.y < 0.0 ? room.x : room.z, sc, hy), reachOf(q.x > 0.0 ? room.y : room.w, sc, hy)) ? vec4(0.0) : cloud(q, e, hs, p, pl, b0, b1, hw, sc, hy, shade);
        col.rgb = emit(col.rgb, rays(q, e, s));
        under += vec4(0.0, 0.0, 0.0, min(shade, 0.6) * (1.0 - under.a));
        fragColor = (col + under * (1.0 - col.a)) * alpha;
        return;
    }
    float rr = radius + SM;
    float per = 4.0 * (e.x + e.y) + 6.2831853 * rr;
    vec4 pm = perim(q, e, rr);
    float u = pm.x;
    float side = pm.y;
    float x = pm.z;
    float len = pm.w;
    bool arc = mod(side, 2.0) > 0.5;

    float poured = forging && athanor.x < SEAT ? 0.0 : 1.0;
    float glowing = forging && athanor.x >= SEAT ? exp(-(athanor.x - SEAT) / COOLING) * (1.0 - smoothstep(LIFE - 120.0, LIFE, athanor.x)) : 0.0;

    float ca = call.a;
    float dla = circ(u, laid.x, per);
    float dg = circ(u, gap.x, per);
    float dcut = circ(u, cut.x, per);
    float shown = clamp(laid.y - dla + 0.5, 0.0, 1.0) * clamp(dg - gap.y + 0.5, 0.0, 1.0);
    shown *= (1.0 - clamp(dcut - cut.y + 0.5, 0.0, 1.0) * clamp(cut.z - dcut + 0.5, 0.0, 1.0)) * poured;
    float molten = melt.z * clamp(dcut - min(melt.x, melt.y) + 0.5, 0.0, 1.0) * clamp(max(melt.x, melt.y) - dcut + 0.5, 0.0, 1.0) * exp(-abs(dcut - melt.x) / max(melt.w, 1.0));
    float tip = laid.z * exp(-sq((laid.y - dla) / 6.0)) * step(dla, laid.y + 3.0) + gap.z * exp(-sq((dg - gap.y) / 6.0)) * step(gap.y - 3.0, dg);

    float sb = 0.5 * (b0 + b1);
    float bw = max(b1 - b0, 0.5);

    float n = arc ? 1.0 : max(1.0, floor(len / pieceLen + 0.5));
    float seg = len / n;
    float k = min(floor(x / seg), n - 1.0);
    float fx = x - k * seg;
    float id = side * 97.0 + k;
    float dj = min(fx, seg - fx);
    float uj = fx < seg - fx ? u - fx : u + seg - fx;

    vec2 w = abs(q) - hs + vec2(radius);
    vec2 gq = sign(q) * (min(w.x, w.y) > 0.0 ? normalize(w) : (w.x > w.y ? vec2(1.0, 0.0) : vec2(0.0, 1.0)));
    vec2 g = vec2(gq.x, -gq.y);

    bool building = build.x >= 0.0;
    float last = T0C + RUNC;
    vec2 nb = build.yz;
    float land = landOf(side, k, n);
    float ti = build.x - land;
    float impact = building && ti >= 0.0 ? 1.0 : 0.0;
    float landed = !building ? 1.0 : (arc ? smoothstep(0.0, 0.3, ti / POP) : impact);
    float flash = impact * exp(-ti / (grand ? 14.0 : 22.0));
    float glow = impact * exp(-ti / (grand ? 140.0 : 110.0));
    float jolt = 0.0;
    if (grand && !arc) {
        float o = orderOf(side);
        float hS = min(headAt(build.x, nb) - beforeOf(o, nb), n - 1.0);
        for (int j = 0; j < 3; ++j) {
            float m = hS - float(j);
            if (m < 0.5)
                break;
            float age = build.x - chainLand(o, m, nb);
            float xb = build.w > 0.0 ? m * seg - x : x - (n - m) * seg;
            jolt += exp(-sq((xb - SURGE * age) / 16.0)) * exp(-age / JOLT) * step(-6.0, xb);
        }
    }
    float turn = 0.0;
    float swell = 0.0;
    float cabFlash = 0.0;
    if (grand) {
        float corner = q.x > 0.0 ? (q.y < 0.0 ? 1.0 : 3.0) : (q.y > 0.0 ? 5.0 : 7.0);
        float big = abs(corner - (build.w > 0.0 ? 7.0 : 1.0)) < 0.5 ? 1.6 : 1.0;
        vec2 tp = turnOf(corner, nb);
        float age = build.x - tp.x;
        if (arc && age >= 0.0) {
            float f = clamp(age / tp.y, 0.0, 1.0);
            float behind = build.w > 0.0 ? f * len - x : x - (1.0 - f) * len;
            float after = max(age - tp.y, 0.0);
            turn = exp(-sq(behind / 5.0)) * exp(-after / 50.0) * 2.4 + step(0.0, behind) * exp(-after / (160.0 * big)) * 0.6;
        }
        float pk = age - 0.5 * tp.y;
        swell = pk > -60.0 ? exp(-sq(pk / 50.0)) * big : 0.0;
        cabFlash = pk >= 0.0 ? exp(-pk / (60.0 * big)) * big : 0.0;
    }
    float sB = s + (grand ? impact * 4.0 * exp(-ti / 18.0) * cos(ti * 0.15) + 1.5 * jolt : impact * 3.0 * exp(-ti / 16.0) * cos(ti * 0.16));
    float held = shown * landed;

    float dSeal = circ(uj, seal.x, per);
    float heat = seal.z * (dSeal <= seal.y ? exp(-(seal.y - dSeal) / 110.0) : exp(-sq((dSeal - seal.y) / 10.0)));

    vec4 col = vec4(0.0);

    float kf = building && !arc && ti < 0.0 ? clamp((ti + (grand ? DIVE : FLY)) / (grand ? DIVE : FLY), 0.0, 1.0) : 0.0;
    float blur = 0.6 + 4.0 * (1.0 - kf * kf);
    under += vec4(0.0, 0.0, 0.0, 0.4 * kf * kf * smoothstep(b0 - blur, b0 + blur, s) * (1.0 - smoothstep(offset + hw - blur, offset + hw + blur, s)) * smoothstep(0.0, 2.0 * blur, dj));

    float tl;
    if (grand && arc) {
        float sp = side - 1.0;
        float sn = mod(side + 1.0, 8.0);
        vec2 ns = bricks();
        float np = mod(sp, 4.0) < 0.5 ? ns.x : ns.y;
        float nn = mod(sn, 4.0) < 0.5 ? ns.x : ns.y;
        tl = fx < 0.5 * seg ? landOf(sp, np - 1.0, np) : landOf(sn, 0.0, nn);
    } else if (grand)
        tl = fx < 0.5 * seg ? (k > 0.5 ? max(land, landOf(side, k - 1.0, n)) : land) : (k < n - 1.5 ? max(land, landOf(side, k + 1.0, n)) : land);
    else {
        float nNext = max(1.0, floor((mod(side + 1.0, 4.0) > 1.0 ? 2.0 * e.y : 2.0 * e.x) / pieceLen + 0.5));
        tl = fx < 0.5 * seg ? (arc ? last : land) : (arc ? landOf(side + 1.0, 0.0, nNext) : (k < n - 1.5 ? landOf(side, k + 1.0, n) : land));
    }
    float tw = build.x - tl - (grand ? 0.0 : SETTLE);
    float tp = grand ? clamp(tw / 80.0, 0.0, 1.0) : clamp((tw - 0.3 * SEAM) / 90.0, 0.0, 1.0);
    float linked = !building || arc ? 1.0 : step(grand ? 0.0 : 0.3 * SEAM, tw);
    float taper = mix(smoothstep(0.0, 8.0, dj), 1.0, linked);
    float halo = on * held * taper * exp(-max(sB - offset - hw, 0.0) / 6.0) * step(offset, sB) * 0.35;
    vec3 jewel = arc ? jewelC : (mod(k + side * 0.5, 2.0) < 1.0 ? jewelA : jewelB);
    vec3 amber = jewelC - (1.0 - unlit) * 0.6 * dot(jewelC, vec3(0.2126, 0.7152, 0.0722));
    col.rgb += (jewel * 0.7 + pool * pl * 0.6) * halo;
    float rim = on * held * taper * exp(s / 4.0) * step(s, 0.0) * (0.1 + 0.12 * pl);
    col.rgb += (jewel * 0.6 + pool * 0.5 + hi * 0.15) * rim;
    col.rgb += call.rgb * ca * held * exp(-max(sB - offset - hw, 0.0) / 7.0) * step(offset, sB) * 0.9;

    float bandShape = clamp(sB - b0 + 0.5, 0.0, 1.0) * clamp(b1 - sB + 0.5, 0.0, 1.0);
    float bandCov = bandShape * held;
    if (bandCov > 0.0) {
        float streak = 0.9 + 0.2 * vnoise(vec2(x * 0.07 + id * 3.1, (sB - sb) * 0.3 + id));
        float across = (sB - sb) / (bw * 0.5);
        vec3 dark = (arc ? amber : jewel * unlit) * streak + sky * 0.16 * smoothstep(-0.2, 1.0, across) * (0.6 + 0.4 * streak);
        vec3 bright = tame(jewel * (1.0 + 0.3 * pl) * streak + jewel * jewel * 0.35 + pool * pl * 0.1);
        vec3 glass = mix(mix(dark, bright, on), call.rgb * (0.9 + 0.3 * streak), ca * 0.65);
        col = vec4(glass, 1.0) * bandCov * 0.95 + col * (1.0 - bandCov * 0.95);
    }

    float pearlPop = building && !arc ? (grand ? 1.0 + 6.0 * pow(tp - 1.0, 3.0) + 5.0 * pow(tp - 1.0, 2.0) : 1.0 + 2.70158 * pow(tp - 1.0, 3.0) + 1.70158 * pow(tp - 1.0, 2.0)) : 1.0;
    float pr = (bw * 0.5 + 0.15) * pearlPop;
    float dp = 1e5;
    if (!arc) {
        if (k > 0.5) dp = fx;
        if (k < n - 1.5) dp = min(dp, seg - fx);
    }
    float pd = length(vec2(dp, sB - sb));
    float pearlCov = clamp(pr - pd + 0.5, 0.0, 1.0) * held * linked;
    if (pearlCov > 0.0) {
        float nz = sqrt(max(1.0 - sq(pd / pr), 0.0));
        vec2 pv = (vec2(g.y, -g.x) * (fx < 0.5 * seg ? fx : fx - seg) + g * (sB - sb)) / pr;
        vec3 pc = metal(normalize(vec3(pv * 0.9, nz + 0.05)), p, nz, pl) * mix(1.05, 1.25, on);
        pc += call.rgb * ca * (0.5 + 0.6 * nz);
        col = vec4(pc, 1.0) * pearlCov + col * (1.0 - pearlCov);
    }

    float leadShape = clamp(0.55 + 0.5 - abs(sB - b0), 0.0, 1.0);
    leadShape = max(leadShape, clamp(0.6 + 0.5 - min(x, len - x), 0.0, 1.0) * bandShape);
    float lead = leadShape * held;
    if (lead > 0.0) {
        vec3 lc = metal(vec3(0.0, 0.0, 1.0), p, 0.7, pl) * 0.55;
        col = vec4(lc, 1.0) * lead + col * (1.0 - lead);
    }

    float dc = sB - offset;
    float cov = clamp(hw + 0.5 - abs(dc), 0.0, 1.0);
    float bd = length(vec2(dj, dc));
    float br = hw + mix(0.5, 0.9, on);
    float beadCov = clamp(br - bd + 0.5, 0.0, 1.0);
    float cameShape = max(cov, beadCov);
    float camC = cameShape * held;
    if (camC > 0.0) {
        float bead = step(cov, beadCov);
        vec2 dv = bead > 0.5 ? (vec2(g.y, -g.x) * (fx < 0.5 * seg ? fx : fx - seg) + g * dc) / br : g * clamp(dc / max(hw, 0.5), -1.0, 1.0);
        float h = sqrt(max(1.0 - dot(dv, dv), 0.0));
        vec3 nrm = normalize(vec3(dv / max(h, 0.2) * 1.1, 1.0));
        vec3 mc = metal(nrm, p, h, pl) * (1.0 + 0.15 * bead);
        col = vec4(mc, 1.0) * camC + col * (1.0 - camC);
    }

    vec2 cq = sign(q) * (e + vec2(radius + offset - 0.5) * 0.70710678);
    float cd = length(q - cq);
    float cabSpend = building ? clamp((build.x - SPEND) / POP, 0.0, 1.0) : 1.0;
    float cabGot = (grand ? cabFlash : (building && build.x >= last ? exp(-(build.x - last) / 45.0) : 0.0));
    float cabPop = 1.0 + 2.70158 * pow(cabSpend - 1.0, 3.0) + 1.70158 * pow(cabSpend - 1.0, 2.0);
    float cr = (3.4 + 0.8 * on + 2.4 * ca) * cabPop * (1.0 + 0.35 * cabGot + 0.5 * swell);
    float cabShown = shown * step(1e-3, cabSpend);
    float cabCov = clamp(cr - cd + 0.5, 0.0, 1.0) * cabShown;
    if (cabCov > 0.0 || cd < cr + 1.5) {
        float nz = sqrt(max(1.0 - sq(cd / cr), 0.0));
        vec3 cc = mix(amber * 1.1, jewelC * 1.25, on) * (0.55 + 0.45 * nz) + vec3(1.0) * pow(nz, 12.0) * 0.5;
        cc = mix(cc, call.rgb * (0.9 + 0.6 * nz), ca * 0.85);
        float ring = clamp(0.9 + 0.5 - abs(cd - cr), 0.0, 1.0) * cabShown;
        vec3 rc = metal(normalize(vec3((q - cq) / max(cd, 1e-3) * 0.6, 1.0)), p, 0.8, pl);
        col = vec4(cc, 1.0) * cabCov + col * (1.0 - cabCov);
        col = vec4(rc, 1.0) * ring + col * (1.0 - ring);
    }


    float joint = max(clamp(br + 2.0 - bd, 0.0, 1.0), max(pearlCov, clamp(1.6 - min(x, len - x), 0.0, 1.0) * bandCov));
    float glowJ = exp(-sq(bd) / 30.0);
    col.rgb += hot * heat * (joint * 1.4 + glowJ * 0.6) * held;
    col.rgb += hot * tip * (max(bandCov, camC) * 1.2 + exp(-sq(sB - sb) / 18.0) * 0.5);
    col.rgb += mix(hot, vec3(1.0), 0.35 * molten) * molten * shown * (camC * 1.5 + bandCov * 0.8 + exp(-abs(s - offset) / 4.0) * 0.45);

    if (building) {
        vec3 bare = col.rgb;
        float tile = max(bandCov, camC);
        col.rgb += (mix(hot, jewel, 0.3) * bandCov * (1.0 - lead) * (0.35 + 0.65 * exp(-sq((sB - sb) / (0.3 * bw)))) + mix(hot, vec3(1.0), 0.5) * camC * (0.25 + 0.95 * exp(-sq(dc / max(hw, 0.5))))) * flash * smoothstep(-8.0, 0.4 * seg, dj) + mix(jewel, hot, 0.5) * glow * 0.12 * tile;
        if (grand) {
            col.rgb += mix(hot, vec3(1.0), 0.5) * (arc ? 0.0 : exp(-tw / 45.0)) * pearlCov * 1.4 + hot * jolt * (pearlCov * 1.6 + camC * 0.9) * held;
            col.rgb += (mix(hot, vec3(1.0), 0.6) * max(camC, bandCov) + hot * 0.35 * exp(-abs(s - sc) / 5.0)) * turn * shown;
        }
        float spent = build.x >= SPEND ? exp(-(build.x - SPEND) / 40.0) : 0.0;
        col.rgb += hot * (spent * 1.2 + cabGot * 1.6) * cabCov + hot * cabGot * 0.5 * exp(-cd * cd / 30.0);
        if (tw >= 0.0 && tw < WELD) {
            float xj = fx < 0.5 * seg ? fx : fx - seg;
            float sIn = b0 - 1.0;
            float sOut = offset + hw + 1.0;
            float run = clamp(tw / SEAM, 0.0, 1.0);
            float torch = mix(sIn, sOut, 1.0 - sq(1.0 - run));
            float cool = clamp((tw - SEAM) / (WELD - SEAM), 0.0, 1.0);
            float fused = exp(-sq(xj / (0.8 + 0.9 * run))) * smoothstep(sIn - 1.0, sIn + 0.5, s) * (1.0 - smoothstep(torch - 1.0, torch + 1.0, s));
            float spark = exp(-(sq(xj) + sq(s - torch)) / 3.0) * (1.0 - smoothstep(0.8, 1.0, run));
            float aura = exp(-(sq(xj) + sq(s - sc)) / 40.0) * smoothstep(0.0, SEAM, tw);
            vec3 fire = mix(mix(hot, vec3(1.0), 0.7), hot * 0.6, smoothstep(0.0, 0.6, cool));
            col.rgb += ((fire * fused * 2.2 + hot * aura * 0.8) * sq(1.0 - cool) + vec3(1.0) * spark * 2.6) * shown;
            float jid = floor(uj + 0.5);
            if (grand) {
                vec2 sv = vec2(xj, s - sc);
                float star = exp(-tw / 70.0) * (exp(-sq(sv.x / 1.3) - abs(sv.y) / (3.0 + 0.1 * tw)) + exp(-sq(sv.y / 1.3) - abs(sv.x) / (5.0 + 0.15 * tw)) + exp(-dot(sv, sv) / 9.0));
                col.rgb += mix(hot, vec3(1.0), 0.6) * star * 2.2 * shown * (!arc && (fx < 0.5 * seg ? k > 0.5 : k < n - 1.5) ? 1.0 : 0.0);
            }
            for (int j = 0; j < (grand ? 6 : 3); ++j) {
                float fj = float(j);
                float age = grand ? tw : tw - fj * SEAM / 3.0;
                float life = (grand ? 120.0 : 140.0) + (grand ? 80.0 : 60.0) * hash(vec2(jid, fj + 0.3));
                if (age < 0.0 || age > life)
                    continue;
                vec2 o = grand ? vec2(0.0, sc) : vec2(0.0, mix(sIn, sOut, 1.0 - sq(1.0 - fj / 3.0)));
                float a = grand ? 2.0 * PI * (fj + 0.7 * hash(vec2(jid + 1.7, fj))) / 6.0 : PI * (0.25 + 0.5 * hash(vec2(jid + 1.7, fj)));
                vec2 dir = vec2(cos(a), sin(a));
                vec2 dv = vec2(xj, s) - o - dir * ((grand ? 0.3 : 0.2) * age * (1.0 - 0.5 * age / life));
                col.rgb += mix(hot, vec3(1.0), 0.5) * exp(-sq(dot(dv, dir) / 2.4) - sq(dot(dv, vec2(-dir.y, dir.x)))) * sq(1.0 - age / life) * 1.6 * shown;
            }
        }
        if (!arc && impact > 0.0 && ti < 150.0) {
            float edge = smoothstep(0.0, 18.0, fx) * smoothstep(0.0, 18.0, seg - fx);
            float puff = offset + hw + 2.0 + (grand ? 16.0 : 26.0) * (1.0 - exp(-ti / 28.0));
            col.rgb += (hot * 0.6 + pearl * 0.3) * sq(1.0 - ti / 150.0) * (grand ? 0.25 : 0.55) * exp(-sq((s - puff) / (2.0 + 5.0 * ti / 150.0))) * edge;
            for (int j = 0; j < 2; ++j) {
                float fj = float(j);
                vec3 h = vec3(hash(vec2(id, fj * 3.1 + 0.7)), hash(vec2(id + 5.3, fj)), hash(vec2(fj, id * 1.7)));
                float life = 110.0 + 50.0 * h.z;
                if (ti > life)
                    continue;
                vec2 vel = vec2((h.y - 0.5) * 0.3, 0.25 + 0.2 * h.z);
                vec2 dir = normalize(vel);
                vec2 dv = vec2(fx, s) - vec2(seg * (0.1 + 0.8 * h.x), offset + hw) - vel * ti * (1.0 - 0.5 * ti / life);
                col.rgb += hot * exp(-sq(dot(dv, dir) / 2.6) - sq(dot(dv, vec2(-dir.y, dir.x)))) * sq(1.0 - ti / life) * 1.6;
            }
        }
        float shade = 0.0;
        col.rgb = emit(bare, col.rgb - bare);
        if (grand) {
            vec4 f = cloud(q, e, hs, p, pl, b0, b1, hw, sc, hy, shade);
            col = f + col * (1.0 - f.a);
            col.rgb = emit(col.rgb, rays(q, e, s));
        } else if (s < 0.0) {
            vec2 aq = abs(q) - hs;
            if (aq.y > -70.0) {
                vec4 f = flights(q.y < 0.0 ? 0.0 : 4.0, q.y < 0.0 ? q.x + e.x : e.x - q.x, 2.0 * e.x, aq.y, sc, hy, p, pl, b0, b1, hw);
                col = f + col * (1.0 - f.a);
            }
            if (aq.x > -70.0) {
                vec4 f = flights(q.x > 0.0 ? 2.0 : 6.0, q.x > 0.0 ? q.y + e.y : e.y - q.y, 2.0 * e.y, aq.x, sc, hy, p, pl, b0, b1, hw);
                col = f + col * (1.0 - f.a);
            }
        } else if (!arc) {
            vec4 f = flights(side, x, len, s, sc, hy, p, pl, b0, b1, hw);
            col = f + col * (1.0 - f.a);
        }
        under += vec4(0.0, 0.0, 0.0, min(shade, 0.6) * (1.0 - under.a));
    }

    fragColor = (col + under * (1.0 - col.a)) * alpha;
}
