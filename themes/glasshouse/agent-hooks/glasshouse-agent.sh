#!/usr/bin/env bash

state="${1:-idle}"
input="$(timeout 0.3 cat 2>/dev/null)"
[ -z "$input" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

sid="$(jq -r '.session_id // empty' <<<"$input" 2>/dev/null)"
[[ "$sid" =~ ^[A-Za-z0-9_-]+$ ]] || exit 0
cwd="$(jq -r '.cwd // empty' <<<"$input" 2>/dev/null)"
detail="$(jq -r '.message // empty' <<<"$input" 2>/dev/null)"
dir="${GLASSHOUSE_AGENTS:-$HOME/.cache/glasshouse/agents}"
mkdir -p "$dir"

if [ "$state" = end ]; then
    rm -f "$dir/$sid.json"
elif [ "$state" = idle ] && jq -e '.state == "done"' "$dir/$sid.json" >/dev/null 2>&1; then
    :
else
    term=0
    p=$PPID
    for _ in $(seq 1 16); do
        [ -z "$p" ] || [ "$p" -le 1 ] && break
        [ "$(cat "/proc/$p/comm" 2>/dev/null)" = kitty ] && { term=$p; break; }
        p="$(awk '{print $4}' "/proc/$p/stat" 2>/dev/null)"
    done
    jq -nc --arg sid "$sid" --arg state "$state" --arg label "$(basename "${cwd:-claude}")" --arg cwd "$cwd" \
        --arg detail "$detail" --argjson pid "$term" \
        '{sid: $sid, state: $state, label: $label, cwd: $cwd, detail: $detail, pid: $pid, updated: (now * 1000 | floor)}' \
        > "$dir/.$sid.tmp" && mv "$dir/.$sid.tmp" "$dir/$sid.json"
fi
date +%s%N > "$dir/.stamp"
exit 0
