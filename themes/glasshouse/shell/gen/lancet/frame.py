import math

import cairo
import numpy as np

from kit import TAU, bevel, canvas, circle, fill_cell, lead, mask, out, save_height, save_rgba, straight_rgba

from .layout import HEX, PAL
from .shapes import arch, blur, closed_outline, latch_box, lozenge, niche_path, outline, quatrefoil, rrect, s


def frame(world, L, name):
    P = PAL[world]
    o = out(world)
    W, H = L["W"], L["H"]
    Wp, Hp = s(W), s(H)
    rng = np.random.default_rng((7 if world == "dark" else 11) + (0 if L["kind"] == "main" else 5))
    t, rd, rs = L["time"], L["roundel"], L["rose"]
    sf, c = canvas(Wp, Hp)
    c.save()
    c.new_path()
    closed_outline(c, L, 1.2)
    c.clip()
    fill_cell(c, lambda c: c.rectangle(0, 0, Wp, Hp), HEX(P["band"]), Wp / 2, s(80), s(700), 0.18)
    c.restore()
    c.save()
    c.new_path()
    closed_outline(c, L, 9.6 if L["kind"] == "main" else 8.4)
    c.clip()
    qw, qh = (20, 30) if L["kind"] == "main" else (17, 26)
    cells = [(i * qw + (qw / 2 if j % 2 else 0) + qw / 2, j * qh / 2) for j in range(-1, int(H / (qh / 2)) + 2) for i in range(-1, int(W / qw) + 2)]
    for cx, cy in cells:
        col = HEX(P["ground"][int(rng.integers(0, 4))])
        k = 1.0 + float(rng.normal(0, 0.035))
        g = cairo.LinearGradient(s(cx - qw / 2), s(cy - qh / 2), s(cx + qw / 2), s(cy + qh / 2))
        g.add_color_stop_rgb(0, *[min(1, v * k * 1.06) for v in col])
        g.add_color_stop_rgb(1, *[v * k * 0.94 for v in col])
        c.new_path()
        lozenge(c, cx, cy, qw / 2, qh / 2)
        c.set_source(g)
        c.fill()
    c.set_line_width(s(1.25))
    c.set_line_join(cairo.LINE_JOIN_MITER)
    for cx, cy in cells:
        c.new_path()
        lozenge(c, cx, cy, qw / 2, qh / 2)
        c.set_source_rgba(*P["lattice"], 0.92)
        c.stroke()
    fill_cell(c, lambda c: c.arc(s(rs["cx"]), s(rs["cy"]), s(rs["r"] + 3), 0, TAU), HEX(P["arch"]), lift=0.12)
    fill_cell(c, lambda c: rrect(c, t["x"], t["y"], t["w"], t["h"], 8), HEX(P["panel"]), s(t["x"] + t["w"] / 2), s(t["y"] + 20), s(70), 0.10)
    boxes = L["niches"] + ([L["vials"]] if L["vials"] else [])
    for n in boxes:
        fill_cell(c, lambda c, n=n: niche_path(c, n), HEX(P["niche"]), s(n["x"] + n["w"] / 2), s(n["y"] + n["h"] * 0.55), s(62), 0.16)
    if L.get("latch"):
        lt = L["latch"]
        fill_cell(c, lambda c: arch(c, *latch_box(L)), HEX(P["niche"]), s(lt["cx"]), s(lt["cy"]), s(lt["h"] * 0.55), 0.16)
    if rd:
        fill_cell(c, lambda c: c.arc(s(rd["cx"]), s(rd["cy"]), s(rd["r"] + 4), 0, TAU), HEX(P["niche"]), lift=0.1)
        for k in range(12):
            a0 = -math.pi / 2 + k * TAU / 12
            col = HEX(P["seg"][k % 4])
            fill_cell(c, lambda c, a0=a0: (c.arc(s(rd["cx"]), s(rd["cy"]), s(rd["r"]), a0, a0 + TAU / 12),
                                           c.arc_negative(s(rd["cx"]), s(rd["cy"]), s(rd["r"] - 7), a0 + TAU / 12, a0), c.close_path()),
                      tuple(v * 0.78 for v in col), s(rd["cx"]), s(rd["cy"]), s(rd["r"]), 0.3)
    c.restore()
    sl = L["sill"]
    g = cairo.LinearGradient(0, s(sl["y"]), 0, s(sl["y"] + sl["h"]))
    base = HEX(P["sill"])
    g.add_color_stop_rgb(0, *[min(1, v * 1.5 + 0.05) for v in base])
    g.add_color_stop_rgb(0.35, *base)
    g.add_color_stop_rgb(1, *[v * 0.55 for v in base])
    c.new_path()
    rrect(c, 0, sl["y"], W, sl["h"], 3)
    c.set_source(g)
    c.fill()
    save_rgba(straight_rgba(sf), f"{o}/{name}.png")

    inner = 9.6 if L["kind"] == "main" else 8.4
    strokes_frame = [(lambda c: outline(c, L, 1.5), s(3.0)), (lambda c: outline(c, L, inner), s(1.6))]
    strokes_inner = [(lambda c, n=n: niche_path(c, n), s(1.9)) for n in boxes]
    strokes_inner.append((lambda c: rrect(c, t["x"], t["y"], t["w"], t["h"], 8), s(1.7)))
    if L.get("latch"):
        strokes_inner.append((lambda c: arch(c, *latch_box(L)), s(1.9)))
    if rd:
        strokes_inner.append((circle(s(rd["cx"]), s(rd["cy"]), s(rd["r"] + 1.2)), s(2.6)))
        strokes_inner.append((circle(s(rd["cx"]), s(rd["cy"]), s(rd["r"] - 7)), s(1.8)))
        for k in range(12):
            a0 = -math.pi / 2 + k * TAU / 12
            strokes_inner.append((lambda c, a0=a0: (c.move_to(s(rd["cx"]) + s(rd["r"] - 7) * math.cos(a0), s(rd["cy"]) + s(rd["r"] - 7) * math.sin(a0)),
                                                    c.line_to(s(rd["cx"]) + s(rd["r"]) * math.cos(a0), s(rd["cy"]) + s(rd["r"]) * math.sin(a0))), s(1.1)))
    hf, mf = lead(Wp, Hp, strokes_frame, radius=s(1.3))
    hi_, mi_ = lead(Wp, Hp, strokes_inner, radius=s(0.95))
    hi_ = blur(hi_, 1.3)
    seps = L["seps"]
    sepm = mask(Wp, Hp, lambda c: [c.rectangle(s(inner + 1), s(y) - s(1.1), s(W - 2 * inner - 2), s(2.2)) for y in seps] + [c.fill()])
    jewelm = mask(Wp, Hp, lambda c: [(quatrefoil(c, W / 2, y, 5.2), c.fill()) for y in seps])
    shelf = mask(Wp, Hp, lambda c: [c.rectangle(s(n["x"] - 1), s(n["y"] + n["h"] - 1.6), s(n["w"] + 2), s(3.2)) for n in boxes] + [c.fill()])
    sill_m = mask(Wp, Hp, lambda c: (rrect(c, 0, sl["y"], W, sl["h"], 3), c.fill()))
    sill_line = mask(Wp, Hp, lambda c: (c.set_line_width(s(1.3)), rrect(c, 0.7, sl["y"] + 0.7, W - 1.4, sl["h"] - 1.4, 2.6), c.stroke()))
    if world == "dark":
        h = np.maximum.reduce([hf, hi_, bevel(sepm, s(0.9)), bevel(jewelm, s(1.6)), bevel(shelf, s(1.0))])
        m = np.maximum.reduce([mf, mi_, sepm, jewelm, shelf])
        save_height(h, m, f"{o}/{name}-lead.png")
        save_height(np.maximum(bevel(sill_line, s(0.7)), bevel(sill_m, s(3.0)) * 0.5), sill_line, f"{o}/{name}-gilt.png")
    else:
        h = np.maximum.reduce([hi_ * 0.9, bevel(shelf, s(1.0))])
        m = np.maximum.reduce([mi_, shelf])
        save_height(h, m, f"{o}/{name}-lead.png")
        hg = np.maximum.reduce([hf, bevel(sepm, s(0.9)), bevel(jewelm, s(1.6)), bevel(sill_line, s(0.7))])
        mg = np.maximum.reduce([mf, sepm, jewelm, sill_line])
        save_height(hg, mg, f"{o}/{name}-gilt.png")
    pearls = [[inner / 2 - 0.3, L["spring"]], [W - inner / 2 + 0.3, L["spring"]]]
    pearls += [p for y in seps for p in ([inner + 2.4, y], [W - inner - 2.4, y])]
    pearls += [[5, sl["y"] + 5], [W - 5, sl["y"] + 5]]
    L["pearls"] = [[round(x, 1), round(y, 1)] for x, y in pearls]
