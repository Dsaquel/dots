import numpy as np

from .filters import blur
from .video import FPS

DOSE = 0.2
GLIMMER = 0.06
LIT = 0.1
SCATTER = 0.15
SPREAD = 700


def written(light, block, first, last):
    dose = np.cumsum(np.clip(np.stack([blur(m, 2) for m in light[first:]]) - GLIMMER, 0, None), 0)
    total = dose[-1]
    if not total.max() > 0:
        return None
    t = np.where(total >= DOSE * total.max(), (first + (dose >= DOSE * total.max()).argmax(0)) / FPS, np.inf)
    while np.isinf(t).any():
        p = np.pad(t, 1, constant_values=np.inf)
        near = np.minimum.reduce([p[1 + dy:p.shape[0] - 1 + dy, 1 + dx:p.shape[1] - 1 + dx] for dy in (-1, 0, 1) for dx in (-1, 0, 1)])
        t = np.where(np.isinf(t), near + block / SPREAD, t)
    t = blur(blur(t, 2), 2) + np.random.default_rng(5).uniform(-SCATTER, SCATTER, t.shape)
    on = np.stack([blur(m, 1) for m in light[first:last + 1]])
    when = (first + np.arange(len(on)))[:, None, None] / FPS
    gap = np.where(on >= LIT, np.abs(when - t), np.inf)
    reached = np.isfinite(gap.min(0))
    t = np.where(reached, (first + gap.argmin(0)) / FPS, t)
    for r in (0, 4, 8, 16):
        close = np.stack([blur(m, r) for m in light[first:last + 1]])
        found = ~reached & (close.max(0) >= LIT / 4)
        t = np.where(found, (first + close.argmax(0)) / FPS, t)
        reached |= found
    return {"block": block, "t": (np.ceil(t * 1000) / 1000).tolist()}
