import importlib.util
import math
import os
import wave

import cairo
import numpy as np

from kit import A, TAU, WORLDS, out, canvas, straight_rgba, save_rgba, glow_of, star4, star6

HEX = lambda h: tuple(int(h[i:i + 2], 16) / 255 for i in (1, 3, 5))  # noqa: E731
ROOT = os.path.dirname(A)

def sfx():
    spec = importlib.util.spec_from_file_location("gen_synth", os.path.join(ROOT, "gen", "synth.py"))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod

def drop(world="dark"):
    o = out(world)
    S = 96
    cx, top, R = S / 2, 10.0, 25.0
    cy = S - 12 - R

    def shape(c):
        c.move_to(cx, top)
        c.curve_to(cx + 7, top + 16, cx + R, cy - R * 0.55, cx + R, cy)
        c.arc(cx, cy, R, 0, math.pi)
        c.curve_to(cx - R, cy - R * 0.55, cx - 7, top + 16, cx, top)
        c.close_path()

    sf, c = canvas(S, S)
    shape(c)
    g = cairo.RadialGradient(cx + 3, cy + 4, 1, cx, cy - 4, R * 1.55)
    g.add_color_stop_rgba(0.0, 0.99, 0.99, 1.0, 1)
    g.add_color_stop_rgba(0.28, *HEX("#dfe6f6"), 1)
    g.add_color_stop_rgba(0.66, *HEX("#8fa4dc"), 1)
    g.add_color_stop_rgba(1.0, *HEX("#3558b8"), 1)
    c.set_source(g)
    c.fill_preserve()
    c.set_source_rgba(*HEX("#1b2350"), 1)
    c.set_line_width(3.4)
    c.stroke()
    c.new_path()
    c.arc(cx - 3, cy + 1, R - 7, math.pi * 0.62, math.pi * 1.18)
    c.set_source_rgba(1, 1, 1, 0.85)
    c.set_line_width(3.2)
    c.set_line_cap(cairo.LINE_CAP_ROUND)
    c.stroke()
    c.arc(cx + 9, cy - 9, 3.2, 0, TAU)
    c.set_source_rgba(1, 1, 1, 0.9)
    c.fill()
    arr = straight_rgba(sf)
    save_rgba(arr, f"{o}/lock-drop.png")
    glow_of(arr, 9, f"{o}/lock-drop-glow.png", 1.7)

def star(world="light"):
    o = out(world)
    S = 96
    C = S / 2
    sf, c = canvas(S, S)
    star4(c, C, C, 40, 0.16, -math.pi / 2, 1.18)
    g = cairo.RadialGradient(C, C, 0, C, C, 44)
    g.add_color_stop_rgba(0.0, 1, 1, 1, 1)
    g.add_color_stop_rgba(0.22, *HEX("#fff6d8"), 1)
    g.add_color_stop_rgba(0.55, *HEX("#ffd48a"), 1)
    g.add_color_stop_rgba(1.0, *HEX("#e41480"), 1)
    c.set_source(g)
    c.fill_preserve()
    c.set_source_rgba(*HEX("#8a0f4f"), 0.9)
    c.set_line_width(2.2)
    c.stroke()
    arr = straight_rgba(sf)
    save_rgba(arr, f"{o}/lock-star.png")
    glow_of(arr, 10, f"{o}/lock-star-glow.png", 1.8)

