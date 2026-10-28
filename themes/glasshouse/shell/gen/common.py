import os

import numpy as np
from PIL import Image

from kit import A, noise, save_height, mask


def glass_noise():
    n = 0.55 * noise(512, 512, 40, 11, 4) + 0.3 * noise(512, 512, 7, 12, 3) + 0.15 * noise(512, 512, 2, 13, 2)
    n = n - n.mean()
    i = np.arange(512, dtype=np.float32)
    wc = 1 - np.abs(i - 255.5) / 255.5
    wx, wy = wc[None, :], wc[:, None]
    rx, ry = np.roll(n, 256, 1), np.roll(n, 256, 0)
    rxy = np.roll(rx, 256, 0)
    w = (wx * wy, (1 - wx) * wy, wx * (1 - wy), (1 - wx) * (1 - wy))
    t = (n * w[0] + rx * w[1] + ry * w[2] + rxy * w[3]) / np.sqrt(sum(k * k for k in w))
    t = np.clip(0.4978 + 0.1204 * (t - t.mean()) / t.std(), 0, 1)
    Image.fromarray((t * 255).astype(np.uint8), "L").convert("RGB").save(f"{A}/shared/glass-noise.png")


def pearl():
    S = 20
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    r = np.hypot(xx - S / 2 + 0.5, yy - S / 2 + 0.5) / (S / 2 - 1)
    h = np.sqrt(np.clip(1 - r * r, 0, 1))
    cover = np.clip((1 - r) * 8, 0, 1)
    save_height(h, cover, f"{A}/shared/pearl.png")


def cames():
    w, h = 64, 10
    m = mask(w, h, lambda c: (c.rectangle(0, 2, w, h - 4), c.fill()))
    hh = np.zeros((h, w), np.float32)
    hh[:] = np.array([0, 0.35, 0.75, 0.95, 1, 1, 0.95, 0.75, 0.35, 0], np.float32)[:, None]
    save_height(hh, m, f"{A}/shared/came-h.png")


def build():
    os.makedirs(f"{A}/shared", exist_ok=True)
    glass_noise()
    pearl()
    cames()
