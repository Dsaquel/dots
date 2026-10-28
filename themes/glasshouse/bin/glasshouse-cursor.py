#!/usr/bin/env python3
import colorsys
import io
import os
import re
import shutil
import struct
import sys
import zipfile
from pathlib import Path

SRC = Path("/usr/share/icons/Bibata-Modern-Classic")
WORLDS = {
    "Rubedo-Dark": dict(fill=["#8aa6f2", "#4166cf", "#253f92"], line="#dcd8f5",
                        jewels=["#e0668a", "#f2b35e", "#5fd0d0", "#6f8cec", "#a88ae8"],
                        comment="cobalt glass, polished lead keyline"),
    "Rubedo-Light": dict(fill=["#fffdf6", "#f4efe6", "#e2d3b8"], line="#94692a",
                         jewels=["#cf3b4a", "#f3c14f", "#5fd3e6", "#7fb6ff", "#8a63da"],
                         comment="pearl, deep gilt keyline"),
}


def rgb(h):
    return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5))


def ramp(stops, t):
    t = min(max(t, 0.0), 1.0) * (len(stops) - 1)
    i = min(int(t), len(stops) - 2)
    a, b = rgb(stops[i]), rgb(stops[i + 1])
    return tuple(round(x + (y - x) * (t - i)) for x, y in zip(a, b))


def jewel(c, world):
    h, l, _ = colorsys.rgb_to_hls(*(x / 255 for x in c))
    deg = h * 360
    k = 0 if deg < 20 or deg >= 330 else 1 if deg < 70 else 2 if deg < 170 else 3 if deg < 260 else 4
    th, tl, ts = colorsys.rgb_to_hls(*(x / 255 for x in rgb(world["jewels"][k])))
    return tuple(round(x * 255) for x in colorsys.hls_to_rgb(th, l * 0.5 + tl * 0.5, ts))


def recolor_image(pixels, w, h, world):
    line = rgb(world["line"])
    out = []
    for n, argb in enumerate(pixels):
        a = argb >> 24
        if a == 0:
            out.append(argb)
            continue
        r, g, b = (((argb >> s) & 255) * 255 // a for s in (16, 8, 0))
        if max(r, g, b) - min(r, g, b) > 40:
            c = jewel((r, g, b), world)
            out.append((a << 24) | ((c[0] * a // 255) << 16) | ((c[1] * a // 255) << 8) | (c[2] * a // 255))
            continue
        lum = (0.299 * r + 0.587 * g + 0.114 * b) / 255
        y, x = divmod(n, w)
        body = ramp(world["fill"], (x + y) / max(1, w + h - 2) * 1.6 - 0.15)
        c = [round(body[i] + (line[i] - body[i]) * lum) for i in range(3)]
        out.append((a << 24) | ((c[0] * a // 255) << 16) | ((c[1] * a // 255) << 8) | (c[2] * a // 255))
    return out


def recolor_xcursor(data, world):
    _, _, _, ntoc = struct.unpack_from("<4sIII", data, 0)
    out = bytearray(data)
    for i in range(ntoc):
        kind, _, pos = struct.unpack_from("<III", data, 16 + i * 12)
        if kind != 0xFFFD0002:
            continue
        w, h = struct.unpack_from("<II", data, pos + 16)
        start = pos + 36
        pixels = struct.unpack_from(f"<{w * h}I", data, start)
        struct.pack_into(f"<{w * h}I", out, start, *recolor_image(pixels, w, h, world))
    return bytes(out)


def recolor_svg(text, world):
    stops = "".join(f'<stop offset="{i / (len(world["fill"]) - 1):.2f}" stop-color="{c}"/>' for i, c in enumerate(world["fill"]))
    grad = f'<defs><linearGradient id="glass" x1="0.1" y1="0.05" x2="0.8" y2="0.95">{stops}</linearGradient></defs>'
    text = re.sub(r'fill="#000000"', 'fill="url(#glass)"', text, flags=re.I)
    text = re.sub(r"#000000\b", world["fill"][-1], text, flags=re.I)
    text = re.sub(r"#FFFFFF\b", world["line"], text, flags=re.I)
    text = re.sub(r"#([0-9a-fA-F]{6})\b", lambda m: m.group(0) if m.group(0).lower() in
                  [c.lower() for c in world["fill"] + [world["line"]]] or max(rgb(m.group(0))) - min(rgb(m.group(0))) <= 40
                  else "#%02x%02x%02x" % jewel(rgb(m.group(0)), world), text)
    return re.sub(r"(<svg[^>]*>)", r"\1" + grad, text, count=1)


def recolor_hlc(path, world):
    buf = io.BytesIO()
    with zipfile.ZipFile(path) as src, zipfile.ZipFile(buf, "w", zipfile.ZIP_DEFLATED) as dst:
        for item in src.infolist():
            data = src.read(item)
            if item.filename.endswith(".svg"):
                data = recolor_svg(data.decode(), world).encode()
            dst.writestr(item, data)
    return buf.getvalue()


def build(root, name, world):
    dst = root / f".{name}.part"
    shutil.rmtree(dst, ignore_errors=True)
    (dst / "cursors").mkdir(parents=True)
    (dst / "hyprcursors").mkdir()
    for entry in sorted((SRC / "cursors").iterdir()):
        target = dst / "cursors" / entry.name
        if entry.is_symlink():
            os.symlink(os.readlink(entry), target)
        else:
            target.write_bytes(recolor_xcursor(entry.read_bytes(), world))
    for entry in sorted((SRC / "hyprcursors").iterdir()):
        (dst / "hyprcursors" / entry.name).write_bytes(recolor_hlc(entry, world))
    (dst / "index.theme").write_text(f"[Icon Theme]\nName={name}\nComment=Bibata Modern Classic, {world['comment']}\nInherits=hicolor\n")
    (dst / "manifest.hl").write_text(f"name = {name}\ndescription = Bibata Modern Classic, {world['comment']}\nversion = 0.1\ncursors_directory = hyprcursors\n")
    shutil.rmtree(root / name, ignore_errors=True)
    return dst.rename(root / name)


def main():
    if not SRC.is_dir():
        sys.exit(f"missing {SRC}: install bibata-cursor-theme first")
    root = Path(sys.argv[1]).expanduser() if len(sys.argv) > 1 else Path.home() / ".local/share/icons"
    for name, world in WORLDS.items():
        print("built", build(root, name, world))


if __name__ == "__main__":
    main()
