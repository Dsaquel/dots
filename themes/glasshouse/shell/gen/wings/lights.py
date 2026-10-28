import glob
import json
import os

import numpy as np
from PIL import Image
from scipy import ndimage

from kit import out, glow_of, save_rgba, straight_rgba

from .raster import K, area, coords, ctx, soft
from .reliquary import Reliquary


def lights(d, side, o):
    slots = d.slots()
    bx, by, bw, bh = d.box
    for f in glob.glob(f"{o}/sanctum-wing-{side}-light-*.png"):
        os.remove(f)
    s, c = ctx(d.box)
    for n, j in enumerate(slots):
        d.light_art(c, j, n)
    arr = straight_rgba(s)
    save_rgba(arr, f"{o}/sanctum-wing-{side}-lights.png")
    small = np.ascontiguousarray(np.asarray(Image.fromarray(arr, "RGBA").resize((bw, bh), Image.LANCZOS)))
    glow_of(small, 5, f"{o}/sanctum-wing-{side}-lights-glow.png", 1.5)
    ids = np.zeros((bh, bw), np.int32)
    meta = []
    for n, j in enumerate(slots):
        m = d.area(lambda c, j=j: (j["shape"](c), c.fill()), 1)
        ids[m > 0.5] = n + 1
        mk = d.area(lambda c, j=j: (j["shape"](c), c.fill()))
        ys, xs = np.nonzero(mk > 0)
        y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
        crop = np.zeros((y1 - y0, x1 - x0, 4), np.uint8)
        crop[..., :3] = 255
        crop[..., 3] = (mk[y0:y1, x0:x1] * 255).astype(np.uint8)
        save_rgba(crop, f"{o}/sanctum-wing-{side}-light-{n}-mask.png")
        meta.append(dict(n=n, kind=j["kind"], group=j["group"], order=round(j["order"], 4), centre=[round(j["cx"], 2), round(j["cy"], 2)],
                         box=[round(x0 / K + bx, 2), round(y0 / K + by, 2), round((x1 - x0) / K, 2), round((y1 - y0) / K, 2)]))
    dist, (iy, ix) = ndimage.distance_transform_edt(ids == 0, return_indices=True)
    near = ids[iy, ix]
    order = np.array([1.0] + [j["order"] for j in slots], np.float32)[near]
    reach = np.clip((12 - dist) / 4, 0, 1)
    om = np.zeros((bh, bw, 4), np.uint8)
    om[..., 0] = np.clip(np.round(order * 255), 0, 255).astype(np.uint8)
    om[..., 1] = np.clip(near, 0, 255).astype(np.uint8)
    om[..., 2] = (reach * 255).astype(np.uint8)
    om[..., 3] = 255
    save_rgba(om, f"{o}/sanctum-wing-{side}-lights-order.png")
    with open(f"{o}/sanctum-wing-{side}-slots.json", "w") as f:
        json.dump(dict(unit="stage", plate=list(d.box), scale=K, slots=meta), f, indent=1)
        f.write("\n")


def drop(world, side):
    o = out(world)
    d = Reliquary(side)
    j = d.slots()[0]
    box = (j["cx"] - 17.0, j["cy"] - 16.5, 34.0, 33.0)
    s, c = ctx(box)
    d.light_art(c, j, 0)
    arr = straight_rgba(s)
    save_rgba(arr, f"{o}/sanctum-wing-{side}-drop.png")
    stone = area(box, lambda c: (j["shape"](c), c.fill()))
    depth = soft(np.clip((ndimage.distance_transform_edt(stone > 0.5) / K - 0.4) / 2.8, 0, 1), 0.6 * K)
    wx, wy = coords(box)
    core = np.exp(-((wx - j["cx"]) ** 2 + (wy - j["cy"]) ** 2) / 7.5 ** 2)
    blur = np.stack([ndimage.gaussian_filter(arr[..., i].astype(np.float32) / 255, 1.6 * K) for i in range(3)], -1)
    glow = np.zeros(arr.shape, np.uint8)
    glow[..., :3] = np.clip((blur * 0.6 + np.array([0.36, 0.55, 1.0]) * 0.55) * 255, 0, 255).astype(np.uint8)
    glow[..., 3] = np.clip(stone * depth * (0.42 + 0.58 * core) * 255, 0, 255).astype(np.uint8)
    save_rgba(glow, f"{o}/sanctum-wing-{side}-drop-glow.png")
