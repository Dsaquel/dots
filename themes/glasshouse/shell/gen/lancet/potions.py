import json
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
PACK = os.environ.get("GLASSHOUSE_PACK") or os.path.expanduser("~/.local/share/glasshouse")


BOTTLES = {
    "dark": ["night-moon-flask", "night-tide-ampoule", "night-mercury-alembic", "night-sea-jar", "night-star-vial"],
    "light": ["day-sky-orb", "day-pearl-drop", "day-sun-crystal", "day-crown-bottle", "day-gold-ampoule"],
}
H2 = 200


def locate(sprite, sheet):
    a = sprite[..., 3] > 200
    ys, xs = np.nonzero(a)
    pick = np.linspace(0, len(ys) - 1, 400).astype(int)
    py, px = ys[pick], xs[pick]
    ref = sprite[py, px, :3].astype(np.float32)
    h, w = sprite.shape[:2]
    best = (1e9, 0, 0)
    for y in range(0, sheet.shape[0] - h + 1, 4):
        for x in range(0, sheet.shape[1] - w + 1, 4):
            d = np.abs(sheet[y + py[::8], x + px[::8], :3].astype(np.float32) - ref[::8]).mean()
            if d < best[0]:
                best = (d, x, y)
    _, bx, by = best
    for y in range(max(0, by - 4), min(sheet.shape[0] - h, by + 4) + 1):
        for x in range(max(0, bx - 4), min(sheet.shape[1] - w, bx + 4) + 1):
            d = np.abs(sheet[y + py, x + px, :3].astype(np.float32) - ref).mean()
            if d < best[0]:
                best = (d, x, y)
    return best


def interior(spec, w, h):
    SS = 4
    im = Image.new("L", (w * SS, h * SS), 0)
    d = ImageDraw.Draw(im)
    kind, *p = spec["shape"]
    Wd, Hd = w * SS, h * SS
    if kind == "ell":
        cu, cv, ru, rv = p
        d.ellipse([(cu - ru) * Wd, (cv - rv) * Hd, (cu + ru) * Wd, (cv + rv) * Hd], fill=255)
        top, bottom = cv - rv, cv + rv
    elif kind == "rrect":
        u0, v0, u1, v1, r = p
        d.rounded_rectangle([u0 * Wd, v0 * Hd, u1 * Wd, v1 * Hd], radius=r * Wd, fill=255)
        top, bottom = v0, v1
    else:
        pts = p[0]
        d.polygon([(u * Wd, v * Hd) for u, v in pts], fill=255)
        top, bottom = min(v for _, v in pts), max(v for _, v in pts)
    return im.filter(ImageFilter.GaussianBlur(SS * 0.8)).resize((w, h), Image.LANCZOS), top, bottom


def potions():
    if not os.path.isdir(f"{PACK}/potions") or not os.path.isdir(f"{PACK}/ref"):
        print("lancet: no art pack, potions skipped")
        return
    dst = f"{PACK}/potions/lancet"
    os.makedirs(dst, exist_ok=True)
    shapes = json.load(open(f"{HERE}/interiors.json"))
    meta = {}
    for world, names in BOTTLES.items():
        full_sheet = np.asarray(Image.open(f"{PACK}/ref/potions-{world}-sheet.png").convert("RGBA"))
        empty_sheet = np.asarray(Image.open(f"{PACK}/ref/potions-{world}-empty.png").convert("RGBA"))
        for n in names:
            spr = np.asarray(Image.open(f"{PACK}/potions/{n}.png").convert("RGBA"))
            d, x, y = locate(spr, full_sheet)
            h, w = spr.shape[:2]
            empty = empty_sheet[y:y + h, x:x + w].copy()
            empty[..., 3] = spr[..., 3]
            sc = H2 / h
            size = (max(1, round(w * sc)), H2)
            Image.fromarray(spr).resize(size, Image.LANCZOS).save(f"{dst}/{n}-full.png")
            Image.fromarray(empty).resize(size, Image.LANCZOS).save(f"{dst}/{n}-empty.png")
            spec = shapes[n]
            im, itop, bottom = interior(spec, *size)
            im.save(f"{dst}/{n}-liquid.png")
            meta[n] = dict(w=size[0], h=size[1], top=spec["top"], itop=round(itop + 0.03, 4), bottom=round(bottom, 4),
                           stopper=spec["stopper"], match=round(float(d), 2))
    json.dump(meta, open(f"{dst}/potions.json", "w"), indent=1)
