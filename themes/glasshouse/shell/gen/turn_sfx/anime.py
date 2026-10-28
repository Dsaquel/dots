import numpy as np

from .dsp import SR, WORLDS, bell, bp, fade, hp, lp, noise, onepole, pcm, place, sweep, t, tail


def anime():
    rng = np.random.default_rng(53)
    out = {}
    for world, p in WORLDS:
        c = out[world] = {}
        d = 0.9; tt = t(d); x = np.zeros(len(tt))
        crack = hp(noise(rng, 0.05), 2) * np.exp(-t(0.05) / 0.006)
        place(x, crack * 1.4, 0.0)
        for k in range(40):
            n = noise(rng, 0.015); s = rng.uniform(0, 0.03)
            place(x, bp(n, 2, 3) * np.exp(-np.arange(len(n)) / (SR * 0.002)) * rng.uniform(0.3, 1.0), s)
        for k in range(9):
            place(x, bell(rng.uniform(3500, 7500) * p, 0.6, 0.12, ((1, 1), (1.5, .4))) * rng.uniform(0.2, 0.5), rng.uniform(0, 0.02))
        x += np.sin(2 * np.pi * 55 * p * tt) * np.exp(-tt / 0.08) * 0.8
        c["snap"] = pcm(x)
        d = 0.1; tt = t(d)
        grind = bp(noise(rng, d), 3, 7) * (tt / d) ** 2 * (0.6 + 0.4 * np.sin(2 * np.pi * 180 * tt))
        tick = np.zeros(len(tt))
        for k in range(12):
            n = noise(rng, 0.006); place(tick, hp(n, 2) * np.exp(-np.arange(len(n)) / (SR * 0.0015)) * (0.3 + k / 12), k * d / 12)
        c["creak"] = pcm(grind * 0.7 + tick * 0.6, 0.8)
    return out


def inhale():
    rng = np.random.default_rng(53)
    out = {}
    for world, p in WORLDS:
        d = 0.20; tt = t(d); u = tt / d
        hiss = lp(rng.normal(0, 1, len(tt)), 3) - lp(rng.normal(0, 1, len(tt)), 24) * 0.5
        bend = 1.0 + 0.04 * u ** 2
        trem = 0.75 + 0.25 * np.sin(2 * np.pi * np.cumsum(18 + 40 * u) / SR)
        tone = sum(np.sin(2 * np.pi * np.cumsum(f * p * bend) / SR) * a for f, a in ((1318.5, 0.5), (1975.5, 0.35), (2637.0, 0.2)))
        env = u ** 2.4 * np.minimum(1.0, (d - tt) / 0.003)
        out[world] = {"hold": pcm((hiss * 0.55 + tone * trem * 0.45) * env, 0.85)}
    return out


