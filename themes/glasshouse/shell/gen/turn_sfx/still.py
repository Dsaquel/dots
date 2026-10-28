import numpy as np

from .dsp import SR, WORLDS, bell, bp, fade, hp, lp, noise, pcm, place, svf, sweep, t, tail


def still():
    rng = np.random.default_rng(113)
    out = {}
    for world, p in WORLDS:
        c = out[world] = {}
        dawn = world == "dawn"
        chord = [f * p for f in (523.25, 783.99, 1174.66, 1760.0, 2637.02)]
        glass = ((1, 1), (2.0, .3), (3.0, .1)) if dawn else ((1, 1), (2.76, .4), (5.4, .18))
        d = 1.4; tt = t(d); x = np.zeros(len(tt))
        lo, hi = (2400 * p, 6400 * p) if dawn else (3800 * p, 10500 * p)
        for k in range(170):
            at = 0.35 * (1 - (1 - rng.uniform()) ** (1 / 3))
            f = rng.uniform(lo, hi) * 2 ** (-0.9 * at / 0.35)
            place(x, bell(f, 0.3, rng.uniform(0.015, 0.06), ((1, 1), (glass[1][0], .35))) * rng.uniform(0.15, 1.0) * (1 - 0.55 * at / 0.35), at)
        for k in range(60):
            at = 0.35 * (1 - (1 - rng.uniform()) ** (1 / 3)); n = noise(rng, 0.004)
            place(x, hp(n, 2) * np.exp(-t(0.004) / 0.0006) * rng.uniform(0.1, 0.5), at)
        wave = 1 - (1 - np.minimum(1, tt / 0.35)) ** 3
        air = hp(svf(noise(rng, d), 9000 * 2 ** (-4.2 * wave), 0.8, 0), 60) * np.minimum(1, tt / 0.004) * np.exp(-tt / 0.22)
        tick = np.zeros(len(tt)); n = noise(rng, 0.012)
        place(tick, bp(n, 2, 3) * np.exp(-np.arange(len(n)) / (SR * 0.002)), 0.35)
        lock = np.zeros(len(tt))
        place(lock, bell(chord[3], d - 0.35, 0.9, glass) * 0.5 + bell(chord[4], d - 0.35, 0.6, glass) * 0.3, 0.35)
        c["freeze"] = pcm(fade(tail(rng, x * 0.75 + air * 0.55 + tick * 0.5 + lock * 0.45, 0.8, 0.45), 0.0, 0.25), 0.8)
        d = 1.635; tt = t(d)
        bend = 1 + 0.009 * np.clip((tt - 0.8) / 0.83, 0, 1) ** 2
        bed = np.zeros(len(tt))
        for i, f in enumerate(chord):
            rate, ph0 = rng.uniform(0.25, 0.9), rng.uniform(0, 6.3)
            am = 0.62 + 0.38 * np.sin(2 * np.pi * rate * tt + ph0)
            beat = rng.uniform(0.4, 1.3) * (1 if dawn else 1.8)
            tone = np.sin(2 * np.pi * np.cumsum(f * bend) / SR) + 0.7 * np.sin(2 * np.pi * np.cumsum((f + beat) * bend) / SR + ph0)
            over = np.sin(2 * np.pi * np.cumsum(f * glass[1][0] * bend) / SR) * glass[1][1] * 0.5
            bed += (tone + over) * am * (0.55 - 0.07 * i)
        bed *= np.minimum(1, tt / 0.3) ** 2 * (0.8 + 0.35 * np.clip((tt - 0.6) / 1.0, 0, 1))
        dust = np.zeros(len(tt))
        for k in range(14):
            place(dust, bell(rng.uniform(5200, 8800) * p, 0.1, 0.012, ((1, 1),)) * rng.uniform(0.2, 0.6), rng.uniform(0.15, d - 0.3))
        u = np.clip((tt - 0.35) / (d - 0.35), 0, 1)
        breath = svf(noise(rng, d), (380 + 2300 * u ** 1.6) * (1 if dawn else 0.62), 2.2, 1) * u ** 2.6
        sheen = svf(noise(rng, d), 2800 * 2 ** (1.5 * np.clip((tt + 0.3 - 0.45) / 0.75, 0, 1)), 3.0, 1) * np.exp(-((tt + 0.3 - 0.8) / 0.22) ** 2)
        x = bed * 0.16 + dust * 0.35 + breath * 0.9 + sheen * 0.35
        x *= np.minimum(1.0, np.maximum(0.0, (d - 0.015 - tt) / 0.004))
        c["still"] = pcm(x, 0.7)
        d = 1.6; tt = t(d)
        rate = np.minimum(1, tt / 0.3) ** 0.7
        stopc = (220, 277.2, 329.6, 440) if dawn else (220, 261.63, 329.6, 440)
        ph = 2 * np.pi * np.cumsum(rate) / SR
        tape = sum(np.sin(ph * f * p * k) / k ** 1.3 * a for f, a in zip(stopc, (.5, .35, .35, .25)) for k in range(1, 5))
        tape *= np.minimum(1, tt / 0.3) ** 1.5 * np.exp(-np.maximum(0, tt - 0.3) / 0.32)
        exhale = svf(noise(rng, d), 500 * 2 ** (4.2 * np.minimum(1, tt / 0.12)), 0.8, 0) * np.minimum(1, tt / 0.01) * np.exp(-tt / 0.3)
        glint = np.zeros(len(tt))
        for k in range(30):
            at = 0.45 * rng.uniform() ** 1.7
            f = chord[rng.integers(len(chord))] * (2 if rng.uniform() < 0.5 else 1)
            place(glint, bell(f, 1.2, rng.uniform(0.06, 0.2), glass) * rng.uniform(0.2, 0.8) * (1 - 0.6 * at / 0.45), at)
        c["thaw"] = pcm(fade(tail(rng, tape * 0.5 + exhale * 0.6 + glint * 0.45, 1.0, 0.45), 0.0, 0.3), 0.8)
    return out


