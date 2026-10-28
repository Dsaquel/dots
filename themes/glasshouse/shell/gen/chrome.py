import math

import cairo
import numpy as np

from kit import TAU, WORLDS, out, canvas, fill_cell, straight_rgba, save_rgba, glow_of, lead, mask, circle, \
    lancet, leaf, bevel, save_height

GLASS = {
    "dark": dict(petal=(0.20, 0.34, 0.80), petal2=(0.27, 0.29, 0.84), heart=(1.00, 0.72, 0.32), spandrel=(0.07, 0.09, 0.23),
                 leaf=(0.28, 0.56, 0.53), leaf2=(0.21, 0.44, 0.46), bud=(0.40, 0.34, 0.86),
                 sector=((0.19, 0.31, 0.76), (0.35, 0.25, 0.72)), core=((0.05, 0.06, 0.14), (0.13, 0.15, 0.32))),
    "light": dict(petal=(0.93, 0.35, 0.58), petal2=(0.84, 0.23, 0.52), heart=(1.00, 0.80, 0.30), spandrel=(0.12, 0.13, 0.43),
                leaf=(0.25, 0.74, 0.83), leaf2=(0.19, 0.58, 0.75), bud=(0.98, 0.56, 0.72),
                sector=((0.90, 0.34, 0.57), (0.21, 0.27, 0.80)), core=((0.07, 0.08, 0.30), (0.19, 0.21, 0.56))),
}

