import math

import cairo
import numpy as np
from PIL import Image, ImageFilter

from kit import A, PAL, TAU, WORLDS, out, canvas, fill_cell, straight_rgba, save_rgba, glow_of, lead, mask, \
    circle, star4, star6, vesica, bevel, save_height, pane, rounded

CW, CH = 760, 1080
CX = 380
R = 220
SPRING = 416
TOP = SPRING - R
BOTTOM = 944
X0, X1 = CX - R, CX + R
SUN = (CX, 236)
BAND = (96, 954, 664, 980)
PRED = (226, 992, 534, 1052)
JEWELS = {
    "dark": [(0.21, 0.35, 0.72), (0.42, 0.31, 0.76), (0.62, 0.68, 0.84), (0.4, 0.62, 0.58), (0.62, 0.3, 0.46)],
    "light": [(0.86, 0.4, 0.56), (0.9, 0.68, 0.24), (0.3, 0.72, 0.84), (0.5, 0.36, 0.8), (0.42, 0.6, 0.94)],
}

def window(c, inset=0):
    c.move_to(X0 + inset, BOTTOM - inset)
    c.line_to(X0 + inset, SPRING)
    c.arc(CX, SPRING, R - inset, math.pi, TAU)
    c.line_to(X1 - inset, BOTTOM - inset)
    c.close_path()

def deep(col, k):
    return tuple(v * k for v in col)

def mix(a, b, k):
    return tuple(x + (y - x) * k for x, y in zip(a, b))

