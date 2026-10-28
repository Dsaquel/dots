import cairo
import numpy as np
from PIL import Image, ImageFilter

from kit import canvas, noise
from orn import alpha

from .draw import beads

K = 2


def rgb(h):
    return tuple(int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))


def ctx(box, k=K):
    bx, by, bw, bh = box
    s, c = canvas(int(round(bw * k)), int(round(bh * k)))
    c.scale(k, k)
    c.translate(-bx, -by)
    return s, c


def area(box, draw, k=K):
    s, c = ctx(box, k)
    c.set_source_rgba(1, 1, 1, 1)
    c.set_line_join(cairo.LINE_JOIN_ROUND)
    c.set_line_cap(cairo.LINE_CAP_ROUND)
    draw(c)
    return alpha(s)


def coords(box, k=K):
    bx, by, bw, bh = box
    yy, xx = np.mgrid[0:int(round(bh * k)), 0:int(round(bw * k))].astype(np.float32)
    return xx / k + bx, yy / k + by


def soft(m, r):
    return np.asarray(Image.fromarray((np.clip(m, 0, 1) * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(r)), np.float32) / 255


def mix(a, b, k):
    return tuple(x + (y - x) * k for x, y in zip(a, b))


def lift(col, k):
    return tuple(min(1, v + (1 - v) * k) for v in col)


def streaks(shape, seed):
    h, w = shape
    n = noise(max(8, w), max(8, h // 9), 9, seed, 4)
    n = np.asarray(Image.fromarray((n * 255).astype(np.uint8)).resize((w, h), Image.BICUBIC), np.float32) / 255
    n2 = noise(w, h, 60, seed + 1, 3)
    return (n - n.mean()) * 0.9 + (n2 - n2.mean()) * 0.5


def grain(arr, body, seed, gain):
    k = streaks(arr.shape[:2], seed)
    rgbv = arr[..., :3].astype(np.float32) * (1 + gain * k * body)[..., None]
    arr[..., :3] = np.clip(rgbv, 0, 255).astype(np.uint8)


def shade(arr, body, occ, amount, toward):
    occ = np.roll(np.roll(occ, int(5 * K), 0), int(3 * K) * toward, 1)
    s = soft(occ, 9 * K) * body
    arr[..., :3] = (arr[..., :3].astype(np.float32) * (1 - amount * s[..., None])).astype(np.uint8)


def dimples(box, pts, r):
    return soft(area(box, lambda c: beads(c, pts, r)), r * K * 0.45)
