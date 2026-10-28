import math

import numpy as np
from PIL import Image, ImageFilter


def distance_from(rgb, bg, floor=1e-3, dark=True):
    up = np.clip((rgb - bg) / np.maximum(1 - bg, 1e-3), 0, None)
    down = np.clip((bg - rgb) / np.maximum(bg, floor), 0, None) * dark
    return np.max(np.maximum(up, down), -1)


def morph(mask, r, pick):
    out = mask.copy()
    for axis in (0, 1):
        pad = np.pad(out, [(r, r) if k == axis else (0, 0) for k in (0, 1)], constant_values=pick is np.minimum)
        out = pick.reduce([np.take(pad, range(d, d + mask.shape[axis]), axis) for d in range(2 * r + 1)])
    return out


def ease(x, a, b):
    x = np.clip((x - a) / (b - a), 0, 1)
    return x * x * (3 - 2 * x)



def smear(a, r):
    p = np.pad(a, [(r, r)] + [(0, 0)] * (a.ndim - 1), mode="edge")
    c = np.concatenate([np.zeros_like(p[:1]), np.cumsum(p, 0)])
    return (c[2 * r + 1:] - c[:-2 * r - 1]) / (2 * r + 1)


def gauss(a, sigma):
    r = max(1, round((math.sqrt(4 * sigma * sigma + 1) - 1) / 2))
    for _ in range(3):
        a = smear(smear(a, r).swapaxes(0, 1), r).swapaxes(0, 1)
    return a


def softened(rgb):
    return np.asarray(Image.fromarray(rgb).filter(ImageFilter.BoxBlur(1)), np.float32) / 255


def blur(a, r):
    for axis in (0, 1):
        pad = np.pad(a, [(r, r) if k == axis else (0, 0) for k in (0, 1)], mode="edge")
        a = sum(np.take(pad, range(d, d + a.shape[axis]), axis) for d in range(2 * r + 1)) / (2 * r + 1)
    return a