def arch(world):
    P = PAL[world]
    o = out(world)
    wm = mask(CW, CH, lambda c: (window(c, 6), c.fill()))
    Image.fromarray((wm * 255).astype(np.uint8), "L").save(f"{o}/sanctum-window.png")

    s, c = canvas(CW, CH)
    cols = [P["teal"], P["violet"], P["cyan"], P["rose"], P["violet"], P["teal"], P["cyan"]] if world == "dark" else \
        [P["rose"], P["gold"], P["cyan"], P["violet"], P["rose"], P["gold"], P["cyan"]]
    leaves = []
    for side in (-1, 1):
        px = CX + side * (R + 44)
        for i in range(7):
            yc = SPRING + 34 + i * 70
            lf = lambda c, px=px, yc=yc, side=side: vesica(c, px, yc + 27, -math.pi / 2 + side * 0.16, 0, 58, 12.5)
            fill_cell(c, lf, deep(cols[i], 0.92 if world == "light" else 0.86), px, yc, 30, 0.34)
            leaves.append(lf)
    band = lambda c: c.rectangle(BAND[0], BAND[1], BAND[2] - BAND[0], BAND[3] - BAND[1])
    fill_cell(c, band, P["deep"] if world == "light" else (0.15, 0.2, 0.42), CX, (BAND[1] + BAND[3]) / 2, 320, 0.22)
    jewels = []
    for k in range(9):
        x = CX + (k - 4) * 58
        d = lambda c, x=x: (c.move_to(x, BAND[1] + 3), c.line_to(x + 9, (BAND[1] + BAND[3]) / 2), c.line_to(x, BAND[3] - 3), c.line_to(x - 9, (BAND[1] + BAND[3]) / 2), c.close_path())
        fill_cell(c, d, (P["amber"] if world == "dark" else P["rose"]) if k % 2 == 0 else P["cyan"], x, BAND[1] + 9, 12, 0.4)
        jewels.append(d)
    side_glass = straight_rgba(s)
    save_rgba(side_glass, f"{o}/sanctum-arch-glass.png")
    glow_of(side_glass, 10, f"{o}/sanctum-arch-glass-glow.png", 1.25)

    def outline(c, inset=-18):
        c.move_to(X0 + inset, BAND[1] - 2)
        c.line_to(X0 + inset, SPRING)
        c.arc(CX, SPRING, R - inset, math.pi, TAU)
        c.line_to(X1 - inset, BAND[1] - 2)
    strokes = [(lambda c: window(c, 0), 11), (outline, 3.6)]
    strokes += [(lf, 3.0) for lf in leaves]
    for side in (-1, 1):
        px = CX + side * (R + 44)
        strokes.append((lambda c, px=px: (c.move_to(px, SPRING + 22), c.line_to(px, BAND[1] - 4)), 2.6))

        def whip(c, side=side):
            sx, sy = CX + side * (R + 76), BAND[1] + 4
            c.move_to(sx, sy)
            c.curve_to(sx + side * 54, sy - 6, sx + side * 34, sy - 118, sx + side * 84, sy - 166)
            c.curve_to(sx + side * 122, sy - 204, sx + side * 146, sy - 148, sx + side * 116, sy - 134)
            c.curve_to(sx + side * 94, sy - 126, sx + side * 100, sy - 154, sx + side * 113, sy - 151)
        strokes.append((whip, 4.6))

        def whip2(c, side=side):
            sx, sy = CX + side * (R + 26), BAND[3] - 2
            c.move_to(sx, sy)
            c.curve_to(sx + side * 118, sy + 8, sx + side * 168, sy - 34, sx + side * 196, sy - 92)
            c.curve_to(sx + side * 216, sy - 134, sx + side * 192, sy - 156, sx + side * 175, sy - 131)
        strokes.append((whip2, 3.6))
    strokes.append((band, 3.4))
    strokes += [(d, 1.8) for d in jewels]
    h, m = lead(CW, CH, strokes, radius=2.6)
    save_height(h, m, f"{o}/sanctum-arch-iron.png")

    ring = mask(CW, CH, lambda c: (c.set_fill_rule(cairo.FILL_RULE_EVEN_ODD), c.arc(CX, SPRING, R + 40, 0, TAU), c.new_sub_path(), c.arc(CX, SPRING, R + 33, 0, TAU), c.fill()))
    ring = ring * mask(CW, CH, lambda c: (c.rectangle(0, 0, CW, SPRING + 2), c.fill()))
    arc2 = mask(CW, CH, lambda c: (c.set_line_width(1.5), c.arc(CX, SPRING, R + 52, math.pi * 1.03, math.pi * 1.97), c.stroke()))
    n = 41 if world == "light" else 33
    angs = np.linspace(math.pi * 1.05, math.pi * 1.95, n)

    def rays(c):
        for k, a in enumerate(angs):
            long_ = k % 2 == 0
            r0 = R + 60
            r1 = R + (124 if long_ else 90) if world == "light" else R + (112 if long_ else 84)
            c.set_line_width(2.1 if long_ else 1.3)
            c.move_to(CX + r0 * math.cos(a), SPRING + r0 * math.sin(a))
            c.line_to(CX + r1 * math.cos(a), SPRING + r1 * math.sin(a))
            c.stroke()
    rm = mask(CW, CH, rays)
    if world == "dark":
        def stars(c):
            for k, a in enumerate(np.linspace(math.pi * 1.1, math.pi * 1.9, 9)):
                star4(c, CX + (R + 36.5) * math.cos(a), SPRING + (R + 36.5) * math.sin(a), 8.5 if k % 2 == 0 else 5.5, 0.2)
                c.fill()
            for k, a in enumerate(angs[:-1]):
                am = a + (angs[1] - angs[0]) / 2
                rr = R + 74 + (k * 37 % 23)
                c.arc(CX + rr * math.cos(am), SPRING + rr * math.sin(am), 1.6 if k % 3 else 2.3, 0, TAU)
                c.fill()
        sm = mask(CW, CH, stars)

        ends = [(CX + (R + 36.5) * math.cos(a), SPRING + (R + 36.5) * math.sin(a), a) for a in (math.pi * 1.04, math.pi * 1.96)]
        rr = 13.5
        disc = mask(CW, CH, lambda c: [(c.arc(mx, my, rr, 0, TAU), c.fill()) for mx, my, a in ends])
        bite = mask(CW, CH, lambda c: [(c.arc(mx + rr * 0.45 * math.cos(a + math.pi), my + rr * 0.45 * math.sin(a + math.pi), rr * 0.82, 0, TAU), c.fill()) for mx, my, a in ends])
        mm = np.clip(disc - bite, 0, 1)
        yy = np.mgrid[0:CH, 0:CW][0]
        ring = ring * np.clip((ends[0][1] - 18 - yy) / 2.0, 0, 1)
        hh = np.maximum.reduce([bevel(ring, 3.0), bevel(arc2, 1.0) * 0.7, bevel(rm, 0.9) * 0.8, bevel(sm, 1.6), bevel(mm, 3.2)])
        mm_all = np.maximum.reduce([ring, arc2, rm, sm, mm])
    else:
        def stars(c):
            for k, a in enumerate(np.linspace(math.pi * 1.1, math.pi * 1.9, 7)):
                star6(c, CX + (R + 36.5) * math.cos(a), SPRING + (R + 36.5) * math.sin(a), 13 if k % 3 == 0 else 9, 0.55, 0.13, a + math.pi / 2)
                c.fill()
        sm = mask(CW, CH, stars)

        def glints(c):
            for k, a in enumerate(angs):
                if k % 4 == 0:
                    rr = R + 132
                    star4(c, CX + rr * math.cos(a), SPRING + rr * math.sin(a), 7 if k % 8 == 0 else 5, 0.16)
                    c.fill()
        gm = mask(CW, CH, glints)
        hh = np.maximum.reduce([bevel(ring, 3.0), bevel(arc2, 1.0) * 0.7, bevel(rm, 0.9) * 0.85, bevel(sm, 2.2), bevel(gm, 1.4)])
        mm_all = np.maximum.reduce([ring, arc2, rm, sm, gm])
    save_height(hh, mm_all, f"{o}/sanctum-halo.png")
    tint = (0.72, 0.8, 1.0) if world == "dark" else (1.0, 0.8, 0.45)
    plate = np.zeros((CH, CW, 4), np.uint8)
    plate[..., :3] = (np.array(tint) * 255).astype(np.uint8)
    plate[..., 3] = (np.clip(mm_all, 0, 1) * 255).astype(np.uint8)
    glow_of(plate, 7, f"{o}/sanctum-halo-glow.png", 1.6)

