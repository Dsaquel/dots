#!/usr/bin/env bash

set -Eeuo pipefail

HYPR_DIR="${HOME}/.config/hypr"
HYPR_THEMES="${HYPR_DIR}/themes"
KITTY_DIR="${HOME}/.config/kitty"
GTK3_INI="${HOME}/.config/gtk-3.0/settings.ini"
GTK4_INI="${HOME}/.config/gtk-4.0/settings.ini"
KVANTUM_CFG="${HOME}/.config/Kvantum/kvantum.kvconfig"
STATE_DIR="${HOME}/.cache/theme-switch"
BTOP_DIR="${HOME}/.config/btop"
BTOP_CONF="${BTOP_DIR}/btop.conf"
HYPRLOCK_ACTIVE="${HYPR_DIR}/hyprlock-active.conf"
LAZYGIT_DIR="${HOME}/.config/lazygit"
LAZYGIT_CFG="${LAZYGIT_DIR}/config.yml"
CLAUDE_SETTINGS="${HOME}/.claude/settings.json"
XSETTINGSD_CFG="${HOME}/.config/xsettingsd/xsettingsd.conf"
BAT_DIR="${HOME}/.config/bat"
BAT_CFG="${BAT_DIR}/config"
QT6CT_CFG="${HOME}/.config/qt6ct/qt6ct.conf"
GLASSHOUSE_ART="${HOME}/.local/share/glasshouse"
STATE_FILE="${STATE_DIR}/current"
LOG_FILE="${XDG_RUNTIME_DIR:-${STATE_DIR}}/theme-switch.log"

mkdir -p "${STATE_DIR}"
exec 9>"${STATE_DIR}/lock"
flock -w 15 9 || { echo "[FATAL] another theme switch still holds ${STATE_DIR}/lock after 15 s" >&2; exit 1; }
exec > >(tee "${LOG_FILE}") 2>&1

PREVIOUS="$(cat "${STATE_FILE}" 2>/dev/null || echo light)"
MUTABLE=(
    "${HYPR_THEMES}/active.lua"
    "${KITTY_DIR}/theme-active.conf"
    "${LAZYGIT_CFG}"
    "${GTK3_INI}"
    "${GTK4_INI}"
    "${KVANTUM_CFG}"
    "${BTOP_CONF}"
    "${HYPRLOCK_ACTIVE}"
    "${CLAUDE_SETTINGS}"
    "${XSETTINGSD_CFG}"
    "${BAT_CFG}"
    "${QT6CT_CFG}"
)
SNAPSHOT_DIR="$(mktemp -d)"
trap 'rm -rf "${SNAPSHOT_DIR}"' EXIT
for i in "${!MUTABLE[@]}"; do
    if [ -e "${MUTABLE[$i]}" ]; then
        cp -p "${MUTABLE[$i]}" "${SNAPSHOT_DIR}/${i}"
    else
        touch "${SNAPSHOT_DIR}/${i}.absent"
    fi
done

