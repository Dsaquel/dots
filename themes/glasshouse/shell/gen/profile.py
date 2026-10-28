import json
import math

import cairo
import numpy as np
from PIL import Image

from kit import A, TAU, WORLDS, out, canvas, fill_cell, straight_rgba, save_rgba, lead, mask, circle, bevel, save_height
from orn import edt_inside
from lancet.layout import PAL, HEX
from lancet.shapes import s, outline, closed_outline, rrect, quatrefoil, lozenge, blur


def layout():
    W, H = 380, 714
    inner = 9.6
    px0, px1 = 22, W - 22
    L = dict(kind="page", W=W, H=H, inner=inner, gap=6,
             portrait=dict(x=px0, y=0, w=px1 - px0, bottom=512),
             titulus=dict(x=px0 + 8, y=520, w=px1 - px0 - 16, h=54),
             mood=dict(x=px0, y=596, w=px1 - px0, h=86, ring=dict(cx=px0 + 48, cy=639, r=36)),
             sill=dict(y=690, h=12),
             seps=[588])
    L["spring"] = round(W * math.sqrt(3) / 2, 2)
    p = L["portrait"]
    p["y"] = math.floor(L["spring"] - p["w"] * math.sqrt(3) / 2)
    return L


def arch(c, x, w, spring, bottom):
    x0, x1 = s(x), s(x + w)
    R = x1 - x0
    sp, bot = s(spring), s(bottom)
    xm = (x0 + x1) / 2
    h = math.sqrt(max(R * R - (xm - x0) ** 2, 0))
    c.move_to(x0, bot)
    c.line_to(x0, sp)
    c.arc(x1, sp, R, math.pi, math.atan2(-h, xm - x1))
    c.arc(x0, sp, R, math.atan2(-h, xm - x0), 0)
    c.line_to(x1, bot)
    c.close_path()


