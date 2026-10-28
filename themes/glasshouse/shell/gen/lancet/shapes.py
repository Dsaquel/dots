import math

import numpy as np
from PIL import Image, ImageFilter

from kit import TAU

from .layout import S


def s(v):
    return v * S


def outline(c, L, inset=0.0):
    x0, x1 = s(inset), s(L["W"] - inset)
    R = x1 - x0
    sp = s(L["spring"])
    bot = s(L["sill"]["y"] + 4)
    xm = (x0 + x1) / 2
    h = math.sqrt(max(R * R - (xm - x0) ** 2, 0))
    c.move_to(x0, bot)
    c.line_to(x0, sp)
    c.arc(x1, sp, R, math.pi, math.atan2(-h, xm - x1))
    c.arc(x0, sp, R, math.atan2(-h, xm - x0), 0)
    c.line_to(x1, bot)


def closed_outline(c, L, inset=0.0):
    outline(c, L, inset)
    c.line_to(s(inset), s(L["sill"]["y"] + 4))
    c.close_path()


def niche_path(c, n, inset=0.0):
    x0, y0, w, h = s(n["x"] + inset), s(n["y"] + inset), s(n["w"] - 2 * inset), s(n["h"] - 2 * inset)
    rise = s(20) - s(inset) * 0.5
    xm = x0 + w / 2
    c.move_to(x0, y0 + h)
    c.line_to(x0, y0 + rise)
    c.curve_to(x0, y0 + rise * 0.45, xm - w * 0.22, y0 + rise * 0.1, xm, y0)
    c.curve_to(xm + w * 0.22, y0 + rise * 0.1, x0 + w, y0 + rise * 0.45, x0 + w, y0 + rise)
    c.line_to(x0 + w, y0 + h)
    c.close_path()


def rrect(c, x, y, w, h, r):
    x, y, w, h, r = s(x), s(y), s(w), s(h), s(r)
    c.new_sub_path()
    c.arc(x + w - r, y + r, r, -math.pi / 2, 0)
    c.arc(x + w - r, y + h - r, r, 0, math.pi / 2)
    c.arc(x + r, y + h - r, r, math.pi / 2, math.pi)
    c.arc(x + r, y + r, r, math.pi, 3 * math.pi / 2)
    c.close_path()


def quatrefoil(c, cx, cy, r):
    for k in range(4):
        a = k * TAU / 4
        c.new_sub_path()
        c.arc(s(cx) + s(r * 0.5) * math.cos(a), s(cy) + s(r * 0.5) * math.sin(a), s(r * 0.52), 0, TAU)


def arch(c, x, sp, w, bot):
    c.move_to(s(x), s(bot))
    c.line_to(s(x), s(sp))
    c.arc(s(x + w), s(sp), s(w), math.pi, 4 * math.pi / 3)
    c.arc(s(x), s(sp), s(w), 5 * math.pi / 3, 2 * math.pi)
    c.line_to(s(x + w), s(bot))
    c.close_path()


def latch_box(L):
    lt = L["latch"]
    x, top, w = lt["cx"] - lt["w"] / 2, lt["cy"] - lt["h"] / 2, lt["w"]
    return x, top + w * math.sqrt(3) / 2, w, top + lt["h"]


def lozenge(c, cx, cy, rx, ry):
    c.move_to(s(cx), s(cy - ry))
    c.line_to(s(cx + rx), s(cy))
    c.line_to(s(cx), s(cy + ry))
    c.line_to(s(cx - rx), s(cy))
    c.close_path()


def blur(a, r):
    return np.asarray(Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(r)), np.float32) / 255
