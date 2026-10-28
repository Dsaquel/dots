from ..spans import cells
from .blocks import centred, keyed, text

GRIMOIRE = {"x": 2, "w": 70, "h": 25, "margin": 5, "initial": (0, 9, 9, 5), "rubrics": [6, 11, 18], "colophon": 23}


def grimoire_layout(F, cw=10, ch=20, meta=None):
    g = GRIMOIRE
    x, w = g["x"], g["w"]
    c0 = x + g["margin"] + 2
    tw = w - g["margin"] - 6
    r0, ic, iw, ih = g["initial"]
    rest = F["day"][1:]
    beside = ic + iw + 1
    texts = [text("day", 0, beside, 2 * cells(rest), [(rest, "s2|day")], tall=True),
             text("date", 1, beside + 2 * cells(rest) + 2, tw, [("the ", "dim"), (F["date"], "fg")]),
             text("title", 2, beside, x + w - beside - 3, [(F["title"], "title"), ("  glasshouse", "dim"), (" · ", "dim"),
                                                          (F["time"], "jewel"), (" · ", "dim"), (F["user"], "dim")], ["title"]),
             text("sky", 3, beside, x + w - beside - 3, keyed(F["rows"]["sky"], 7), F["rows"]["sky"]["from"]),
             text("moon", 4, beside, x + w - beside - 3, keyed(F["rows"]["moon"], 7), F["rows"]["moon"]["from"])]
    blocks = [("Of the Athanor", ["athanor", "letters", "awake"]), ("Of the Four Elements", ["fire", "water", "earth", "air", "aether"]),
              ("Of the Three Principles", ["mercury", "sulphur", "salt"])]
    for (title, keys), r in zip(blocks, g["rubrics"]):
        texts.append(text("rubric-" + keys[0], r, c0 + 3, tw - 3, [(title, "rubric")]))
        texts += [text(k, r + 1 + i, c0, tw, keyed(F["rows"][k]), F["rows"][k]["from"]) for i, k in enumerate(keys)]
    texts.append(centred("her", g["colophon"], c0, tw, [(F["her"], "her")]))
    images = [{"name": "grimoire.png", "row": 0, "col": x, "z": -3},
              {"name": f"initial-{F["day"][0]}.png", "row": r0, "col": ic, "z": 1}]
    fillers = [t["id"] for t in texts if t["id"] in F["rows"] and t["row"] > 5]
    return {"name": "grimoire", "width": x + w, "height": g["h"], "texts": texts, "images": images, "fillers": fillers,
            "filler_end": c0 + tw}