def sun(world="light"):
    o = out(world)
    S = 160
    C = S / 2
    sf, c = canvas(S, S)
    for k in range(16):
        a = -math.pi / 2 + k * TAU / 16
        r0, r1 = 46, 70 if k % 2 == 0 else 60
        half = 0.07 if k % 2 == 0 else 0.055
        c.move_to(C + r0 * math.cos(a - half * 2.2), C + r0 * math.sin(a - half * 2.2))
        c.line_to(C + r1 * math.cos(a), C + r1 * math.sin(a))
        c.line_to(C + r0 * math.cos(a + half * 2.2), C + r0 * math.sin(a + half * 2.2))
        c.close_path()
    g = cairo.RadialGradient(C, C, 40, C, C, 72)
    g.add_color_stop_rgba(0, *HEX("#fff2c8"), 1)
    g.add_color_stop_rgba(1, *HEX("#f3c14f"), 0.9)
    c.set_source(g)
    c.fill()
    c.arc(C, C, 46, 0, TAU)
    g = cairo.RadialGradient(C - 10, C - 12, 4, C, C, 48)
    g.add_color_stop_rgba(0, *HEX("#fff8e2"), 1)
    g.add_color_stop_rgba(0.6, *HEX("#ffd48a"), 1)
    g.add_color_stop_rgba(1, *HEX("#e39a3a"), 1)
    c.set_source(g)
    c.fill_preserve()
    c.set_source_rgba(*HEX("#7a4a1c"), 0.85)
    c.set_line_width(2.6)
    c.stroke()
    star6(c, C, C, 36, 0.58, 0.14)
    g = cairo.RadialGradient(C, C, 0, C, C, 36)
    g.add_color_stop_rgba(0, 1, 1, 1, 1)
    g.add_color_stop_rgba(0.5, *HEX("#fff4f8"), 1)
    g.add_color_stop_rgba(1, *HEX("#ff8cc6"), 1)
    c.set_source(g)
    c.fill_preserve()
    c.set_source_rgba(*HEX("#c4106c"), 0.95)
    c.set_line_width(2.4)
    c.stroke()
    arr = straight_rgba(sf)
    save_rgba(arr, f"{o}/lock-sun.png")
    glow_of(arr, 12, f"{o}/lock-sun-glow.png", 1.6)

def write(path, x):
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(48000)
        w.writeframes(np.round(np.clip(x, -1, 1) * 32767).astype("<i2").tobytes())

def level(fx, x, ref, trim):
    y = x * 10 ** ((ref + trim - fx.loud40(x)) / 20)
    return y * min(1, 10 ** (-1 / 20) / max(np.abs(y).max(), 1e-9))

def sounds(world):
    fx = sfx()
    dark = world == "dark"
    V = fx.GLASS if dark else fx.CRYSTAL
    fc = 5200 if dark else 9000
    o = out(world)
    with wave.open(os.path.join(ROOT, "sounds", world, "ws-3.wav")) as w:
        ref = fx.loud40(np.frombuffer(w.readframes(w.getnframes()), "<i2").astype(np.float64) / 32767)
    ladder = ["C6", "D6", "E6", "G6", "A6"] if dark else ["C7", "D7", "E7", "G7", "A7"]
    for i, n in enumerate(ladder, 1):
        ev = [(0, fx.strike(fx.hz(n), V, 0.7, 0.14 if dark else 0.06)), (0.004, fx.strike(fx.hz(n) * 2, fx.SPARK, 0.12 if dark else 0.2))]
        write(f"{o}/lock-key-{i}.wav", level(fx, fx.render(0.5 if dark else 0.35, ev, 0.1, fc), ref, -11))
    rng = np.random.default_rng(11 if dark else 12)
    snap = fx.burst(2600 if dark else 4200, 0.9, 0.0035)
    ev = [(0, 1.1 * snap), (0.0, 0.55 * fx.burst(240 if dark else 320, 0.6, 0.03))]
    for t in np.sort(rng.uniform(0.006, 0.17, 9)):
        ev.append((t, 0.5 * (1 - t / 0.2) * fx.burst(rng.uniform(3000, 6500) if dark else rng.uniform(4500, 8500), 0.4, 0.0018)))
    ev.append((0.025, fx.strike(fx.hz("F5" if dark else "F6") * 2 ** (1 / 12), V, 0.42, 0.22 if dark else 0.1)))
    ev.append((0.03, 0.22 * fx.sweep(0.32, 3600 if dark else 5200, 900 if dark else 1600, 0.4, 0.1, 2.0)))
    write(f"{o}/lock-crack.wav", level(fx, fx.render(0.9, ev, 0.16, fc), ref, -2))
    ev = [(0, 0.9 * fx.burst(3200 if dark else 4800, 1.0, 0.008)), (0.01, 0.35 * fx.sweep(0.7, 6500 if dark else 8000, 1500 if dark else 2400, 0.5, 0.15, 1.6))]
    ev += fx.dust(0.02, 0.85, 12 if dark else 16, ["E7", "G7", "A7", "C8"] if dark else ["G7", "A7", "C8", "D8", "E8"], 0.16 if dark else 0.2)
    write(f"{o}/lock-break.wav", level(fx, fx.render(1.3, ev, 0.2, fc), ref, -3))

def build():
    drop("dark")
    star("light")
    sun("light")
    for w in WORLDS:
        sounds(w)
