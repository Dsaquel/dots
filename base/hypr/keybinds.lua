local mainMod = "SUPER"

hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd("kitty"))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("sh -c 'command -v yazi >/dev/null && exec kitty --class yazi -e yazi || exec thunar'"))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.layout("rotatesplit"))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())

hl.bind(mainMod .. " + Delete", hl.dsp.exec_cmd("loginctl lock-session"))

hl.bind("Print", hl.dsp.exec_cmd([[sh -c 'geom=$(slurp) && [ -n "$geom" ] || exit 0; grim -g "$geom" - | satty --filename - --early-exit --initial-tool arrow --copy-command wl-copy']]))
hl.bind("Home", hl.dsp.exec_cmd([[sh -c 'geom=$(slurp) && [ -n "$geom" ] || exit 0; grim -g "$geom" - | satty --filename - --early-exit --initial-tool arrow --copy-command wl-copy']]))
hl.bind("End", hl.dsp.exec_cmd("hyprshot -m region --freeze"))
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd("hyprshot -m window --freeze"))
hl.bind(mainMod .. " + SHIFT + Print", hl.dsp.exec_cmd("hyprshot -m output"))
hl.bind(mainMod .. " + CTRL + Print", hl.dsp.exec_cmd([[sh -c 'notify-send "Screenshot in 3s..." && sleep 3 && hyprshot -m region --freeze']]))

hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "d" }))
hl.bind(mainMod .. " + h",     hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + l",     hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + k",     hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + j",     hl.dsp.focus({ direction = "d" }))

hl.bind(mainMod .. " + SHIFT + h", hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + l", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + SHIFT + k", hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + j", hl.dsp.window.move({ direction = "d" }))

hl.bind(mainMod .. " + CTRL + h", hl.dsp.window.resize({ x = -20, y = 0, relative = true }))
hl.bind(mainMod .. " + CTRL + l", hl.dsp.window.resize({ x = 20, y = 0, relative = true }))
hl.bind(mainMod .. " + CTRL + k", hl.dsp.window.resize({ x = 0, y = -20, relative = true }))
hl.bind(mainMod .. " + CTRL + j", hl.dsp.window.resize({ x = 0, y = 20, relative = true }))

for i = 1, 10 do
    local key = "code:" .. (23 + i)
    hl.bind(mainMod .. " + " .. key,            hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key,    hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind(mainMod .. " + S", hl.dsp.window.move({ workspace = "special" }))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.workspace.toggle_special())
hl.bind(mainMod .. " + CTRL + S", hl.dsp.window.move({ workspace = "+0" }))

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"),     { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind(mainMod .. " + G", hl.dsp.group.toggle())
hl.bind(mainMod .. " + SHIFT + G", hl.dsp.group.next())
hl.bind(mainMod .. " + CTRL + G", hl.dsp.window.move({ out_of_group = true }))

hl.bind(mainMod .. " + W", hl.dsp.submap("groupify"))
hl.define_submap("groupify", function()
    hl.bind("h", hl.dsp.window.move({ into_or_create_group = "l" }))
    hl.bind("j", hl.dsp.window.move({ into_or_create_group = "d" }))
    hl.bind("k", hl.dsp.window.move({ into_or_create_group = "u" }))
    hl.bind("l", hl.dsp.window.move({ into_or_create_group = "r" }))
    hl.bind("escape", hl.dsp.submap("reset"))
    hl.bind("Return", hl.dsp.submap("reset"))
end)

hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("hyprpicker -an -f hex"))
