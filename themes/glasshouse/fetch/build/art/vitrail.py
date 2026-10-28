import math

import numpy as np

from .canvas import SS, grid, rounded, save, shape, surf, widen
from .palette import GILT, GLASS, JEWEL, LEAD, hexf
from .parts import bead, floor_for
from .shading import bevel, emboss, glass, metal_shape, metal_strokes, over


def window_path(W, sill, apex, shoulder, inset=0.0):
    def go(c):
        l, r = 4 + inset, W - 4 - inset
        c.move_to(l, sill)
        c.line_to(l, shoulder + inset * 0.5)
        c.curve_to(l, apex + (shoulder - apex) * 0.25, W * 0.30, apex + inset * 0.9, W / 2, apex + inset)
        c.curve_to(W * 0.70, apex + inset * 0.9, r, apex + (shoulder - apex) * 0.25, r, shoulder + inset * 0.5)
        c.line_to(r, sill)
        c.close_path()
    return go


def stars(w, h, n, seed, colour, size=(0.6, 1.6)):
    rng = np.random.default_rng(seed)
    s, c = surf(w, h)
    for _ in range(n):
        x, y, r = rng.uniform(0, w), rng.uniform(0, h), rng.uniform(*size)
        c.set_source_rgba(*colour, rng.uniform(0.35, 0.9))
        c.arc(x, y, r, 0, math.tau)
        c.fill()
    s.flush()
    a = np.ndarray((s.get_height(), s.get_stride() // 4, 4), np.uint8, s.get_data())[:, :s.get_width()].astype(np.float32) / 255
    al = a[..., 3:4]
    return np.dstack([a[..., 2::-1][..., :3] / np.maximum(al, 1e-6), al])


def vitrail_art(world, cw, ch, out, g, her):
    W, H = g["w"] * cw, g["h"] * ch
    sill = g["sill"] * ch + ch // 2
    apex, shoulder = 13, 2 * ch + 8
    lead = LEAD[world]
    gl = GLASS[world]
    jw = JEWEL[world]
    win = shape(W, H, lambda c: (window_path(W, sill, apex, shoulder)(c), c.fill()))
    art = np.zeros(win.shape + (4,), np.float32)
    art = over(art, glass(win, gl["top"], gl["bottom"], gl["light"], (0.88, -0.15), 0.75, gl["alpha"], 3))
    ys0, xs0 = grid(H, W)
    shaft = np.exp(-(((xs0 - W * 0.92) * 0.8 + (ys0 + 40) * 0.6 - 0) / 150) ** 2) * np.clip(1 - ys0 / H, 0.25, 1)
    beam = {"dark": "#8ea2ff", "light": "#ffffff"}[world]
    art = over(art, np.dstack([np.broadcast_to(hexf(beam), win.shape + (3,)), win * shaft * (0.10 if world == "dark" else 0.35)]))
    tymp = win * (ys0 < g["bars"][0] * ch + ch // 2 - 0.5)
    deep = {"dark": ("#0c1030", "#1a2058", "#46559c"), "light": ("#f9e7b0", "#fff3d2", "#ffffff")}[world]
    art = over(art, glass(tymp, deep[0], deep[1], deep[2], (0.5, 0.1), 0.45, gl["alpha"], 5))
    if world == "dark":
        st = stars(W, H, 70, 11, (0.85, 0.88, 1.0))
        st[..., 3] *= tymp
        art = over(art, st)
    else:
        ys, xs = ys0, xs0
        ang = np.arctan2(ys - apex - 40, xs - W / 2)
        rays = (0.5 + 0.5 * np.cos(ang * 22)) ** 6 * np.exp(-np.hypot(ys - apex - 40, xs - W / 2) / 260)
        art = over(art, np.dstack([np.broadcast_to(hexf("#ffd27a"), win.shape + (3,)), rays * tymp * 0.45]))
    bl, br = 27, W - 27
    for side in (0, 1):
        x0, x1 = (5, bl) if side == 0 else (br, W - 5)
        for k, top in enumerate(range(g["bars"][0] * ch + ch // 2, sill, 2 * ch)):
            colour = [jw["rose"], jw["gold"], jw["cyan"], jw["violet"]][(k + side * 2) % 4]
            cx, cy = (x0 + x1) / 2, top + ch
            m = shape(W, H, lambda c, cx=cx, cy=cy: (c.move_to(cx, cy - ch + 2), c.line_to(x1 - 2, cy), c.line_to(cx, cy + ch - 2),
                                                     c.line_to(x0 + 2, cy), c.close_path(), c.fill())) * win
            light = "#ffffff" if world == "light" else colour
            art = over(art, glass(m, colour, colour, light, (0.85, -0.2), 0.6, 0.55 if world == "dark" else 0.42, 20 + k))
    ys = ys0[:, :1]
    for row, key in zip(range(g["elements"], g["elements"] + 5), ["fire", "water", "earth", "air", "aether"]):
        yy = ys.astype(np.float32) - (row * ch + ch / 2)
        band = np.exp(-(yy / (ch * 0.42)) ** 4)
        xs = xs0[:1, :]
        fade = np.clip(1 - (xs - bl) / 200, 0, 1) ** 1.5 * np.clip((xs - bl) / 6, 0, 1)
        a = band * fade * (0.26 if world == "dark" else 0.20)
        art = over(art, np.dstack([np.broadcast_to(hexf(jw[key]), win.shape + (3,)), a]))
    bars = [lambda c, y=b * ch + ch // 2: (c.move_to(6, y), c.line_to(W - 6, y)) for b in g["bars"]]
    mullions = [lambda c, x=x: (c.move_to(x, shoulder + 4), c.line_to(x, sill)) for x in (bl, br)]
    lozenge = []
    for side in (0, 1):
        x0, x1 = (5, bl) if side == 0 else (br, W - 5)
        for top in range(g["bars"][0] * ch + ch // 2, sill, 2 * ch):
            cx, cy = (x0 + x1) / 2, top + ch
            lozenge.append(lambda c, cx=cx, cy=cy, x0=x0, x1=x1: (c.move_to(cx, cy - ch + 2), c.line_to(x1 - 2, cy),
                                                                  c.line_to(cx, cy + ch - 2), c.line_to(x0 + 2, cy), c.close_path()))
    art = over(art, metal_strokes(W, H, lozenge, 1.8, lead, 1.0))
    art = over(art, metal_strokes(W, H, bars + mullions, 5.0, lead, 2.6))
    art = over(art, metal_strokes(W, H, [window_path(W, sill, apex, shoulder)], 8.0, lead, 3.6))
    art = over(art, metal_strokes(W, H, [window_path(W, sill, apex, shoulder, 6.5)], 1.4, GILT, 0.9))
    for row in [g["sky"] + i for i in range(5)] + [g["elements"] + i for i in range(5)] + [g["principles"] + i for i in range(3)]:
        key = ["fire", "water", "earth", "air", "aether"][row - g["elements"]] if g["elements"] <= row < g["elements"] + 5 else \
            ["gold", "violet", "rose", "cyan", "gold"][row - g["sky"]] if row < g["elements"] else ["cyan", "gold", "violet"][row - g["principles"]]
        b = bead(20, jw[key], world)
        y0, x0 = (row * ch + ch // 2 - 10) * SS, (4 * cw + cw // 2 - 10) * SS
        art[y0:y0 + 20 * SS, x0:x0 + 20 * SS] = over(art[y0:y0 + 20 * SS, x0:x0 + 20 * SS], b)
    for bar, label in ((g["bars"][1], "THE FOUR ELEMENTS"), (g["bars"][2], "THE THREE PRINCIPLES")):
        pw = (len(label) + 6) * cw
        x0, y = ((g["w"] - len(label)) // 2 - 3) * cw, bar * ch + ch // 2
        art = over(art, metal_shape(W, H, lambda c, x0=x0, y=y: rounded(c, x0, y - 10, x0 + pw, y + 10, 9) or c.fill(), GILT, 3.4))
        for ex in (x0 + 9, x0 + pw - 9):
            art = over(art, metal_shape(W, H, lambda c, ex=ex, y=y: (c.arc(ex, y, 3.2, 0, math.tau), c.fill()), LEAD[world], 2.0))
    for bar in (g["bars"][0], g["bars"][3]):
        y = bar * ch + ch // 2
        art = over(art, metal_shape(W, H, lambda c, y=y: (c.arc(W / 2, y, 7, 0, math.tau), c.fill()), GILT, 3.0))
    rib = g["ribbon"] * ch + ch // 2
    rx0, rx1 = 60, W - 60

    def ribbon(c):
        c.move_to(rx0, rib - 10)
        c.curve_to(W * 0.35, rib - 14, W * 0.65, rib - 6, rx1, rib - 10)
        c.line_to(rx1, rib + 10)
        c.curve_to(W * 0.65, rib + 14, W * 0.35, rib + 6, rx0, rib + 10)
        c.close_path()
    tails = shape(W, H, lambda c: (c.move_to(rx0 + 2, rib - 6), c.line_to(rx0 - 26, rib - 2), c.line_to(rx0 - 14, rib + 6),
                                   c.line_to(rx0 - 26, rib + 14), c.line_to(rx0 + 2, rib + 12), c.close_path(),
                                   c.move_to(rx1 - 2, rib - 6), c.line_to(rx1 + 26, rib - 2), c.line_to(rx1 + 14, rib + 6),
                                   c.line_to(rx1 + 26, rib + 14), c.line_to(rx1 - 2, rib + 12), c.close_path(), c.fill()))
    tone = {"dark": ("#dfe3f6", "#9aa2cc", "#6c73a0"), "light": ("#fff6dc", "#ecd59c", "#c9a964")}[world]
    art = over(art, glass(tails, tone[2], tone[2], tone[1], (0.5, 0.5), 0.5, 1.0, 9, 0.03))
    body = shape(W, H, lambda c: (ribbon(c), c.fill()))
    art = over(art, glass(body, tone[0], tone[1], "#ffffff", (0.3, 0.0), 0.6, 1.0, 8, 0.03))
    art = over(art, metal_strokes(W, H, [ribbon], 1.4, GILT if world == "light" else LEAD[world], 0.8))
    sill_mask = shape(W, H, lambda c: (rounded(c, 0, sill, W, H - 1, 3), c.fill()))
    art = over(art, emboss(bevel(sill_mask, 4.0), sill_mask, GILT if world == "light" else lead))
    fin = shape(W, H, lambda c: (c.move_to(W / 2, 0), c.line_to(W / 2 + 6, apex - 2), c.line_to(W / 2, apex + 3),
                                 c.line_to(W / 2 - 6, apex - 2), c.close_path(), c.fill()))
    art = over(art, emboss(bevel(fin, 2.5), fin, GILT))
    save(art, out / "vitrail.png")
    floor = floor_for(W, her, cw, sill)
    E = floor["w"]
    run = shape(E, H, lambda c: (rounded(c, 0, sill, E - 2, H - 1, 3), c.fill()))
    save(over(widen(art, E), emboss(bevel(run, 4.0), run, GILT if world == "light" else lead)), out / "vitrail-floor.png")
    return {"panel": "vitrail.png", "floor": dict(floor, file="vitrail-floor.png", panel="vitrail.png")}
