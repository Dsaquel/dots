import math

import cairo
import numpy as np
from PIL import Image, ImageDraw, ImageFont

SS = 4


def surf(w, h):
    s = cairo.ImageSurface(cairo.FORMAT_ARGB32, w * SS, h * SS)
    c = cairo.Context(s)
    c.scale(SS, SS)
    c.set_antialias(cairo.ANTIALIAS_BEST)
    c.set_line_join(cairo.LINE_JOIN_ROUND)
    c.set_line_cap(cairo.LINE_CAP_ROUND)
    return s, c


def cover(s):
    s.flush()
    a = np.ndarray((s.get_height(), s.get_stride() // 4, 4), np.uint8, s.get_data())
    return a[:, : s.get_width(), 3].astype(np.float32) / 255


def shape(w, h, draw):
    s, c = surf(w, h)
    c.set_source_rgba(1, 1, 1, 1)
    draw(c)
    return cover(s)


def stroke(w, h, paths, width):
    def go(c):
        c.set_line_width(width)
        for p in paths:
            c.new_path()
            p(c)
            c.stroke()
    return shape(w, h, go)


def grid(h, w):
    return (np.mgrid[0:h * SS, 0:w * SS].astype(np.float32) + 0.5) / SS - 0.5


def save(arr, path):
    arr = np.clip(arr, 0, 1)
    pre = np.dstack([arr[..., :3] * arr[..., 3:], arr[..., 3:]])
    small = pre.reshape(arr.shape[0] // SS, SS, arr.shape[1] // SS, SS, 4).mean((1, 3))
    a = small[..., 3:]
    out = np.dstack([np.where(a > 0, small[..., :3] / np.maximum(a, 1e-6), 0), a])
    Image.fromarray((np.clip(out, 0, 1) * 255 + 0.5).astype(np.uint8), "RGBA").save(path, optimize=True)


def glyph_mask(w, h, text, font_path, size, cx, cy, variation=None):
    img = Image.new("L", (w * SS, h * SS), 0)
    f = ImageFont.truetype(str(font_path), size * SS)
    if variation:
        f.set_variation_by_name(variation)
    ImageDraw.Draw(img).text((cx * SS, cy * SS), text, font=f, fill=255, anchor="mm")
    return np.asarray(img, np.float32) / 255


def rounded(c, x0, y0, x1, y1, r):
    c.new_sub_path()
    c.arc(x1 - r, y0 + r, r, -math.pi / 2, 0)
    c.arc(x1 - r, y1 - r, r, 0, math.pi / 2)
    c.arc(x0 + r, y1 - r, r, math.pi / 2, math.pi)
    c.arc(x0 + r, y0 + r, r, math.pi, 3 * math.pi / 2)
    c.close_path()



def outline(x0, y0, x1, y1, r, run=None, inset=0):
    x0, y0, x1, y1 = x0 + inset, y0 + inset, x1 - inset, y1 - inset

    def go(c):
        if not run:
            return rounded(c, x0, y0, x1, y1, r)
        f, e = run[0] + inset, run[1] - inset
        c.new_sub_path()
        c.arc(x0 + r, y0 + r, r, math.pi, 3 * math.pi / 2)
        c.arc(x1 - r, y0 + r, r, -math.pi / 2, 0)
        c.arc_negative(x1 + r, f - r, r, math.pi, math.pi / 2)
        c.arc(e - r, f + r, r, -math.pi / 2, 0)
        c.arc(e - r, y1 - r, r, 0, math.pi / 2)
        c.arc(x0 + r, y1 - r, r, math.pi / 2, math.pi)
        c.close_path()
    return go


def widen(art, width):
    out = np.zeros((art.shape[0], width * SS, 4), np.float32)
    out[:, :art.shape[1]] = art
    return out
