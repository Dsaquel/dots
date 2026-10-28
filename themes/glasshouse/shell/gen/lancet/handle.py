import math

import cairo
import numpy as np

from kit import TAU, bevel, canvas, circle, fill_cell, glow_of, lead, mask, out, save_height, save_rgba, straight_rgba

from .layout import HEX, PAL, ROSE
from .shapes import arch, lozenge, rrect, s


def handle(world, L, name):
    P = PAL[world]
    o = out(world)
    hd = L["handle"]
    w, h, pad = hd["w"], hd["h"], hd["pad"]
    W2, H2_ = s(w + 2 * pad), s(h + 2 * pad)
    x0, y0 = pad, pad
    cx = x0 + w / 2
    sill, band = 5, 2.6
    bot = y0 + h - sill
    sp = y0 + w * math.sqrt(3) / 2
    jy, jr = y0 + hd["jewel"]["cy"], hd["jewel"]["r"]
    pe = hd["pearl"]
    rng = np.random.default_rng(23 if world == "dark" else 29)
    sf, c = canvas(W2, H2_)
    fill_cell(c, lambda c: arch(c, x0, sp, w, bot), HEX(P["band"]), s(cx), s(y0 + 22), s(46), 0.2)
    ix, iw = x0 + band, w - 2 * band
    c.save()
    c.new_path()
    arch(c, ix, sp, iw, bot - 1)
    c.clip()
    qh = 13
    cells = [(cx + (iw / 2 if j % 2 else 0) * k, y0 + 4 + j * qh / 2) for j in range(0, int(h / (qh / 2)) + 2) for k in ((-1, 1) if j % 2 else (0,))]
    for qx, qy in cells:
        col = HEX(P["ground"][int(rng.integers(0, 4))])
        g = cairo.LinearGradient(s(qx - iw / 2), s(qy - qh / 2), s(qx + iw / 2), s(qy + qh / 2))
        g.add_color_stop_rgb(0, *[min(1, v * 1.08) for v in col])
        g.add_color_stop_rgb(1, *[v * 0.92 for v in col])
        c.new_path()
        lozenge(c, qx, qy, iw / 2, qh / 2)
        c.set_source(g)
        c.fill()
    c.restore()
    fill_cell(c, circle(s(cx), s(jy), s(jr + 1.2)), HEX(P["niche"]), lift=0.08)
    fill_cell(c, circle(s(cx), s(jy), s(jr)), ROSE[world]["deep"], s(cx), s(jy - 1), s(jr), 0.35)
    if pe:
        fill_cell(c, circle(s(cx), s(y0 + pe["cy"]), s(pe["r"] + 1)), ROSE[world]["ink"], lift=0.06)
    g = cairo.LinearGradient(0, s(bot), 0, s(bot + sill))
    base = HEX(P["sill"])
    g.add_color_stop_rgb(0, *[min(1, v * 1.5 + 0.05) for v in base])
    g.add_color_stop_rgb(0.4, *base)
    g.add_color_stop_rgb(1, *[v * 0.55 for v in base])
    c.new_path()
    rrect(c, x0 - 1, bot, w + 2, sill, 1.6)
    c.set_source(g)
    c.fill()
    arr = straight_rgba(sf)
    save_rgba(arr, f"{o}/{name}.png")
    glow_of(arr, s(3), f"{o}/{name}-glow.png", 1.2)
    inner = [(lambda c: arch(c, ix, sp, iw, bot - 1), s(0.9))]
    for qx, qy in cells:
        inner.append((lambda c, qx=qx, qy=qy: lozenge(c, qx, qy, iw / 2, qh / 2), s(0.55)))
    holes = [(cx, jy, jr + 1)] + ([(cx, y0 + pe["cy"], pe["r"] + 1)] if pe else [])
    clip = mask(W2, H2_, lambda c: (arch(c, ix, sp, iw, bot - 1), c.fill()))
    clip *= 1 - mask(W2, H2_, lambda c: [(c.arc(s(hx), s(hy), s(hr_), 0, TAU), c.fill()) for hx, hy, hr_ in holes])
    hl, ml = lead(W2, H2_, inner, radius=s(0.5))
    hl, ml = hl * clip, ml * clip
    rings = [(circle(s(cx), s(jy), s(jr + 0.6)), s(1.2))]
    if pe:
        rings.append((circle(s(cx), s(y0 + pe["cy"]), s(pe["r"] + 0.8)), s(1.1)))
    hr, mr = lead(W2, H2_, rings, radius=s(0.6))
    edge = mask(W2, H2_, lambda c: (c.set_line_width(s(0.8)), arch(c, ix, sp, iw, bot - 1), c.stroke()))
    h_lead = np.maximum.reduce([hl, hr, bevel(edge, s(0.4))])
    m_lead = np.maximum.reduce([ml, mr, edge])
    save_height(h_lead, m_lead, f"{o}/{name}-lead.png")
    hf, mf = lead(W2, H2_, [(lambda c: arch(c, x0 + 0.6, sp, w - 1.2, bot), s(1.5))], radius=s(0.75))
    sill_line = mask(W2, H2_, lambda c: (c.set_line_width(s(0.8)), rrect(c, x0 - 0.6, bot + 0.4, w + 1.2, sill - 0.8, 1.4), c.stroke()))
    save_height(np.maximum(hf, bevel(sill_line, s(0.5))), np.maximum(mf, sill_line), f"{o}/{name}-gilt.png")
