import wave
from fractions import Fraction

import numpy as np
from scipy.ndimage import maximum_filter1d
from scipy.signal import butter, lfilter, resample_poly, sosfilt

SR = 48000


def read(path):
    with wave.open(path) as w:
        x = np.frombuffer(w.readframes(w.getnframes()), "<i2") / 32768
        return x if w.getnchannels() == 1 else x.reshape(-1, w.getnchannels()).mean(1)


def band(x, lo=None, hi=None, order=4):
    if lo and hi:
        return sosfilt(butter(order, [lo, hi], "bandpass", fs=SR, output="sos"), x)
    if lo:
        return sosfilt(butter(order, lo, "highpass", fs=SR, output="sos"), x)
    return sosfilt(butter(order, hi, "lowpass", fs=SR, output="sos"), x)


def env(x, ms=5):
    n = max(1, int(SR * ms / 1000))
    return np.sqrt(np.convolve(x ** 2, np.ones(n) / n, "same"))


def active(x, db=-30):
    e = env(x, 10)
    on = np.flatnonzero(e > e.max() * 10 ** (db / 20))
    return (on[0], on[-1]) if len(on) else (0, len(x))


def onsets(x, gap=0.035, db=-26):
    e = env(x, 2)
    d = np.diff(e, prepend=0)
    th = e.max() * 10 ** (db / 20)
    out, last = [], -SR
    for i in np.flatnonzero((d > 0) & (e > th)):
        if i - last > gap * SR:
            out.append(i)
        last = i if i - last > gap * SR else last
    return out


def hits(x, gap=0.035, db=-26, length=0.25):
    on = onsets(x, gap, db)
    out = []
    for i, a in enumerate(on):
        b = min(on[i + 1] if i + 1 < len(on) else len(x), a + int(length * SR))
        h = x[max(a - 96, 0):b].copy()
        n = min(len(h) // 3, 960)
        h[-n:] *= np.linspace(1, 0, n) ** 2
        h[:48] *= np.linspace(0, 1, min(48, len(h)))
        out.append(h)
    return out


def pitch(x, ratio):
    q = Fraction(ratio).limit_denominator(200)
    return resample_poly(x, q.denominator, q.numerator)


def norm(x, db=-20, win=0.1):
    n = int(win * SR)
    r = np.convolve(x ** 2, np.ones(n) / n, "valid").max() if len(x) > n else np.mean(x ** 2)
    return x * 10 ** ((db - 10 * np.log10(r + 1e-12)) / 20)


def put(mix, x, t):
    i = int(round(t * SR))
    a, b = max(i, 0), min(i + len(x), len(mix))
    if b > a:
        mix[a:b] += x[a - i:b - i]


def blank(sec):
    return np.zeros(int(sec * SR))


def fade(x, a=0.004, b=0.04):
    x = x.copy()
    na, nb = min(int(a * SR), len(x)), min(int(b * SR), len(x))
    x[:na] *= np.linspace(0, 1, na)
    x[len(x) - nb:] *= np.linspace(1, 0, nb) ** 2
    return x


def onset(x):
    on = onsets(x)
    return fade(x[max(on[0] - 96, 0):] if on else x, 0.002, 0)


def peak(x):
    return int(np.argmax(env(x, 10)))


def decay(n, tau):
    return np.exp(-np.arange(n) / SR / tau)


def ring(x, length, tau):
    x = norm(x, -20)[:int(length * SR)]
    return x * decay(len(x), tau)


def secs(a, b):
    return np.arange(int((b - a) * SR)) / SR + a


def trill(n, rate, sharp, depth, seed):
    rng = np.random.default_rng(seed)
    r = np.broadcast_to(rate, (n,)) * (1 + 0.06 * np.interp(np.arange(n), np.linspace(0, n, 40), rng.standard_normal(40)))
    return 1 - depth + depth * (0.5 + 0.5 * np.cos(2 * np.pi * np.cumsum(r) / SR)) ** sharp


def flat(x, ms=12):
    return x / (env(x, ms) + 1e-4)


def kweight(x):
    x = lfilter([1.53512485958697, -2.69169618940638, 1.19839281085285], [1, -1.69065929318241, 0.73248077421585], x)
    return lfilter([1, -2, 1], [1, -1.99004745483398, 0.99007225036621], x)


def level(x):
    k = kweight(x) ** 2
    c = np.concatenate([[0], np.cumsum(k)])
    return np.mean([10 * np.log10((c[n:] - c[:-n]).max() / n + 1e-12) - 0.691 for n in (int(0.4 * SR), int(0.1 * SR))])


def limiter(x, crest=14.5, release=0.012):
    top = 10 ** ((level(x) + crest) / 20)
    g = np.minimum(1.0, top / np.maximum(maximum_filter1d(np.abs(x), 2 * int(0.0015 * SR) + 1), 1e-9))
    k = 1 - np.exp(-1 / (release * SR))
    out, v = np.empty_like(g), 1.0
    for i, t in enumerate(g):
        v = t if t < v else v + (t - v) * k
        out[i] = v
    return out


def placed(stems, at, sec):
    mix = blank(sec)
    for name, t, g in at:
        put(mix, stems[name] * g, t)
    return mix


def write(path, x):
    x = x[:active(x, -60)[1] + int(0.02 * SR)] if np.abs(x).max() > 0 else x
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(np.round(np.clip(x / max(1, np.abs(x).max() / 0.98), -1, 1) * 32767).astype("<i2").tobytes())
