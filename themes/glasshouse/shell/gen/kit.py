import math
import os

import cairo
import numpy as np
from PIL import Image, ImageFilter

from orn import canvas, alpha, bevel, save_height, noise  # noqa: F401

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
A = os.path.join(ROOT, "assets")
TAU = math.tau
WORLDS = ("dark", "light")

PAL = {
    "dark": dict(rose=(0.85, 0.40, 0.56), cyan=(0.31, 0.70, 0.86), amber=(0.93, 0.66, 0.30),
                 teal=(0.42, 0.72, 0.66), violet=(0.55, 0.45, 0.84), deep=(0.16, 0.22, 0.46),
                 moon=(0.86, 0.89, 0.97), gold=(0.88, 0.70, 0.40), leaf=(0.40, 0.64, 0.46),
                 ink=(0.12, 0.15, 0.30)),
    "light": dict(rose=(0.90, 0.28, 0.55), cyan=(0.38, 0.82, 0.92), amber=(0.97, 0.78, 0.44),
                teal=(0.34, 0.74, 0.72), violet=(0.58, 0.36, 0.80), deep=(0.36, 0.48, 0.84),
                moon=(0.99, 0.96, 0.88), gold=(0.97, 0.78, 0.44), leaf=(0.46, 0.74, 0.50),
                ink=(0.20, 0.18, 0.44)),
}
WHITE = (0.92, 0.93, 0.97)


def out(world):
    d = os.path.join(A, world)
    os.makedirs(d, exist_ok=True)
    return d


