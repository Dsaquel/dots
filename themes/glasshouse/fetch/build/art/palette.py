import subprocess
import sys
from pathlib import Path

import numpy as np


def font(pattern):
    family = pattern.split(":")[0]
    found, _, path = subprocess.run(["fc-match", "-f", "%{family}\n%{file}", pattern], capture_output=True, text=True).stdout.partition("\n")
    if family not in found.split(","):
        sys.exit(f"glasshouse-fetch-build: font '{family}' not installed (fc-match gave '{found}')")
    return Path(path)


CARDO = font("Cardo:style=Regular")
CINZEL = font("Cinzel Decorative:style=Black")
DEJAVU = font("DejaVu Sans:style=Book")
LEAD = {"dark": dict(base="#3a3950", hi="#d6d3f2", low="#06070e", sky="#7d88ba", metal=0.7, shininess=30, depth=4.2),
        "light": dict(base="#caa36a", hi="#fff7e2", low="#4a2f1c", sky="#fbe3b0", metal=1.0, shininess=42, depth=5.0)}
GILT = dict(base="#c99a4e", hi="#fff4cf", low="#3b2410", sky="#f7dfa4", metal=1.0, shininess=42, depth=5.0)
JEWEL = {"dark": {"fire": "#e0668a", "water": "#5fb0e0", "earth": "#7cc9a0", "air": "#5fd0d0", "aether": "#a88ae8",
                  "rose": "#d9668f", "gold": "#f2b35e", "cyan": "#5fb4dc", "violet": "#8c73d6"},
         "light": {"fire": "#e2566b", "water": "#4aa8de", "earth": "#5cbf86", "air": "#4cc9c9", "aether": "#9a80e6",
                 "rose": "#e6488c", "gold": "#f7c76f", "cyan": "#61d1eb", "violet": "#9459cc"}}
GLASS = {"dark": {"top": "#1b2350", "bottom": "#10153a", "light": "#3b4f9a", "alpha": 0.93},
         "light": {"top": "#fff8e2", "bottom": "#f6e9c4", "light": "#fffdf2", "alpha": 0.96}}


def hexf(h):
    return np.array([int(h[i:i + 2], 16) for i in (1, 3, 5)], np.float32) / 255