def sunburst(world):
    P = PAL[world]
    o = out(world)
    ox, oy = SUN
    rings = [62, 124, 204, 300, 460, 980]
    if world == "dark":
        plan = [
            (P["moon"], P["moon"]),
            (mix(P["moon"], P["cyan"], 0.45), mix(P["moon"], P["violet"], 0.5)),
            ((0.21, 0.35, 0.72), (0.32, 0.27, 0.70)),
            ((0.17, 0.23, 0.52), (0.30, 0.24, 0.62)),
            ((0.12, 0.16, 0.38), (0.15, 0.17, 0.44)),
            ((0.09, 0.11, 0.28), (0.11, 0.12, 0.31)),
        ]
        accent = {3: (4, P["teal"]), 4: (6, deep(P["rose"], 0.8))}
    else:
        plan = [
            ((1.0, 0.95, 0.80), (1.0, 0.95, 0.80)),
            (P["gold"], (0.98, 0.66, 0.36)),
            (P["rose"], (0.66, 0.30, 0.74)),
            (P["cyan"], (0.48, 0.66, 0.98)),
            ((0.22, 0.26, 0.70), (0.42, 0.30, 0.76)),
            ((0.15, 0.17, 0.52), (0.19, 0.19, 0.58)),
        ]
        accent = {3: (4, P["gold"]), 4: (6, deep(P["rose"], 0.85))}
    s, c = canvas(CW, CH)
    c.save()
    c.new_path()
    window(c, 6)
    c.clip()
    for ri, r1 in enumerate(rings):
        r0 = 0 if ri == 0 else rings[ri - 1]
        nsec = 1 if ri == 0 else (12 if ri == 1 else 24)
        for k in range(nsec):
            if ri == 0:
                fill_cell(c, circle(ox, oy, r1), plan[0][0], ox, oy, r1, 0.35)
                continue
            a0 = -math.pi / 2 + k * TAU / nsec
            a1 = a0 + TAU / nsec
            col = plan[ri][k % 2]
            if ri in accent and k % accent[ri][0] == 1:
                col = accent[ri][1]
            mid = (a0 + a1) / 2
            rm = (r0 + r1) / 2
            path = lambda c, r0=r0, r1=r1, a0=a0, a1=a1: (c.arc(ox, oy, r1, a0, a1), c.arc_negative(ox, oy, r0, a1, a0), c.close_path())
            fill_cell(c, path, col, ox + rm * math.cos(mid), oy + rm * math.sin(mid), (r1 - r0) * 0.9, 0.3)
    c.restore()
    save_rgba(straight_rgba(s), f"{o}/sanctum-sun.png")
    strokes = [(circle(ox, oy, rr), 3.0 if i < 3 else 2.6) for i, rr in enumerate(rings[:-1])]
    for k in range(24):
        a = -math.pi / 2 + k * TAU / 24
        r0 = rings[0] if k % 2 == 0 else rings[1]
        strokes.append((lambda c, a=a, r0=r0: (c.move_to(ox + r0 * math.cos(a), oy + r0 * math.sin(a)), c.line_to(ox + 1100 * math.cos(a), oy + 1100 * math.sin(a))), 2.5))
    h, m = lead(CW, CH, strokes, radius=1.6)
    wm = mask(CW, CH, lambda c: (window(c, 6), c.fill()))
    save_height(h * wm, m * wm, f"{o}/sanctum-sun-lead.png")

