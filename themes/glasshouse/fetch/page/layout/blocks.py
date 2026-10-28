from ..spans import cells


def keyed(r, keyw=9):
    return [(r["glyph"] + "  ", r["style"]), (r["name"].ljust(keyw), r["style"])] + r["value"]


def text(tid, row, col, width, spans, src=(), tall=False):
    return {"id": tid, "row": row, "col": col, "w": width, "spans": spans, "from": list(src), "tall": tall}


def centred(tid, row, x0, width, spans, src=()):
    n = sum(cells(t) * (2 if s.startswith("s2") else 1) for t, s in spans)
    return text(tid, row, x0 + max(0, (width - n) // 2), width, spans, src, any(s.startswith("s2") for _, s in spans))


def stamp(F):
    return [(F["day"], "fg"), (" · ", "dim"), (F["date"], "fg"), (" · ", "dim"), (F["time"], "jewel"), (" · ", "dim"), (F["user"], "dim")]
