import glob
import os

import cairo
import numpy as np
from PIL import Image

from kit import TAU, WORLDS, glow_of, out, save_height, save_rgba, straight_rgba

from .emblems import medal, week
from .gable import Gable
from .lights import drop, lights
from .raster import ctx
from .reliquary import Reliquary


DESIGN = {"light": Gable, "dark": Reliquary}


def build_side(world, side):
    o = out(world)
    d = DESIGN[world](side)
    bx, by, bw, bh = d.box
    arr = d.colours()
    save_rgba(arr, f"{o}/sanctum-wing-{side}.png")
    small = np.ascontiguousarray(np.asarray(Image.fromarray(arr, "RGBA").resize((bw, bh), Image.LANCZOS)))
    glow_of(small, 10, f"{o}/sanctum-wing-{side}-glow.png", 1.15)
    s, c = ctx(d.box, 1)
    spot = d.look["spot"]
    for fx, fy in d.spots():
        g = cairo.RadialGradient(fx, fy, 0, fx, fy, 15)
        g.add_color_stop_rgba(0, *spot, 0.55)
        g.add_color_stop_rgba(1, *spot, 0)
        c.set_source(g)
        c.arc(fx, fy, 15, 0, TAU)
        c.fill()
    glow_of(straight_rgba(s), 4, f"{o}/sanctum-wing-{side}-jewels-glow.png", 1.3)
    h, m = d.lead()
    save_height(h, m, f"{o}/sanctum-wing-{side}-lead.png")
    h, m = d.gilt()
    save_height(h, m, f"{o}/sanctum-wing-{side}-gilt.png")
    for f in glob.glob(f"{o}/sanctum-wing-{side}-hinge.png"):
        os.remove(f)
    lights(d, side, o)


def build(world=None):
    for w in ([world] if world else WORLDS):
        week(w)
        medal(w)
        for side in ("left", "right"):
            build_side(w, side)
            if w == "dark":
                drop(w, side)
