void main() {
    vec2 p = drawn.xy + v_texcoord * drawn.zw;
    vec2 hs = foot.zw * 0.5;
    vec2 q = p - foot.xy - hs;
    float lo = min(foot.z, foot.w);
    float R = ringAt(t, lo);
    float M = mouthAt(t, lo);
    float m = morphAt(t);
    vec2 hc = hs + vec2(came);
    float rc = radius + came;
    float r = length(q);
    float d = t >= SEAT ? sdRoundBox(q, hc, rc) : mix(r - M, sdRoundBox(q, hc, rc), m);
    float phi = atan(-q.x, q.y + 1e-4);
    phi = phi < 0.0 ? phi + TAU : phi;
    float f = phi / TAU;
    float H = lapsAt(t);
    float opened = clamp((t - SLING) / IRIS, 0.0, 1.0);
    float iris = (1.0 - pow(1.0 - opened, 3.0)) * M * 1.02;
    float inside = t >= SEAT ? 1.0 : smoothstep(1.5 * scale, -1.5 * scale, d) * (opened >= 1.0 ? 1.0 : smoothstep(iris + 1.5 * scale, iris - 1.5 * scale, r));
    float sdw = sdRoundBox(q, hs, radius);
    if (pass > 1.5) {
        vec4 c = texture(tex, p / texSize);
        fragColor = sdw <= 0.0 && inside > 0.5 && c.a > 0.0 ? vec4(c.rgb / c.a, c.a) : c;
        return;
    }
    if (pass > 0.5) {
        fragColor = texture(tex, p / texSize) * inside;
        return;
    }

    vec2 bend = vec2(0.0);
    if (sdw < -2.0 * scale) {
        float k = t - SEAT;
        if (k > 0.0 && k < RUNG) {
            float x = -sdw / scale - RING * k;
            bend = -q / max(r, 1.0) * 7.0 * scale * exp(-k / 70.0) * sin(x * 0.13) * exp(-sq(x / 34.0));
        } else if (k < 0.0 && d > -160.0 * scale && d < 2.0 * scale)
            bend = (vec2(vnoise(p / scale * 0.05 + vec2(0.0, t * 0.03)), vnoise(p / scale * 0.05 + vec2(7.1, t * 0.03))) - 0.5) * 3.0 * scale * exp(d / (24.0 * scale));
    }
    vec4 c = inside > 0.0 ? sampled(p + bend) * inside : vec4(0.0);
    if (sdw < 0.0 && c.a > 0.0) {
        float clear = pow(smoothstep(0.0, 1.0, (t - SEAT + 30.0 - length(p - lamp) / (SWEEP * scale)) / CLEARING), 1.5);
        float near = t < SEAT ? exp(d / (34.0 * scale)) : 0.0;
        vec3 straight = c.rgb / c.a;
        float lum = dot(straight, vec3(0.299, 0.587, 0.114));
        if (ink > 0.5) {
            vec3 print_ = mix(sepia, vec3(1.0, 0.94, 0.82), smoothstep(0.15, 0.85, lum));
            vec3 aged = mix(straight, print_, 0.4 * (1.0 - clear));
            c.rgb = mix(aged, leaf, clamp(near * 0.45, 0.0, 0.55)) * c.a;
        } else
            c.rgb = c.rgb * mix(vec3(0.9, 0.8, 0.68), vec3(1.0), clear) + gold * near * 0.3 * c.a;
    }
    if (t > SEAT + FLASH * 3.0) {
        fragColor = c;
        return;
    }

    float behind = fract(H - f);
    float gone = 1.0 - smoothstep(SEAT - 10.0, SEAT + 30.0, t);

    vec4 col = vec4(0.0);
    vec3 glow = vec3(0.0);
    float melting = 0.0;
    float Ro = R * (1.0 + WREATH);
    float band = R * WREATH;
    float s = (r - R) / band;
    vec2 half_ = hc * mix(M / min(hc.x, hc.y), 1.0, m);
    bool burning = t > SLING && t < SEAT + 30.0;
    bool roseIn = burning && s > -0.02 && s < 1.06;
    bool sealIn = burning && d > 0.0 && r < length(half_) + (BAR + 40.0) * scale;
    float sweepK = 0.0;
    float glintAt = 0.0;
    if (roseIn || sealIn) {
        vec2 toLamp = lamp - foot.xy - hs;
        sweepK = exp(-sq(min(behind, 1.0 - behind) * TAU * R / (150.0 * scale)));
        glintAt = pow(max(cos(phi - atan(-toLamp.x, toLamp.y + 1e-4)), 0.0), 24.0) + 1.4 * pow(sweepK, 3.0);
    }
    if (ink < 0.5)
        col.a = 0.3 * smoothstep(Ro * 1.7, Ro * 0.9, r) * smoothstep(0.0, 60.0, t) * gone * (1.0 - inside);
    if (roseIn) {
        float drawnIn = clamp((H - 1.0 - f) * 10.0 + 0.5, 0.0, 1.0);
        float burnt = smoothstep(-1.0 * scale, 1.0 * scale, -d);
        float front = t > LOCK ? exp(-max(d, 0.0) / (5.0 * scale)) * (1.0 - burnt) : 0.0;
        float molten = t > LOCK ? exp(-max(d, 0.0) / (22.0 * scale)) * (1.0 - burnt) : 0.0;
        float shown = drawnIn * gone * (1.0 - burnt);
        float wreath = smoothstep(-0.02, 0.02, s) * smoothstep(1.04, 1.0, s) * shown;
        vec4 rose = ink > 0.5 ? vec4(vec3(1.0, 0.95, 0.86) * 0.82, 0.82) * wreath : vec4(0.0, 0.0, 0.0, 0.66) * wreath;
        float back = exp(-max(r - R, 0.0) / (0.45 * band));
        float spot = sweepK * exp(-max(r - R, 0.0) / (0.7 * band));

        float pr = phi - DRIFT * t;
        float pp = (pr / TAU) * PETALS;
        float k = floor(pp);
        float a = fract(pp) - 0.5;
        float v = (s - 0.3) / 0.65;
        float arcW = TAU * r / PETALS;
        float tall = 0.65 * band;
        if (v > -0.03 && v < 1.03) {
            float hw = 0.45 * pow(max(1.0 - pow(clamp(v, 0.0, 1.0), 1.7), 0.0), 0.7);
            float sp = (abs(a) - hw) * arcW;
            bool petalIn = sp < 0.0;
            float cabR = 0.075 * arcW;
            vec2 cq = vec2((abs(a) - 0.5) * arcW, (v - 0.74) * tall);
            float cab = length(cq) - cabR;
            float ld = min(abs(sp), min(abs(v) * tall, abs(1.0 - v) * tall));
            ld = petalIn ? min(ld, min(v < 0.86 ? abs(a) * arcW : 1e3, abs(v - 0.42) * tall)) : min(ld, min(abs(cab) + 0.5 * scale, v > 0.55 && cab > 0.0 ? abs(abs(a) - 0.5) * arcW : 1e3));
            float lw = 1.9 * scale;
            float lead = clamp((lw - ld) / scale + 0.5, 0.0, 1.0);
            float ridge = sqrt(max(1.0 - sq(ld / lw), 0.0));
            float putty = clamp((lw + 1.3 * scale - ld) / scale + 0.5, 0.0, 1.0) * (1.0 - lead);
            float glassIn = smoothstep(0.0, 0.04, v) * smoothstep(1.0, 0.96, v) * wreath;
            float pane = petalIn ? k * 4.0 + step(0.0, a) + 2.0 * step(0.42, v) : k * 4.0 + 7.0 + step(0.74, v);
            vec2 gp = vec2(a * arcW, v * tall) / scale;
            float dens = 0.65 + 0.7 * vnoise(gp / 26.0 + pane * 1.7) + 0.3 * (hash(vec2(pane, 3.3)) - 0.5);
            float streaks = 0.72 + 0.56 * vnoise(vec2(gp.x / 2.2 + pane * 5.0, gp.y / 48.0)) * (0.6 + 0.4 * vnoise(vec2(gp.x / 9.0, gp.y / 90.0 + pane)));
            vec2 bc = floor(gp / 7.0);
            vec2 bo = (bc + vec2(0.2 + 0.6 * hash(bc + pane), 0.2 + 0.6 * hash(bc + pane + 3.1))) * 7.0;
            float bd = length(gp - bo) - (0.7 + 0.9 * hash(bc + 1.7 + pane));
            float bubble = step(0.86, hash(bc + pane * 0.37)) * clamp(0.9 - abs(bd) * 1.6, 0.0, 1.0);
            float edgeDark = 0.42 + 0.58 * smoothstep(0.0, 9.0 * scale, ld);
            vec3 petal = mod(k, 2.0) < 0.5 ? jewelA : jewelB;
            vec3 garnet = mix(vec3(0.62, 0.08, 0.1), jewelC, 0.2);
            vec3 jewel = cab < 0.0 ? mix(jewelC, gold, 0.5) : (petalIn ? petal : garnet);
            float tone = dens * streaks * edgeDark * mix(1.0, 0.55, smoothstep(0.2, 1.0, v));
            vec2 gn = cab < 0.0 ? cq / cabR : vec2(0.0);
            float dome = cab < 0.0 ? sqrt(max(1.0 - dot(gn, gn), 0.0)) : 0.0;
            float spec = cab < 0.0 ? pow(max(dot(normalize(vec3(gn, dome + 1e-3)), normalize(vec3(-0.5, -0.6, 0.8))), 0.0), 26.0) * (0.6 + glintAt) : 0.0;
            if (ink > 0.5) {
                vec3 paint = mix(jewel * mix(0.62, 1.0, tone), mix(jewel, vec3(1.0, 0.97, 0.9), 0.35), clamp((tone - 0.9) * 1.2 + 0.4 * spot, 0.0, 0.6)) + vec3(1.0) * (bubble * 0.25 + spec * 0.8);
                rose = over(vec4(paint, 1.0) * 0.9 * glassIn * (1.0 - lead), rose);
                rose = over(vec4(sepia * 0.6, 1.0) * putty * 0.5 * wreath, rose);
                rose = over(vec4(mix(sepia * 0.9, leaf, pow(ridge, 4.0) * 0.6), 1.0) * lead * wreath, rose);
            } else {
                float light = (0.42 + 1.25 * back + 1.5 * spot) * tone;
                vec3 shine = mix(jewel * jewel * 0.7, mix(jewel, vec3(1.0, 0.95, 0.85), 0.28), smoothstep(0.25, 1.5, light)) * light;
                shine = mix(shine, fire(0.7 + 0.6 * molten) * (1.4 + 1.6 * molten) * (0.7 + 0.3 * streaks), molten) + vec3(1.0, 0.95, 0.85) * (bubble * 0.35 * light + spec * 1.6);
                rose = over(vec4(jewel * jewel * 0.06, 1.0) * 0.95 * glassIn * (1.0 - lead), rose);
                glow += shine * glassIn * (1.0 - lead) * (1.0 - 0.6 * putty);
                rose = over(vec4(vec3(0.0), 1.0) * putty * 0.55 * wreath, rose);
                rose = over(vec4(leadOf(ridge, back + molten), 1.0) * lead * wreath, rose);
            }
            if (v > 0.93) {
                vec2 bq = vec2((abs(a) - 0.5) * arcW, (v - 1.0) * tall);
                float bl = length(bq);
                float bead = clamp(2.6 * scale - bl + 0.5, 0.0, 1.0) * wreath;
                float bdome = sqrt(max(1.0 - sq(bl / (2.6 * scale)), 0.0));
                rose = over(vec4(ink > 0.5 ? mix(leaf, vec3(1.0, 0.95, 0.8), pow(bdome, 6.0) * glintAt * 0.5) : giltOf(bdome, pow(bdome, 8.0) * glintAt), 1.0) * bead, rose);
            }
        }

        float rv = (s - 0.06) / 0.2;
        if (rv > -0.1 && rv < 1.1) {
            float pg = phi + DRIFT * 1.5 * t;
            float cells = floor(TAU * (R + 0.16 * band) / (RUNE * scale));
            float gi = floor(pg / TAU * cells);
            float gu = fract(pg / TAU * cells) - 0.5;
            float cw = TAU * r / cells;
            vec2 gq = vec2(gu * cw / (0.34 * cw), (rv - 0.5) * 2.0 / 0.82);
            float gd = glyph(gq, gi + 17.0 * floor(seed * 7.0));
            float head_ = abs((rv - 0.92) * 0.2 * band);
            float gap = step(0.18, hash(vec2(floor(gi / 3.0), 9.3)));
            float strokes = max(line(gd * 0.34 * cw, 0.9 * scale), line(head_, 0.9 * scale) * gap) * wreath;
            float burn = smoothstep(0.0, 0.25, H - 1.0 - fract(pg / TAU));
            if (ink > 0.5)
                rose = over(vec4(mix(sepia, vec3(0.7, 0.16, 0.04), 0.35 * spot), 1.0) * strokes, rose);
            else {
                rose = over(vec4(gold * 0.3, 1.0) * strokes * 0.7, rose);
                glow += gold * strokes * (0.5 + 0.8 * back + 1.2 * spot) * (0.6 + 0.4 * burn);
            }
        }

        float ringD = min(min(abs(s - 0.035), abs(s - 0.28)), abs(s - 0.965)) * band;
        float rw = 1.1 * scale;
        float rings = clamp((rw - ringD) / scale + 0.5, 0.0, 1.0) * wreath;
        float rridge = sqrt(max(1.0 - sq(ringD / rw), 0.0));
        float thin = line((s - 0.995) * band, 0.6 * scale) * wreath;
        if (ink > 0.5) {
            rose = over(vec4(mix(mix(leaf, sepia, 0.35), vec3(1.0, 0.93, 0.75), pow(rridge, 6.0) * glintAt * 0.6), 1.0) * rings, rose);
            rose = over(vec4(sepia, 1.0) * thin, rose);
        } else {
            rose = over(vec4(giltOf(rridge, pow(rridge, 10.0) * glintAt) * 0.55, 1.0) * rings, rose);
            glow += gold * (rings * (0.3 + 0.9 * back + 0.8 * spot) * rridge + thin * 0.5) + vec3(1.0, 0.95, 0.85) * rings * pow(rridge, 10.0) * glintAt * 1.2;
        }
        if (ink > 0.5 && t > LOCK && rose.a > 0.0) {
            float ahead = max(d, 0.0) / scale;
            float onset = smoothstep(LOCK, LOCK + 20.0, t);
            float edge = MELT * (0.8 + 0.6 * vnoise(q / (16.0 * scale)));
            float heat_ = clamp(1.0 - ahead / edge, 0.0, 1.0);
            melting = (1.0 - smoothstep(0.6 * edge, edge, ahead)) * onset;
            float char_ = smoothstep(0.6 * edge, edge, ahead) * exp(-max(ahead - edge, 0.0) / CHAR) * onset;
            vec3 straight = rose.rgb / rose.a;
            float lum = smoothstep(0.15, 0.6, dot(straight, vec3(0.299, 0.587, 0.114)));
            vec3 molten_ = mix(mix(vec3(0.5, 0.05, 0.02), vec3(0.86, 0.2, 0.03), heat_), mix(vec3(0.9, 0.26, 0.04), vec3(1.0, 0.76, 0.22), smoothstep(0.2, 0.75, heat_)), lum);
            straight = mix(mix(straight, sepia * (0.7 + 0.4 * lum), char_ * 0.9), molten_, melting);
            float a = mix(rose.a, wreath, max(melting, char_ * 0.9));
            rose = vec4(straight * a, a);
        }
        col = over(rose, col);
        glow += fire(0.6 + 0.5 * front) * front * 2.2 * smoothstep(-0.02, 0.05, s) * smoothstep(1.06, 1.0, s) * (1.0 - ink);
    }

    if (sealIn) {
        float th = turnAt(t);
        float om = PI / (0.7 * SEAT) * (1.0 - 0.6 * clamp(t / SEAT, 0.0, 1.0));
        float rr = rc * half_.y / hc.y;
        float reveal = smoothstep(80.0, 140.0, t) * gone;
        vec4 bars = vec4(0.0);
        vec3 barGlow = vec3(0.0);
        for (int i = 0; i < 2; ++i) {
            float th_ = i == 0 ? th : -th;
            float w_ = i == 0 ? om : -om;
            mat2 toLocal = mat2(cos(th_), -sin(th_), sin(th_), cos(th_));
            vec2 rq = toLocal * q;
            float sd = sdRoundBox(rq, half_, rr);
            float bw = BAR * scale;
            float bar = clamp((bw - abs(sd)) / scale + 0.5, 0.0, 1.0);
            float bridge = sqrt(max(1.0 - sq(sd / bw), 0.0));
            vec2 nL = abs(rq.x) - half_.x > abs(rq.y) - half_.y ? vec2(sign(rq.x), 0.0) : vec2(0.0, sign(rq.y));
            float push = dot(w_ * vec2(-rq.y, rq.x), nL);
            float lead_ = sign(push) * sd;
            float speedK = min(abs(push) / (4.0 * scale), 1.0);
            float heatFace = smoothstep(bw - 0.5 * scale, bw + 0.5 * scale, lead_) * exp(-max(lead_ - bw, 0.0) / (3.0 * scale)) * speedK;
            float hotEdge = smoothstep(bw - 2.6 * scale, bw - 0.6 * scale, lead_) * bar * speedK;
            float rim_ = clamp((abs(sd) - (bw - 1.2 * scale)) / scale, 0.0, 1.0) * bar;
            vec2 cc = sign(rq) * (half_ - vec2(rr * 0.29));
            float gd = length(rq - cc);
            float gemC = clamp(GEM * scale - gd + 0.5, 0.0, 1.0);
            float gemDome = sqrt(max(1.0 - sq(gd / (GEM * scale)), 0.0));
            float bezel = clamp(1.4 * scale - abs(gd - GEM * scale) + 0.5, 0.0, 1.0);
            vec2 gn = (rq - cc) / (GEM * scale);
            float gspec = pow(max(dot(normalize(vec3(gn, gemDome + 1e-3)), normalize(vec3(-0.5, -0.6, 0.8))), 0.0), 22.0);
            float heat = 0.25 + 0.75 * m;
            if (ink > 0.5) {
                bars = over(vec4(mix(vec3(0.85, 0.3, 0.05), vec3(0.95, 0.55, 0.1), heat), 1.0) * clamp(heatFace * 0.7 + hotEdge, 0.0, 0.85) * reveal, bars);
                float soot_ = exp(-max(abs(sd) - bw, 0.0) / (2.5 * scale)) * (1.0 - bar) * 0.35;
                bars = over(vec4(sepia * 0.7, 1.0) * soot_ * reveal, bars);
                vec3 inkBar = mix(sepia * 0.85, mix(leaf, vec3(0.95, 0.72, 0.3), 0.4), smoothstep(0.15, 0.7, bridge)) + vec3(1.0, 0.95, 0.8) * pow(bridge, 24.0) * (0.3 + 0.5 * glintAt);
                bars = over(vec4(mix(inkBar, vec3(0.9, 0.3, 0.04), hotEdge * 0.8), 1.0) * bar * reveal, bars);
                bars = over(vec4(mix(jewelC, vec3(0.75, 0.12, 0.08), 0.5) * (0.7 + 0.5 * gemDome) + vec3(1.0) * gspec * 0.7, 1.0) * gemC * reveal, bars);
                bars = over(vec4(leaf, 1.0) * bezel * reveal, bars);
            } else {
                vec3 gilt_ = gold * (0.16 + 0.62 * pow(bridge, 1.5)) + mix(gold, vec3(1.0, 0.96, 0.85), 0.7) * pow(bridge, 28.0) * (0.5 + glintAt) * 0.9;
                vec3 metal_ = mix(leadHi * 0.2 + leadLow * 0.4, gilt_, smoothstep(0.15, 0.65, bridge));
                bars = over(vec4(mix(mix(metal_, leadLow * 0.4, rim_ * 0.85), fire(0.5 + 0.4 * heat) * 0.6, hotEdge * 0.7), 1.0) * bar * reveal, bars);
                barGlow += fire(0.55 + 0.45 * heat) * (heatFace * 0.6 + hotEdge * 0.9) * (0.7 + 1.5 * heat) * reveal + fire(0.7 + 0.3 * m) * bar * pow(m, 4.0) * 1.1 * reveal;
                bars = over(vec4(mix(jewelC, vec3(0.75, 0.12, 0.08), 0.5) * 0.25, 1.0) * gemC * reveal, bars);
                barGlow += (mix(jewelC, vec3(1.0, 0.3, 0.15), 0.4) * (0.4 + 0.9 * gemDome) + vec3(1.0, 0.95, 0.85) * gspec * 2.0) * gemC * reveal;
                bars = over(vec4(giltOf(1.0 - abs(gd - GEM * scale) / (1.4 * scale), 0.0), 1.0) * bezel * reveal, bars);
            }
        }
        float keep = smoothstep(0.0, 2.0 * scale, d);
        col = over(bars * keep, col);
        glow += barGlow * keep;
    }

    if (abs(d) < 90.0 * scale) {
        float lit = H >= 1.0 ? 1.0 : clamp((H - f) * TAU * R / (8.0 * scale) + 0.5, 0.0, 1.0);
        float live = t < SEAT ? 1.0 : 0.0;
        float flash = t >= SEAT ? 1.6 * exp(-(t - SEAT) / FLASH) : 0.0;
        float head = exp(-sq(behind * TAU * R / (22.0 * scale))) + 0.5 * exp(-sq((1.0 - behind) * TAU * R / (7.0 * scale)));
        float knot = exp(-sq(min(f, 1.0 - f) * TAU * R / (9.0 * scale))) * smoothstep(0.0, 15.0, t);
        float flick = vnoise(vec2(phi * R / (22.0 * scale) - t * 0.02, t * 0.013 + seed)) * 0.6 + vnoise(vec2(phi * R / (8.0 * scale) + t * 0.05, seed * 3.1)) * 0.4;
        float burn = (lit * (0.35 + 0.3 * flick + 0.7 * exp(-behind / TAIL)) + 1.6 * head + 0.6 * knot) * live * smoothstep(0.0, 8.0, t) + flash;
        if (burn > 0.002) {
            float burnLit = max(lit * live, min(flash, 1.0));
            float W = scale * (1.0 + 0.7 * head * live);
            float h = burn;
            float hk = min(h, 1.0);
            float strand = 0.0;
            for (int i = 0; i < 3; ++i) {
                float fi = float(i);
                float sway = (vnoise(vec2(phi * R / (40.0 * scale) + fi * 7.3 - t * 0.03, fi * 3.1 + seed)) - 0.5) * 7.0 * scale;
                strand += exp(-sq((d - sway) / (0.9 * W))) * (0.5 + vnoise(vec2(phi * R / (12.0 * scale) - t * 0.06, fi * 5.7)));
            }
            float core = exp(-sq(d / (3.0 * W)));
            float wire = exp(-sq(d / (1.4 * W))) * 0.6 + strand * 0.5;
            float halo = exp(-abs(d) / ((5.0 + 9.0 * hk) * W)) * max(burnLit, hk);
            float bloom = exp(-abs(d) / (30.0 * W)) * hk;
            float out_ = max(d - 2.0 * W, 0.0) / W;
            vec2 fl = vec2(phi * R / (18.0 * scale) + t * 0.03 - out_ * 0.09, out_ / 9.0 - t * 0.05) + seed;
            float n = vnoise(fl) * 0.65 + vnoise(fl * 2.3 + 7.1) * 0.35;
            float tongue = smoothstep(0.0, 1.0, (n - 0.22) * 1.6 - out_ / (8.0 + 38.0 * hk * burnLit)) * step(0.0, d) * burnLit;
            float inner = smoothstep(-24.0 * scale, -4.0 * scale, d);
            if (ink > 0.5) {
                float soot = 0.55 * hk * smoothstep(3.0 * W, 10.0 * W, abs(d)) * exp(-max(abs(d) - 10.0 * W, 0.0) / (16.0 * W)) * inner * (1.0 - melting);
                col = over(vec4(sepia * 0.8, 1.0) * soot, col);
                float fA = clamp(1.1 * hk * halo + 0.95 * tongue, 0.0, 0.95) * inner;
                col = over(vec4(mix(vec3(0.78, 0.16, 0.03), vec3(0.98, 0.45, 0.06), exp(-abs(d) / (5.0 * W))), 1.0) * fA, col);
                float gA = clamp(1.3 * hk * core + 0.7 * hk * wire, 0.0, 1.0);
                col = over(vec4(mix(vec3(1.0, 0.62, 0.1), vec3(1.0, 0.86, 0.36), clamp(h - 0.8, 0.0, 1.0)), 1.0) * gA, col);
            } else {
                float hc_ = min(h, 2.0);
                glow += (fire(0.7 + 0.4 * hc_) * core * (0.5 + 0.6 * hc_) + fire(0.85 + 0.3 * hc_) * wire * min(hc_, 1.5) + fire(0.45 + 0.25 * hk) * 0.8 * hk * halo +
                         fire(0.4) * 0.3 * bloom + fire(0.3 + 0.6 * tongue * hk) * tongue) * inner;
            }
        }
    }

    float point = t < SLING + IRIS ? exp(-dot(q, q) / sq((5.0 + 3.0 * sin(t * 0.4)) * scale)) * (t < SLING ? smoothstep(0.0, 10.0, t) : 1.0 - opened) : 0.0;
    float rim = t > SLING && opened < 1.0 ? exp(-sq((r - iris) / (3.0 * scale))) * (1.0 - opened) : 0.0;
    if (ink > 0.5) {
        col = over(vec4(vec3(1.0, 0.7, 0.2), 1.0) * clamp(point * 1.5, 0.0, 1.0), col);
        col = over(vec4(vec3(0.95, 0.5, 0.08), 1.0) * clamp(rim, 0.0, 0.9), col);
    } else
        glow += mix(hot, vec3(1.0), 0.5) * point * 3.0 + fire(1.1) * rim * 2.2;

    col = over(col, c);
    col.rgb = emit(col.rgb, glow);
    fragColor = col;
}
