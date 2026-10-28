import math
import cairo
import numpy as np
from PIL import Image


def canvas(w, h):
    s = cairo.ImageSurface(cairo.FORMAT_ARGB32, w, h)
    c = cairo.Context(s)
    c.set_antialias(cairo.ANTIALIAS_BEST)
    return s, c


def alpha(s):
    s.flush()
    a = np.ndarray((s.get_height(), s.get_stride() // 4, 4), np.uint8, s.get_data())
    return a[:, : s.get_width(), 3].astype(np.float32) / 255.0


def rgba(s):
    s.flush()
    a = np.ndarray((s.get_height(), s.get_stride() // 4, 4), np.uint8, s.get_data())[:, : s.get_width()]
    b, g, r, al = [a[..., i].astype(np.float32) for i in range(4)]
    out = np.zeros(a.shape, np.float32)
    nz = al > 0
    for i, ch in enumerate((r, g, b)):
        out[..., i] = np.where(nz, ch * 255.0 / np.maximum(al, 1), 0)
    out[..., 3] = al
    return out.astype(np.uint8)


def edt_inside(mask, R=24):
    INF = np.float32(4 * R * R)
    f = np.where(mask > 0.5, INF, 0).astype(np.float32)
    g = f.copy()
    for k in range(1, R + 1):
        up = np.full_like(f, INF)
        up[:-k] = f[k:]
        dn = np.full_like(f, INF)
        dn[k:] = f[:-k]
        g = np.minimum(g, np.minimum(up, dn) + k * k)
    d = g.copy()
    for k in range(1, R + 1):
        l = np.full_like(g, INF)
        l[:, :-k] = g[:, k:]
        r = np.full_like(g, INF)
        r[:, k:] = g[:, :-k]
        d = np.minimum(d, np.minimum(l, r) + k * k)
    return np.sqrt(np.minimum(d, R * R)).astype(np.float32)


def bevel(mask, radius=4.0, profile="round", R=None):
    R = R or int(math.ceil(radius)) + 2
    d = edt_inside(mask, R) + mask - 0.5
    t = np.clip(d / radius, 0, 1)
    if profile == "round":
        h = np.sqrt(1 - (1 - t) ** 2)
    elif profile == "chamfer":
        h = t
    else:
        h = t * t * (3 - 2 * t)
    return (h * np.clip(mask * 1.5, 0, 1)).astype(np.float32)


def save_height(h, cover, path):
    out = np.zeros(h.shape + (4,), np.uint8)
    hv = (np.clip(h, 0, 1) * 255).astype(np.uint8)
    out[..., 0] = hv
    out[..., 1] = hv
    out[..., 3] = (np.clip(cover, 0, 1) * 255).astype(np.uint8)
    Image.fromarray(out, "RGBA").save(path)


def noise(w, h, scale, seed=0, octaves=5, persistence=0.5):
    rng = np.random.default_rng(seed)
    acc = np.zeros((h, w), np.float32)
    amp, total = 1.0, 0.0
    for o in range(octaves):
        cw = max(2, int(w / scale * 2 ** o) + 2)
        ch = max(2, int(h / scale * 2 ** o) + 2)
        grid = rng.random((ch, cw)).astype(np.float32)
        img = Image.fromarray((grid * 255).astype(np.uint8)).resize((w, h), Image.BICUBIC)
        acc += amp * (np.asarray(img, np.float32) / 255.0)
        total += amp
        amp *= persistence
    return acc / total


def tint(v, lo, hi):
    lo = np.array(lo, np.float32)
    hi = np.array(hi, np.float32)
    v = np.clip(v, 0, 1)[..., None]
    return lo + (hi - lo) * v


def save_rgb(arr, path, quality=92):
    Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGB").save(path, quality=quality)


def hexrgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))
