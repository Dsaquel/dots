import os

import numpy as np

from .cues import GLAZE, GLAZE_HIDE, GLAZE_SHOW, HOIST_SYNTH, MOVE, MOVE_SYNTH, MULLION_SYNTH, SLAM, STANDIN, STRIKE
from .dsp import blank, level, placed, put, read, write
from .fire import burn, move, whoosh
from .glass import extension, hoist, sanctuary
from .steel import deal, lightning, steel
from .takes import CAND

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "sounds")


def synth(world, cues, sec):
    mix = blank(sec)
    for name, t, g in cues:
        put(mix, read(os.path.join(OUT, world, f"{name}.wav")) * g, t)
    return mix


def effects():
    full, slam = steel()
    clock, struck = deal()
    shown, hidden = lightning()
    g = GLAZE
    beside, beside_at = extension()
    hoisted, hoisted_at = hoist()
    sand_ = move()
    open_, close = sanctuary()
    stones = [("sand-stone", t, 0.5 + 0.3 * j / len(MOVE["stones"])) for j, t in enumerate(MOVE["stones"])]
    moved = [("pyre-lift", 0, 1), ("pyre-flight", 0.18, 1), ("pyre-strike", MOVE["strike"], 1), ("sand-rebuild", MOVE["unframe"] + 0.2, 1), ("sand-boom", MOVE["boom"], 1)] + stones
    return [({"burn": burn()}, [("burn", 0, 1)], [("burn", 0, 1)], 1.4),
            ({"athanor": whoosh(), "athanor-pyre": whoosh(False)}, [("athanor", 0, 1)], [("athanor", 0, 1)], 1.4),
            ({"swap": full, "swap-slam": slam}, [("swap", 0, 1)], [("shatter", 0, 0.5), ("sluice", 0.15, 1), ("slam", SLAM, 1), ("strike", STRIKE, 0.4)], 1.8),
            ({"pivot": clock, "pivot-slam": struck}, [("pivot", 0, 1)], [("shatter", 0, 0.5), ("scrape", 0.15, 1), ("slam", SLAM, 1), ("strike", STRIKE, 0.4)], 2.2),
            (sand_, moved, MOVE_SYNTH, 3.4),
            (shown, [(f"scratch-row-{n}", t, 1) for n, t in enumerate(g["rows"], 1)] + [("scratch-slam", g["slam"] - g["pre"], 1), ("scratch-gild", g["gild"], 1)], GLAZE_SHOW, 1.4),
            (hidden, [("scratch-hide", 0, 1)], GLAZE_HIDE, 1.0),
            (beside, beside_at, MULLION_SYNTH, 2.0),
            (hoisted, hoisted_at, HOIST_SYNTH, 1.0),
            ({"sanctum-open": open_}, [("sanctum-open", 0, 1)], [("menu-open", 0, 1)], 2.2),
            ({"sanctum-close": close}, [("sanctum-close", 0, 1)], [("menu-close", 0, 1)], 1.0)]


def main():
    worlds = ("dark", "light")
    if not os.path.isdir(CAND):
        for world in worlds:
            for name, cues in STANDIN.items():
                write(os.path.join(OUT, world, f"{name}.wav"), synth(world, cues, 2.4))
        print(f"foley: no pack at {CAND}, synth stand-ins written")
        return
    report = []
    for stems, at, cues, sec in effects():
        mix = placed(stems, at, sec)
        for world in worlds:
            gain = 10 ** ((level(synth(world, cues, sec)) - level(mix)) / 20)
            for name, x in stems.items():
                write(os.path.join(OUT, world, f"{name}.wav"), x * gain)
            report.append(f"{world:5} {', '.join(stems):42} gain {20 * np.log10(gain):+5.1f} dB")
    print("\n".join(report))