def chrome_corner(world):
    G = GLASS[world]
    S, C = 240, 72
    o = out(world)
    R_IN, LOBE_D, LOBE_R, HEART = 31.0, 14.5, 13.2, 7.4
    lobes = [-math.pi / 2 + math.pi / 4 + k * TAU / 5 for k in range(5)]

    def pane(k):
        a = lobes[k]
        def path(c, a=a):
            c.save()
            c.new_path()
            c.move_to(C, C)
            c.arc(C, C, R_IN + 4, a - math.pi / 5, a + math.pi / 5)
            c.close_path()
            c.clip()
            c.new_path()
            c.arc(C + LOBE_D * math.cos(a), C + LOBE_D * math.sin(a), LOBE_R, 0, TAU)
            c.restore()
        return path

    def lobe_fill(c, k, col):
        a = lobes[k]
        c.save()
        c.new_path()
        c.move_to(C, C)
        c.arc(C, C, R_IN + 4, a - math.pi / 5, a + math.pi / 5)
        c.close_path()
        c.clip()
        fill_cell(c, circle(C + LOBE_D * math.cos(a), C + LOBE_D * math.sin(a), LOBE_R), col,
                  C + (LOBE_D + 1) * math.cos(a), C + (LOBE_D + 1) * math.sin(a), LOBE_R + 3, 0.3)
        c.restore()

    leaves = [lambda c: leaf(c, C + 33, C + 0.5, 0.0, 86, 11.5, 0.03),
              lambda c: leaf(c, C + 0.5, C + 33, math.pi / 2, 86, 11.5, -0.03)]
    sprigs = [lambda c: leaf(c, C + 47, C - 4, -0.5, 40, 7.5, -0.2),
              lambda c: leaf(c, C - 4, C + 47, math.pi / 2 + 0.5, 40, 7.5, 0.2)]
    bud = lambda c: lancet(c, C, C, -3 * math.pi / 4, 34, 64, 10.5)
    s, c = canvas(S, S)
    for lf in leaves:
        fill_cell(c, lf, G["leaf"], lift=0.2)
    for lf in sprigs:
        fill_cell(c, lf, G["leaf2"], lift=0.16)
    fill_cell(c, bud, G["bud"], C - 40, C - 40, 22, 0.3)
    fill_cell(c, circle(C, C, R_IN + 0.5), G["spandrel"], C, C, R_IN, 0.18)
    for k in range(5):
        lobe_fill(c, k, G["petal"] if k % 2 == 0 else G["petal2"])
    fill_cell(c, circle(C, C, HEART), G["heart"], C - 1.5, C - 1.5, HEART + 1, 0.7)
    arr = straight_rgba(s)
    save_rgba(arr, f"{o}/chrome-corner.png")
    gs, gc = canvas(S, S)
    for k in range(5):
        lobe_fill(gc, k, G["petal"])
    fill_cell(gc, circle(C, C, 12), G["heart"], C, C, 12, 0.8)
    fill_cell(gc, bud, G["bud"], lift=0.4)
    for lf in leaves:
        fill_cell(gc, lf, tuple(v * 0.5 for v in G["leaf"]), lift=0.2)
    glow_of(straight_rgba(gs), 12, f"{o}/chrome-corner-glow.png", 1.8)

    sn, cs = math.sin(math.pi / 5), math.cos(math.pi / 5)
    t_cusp = LOBE_D * cs + math.sqrt(LOBE_R * LOBE_R - (LOBE_D * sn) ** 2)
    half = math.atan2(t_cusp * sn, t_cusp * cs - LOBE_D)

    def cusps(c):
        for a in lobes:
            for sgn in (-1, 1):
                b = a + sgn * math.pi / 5
                c.move_to(C + HEART * math.cos(b), C + HEART * math.sin(b))
                c.line_to(C + t_cusp * math.cos(b), C + t_cusp * math.sin(b))
                c.move_to(C + (t_cusp + 3) * math.cos(b), C + (t_cusp + 3) * math.sin(b))
                c.line_to(C + (R_IN - 1) * math.cos(b), C + (R_IN - 1) * math.sin(b))
    strokes = [(circle(C, C, HEART), 3.0), (bud, 3.2), (cusps, 2.6)]
    strokes += [(lf, 3.2) for lf in leaves]
    strokes += [(lf, 2.8) for lf in sprigs]
    def rib(x0, y0, ang, length, curl, reach=0.8):
        ux, uy = math.cos(ang), math.sin(ang)
        vx, vy = -uy, ux
        def path(c):
            c.move_to(x0 + ux * length * 0.08, y0 + uy * length * 0.08)
            c.curve_to(x0 + ux * length * 0.35 + vx * length * curl * 0.1, y0 + uy * length * 0.35 + vy * length * curl * 0.1,
                       x0 + ux * length * 0.6 + vx * length * curl * 0.3, y0 + uy * length * 0.6 + vy * length * curl * 0.3,
                       x0 + ux * length * reach + vx * length * curl * 0.55, y0 + uy * length * reach + vy * length * curl * 0.55)
        return path
    strokes += [(rib(C + 33, C + 0.5, 0.0, 86, 0.03), 1.5), (rib(C + 0.5, C + 33, math.pi / 2, 86, -0.03), 1.5),
                (rib(C + 47, C - 4, -0.5, 40, -0.2, 0.7), 1.2), (rib(C - 4, C + 47, math.pi / 2 + 0.5, 40, 0.2, 0.7), 1.2)]
    for a in lobes:
        cx, cy = C + LOBE_D * math.cos(a), C + LOBE_D * math.sin(a)
        strokes.append((lambda c, cx=cx, cy=cy, a=a: (c.arc(cx, cy, LOBE_R, a - half, a + half)), 2.8))
    strokes.append((lambda c: (c.move_to(C + 35, C + 0.5), c.curve_to(C + 62, C + 2.5, C + 92, C + 3, C + 116, C + 3.5)), 1.8))
    strokes.append((lambda c: (c.move_to(C + 0.5, C + 35), c.curve_to(C + 2.5, C + 62, C + 3, C + 92, C + 3.5, C + 116)), 1.8))
    strokes.append((lambda c: (c.move_to(C - 35 * 0.707, C - 35 * 0.707), c.line_to(C - 58 * 0.707, C - 58 * 0.707)), 1.8))
    ring = mask(S, S, lambda c: (c.set_fill_rule(cairo.FILL_RULE_EVEN_ODD), c.arc(C, C, R_IN + 4.6, 0, TAU), c.new_sub_path(), c.arc(C, C, R_IN - 0.4, 0, TAU), c.fill()))
    h, m = lead(S, S, strokes, radius=1.8, extra=[(ring, 0.95, 2.6)])
    save_height(h, m, f"{o}/chrome-corner-lead.png")
    g1 = mask(S, S, lambda c: (c.set_line_width(2.6), c.arc(C, C, R_IN + 7.4, 0, TAU), c.stroke()))
    beads = mask(S, S, lambda c: [(c.arc(C + (R_IN + 7.4) * math.cos(a), C + (R_IN + 7.4) * math.sin(a), 3.6, 0, TAU), c.fill()) for a in [math.pi / 4 + k * math.pi / 2 for k in range(4)]])
    gh = np.maximum(bevel(g1, 1.3), bevel(beads, 3.0))
    save_height(gh, np.maximum(g1, beads), f"{o}/chrome-corner-gilt.png")

