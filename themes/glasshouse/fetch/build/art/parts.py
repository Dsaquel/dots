import math

import numpy as np

from .canvas import SS, grid
from .palette import LEAD, hexf
from .shading import metal_strokes, over


def floor_for(width, her, cw, y):
    x = width + cw
    return {"y": y, "x": x, "w": x + her["fig"][2] - her["fig"][0] + 3 * cw}


def bead(size, colour, world):
    H = W = size
    ys, xs = grid(H, W)
    r = size / 2 - 1.5
    d = np.hypot(xs - W / 2 + 0.5, ys - H / 2 + 0.5)
    cov = np.clip((r - d) * SS + 0.5, 0, 1)
    base = hexf(colour) * (0.55 if world == "dark" else 0.9) + (0 if world == "dark" else 0.1)
    hl = np.exp(-(((xs - W * 0.38) ** 2 + (ys - H * 0.32) ** 2) / (size * size * 0.03)))[..., None]
    rim = np.clip((d - r * 0.55) / (r * 0.45), 0, 1)[..., None]
    col = base * (1.15 - 0.45 * rim) + hl * 0.45
    out = np.dstack([np.clip(col, 0, 1), cov])
    ring = metal_strokes(W, H, [lambda c: c.arc(W / 2, H / 2, r - 0.6, 0, math.tau)], 1.8, LEAD[world], 1.2)
    return over(out, ring)
