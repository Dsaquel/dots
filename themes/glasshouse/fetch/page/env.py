import json
import os
from pathlib import Path

HOME = Path.home()
CACHE = Path(os.environ.get("XDG_CACHE_HOME") or HOME / ".cache")
HOUSE = Path(os.environ.get("GLASSHOUSE_HOUSE") or CACHE / "glasshouse")
SPRITES = Path(os.environ.get("GLASSHOUSE_FETCH_SPRITES") or HOUSE / "fetch")
RUNTIME = Path(os.environ.get("XDG_RUNTIME_DIR") or "/tmp")
CHOICE = Path(os.environ.get("XDG_CONFIG_HOME") or HOME / ".config") / "glasshouse/fetch-page"
PAGES = ("grimoire", "vitrail", "astrolabe")


def world():
    forced = os.environ.get("GLASSHOUSE_FETCH_WORLD")
    if forced in ("dark", "light"):
        return forced
    current = CACHE / "theme-switch/current"
    return "dark" if current.exists() and current.read_text().strip() == "dark" else "light"


def read_json(path, default=None):
    try:
        return json.loads(Path(path).read_text())
    except (OSError, ValueError):
        return default


def safe(read, fallback):
    try:
        return read()
    except Exception:
        return fallback


LATLON = safe(lambda: tuple(float(x) for x in os.environ["GLASSHOUSE_LATLON"].split(",", 1)) if "," in os.environ.get("GLASSHOUSE_LATLON", "") else None, None)
