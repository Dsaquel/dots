import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
SHEET = os.path.join(ROOT, "parts", "Turn", "cues.json")
OUT = os.path.join(ROOT, "sounds", "turn")
FOLEY = os.path.join(os.environ.get("GLASSHOUSE_PACK") or os.path.expanduser("~/.local/share/glasshouse"), "foley", "turn")
