import numpy as np

from .cues import HOIST, MOTION, MULLION
from .dsp import SR, band, blank, decay, fade, flat, hits, limiter, norm, onset, peak, pitch, placed, put, ring, trill
from .takes import bank, take


def at_peak(mix, x, t, gain=1.0):
    early = max(peak(x) - int(t * SR), 0)
    x = x[early:].copy()
    if early:
        x[:1440] *= np.linspace(0, 1, min(1440, len(x))) ** 2
    put(mix, x * gain, t - (peak(x) if not early else int(t * SR)) / SR)


def stream(mix, grains, t0, t1, rate, gain, seed, origin=0.0):
    rng = np.random.default_rng(seed)
    t = t0 + rng.exponential(1 / max(rate(t0), 1))
    while t < t1:
        g = grains[rng.integers(len(grains))]
        put(mix, pitch(g, rng.uniform(0.94, 1.06)) * gain(t) * rng.uniform(0.4, 1), t - origin)
        t += rng.exponential(1 / max(rate(t), 1))


def arc(t0, t1, amp, src, seed, out=0.03):
    n = int((t1 - t0) * SR)
    t = t0 + np.arange(n) / SR
    x = take(*src)[int(0.02 * SR):][:n]
    body = norm(flat(band(x, 150, 12000)), -20) * 0.7 + norm(band(x, 150, 12000), -20) * 0.3
    hiss = norm(flat(band(x, 3000, 12000)), -20)
    tr = trill(n, np.full(n, 25.0), 2.0, 0.88, seed)
    tongue = np.clip((t - t0 - 0.04) / 0.015, 0, 1)
    y = body * (1 - tongue * (1 - tr)) * np.clip((t - t0 - 0.015) / 0.03, 0, 1) + 0.5 * hiss * (1 - tongue * 0.85 * (1 - tr)) * (1 + 1.2 * np.exp(-(t - t0) / 0.03))
    return fade(y * np.array([amp(v) for v in t]), 0.003, out)


def crystal():
    sparks = [fade(norm(h[:int(0.03 * SR)], -20), 0.001, 0.015) for h in hits(take("gz2-zap", 0), 0.015, -24, 0.04)][:6]
    ice = [h for k in (0, 1) for h in bank("r6-icesnap", k, 0.03, -24, 0.2)]
    return sparks, bank("r7-shards", 2, 0.03, -26, 0.15) + ice[:8]


def baked(stems, at, sec, shared=()):
    g = limiter(placed(stems, at, sec))
    out = dict(stems)
    for name, t, _ in at:
        if name not in shared:
            i, x = int(round(t * SR)), stems[name]
            seg = np.ones(len(x))
            n = max(0, min(len(x), len(g) - i))
            seg[:n] = g[i:i + n]
            out[name] = x * seg
    return out


def extension():
    m, (lo, hi, v) = MULLION, MOTION["sweep"]
    sparks, shards = crystal()
    sweep = lambda t: float(np.interp(t, np.linspace(lo, hi, len(v)), v, left=0, right=0))
    opened = lambda t: max(0.6 * np.clip(1 - (t - 0.02) / 0.25, 0, 1), sweep(t), 0.15 if t < 0.7 else 0.15 * np.clip((0.75 - t) / 0.05, 0, 1))
    open_, ring = blank(0.95), blank(0.4)
    put(open_, arc(0.02, 0.75, opened, ("r7-arc", 0), 3) * 0.75, 0.02)
    stream(open_, sparks, 0.12, 0.70, lambda t: 10 + 40 * sweep(t), lambda t: 0.2, 81)
    for t in (0.75, 0.81, 0.86):
        put(open_, sparks[1] * 0.15, t)
    stream(ring, sparks, m["boom"], m["boom"] + 0.25, lambda t: 200 * np.exp(-(t - m["boom"]) / 0.06) + 3, lambda t: 0.35 * np.exp(-(t - m["boom"]) / 0.08), 82, m["boom"])
    stems = {"crystal-open": open_, "crystal-flash": fade(norm(onset(take("r7-crack", 1)), -20)[:int(0.16 * SR)], 0.001, 0.06) * 0.9, "crystal-ring": ring,
             **{f"crystal-shard-{j + 1}": pitch(shards[j % len(shards)], 1.0 + 0.25 * j / 14) * 0.5 for j in range(16)},
             **{f"crystal-spark-{k + 1}": sparks[k] * 0.25 for k in range(6)}}
    names = [1 + j * 8 // len(m["stones"]) for j in range(len(m["stones"]))]
    at = [("crystal-open", 0, 1), ("crystal-flash", m["blink"], 1), ("crystal-ring", m["boom"], 1)]
    for j, t in enumerate(m["stones"]):
        at += [(f"crystal-shard-{j + 1}", t, 1 if j == 0 or names[j] != names[j - 1] else 0.56), (f"crystal-spark-{j % 6 + 1}", t + 0.004, 1)]
    return baked(stems, at, 2.0, [f"crystal-spark-{k + 1}" for k in range(6)]), at


def hoist():
    h = HOIST
    sparks, shards = crystal()
    snap = bank("r10-snap", 0, 0.05, -26, 0.12)[0]
    fizz = fade(norm(onset(take("r10-fizz", 1)), -20)[:int(0.12 * SR)] * decay(int(0.12 * SR), 0.035), 0.001, 0.04)
    rise = lambda t: np.clip((t - 0.02) / (h["slam"] - 0.02), 0, 1)
    up, burst, slam = blank(0.5), blank(0.1), blank(0.3)
    put(up, arc(0.02, h["slam"] + 0.004, lambda t: 0.3 + 0.7 * rise(t), ("r7-arc", 2), 5) * 0.7, 0.02)
    stream(up, sparks, 0.02, h["slam"] - 0.004, lambda t: 20 + 120 * rise(t), lambda t: 0.2 + 0.15 * rise(t), 83)
    for q in range(4):
        put(burst, sparks[q] * 0.4, 0.008 * q)
    put(slam, snap * 0.9, h["pre"] - peak(snap) / SR)
    put(slam, fizz * 0.4, h["pre"] + 0.004)
    stems = {"crystal-rise": up, "crystal-burst": burst, "crystal-slam": slam,
             **{f"crystal-row-{n}": pitch(shards[(n + 1) % len(shards)], 1.0 + 0.2 * (n - 1) / 7) * 0.35 for n in range(1, 9)}}
    at = [("crystal-rise", 0, 1), ("crystal-burst", h["shatter"], 1), ("crystal-slam", h["slam"] - h["pre"], 1)] + [(f"crystal-row-{n}", t, 1) for n, t in enumerate(h["rows"], 1)]
    return baked(stems, at, 1.0), at


def sanctuary():
    bell = onset(take("sd-bell", 0))
    a, b = blank(2.2), blank(1.0)
    put(a, fade(norm(take("gz2-shimmer", 0)[:int(0.22 * SR)], -20), 0.01, 0.12) * 0.3, 0)
    at_peak(a, norm(take("sd-air", 2), -20), 0.34, 0.7)
    put(a, fade(norm(onset(take("sd-harp", 2)), -20)[:int(0.18 * SR)], 0.003, 0.05) * 0.5, 0.18)
    put(a, ring(bell, 1.6, 0.5) * 0.6, 0.37)
    at_peak(b, norm(take("sd-back", 0), -20), 0.22, 0.7)
    put(b, norm(bell, -20)[:int(0.24 * SR)][::-1] * np.linspace(0, 1, int(0.24 * SR)) ** 2 * 0.6, 0)
    return a, b
