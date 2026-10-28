import wave

import numpy as np

SR, PAD, PRE, ROOM = 48000, 24, .011, .7
RT60 = [1.4, 1.3, 1.15, 1.0, .8, .6, .35]
RNG = np.random.default_rng(1028)
PANE = np.random.default_rng(2611)
ISO40 = np.array([(250, 50.4), (315, 47.6), (400, 45.0), (500, 43.1), (630, 41.3), (800, 40.1), (1000, 40.0),
                  (1250, 41.8), (1600, 42.5), (2000, 39.2), (2500, 36.5), (3150, 35.6), (4000, 36.7),
                  (5000, 40.0), (6300, 45.8), (8000, 51.8), (10000, 54.3), (12500, 51.5)]).T

GLASS = dict(tau=.42, fc=3800, click=.02, attack=.004,
             parts=[(1, 1, 1, .9, .2), (2.32, .22, .55, 1.7, .4), (4.25, .08, .3, 2.6, .4), (6.63, .025, .18, 3.1, .3)])
CRYSTAL = dict(tau=.16, fc=7500, click=.07, attack=.0012,
               parts=[(1, 1, 1, 1.4, .1), (2.76, .3, .3, 4.7, .3), (5.40, .12, .14, 6.3, .3), (8.93, .04, .08, 8, .3)])
SPARK = dict(tau=.04, fc=8000, click=0, attack=.0008, parts=[(1, 1, 1, 7, .3), (2.76, .18, .4, 9, .3)])

def hz(note):
    return 440 * 2 ** (("C D EF G A B".index(note[0]) - 9) / 12 + int(note[1:]) - 4)

def secs(dur):
    return np.arange(int(round(dur * SR))) / SR

def ramp(t, a=.001):
    return np.sin(np.pi / 2 * np.minimum(t / a, 1)) ** 2

def rolloff(f, fc=6000, order=2):
    return 1 / np.sqrt(1 + (f / fc) ** (2 * order))

def band(n, fc, octs, rng=RNG):
    f = np.fft.rfftfreq(n, 1 / SR)
    x = np.fft.irfft(np.fft.rfft(rng.standard_normal(n)) * np.exp(-.5 * (np.log2(np.maximum(f, 1) / fc) / octs) ** 2), n)
    return x / np.sqrt(np.mean(x ** 2))

def strike(f, voice, amp=1., tau=None, rng=RNG):
    tau = (tau or voice["tau"]) * (hz("C5") / f) ** .15
    t, tilt = secs(7 * tau), min(1, (hz("C5") / f) ** .5)
    x = sum(a * (1 if r == 1 else tilt) * rolloff(f * r, voice["fc"]) * np.exp(-t / (tau * d))
            * (np.sin(2 * np.pi * f * r * t) + m * np.sin(2 * np.pi * (f * r + b) * t)) for r, a, d, b, m in voice["parts"])
    if voice["click"]:
        x[:480] += voice["click"] * band(480, min(4 * f, 4000), .6, rng) * np.exp(-t[:480] / .0012)
    return amp * x * ramp(t, voice["attack"])

def ring(f, voice, amp, hold, fall=.09):
    t, mute = secs(hold + fall), {**voice, "click": 0}
    x = layered(strike(f, mute, .62, voice["tau"] * .3), strike(f, mute, .38, voice["tau"] * 2))[:len(t)]
    return amp * x * np.cos(np.pi / 2 * np.clip((t - hold) / fall, 0, 1)) ** 2

def bubble(f0, f1, tau, amp=1.):
    t = secs(6 * tau)
    f = f0 * (f1 / f0) ** np.minimum(t / (3 * tau), 1)
    return amp * np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / tau) * ramp(t, .0008)

def burst(fc, octs, tau, res=0, rng=RNG):
    t = secs(8 * tau)
    return (band(len(t), fc, octs, rng) + (.7 * band(len(t), res, .04, rng) if res else 0)) * np.exp(-t / tau) * ramp(t, .0006)

def sweep(dur, f0, f1, octs=.5, rise=.3, fall=1.5, rng=RNG):
    t = secs(dur)
    u = t / dur
    ks = 2 ** np.arange(7, 13.4, .25)
    w = np.exp(-.5 * (np.log2(ks[:, None] / (f0 * (f1 / f0) ** u)) / octs) ** 2)
    x = sum(wk * band(len(t), k, .15, rng) for wk, k in zip(w, ks))
    env = u ** rise * (1 - u) ** fall
    return x / np.sqrt(np.mean(x ** 2)) * env / env.max()

