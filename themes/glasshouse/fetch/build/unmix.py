import numpy as np

from .filters import distance_from, ease, gauss, morph, softened

MARGIN = (38, 66, 50)
EDGE = 6
QUIET = 3
LUMA = np.array([0.3, 0.6, 0.1], np.float32)
STRONG = (0.35, 0.6)
DENSE = 12
NEAR = (0.06, 0.3)
THIN = (0.03, 0.1)
GLOW = ((3, 0.3), (8, 0.25), (16, 0.3), (32, 0.2))
RIM = 32


def shine(D):
    Y = D @ LUMA
    keep = np.maximum(ease(gauss(ease(Y, *STRONG), DENSE), *NEAR), ease(Y - morph(morph(Y, 3, np.minimum), 3, np.maximum), *THIN))
    K = D * keep[..., None]
    ys, xs = np.ogrid[0:D.shape[0], 0:D.shape[1]]
    rim = ease(np.minimum(np.minimum(ys, D.shape[0] - 1 - ys), np.minimum(xs, D.shape[1] - 1 - xs)).astype(np.float32), 0, RIM)
    glow = np.maximum(sum(w * gauss(K, s) for s, w in GLOW), 0) * rim[..., None]
    top = np.maximum(glow.max(-1), 1e-4)
    return K + (np.maximum(top - K.max(-1), 0) / top)[..., None] * glow * glow / top[..., None]


def unmix(rgb, bg, matte=None, floor=None):
    c = rgb.astype(np.float32) / 255
    her = np.zeros(c.shape[:2], np.float32) if matte is None else matte.astype(np.float32) / 255
    her = np.maximum(her, distance_from(c, bg) * ease(her, 0.005, 0.02))
    her[floor + 2 if floor else len(her):] = 0
    H, W = her.shape
    sign = 1 if np.mean(bg) < 0.5 else -1
    gate = ease(distance_from(softened(rgb), bg, 0.35, sign < 0), 0.04, 0.12)
    ys, xs = np.ogrid[0:H, 0:W]
    edge = ease(np.minimum(np.minimum(ys, H - 1 - ys), xs).astype(np.float32), 0, EDGE)
    free = np.clip(1 - gauss(her, 1) / 0.02, 0, 1)
    T, B, L = MARGIN
    pad = [(T, B), (L, 0)]
    D = sign * shine(sign * np.pad((c - bg) * (gate * edge * free)[..., None], pad + [(0, 0)]))
    back = np.pad(np.broadcast_to(bg, c.shape), pad + [(0, 0)], mode="edge")
    ga = np.clip(np.maximum(D / (1 - back), -D / np.maximum(back, 1e-3)).max(-1), 0, 1)
    gl = np.clip(back + D / np.maximum(ga, 1e-3)[..., None], 0, 1)
    F = np.pad(np.clip(bg + (c - bg) / np.maximum(her, 1 / 255)[..., None], 0, 1), pad + [(0, 0)])
    her = np.pad(her, pad)
    alpha = her + (1 - her) * ga
    rgb = (her[..., None] * F + ((1 - her) * ga)[..., None] * gl) / np.maximum(alpha, 1e-4)[..., None]
    fade = np.clip((W + L - 9 - np.arange(W + L)) / 8, 0, 1)[None, :]
    return np.dstack([rgb, alpha * fade]), ga * (1 - her) * gl.mean(-1)


def background(frames, mattes):
    H, W = frames.shape[1:3]
    first = (np.median(frames[::max(1, len(frames) // 24), :H // 12].reshape(-1, W, 3), 0).astype(np.float32) / 255)[None]
    total, count = np.zeros((H, W, 3), np.float32), np.zeros((H, W), np.float32)
    for f, m in zip(frames[::QUIET], mattes[::QUIET]):
        quiet = ~morph((distance_from(softened(f), first, 0.35) > 0.035) | (m > 1), 4, np.maximum)
        total += f.astype(np.float32) / 255 * quiet[..., None]
        count += quiet
    w = np.clip(count / 4, 0, 1)
    near = gauss(w, 12)
    fill = gauss(total / np.maximum(count, 1)[..., None] * w[..., None], 12) / np.maximum(near, 1e-3)[..., None]
    fill = np.where((near > 0.02)[..., None], fill, first)
    return total / np.maximum(count, 1)[..., None] * w[..., None] + fill * (1 - w)[..., None]
