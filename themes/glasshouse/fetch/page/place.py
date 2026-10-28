from .kitty import IMG, apc, show
from .spans import fit_spans, text_end
from .style import draw
from .term import at


def page_writes(lay, sprite_dir, cw, ch):
    out = [at(t["row"], t["col"]) + draw(fit_spans(t)) for t in lay["texts"]]
    return out + (place_items(page_items(lay, cw, ch), sprite_dir) if sprite_dir else [])


def page_items(lay, cw, ch):
    items = []
    for k, im in enumerate(lay["images"]):
        row, y = divmod(round(im["py"]), ch) if "py" in im else (im["row"], im.get("y", 0))
        col, x = divmod(round(im["px"]), cw) if "px" in im else (im["col"], im.get("x", 0))
        items.append({"name": im["name"], "row": row + lay["pad"] * ("py" in im), "col": col, "x": x, "y": y, "z": im["z"],
                      "crop": im.get("crop"), "kind": "page"})
    by = {t["id"]: t for t in lay["texts"]}
    for tid in lay.get("fillers", []):
        start = text_end(by[tid]) + 1
        if lay["filler_end"] - start >= 3:
            items.append({"name": "filler.png", "row": by[tid]["row"], "col": start, "x": 0, "y": 0, "z": -1,
                          "crop": (0, 0, (lay["filler_end"] - start) * cw, ch), "kind": "page"})
    if lay["her"]:
        h = lay["her"]
        name, x, y = h["still"]
        (row, Y), (col, X) = divmod(h["y"] + y, ch), divmod(h["x"] + x, cw)
        items.append({"name": name, "row": row, "col": col, "x": X, "y": Y, "z": -2, "crop": None, "kind": "her"})
    return items


def place_items(items, sprite_dir, base=None):
    out, ids = [], {}
    for k, it in enumerate(items):
        crop = it.get("crop")
        src = f",x={crop[0]},y={crop[1]},w={crop[2]},h={crop[3]}" if crop else ""
        iid = IMG["her"] if it["kind"] == "her" else None
        if iid is None and it["name"] in ids:
            out.append(at(it["row"], it["col"]) + apc(f"a=p,i={ids[it["name"]]},p={k + 2},X={it["x"]},Y={it["y"]},z={it["z"]},C=1{src}"))
            continue
        if iid is None:
            iid = ids[it["name"]] = (base or IMG["page"]) + len(ids)
        out.append(show(iid, sprite_dir / it["name"], it["row"], it["col"], it["x"], it["y"], it["z"], crop))
    return out
