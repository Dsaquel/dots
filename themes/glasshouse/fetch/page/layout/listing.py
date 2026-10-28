from .blocks import keyed, stamp, text


def list_layout(F, cw=10, ch=20, meta=None):
    w = 76
    order = ["sky", "moon", "athanor", "letters", "awake", None, "fire", "water", "earth", "air", "aether", None, "mercury", "sulphur", "salt"]
    texts = [text("title", 0, 2, 20, [(F["title"], "s2|title")], tall=True),
             text("brand", 0, 24, w - 22, [("GLASSHOUSE", "dim")]),
             text("names", 1, 24, w - 22, [(F["names"][1], "jewel"), (" · ", "dim"), (F["names"][0], "jewel")]),
             text("date", 2, 2, w, stamp(F), ["title"])]
    texts += [text(k, 4 + i, 2, w, keyed(F["rows"][k]), F["rows"][k]["from"]) for i, k in enumerate(order) if k]
    texts.append(text("her", 4 + len(order) + 1, 2, w, [("« " + F["her"] + " »", "her")]))
    return {"name": "list", "width": w + 2, "height": 4 + len(order) + 2, "texts": texts, "images": []}
