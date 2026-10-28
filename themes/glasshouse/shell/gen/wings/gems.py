import math

import cairo
import numpy as np

from kit import TAU

from .draw import knob, oval
from .raster import lift, mix


def facets(c, shape, col, cx, cy, r, seed):
    c.new_path()
    shape(c)
    c.save()
    c.clip()
    g = cairo.RadialGradient(cx - r * 0.2, cy - r * 0.35, 0, cx, cy, r * 1.25)
    g.add_color_stop_rgba(0, *lift(col, 0.55), 1)
    g.add_color_stop_rgba(0.5, *col, 1)
    g.add_color_stop_rgba(1, *[v * 0.55 for v in col], 1)
    c.set_source(g)
    c.paint()
    rng = np.random.default_rng(seed)
    pts = []
    n = 9
    for i in range(n):
        a = -math.pi / 2 + i * TAU / n + rng.uniform(-0.18, 0.18)
        pts.append((cx + math.cos(a) * r * 2.2, cy + math.sin(a) * r * 2.2))
    for i in range(n):
        c.move_to(cx, cy)
        c.line_to(*pts[i])
        c.line_to(*pts[(i + 1) % n])
        c.close_path()
        c.set_source_rgba(*((1, 1, 1) if i % 2 else (0, 0, 0)), 0.1 if i % 2 else 0.12)
        c.fill()
    c.set_source_rgba(*lift(col, 0.7), 0.5)
    c.set_line_width(0.5)
    for p in pts:
        c.move_to(cx, cy)
        c.line_to(*p)
        c.stroke()
    c.set_source_rgba(1, 1, 1, 0.55)
    oval(c, cx - r * 0.3, cy - r * 0.42, r * 0.26, r * 0.15, -0.5)
    c.fill()
    c.restore()


def cabochon(c, cx, cy, rx, ry, rot, col, pearl=False):
    c.save()
    c.new_path()
    oval(c, cx, cy, rx, ry, rot)
    c.clip()
    rr = max(rx, ry)
    g = cairo.RadialGradient(cx - rx * 0.28, cy - ry * 0.34, 0, cx, cy, rr * 1.12)
    if pearl:
        g.add_color_stop_rgba(0, *lift(col, 0.6), 1)
        g.add_color_stop_rgba(0.45, *col, 1)
        g.add_color_stop_rgba(1, *[v * 0.62 for v in mix(col, (0.62, 0.55, 0.8), 0.4)], 1)
    else:
        g.add_color_stop_rgba(0, *lift(col, 0.45), 1)
        g.add_color_stop_rgba(0.42, *col, 1)
        g.add_color_stop_rgba(1, *[v * 0.32 for v in col], 1)
    c.set_source(g)
    c.paint()
    g = cairo.RadialGradient(cx + rx * 0.25, cy + ry * 0.34, 0, cx + rx * 0.25, cy + ry * 0.34, rr * 0.62)
    g.add_color_stop_rgba(0, *lift(col, 0.35 if not pearl else 0.1), 0.0 if pearl else 0.55)
    g.add_color_stop_rgba(1, *col, 0)
    c.set_source(g)
    c.paint()
    c.set_source_rgba(1, 1, 1, 0.82 if not pearl else 0.7)
    oval(c, cx - rx * 0.34, cy - ry * 0.4, rx * 0.3, ry * 0.18, -0.6)
    c.fill()
    c.set_source_rgba(1, 1, 1, 0.9)
    knob(c, cx - rx * 0.12, cy - ry * 0.52, rr * 0.06)
    c.fill()
    c.restore()
