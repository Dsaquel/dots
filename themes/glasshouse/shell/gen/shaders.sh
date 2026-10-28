#!/usr/bin/env bash
set -euo pipefail
if [ -z "${QSB:-}" ]; then
    for QSB in "$(command -v qsb || true)" /usr/lib/qt6/bin/qsb /usr/lib64/qt6/bin/qsb /usr/lib/qt6/libexec/qsb; do [ -x "$QSB" ] && break; done
fi
[ -x "$QSB" ] || { echo "shaders.sh: qsb not found (install Qt 6 Shader Tools or set QSB)" >&2; exit 1; }
files=()
for f in "$@"; do
    [ -f "$f" ] || { echo "shaders.sh: no such file: $f" >&2; exit 1; }
    files+=("$(realpath -s "$f")")
done
cd "$(dirname "$0")/../shaders"
[ ${#files[@]} -eq 0 ] && files=(*.frag *.vert ../parts/Turn/shaders/{blur,clap_post,win}.frag)
for f in "${files[@]}"; do
    [ -f "$f" ] || continue
    "$QSB" --glsl "100 es,120,150,330" --hlsl 50 --msl 12 -o "$f.qsb" "$f"
done