def chrome_crest(world):
    G = GLASS[world]
    S = 104
    C = S / 2
    o = out(world)
    R0, R1 = 23.0, 41.5
    s, c = canvas(S, S)
    for k in range(8):
        a0 = -math.pi / 2 - TAU / 16 + k * TAU / 8
        col = G["sector"][k % 2]
        fill_cell(c, lambda c, a0=a0: (c.new_sub_path(), c.arc(C, C, R1 + 0.5, a0, a0 + TAU / 8), c.arc_negative(C, C, R0 - 0.5, a0 + TAU / 8, a0), c.close_path()),
                  col, C + 32 * math.cos(a0 + TAU / 16), C + 32 * math.sin(a0 + TAU / 16), 14, 0.3)
    g = cairo.RadialGradient(C - 5, C - 6, 1, C, C, R0 + 1)
    g.add_color_stop_rgba(0, *G["core"][1], 1)
    g.add_color_stop_rgba(1, *G["core"][0], 1)
    c.new_path()
    c.arc(C, C, R0 + 0.5, 0, TAU)
    c.set_source(g)
    c.fill()
    arr = straight_rgba(s)
    save_rgba(arr, f"{o}/chrome-crest.png")
    gs, gc = canvas(S, S)
    for k in range(8):
        a0 = -math.pi / 2 - TAU / 16 + k * TAU / 8
        fill_cell(gc, lambda c, a0=a0: (c.new_sub_path(), c.arc(C, C, R1, a0, a0 + TAU / 8), c.arc_negative(C, C, R0, a0 + TAU / 8, a0), c.close_path()), G["sector"][k % 2], lift=0.4)
    glow_of(straight_rgba(gs), 8, f"{o}/chrome-crest-glow.png", 1.6)
    strokes = [(circle(C, C, R0), 3.2)]
    for k in range(8):
        a0 = -math.pi / 2 - TAU / 16 + k * TAU / 8
        strokes.append((lambda c, a0=a0: (c.move_to(C + R0 * math.cos(a0), C + R0 * math.sin(a0)), c.line_to(C + R1 * math.cos(a0), C + R1 * math.sin(a0))), 2.7))
    ring = mask(S, S, lambda c: (c.set_fill_rule(cairo.FILL_RULE_EVEN_ODD), c.arc(C, C, 46.0, 0, TAU), c.new_sub_path(), c.arc(C, C, R1 - 0.8, 0, TAU), c.fill()))
    h, m = lead(S, S, strokes, radius=1.7, extra=[(ring, 0.95, 2.6)])
    save_height(h, m, f"{o}/chrome-crest-lead.png")
    g1 = mask(S, S, lambda c: (c.set_line_width(2.4), c.arc(C, C, 48.6, 0, TAU), c.stroke()))
    save_height(bevel(g1, 1.2), g1, f"{o}/chrome-crest-gilt.png")

def build():
    for w in WORLDS:
        chrome_corner(w)
        chrome_crest(w)
