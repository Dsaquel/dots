hl.on("hyprland.start", function()
    hl.exec_cmd("systemctl --user restart xdg-desktop-portal-hyprland xdg-desktop-portal")

    hl.exec_cmd("hypridle")
    hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd([[sh -c 'd=${XDG_STATE_HOME:-$HOME/.local/state}/hyprland; i=$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE; mkdir -p "$d"; [ -f "$d/session.log" ] && mv "$d/session.log" "$d/previous.log"; exec tail --pid="$(head -n1 "$i/hyprland.lock")" -F -n +1 "$i/hyprland.log" > "$d/session.log"']])
end)
