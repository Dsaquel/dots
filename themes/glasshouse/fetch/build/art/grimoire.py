import math

import numpy as np
from PIL import Image, ImageFilter, ImageFont

from .canvas import SS, glyph_mask, outline, rounded, save, shape, stroke
from .palette import CINZEL, DEJAVU, GILT, hexf
from .parts import floor_for
from .shading import bevel, distance, emboss, glass, metal_strokes, noise, over

VELLUM = {"dark": ("#1a1d36", "#121428", "#262b4c"), "light": ("#f4e9c8", "#e6d4a4", "#fbf3dc")}
ENAMEL = {"dark": ["#3a5bd0", "#d9668f", "#4fa898", "#8c73d6"], "light": ["#2f5fc0", "#d9452f", "#3a9467", "#9459cc"]}


def leaf(c, x0, y0, ang, length, half, curl=0.18):
    ux, uy = math.cos(ang), math.sin(ang)
    vx, vy = -uy, ux
    tip = (x0 + ux * length + vx * length * curl, y0 + uy * length + vy * length * curl)
    c.move_to(x0, y0)
    c.curve_to(x0 + ux * length * 0.3 + vx * half * 1.4, y0 + uy * length * 0.3 + vy * half * 1.4,
               x0 + ux * length * 0.75 + vx * half * 1.2, y0 + uy * length * 0.75 + vy * half * 1.2, *tip)
    c.curve_to(x0 + ux * length * 0.7 - vx * half * 0.6, y0 + uy * length * 0.7 - vy * half * 0.6,
               x0 + ux * length * 0.25 - vx * half * 0.9, y0 + uy * length * 0.25 - vy * half * 0.9, x0, y0)
    c.close_path()


