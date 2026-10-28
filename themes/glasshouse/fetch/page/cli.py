import json
import os
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path

from .compose import compose, her_of, sprites_for
from .env import CHOICE, HOUSE, PAGES, RUNTIME, SPRITES, read_json, world
from .facts import facts
from .house import agents
from .place import page_writes
from .plain import plain, plain_text
from .play import Show, fits
from .system import join_fastfetch, start_fastfetch
from .term import graphics_ok, release, reserve, size, write

BUILDER = Path(__file__).resolve().parents[2] / "bin/glasshouse-fetch-build"


def first_of_session():
    mark = RUNTIME / f"glasshouse-fetch.{os.environ.get("HYPRLAND_INSTANCE_SIGNATURE", "plain")[-24:]}"
    try:
        os.close(os.open(mark, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600))
        return True
    except OSError:
        return False


def kick_builder(w, cw, ch):
    stamp = SPRITES / f".tried-{w}-{cw}x{ch}"
    if not BUILDER.exists() or (stamp.exists() and time.time() - stamp.stat().st_mtime < 86400):
        return
    SPRITES.mkdir(parents=True, exist_ok=True)
    stamp.touch()
    subprocess.Popen(["nice", "-n", "19", "python3", str(BUILDER), w, f"--cell={cw}x{ch}"], stdin=subprocess.DEVNULL,
                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)


def chosen_page(argv):
    picked = next((a for a in argv if a in PAGES), None)
    if picked and "--page" in argv:
        CHOICE.parent.mkdir(parents=True, exist_ok=True)
        CHOICE.write_text(picked + "\n")
    saved = CHOICE.read_text().strip() if CHOICE.exists() else ""
    return picked or os.environ.get("GLASSHOUSE_FETCH_PAGE") or (saved if saved in PAGES else PAGES[0])


def main():
    args = set(sys.argv[1:])
    w, now = world(), datetime.now()
    proc = start_fastfetch()
    cols, lines, cw, ch = size()
    live, settings = agents(), read_json(HOUSE / "settings.json", {}) or {}
    f = join_fastfetch(proc)
    F = facts(f, w, now, live, settings)
    if "--plain" in args or not sys.stdout.isatty():
        write(plain_text(F))
        return
    if cols < 44:
        return
    gfx = graphics_ok() and "--text" not in args and cw > 0 and ch > 0
    sprite_dir, meta = sprites_for(w, cw, ch) if gfx else (None, None)
    if gfx and not meta:
        kick_builder(w, cw, ch)
    lay = compose(F, cols, lines, cw, ch, meta, chosen_page(sys.argv[1:]))
    if "--layout" in args:
        write(json.dumps({"world": w, "cols": cols, "lines": lines, "cell": [cw, ch], "layout": lay, "plain": plain(f)},
                         ensure_ascii=False, indent=1) + "\n")
        return
    play = (bool(meta) and lay["her"] and her_of(meta, lay["name"])["frames"] and fits(lay, her_of(meta, lay["name"]), cols, lines, cw, ch)
            and ("--replay" in args or ("--static" not in args and first_of_session())))
    if play:
        Show(lay, sprite_dir, meta).run()
        return
    write(reserve(lay["height"]) + "".join(page_writes(lay, sprite_dir if meta else None, cw, ch)) + release(lay["height"]))


def run():
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(130)
