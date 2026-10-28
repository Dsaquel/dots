import numpy as np

from .cues import MOTION, MOVE
from .dsp import SR, active, band, blank, decay, fade, flat, norm, onset, put, secs, trill
from .takes import bank, take


def follow(name, a, b, floor=0.3):
    lo, hi, v = MOTION[name]
    m = np.interp(secs(a, b), np.linspace(lo, hi, len(v)), v, left=0, right=0)
    return floor + (1 - floor) * m / max(m.max(), 1e-6)


def frr(dur, rate, bright, amp, sharp=2.0, depth=0.88, hiss=0.5, seed=0, src=("tk2-roar", 0), bed=0.25):
    n = int(dur * SR)
    rng = np.random.default_rng(seed)
    roar, air, fire = take(*src), take("tk2-roar", 2), take("tk2-roar", 1)
    hi = min(active(roar)[1], len(air)) - n - 1
    off = int(rng.integers(int(0.05 * SR), max(hi, int(0.05 * SR) + 1)))
    t = np.arange(n) / SR
    stretch = lambda v: np.interp(np.arange(n), np.linspace(0, n, len(v)), v)
    body = flat(band(roar[off:off + n], 120, 5200))
    dark = band(body, hi=1800)
    tone = dark + stretch(bright) * (body - dark)
    tr = trill(n, stretch(rate), sharp, depth, seed)
    tongue = np.clip((t - 0.04) / 0.015, 0, 1)
    f = flat(band(air[off:off + n], 2800, 10000))
    flame = norm(band(fire[off:off + n], 100, 6000), -20) * np.clip(t / 0.02, 0, 1)
    x = (norm(tone, -20) * (1 - tongue * (1 - tr)) * np.clip((t - 0.015) / 0.03, 0, 1)
         + hiss * norm(f, -20) * (1 - tongue * 0.85 * (1 - tr)) * (1 + 1.2 * np.exp(-t / 0.03))
         + bed * flame)
    return fade(x * stretch(amp), 0.003, 0.03)


def crackle(dur, amp, rate, seed):
    rng = np.random.default_rng(seed)
    pops = [h for k in (0, 2) for h in bank("tk2-embers", k, 0.03, -30, 0.04)]
    x = blank(dur)
    t = rng.exponential(1 / rate)
    while t < dur - 0.04:
        h = pops[rng.integers(len(pops))]
        put(x, fade(h, 0.0005, 0.01) * rng.uniform(0.25, 1) ** 2 * np.interp(t, np.linspace(0, dur, len(amp)), amp), t)
        t += rng.exponential(1 / rate)
    return 0.08 * np.tanh(x / 0.08)


def embers(length, gain, k=0):
    x = onset(take("tk2-embers", k))[:int(length * SR)]
    x = norm(x, -20) * decay(len(x), length / 2.5)
    return fade(0.09 * np.tanh(x / 0.09), 0.015, 0.1) * gain


def sand(n, rate, lo, hi, seed):
    rng = np.random.default_rng(seed)
    hit = rng.random(n) < np.broadcast_to(rate, (n,)) / SR
    x = np.zeros(n)
    x[hit] = rng.choice((-1, 1), hit.sum()) * np.clip(rng.pareto(3, hit.sum()), 0, 3)
    return norm(band(x, lo, hi, 2), -20)


def burn(end=0.38, tail=0.7, glow=0.6):
    amp = follow("burn", 0, 0.38, 0.45)
    mix = blank(1.4)
    put(mix, frr(end + 0.04, np.full(64, 25.0), np.linspace(1.0, 0.35, 64), amp, 2.0, hiss=0.5, seed=3, src=("tk2-roar", 0)), 0)
    put(mix, crackle(end + 0.04, amp, 30, 3), 0)
    put(mix, embers(tail, glow, 0), end - 0.01)
    return mix


