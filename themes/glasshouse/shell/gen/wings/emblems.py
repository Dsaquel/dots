import math

import cairo
import numpy as np

from kit import PAL, TAU, bevel, canvas, fill_cell, glow_of, out, save_height, save_rgba, straight_rgba
from orn import alpha

from .draw import beads, eo, stroke
from .raster import K, area, lift, mix, soft


def medal(world):
    o = out(world)
    if world == "dark":
        rg, rr, rd, studs = 40.0, 31.8, 26.1, 4
        ring, disc = (0.32, 0.4, 0.8), (0.09, 0.11, 0.26)
    else:
        rg, rr, rd, studs = 30.5, 22.9, 22.9, 2
        ring, disc = (0.97, 0.78, 0.44), (0.1, 0.11, 0.33)
    pad = 6
    S = 2 * (rg + pad)
    C = S / 2
    W = int(round(S * K))
    s, c = canvas(W, W)
    c.scale(K, K)
    c.arc(C, C, rg, 0, TAU)
    c.set_source_rgba(0.6, 0.45, 0.2, 1)
    c.fill()
    if rr > rd:
        c.set_fill_rule(cairo.FILL_RULE_EVEN_ODD)
        c.arc(C, C, rr, 0, TAU)
        c.new_sub_path()
        c.arc(C, C, rd, 0, TAU)
        g = cairo.RadialGradient(C - rr * 0.3, C - rr * 0.4, 0, C, C, rr * 1.2)
        g.add_color_stop_rgba(0, *lift(ring, 0.4), 1)
        g.add_color_stop_rgba(1, *[v * 0.6 for v in ring], 1)
        c.set_source(g)
        c.fill()
        c.set_fill_rule(cairo.FILL_RULE_WINDING)
    c.arc(C, C, rd, 0, TAU)
    g = cairo.RadialGradient(C - rd * 0.25, C - rd * 0.35, 0, C, C, rd * 1.1)
    g.add_color_stop_rgba(0, *lift(disc, 0.22), 1)
    g.add_color_stop_rgba(1, *[v * 0.7 for v in disc], 1)
    c.set_source(g)
    c.fill()
    arr = straight_rgba(s)
    save_rgba(arr, f"{o}/sanctum-medal.png")
    glow_of(arr, 4 * K, f"{o}/sanctum-medal-glow.png", 1.2)
    box = (0, 0, S, S)
    gold = area(box, lambda c: eo(c, lambda c: c.arc(C, C, rg, 0, TAU), lambda c: (c.new_sub_path(), c.arc(C, C, rr, 0, TAU))))
    roll = area(box, lambda c: (c.arc(C, C, (rg + rr) / 2, 0, TAU), stroke(c, 1.2)))
    save_height(np.clip(bevel(gold, 2.6 * K, "smooth") - soft(roll, 1.0 * K) * 0.3, 0, 1), gold, f"{o}/sanctum-medal-gilt.png")
    rim = area(box, lambda c: ([(c.arc(C, C, r, 0, TAU), stroke(c, w)) for r, w in ((rr, 1.6), (rd, 1.8))]))
    rv = area(box, lambda c: beads(c, [(C + (rr + rd) / 2 * math.cos(a), C + (rr + rd) / 2 * math.sin(a)) if rr > rd else (C + (rg + rr) / 2 * math.cos(a), C + (rg + rr) / 2 * math.sin(a))
                                       for a in np.linspace(-math.pi / 2, 1.5 * math.pi, studs + 1)[:-1]], 1.9))
    m = np.maximum(rim, rv)
    save_height(np.maximum(bevel(rim, 0.9 * K), bevel(rv, 1.2 * K)), m, f"{o}/sanctum-medal-lead.png")


def week(world):
    o = out(world)
    P = PAL[world]
    S = 160
    C = S / 2
    R0, R1 = 31, 76
    cols = [P["deep"], mix(P["deep"], P["violet"], 0.45)] if world == "dark" else [P["deep"], mix(P["deep"], P["violet"], 0.5)]
    sector = lambda c, k, r0=R0, r1=R1: (c.arc(C, C, r1, -math.pi / 2 + (k - 0.5) * TAU / 7, -math.pi / 2 + (k + 0.5) * TAU / 7), c.arc_negative(C, C, r0, -math.pi / 2 + (k + 0.5) * TAU / 7, -math.pi / 2 + (k - 0.5) * TAU / 7), c.close_path())
    s, c = canvas(S * K, S * K)
    c.scale(K, K)
    for k in range(7):
        a = -math.pi / 2 + k * TAU / 7
        fill_cell(c, lambda c, k=k: sector(c, k), cols[k % 2], C + 54 * math.cos(a), C + 54 * math.sin(a), 40, 0.22)
    fill_cell(c, lambda c: c.arc(C, C, R0, 0, TAU), P["ink"], C, C - 8, 34, 0.25)
    save_rgba(straight_rgba(s), f"{o}/sanctum-week.png")
    lit = P["amber"] if world == "dark" else P["gold"]
    s, c = canvas(S * K, S * K)
    c.scale(K, K)
    fill_cell(c, lambda c: sector(c, 0), lit, C, C - 54, 40, 0.4)
    arr = straight_rgba(s)
    save_rgba(arr, f"{o}/sanctum-week-lit.png")
    glow_of(arr, 6 * K, f"{o}/sanctum-week-lit-glow.png", 1.6)
    s, c = canvas(S * K, S * K)
    c.scale(K, K)
    c.set_source_rgba(1, 1, 1, 1)
    for r, w in ((R0, 2.6), (R1, 3.2)):
        c.arc(C, C, r, 0, TAU)
        stroke(c, w)
    for k in range(7):
        a = -math.pi / 2 + (k + 0.5) * TAU / 7
        c.move_to(C + R0 * math.cos(a), C + R0 * math.sin(a))
        c.line_to(C + R1 * math.cos(a), C + R1 * math.sin(a))
        stroke(c, 2.2)
    m = alpha(s)
    save_height(bevel(m, 1.2 * K), m, f"{o}/sanctum-week-lead.png")
