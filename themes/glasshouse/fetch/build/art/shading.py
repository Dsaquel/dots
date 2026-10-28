import math

import numpy as np
from PIL import Image

from .canvas import SS, shape, stroke
from .palette import hexf


def distance(mask, r):
    inf = np.float32(4 * r * r)
    f = np.where(mask > 0.5, inf, 0).astype(np.float32)
    g = f.copy()
    for k in range(1, r + 1):
        up, dn = np.full_like(f, inf), np.full_like(f, inf)
        up[:-k], dn[k:] = f[k:], f[:-k]
        g = np.minimum(g, np.minimum(up, dn) + k * k)
    d = g.copy()
    for k in range(1, r + 1):
        lf, rt = np.full_like(g, inf), np.full_like(g, inf)
        lf[:, :-k], rt[:, k:] = g[:, k:], g[:, :-k]
        d = np.minimum(d, np.minimum(lf, rt) + k * k)
    return np.sqrt(np.minimum(d, r * r))


def bounds(a, pad):
    rows, cols = np.nonzero(a.any(1))[0], np.nonzero(a.any(0))[0]
    if not len(rows):
        return None
    return (slice(max(0, rows[0] - pad), min(a.shape[0], rows[-1] + 1 + pad)),
            slice(max(0, cols[0] - pad), min(a.shape[1], cols[-1] + 1 + pad)))


def bevel(mask, radius):
    out, box = np.zeros(mask.shape, np.float32), bounds(mask, 1)
    if box:
        m = mask[box]
        t = np.clip((distance(m, int(math.ceil(radius * SS)) + 2) + m - 0.5) / (radius * SS), 0, 1)
        out[box] = np.sqrt(1 - (1 - t) ** 2) * np.clip(m * 1.5, 0, 1)
    return out


def emboss(height, cov, m, light=(0.1, -0.35), lz=1.4):
    H, W = height.shape
    out, box = np.zeros((H, W, 4), np.float32), bounds(cov, 2)
    if not box:
        return out
    p = np.pad(height[box], 1, mode="edge")
    hx = 0.25 * (p[:-2, 2:] + 2 * p[1:-1, 2:] + p[2:, 2:] - p[:-2, :-2] - 2 * p[1:-1, :-2] - p[2:, :-2])
    hy = 0.25 * (p[2:, :-2] + 2 * p[2:, 1:-1] + p[2:, 2:] - p[:-2, :-2] - 2 * p[:-2, 1:-1] - p[:-2, 2:])
    n = np.dstack([-hx * m["depth"] * SS, hy * m["depth"] * SS, np.ones_like(hx)])
    n /= np.linalg.norm(n, axis=-1, keepdims=True)
    ys, xs = np.mgrid[box].astype(np.float32)
    aspect = W / H
    pos = np.dstack([xs / W * aspect, 1 - ys / H, height[box] * 0.015])
    lp = np.array([light[0] * aspect, 1 - light[1], lz], np.float32)
    L = lp - pos
    L /= np.linalg.norm(L, axis=-1, keepdims=True)
    Hv = L + np.array([0, 0, 1], np.float32)
    Hv /= np.linalg.norm(Hv, axis=-1, keepdims=True)
    diff = np.clip((n * L).sum(-1), 0, 1)[..., None]
    spec = np.clip((n * Hv).sum(-1), 0, 1)[..., None] ** m["shininess"]
    env = np.clip(0.5 + n[..., 2:3] * n[..., 1:2], 0, 1)
    sm = lambda a, b, x: np.clip((x - a) / (b - a), 0, 1) ** 2 * (3 - 2 * np.clip((x - a) / (b - a), 0, 1))
    envc = hexf(m["low"]) + (hexf(m["sky"]) - hexf(m["low"])) * sm(0.2, 0.9, env)
    ao = 0.55 + 0.45 * sm(0.0, 0.6, height[box][..., None])
    base = hexf(m["base"])
    col = base * (0.22 + 0.78 * diff) * ao
    k = m["metal"] * 0.35 * (1 - diff * 0.5)
    col = col * (1 - k) + envc * base * 1.6 * k
    col = col + hexf(m["hi"]) * spec * (0.35 + 0.9 * m["metal"])
    out[box] = np.dstack([np.clip(col, 0, 1), cov[box]])
    return out


def noise(w, h, scale, seed, octaves=4, stretch=1.0, box=(slice(None), slice(None))):
    rng = np.random.default_rng(seed)
    (y0, y1, _), (x0, x1, _) = box[0].indices(h), box[1].indices(w)
    acc, amp, total = np.zeros((y1 - y0, x1 - x0), np.float32), 1.0, 0.0
    for o in range(octaves):
        gw, gh = max(2, int(w / (scale * SS * stretch) * 2 ** o) + 2), max(2, int(h / (scale * SS) * 2 ** o) + 2)
        img = Image.fromarray((rng.random((gh, gw)) * 255).astype(np.uint8)).resize((x1 - x0, y1 - y0), Image.BICUBIC,
                                                                                    (x0 * gw / w, y0 * gh / h, x1 * gw / w, y1 * gh / h))
        acc += amp * np.asarray(img, np.float32) / 255
        total += amp
        amp *= 0.5
    return acc / total


def glass(cov, top, bottom, light, lxy=(0.85, -0.1), radius=0.9, alpha=0.93, seed=1, grain=0.05):
    H, W = cov.shape
    out, box = np.zeros((H, W, 4), np.float32), bounds(cov, 0)
    if not box:
        return out
    ys, xs = np.mgrid[box].astype(np.float32)
    v = (ys / max(1, H - 1))[..., None]
    col = hexf(top) * (1 - v) + hexf(bottom) * v
    d2 = ((xs / W - lxy[0]) * W / H) ** 2 + (ys / H - lxy[1]) ** 2
    fall = np.exp(-d2 / (radius * radius))[..., None]
    col = col + (hexf(light) - col) * fall * 0.55
    tex = (noise(W, H, 3.0, seed, 3, box=box) - 0.5) * grain + (noise(W, H, 40.0, seed + 7, 3, 6.0, box) - 0.5) * grain * 0.8
    col = col * (1 + tex[..., None])
    out[box] = np.dstack([np.clip(col, 0, 1), cov[box] * alpha])
    return out


def over(dst, src):
    out, box = np.array(dst, np.float32), bounds(src[..., 3], 0)
    if not box:
        return out
    src, dst = src[box], dst[box]
    sa = src[..., 3:4]
    da = dst[..., 3:4]
    oa = sa + da * (1 - sa)
    rgb = (src[..., :3] * sa + dst[..., :3] * da * (1 - sa)) / np.maximum(oa, 1e-6)
    out[box] = np.dstack([rgb, oa])
    return out


def metal_strokes(w, h, paths, width, m, radius=None):
    mask = stroke(w, h, paths, width)
    return emboss(bevel(mask, radius or width / 2 + 0.3), mask, m)



def metal_shape(w, h, draw, m, radius):
    mask = shape(w, h, draw)
    return emboss(bevel(mask, radius), mask, m)