def vellum(cov, world, seed, lx=0.55):
    H, W = cov.shape
    top, bottom, light = VELLUM[world]
    v = glass(cov, top, bottom, light, (lx, 0.35), 1.1, 0.97, seed, 0.035)
    fib = noise(W, H, 14.0, seed + 3, 3, 9.0)
    low = cov.reshape(H // SS, SS, W // SS, SS).mean((1, 3))
    vig = np.repeat(np.repeat(np.clip(distance(low, 40) / 40, 0, 1), SS, 0), SS, 1)
    v[..., :3] *= (0.94 + 0.08 * fib[..., None]) * (0.86 + 0.14 * vig[..., None])
    return v


def grimoire_page(world, cw, ch, g, E, run=None):
    W, H = g["w"] * cw, g["h"] * ch
    page = shape(E, H, lambda c: (outline(2, 2, W - 2, H - 2, 6, run)(c), c.fill()))
    art = vellum(page, world, 41, 0.55 * W / E)
    gilt_lines = [outline(2, 2, W - 2, H - 2, 4, run, 6), outline(2, 2, W - 2, H - 2, 3, run, 10)]
    art = over(art, metal_strokes(E, H, gilt_lines[:1], 1.8, GILT, 1.0))
    art = over(art, metal_strokes(E, H, gilt_lines[1:], 0.9, GILT, 0.6))
    mx = g["margin"] * cw // 2 + 4
    top, bottom = 22, H - 22
    stem = lambda c: (c.move_to(mx, top), [c.line_to(mx + 7 * math.sin((y - top) / 24), y) for y in range(top, bottom, 2)])
    art = over(art, metal_strokes(E, H, [stem], 2.4, GILT, 1.4))
    enamel = ENAMEL[world]
    for k, y in enumerate(range(top + 16, bottom - 10, 30)):
        x = mx + 7 * math.sin((y - top) / 24)
        side = 1 if k % 2 else -1
        ang = (0.0 if side > 0 else math.pi) + side * (-0.55)
        lm = shape(E, H, lambda c, x=x, y=y, ang=ang: (leaf(c, x, y, ang, 15, 4.6, 0.12 * side), c.fill()))
        colour = enamel[k % len(enamel)]
        art = over(art, glass(lm, colour, colour, "#ffffff", (0.3, 0.2), 0.4, 0.95, 50 + k, 0.04))
        art = over(art, metal_strokes(E, H, [lambda c, x=x, y=y, ang=ang: leaf(c, x, y, ang, 15, 4.6, 0.12 * side)], 1.1, GILT, 0.7))
        bx = x - side * 11
        dot = shape(E, H, lambda c, bx=bx, y=y: (c.arc(bx, y + 14, 2.6, 0, math.tau), c.fill()))
        art = over(art, emboss(bevel(dot, 2.0), dot, GILT))
    c0 = (g["margin"] + 2) * cw
    for r in g["rubrics"]:
        y = r * ch + ch // 2
        m = glyph_mask(E, H, "❦", DEJAVU, 22, c0 + 12, y)
        art = over(art, emboss(bevel(m, 1.6), m, GILT))
    y = (g["colophon"] - 1) * ch + ch // 2
    flourish = [lambda c: (c.move_to(W / 2 - 150, y), c.curve_to(W / 2 - 80, y - 6, W / 2 - 40, y + 6, W / 2 - 12, y)),
                lambda c: (c.move_to(W / 2 + 150, y), c.curve_to(W / 2 + 80, y - 6, W / 2 + 40, y + 6, W / 2 + 12, y))]
    art = over(art, metal_strokes(E, H, flourish, 1.4, GILT, 0.8))
    dia = shape(E, H, lambda c: (c.move_to(W / 2, y - 7), c.line_to(W / 2 + 7, y), c.line_to(W / 2, y + 7), c.line_to(W / 2 - 7, y), c.close_path(), c.fill()))
    art = over(art, emboss(bevel(dia, 2.5), dia, GILT))
    return art if run else art[:, :W * SS]


def grimoire_art(world, cw, ch, out, g, her):
    W, H = g["w"] * cw, g["h"] * ch
    floor = floor_for(W, her, cw, H - 24)
    save(grimoire_page(world, cw, ch, g, floor["w"]), out / "grimoire.png")
    save(grimoire_page(world, cw, ch, g, floor["w"], (floor["y"] - 6, floor["w"] - 2)), out / "grimoire-floor.png")
    for letter in "mtwfs":
        initial(world, letter, g["initial"][2] * cw, g["initial"][3] * ch, out / f"initial-{letter}.png")
    filler(world, ch, out / "filler.png")
    return {"panel": "grimoire.png", "floor": dict(floor, file="grimoire-floor.png", panel="grimoire.png")}


def initial(world, letter, W, H, path):
    box = shape(W, H, lambda c: (rounded(c, 3, 3, W - 3, H - 3, 3), c.fill()))
    ground = {"dark": ("#1d3c94", "#0f1f5c", "#4b6fd6"), "light": ("#c8324c", "#8a1c30", "#f06a7a")}[world]
    art = glass(box, ground[0], ground[1], ground[2], (0.3, 0.2), 0.8, 1.0, 61, 0.04)
    rng = np.random.default_rng(7)
    curls = []
    for _ in range(14):
        x, y, r = rng.uniform(8, W - 8), rng.uniform(8, H - 8), rng.uniform(4, 9)
        a0 = rng.uniform(0, math.tau)
        curls.append(lambda c, x=x, y=y, r=r, a0=a0: c.arc(x, y, r, a0, a0 + 4.2))
    fil = stroke(W, H, curls, 0.9) * box
    art = over(art, np.dstack([np.broadcast_to(hexf("#f4f2fb"), box.shape + (3,)), fil * 0.55]))
    face = CINZEL
    ink = lambda size: [v / SS for v in ImageFont.truetype(str(face), size * SS).getbbox(letter.upper(), anchor="mm")]
    size = next(s for s in range(int(H * 0.82), 8, -1) if ink(s)[2] - ink(s)[0] <= W - 12 and ink(s)[3] - ink(s)[1] <= H - 16)
    b = ink(size)
    m = glyph_mask(W, H, letter.upper(), face, size, W / 2 - (b[0] + b[2]) / 2, H / 2 - (b[1] + b[3]) / 2)
    shadow = np.asarray(Image.fromarray((m * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(2.5 * SS)), np.float32) / 255
    sh = np.zeros(m.shape + (4,), np.float32)
    sh[3 * SS:, 3 * SS:, 3] = shadow[:-3 * SS, :-3 * SS] * 0.7
    art = over(art, sh)
    art = over(art, emboss(bevel(m, 2.6), m, GILT, (0.2, -0.3)))
    art = over(art, metal_strokes(W, H, [lambda c: rounded(c, 3, 3, W - 3, H - 3, 3)], 3.4, GILT, 1.8))
    save(art, path)


def filler(world, ch, path, W=900):
    y = ch / 2
    line = stroke(W, ch, [lambda c: (c.move_to(4, y), c.line_to(W - 2, y))], 0.8)
    dots = shape(W, ch, lambda c: [(c.arc(x, y, 1.5, 0, math.tau), c.fill()) for x in range(10, W, 10)])
    gems = shape(W, ch, lambda c: [(c.move_to(x, y - 4), c.line_to(x + 4, y), c.line_to(x, y + 4), c.line_to(x - 4, y), c.close_path(), c.fill())
                                   for x in range(40, W, 80)])
    m = np.maximum(np.maximum(line * 0.5, dots), gems)
    save(emboss(bevel(m, 1.2), m * 0.85, GILT), path)