def predella(world):
    o = out(world)
    W, H = 320, 64
    s, c = canvas(W, H)
    shape = lambda c, i=0: rounded(c, 4 + i, 4 + i, W - 4 - i, H - 4 - i, 22 - i)
    fill_cell(c, shape, (0.13, 0.16, 0.36) if world == "dark" else (0.17, 0.18, 0.52), W / 2, 10, 300, 0.18)
    save_rgba(straight_rgba(s), f"{o}/sanctum-predella.png")
    h, m = lead(W, H, [(shape, 5.0), (lambda c: shape(c, 9), 1.6)], radius=2.4)
    save_height(h, m, f"{o}/sanctum-predella-lead.png")

def alchemy_circle():
    S = 640
    C = S / 2
    o = f"{A}/shared"
    planets = ["☽", "☿", "♀", None, "♂", "♃", "♄"]
    alch = ["\U0001F701", "\U0001F702", "\U0001F703", "\U0001F704", "\U0001F70D"]
    band = planets + alch

    def outer(c):
        c.set_line_width(2.4)
        c.arc(C, C, 306, 0, TAU)
        c.stroke()
        c.set_line_width(1.1)
        c.arc(C, C, 297, 0, TAU)
        c.stroke()
        for k in range(72):
            a = k * TAU / 72
            r0 = 276 if k % 6 == 0 else (283 if k % 3 == 0 else 287)
            c.set_line_width(1.8 if k % 6 == 0 else 1.0)
            c.move_to(C + r0 * math.cos(a), C + r0 * math.sin(a))
            c.line_to(C + 295 * math.cos(a), C + 295 * math.sin(a))
            c.stroke()
        c.set_line_width(1.4)
        c.arc(C, C, 238, 0, TAU)
        c.stroke()
        c.set_line_width(0.9)
        c.arc(C, C, 231, 0, TAU)
        c.stroke()
        c.select_font_face("Noto Sans Symbols", cairo.FONT_SLANT_NORMAL, cairo.FONT_WEIGHT_NORMAL)
        c.set_font_size(25)
        for k, g in enumerate(band):
            a = -math.pi / 2 + k * TAU / 12
            gx, gy = C + 257 * math.cos(a), C + 257 * math.sin(a)
            c.save()
            c.translate(gx, gy)
            c.rotate(a + math.pi / 2)
            if g is None:
                c.set_line_width(1.8)
                c.arc(0, 0, 10, 0, TAU)
                c.stroke()
                c.arc(0, 0, 2.6, 0, TAU)
                c.fill()
            else:
                x0, y0, w, h, _, _ = c.text_extents(g)
                c.move_to(-x0 - w / 2, -y0 - h / 2)
                c.show_text(g)
            c.restore()
            b = a + TAU / 24
            c.arc(C + 257 * math.cos(b), C + 257 * math.sin(b), 2.0, 0, TAU)
            c.fill()

    def inner(c):
        c.set_line_join(cairo.LINE_JOIN_MITER)
        c.set_line_width(1.6)
        pts = [(C + 214 * math.cos(-math.pi / 2 + k * TAU / 7), C + 214 * math.sin(-math.pi / 2 + k * TAU / 7)) for k in range(7)]
        order = [(k * 3) % 7 for k in range(7)]
        c.move_to(*pts[order[0]])
        for k in order[1:]:
            c.line_to(*pts[k])
        c.close_path()
        c.stroke()
        c.set_line_width(1.2)
        c.arc(C, C, 214, 0, TAU)
        c.stroke()
        for p in pts:
            c.arc(p[0], p[1], 3.2, 0, TAU)
            c.fill()
        c.set_line_width(1.4)
        c.arc(C, C, 120, 0, TAU)
        c.stroke()
        for rot in (-math.pi / 2, math.pi / 2):
            tri = [(C + 120 * math.cos(rot + k * TAU / 3), C + 120 * math.sin(rot + k * TAU / 3)) for k in range(3)]
            c.move_to(*tri[0])
            c.line_to(*tri[1])
            c.line_to(*tri[2])
            c.close_path()
            c.stroke()
        c.set_line_width(1.0)
        c.arc(C, C, 58, 0, TAU)
        c.stroke()
        c.arc(C, C, 4, 0, TAU)
        c.fill()

    for name, fn in (("outer", outer), ("inner", inner)):
        s, c = canvas(S, S)
        c.set_source_rgba(1, 1, 1, 1)
        fn(c)
        a = np.asarray(straight_rgba(s))[..., 3]
        arr = np.zeros((S, S, 4), np.uint8)
        arr[..., :3] = 255
        arr[..., 3] = a
        Image.fromarray(arr, "RGBA").save(f"{o}/sanctum-circle-{name}.png")
        g = Image.fromarray(a).filter(ImageFilter.GaussianBlur(5))
        ga = np.clip(np.asarray(g, np.float32) * 2.4, 0, 255).astype(np.uint8)
        arr[..., 3] = ga
        Image.fromarray(arr, "RGBA").save(f"{o}/sanctum-circle-{name}-glow.png")