def bolts(sh):
    rng = np.random.default_rng(127)
    out = {}
    gold = (523.25, 587.33, 659.25, 783.99, 880.0, 1046.5, 1174.66, 1318.51, 1567.98, 1760.0, 2093.0, 2349.32, 2637.02)
    for world, p in WORLDS:
        c = out[world] = {}
        b = sh["bolts"][world]
        dawn = world == "dawn"
        new, area, hgt = (np.array(b[k], np.float64) for k in ("new", "area", "height"))
        n = len(new); d = n / 24 + 2.2; tt = t(d)
        lift = (hgt - hgt.min()) / (hgt.max() - hgt.min())
        peak = new.max()
        h = np.interp(tt, np.arange(n) / 24, lift)
        prog = np.minimum(1, tt / ((n - 1) / 24))
        hits = np.zeros(len(tt)); rings = np.zeros(len(tt)); pulse = np.zeros(len(tt))
        for i in range(n):
            if new[i] < 0.08 * peak:
                continue
            A = (new[i] / peak) ** 0.7; at = i / 24; s0 = int(SR * at)
            pulse[s0:] += A * np.exp(-(tt[s0:] - at) / 0.045)
            place(hits, hp(noise(rng, 0.006), 2) * np.exp(-t(0.006) / 0.0009) * A * 0.45, at)
            s = np.zeros(int(SR * 0.08))
            for k in range(int(14 + 70 * A)):
                u = rng.uniform() ** 1.8
                place(s, noise(rng, 0.003) * np.exp(-t(0.003) / rng.uniform(0.0003, 0.001)) * rng.uniform(0.15, 1.0) * (1 - 0.7 * u), u * 0.076)
            fc = 1700 * 2 ** (2.1 * lift[i]) if dawn else 7200 * 2 ** (-1.5 * i / n)
            place(hits, svf(s, fc * 2 ** ((0.7 if dawn else -0.6) * t(0.08) / 0.08), 1.3, 1) * A * 1.8, at)
            k = int(round(lift[i] * (len(gold) - 1))) if dawn else int(round((1 - i / (n - 1)) * (len(gold) - 1)))
            part = ((1, 1), (2.0, .3), (3.0, .12)) if dawn else ((1, 1), (2.76, .35), (5.4, .15))
            r = (0.22 if dawn else 0.14) * (0.6 + 0.6 * A)
            place(rings, (bell(gold[k] * p, 1.6, r, part) + bell(gold[min(k + 2, len(gold) - 1)] * p * 2, 1.6, r * 0.6, part) * 0.3) * A, at + 0.004)
        end = np.minimum(1, np.maximum(0, ((n + 2) / 24 - tt) / 0.45))
        f0 = (110 * 2 ** h if dawn else 165 * 2 ** (-prog)) * (1 + 0.03 * lp(noise(rng, d), 240) / 0.065)
        fcb = 2500 + 5000 * h if dawn else 6500 * 2 ** (-2.2 * prog)
        ph = 2 * np.pi * np.cumsum(f0) / SR
        buzz = sum(np.sin(k * ph) / k ** 0.7 * np.exp(-k * f0 / fcb) for k in range(1, 41)) * np.minimum(1.2, pulse) * end
        drain = 0 if dawn else np.clip((tt - 11 / 24) / 0.8, 0, 1)
        fcr = 450 * 2 ** (3.3 * h) if dawn else 650 * 2 ** (2.4 * h - 2.5 * drain)
        rush = svf(noise(rng, d), fcr, 1.4, 1) * lp(np.minimum(1.2, pulse), 1200) * end
        x = hits + rings * 0.22 + buzz * 0.13 + rush * 0.4
        if dawn:
            place(x, sweep(150, 46, 0.3, 0.5) * np.exp(-t(0.3) / 0.06) * 0.3, 3 / 24)
            zt = t(0.18); zf = 700 * 2 ** (1.9 * (zt / 0.18) ** 0.8)
            place(x, sum(np.sin(2 * np.pi * np.cumsum(zf * k) / SR) / k for k in range(1, 9)) * np.minimum(1, zt / 0.005) * np.exp(-zt / 0.07) * 0.18, 3 / 24)
            place(x, sum(bell(f, 3.0, 0.5, ((1, 1), (2.0, .25))) * a for f, a in ((2093.0, .5), (2637.02, .4), (3135.96, .3))) * 0.22, 28 / 24)
        else:
            place(x, sweep(6500, 1400, 0.03, 0.5) * np.exp(-t(0.03) / 0.01) * 0.35, 3 / 24)
            gt = t(2.4); u = np.minimum(1, gt / 0.9)
            gl = sum(np.sin(2 * np.pi * np.cumsum(f * p * 2 ** -u) / SR) * a for f, a in ((2637.02, .5), (3520.0, .35), (4186.0, .25), (5274.0, .15)))
            place(x, svf(gl, 6000 * 2 ** (-3 * u), 0.7, 0) * np.minimum(1, gt / 0.06) * np.exp(-gt / 0.45) * 0.3, 11 / 24)
        c["bolt"] = pcm(fade(np.tanh(2.0 * x / np.abs(x).max()), 0.0, 0.2), 0.92)
    return out
