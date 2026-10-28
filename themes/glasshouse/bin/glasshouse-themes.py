#!/usr/bin/env python3
import re
import shutil
import sys
from pathlib import Path

GTK = Path("/usr/share/themes")
KVANTUM = Path("/usr/share/Kvantum")

WORLDS = {
    "Rubedo-Dark": dict(
        gtk="catppuccin-mocha-blue-standard+default", kvantum="catppuccin-mocha-blue", icons="Papirus-Dark",
        select=("#314083", "#f1e8dc"), iconsel="alpha(#8aa6f2, 0.32)", icontint="#e7e4f5",
        map={
            "f5e0dc": "f1e8dc", "f2cdcd": "eab8c8", "f5c2e7": "e08ab0", "cba6f7": "a88ae8", "f38ba8": "e0668a",
            "eba0ac": "f07fa0", "fab387": "f2b35e", "f9e2af": "e2c58f", "a6e3a1": "7cc9a0", "94e2d5": "5fd0d0",
            "89dceb": "86d3e2", "74c7ec": "7ec4ee", "89b4fa": "6f8cec", "b4befe": "bea2f2", "cdd6f4": "e7e4f5",
            "bac2de": "c9c3d8", "a6adc8": "9aa4bd", "9399b2": "7d88ba", "7f849c": "6b72a3", "6c7086": "555b8a",
            "585b70": "3a4166", "45475a": "2b3254", "313244": "222a4c", "1e1e2e": "161b38", "181825": "121733",
            "11111b": "0f1226", "eff1f5": "e7e4f5", "393947": "2a3155", "282938": "1b2142", "97bbf9": "8aa3f0",
            "7ea5e6": "5f7ee0",
        }),
    "Rubedo-Light": dict(
        gtk="catppuccin-latte-pink-standard+default", kvantum="catppuccin-latte-pink", icons="Papirus-Light",
        select=("#fdcf6f", "#211b33"), iconsel="#fdcf6f", icontint="#fdcf6f",
        map={
            "dc8a78": "b8466e", "dd7878": "9c3d64", "ea76cb": "cb326e", "8839ef": "6450c4", "d20f39": "cb3747",
            "e64553": "b8405e", "fe640b": "996400", "df8e1d": "996400", "40a02b": "207f53", "179299": "007d7d",
            "04a5e5": "0076a7", "209fb5": "0068a0", "1e66f5": "0076a7", "7287fd": "745fca", "4c4f69": "211b33",
            "5c5f77": "3d3552", "6c6f85": "5b5570", "7c7f93": "6e6886", "8c8fa1": "8c86a0", "9ca0b0": "a39dae",
            "acb0be": "c9bd88", "bcc0cc": "e3d49a", "ccd0da": "f4e8b2", "eff1f5": "fdf8cd", "e6e9ef": "f8f0c4",
            "dce0e8": "f1e6b2", "d2d4d8": "e9dca5", "11111b": "211b33", "ca6eb7": "a8327f", "ea83cf": "d9488a",
        }),
}

HEX = re.compile(r"#([0-9a-fA-F]{6})([0-9a-fA-F]{2})?\b")
RGBA = re.compile(r"rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*(,\s*[\d.]+\s*)?\)")


def rgb(h):
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def recolour(table):
    keys = [(rgb(k), rgb(v)) for k, v in table.items()]

    def move(c):
        src, dst = min(keys, key=lambda kv: sum((a - b) ** 2 for a, b in zip(kv[0], c)))
        d = sum((a - b) ** 2 for a, b in zip(src, c)) ** .5
        if d > 72:
            return c
        return tuple(max(0, min(255, b + (x - a))) for x, a, b in zip(c, src, dst))
    return move


def rewrite(text, move):
    text = HEX.sub(lambda m: "#%02x%02x%02x" % move(rgb(m.group(1))) + (m.group(2) or ""), text)
    return RGBA.sub(lambda m: ("rgba(%d, %d, %d%s)" if m.group(4) else "rgb(%d, %d, %d%s)")
                    % (*move(tuple(int(m.group(i)) for i in (1, 2, 3))), m.group(4) or ""), text)


def selection_css(bg, fg, iconsel, icontint):
    named = "".join(f"@define-color {n} {c};\n" for n, c in (
        ("theme_selected_bg_color", bg), ("theme_selected_fg_color", fg),
        ("theme_unfocused_selected_bg_color", bg), ("theme_unfocused_selected_fg_color", fg)))
    icons = ".view:selected, iconview:selected, flowbox flowboxchild:selected"
    rows = ("treeview.view:selected, row:selected, list row:selected, placessidebar.sidebar row:selected, "
            "stacksidebar.sidebar row:selected, columnview row:selected, listview row:selected")
    text = "selection, *:selected selection, entry selection, label selection, textview text selection"
    return (f"\n/* rubedo selection */\n{named}"
            f"{icons} {{ background-color: {iconsel}; color: {fg}; }}\n"
            f".thunar .view:active {{ background-color: {icontint}; }}\n"
            f"{rows} {{ background-color: {bg}; color: {fg}; }}\n"
            f"row:selected label, row:selected image {{ color: {fg}; }}\n"
            f"{text} {{ background-color: {bg}; color: {fg}; }}\n")


def build(root, name, w):
    move = recolour(w["map"])
    out = root / f".{name}.part"
    shutil.rmtree(out, ignore_errors=True)
    src = GTK / w["gtk"]
    for part in ("gtk-3.0", "gtk-4.0"):
        shutil.copytree(src / part, out / part)
        for f in (out / part).rglob("*"):
            if f.suffix in (".css", ".svg"):
                text = rewrite(f.read_text(), move)
                if f.suffix == ".css":
                    text += selection_css(*w["select"], w["iconsel"], w["icontint"])
                f.write_text(text)
    (out / "index.theme").write_text(
        "[Desktop Entry]\nType=X-GNOME-Metatheme\n"
        f"Name={name}\nComment=RUBEDO {name.split('-')[1].upper()}, recoloured from {w['gtk']}\nEncoding=UTF-8\n\n"
        f"[X-GNOME-Metatheme]\nGtkTheme={name}\nIconTheme={w['icons']}\n")
    kv = out / "Kvantum"
    kv.mkdir()
    for ext in ("kvconfig", "svg"):
        text = rewrite((KVANTUM / w["kvantum"] / f"{w['kvantum']}.{ext}").read_text(), move)
        if ext == "kvconfig":
            bg, fg = w["select"]
            text, n = re.subn(r"(?m)^highlight\.color=.*$", f"highlight.color={bg}", text)
            text, m = re.subn(r"(?m)^highlight\.text\.color=.*$", f"highlight.text.color={fg}", text)
            assert n == 1 and m == 1, "kvantum highlight keys"
        (kv / f"{name}.{ext}").write_text(text)
    shutil.rmtree(root / name, ignore_errors=True)
    return out.rename(root / name)


def main():
    root = Path(sys.argv[1]).expanduser() if len(sys.argv) > 1 else Path.home() / ".themes"
    root.mkdir(parents=True, exist_ok=True)
    for name, w in WORLDS.items():
        print("built", build(root, name, w))


if __name__ == "__main__":
    main()
