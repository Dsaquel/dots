import numpy as np

from .dsp import SR, WORLDS, bell, bp, hp, lp, noise, pcm, place, sweep, t, tail, tinkles


def gen4():
    rng = np.random.default_rng(29)
    out = {}
    for world, p in WORLDS:
        c = out[world] = {}
        noise(rng, 1.25)
        for i in range(6):
            g = 0.55 + 0.09 * i
            d = 0.9; tt = t(d)
            thump = sweep(72 * p, 36 * p, d, 0.4) * np.exp(-tt / (0.16 + 0.02 * i))
            click = hp(noise(rng, 0.02), 3) * np.exp(-t(0.02) / 0.003)
            x = thump * 1.0
            place(x, click * 0.25, 0.0)
            crack = np.zeros(len(tt))
            for k in range(10 + 5 * i):
                n = noise(rng, 0.02); s = rng.uniform(0.0, 0.18 + 0.03 * i)
                place(crack, bp(n, 2, 4) * np.exp(-np.arange(len(n)) / (SR * 0.0025)) * rng.uniform(0.3, 1.0), s)
            crack += tinkles(rng, d, 4 + 2 * i, 3000 * p, 7500 * p, 0.04, 0.3) * 0.5
            c[f"beat{i}"] = pcm(tail(rng, x + crack * (0.35 + 0.08 * i), 0.8, 0.3), 0.92 * g)
        d = 1.7; tt = t(d)
        base = sweep(98 * p, 392 * p, d, 1.6)
        saw = sum(np.sin(2 * np.pi * np.cumsum(98 * p + (392 - 98) * p * (tt / d) ** 1.6) * k / SR) / k for k in range(1, 7))
        trem = 0.6 + 0.4 * np.sin(2 * np.pi * np.cumsum(4 + 22 * (tt / d) ** 2) / SR)
        air = lp(noise(rng, d), 4) * (tt / d) ** 2
        c["riser"] = pcm((base * 0.3 + saw * 0.35 + air * 0.4) * trem * (tt / d) ** 1.5)
        noise(rng, 0.2)
        d = 2.2; tt = t(d)
        boom = sweep(92 * p, 28 * p, d, 0.45) * np.exp(-tt / 0.55)
        blast = lp(noise(rng, d), 8) * np.exp(-tt / 0.18)
        shat = tinkles(rng, d, 260, 2200 * p, 8000 * p, 0.06, 0.55)
        c["burst"] = pcm(tail(rng, boom * 1.2 + blast * 0.9 + shat * 0.7, 1.6, 0.5))
        d = 1.2; tt = t(d); x = np.zeros(len(tt))
        for i, f in enumerate((392, 587.3, 784, 1174.7)):
            place(x, bell(f * p * 0.5, d, 1.2) * 0.35, 0.03 * i)
        c["hang"] = pcm(x * np.minimum(1, tt / 0.06))
        d = 1.0; tt = t(d)
        noise(rng, d)
        wh = bp(noise(rng, d), 2, 5) * np.exp(-((tt - 0.12) / 0.12) ** 2)
        c["blast"] = pcm(tail(rng, wh + tinkles(rng, d, 60, 2000 * p, 6000 * p, 0.05, 0.6) * 0.5, 0.8, 0.3))
        for _ in range(260):
            rng.uniform(0, 1); noise(rng, 0.025); rng.uniform(0.2, 1.0)
        for _ in range(14):
            rng.uniform(); rng.uniform(); rng.uniform()
        for i, f in enumerate((523.25, 587.33, 659.25, 783.99, 880.0, 1046.5)):
            c[f"petal{i}"] = pcm(tail(rng, bell(f * p, 1.2, 0.9) + bell(f * p * 2, 1.2, 0.5) * 0.3, 1.0, 0.4), 0.8)
        noise(rng, 1.0); noise(rng, 0.8)
    return out


