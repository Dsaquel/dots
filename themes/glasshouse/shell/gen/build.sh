#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")/.."
for font in "Noto Sans Symbols" "Noto Sans Symbols 2" "Cinzel"; do
    [[ ",$(fc-match -f '%{family}' "$font")," == *",$font,"* ]] || { echo "glasshouse build: font '$font' not installed" >&2; exit 1; }
done
command -v ffmpeg >/dev/null || { echo "glasshouse build: ffmpeg not found" >&2; exit 1; }
python3 gen/sfx.py
PYTHONPATH=gen python3 -m foley_sfx
PYTHONPATH=gen python3 -m phial_sfx
PYTHONPATH=gen python3 -m cutter_sfx
python3 gen/art.py
gen/turn/build.sh
PYTHONPATH=gen python3 -m turn_sfx
gen/shaders.sh
