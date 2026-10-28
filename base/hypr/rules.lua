hl.window_rule({
    name = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name = "fix-xwayland-drags",
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },
    no_focus = true,
})

hl.window_rule({
    name = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move = { 20, "monitor_h-120" },
    float = true,
})

hl.window_rule({
    name = "satty-float-center",
    match = { class = "^(com\\.gabm\\.satty)$" },
    float = true,
    size = { "monitor_w*0.7", "monitor_h*0.78" },
    center = true,
})

hl.workspace_rule({ workspace = "s[false] f[1]", gaps_out = 0, gaps_in = 0 })
hl.window_rule({
    name = "solo-panel-fullscreen",
    match = { workspace = "s[false] f[1]", float = false },
    border_size = 0,
    rounding = 0,
})

hl.window_rule({
    name = "pip",
    match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)$" },
    float = true,
    pin = true,
    move = { "monitor_w*0.73", "monitor_h*0.72" },
    size = { "monitor_w*0.25", "monitor_h*0.25" },
})

hl.window_rule({
    name = "screenshare-chip",
    match = { title = ".*is sharing (a window|your screen).*" },
    float = true,
    pin = true,
    move = { "monitor_w*0.5-window_w*0.5", "monitor_h-window_h-12" },
})