def straight_rgba(s):
    s.flush()
    a = np.ndarray((s.get_height(), s.get_stride() // 4, 4), np.uint8, s.get_data())[:, : s.get_width()]
    b, g, r, al = [a[..., i].astype(np.float32) for i in range(4)]
    o = np.zeros(a.shape, np.float32)
    nz = np.maximum(al, 1)
    o[..., 0] = np.where(al > 0, r * 255 / nz, 0)
    o[..., 1] = np.where(al > 0, g * 255 / nz, 0)
    o[..., 2] = np.where(al > 0, b * 255 / nz, 0)
    o[..., 3] = al
    return np.clip(o, 0, 255).astype(np.uint8)


def fill_cell(c, path, col, cx=None, cy=None, r=None, lift=0.22):
    c.new_path()
    path(c)
    if cx is None:
        x0, y0, x1, y1 = c.fill_extents()
        cx, cy, r = (x0 + x1) / 2, (y0 + y1) / 2, max(4, max(x1 - x0, y1 - y0) * 0.6)
    g = cairo.RadialGradient(cx, cy, 0, cx, cy, r)
    hi = tuple(min(1, v + lift * (1 - v) + 0.04) for v in col)
    lo = tuple(v * 0.72 for v in col)
    g.add_color_stop_rgba(0, *hi, 1)
    g.add_color_stop_rgba(1, *lo, 1)
    c.set_source(g)
    c.fill()


def save_rgba(arr, path):
    Image.fromarray(arr, "RGBA").save(path)


def glow_of(arr, radius, path, boost=1.0):
    rgb = np.asarray(Image.fromarray(arr, "RGBA"), np.float32)
    prem = rgb.copy()
    prem[..., :3] *= prem[..., 3:4] / 255
    pim = Image.fromarray(np.clip(prem, 0, 255).astype(np.uint8), "RGBA").filter(ImageFilter.GaussianBlur(radius))
    p = np.asarray(pim, np.float32)
    o = np.zeros_like(p)
    a = np.maximum(p[..., 3:4], 1)
    o[..., :3] = np.clip(p[..., :3] * 255 / a, 0, 255)
    o[..., 3] = np.clip(p[..., 3] * boost, 0, 255)
    Image.fromarray(o.astype(np.uint8), "RGBA").save(path)


def lead(w, h, strokes, radius=None, extra=None):
    s, c = canvas(w, h)
    c.set_source_rgba(1, 1, 1, 1)
    c.set_line_join(cairo.LINE_JOIN_ROUND)
    c.set_line_cap(cairo.LINE_CAP_ROUND)
    for path, lw in strokes:
        c.new_path()
        path(c)
        c.set_line_width(lw)
        c.stroke()
    m = alpha(s)
    hmap = bevel(m, radius or 2.4)
    if extra is not None:
        for em, amp, rad in extra:
            hmap = np.maximum(hmap, bevel(em, rad) * amp)
            m = np.maximum(m, em)
    return hmap, m


def mask(w, h, draw):
    s, c = canvas(w, h)
    c.set_source_rgba(1, 1, 1, 1)
    draw(c)
    return alpha(s)


def circle(cx, cy, r):
    return lambda c: c.arc(cx, cy, r, 0, TAU)


def star6(c, cx, cy, R, side=0.6, inner=0.16, rot=-math.pi / 2):
    tips = []
    for i in range(6):
        a = rot + i * TAU / 6
        rr = R if i % 3 == 0 else R * side
        tips.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
    c.move_to(*tips[0])
    for i in range(6):
        t0 = tips[i]
        t1 = tips[(i + 1) % 6]
        am = rot + (i + 0.5) * TAU / 6
        ix, iy = cx + R * inner * math.cos(am), cy + R * inner * math.sin(am)
        c.curve_to(t0[0] * 0.35 + ix * 0.65, t0[1] * 0.35 + iy * 0.65, t1[0] * 0.35 + ix * 0.65, t1[1] * 0.35 + iy * 0.65, *t1)
    c.close_path()


def star4(c, cx, cy, R, inner=0.18, rot=-math.pi / 2, stretch=1.0):
    tips = []
    for i in range(4):
        a = rot + i * TAU / 4
        rr = R * (stretch if i % 2 == 0 else 1.0)
        tips.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
    c.move_to(*tips[0])
    for i in range(4):
        t0, t1 = tips[i], tips[(i + 1) % 4]
        am = rot + (i + 0.5) * TAU / 4
        ix, iy = cx + R * inner * math.cos(am), cy + R * inner * math.sin(am)
        c.curve_to(t0[0] * 0.3 + ix * 0.7, t0[1] * 0.3 + iy * 0.7, t1[0] * 0.3 + ix * 0.7, t1[1] * 0.3 + iy * 0.7, *t1)
    c.close_path()


def vesica(c, cx, cy, ang, r0, r1, half):
    ux, uy = math.cos(ang), math.sin(ang)
    vx, vy = -uy, ux
    ax, ay = cx + ux * r0, cy + uy * r0
    bx, by = cx + ux * r1, cy + uy * r1
    mx, my = (ax + bx) / 2, (ay + by) / 2
    k = 1.33
    c.move_to(ax, ay)
    c.curve_to(ax + vx * half * k * 0.55 + ux * (r1 - r0) * 0.12, ay + vy * half * k * 0.55 + uy * (r1 - r0) * 0.12,
               mx + vx * half * k + ux * (r1 - r0) * 0.28, my + vy * half * k + uy * (r1 - r0) * 0.28, bx, by)
    c.curve_to(mx - vx * half * k + ux * (r1 - r0) * 0.28, my - vy * half * k + uy * (r1 - r0) * 0.28,
               ax - vx * half * k * 0.55 + ux * (r1 - r0) * 0.12, ay - vy * half * k * 0.55 + uy * (r1 - r0) * 0.12, ax, ay)
    c.close_path()


def crescent(c, cx, cy, R, off=0.42, rot=-0.55):
    ox, oy = cx + R * off * math.cos(rot), cy + R * off * math.sin(rot)
    c.arc(cx, cy, R, 0, TAU)
    c.new_sub_path()
    c.arc_negative(ox, oy, R * 0.86, TAU, 0)


def lancet(c, cx, cy, ang, r0, r1, half):
    ux, uy = math.cos(ang), math.sin(ang)
    vx, vy = -uy, ux

    def P(r, s_):
        return cx + ux * r + vx * s_, cy + uy * r + vy * s_
    a = P(r0, 0)
    bl, br = P(r0 + (r1 - r0) * 0.18, -half * 0.55), P(r0 + (r1 - r0) * 0.18, half * 0.55)
    ml, mr = P(r0 + (r1 - r0) * 0.62, -half), P(r0 + (r1 - r0) * 0.62, half)
    tip = P(r1, 0)
    c.move_to(*a)
    c.line_to(*br)
    c.line_to(*mr)
    c.curve_to(*P(r0 + (r1 - r0) * 0.85, half * 0.9), *P(r1 - 3, half * 0.3), *tip)
    c.curve_to(*P(r1 - 3, -half * 0.3), *P(r0 + (r1 - r0) * 0.85, -half * 0.9), *ml)
    c.line_to(*bl)
    c.close_path()


def leaf(c, x0, y0, ang, length, half, curl=0.18):
    ux, uy = math.cos(ang), math.sin(ang)
    vx, vy = -uy, ux
    tip = (x0 + ux * length + vx * length * curl, y0 + uy * length + vy * length * curl)
    c.move_to(x0, y0)
    c.curve_to(x0 + ux * length * 0.3 + vx * half * 1.4, y0 + uy * length * 0.3 + vy * half * 1.4,
               x0 + ux * length * 0.75 + vx * half * 1.2 + vx * length * curl * 0.5, y0 + uy * length * 0.75 + vy * half * 1.2 + vy * length * curl * 0.5, *tip)
    c.curve_to(x0 + ux * length * 0.7 - vx * half * 0.6 + vx * length * curl * 0.5, y0 + uy * length * 0.7 - vy * half * 0.6 + vy * length * curl * 0.5,
               x0 + ux * length * 0.25 - vx * half * 0.9, y0 + uy * length * 0.25 - vy * half * 0.9, x0, y0)
    c.close_path()


def rounded(c, x0, y0, x1, y1, rad):
    c.new_sub_path()
    c.arc(x1 - rad, y0 + rad, rad, -math.pi / 2, 0)
    c.arc(x1 - rad, y1 - rad, rad, 0, math.pi / 2)
    c.arc(x0 + rad, y1 - rad, rad, math.pi / 2, math.pi)
    c.arc(x0 + rad, y0 + rad, rad, math.pi, 3 * math.pi / 2)
    c.close_path()


def pane(world, name, w, h, rad, col, border=5):
    o = out(world)

    def shape(c):
        rounded(c, border / 2 + 1, border / 2 + 1, w - border / 2 - 1, h - border / 2 - 1, rad)
    s, c = canvas(w, h)
    c.new_path()
    shape(c)
    g = cairo.LinearGradient(0, 0, 0, h)
    hi = tuple(min(1, v * 1.18 + 0.05) for v in col)
    g.add_color_stop_rgba(0, *hi, 1)
    g.add_color_stop_rgba(1, *[v * 0.8 for v in col], 1)
    c.set_source(g)
    c.fill()
    save_rgba(straight_rgba(s), f"{o}/{name}.png")
    h2, m = lead(w, h, [(shape, border)], radius=border / 2 + 0.3)
    save_height(h2, m, f"{o}/{name}-lead.png")


def medallion(world, name="medal", S=60, cols=None):
    P = PAL[world]
    C = S / 2
    o = out(world)
    cols = cols or [P["deep"], P["violet"]]
    R = S / 2 - 5
    s, c = canvas(S, S)
    for k in range(8):
        a0 = -math.pi / 2 + k * TAU / 8
        fill_cell(c, lambda c, a0=a0: (c.move_to(C, C), c.arc(C, C, R, a0, a0 + TAU / 8), c.close_path()), cols[k % 2], C, C, R, 0.25)
    fill_cell(c, circle(C, C, R * 0.52), P["ink"], C, C, R * 0.5, 0.3)
    arr = straight_rgba(s)
    save_rgba(arr, f"{o}/{name}.png")
    glow_of(arr, 6, f"{o}/{name}-glow.png", 1.3)
    strokes = [(circle(C, C, R * 0.52), 2.2)]
    for k in range(8):
        a0 = -math.pi / 2 + k * TAU / 8
        strokes.append((lambda c, a0=a0: (c.move_to(C + R * 0.52 * math.cos(a0), C + R * 0.52 * math.sin(a0)), c.line_to(C + R * math.cos(a0), C + R * math.sin(a0))), 1.6))
    ring = mask(S, S, lambda c: (c.set_fill_rule(cairo.FILL_RULE_EVEN_ODD), c.arc(C, C, S / 2 - 1, 0, TAU), c.new_sub_path(), c.arc(C, C, R, 0, TAU), c.fill()))
    h, m = lead(S, S, strokes, radius=1.4, extra=[(ring, 0.95, 2.6)])
    save_height(h, m, f"{o}/{name}-lead.png")
    gr = mask(S, S, lambda c: (c.set_line_width(2.0), c.arc(C, C, S / 2 - 1.6, 0, TAU), c.stroke()))
    save_height(bevel(gr, 1.0), gr, f"{o}/{name}-gilt.png")
