import json
import os

from kit import A, WORLDS

from . import frame, handle, potions, rose, trim
from .layout import layouts


def build():
    L = layouts()
    for world in WORLDS:
        for kind, Lk in L.items():
            frame.frame(world, Lk, f"lancet-{kind}")
            rose.rose(world, Lk, f"lancet-{kind}-rose")
            handle.handle(world, Lk, f"lancet-{kind}-handle")
        trim.glints(world)
        trim.tip(world)
        trim.jewel(world)
        trim.seal(world)
    os.makedirs(f"{A}/shared", exist_ok=True)
    trim.shadow()
    json.dump(L, open(f"{A}/shared/lancet.json", "w"), indent=1)
    potions.potions()
