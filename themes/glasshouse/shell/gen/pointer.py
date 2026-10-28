import numpy as np
from PIL import Image

from kit import out

HEX = lambda h: np.array([int(h[i:i + 2], 16) for i in (1, 3, 5)], np.float32)  # noqa: E731
MOTES = {
    "dark": {"pointer-mote": ("#f4f6ff", "#cfd8ec", 0.42, 1.6), "pointer-mote-b": ("#fff1d6", "#ffc978", 0.42, 1.6)},
    "light": {"pointer-mote": ("#b8730c", "#f3b544", 0.6, 2.1), "pointer-mote-b": ("#cb326e", "#e8759a", 0.5, 2.0)},
}


def mote(core, halo, hk, cr, S=24):
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    r = np.hypot(xx - (S - 1) / 2, yy - (S - 1) / 2)
    ac = np.exp(-(r / cr) ** 2)
    ah = np.exp(-(r / 4.2) ** 2) * hk
    a = ac + ah * (1 - ac)
    rgb = (HEX(core)[None, None] * ac[..., None] + HEX(halo)[None, None] * (ah * (1 - ac))[..., None]) / np.maximum(a, 1e-6)[..., None]
    return np.dstack([np.clip(rgb, 0, 255), np.clip(a * 255, 0, 255)]).astype(np.uint8)


def build():
    for world, motes in MOTES.items():
        o = out(world)
        for name, spec in motes.items():
            Image.fromarray(mote(*spec), "RGBA").save(f"{o}/{name}.png")
