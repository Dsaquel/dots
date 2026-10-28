import math

import cairo
import numpy as np
from PIL import Image, ImageFilter

from kit import A, TAU, WORLDS, out, canvas, fill_cell, straight_rgba, save_rgba, glow_of, lead, circle, \
    star6, crescent, save_height, noise

HEX = lambda h: tuple(int(h[i:i + 2], 16) / 255 for i in (1, 3, 5))  # noqa: E731
SEG = {"dark": ["#3558b8", "#6a4fc2", "#87b2aa", "#b8567e"], "light": ["#e8759a", "#f3c14f", "#5fd3e6", "#8a63da"]}
HEART = {"dark": "#10163a", "light": "#16195e"}


def ring(world):
    o = out(world)
    S = 112
    C = S / 2
    R = C - 3
    w = 9
    sf, c = canvas(S, S)
    fill_cell(c, circle(C, C, R - w), HEX(HEART[world]), C, C, R, 0.1)
    for k in range(12):
        a0 = -math.pi / 2 + k * TAU / 12
        col = HEX(SEG[world][k % 4])
        fill_cell(c, lambda c, a0=a0: (c.arc(C, C, R, a0, a0 + TAU / 12), c.arc_negative(C, C, R - w, a0 + TAU / 12, a0), c.close_path()),
                  tuple(v * 0.8 for v in col), C, C, R, 0.3)
    save_rgba(straight_rgba(sf), f"{o}/chat-ring.png")
    strokes = [(circle(C, C, R + 0.4), 3.6), (circle(C, C, R - w), 2.6)]
    for k in range(12):
        a0 = -math.pi / 2 + k * TAU / 12
        strokes.append((lambda c, a0=a0: (c.move_to(C + (R - w) * math.cos(a0), C + (R - w) * math.sin(a0)),
                                          c.line_to(C + R * math.cos(a0), C + R * math.sin(a0))), 1.5))
    h, m = lead(S, S, strokes, radius=1.5)
    save_height(h, m, f"{o}/chat-ring-lead.png")


def sigil(world):
    o = out(world)
    S = 40
    C = S / 2
    sf, c = canvas(S, S)
    if world == "dark":
        c.set_fill_rule(cairo.FILL_RULE_EVEN_ODD)
        fill_cell(c, lambda c: crescent(c, C - 1, C + 1, 14, 0.46, -0.75), (0.83, 0.87, 0.96), C - 6, C - 3, 15, 0.35)
        shape = lambda c: crescent(c, C - 1, C + 1, 14, 0.46, -0.75)  # noqa: E731
    else:
        fill_cell(c, lambda c: star6(c, C, C, 16, 0.58, 0.14), (0.99, 0.84, 0.50), C, C - 3, 15, 0.4)
        shape = lambda c: star6(c, C, C, 16, 0.58, 0.14)  # noqa: E731
    arr = straight_rgba(sf)
    save_rgba(arr, f"{o}/chat-sigil.png")
    glow_of(arr, 3, f"{o}/chat-sigil-glow.png", 1.4)

    def stroke(c):
        if world == "dark":
            c.set_fill_rule(cairo.FILL_RULE_EVEN_ODD)
        shape(c)
    h, m = lead(S, S, [(stroke, 1.6)], radius=0.9)
    save_height(h, m, f"{o}/chat-sigil-lead.png")


def speak():
    N = 400
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float32)
    r = np.hypot(xx - N / 2 + 0.5, yy - N / 2 + 0.5)
    v = np.exp(-((r - 90) / 20) ** 2) + 0.08 * np.exp(-(r / 84) ** 2) + 0.22 * np.exp(-((r - 92) / 64) ** 2)
    v = np.clip(v / v.max(), 0, 1)
    out = np.zeros((N, N, 4), np.uint8)
    out[..., :3] = 255
    out[..., 3] = (v * 255).astype(np.uint8)
    Image.fromarray(out, "RGBA").save(f"{A}/shared/chat-speak.png")


def glass():
    N = 512
    cloud = 0.6 * noise(N, N, 90, 31, 3) + 0.4 * noise(N, N, 24, 32, 3)
    st = noise(N, N // 8, 6, 33, 3)
    streak = np.asarray(Image.fromarray((st * 255).astype(np.uint8)).resize((N, N), Image.BICUBIC), np.float32) / 255
    fine = noise(N, N, 3, 34, 2)
    v = 0.5 * cloud + 0.3 * streak + 0.2 * fine
    v2 = np.roll(np.roll(v, N // 2, 0), N // 2, 1)
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float32)
    wgt = np.clip(np.minimum(np.minimum(xx, N - 1 - xx), np.minimum(yy, N - 1 - yy)) / (N / 2) * 1.6, 0, 1)
    v = v * wgt + v2 * (1 - wgt)
    v = (v - v.min()) / (v.max() - v.min())
    rng = np.random.default_rng(35)
    seeds = np.zeros((N, N), np.float32)
    for _ in range(26):
        x, y, r = rng.uniform(0, N), rng.uniform(0, N), rng.uniform(1.2, 3.4)
        for dx in (-N, 0, N):
            for dy in (-N, 0, N):
                d = np.hypot(xx - x - dx, yy - y - dy)
                seeds = np.maximum(seeds, np.clip(1 - np.abs(d - r) / 0.9, 0, 1) * 0.9)
                seeds = np.maximum(seeds, np.clip(1 - d / (r * 0.6), 0, 1) * 0.35)
    v = np.clip(0.18 + 0.64 * v + 0.35 * seeds, 0, 1)
    Image.fromarray((v * 255).astype(np.uint8), "L").filter(ImageFilter.GaussianBlur(0.5)).convert("RGB").save(f"{A}/shared/chat-glass.png")


def build():
    for w in WORLDS:
        ring(w)
        sigil(w)
    glass()
    speak()
