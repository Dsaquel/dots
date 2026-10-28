import json
import math
import os
import re

import numpy as np

from .dsp import SR, WORLDS, band, bell, hp, noise, pcm, place, sweep, t, tail
from .paths import ROOT


def seats():
    qml = open(os.path.join(ROOT, "parts", "Turn", "Score.qml")).read()
    prop = lambda name: float(re.search(r"readonly property real %s: ([0-9.]+)" % name, qml).group(1))  # noqa: E731
    landT, span, K, A0 = prop("landT"), prop("rbSpan"), prop("rbK"), prop("rbA0")
    mesh = json.load(open(os.path.join(ROOT, "assets", "turn", "mesh-anime.json")))["verts"]
    pieces = {}
    for v in mesh:
        pieces.setdefault((v[8], v[9], v[10]), (v[12], v[16]))
    out = []
    for (cx, cy, seed), (kind, size) in pieces.items():
        dx, dy = cx - 960.0, cy - 580.0; r = math.hypot(dx, dy)
        g = (0 if r < 90 else 1 if r < 200 else 2 if r < 380 else 3 if r < 450 else 4) if kind < 0.5 else (5 if r < 610 else 6 if r < 820 else 7)
        ph = (math.atan2(dy, dx) / (2 * math.pi) + A0 + 1.0) % 1.0
        q = min(8.0, max(0.0, g + ph))
        out.append((landT - span * (q / 8) ** K, g, size, seed))
    return landT, sorted(out)


def rebuild(rise_at, clink0):
    landT, seated = seats()
    rng = np.random.default_rng(97)
    out = {}
    for world, pch in WORLDS:
        c = out[world] = {}
        d = landT - rise_at; tt = t(d)
        whoosh = band(noise(rng, d), 700 * pch, 5200 * pch) * np.exp(-(d - tt) / 0.32)
        body = band(noise(rng, d), 180 * pch, 1400 * pch) * (tt / d) ** 1.4
        air = band(noise(rng, d), 3500 * pch, 9000 * pch) * (tt / d) ** 4.0
        shim = np.zeros(len(tt))
        for k, f in enumerate((1568, 2093, 2637, 3136, 3951, 4699)):
            rate = 7 + 17 * (tt / d) ** 2
            trem = 0.55 + 0.45 * np.sin(2 * np.pi * np.cumsum(rate) / SR + k)
            shim += sweep(f * pch, f * 1.22 * pch, d, 1.6) * trem * (0.6 + 0.4 * rng.uniform())
        shim *= (tt / d) ** 1.8
        x = whoosh * 0.8 + body * 0.55 + air * 0.18 + shim * 0.14
        x *= np.minimum(1.0, (d - tt) / 0.012)
        c["rb-rise"] = pcm(x, 0.85)
        d = landT - clink0 + 0.6; x = np.zeros(int(SR * d))
        for ts, g, size, seed in seated:
            f = (2300 + 2600 * (1 - g / 7) ** 1.4 + 900 * (seed - 0.5)) * pch
            a = (0.35 + 0.65 * min(1.0, size / 3.0)) * (0.55 + 0.45 * (1 - g / 7))
            tk = bell(f, 0.12, 0.028, ((1, 1), (1.47, .45), (2.09, .3))) * a
            n = noise(rng, 0.004); tk[: len(n)] += hp(n, 2) * np.exp(-np.arange(len(n)) / (SR * 0.0008)) * a * 0.6
            if size > 1.6:
                tk += bell(620 * pch * (0.9 + 0.2 * seed), 0.12, 0.03, ((1, 1), (2.3, .3))) * 0.35 * a
            place(x, tk, ts - clink0)
        c["rb-clinks"] = pcm(tail(rng, x, 0.5, 0.25), 0.8)
        d = 1.9; tt = t(d)
        thud = sweep(115 * pch, 42 * pch, d, 0.45) * np.exp(-tt / 0.13)
        click = np.zeros(len(tt)); n = noise(rng, 0.02); place(click, hp(n, 2) * np.exp(-t(0.02) / 0.003), 0.0)
        chord = (1046.5, 1318.5, 1568.0, 2093.0) if world == "dawn" else (880.0, 1108.7, 1318.5, 1760.0)
        chime = sum(bell(f * pch, d, 1.1) * a for f, a in zip(chord, (0.5, 0.38, 0.34, 0.26)))
        c["rb-land"] = pcm(tail(rng, thud * 1.25 + click * 0.7 + chime * 0.5, 1.4, 0.5))
        d = 0.9; tt = t(d)
        air = sum(band(noise(rng, d), f0 * pch, f0 * 1.6 * pch) * np.exp(-((tt - c0) / 0.11) ** 2) for f0, c0 in ((2400, 0.12), (3600, 0.22), (5200, 0.32)))
        tw = np.zeros(len(tt))
        for i, f in enumerate((3520, 4186, 4699, 5274, 6272)):
            place(tw, bell(f * pch, 0.5, 0.18, ((1, 1), (2.0, .25))) * (0.6 - 0.08 * i), 0.05 + i * 0.07)
        c["rb-glint"] = pcm(tail(rng, air * 0.35 + tw * 0.5, 0.8, 0.4), 0.7)
    return out