# -t: newest instance; dead same-boot instance dirs sort first and give a stale log
hypr_log() {
    local own="/run/user/$(id -u)/hypr/${HYPRLAND_INSTANCE_SIGNATURE:-}/hyprland.log"
    if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && [ -f "${own}" ]; then
        echo "${own}"
        return
    fi
    ls -t /run/user/$(id -u)/hypr/*/hyprland.log 2>/dev/null | head -1 || true
}
gtk_name() {
    case "$1" in
        light) [ -d "${HOME}/.themes/Rubedo-Light" ] && echo Rubedo-Light || echo "catppuccin-latte-pink-standard+default" ;;
        *)       [ -d "${HOME}/.themes/Rubedo-Dark" ] && echo Rubedo-Dark || echo "catppuccin-mocha-blue-standard+default" ;;
    esac
}
cursor_name() {
    case "$1" in
        light) [ -d "${HOME}/.local/share/icons/Rubedo-Light" ] && echo Rubedo-Light && return ;;
        *)       [ -d "${HOME}/.local/share/icons/Rubedo-Dark" ] && echo Rubedo-Dark && return ;;
    esac
    echo Adwaita
}
put() {
    local dst
    dst="$(readlink -f "$2")"
    if [ -e "${dst}" ]; then chmod --reference="${dst}" "$1"; else chmod =rw "$1"; fi
    mv "$1" "${dst}"
}
HYPR_LOG_BEFORE_LINES=0
if HL="$(hypr_log)"; then
    [ -n "$HL" ] && HYPR_LOG_BEFORE_LINES=$(wc -l < "$HL" 2>/dev/null || echo 0)
fi

rollback() {
    trap - ERR
    set +e
    trap '' INT TERM
    [ "${BASHPID}" = "$$" ] || exit 1
    echo "[FAIL] error during switch — reverting to ${PREVIOUS}"
    local i failed=()
    for i in "${!MUTABLE[@]}"; do
        if [ -f "${SNAPSHOT_DIR}/${i}" ]; then
            cp -p "${SNAPSHOT_DIR}/${i}" "${MUTABLE[$i]}" || failed+=("${MUTABLE[$i]}")
        elif [ -f "${SNAPSHOT_DIR}/${i}.absent" ]; then
            rm -f "${MUTABLE[$i]}" || failed+=("${MUTABLE[$i]}")
        else
            failed+=("${MUTABLE[$i]}")
        fi
    done
    pkill -x xsettingsd 2>/dev/null || true
    xsettingsd >/dev/null 2>&1 9>&- &
    mkdir -p "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}" 2>/dev/null || true
    echo "${PREVIOUS}" > "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/nvim-flavour" 2>/dev/null || true
    if [ "${PREVIOUS}" = "light" ]; then
        gsettings set org.gnome.desktop.interface color-scheme prefer-light 2>/dev/null || true
        gsettings set org.gnome.desktop.interface gtk-theme  "$(gtk_name light)" 2>/dev/null || true
        gsettings set org.gnome.desktop.interface icon-theme "Papirus-Light" 2>/dev/null || true
        gsettings set org.gnome.desktop.interface accent-color pink 2>/dev/null || true
    else
        gsettings set org.gnome.desktop.interface color-scheme prefer-dark  2>/dev/null || true
        gsettings set org.gnome.desktop.interface gtk-theme  "$(gtk_name dark)" 2>/dev/null || true
        gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark" 2>/dev/null || true
        gsettings set org.gnome.desktop.interface accent-color blue 2>/dev/null || true
    fi
    gsettings set org.gnome.desktop.interface cursor-theme "$(cursor_name "${PREVIOUS}")" 2>/dev/null || true
    hyprctl reload 2>/dev/null || true
    hyprctl eval "hl.env(\"GTK_THEME\", \"$(gtk_name "${PREVIOUS}")\")" >/dev/null 2>&1 || true
    hyprctl setcursor "$(cursor_name "${PREVIOUS}")" 24 >/dev/null 2>&1 || true
    pkill -SIGUSR1 -x kitty 2>/dev/null || true
    pkill -SIGUSR2 -x btop 2>/dev/null || true
    if [ ${#failed[@]} -eq 0 ]; then
        notify-send -a "the house" -u critical "Theme switch FAILED" "Reverted to ${PREVIOUS}. See ${LOG_FILE}." 2>/dev/null || true
        echo "[ROLLBACK COMPLETE]" >&2
    else
        notify-send -a "the house" -u critical "Theme switch FAILED" "Reverted to ${PREVIOUS} except ${failed[*]}. See ${LOG_FILE}." 2>/dev/null || true
        echo "[ROLLBACK INCOMPLETE] not restored: ${failed[*]}" >&2
    fi
    exit 1
}
trap rollback ERR INT TERM

MODE="${1:-light}"
case "${MODE}" in
    light|dark) ;;
    toggle)
        if [ "${PREVIOUS}" = "light" ]; then MODE=dark; else MODE=light; fi
        ;;
    *) echo "Usage: $0 {light|dark|toggle}" >&2; exit 2 ;;
esac

echo "[INFO] resolving mode=${MODE} (previous=${PREVIOUS})"

kvantum_find() { find /usr/share/Kvantum -maxdepth 1 -type d -iname "$1" 2>/dev/null | head -1 | xargs -r basename || true; }
kvantum_own() { [ -f "${HOME}/.themes/$1/Kvantum/$1.kvconfig" ] && echo "$1" || true; }
KVANTUM_DARK=$(kvantum_own Rubedo-Dark)
[ -z "${KVANTUM_DARK}" ] && KVANTUM_DARK=$(kvantum_find '*mocha*blue*')
[ -z "${KVANTUM_DARK}" ] && KVANTUM_DARK=$(kvantum_find '*mocha*') && [ -n "${KVANTUM_DARK}" ] && echo "[WARN] Kvantum Rubedo-Dark unavailable, using ${KVANTUM_DARK}"
[ -z "${KVANTUM_DARK}" ] && { echo "[FATAL] No Kvantum dark theme installed"; exit 1; }
KVANTUM_LIGHT=$(kvantum_own Rubedo-Light)
[ -z "${KVANTUM_LIGHT}" ] && KVANTUM_LIGHT=$(kvantum_find '*latte*pink*')
[ -z "${KVANTUM_LIGHT}" ] && KVANTUM_LIGHT="${KVANTUM_DARK}" && echo "[WARN] Kvantum Rubedo-Light unavailable, using ${KVANTUM_DARK}"

case "${MODE}" in
    light)
        GTK_THEME_NAME="$(gtk_name light)"
        GTK_PREFER_DARK=0
        BTOP_THEME="rubedo_light"; [ -f "${BTOP_DIR}/themes/rubedo_light.theme" ] || BTOP_THEME="catppuccin_light"
        CLAUDE_THEME="rubedo-light"
        ACCENT="pink"
        GTK_SCHEME="prefer-light"
        GTK_ICON="Papirus-Light"
        KVANTUM_THEME="${KVANTUM_LIGHT}"
        ;;
    dark)
        GTK_THEME_NAME="$(gtk_name dark)"
        GTK_PREFER_DARK=1
        BTOP_THEME="rubedo_dark"; [ -f "${BTOP_DIR}/themes/rubedo_dark.theme" ] || BTOP_THEME="catppuccin_dark"
        CLAUDE_THEME="rubedo-dark"
        ACCENT="blue"
        GTK_SCHEME="prefer-dark"
        GTK_ICON="Papirus-Dark"
        KVANTUM_THEME="${KVANTUM_DARK}"
        ;;
esac
CURSOR_THEME="$(cursor_name "${MODE}")"

TMP_HYPR=$(mktemp)
cat > "${TMP_HYPR}" <<EOF
require("themes/${MODE}")
EOF
put "${TMP_HYPR}" "${HYPR_THEMES}/active.lua"

TMP_KITTY=$(mktemp)
cat > "${TMP_KITTY}" <<EOF
include theme-${MODE}.conf
EOF
put "${TMP_KITTY}" "${KITTY_DIR}/theme-active.conf"

cp "${LAZYGIT_DIR}/config-${MODE}.yml" "${LAZYGIT_CFG}"

TMP_BTOP=$(mktemp)
sed "s|^color_theme = .*|color_theme = \"${BTOP_THEME}\"|" \
    "${BTOP_CONF}" > "${TMP_BTOP}"
put "${TMP_BTOP}" "${BTOP_CONF}"

mkdir -p "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
echo "${MODE}" > "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/nvim-flavour"

if [ -f "${BAT_DIR}/config-${MODE}" ]; then
    TMP_BAT=$(mktemp)
    cp "${BAT_DIR}/config-${MODE}" "${TMP_BAT}"
    put "${TMP_BAT}" "${BAT_CFG}"
fi

if [ -f "${QT6CT_CFG}" ]; then
    TMP_QT=$(mktemp)
    sed "s|^icon_theme=.*|icon_theme=${GTK_ICON}|" "${QT6CT_CFG}" > "${TMP_QT}"
    put "${TMP_QT}" "${QT6CT_CFG}"
fi

if [ -f "${CLAUDE_SETTINGS}" ]; then
    TMP_CLAUDE=$(mktemp)
    jq --arg t "custom:${CLAUDE_THEME}" '.theme = $t' "${CLAUDE_SETTINGS}" > "${TMP_CLAUDE}"
    put "${TMP_CLAUDE}" "${CLAUDE_SETTINGS}"
fi

mkdir -p "$(dirname "${GTK3_INI}")" "$(dirname "${GTK4_INI}")"
TMP_GTK=$(mktemp)
cat > "${TMP_GTK}" <<EOF
[Settings]
gtk-theme-name=${GTK_THEME_NAME}
gtk-icon-theme-name=${GTK_ICON}
gtk-cursor-theme-name=${CURSOR_THEME}
gtk-cursor-theme-size=24
gtk-font-name=JetBrainsMono Nerd Font 11
gtk-application-prefer-dark-theme=${GTK_PREFER_DARK}
EOF
put "${TMP_GTK}" "${GTK3_INI}"
cp "${GTK3_INI}" "${GTK4_INI}"

mkdir -p "$(dirname "${KVANTUM_CFG}")"
TMP_KV=$(mktemp)
cat > "${TMP_KV}" <<EOF
[General]
theme=${KVANTUM_THEME}
EOF
put "${TMP_KV}" "${KVANTUM_CFG}"

LOCK_WALLPAPER="${GLASSHOUSE_ART}/world/room-${MODE}-asleep.png"
LOCK_SIDE="${GLASSHOUSE_ART}/world/diner-${MODE}.png"
[ -f "${LOCK_SIDE}" ] || LOCK_SIDE="${LOCK_WALLPAPER}"
TMP_LOCK=$(mktemp)
cat > "${TMP_LOCK}" <<EOF
source = ${HYPR_DIR}/hyprlock-${MODE}.conf
\$wallpaper = ${LOCK_WALLPAPER}
\$side = ${LOCK_SIDE}
EOF
put "${TMP_LOCK}" "${HYPRLOCK_ACTIVE}"

hyprctl reload

pkill -SIGUSR1 -x kitty 2>/dev/null || true

mkdir -p "$(dirname "${XSETTINGSD_CFG}")"
TMP_XS=$(mktemp)
cat > "${TMP_XS}" <<EOF
Net/ThemeName "${GTK_THEME_NAME}"
Net/IconThemeName "${GTK_ICON}"
Gtk/CursorThemeName "${CURSOR_THEME}"
Gtk/CursorThemeSize 24
Gtk/FontName "JetBrainsMono Nerd Font 11"
EOF
put "${TMP_XS}" "${XSETTINGSD_CFG}"

pkill -x xsettingsd 2>/dev/null || true
xsettingsd >/dev/null 2>&1 9>&- &

hyprctl eval "hl.env(\"GTK_THEME\", \"${GTK_THEME_NAME}\")" >/dev/null 2>&1 || true

gsettings set org.gnome.desktop.interface color-scheme "${GTK_SCHEME}" 2>/dev/null || true
gsettings set org.gnome.desktop.interface gtk-theme  "${GTK_THEME_NAME}"     2>/dev/null || true
gsettings set org.gnome.desktop.interface icon-theme "${GTK_ICON}"           2>/dev/null || true
gsettings set org.gnome.desktop.interface cursor-theme "${CURSOR_THEME}" 2>/dev/null || true
gsettings set org.gnome.desktop.interface accent-color "${ACCENT}" 2>/dev/null || true

hyprctl setcursor "${CURSOR_THEME}" 24 >/dev/null 2>&1 || true

pkill -SIGUSR2 -x btop 2>/dev/null || true

sleep 0.3
CONFIG_ERRORS="$(hyprctl -j configerrors | jq -r '.[] | select(. != "")')"
if [ -n "${CONFIG_ERRORS}" ]; then
    echo "${CONFIG_ERRORS}"
    echo "[FAIL] hyprctl configerrors reports errors after reload"
    false
fi
if HL="$(hypr_log)" && [ -n "$HL" ]; then
    NEW_LINES_COUNT=$(wc -l < "$HL")
    if [ "${NEW_LINES_COUNT}" -gt "${HYPR_LOG_BEFORE_LINES}" ]; then
        NEW_LINES=$(tail -n $((NEW_LINES_COUNT - HYPR_LOG_BEFORE_LINES)) "$HL")
        if echo "${NEW_LINES}" | grep -E '(Config error|Couldn'"'"'t find file|[Ll]ua error|module .* not found)'; then
            echo "[FAIL] Hyprland log shows config errors after reload"
            false
        fi
    fi
fi

echo "${MODE}" > "${STATE_FILE}"
trap - ERR INT TERM

RUNNING_NEEDS_RELAUNCH=()
for proc in brave brave-browser chromium chrome discord obs mpv vlc; do
    if pgrep -x "$proc" >/dev/null 2>&1; then
        RUNNING_NEEDS_RELAUNCH+=("$proc")
    fi
done

if [ -n "${GLASSHOUSE_QUIET:-}" ]; then
    :
elif [ ${#RUNNING_NEEDS_RELAUNCH[@]} -gt 0 ]; then
    RELAUNCH_LIST=$(IFS=', '; echo "${RUNNING_NEEDS_RELAUNCH[*]}")
    notify-send -a "the house" "Theme switched: ${MODE}" \
      "Live: hyprland, kitty, hyprlock, prompt, btop, nvim, bat, lazygit(restart). Relaunch needed: ${RELAUNCH_LIST}. GTK3/Thunar may auto-refresh." \
      || true
else
    notify-send -a "the house" "Theme switched: ${MODE}" \
      "Live: hyprland, kitty, hyprlock, prompt, btop, nvim, bat, lazygit(restart). No browser/media apps to relaunch. GTK3/Thunar may auto-refresh." \
      || true
fi

echo "[OK] theme=${MODE} hyprctl=ok kitty=ok cascade=ok(prompt/lazygit/btop/nvim/bat) log=clean"
