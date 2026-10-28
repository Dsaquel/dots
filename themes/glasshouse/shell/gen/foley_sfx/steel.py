import numpy as np

from .cues import GLAZE, SLAM, STRIKE
from .dsp import SR, active, band, blank, fade, hits, norm, onset, peak, pitch, put, ring
from .takes import bank, cards, take


def riffle(mix, deck, a, b, r0, r1, amp, seed, shape, origin=0.0):
    rng = np.random.default_rng(seed)
    t = a
    while t < b:
        u = (t - a) / (b - a)
        h = pitch(deck[rng.integers(len(deck))], rng.uniform(0.9, 1.15))
        put(mix, h * amp * shape(u) * rng.uniform(0.35, 1), t - origin)
        t += rng.exponential(1 / (r0 * (r1 / r0) ** u))


def metal():
    deck = cards("sw2-metal-ticks")
    tap = bank("sw2-metal-ticks", 2, 0.3, -20, 0.6)[0]
    knock = norm(onset(take("sw2-glass-square", 0))[:int(0.25 * SR)], -20)
    glint = fade(norm(take("gz2-shimmer", 0)[:int(0.3 * SR)], -20), 0.004, 0.15) * 0.3
    return deck, tap, knock, glint


def steel():
    deck, tap, knock, glint = metal()
    edge = [fade(norm(h[:int(0.012 * SR)], -20, 0.004), 0.0005, 0.005) for h in hits(take("sw2-glass-riffle", 2), 0.006, -34, 0.02) if len(h) > 200]
    bridge = lambda u: np.sin(np.pi * min(u * 1.15, 1)) ** 0.7
    full, slam = blank(1.8), blank(1.4)
    riffle(full, deck, 0.03, 0.25, 70, 230, 0.7, 12, lambda u: 0.5 + 0.5 * u)
    riffle(full, edge, 0.03, 0.25, 70, 230, 0.2, 42, lambda u: 0.5 + 0.5 * u)
    riffle(full, deck, 0.25, SLAM - 0.004, 300, 360, 0.6, 22, bridge)
    put(full, knock * 0.6, SLAM)
    put(full, tap, SLAM - peak(tap) / SR)
    put(full, fade(band(norm(take("ml2-slide", 1)[:int(0.12 * SR)], -20), 1500, None), 0.004, 0.06) * 0.35, 0)
    put(full, glint, STRIKE)
    for mix, origin in ((full, 0.0), (slam, SLAM)):
        riffle(mix, deck, SLAM + 0.05, SLAM + 0.3, 30, 10, 0.3, 32, lambda u: (1 - u) ** 1.5, origin)
    put(slam, knock * 0.6, 0)
    put(slam, fade(tap[peak(tap):], 0.001, 0.2), 0)
    put(slam, glint, STRIKE - SLAM)
    return full, slam


def ticks(a, b, r0, r1):
    t, out = a, []
    while t < b:
        out.append(t)
        t += 1 / (r0 * (r1 / r0) ** ((t - a) / (b - a)))
    return out


def deal():
    deck, tap, knock, glint = metal()
    tock = bank("pv2-tock", 0, 0.3, -18, 0.3)
    gears = norm(onset(take("pv-gears", 1)), -20)
    latch = norm(onset(take("pv-latch", 0)), -20)[:int(0.3 * SR)]
    dong = ring(onset(take("pv2-dong", 1)), 0.9, 0.3) * 0.6
    warp = take("pv2-warp", 1)
    warp = norm(warp[:active(warp)[1]], -20)
    full, slam = blank(2.2), blank(1.8)
    put(full, fade(band(norm(take("ml2-slide", 1)[:int(0.12 * SR)], -20), 1500, None), 0.004, 0.06) * 0.35, 0)
    riffle(full, deck, 0.03, 0.12, 70, 160, 0.6, 13, lambda u: 1 - 0.5 * u)
    put(full, gears * 0.5, 0)
    for k, t in enumerate(ticks(0.2, SLAM - 0.02, 14, 58)):
        u = (t - 0.2) / (SLAM - 0.2)
        put(full, pitch(deck[(3 * k) % len(deck)], (1.15 if k % 2 == 0 else 0.85) * (1 + 0.3 * u)) * (0.45 + 0.4 * u), t)
        put(full, pitch(tock[k % len(tock)], 1 + 0.35 * u) * (0.12 + 0.12 * u), t)
    put(full, fade(warp[-int((SLAM - 0.2) * SR):], 0.05, 0.01) * 0.6, 0.2)
    put(full, tap, SLAM - peak(tap) / SR)
    put(slam, fade(tap[peak(tap):], 0.001, 0.2), 0)
    for mix, origin in ((full, SLAM), (slam, 0.0)):
        put(mix, latch * 0.7, origin)
        put(mix, knock * 0.6, origin)
        put(mix, dong * 0.75, origin + STRIKE - SLAM)
        put(mix, glint * 0.6, origin + STRIKE - SLAM)
        put(mix, pitch(deck[0], 0.85) * 0.35, origin + 0.55)
        put(mix, pitch(deck[3], 1.15) * 0.25, origin + 1.05)
    for mix, origin in ((full, 0.0), (slam, SLAM)):
        riffle(mix, deck, SLAM + 0.05, SLAM + 0.3, 30, 10, 0.3, 33, lambda u: (1 - u) ** 1.5, origin)
    return full, slam


def lightning():
    deck, tap, knock, glint = metal()
    zap = take("gz2-zap", 0)
    sparks = [fade(norm(h[:int(0.03 * SR)], -20), 0.001, 0.015) for h in hits(zap, 0.015, -24, 0.04)][:6]
    zing = fade(norm(band(take("r6-zing", 0), 1500, None), -20)[:int(0.14 * SR)], 0.002, 0.08)
    pre = GLAZE["pre"]
    rows = {f"scratch-row-{n}": pitch(deck[(3 * (n - 1)) % len(deck)], 1.0 + 0.04 * (n - 1)) * 0.4 for n in range(1, 9)}
    slam = blank(0.6)
    put(slam, tap, pre - peak(tap) / SR)
    put(slam, knock * 0.6, pre)
    put(slam, fade(norm(zap[:int(0.12 * SR)], -20), 0.002, 0.05) * 0.3, pre)
    put(slam, zing * 0.45, pre + 0.01)
    for k, dt in enumerate([0.02, 0.032, 0.046, 0.059, 0.072, 0.085]):
        put(slam, sparks[k % len(sparks)] * 0.3, pre + dt)
    hide = blank(0.6)
    put(hide, fade(norm(take("gz2-shimmer", 0)[:int(0.12 * SR)], -20), 0.01, 0.06) * 0.15, 0.02)
    for j, t in enumerate(np.linspace(0.145, 0.30, 8)):
        put(hide, pitch(deck[(2 * j + 5) % len(deck)], 1.15 - 0.05 * j) * 0.3, t)
    return {**rows, "scratch-slam": slam, "scratch-gild": glint}, {"scratch-hide": hide}
