import json

import numpy as np
from PIL import Image

from .art.shading import over
from .crop import crop_save, extent
from .reveal import written
from .unmix import MARGIN, background, unmix
from .video import CLIP, FPS, PACK, decode, probe


def dial(world, cw, ch, out, she, maps, astro):
    take = PACK / "fetch/clips" / f"{world}-{CLIP}-dial.mp4"
    if maps is None or not take.exists():
        return None
    cue = json.loads(take.with_suffix(".cues.json").read_text())
    k = 0.92 * astro["radius"] / cue["radius"]
    W, H = probe(take)
    raw = decode(take, (round(W * k), round(H * k)))
    H, W = raw.shape[1:3]
    bg = background(raw, np.zeros(raw.shape[:3], np.uint8))
    T, Bm, L = MARGIN
    size = (W + L, H + T + Bm)
    ox = round(astro["dial"][0] - astro["floor"]["x"] + she["fig"][0] - cue["centre"][0] * k - L)
    oy = round(astro["dial"][1] - astro["floor"]["y"] + she["fig"][3] - cue["centre"][1] * k - T)
    P, Q = -(min(0, ox) // cw) * cw, -(min(0, oy) // cw) * cw
    w, h = she["w"] + P, max(she["h"] + Q, oy + Q + size[1])
    first = round(cue["start"] * FPS)
    grid = (h // cw, P // cw + maps.shape[2])
    lit = [maps.shape[0], -1]
    frames, light = [], np.zeros((len(she["frames"]), *grid), np.float32)
    light[:, Q // cw:Q // cw + maps.shape[1], P // cw:] = maps
    for i, (name, x, y) in enumerate(she["frames"]):
        if not 0 <= i - first < len(raw):
            frames.append([name, x + P, y + Q])
            continue
        rgba, glow = unmix(raw[i - first], bg)
        canvas = np.zeros((h, w, 4), np.float32)
        canvas[oy + Q:oy + Q + size[1], ox + P:ox + P + size[0]] = rgba
        base = np.asarray(Image.open(out / name).convert("RGBA"), np.float32) / 255
        canvas[y + Q:y + Q + base.shape[0], x + P:x + P + base.shape[1]] = over(canvas[y + Q:y + Q + base.shape[0], x + P:x + P + base.shape[1]], base)
        frames.append([f"astro-{i:03d}.png", *crop_save(canvas, out / f"astro-{i:03d}.png")])
        spot = np.zeros((h, w), np.float32)
        spot[oy + Q:oy + Q + size[1], ox + P:ox + P + size[0]] = glow
        light[i] += spot[:grid[0] * cw, :grid[1] * cw].reshape(grid[0], cw, grid[1], cw).mean((1, 3))
        lit = [min(lit[0], i), max(lit[1], i)]
    on = she["cues"]["light"]
    lit = [min(lit[0], round(on[0] * FPS)), max(lit[1], round(on[1] * FPS) - 1)]
    return dict(she, w=w, h=h, fig=[v + d for v, d in zip(she["fig"], (P, Q, P, Q))], still=frames[-1], frames=frames,
                extent=extent(frames, out), source=she["source"] + " " + take.name, written=written(light, cw, *lit))
