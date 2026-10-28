from .env import SPRITES, read_json
from .layout.astrolabe import astrolabe_layout
from .layout.grimoire import grimoire_layout
from .layout.listing import list_layout
from .layout.vitrail import vitrail_layout

SPRITE_VERSION = 18

LAYOUTS = {"vitrail": vitrail_layout, "grimoire": grimoire_layout, "astrolabe": astrolabe_layout, "list": list_layout}


def sprites_for(w, cw, ch):
    d = SPRITES / f"{w}-{cw}x{ch}"
    meta = read_json(d / "sprites.json")
    return (d, meta) if meta and meta.get("version") == SPRITE_VERSION and (d / meta["her"]["still"][0]).exists() else (d, None)


def compose(F, cols, lines, cw, ch, meta, page):
    lay = LAYOUTS.get(page if meta and page in (meta.get("pages") or {}) else "list")(F, cw, ch, meta)
    if lay["name"] != "list" and (cols < lay["width"] + 2 or lines < lay["height"] + 2):
        lay = list_layout(F)
    lay.update(pad=0, her=None)
    floor = ((meta or {}).get("pages", {}).get(lay["name"]) or {}).get("floor")
    if not floor:
        return lay
    her = her_of(meta, lay["name"])
    panel = next(im for im in lay["images"] if im["name"] == floor["panel"])
    x0, _, x1, feet = her["fig"]
    ground = panel["row"] * ch + floor["y"]
    left = panel["col"] * cw + floor["x"] - x0
    pad = max(0, -((ground - feet) // ch))
    if cols < -(-max(panel["col"] * cw + floor["w"], left + x1) // cw) + 2 or lines < lay["height"] + pad + 2:
        return lay
    for t in lay["texts"] + [im for im in lay["images"] if "row" in im]:
        t["row"] += pad
    panel["name"] = floor["file"]
    lay.update(pad=pad, height=lay["height"] + pad)
    lay["her"] = {"x": left, "y": ground + pad * ch - feet, "still": her["still"]}
    return lay


def her_of(meta, page):
    return (meta["pages"].get(page) or {}).get("her") or meta["her"]