def gen5():
    rng = np.random.default_rng(41)
    out = {}
    for world, p in WORLDS:
        c = out[world] = {}
        d = 1.3; tt = t(d)
        sub = sweep(62 * p, 24 * p, d, 0.5) * np.exp(-tt / 0.45)
        rate = np.maximum(0.0, 1.0 - tt / 0.42) ** 1.6
        chord = sum(np.sin(2 * np.pi * np.cumsum(f * p * rate) / SR) * a for f, a in ((220, .5), (277.2, .35), (329.6, .35), (440, .25)))
        chord *= np.exp(-tt / 0.3) * np.minimum(1, tt / 0.004)
        ping = bell(2637 * p, d, 0.7) * 0.25
        c["stop"] = pcm(tail(rng, sub * 1.1 + chord * 0.8 + ping, 1.2, 0.5))
        d = 1.9; tt = t(d)
        hum = (np.sin(2 * np.pi * 1318.5 * p * tt) + 0.6 * np.sin(2 * np.pi * 1320.9 * p * tt) + 0.35 * np.sin(2 * np.pi * 1975.5 * p * tt))
        hum *= np.minimum(1, tt / 0.5) * np.exp(-np.maximum(0, tt - 1.4) / 0.25)
        ticks = np.zeros(len(tt))
        for k, at in enumerate((0.08, 0.5, 1.05)):
            n = noise(rng, 0.012); place(ticks, bp(n, 2, 3) * np.exp(-np.arange(len(n)) / (SR * 0.002)) * (1.0 - 0.25 * k), at)
            place(ticks, bell(3100 * p, 0.2, 0.05, ((1, 1),)) * 0.25 * (1.0 - 0.25 * k), at)
        c["frozen"] = pcm(hum * 0.22 + ticks * 0.9, 0.7)
        d = 1.4; tt = t(d)
        x = bell(3520 * p, d, 1.0) + bell(5274 * p, d, 0.6) * 0.5
        shim = sum(np.sin(2 * np.pi * f * p * tt) * np.exp(-tt / 0.5) * (0.5 + 0.5 * np.sin(2 * np.pi * 9 * tt + k)) for k, f in enumerate((4186, 4699, 6272)))
        c["star"] = pcm(tail(rng, x + shim * 0.2, 1.0, 0.45), 0.8)
        d = 0.98; tt = t(d)
        whoosh = np.zeros(len(tt))
        for lo, hi, a in ((3, 9, 1.0), (2, 5, 0.6)):
            whoosh += bp(noise(rng, d), lo, hi) * a
        whoosh *= (tt / d) ** 2.2
        harp = np.zeros(len(tt))
        notes = [523.25, 587.33, 659.25, 783.99, 880, 1046.5, 1174.7, 1318.5, 1568, 1760, 2093]
        for i, f in enumerate(notes):
            at = d * (1 - (1 - i / len(notes)) ** 0.55) * 0.95
            place(harp, bell(f * p, 0.5, 0.35, ((1, 1), (2, .3))) * (0.5 + 0.5 * i / len(notes)), at)
        c["fly"] = pcm(whoosh * 0.7 + harp * 0.8)
        d = 1.8; tt = t(d)
        knock = sweep(180 * p, 70 * p, d, 0.3) * np.exp(-tt / 0.09)
        click = hp(noise(rng, 0.03), 2) * np.exp(-t(0.03) / 0.004)
        res = sum(bell(f * p, d, 0.9) * a for f, a in ((523.25, .5), (659.25, .4), (783.99, .4), (1046.5, .3)))
        x = knock * 1.2 + res * 0.6
        place(x, click * 0.8, 0)
        c["touch"] = pcm(tail(rng, x, 1.5, 0.55))
        d = 1.2; tt = t(d)
        x = sum(np.sin(2 * np.pi * f * p * tt) * a for f, a in ((261.6, .5), (329.6, .4), (392, .4), (523.25, .3), (659.25, .2)))
        air = lp(noise(rng, d), 4) * 0.25
        c["release"] = pcm((x + air) * np.minimum(1, tt / 0.12) ** 2 * np.exp(-np.maximum(0, tt - 0.15) / 0.45), 0.75)
    return out
