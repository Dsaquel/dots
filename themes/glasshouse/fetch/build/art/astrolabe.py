import math

import numpy as np

from .canvas import SS, glyph_mask, grid, outline, rounded, save, shape, stroke
from .palette import CARDO, DEJAVU, GILT, JEWEL, LEAD, hexf
from .parts import bead, floor_for
from .shading import bevel, emboss, glass, metal_strokes, over


def astrolabe_art(world, cw, ch, out, g, her):
    D = g["disc"] * cw
    H = g["h"] * ch
    W = D
    cx, cy = D / 2, g["disc_rows"] * ch / 2
    R = min(cx, cy) - 4
    disc = shape(W, H, lambda c: (c.arc(cx, cy, R, 0, math.tau), c.fill()))
    face = shape(W, H, lambda c: (c.arc(cx, cy, R * 0.80, 0, math.tau), c.fill()))
    ring = np.clip(disc - face, 0, 1)
    tone = {"dark": ("#141a42", "#0b0f2c", "#2c3a80"), "light": ("#fff6dc", "#f0dfae", "#ffffff")}[world]
    art = glass(face, tone[0], tone[1], tone[2], (0.7, 0.15), 0.7, 0.95, 71)
    band = {"dark": ("#26305e", "#1a2148", "#4a5aa8"), "light": ("#e9d29a", "#d7b874", "#fff3cf")}[world]
    art = over(art, glass(ring, band[0], band[1], band[2], (0.3, 0.1), 0.8, 0.97, 72))
    lead = LEAD[world]
    rings = [lambda c, r=r: c.arc(cx, cy, r, 0, math.tau) for r in (R, R * 0.80, R * 0.895)]
    art = over(art, metal_strokes(W, H, rings[:2], 4.0, GILT if world == "light" else lead, 2.2))
    art = over(art, metal_strokes(W, H, rings[2:], 1.2, GILT, 0.8))
    ticks = []
    for k in range(96):
        phi = k / 96 * math.tau
        r0 = R * (0.955 if k % 4 else 0.93)
        ticks.append(lambda c, phi=phi, r0=r0: (c.move_to(cx + r0 * math.sin(phi), cy - r0 * math.cos(phi)),
                                                c.line_to(cx + R * 0.985 * math.sin(phi), cy - R * 0.985 * math.cos(phi))))
    art = over(art, metal_strokes(W, H, ticks, 1.1, GILT, 0.7))
    signs = "♈♉♊♋♌♍♎♏♐♑♒♓"
    m = np.zeros(disc.shape, np.float32)
    for k, s_ in enumerate(signs):
        phi = (k + 0.5) / 12 * math.tau
        m = np.maximum(m, glyph_mask(W, H, s_, DEJAVU, 17,
                                     cx + R * 0.84 * math.sin(phi), cy - R * 0.84 * math.cos(phi)))
    art = over(art, emboss(bevel(m, 1.2), m * 0.9, GILT))
    for glyph, phi in (("☉", 0.0), ("☽", math.pi)):
        gm = glyph_mask(W, H, glyph, CARDO, 22, cx + R * 0.71 * math.sin(phi), cy - R * 0.71 * math.cos(phi))
        art = over(art, emboss(bevel(gm, 1.4), gm, GILT))
    rete = []
    for k in range(6):
        a0 = k / 6 * math.tau
        rete.append(lambda c, a0=a0: (c.move_to(cx + R * 0.30 * math.sin(a0), cy - R * 0.30 * math.cos(a0)),
                                      c.curve_to(cx + R * 0.55 * math.sin(a0 + 0.5), cy - R * 0.55 * math.cos(a0 + 0.5),
                                                 cx + R * 0.70 * math.sin(a0 + 0.2), cy - R * 0.70 * math.cos(a0 + 0.2),
                                                 cx + R * 0.79 * math.sin(a0 + 0.45), cy - R * 0.79 * math.cos(a0 + 0.45))))
    rm = stroke(W, H, rete, 1.3)
    art = over(art, np.dstack([emboss(bevel(rm, 0.9), rm, GILT)[..., :3], rm * 0.45]))
    art = over(art, metal_strokes(W, H, [lambda c: c.arc(cx, cy, R * 0.30, 0, math.tau)], 1.6, GILT, 1.0))
    save(art, out / "astrolabe.png")
    for name, colour, size in (("bead-day.png", JEWEL[world]["gold"], 12), ("bead-night.png", "#3a4b9a" if world == "dark" else "#2f5fc0", 10)):
        save(bead(size, colour, world), out / name)
    for name, glyph, colour in (("now-sun.png", "☉", "#ffd27a"), ("now-moon.png", "☽", "#dfe6ff")):
        S = 30
        ys, xs = grid(S, S)
        halo = np.exp(-((ys - S / 2 + 0.5) ** 2 + (xs - S / 2 + 0.5) ** 2) / (S * S * 0.06))
        art2 = np.dstack([np.broadcast_to(hexf(colour), halo.shape + (3,)), halo * 0.8])
        gm = glyph_mask(S, S, glyph, CARDO, 22, S / 2, S / 2 + 1)
        art2 = over(art2, emboss(bevel(gm, 1.2), gm, GILT))
        save(art2, out / name)
    tube(world, g["tube"] * cw, out)
    PW, PH = (g["w"] + 3) * cw, 21 * ch
    floor = floor_for(PW, her, cw, PH - 31)
    tone2 = {"dark": ("#141a3e", "#0d1130", "#2a3672"), "light": ("#fffaea", "#f5e8c2", "#ffffff")}[world]

    def plate(E, run=None):
        pane = shape(E, PH, lambda c: (outline(3, 3, PW - 3, PH - 3, 10, run)(c), c.fill()))
        art = glass(pane, tone2[0], tone2[1], tone2[2], (0.9 * PW / E, -0.2), 0.8, 0.9, 91)
        art = over(art, metal_strokes(E, PH, [outline(3, 3, PW - 3, PH - 3, 10, run)], 3.0, GILT if world == "light" else lead, 1.8))
        art = over(art, metal_strokes(E, PH, [outline(3, 3, PW - 3, PH - 3, 7, run, 5)], 1.0, GILT, 0.6))
        for yy in (3.5 * ch, 7.5 * ch, 13.5 * ch, 17.5 * ch):
            art = over(art, metal_strokes(E, PH, [lambda c, yy=yy: (c.move_to(2 * cw, yy), c.line_to(PW - 2 * cw, yy))], 0.9, GILT, 0.6))
        return art if run else art[:, :PW * SS]
    save(plate(floor["w"]), out / "astro-plate.png")
    save(plate(floor["w"], (floor["y"] + 1, floor["w"] - 3)), out / "astro-plate-floor.png")
    return {"panel": "astrolabe.png", "radius": R, "centre": [cx, cy], "dial": [cx - (g["col"] - 2 - g["x"]) * cw, cy],
            "floor": dict(floor, file="astro-plate-floor.png", panel="astro-plate.png")}


