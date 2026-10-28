import json
import os
import subprocess
from pathlib import Path

import numpy as np

FPS = 24
PACK = Path(os.environ.get("GLASSHOUSE_PACK") or Path.home() / ".local/share/glasshouse")
CLIP = os.environ.get("GLASSHOUSE_FETCH_CLIP", "reel8")


def probe(path):
    s = json.loads(subprocess.run(["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries", "stream=width,height", "-of", "json", str(path)],
                                  capture_output=True, text=True, check=True).stdout)["streams"][0]
    return s["width"], s["height"]


def decode(path, size=None, gray=False, tail=None):
    w, h = size or probe(path)
    raw = subprocess.run(["ffmpeg", "-v", "error", *(["-sseof", str(-tail)] if tail else []), "-i", str(path),
                          "-vf", f"fps={FPS}" + (f",scale={w}:{h}:flags={"area" if gray else "lanczos"}" if size else ""), "-f", "rawvideo",
                          "-pix_fmt", "gray" if gray else "rgb24", "-"], capture_output=True, check=True).stdout
    return np.frombuffer(raw, np.uint8).reshape(-1, h, w, *([] if gray else [3]))