def icon_ring(world, name, S, ring, inner, pad=0, gilt=False):
    W = S + 2 * pad
    C = W / 2
    o = out(world)
    ro = S / 2 - 3
    ri = ro - max(4, S * 0.11)
    s, c = canvas(W, W)
    fill_cell(c, lambda c: (c.set_fill_rule(cairo.FILL_RULE_EVEN_ODD), c.arc(C, C, ro, 0, TAU), c.new_sub_path(), c.arc(C, C, ri, 0, TAU)), ring, C, C - ro * 0.5, ro * 1.4, 0.34)
    fill_cell(c, circle(C, C, ri), inner, C, C - ri * 0.3, ri * 1.2, 0.2)
    arr = straight_rgba(s)
    save_rgba(arr, f"{o}/{name}.png")
    glow_of(arr, max(3, S // 10), f"{o}/{name}-glow.png", 1.3)
    strokes = [(circle(C, C, ri), 1.8), (circle(C, C, ro), 2.4)]
    studs = mask(W, W, lambda c: [(c.arc(C + (ro + ri) / 2 * math.cos(a), C + (ro + ri) / 2 * math.sin(a), max(1.6, S * 0.035), 0, TAU), c.fill()) for a in (-math.pi / 2, 0, math.pi / 2, math.pi)])
    h, m = lead(W, W, strokes, radius=1.3, extra=[(studs, 1.0, 1.4)])
    save_height(h, m, f"{o}/{name}-lead.png")
    if gilt:
        rim = mask(W, W, lambda c: (c.set_line_width(2.2), c.arc(C, C, S / 2 - 1.4, 0, TAU), c.stroke()))
        save_height(bevel(rim, 1.0), rim, f"{o}/{name}-gilt.png")

def lozenge(world):
    P = PAL[world]
    S = 53
    k = S / 60
    C = S / 2
    o = out(world)
    d = lambda c, m=0: (c.move_to(C + m, 4 * k + m), c.line_to(S - 4 * k + m, C + m), c.line_to(C + m, S - 4 * k + m), c.line_to(4 * k + m, C + m), c.close_path())
    s, c = canvas(S, S)
    fill_cell(c, d, (0.16, 0.2, 0.42) if world == "dark" else (0.2, 0.22, 0.58), C, C - 8 * k, 32 * k, 0.3)
    save_rgba(straight_rgba(s), f"{o}/sanctum-loz.png")
    lit = P["amber"] if world == "dark" else (0.98, 0.62, 0.18)
    s, c = canvas(S, S)
    fill_cell(c, d, lit, C, C - 8 * k, 32 * k, 0.38 if world == "dark" else 0.3)
    save_rgba(straight_rgba(s), f"{o}/sanctum-loz-on.png")
    s, c = canvas(S + 30, S + 30)
    fill_cell(c, lambda c: d(c, 15), lit, C + 15, C + 15 - 8 * k, 32 * k, 0.38)
    glow_of(straight_rgba(s), 9 * k, f"{o}/sanctum-loz-on-glow.png", 1.4)
    inner = lambda c: (c.move_to(C, 11 * k), c.line_to(S - 11 * k, C), c.line_to(C, S - 11 * k), c.line_to(11 * k, C), c.close_path())
    h, m = lead(S, S, [(d, 4.2 * k), (inner, 1.1 * k)], radius=2.0 * k)
    save_height(h, m, f"{o}/sanctum-loz-lead.png")

def bead(world):
    S = 40
    k = S / 44
    C = S / 2
    o = out(world)
    s, c = canvas(S, S)
    g = cairo.RadialGradient(C - 5 * k, C - 7 * k, k, C, C, C - 3 * k)
    top = (0.42, 0.48, 0.78) if world == "dark" else (0.5, 0.52, 0.95)
    low = (0.08, 0.1, 0.24) if world == "dark" else (0.12, 0.12, 0.38)
    g.add_color_stop_rgba(0, *top, 1)
    g.add_color_stop_rgba(1, *low, 1)
    c.arc(C, C, C - 3 * k, 0, TAU)
    c.set_source(g)
    c.fill()
    save_rgba(straight_rgba(s), f"{o}/sanctum-bead.png")
    h, m = lead(S, S, [(circle(C, C, C - 3 * k), 3.0 * k)], radius=1.6 * k)
    save_height(h, m, f"{o}/sanctum-bead-lead.png")

def gauge(world):
    o = out(world)
    n, sw, gap, H, pad = 14, 22, 4, 16, 10
    W = n * sw + (n - 1) * gap
    ramp = [(0.46, 0.4, 0.86), (0.42, 0.56, 0.94), (0.86, 0.89, 0.98)] if world == "dark" else \
        [(0.32, 0.8, 0.9), (0.42, 0.68, 1.0), (0.8, 0.9, 1.0)]

    def col(t):
        k = min(1.0, t) * (len(ramp) - 1)
        i = min(int(k), len(ramp) - 2)
        return mix(ramp[i], ramp[i + 1], k - i)

    def cap(k, ox=0.0, oy=0.0):
        x0 = k * (sw + gap) + 1 + ox
        return lambda c: rounded(c, x0, 2 + oy, x0 + sw - 2, H - 2 + oy, 4)
    for name, ox, oy, w_, h_ in (("sanctum-gauge", 0, 0, W, H), ("glow", pad, pad, W + 2 * pad, H + 2 * pad)):
        s, c = canvas(w_, h_)
        for k in range(n):
            fill_cell(c, cap(k, ox, oy), col(k / (n - 1)), ox + k * (sw + gap) + sw / 2, oy + H / 2 - 2, sw * 0.7, 0.3)
        arr = straight_rgba(s)
        if name == "glow":
            glow_of(arr, 5, f"{o}/sanctum-gauge-glow.png", 1.5)
        else:
            save_rgba(arr, f"{o}/{name}.png")
    h, m = lead(W, H, [(cap(k), 1.8) for k in range(n)], radius=1.0)
    save_height(h, m, f"{o}/sanctum-gauge-lead.png")

def ivory_row(world):
    o = out(world)
    W, H, rad, b = 200, 60, 9, 3

    def shape(c):
        rounded(c, b / 2 + 1, b / 2 + 1, W - b / 2 - 1, H - b / 2 - 1, rad)
    s, c = canvas(W, H)
    c.new_path()
    shape(c)
    g = cairo.LinearGradient(0, 0, 0, H)
    g.add_color_stop_rgba(0, 0.985, 0.96, 0.9, 1)
    g.add_color_stop_rgba(0.55, 0.94, 0.905, 0.835, 1)
    g.add_color_stop_rgba(1, 0.86, 0.815, 0.73, 1)
    c.set_source(g)
    c.fill()
    save_rgba(straight_rgba(s), f"{o}/sanctum-row.png")
    h, m = lead(W, H, [(shape, b)], radius=b / 2 + 0.3)
    save_height(h, m, f"{o}/sanctum-row-lead.png")

def grain():
    from kit import noise
    n = 0.55 * noise(512, 512, 40, 11, 4) + 0.3 * noise(512, 512, 7, 12, 3) + 0.15 * noise(512, 512, 2, 13, 2)
    i = np.arange(512, dtype=np.float32)
    wc = 1 - np.abs(i - 255.5) / 255.5
    wx, wy = wc[None, :], wc[:, None]
    rx, ry = np.roll(n, 256, 1), np.roll(n, 256, 0)
    rxy = np.roll(rx, 256, 0)
    t = n * wx * wy + rx * (1 - wx) * wy + ry * wx * (1 - wy) + rxy * (1 - wx) * (1 - wy)
    t = (t - t.mean()) / max(1e-6, t.std())
    t = np.clip(0.5 + 0.12 * t, 0, 1)
    Image.fromarray((t * 255).astype(np.uint8), "L").convert("RGB").save(f"{A}/shared/sanctum-grain.png")

def build():
    for w in WORLDS:
        arch(w)
        sunburst(w)
        predella(w)
        lozenge(w)
        bead(w)
        gauge(w)
        ring = (0.27, 0.33, 0.66) if w == "dark" else (0.86, 0.62, 0.3)
        heart = (0.1, 0.12, 0.27) if w == "dark" else (0.13, 0.13, 0.4)
        icon_ring(w, "sanctum-ring", 46, ring, heart)
        for k, col in enumerate(JEWELS[w]):
            icon_ring(w, f"sanctum-ring-{k}", 46, col, heart)
        icon_ring(w, "sanctum-art", 76, ring, heart, pad=8)
        icon_ring(w, "sanctum-power", 48, ring, heart)
        icon_ring(w, "sanctum-power-armed", 48, (0.84, 0.25, 0.36), (0.3, 0.06, 0.12), pad=10)
        icon_ring(w, "sanctum-btn", 34, ring, heart)
        icon_ring(w, "sanctum-crest", 72, (0.62, 0.68, 0.92) if w == "dark" else (0.92, 0.36, 0.56), heart, pad=10, gilt=True)
        pane(w, "sanctum-search", 200, 56, 22, (0.09, 0.11, 0.25) if w == "dark" else (0.13, 0.13, 0.4), 5)
        pane(w, "sanctum-card", 200, 72, 10, (0.14, 0.18, 0.38) if w == "dark" else (0.2, 0.22, 0.58), 4)
        ivory_row(w)
        pane(w, "sanctum-plaque", 120, 40, 12, (0.1, 0.12, 0.27) if w == "dark" else (0.15, 0.15, 0.45), 3)
    alchemy_circle()
    grain()
