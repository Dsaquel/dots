import numpy as np

SR = 48000
WORLDS = (("dawn", 1.0), ("dusk", 0.84))


def t(d): return np.arange(int(SR * d)) / SR
def lp(x, k): return np.convolve(x, np.ones(k) / k, "same")
def hp(x, k): return x - lp(x, k)
def bp(x, lo, hi): return lp(hp(x, lo), hi)
def noise(rng, d): return rng.normal(0, 1, int(SR * d))


def place(dst, src, at):
    s = int(SR * at); e = min(len(dst), s + len(src)); dst[s:e] += src[: e - s]; return dst


def sweep(f0, f1, d, shape=2.0):
    tt = t(d); f = f0 + (f1 - f0) * (tt / d) ** shape; return np.sin(2 * np.pi * np.cumsum(f) / SR)


def bell(f, d, r=0.8, parts=((1, 1), (2.76, .5), (5.4, .25), (8.9, .12))):
    tt = t(d); return sum(a * np.sin(2 * np.pi * f * m * tt) * np.exp(-tt / (r / m ** .5)) for m, a in parts)


def tail(rng, x, d=0.9, amt=0.35):
    tt = t(d); ir = noise(rng, d) * np.exp(-tt / (d / 5)); ir = lp(ir, 6)
    return x + np.convolve(x, ir)[: len(x)] * amt / (np.max(np.abs(ir)) * 40 + 1e-9)


def tinkles(rng, d, n, lo=2500, hi=7000, dec=0.05, spread=1.0):
    x = np.zeros(int(SR * d))
    for _ in range(n):
        f = rng.uniform(lo, hi); s = rng.uniform(0, d * spread) ** 1.3 / max(d * spread, 1e-6) ** 0.3
        place(x, bell(f, 0.25, dec * rng.uniform(0.6, 1.6), ((1, 1), (1.51, .4))) * rng.uniform(0.15, 1.0), min(s, d - 0.26))
    return x


def onepole(x, fc):
    y = np.zeros(len(x)); a = 1 - np.exp(-2 * np.pi * np.asarray(fc) / SR); s = 0.0
    for i in range(len(x)):
        s += a[i] * (x[i] - s); y[i] = s
    return y


def svf(x, fc, q, mode=1):
    g = np.tan(np.pi * np.minimum(np.broadcast_to(np.asarray(fc, np.float64), x.shape), SR * 0.45) / SR); k = 1.0 / q
    a1 = 1 / (1 + g * (g + k)); a2 = g * a1; a3 = g * a2
    y = [0.0] * len(x); c1 = c2 = 0.0
    for i, (v0, b1, b2, b3) in enumerate(zip(x.tolist(), a1.tolist(), a2.tolist(), a3.tolist())):
        v3 = v0 - c2; v1 = b1 * c1 + b2 * v3; v2 = c2 + b2 * c1 + b3 * v3
        c1 = 2 * v1 - c1; c2 = 2 * v2 - c2
        y[i] = (v2, v1, v0 - k * v1 - v2)[mode]
    return np.array(y)


def fade(x, a=0.004, b=0.004):
    n = len(x); env = np.ones(n); ia, ib = int(SR * a), int(SR * b)
    if ia: env[:ia] = np.linspace(0, 1, ia)
    if ib: env[n - ib:] = np.linspace(1, 0, ib)
    return x * env


def band(x, lo, hi):
    X = np.fft.rfft(x); f = np.fft.rfftfreq(len(x), 1 / SR)
    m = np.clip(np.minimum((f - lo * 0.7) / (lo * 0.3 + 1e-9), (hi * 1.3 - f) / (hi * 0.3)), 0, 1)
    return np.fft.irfft(X * m, len(x))


def pcm(x, peak=0.92):
    x = np.asarray(x, np.float64); x = x / (np.max(np.abs(x)) + 1e-9) * peak
    return (x * 32767).astype(np.int16)
