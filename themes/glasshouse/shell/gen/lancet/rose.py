import math

import cairo
import numpy as np

from kit import TAU, bevel, canvas, circle, fill_cell, glow_of, lead, mask, out, save_height, save_rgba, star6, straight_rgba, \
    lancet as petal_shape

from .layout import ROSE
from .shapes import s


def rose(world, L, name):
    W = ROSE[world]
    o = out(world)
    R = L["rose"]["r"]
    hr = L["rose"]["heart"]
    k = R / 44
    SZ = s(2 * R + 8)
    C = SZ / 2
    angs = [-math.pi / 2 + i * TAU / 5 for i in range(5)]
    pin, pout, phalf = s(14 * k), s(R - 3), s(8.6 * k)
    sf, c = canvas(SZ, SZ)
    c.set_fill_rule(cairo.FILL_RULE_EVEN_ODD)
    fill_cell(c, lambda c: (c.arc(C, C, s(R - 2), 0, TAU), c.new_sub_path(), c.arc(C, C, s(hr), 0, TAU)), W["deep"], C, C, s(R), 0.12)
    c.set_fill_rule(cairo.FILL_RULE_WINDING)
    dots = []
    for a0 in angs:
        a = a0 + TAU / 10
        for j in (-1, 0, 1):
            aa = a + j * 0.12
            rr = s(R - 8 * k) if j == 0 else s(R - 10 * k)
            dots.append((C + rr * math.cos(aa), C + rr * math.sin(aa)))
    for x, y in dots:
        fill_cell(c, circle(x, y, s(2.5 * k)), tuple(v * 0.75 for v in W["dots"]), lift=0.12)
    fill_cell(c, circle(C, C, s(hr)), W["ink"], C, C, s(hr), 0.2)
    if world == "light":
        fill_cell(c, circle(C, C, s(hr - 1.5)), (0.98, 0.80, 0.42), C, C, s(hr - 1), 0.35)
        fill_cell(c, lambda c: star6(c, C, C, s(hr - 2.5), 0.58, 0.14), (0.99, 0.96, 0.88), C, C, s(hr - 3), 0.05)
    arr = straight_rgba(sf)
    save_rgba(arr, f"{o}/{name}-frame.png")
    glow_of(arr, s(3), f"{o}/{name}-frame-glow.png")
    yy, xx = np.mgrid[0:SZ, 0:SZ].astype(np.float32)
    rr = np.hypot(xx - C, yy - C)
    band = np.where(rr < s(22 * k), 0.82, np.where(rr < s(32 * k), 0.93, 1.04))
    for i, a in enumerate(angs):
        sf, c = canvas(SZ, SZ)
        fill_cell(c, lambda c: petal_shape(c, C, C, a, pin, pout, phalf), (0.92, 0.93, 0.97),
                  C + s(R * 0.72) * math.cos(a), C + s(R * 0.72) * math.sin(a), s(18 * k), 0.25)
        p = straight_rgba(sf).astype(np.float32)
        p[..., :3] = np.clip(p[..., :3] * band[..., None], 0, 255)
        p = p.astype(np.uint8)
        save_rgba(p, f"{o}/{name}-petal-{i + 1}.png")
        glow_of(p, s(4.5 * k), f"{o}/{name}-petal-{i + 1}-glow.png", 1.4)
    strokes = [(circle(C, C, s(hr)), s(1.7)), (circle(C, C, s(R - 2)), s(1.8))]
    for a in angs:
        strokes.append((lambda c, a=a: petal_shape(c, C, C, a, pin, pout, phalf), s(1.6)))
        ux, uy = math.cos(a), math.sin(a)
        vx, vy = -uy, ux
        for rc, wdt in ((s(22 * k), s(6.2 * k)), (s(32 * k), s(8.2 * k))):
            strokes.append((lambda c, rc=rc, wdt=wdt, ux=ux, uy=uy, vx=vx, vy=vy: (c.move_to(C + ux * rc - vx * wdt, C + uy * rc - vy * wdt),
                                                                                   c.line_to(C + ux * rc + vx * wdt, C + uy * rc + vy * wdt)), s(1.1)))
    for x, y in dots:
        strokes.append((circle(x, y, s(2.5 * k)), s(0.9)))
    if world == "light":
        strokes.append((lambda c: star6(c, C, C, s(hr - 2.5), 0.58, 0.14), s(1.0)))
    ring = mask(SZ, SZ, lambda c: (c.set_fill_rule(cairo.FILL_RULE_EVEN_ODD), c.arc(C, C, s(R + 3), 0, TAU), c.new_sub_path(), c.arc(C, C, s(R - 2), 0, TAU), c.fill()))
    rivets = mask(SZ, SZ, lambda c: [(c.arc(C + s(R + 0.5) * math.cos(a), C + s(R + 0.5) * math.sin(a), s(1.3), 0, TAU), c.fill())
                                     for a in [angs[0] + TAU / 10 + i * TAU / 5 for i in range(5)] + angs])
    h, m = lead(SZ, SZ, strokes, radius=s(0.9), extra=[(ring, 0.9, s(1.7)), (rivets, 1.0, s(1.1))])
    save_height(h, m, f"{o}/{name}-lead.png")
    g = mask(SZ, SZ, lambda c: (c.set_line_width(s(1.4)), c.arc(C, C, s(R + 3.4), 0, TAU), c.stroke()))
    save_height(bevel(g, s(0.7)), g, f"{o}/{name}-gilt.png")
