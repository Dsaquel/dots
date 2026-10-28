#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
export GH_TURN_TMP=${GH_TURN_TMP:-${XDG_RUNTIME_DIR:-/tmp}/glasshouse-gen-turn-$UID}
mkdir -p -m 700 "$GH_TURN_TMP"
mkdir -p ../../assets/turn
PY=${GH_PY:-python3}
SCIPY=${GH_SCIPY_PY:-$PY}
$PY rose.py
$PY anime_fracture.py
$SCIPY crackmap.py anime
$PY sparks.py anime