def pad(notes, rise, tau, harmonics=((1, 1), (2, .25), (3, .08)), cents=5):
    t = secs(8 * tau)
    x = sum(a * (1 if c == 0 else .35) * rolloff(hz(n) * h)
            * np.sin(2 * np.pi * hz(n) * h * 2 ** (c / 1200) * t + RNG.uniform(0, 2 * np.pi))
            for n in notes for h, a in harmonics for c in (-cents, 0, cents))
    return x * (1 - np.exp(-t / rise)) * np.exp(-t / tau) / len(notes)

def dust(t0, t1, count, notes, amp, rng=RNG):
    return [(t, strike(hz(rng.choice(notes)), SPARK, amp * rng.uniform(.4, 1) * (1 - (t - t0) / (t1 - t0)) ** 1.5))
            for t in np.sort(rng.uniform(t0, t1, count))]

def layered(*xs):
    out = np.zeros(max(len(x) for x in xs))
    for x in xs:
        out[:len(x)] += x
    return out

def crack(fc, amp=1.):
    t = secs(.06)
    knock = np.sin(2 * np.pi * (fc / 24) * t) * np.exp(-t / .012) * ramp(t, .0006)
    return amp * layered(burst(fc, .6, .003, rng=PANE), .5 * burst(fc / 2.6, .5, .009, fc / 3.1, PANE), .35 * knock)

def solder(start, count, gap, fc, amp, rng=PANE):
    return [(start + i * gap * (1 + .12 * i), amp * (1 - .1 * i) * layered(burst(fc, .25, .0025, fc * 1.07, rng), .12 * burst(fc * 2, .9, .03, rng=rng)))
            for i in range(count)]

def laying(start, end, count, notes, amp):
    return [(start + (end - start) * (1 - np.sqrt(1 - i / count)), strike(hz(notes[i % len(notes)]), SPARK, amp * (1 - .4 * i / count)))
            for i in range(count)]

def room(dur=1.2, seed=235):
    t = secs(dur)
    octave = np.clip(np.log2(np.maximum(np.fft.rfftfreq(len(t), 1 / SR), 1) / 125), 0, 6)
    spectrum = np.fft.rfft(np.random.default_rng(seed).standard_normal(len(t)))
    ir = sum(np.fft.irfft(spectrum * np.clip(1 - abs(octave - k), 0, 1), len(t)) * np.exp(-6.91 * t / (ROOM * rt))
             for k, rt in enumerate(RT60))
    ir = np.concatenate([np.zeros(int(PRE * SR)), ir * (1 - np.exp(-t / .01))])
    return ir / np.sqrt(np.sum(ir ** 2))

IR = room()

def master(x, wet, fade, fc):
    x = np.concatenate([np.zeros(PAD), x[:-PAD]])
    n, m, k = len(x), len(x) + len(IR), int(fade * SR)
    y = x + wet * np.fft.irfft(np.fft.rfft(x, m) * np.fft.rfft(IR, m), m)[:n]
    y = np.fft.irfft(np.fft.rfft(y, 2 * n) * rolloff(np.fft.rfftfreq(2 * n, 1 / SR), fc, 4), 2 * n)[:n]
    return y * np.concatenate([ramp(secs(PAD / SR), PAD / SR), np.ones(n - PAD - k), ramp(secs(k / SR)[::-1], (k - 1) / SR)])

def render(dur, events, wet, fc):
    b = np.zeros(int(round(dur * SR)))
    for t0, x in events:
        i = int(round(t0 * SR))
        n = min(len(x), len(b) - i)
        b[i:i + n] += x[:n]
    return master(b, wet, .3 * dur, fc)

def loud40(x):
    f = np.fft.rfftfreq(len(x), 1 / SR)
    gain = 10 ** ((40 - np.interp(np.log(np.maximum(f, 1)), np.log(ISO40[0]), ISO40[1])) / 20)
    k, y = int(.2 * SR), np.fft.irfft(np.fft.rfft(x) * gain, len(x)) ** 2
    c = np.cumsum(np.pad(y, k))
    return 10 * np.log10((c[k:] - c[:-k]).max() / k + 1e-20)

def write(path, x):
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(np.round(np.clip(x, -1, 1) * 32767).astype("<i2").tobytes())
