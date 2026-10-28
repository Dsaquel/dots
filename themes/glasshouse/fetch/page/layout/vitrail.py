from ..facts import PLANETS
from .blocks import centred, keyed, stamp, text

VITRAIL = {"x": 2, "w": 68, "h": 24, "sky": 5, "elements": 11, "principles": 17, "bars": [4, 10, 16, 20], "ribbon": 21, "sill": 23}


def vitrail_layout(F, cw=10, ch=20, meta=None):
    g = VITRAIL
    x, w = g["x"], g["w"]
    c0, cw_ = x + 4, w - 8
    texts = [centred("title", 1, x, w, [(F["title"], "s2|title")]), centred("date", 3, x, w, stamp(F), ["title"])]
    groups = [("sky", ["sky", "moon", "athanor", "letters", "awake"]), ("elements", ["fire", "water", "earth", "air", "aether"]),
              ("principles", ["mercury", "sulphur", "salt"])]
    texts += [text(k, g[band] + i, c0, cw_, keyed(F["rows"][k]), F["rows"][k]["from"]) for band, keys in groups for i, k in enumerate(keys)]
    texts += [centred("plaque-elements", g["bars"][1], x, w, [("THE FOUR ELEMENTS", "plaque")]),
              centred("plaque-principles", g["bars"][2], x, w, [("THE THREE PRINCIPLES", "plaque")]),
              centred("her", g["ribbon"], x, w, [(F["her"], "ribbon")])]
    images = [{"name": "vitrail.png", "row": 0, "col": x, "z": -3},
              {"name": f"moon-{round(F["phase"] * 28) % 28:02d}.png", "row": 0, "col": x + 7, "y": 2, "z": 1},
              {"name": f"planet-{PLANETS.index(F["planet"])}.png", "row": 0, "col": x + w - 12, "y": 2, "z": 1}]
    return {"name": "vitrail", "width": x + w, "height": g["h"], "texts": texts, "images": images}
