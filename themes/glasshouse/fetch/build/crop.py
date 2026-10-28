import numpy as np
from PIL import Image


def shrink(rgba, size):
    pre = np.dstack([rgba[..., :3] * rgba[..., 3:], rgba[..., 3:]])
    small = np.clip(np.dstack([np.asarray(Image.fromarray(np.ascontiguousarray(pre[..., k], np.float32), "F").resize(size, Image.LANCZOS)) for k in range(4)]), 0, 1)
    a = small[..., 3:]
    return np.dstack([np.clip(small[..., :3] / np.maximum(a, 1e-4), 0, 1), a])


def crop_save(rgba, path):
    a = rgba[..., 3]
    ys, xs = np.nonzero(a > 1.5 / 255)
    if not len(ys):
        ys, xs = np.array([0]), np.array([0])
    x0, y0, x1, y1 = int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1
    px = (np.clip(rgba[y0:y1, x0:x1], 0, 1) * 255 + 0.5).astype(np.uint8)
    px[px[..., 3] == 0] = 0
    Image.fromarray(px, "RGBA").save(path, optimize=True)
    return x0, y0


def extent(frames, out):
    sizes = [(x, y, *Image.open(out / name).size) for name, x, y in frames]
    return [max(x + w for x, _, w, _ in sizes), max(y + h for _, y, _, h in sizes)]