def whoosh(lit=True):
    arc, seat, end = 0.012, 0.355, 0.62
    t = arc + np.arange(int((end - arc) * SR)) / SR
    u = np.clip((t - arc) / (seat - arc), 0, 1)
    after = np.clip(t - seat, 0, None)
    roar, air = take("tk2-roar", 0), take("tk2-roar", 2)
    pos = 0.1 * SR + np.cumsum(0.7 + 0.8 * u ** 1.5)
    x = flat(band(np.interp(pos, np.arange(len(roar)), roar), 120, 14000), 20)
    dark = band(x, hi=1200)
    body = norm(dark + (0.15 + 0.85 * u ** 1.2) * (x - dark), -20)
    h = flat(band(np.interp(pos, np.arange(len(air)), air), 2800, 12000), 20)
    lead = np.clip((t - arc) / 0.006, 0, 1) * (1 + 1.5 * lit * np.exp(-(t - arc) / 0.035))
    y = (body * (0.2 + 0.8 * u ** 2) * np.exp(-after / 0.05)
         + 0.45 * norm(h, -20) * lead * (0.4 + 0.6 * u ** 2) * np.exp(-after / 0.11))
    mix = blank(1.4)
    put(mix, fade(y, 0.002 if lit else 0.04, 0.08), arc)
    return mix


def move():
    lo, hi = 1000, 6000
    strike, u0, land = MOVE["strike"], MOVE["unframe"], MOVE["stones"]
    lift = burn(0.3, 0.4, 0.35)
    fl = secs(0.18, strike)
    u = (fl - 0.18) / (strike - 0.18)
    swell = np.sin(np.pi * np.clip(u * 0.9 + 0.08, 0, 1)) ** 1.2 * (1 + 0.4 * u)
    g = onset(take("mv2-gust", 2))[:len(fl)]
    s = norm(band(g, 200, 9000), -20) + 0.6 * norm(band(take("mv2-sift", 1)[:len(fl)], 1500, 11000), -20)
    flight = blank(0.6)
    put(flight, fade(norm(s, -20) * swell[:len(s)], 0.03, 0.01) * 0.9, 0)
    put(flight, fade(sand(len(fl), 400 + 1600 * swell, lo, hi, 62) * swell, 0.03, 0.01) * 0.7, 0)
    hit = blank(0.8)
    put(hit, fade(norm(onset(take("mv2-blast", 0)), -20)[:int(0.45 * SR)], 0.001, 0.15), 0)
    burst = int(0.35 * SR)
    put(hit, sand(burst, 9000 * decay(burst, 0.06), lo, hi, 72) * decay(burst, 0.12) * 0.9, 0)
    n = int(0.5 * SR)
    put(hit, np.sin(2 * np.pi * np.cumsum(35 + 45 * np.exp(-np.arange(n) / SR / 0.05)) / SR) * decay(n, 0.035) * 0.35, 0)
    put(hit, fade(norm(onset(take("mv2-thump", 1)), -20)[:int(0.4 * SR)], 0.001, 0.1) * 0.6, 0)
    rb = follow("rebuild", u0 + 0.2, land[0], 0.3)
    rebuild = blank(len(rb) / SR + 0.1)
    put(rebuild, fade(norm(band(take("mv2-settle", 0)[:len(rb)], 800, 11000), -20) * rb, 0.05, 0.1) * 0.35, 0)
    put(rebuild, fade(sand(len(rb), 700 * rb, lo, hi, 82) * rb, 0.05, 0.1) * 0.5, 0)
    k = int(0.04 * SR)
    stone = sand(k, 6000, lo, hi, 124) * decay(k, 0.012)
    tail = int(0.6 * SR)
    boom = blank(0.7)
    put(boom, sand(tail, 7000 * decay(tail, 0.08), lo, hi, 101) * decay(tail, 0.15) * 0.8, 0)
    put(boom, fade(norm(onset(take("mv2-blast", 2)), -20)[:int(0.4 * SR)], 0.001, 0.15) * 0.45, 0)
    return {"pyre-lift": lift, "pyre-flight": flight, "pyre-strike": hit, "sand-rebuild": rebuild, "sand-stone": stone, "sand-boom": boom}
