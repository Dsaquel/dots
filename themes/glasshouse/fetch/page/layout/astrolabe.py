import math

from .blocks import centred, keyed, text

ASTROLABE = {"x": 2, "disc": 44, "disc_rows": 22, "h": 23, "col": 48, "w": 62, "tube": 16}


def astrolabe_layout(F, cw=10, ch=20, meta=None):
    g = ASTROLABE
    x, col, w = g["x"], g["col"], g["w"]
    info = ((meta or {}).get("pages") or {}).get("astrolabe") or {"radius": g["disc_rows"] * ch / 2 - 4, "centre": [g["disc"] * cw / 2, g["disc_rows"] * ch / 2]}
    cx, cy = info["centre"]
    R = info["radius"]
    rows = F["rows"]
    texts = [centred("time", 9, x, g["disc"], [(F["time"], "s2|title")]),
             centred("date", 11, x, g["disc"], [(F["day"], "fg"), (" ", "dim"), (F["date"], "fg")], ["title"]),
             centred("sky", 13, x, g["disc"], rows["sky"]["value"][:3], rows["sky"]["from"]),
             centred("moon", 14, x, g["disc"], rows["moon"]["value"], rows["moon"]["from"]),
             text("title", 1, col, 20, [(F["title"], "s2|title")], tall=True),
             text("brand", 1, col + 22, w - 22, [("GLASSHOUSE", "dim"), (" · ", "dim"), (F["user"], "dim")]),
             text("names", 2, col + 22, w - 22, [(F["names"][1], "jewel"), (" · ", "dim"), (F["names"][0], "jewel")])]
    blocks = [(4, ["athanor", "letters", "awake"], w), (8, ["fire", "water", "earth", "air", "aether"], w - g["tube"] - 2),
              (14, ["mercury", "sulphur", "salt"], w)]
    for r, keys, width in blocks:
        texts += [text(k, r + i, col, width if k in ("fire", "water", "earth") else w, keyed(rows[k]), rows[k]["from"]) for i, k in enumerate(keys)]
    texts.append(text("her", 18, col, w, [("« " + F["her"] + " »", "her")]))
    images = [{"name": "astrolabe.png", "row": 0, "col": x, "z": -3},
              {"name": "astro-plate.png", "row": 0, "col": col - 2, "z": -3},
              {"name": f"bigmoon-{round(F["phase"] * 28) % 28:02d}.png", "px": x * cw + cx - 56, "py": cy - 172, "z": 1}]
    rise, fall = F["sun"]
    Rb = R * 0.895
    for h in range(24):
        phi = (h - 12) / 24 * math.tau
        day = rise <= h + 0.5 <= fall
        size = 12 if day else 10
        images.append({"name": "bead-day.png" if day else "bead-night.png", "z": 1,
                       "px": round(x * cw + cx + Rb * math.sin(phi) - size / 2), "py": round(cy - Rb * math.cos(phi) - size / 2)})
    phi = (F["hour"] - 12) / 24 * math.tau
    images.append({"name": "now-sun.png" if rise <= F["hour"] <= fall else "now-moon.png", "z": 2,
                   "px": round(x * cw + cx + Rb * math.sin(phi) - 15), "py": round(cy - Rb * math.cos(phi) - 15)})
    tube_x = (col + w - g["tube"]) * cw
    for i, key in enumerate(("fire", "water", "earth")):
        level = max(0.0, min(1.0, F["levels"][key]))
        py = (8 + i) * ch + (ch - 14) // 2
        images.append({"name": "tube-empty.png", "px": tube_x, "py": py, "z": 1})
        images.append({"name": f"tube-{key}.png", "px": tube_x, "py": py, "z": 2, "crop": (0, 0, max(8, round(8 + level * (g["tube"] * cw - 16))), 14)})
    return {"name": "astrolabe", "width": col + w + 2, "height": g["h"], "texts": texts, "images": images}
