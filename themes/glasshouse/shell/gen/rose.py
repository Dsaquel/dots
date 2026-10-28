import math

import cairo
import numpy as np

from kit import TAU, out, canvas, straight_rgba, save_rgba, glow_of, lead, noise, save_height

D = 152
K = 2
S = D * K
C = S / 2
HUB, WAIST, TIP, FLARE = 30.6, 50.0, 61.8, math.tan(math.radians(11.8))
PETALS = {
    "left": ["fdeb9e", "fdefa9", "fce191", "fcb897", "fcb695", "fdd588", "fbb7a0", "fdce9a", "fdee93", "fdeaba"],
    "right": ["fceca1", "fde5a3", "fccba6", "fcbe97", "faa6ab", "fdd48a", "fdc88f", "fbae96", "fcdd99", "fdf1a7"],
}
RING = 62.6
BEAD = 57.5


def u(v):
    return v * K


def rgb(h):
    return tuple(int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))


def at(r, a):
    return C + u(r) * math.sin(a), C - u(r) * math.cos(a)


def lobe(a, grow=0.0):
    ux, uy = math.sin(a), -math.cos(a)
    vx, vy = -uy, ux

    def P(r, q):
        return C + u(ux * r + vx * q), C + u(uy * r + vy * q)
    r0, r1 = HUB - grow, TIP + grow
    w0, w1 = HUB * FLARE + grow, WAIST * FLARE + grow
    rh = u(math.hypot(r0, w0))
    side = math.atan2(w0, r0)
    base = a - math.pi / 2

    def draw(c):
        c.move_to(*P(r0, -w0))
        c.line_to(*P(WAIST, -w1))
        c.curve_to(*P(WAIST + 0.5 * (r1 - WAIST), -w1), *P(r1, -0.5 * w1), *P(r1, 0))
        c.curve_to(*P(r1, 0.5 * w1), *P(WAIST + 0.5 * (r1 - WAIST), w1), *P(WAIST, w1))
        c.line_to(*P(r0, w0))
        c.arc_negative(C, C, rh, base + side, base - side)
        c.close_path()
    return draw


def lift(col, k):
    return tuple(v + (1 - v) * k for v in col)


def petals(side):
    s, c = canvas(S, S)
    for k, hx in enumerate(PETALS[side]):
        a = k * TAU / 10
        col = rgb(hx)
        ux, uy = math.sin(a), -math.cos(a)
        vx, vy = -uy, ux

        def P(r, q):
            return C + u(ux * r + vx * q), C + u(uy * r + vy * q)
        shape = lobe(a)
        c.save()
        c.new_path()
        shape(c)
        c.clip()
        g = cairo.RadialGradient(*P(48, -2.5), 0, *P(46, 0), u(19))
        g.add_color_stop_rgba(0, *lift(col, 0.55), 1)
        g.add_color_stop_rgba(0.55, *col, 1)
        g.add_color_stop_rgba(1, col[0] * 0.93, col[1] * 0.74, col[2] * 0.62, 1)
        c.set_source(g)
        c.paint()
        deep = (col[0] * 0.9, col[1] * 0.66, col[2] * 0.5)
        c.set_line_width(u(0.7))
        c.set_source_rgba(*deep, 0.6)
        for sx in (-1, 1):
            c.move_to(*P(38, sx * 8.2))
            c.line_to(*P(51, 0))
            c.line_to(*P(58.5, sx * 6.2))
        c.move_to(*P(32, 0))
        c.line_to(*P(51, 0))
        c.stroke()
        c.set_source_rgba(*lift(col, 0.8), 0.5)
        c.set_line_width(u(1.6))
        c.move_to(*P(51.5, -3.2))
        c.line_to(*P(57, -1.4))
        c.stroke()
        c.restore()
    p = straight_rgba(s).astype(np.float32)
    streak = 0.94 + 0.12 * noise(S, S, 20, 41, 3)
    p[..., :3] = np.clip(p[..., :3] * streak[..., None], 0, 255)
    return p.astype(np.uint8)


def tracery():
    strokes = []
    for k in range(10):
        a = k * TAU / 10
        strokes.append((lobe(a, 1.2), u(2.4)))
    strokes.append((lambda c: c.arc(C, C, u(RING), 0, TAU), u(1.8)))
    for k in range(10):
        x, y = at(BEAD, (k + 0.5) * TAU / 10)
        strokes.append((lambda c, x=x, y=y: c.arc(x, y, u(3.6), 0, TAU), u(1.1)))
    return lead(S, S, strokes, radius=u(0.95))


def build():
    o = out("light")
    for side in ("left", "right"):
        arr = petals(side)
        save_rgba(arr, f"{o}/sanctum-rose-{side}.png")
        glow_of(arr, u(2.4), f"{o}/sanctum-rose-{side}-glow.png", 1.35)
    h, m = tracery()
    save_height(h, m, f"{o}/sanctum-rose-lead.png")