def tube(world, length, out, h=14):
    body = shape(length, h, lambda c: (rounded(c, 2, 2, length - 2, h - 2, 5), c.fill()))
    empty = glass(body, "#2a3366" if world == "dark" else "#fff8e6", "#151b40" if world == "dark" else "#efe2bd", "#ffffff", (0.5, 0.0), 0.6, 0.55, 81)
    hl = shape(length, h, lambda c: (rounded(c, 6, 3.2, length - 6, 5.2, 1), c.fill()))
    cap = metal_strokes(length, h, [lambda c: rounded(c, 2, 2, length - 2, h - 2, 5)], 1.4, GILT, 0.8)
    shine = np.dstack([np.ones(hl.shape + (3,), np.float32), hl * 0.35])
    save(over(over(empty, shine), cap), out / "tube-empty.png")
    inner = shape(length, h, lambda c: (rounded(c, 3.5, 3.5, length - 3.5, h - 3.5, 3.5), c.fill()))
    for key in ("fire", "water", "earth"):
        colour = JEWEL[world][key]
        liquid = glass(inner, colour, colour, "#ffffff", (0.5, 0.0), 0.5, 0.95, 82)
        liquid[..., :3] *= np.linspace(1.15, 0.8, h * SS)[:, None, None]
        save(over(over(over(empty, liquid), shine), cap), out / f"tube-{key}.png")
