import unicodedata


def cells(text):
    return sum(0 if unicodedata.combining(c) else 2 if unicodedata.east_asian_width(c) in "WF" else 1 for c in text)


def fit(spans, width):
    out, used = [], 0
    for text, style in spans:
        room = width - used
        if room <= 0:
            break
        if cells(text) <= room:
            out.append((text, style))
            used += cells(text)
            continue
        cut = ""
        for c in text:
            if cells(cut + c) > room - 1:
                break
            cut += c
        out.append((cut.rstrip() + "…", style))
        break
    return out


def text_end(t):
    return t["col"] + min(t["w"], sum(cells(s) * (2 if st.startswith("s2") else 1) for s, st in fit_spans(t)))


def fit_spans(t):
    return t["spans"] if t.get("tall") else fit(t["spans"], t["w"])