def page(world, L):
    P = PAL[world]
    o = out(world)
    W, H = L["W"], L["H"]
    Wp, Hp = s(W), s(H)
    rng = np.random.default_rng(23 if world == "dark" else 29)
    pt, ti, md = L["portrait"], L["titulus"], L["mood"]
    rg = md["ring"]
    sf, c = canvas(Wp, Hp)
    c.save()
    c.new_path()
    closed_outline(c, L, 1.2)
    c.clip()
    fill_cell(c, lambda c: c.rectangle(0, 0, Wp, Hp), HEX(P["band"]), Wp / 2, s(120), s(800), 0.18)
    c.restore()
    c.save()
    c.new_path()
    closed_outline(c, L, L["inner"])
    c.clip()
    qw, qh = 20, 30
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
    fill_cell(c, lambda c: arch(c, pt["x"], pt["w"], L["spring"], pt["bottom"]), HEX(P["niche"]), s(pt["x"] + pt["w"] / 2), s(260), s(300), 0.1)
    fill_cell(c, lambda c: rrect(c, ti["x"], ti["y"], ti["w"], ti["h"], 7), HEX(P["band"]), s(ti["x"] + ti["w"] / 2), s(ti["y"] + 18), s(200), 0.14)
    fill_cell(c, lambda c: rrect(c, md["x"], md["y"], md["w"], md["h"], 9), HEX(P["panel"]), s(md["x"] + md["w"] * 0.6), s(md["y"] + 30), s(220), 0.1)
    fill_cell(c, lambda c: c.arc(s(rg["cx"]), s(rg["cy"]), s(rg["r"] + 4), 0, TAU), HEX(P["niche"]), lift=0.1)
    for k in range(12):
        a0 = -math.pi / 2 + k * TAU / 12
        fill_cell(c, lambda c, a0=a0: (c.arc(s(rg["cx"]), s(rg["cy"]), s(rg["r"]), a0, a0 + TAU / 12),
                                       c.arc_negative(s(rg["cx"]), s(rg["cy"]), s(rg["r"] - 7), a0 + TAU / 12, a0), c.close_path()),
                  tuple(v * 0.78 for v in HEX(P["seg"][k % 4])), s(rg["cx"]), s(rg["cy"]), s(rg["r"]), 0.3)
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
    save_rgba(straight_rgba(sf), f"{o}/profile-page.png")

    inner = L["inner"]
    strokes_frame = [(lambda c: outline(c, L, 1.5), s(3.0)), (lambda c: outline(c, L, inner), s(1.6))]
    strokes_inner = [(lambda c: arch(c, pt["x"], pt["w"], L["spring"], pt["bottom"]), s(2.6)),
                     (lambda c: rrect(c, ti["x"], ti["y"], ti["w"], ti["h"], 7), s(1.9)),
                     (lambda c: rrect(c, md["x"], md["y"], md["w"], md["h"], 9), s(1.7)),
                     (circle(s(rg["cx"]), s(rg["cy"]), s(rg["r"] + 1.2)), s(2.6)),
                     (circle(s(rg["cx"]), s(rg["cy"]), s(rg["r"] - 7)), s(1.8))]
    strokes_inner += [(lambda c, a0=-math.pi / 2 + k * TAU / 12: (c.move_to(s(rg["cx"]) + s(rg["r"] - 7) * math.cos(a0), s(rg["cy"]) + s(rg["r"] - 7) * math.sin(a0)),
                                                                   c.line_to(s(rg["cx"]) + s(rg["r"]) * math.cos(a0), s(rg["cy"]) + s(rg["r"]) * math.sin(a0))), s(1.1)) for k in range(12)]
    hf, mf = lead(Wp, Hp, strokes_frame, radius=s(1.3))
    hi_, mi_ = lead(Wp, Hp, strokes_inner, radius=s(0.95))
    hi_ = blur(hi_, 1.3)
    seps = L["seps"]
    sepm = mask(Wp, Hp, lambda c: [c.rectangle(s(inner + 1), s(y) - s(1.1), s(W - 2 * inner - 2), s(2.2)) for y in seps] + [c.fill()])
    jewelm = mask(Wp, Hp, lambda c: [(quatrefoil(c, W / 2, y, 5.2), c.fill()) for y in seps])
    sill_m = mask(Wp, Hp, lambda c: (rrect(c, 0, sl["y"], W, sl["h"], 3), c.fill()))
    sill_line = mask(Wp, Hp, lambda c: (c.set_line_width(s(1.3)), rrect(c, 0.7, sl["y"] + 0.7, W - 1.4, sl["h"] - 1.4, 2.6), c.stroke()))
    if world == "dark":
        h = np.maximum.reduce([hf, hi_, bevel(sepm, s(0.9)), bevel(jewelm, s(1.6))])
        m = np.maximum.reduce([mf, mi_, sepm, jewelm])
        save_height(h, m, f"{o}/profile-page-lead.png")
        save_height(np.maximum(bevel(sill_line, s(0.7)), bevel(sill_m, s(3.0)) * 0.5), sill_line, f"{o}/profile-page-gilt.png")
    else:
        save_height(hi_ * 0.9, mi_, f"{o}/profile-page-lead.png")
        hg = np.maximum.reduce([hf, bevel(sepm, s(0.9)), bevel(jewelm, s(1.6)), bevel(sill_line, s(0.7))])
        mg = np.maximum.reduce([mf, sepm, jewelm, sill_line])
        save_height(hg, mg, f"{o}/profile-page-gilt.png")
    pearls = [[inner / 2 - 0.3, L["spring"]], [W - inner / 2 + 0.3, L["spring"]]]
    pearls += [p for y in seps for p in ([inner + 2.4, y], [W - inner - 2.4, y])]
    pearls += [[5, sl["y"] + 5], [W - 5, sl["y"] + 5]]
    L["pearls"] = [[round(x, 1), round(y, 1)] for x, y in pearls]


def portrait_mask(L):
    pt = L["portrait"]
    w, h = pt["w"], pt["bottom"] - pt["y"]
    m = mask(s(w), s(h), lambda c: (c.translate(-s(pt["x"]), -s(pt["y"])), arch(c, pt["x"], pt["w"], L["spring"], pt["bottom"]), c.fill()))
    save_height(edt_inside(m, s(24)) / s(24), m, f"{A}/shared/profile-portrait-mask.png")


def shadow(L):
    pad = 30
    W, H = L["W"], L["H"]
    sf, c = canvas(s(W + 2 * pad), s(H + 2 * pad))
    c.translate(s(pad), s(pad))
    c.new_path()
    closed_outline(c, L, 0)
    c.set_source_rgba(0, 0, 0, 1)
    c.fill()
    a = blur(np.asarray(straight_rgba(sf)[..., 3], np.float32) / 255, s(9))
    out_ = np.zeros(a.shape + (4,), np.uint8)
    out_[..., :3] = (5, 5, 14)
    out_[..., 3] = np.clip(a * 0.6 * 255, 0, 255).astype(np.uint8)
    Image.fromarray(out_, "RGBA").resize((W + 2 * pad, H + 2 * pad), Image.LANCZOS).save(f"{A}/shared/profile-page-shadow.png")
    L["shadowPad"] = pad


def build():
    L = layout()
    for world in WORLDS:
        page(world, L)
    shadow(L)
    portrait_mask(L)
    json.dump(L, open(f"{A}/shared/profile.json", "w"), indent=1)
