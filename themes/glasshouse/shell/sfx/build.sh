#!/bin/sh
set -e
src="$(dirname "$(readlink -f "$0")")/ghsfx.c"
out="${1:-${XDG_CACHE_HOME:-$HOME/.cache}/glasshouse/ghsfx}"
mkdir -p "$(dirname "$out")"
[ "$out" -nt "$src" ] && exit 0
cc -O2 -o "$out.new" "$src" $(pkg-config --cflags --libs libpipewire-0.3)
mv -f "$out.new" "$out"
