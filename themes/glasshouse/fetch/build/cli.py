import json
import shutil
import sys
import tempfile
from pathlib import Path

from ..page.compose import SPRITE_VERSION
from ..page.env import SPRITES
from ..page.facts import PLANETS
from ..page.layout.astrolabe import ASTROLABE
from ..page.layout.grimoire import GRIMOIRE
from ..page.layout.vitrail import VITRAIL
from .art.astrolabe import astrolabe_art
from .art.canvas import save
from .art.grimoire import grimoire_art
from .art.roundel import moon_disc, planet_disc, roundel
from .art.vitrail import vitrail_art
from .dial import dial
from .her import her, sources
from .video import PACK

WORLDS = ("dark", "light")


def pages(world, cw, ch, out, her):
    made = {"vitrail": vitrail_art(world, cw, ch, out, VITRAIL, her), "grimoire": grimoire_art(world, cw, ch, out, GRIMOIRE, her),
            "astrolabe": astrolabe_art(world, cw, ch, out, ASTROLABE, her)}
    for k in range(28):
        save(roundel(56, world, moon_disc(world, k / 28)), out / f"moon-{k:02d}.png")
        save(roundel(112, world, moon_disc(world, k / 28)), out / f"bigmoon-{k:02d}.png")
    for k, (glyph, _, _) in enumerate(PLANETS):
        save(roundel(56, world, planet_disc(world, glyph)), out / f"planet-{k}.png")
    return made


def build(world, cw, ch):
    _, parts, still = sources(world)
    if not parts and not still:
        print(f"glasshouse-fetch-build: no {world} clips or stills in {PACK / 'fetch'}, skipped", file=sys.stderr)
        return
    missing = [t for t in ("ffmpeg", "ffprobe") if parts and not shutil.which(t)]
    if missing:
        sys.exit(f"glasshouse-fetch-build: {', '.join(missing)} not found")
    out = SPRITES / f"{world}-{cw}x{ch}"
    tmp = Path(tempfile.mkdtemp(prefix=f".{world}-", dir=SPRITES))
    try:
        she, maps = her(world, cw, ch, tmp)
        made = pages(world, cw, ch, tmp, she)
        made["astrolabe"].update({"her": v for v in [dial(world, cw, ch, tmp, she, maps, made["astrolabe"])] if v})
        meta = {"version": SPRITE_VERSION, "world": world, "cell": [cw, ch], "her": she, "pages": made}
        (tmp / "sprites.json").write_text(json.dumps(meta, indent=1))
    except BaseException:
        shutil.rmtree(tmp, ignore_errors=True)
        raise
    shutil.rmtree(out, ignore_errors=True)
    tmp.rename(out)
    print(out)


def main():
    args = sys.argv[1:]
    cell = next((a.split("=", 1)[1] for a in args if a.startswith("--cell=")), "10x20")
    cw, ch = (int(v) for v in cell.split("x"))
    worlds = [a for a in args if a in WORLDS] or (list(WORLDS) if "both" in args or not args or all(a.startswith("--") for a in args) else [])
    SPRITES.mkdir(parents=True, exist_ok=True)
    for w in worlds:
        build(w, cw, ch)
