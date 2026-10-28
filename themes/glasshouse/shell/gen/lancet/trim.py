import math

import cairo
import numpy as np
from PIL import Image, ImageFilter

from kit import A, TAU, bevel, canvas, circle, fill_cell, glow_of, lead, mask, out, pane, save_height, save_rgba, star4, straight_rgba

from .layout import HEX, PAL
from .shapes import rrect


def glints(world):
    o = out(world)
    col = (1.0, 0.80, 0.48) if world == "dark" else (1.0, 0.36, 0.72)
    SZ = 64
    C = SZ / 2
    sf, c = canvas(SZ, SZ)
    g = cairo.RadialGradient(C, C, 0, C, C, C)
    g.add_color_stop_rgba(0, *col, 0.55)
    g.add_color_stop_rgba(1, *col, 0)
    c.set_source(g)
    c.paint()
    star4(c, C, C, C - 2, 0.07)
    c.set_source_rgba(*[min(1, v * 0.35 + 0.7) for v in col], 1)
    c.fill()
    star4(c, C, C, C * 0.42, 0.12, rot=-math.pi / 4)
    c.set_source_rgba(*col, 0.85)
    c.fill()
    save_rgba(straight_rgba(sf), f"{o}/lancet-glint.png")


def tip(world):
    P = PAL[world]
    o = out(world)
    pane(world, "lancet-tip", 120, 44, 10, HEX(P["tip"]), 4)
    w, h = 120, 44
    g = mask(w, h, lambda c: (c.set_line_width(1.3), c.rectangle(6.5, 6.5, w - 13, h - 13), c.stroke()))
    dots = mask(w, h, lambda c: [(star4(c, x, y, 4.6, 0.2), c.fill()) for x, y in ((6.5, 6.5), (w - 6.5, 6.5), (6.5, h - 6.5), (w - 6.5, h - 6.5))])
    save_height(np.maximum(bevel(g, 0.8) * 0.8, bevel(dots, 1.4)), np.maximum(g, dots), f"{o}/lancet-tip-gilt.png")


def shadow():
    S2 = 96
    sf, c = canvas(S2, S2)
    rrect(c, 12, 12, 24, 24, 3)
    c.set_source_rgba(0.02, 0.02, 0.06, 1)
    c.fill()
    im = Image.fromarray(straight_rgba(sf), "RGBA")
    a = np.asarray(im.getchannel("A").filter(ImageFilter.GaussianBlur(9)), np.float32) * 0.62
    out = np.zeros((S2, S2, 4), np.uint8)
    out[..., :3] = (5, 5, 14)
    out[..., 3] = np.clip(a, 0, 255).astype(np.uint8)
    Image.fromarray(out, "RGBA").save(f"{A}/shared/lancet-shadow.png")


def jewel(world):
    o = out(world)
    S2 = 36
    C = S2 / 2
    col = (0.95, 0.70, 0.37) if world == "dark" else (0.89, 0.08, 0.50)
    diamond = lambda c: (c.move_to(C, 3), c.line_to(S2 - 3, C), c.line_to(C, S2 - 3), c.line_to(3, C), c.close_path())  # noqa: E731
    sf, c = canvas(S2, S2)
    fill_cell(c, diamond, col, C, C - 3, 15, 0.38)
    arr = straight_rgba(sf)
    save_rgba(arr, f"{o}/lancet-jewel.png")
    glow_of(arr, 5, f"{o}/lancet-jewel-glow.png", 1.4)
    h, m = lead(S2, S2, [(diamond, 3.2), (lambda c: (c.move_to(C, 6), c.line_to(C, S2 - 6)), 1.2)], radius=1.6)
    save_height(h, m, f"{o}/lancet-jewel-lead.png")


def seal(world):
    o = out(world)
    S2 = 44
    C = S2 / 2
    sf, c = canvas(S2, S2)
    fill_cell(c, circle(C, C, C - 4), (0.10, 0.12, 0.27) if world == "dark" else (0.17, 0.19, 0.55), C, C - 4, C, 0.22)
    save_rgba(straight_rgba(sf), f"{o}/lancet-seal.png")
    ring = mask(S2, S2, lambda c: (c.set_fill_rule(cairo.FILL_RULE_EVEN_ODD), c.arc(C, C, C - 1, 0, TAU), c.new_sub_path(), c.arc(C, C, C - 5, 0, TAU), c.fill()))
    save_height(bevel(ring, 2.0), ring, f"{o}/lancet-seal-lead.png")
    glow_of(straight_rgba(sf), 4, f"{o}/lancet-seal-glow.png", 1.0)