def clap():
    rng = np.random.default_rng(71)
    out = {}
    for world, p in WORLDS:
        c = out[world] = {}
        d = 2.6; tt = t(d); x = np.zeros(len(tt))
        for off, a in ((0.0, 1.0), (0.0065, 0.7), (0.0115, 0.25)):
            n = noise(rng, 0.06); e = np.exp(-np.arange(len(n)) / (SR * 0.011)) * np.minimum(1, np.arange(len(n)) / (SR * 0.0004))
            place(x, (bp(n, 2, 9) * 0.8 + hp(n, 2) * 0.35) * e * a, off)
        body = sweep(260 * p, 150 * p, 0.09, 0.6) * np.exp(-t(0.09) / 0.022)
        boom = np.tanh(2.2 * sweep(118 * p, 36 * p, d, 0.42) * np.exp(-tt / 0.38)) * 0.9
        sub = sweep(62 * p, 23 * p, d, 0.7) * np.exp(-tt / 0.95) * np.minimum(1, tt / 0.006)
        airn = noise(rng, 0.9); ta = t(0.9)
        air = onepole(airn, 5200 * np.exp(-ta / 0.07) + 260) * np.exp(-ta / 0.22) * np.minimum(1, ta / 0.003) * 3.0
        ring = (bell(2349.3 * p, d, 1.1) * 0.5 + bell(3135.96 * p, d, 0.8) * 0.3 + bell(4698.6 * p, d, 0.5) * 0.14
                + np.sin(2 * np.pi * 2355.0 * p * tt) * np.exp(-tt / 0.9) * 0.18)
        mix = x * 1.7
        place(mix, body * 0.9, 0.0)
        mix = mix + boom * 1.05 + sub * 0.95 + ring * 0.3
        place(mix, air * 0.75, 0.004)
        c["clap-hit"] = pcm(fade(tail(rng, mix, 1.6, 0.55), 0.0, 0.3))
        d = 0.62; tt = t(d); u = tt / d
        ph = 2 * np.pi * np.cumsum((190 + 640 * u ** 1.7) * p) / SR
        tone = sum(np.sin(ph * k) / k ** 1.2 for k in range(1, 7))
        trem = 0.55 + 0.45 * np.sin(2 * np.pi * np.cumsum(7 + 34 * u ** 2) / SR)
        rev = hp(noise(rng, d), 3) * u ** 3.2
        c["clap-charge"] = pcm(fade((tone * 0.5 * trem + rev * 0.8) * u ** 1.6, 0.01, 0.006), 0.85)
        d = 0.5; tt = t(d)
        nz = noise(rng, d)
        lo_ = bp(nz, 6, 24); hi_ = bp(nz, 2, 6)
        env = np.exp(-((tt - 0.2) / 0.11) ** 2)
        flutter = 0.7 + 0.3 * np.sin(2 * np.pi * np.cumsum(18 + 14 * tt / d) / SR + rng.uniform(0, 6))
        c["clap-whoosh"] = pcm(fade((lo_ * 1.0 + hi_ * 0.35) * env * flutter), 0.8)
        if world == "dawn":
            d = 0.9; tt = t(d); x = np.zeros(len(tt))
            f0 = 1830 * p
            met = sum(a * np.sin(2 * np.pi * f0 * m * tt) * np.exp(-tt / r) for m, a, r in ((1, 1, .22), (2.32, .55, .12), (4.25, .35, .07), (6.63, .2, .05)))
            thud = bp(noise(rng, 0.03), 10, 40) * np.exp(-t(0.03) / 0.006)
            x += met * 0.6
            place(x, thud * 0.9, 0.0)
            for at, a in ((0.045, 0.3), (0.075, 0.14)):
                place(x, bell(3900 * p * rng.uniform(0.9, 1.1), 0.2, 0.03, ((1, 1), (1.5, .4))) * a, at)
            c["clink"] = pcm(fade(tail(rng, x, 0.7, 0.4), 0.0, 0.05), 0.8)
            d = 1.25; tt = t(d); x = np.zeros(len(tt))
            for k in range(420):
                s = d * 0.8 * rng.uniform(0, 1) ** 1.35; n = noise(rng, 0.02)
                place(x, bp(n, 2, 4) * np.exp(-np.arange(len(n)) / (SR * rng.uniform(0.0015, 0.004))) * rng.uniform(0.2, 1.0), s)
            for k in range(16):
                s = rng.uniform(0.0, 0.95)
                place(x, sweep(rng.uniform(4000, 7500) * p, rng.uniform(600, 1300) * p, 0.08, 0.6) * np.exp(-t(0.08) / 0.025) * 0.5, s)
            buzz = (np.sign(np.sin(2 * np.pi * 100 * p * tt)) * 0.25 + np.sin(2 * np.pi * 200 * p * tt) * 0.3) * (0.6 + 0.4 * np.sin(2 * np.pi * 17 * tt))
            rush = bp(noise(rng, d), 3, 10) * 0.5
            env = np.minimum(1, tt / 0.015) * (0.65 + 0.35 * np.exp(-tt / 0.12)) * np.exp(-np.maximum(0, tt - 0.8) / 0.14)
            climb = np.exp(-((tt - 0.66) / 0.12) ** 2) * 0.5
            c["crackle-c"] = pcm((x * 0.9 + lp(buzz, 3) * 0.35 + rush) * env * (1 + climb))
            d = 2.0; tt = t(d); x = np.zeros(len(tt))
            for i, f in enumerate((523.25, 659.25, 783.99, 1046.5, 1318.5, 1567.98)):
                place(x, bell(f * p, d, 1.3) * (0.42 - 0.04 * i), 0.05 + 0.035 * i)
            pad = sum(np.sin(2 * np.pi * f * p * tt + 0.8 * np.sin(2 * np.pi * 4.6 * tt + i)) * a for i, (f, a) in enumerate(((261.63, .5), (329.63, .4), (392.0, .4), (523.25, .3))))
            air = onepole(noise(rng, d), 1500 + 5000 * np.minimum(1, tt / 0.7)) * 1.2
            env = np.minimum(1, tt / 0.5) ** 2 * np.exp(-np.maximum(0, tt - 0.6) / 0.6)
            c["sunburst"] = pcm(fade(x * 0.7 + (pad * 0.35 + air * 0.25) * env, 0.02, 0.1), 0.8)
        else:
            d = 1.9; tt = t(d); x = np.zeros(len(tt))
            for k in range(360):
                s = d * 0.85 * rng.uniform(0, 1) ** 1.2; n = noise(rng, 0.015)
                place(x, bp(n, 2, 3) * np.exp(-np.arange(len(n)) / (SR * rng.uniform(0.001, 0.003))) * rng.uniform(0.2, 1.0), s)
            for k in range(40):
                place(x, bell(rng.uniform(3200, 7200) * p, 0.25, rng.uniform(0.02, 0.06), ((1, 1), (1.51, .4))) * rng.uniform(0.1, 0.4), rng.uniform(0, d * 0.8))
            for k in range(10):
                place(x, sweep(rng.uniform(5000, 8000) * p, rng.uniform(900, 1600) * p, 0.07, 0.6) * np.exp(-t(0.07) / 0.02) * 0.4, rng.uniform(0.0, 1.3))
            wv = onepole(noise(rng, d), 700 + 2600 * np.exp(-((tt - 0.3) / 0.35) ** 2))
            env = np.minimum(1, tt / 0.02) * np.exp(-np.maximum(0, tt - 1.2) / 0.25)
            c["wave-c"] = pcm((x * 0.8 + wv * 1.4 * np.exp(-((tt - 0.45) / 0.5) ** 2)) * env)
            d = 2.4; tt = t(d)
            pad = sum(a * (np.sin(2 * np.pi * f * p * tt) + np.sin(2 * np.pi * (f * p + 0.7) * tt)) for f, a in ((110.0, .5), (130.81, .4), (164.81, .35), (220.0, .2)))
            glide = np.sin(2 * np.pi * np.cumsum(1760 * p * (1 - 0.5 * np.minimum(1, tt / 1.6))) / SR) * np.exp(-tt / 0.9) * 0.12
            wind = onepole(noise(rng, d), 400 + 300 * np.sin(2 * np.pi * 0.7 * tt) ** 2) * 1.5
            env = np.minimum(1, tt / 0.7) ** 1.5 * np.exp(-np.maximum(0, tt - 0.9) / 0.6)
            c["night"] = pcm(fade((pad * 0.5 + wind * 0.3) * env + glide, 0.02, 0.2), 0.7)
            d = 1.2; tt = t(d); x = np.zeros(len(tt))
            fw = onepole(noise(rng, 0.35), 300 + 2200 * np.minimum(1, t(0.35) / 0.08)) * np.minimum(1, t(0.35) / 0.03) * np.exp(-t(0.35) / 0.1) * 3.0
            place(x, fw, 0.0)
            for k in range(14):
                n = noise(rng, 0.01); place(x, bp(n, 2, 4) * np.exp(-np.arange(len(n)) / (SR * 0.0015)) * rng.uniform(0.05, 0.3), rng.uniform(0.04, 0.9))
            hum = (np.sin(2 * np.pi * 146.83 * tt) * 0.5 + np.sin(2 * np.pi * 220.0 * tt) * 0.3 + np.sin(2 * np.pi * 293.66 * tt) * 0.2)
            henv = np.minimum(1, tt / 0.5) ** 2 * np.exp(-np.maximum(0, tt - 0.6) / 0.35)
            c["flame-c"] = pcm(fade(x + hum * henv * 0.35, 0.0, 0.1), 0.75)
    return out
