import math

import numpy as np

from .canvas import SS, glyph_mask, grid, shape
from .palette import CARDO, DEJAVU, GILT, LEAD, hexf
from .shading import bevel, emboss, glass, metal_strokes, noise, over


def roundel(size, world, inner):
    W = H = size
    r = size / 2 - 3
    disc = shape(W, H, lambda c: (c.arc(W / 2, H / 2, r, 0, math.tau), c.fill()))
    art = over(np.zeros(disc.shape + (4,), np.float32), inner(disc, r))
    art = over(art, metal_strokes(W, H, [lambda c: c.arc(W / 2, H / 2, r, 0, math.tau)], 3.2, LEAD[world], 1.8))
    art = over(art, metal_strokes(W, H, [lambda c: c.arc(W / 2, H / 2, r - 3.2, 0, math.tau)], 1.0, GILT, 0.7))
    return art


def moon_disc(world, phase):
    def inner(disc, r):
        H, W = disc.shape[0] // SS, disc.shape[1] // SS
        ys, xs = grid(H, W)
        x, y = (xs - W / 2 + 0.5) / (r - 2), (ys - H / 2 + 0.5) / (r - 2)
        k = math.cos(math.tau * phase)
        edge = np.sqrt(np.clip(1 - y * y, 0, 1))
        lit = np.clip(((x - k * edge) if phase < 0.5 else (-k * edge - x)) * (r - 2) * SS + 0.5, 0, 1)
        night = glass(disc, "#0b1030" if world == "dark" else "#2a3a8a", "#141a44" if world == "dark" else "#1c2766", "#26306a", (0.5, 0.5), 0.5, 1.0, 4)
        maria = noise(W * SS, H * SS, 6.0, 31, 3)
        moonc = hexf("#eef1ff") * (0.86 + 0.18 * maria[..., None])
        face = np.dstack([moonc, disc * lit * (x * x + y * y <= 1.0)])
        return over(night, face)
    return inner


def planet_disc(world, glyph):
    def inner(disc, r):
        H, W = disc.shape[0] // SS, disc.shape[1] // SS
        ground = glass(disc, "#152056" if world == "dark" else "#1d3f9e", "#0d1338" if world == "dark" else "#122a70", "#3550b0", (0.35, 0.25), 0.6, 1.0, 6)
        m = glyph_mask(W, H, glyph, CARDO if glyph in "☉☽" else DEJAVU, int(r * 1.35), W / 2, H / 2 + 1)
        return over(ground, emboss(bevel(m, 2.0), m, GILT))
    return inner
