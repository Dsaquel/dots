import json

import numpy as np
from PIL import Image

from .crop import crop_save, extent, shrink
from .reveal import written
from .unmix import MARGIN, background, unmix
from .video import CLIP, FPS, PACK, decode, probe

MEET = 6
HEIGHT_ROWS = 21


def sources(world):
    clip = PACK / "fetch/clips" / f"{world}-{CLIP}.mp4"
    stills = PACK / "fetch/stills"
    parts = [clip] if clip.exists() else sorted(clip.parent.glob(f"{world}-{CLIP}-[0-9].mp4"))
    still = next((stills / n for n in (f"pose-{world}-{CLIP}-wink.png", f"pose-dark-{CLIP}-wink.png") if (stills / n).exists()), None)
    return clip, parts, still


def her(world, cw, ch, out):
    clip, parts, still = sources(world)
    if not parts:
        name = still.name
        im = np.asarray(Image.open(still).convert("RGBA"), np.float32) / 255
        ys, xs = np.nonzero(im[..., 3] > 0.5)
        k = HEIGHT_ROWS * ch / (ys.max() - ys.min())
        im = shrink(im, (round(im.shape[1] * k), round(im.shape[0] * k)))
        x0, y0 = crop_save(im, out / "her-still.png")
        ys, xs = np.nonzero(im[..., 3] > 0.5)
        return {"w": im.shape[1], "h": im.shape[0], "fig": [int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())],
                "still": ["her-still.png", x0, y0], "frames": [], "fps": FPS, "seconds": 0, "cues": {}, "source": name}, None
    mattes = [p.with_suffix(".matte.mkv") for p in parts]
    W, H = probe(parts[-1])
    rows = np.nonzero((decode(mattes[-1], None, True, 1)[-1] > 127).sum(1) >= 6)[0]
    k = HEIGHT_ROWS * ch / (rows.max() - rows.min())
    W, H = round(W * k), round(H * k)
    raw, alpha, mix, bgs = [], [], [], []
    for n, (part, matte) in enumerate(zip(parts, mattes)):
        got, mat = decode(part, (W, H))[1 if n else 0:], decode(matte, (W, H), True)[1 if n else 0:]
        bgs.append(background(got, mat))
        prev = (raw[-1], alpha[-1]) if n else None
        for j, (f, m) in enumerate(zip(got, mat)):
            x = (j + 1) / (MEET + 1) if n and j < MEET else 1.0
            raw.append(f if x == 1 else (prev[0] + (f.astype(np.float32) - prev[0]) * x + 0.5).astype(np.uint8))
            alpha.append(m if x == 1 else (prev[1] + (m.astype(np.float32) - prev[1]) * x + 0.5).astype(np.uint8))
            mix.append((n, x))
    still = alpha[-1] > 127
    xs = np.nonzero(still)[1]
    rows = np.nonzero(still.sum(1) >= 6)[0]
    fig = (int(xs.min()), int(rows.min()), int(xs.max()), int(rows.max()))
    start = max(0, fig[0] - W // 40)
    T, Bm, L = MARGIN
    size = (W + L, H + T + Bm)
    B = cw
    grid = (size[1] // B, (start + L) // B)
    upper = round(fig[3] + T - (fig[3] - fig[1]) / 4) // B
    frames, light, maps = [], [], []
    for i, (f, m, (n, x)) in enumerate(zip(raw, alpha, mix)):
        rgba, glow = unmix(f, bgs[n] if x == 1 else bgs[n - 1] + (bgs[n] - bgs[n - 1]) * x, m, fig[3])
        name = f"her-{i:03d}.png"
        frames.append([name, *crop_save(rgba, out / name)])
        maps.append(glow[:grid[0] * B, :grid[1] * B].reshape(grid[0], B, grid[1], B).mean((1, 3)))
        light.append(float(maps[-1][:upper].sum()))
    peak = max(light) or 1.0
    lit = [i for i, v in enumerate(light) if v > 0.12 * peak]
    seconds = len(raw) / FPS
    cues = {"light": [round(lit[0] / FPS, 3), round((lit[-1] + 1) / FPS, 3)] if lit else [seconds * 0.5, seconds * 0.7]}
    extra = clip.with_suffix(".cues.json")
    cues.update(json.loads(extra.read_text()) if extra.exists() else {})
    return {"w": size[0], "h": size[1], "fig": [v + d for v, d in zip(fig, (L, T, L, T))], "still": frames[-1], "frames": frames,
            "extent": extent(frames, out), "fps": FPS,
            "seconds": round(seconds, 3), "cues": cues, "source": " ".join(p.name for p in parts),
            "written": written(np.stack(maps), B, lit[0], lit[-1]) if lit else None}, np.stack(maps)
