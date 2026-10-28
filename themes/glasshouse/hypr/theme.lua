local glasshouse = require("glasshouse")
local mainMod = "SUPER"

require(package.searchpath("themes/active", package.path) and "themes/active" or "themes/light")

hl.env("QT_STYLE_OVERRIDE", "kvantum")

local function shell(name, fallback)
    return function()
        if glasshouse.on() then
            hl.dispatch(hl.dsp.global("glasshouse:" .. name))
        else
            hl.dispatch(hl.dsp.exec_cmd(fallback))
        end
    end
end

hl.bind(mainMod .. " + D", shell("sanctum", "true"))
hl.bind(mainMod .. " + SHIFT + Delete", shell("power", "true"))
hl.bind(mainMod .. " + CTRL + T", shell("turn", "~/.local/bin/glasshouse-turn"))
hl.bind(mainMod .. " + CTRL + P", shell("profile", "true"))
hl.bind(mainMod .. " + CTRL + B", shell("lancet", "true"))
hl.bind(mainMod .. " + SHIFT + V", shell("clipboard", "true"))
hl.bind(mainMod .. " + CTRL + I", shell("settings", "true"))

hl.unbind("Home")
hl.bind("Home", shell("cutter", [[sh -c 'geom=$(slurp) && [ -n "$geom" ] || exit 0; grim -g "$geom" - | satty --filename - --early-exit --initial-tool arrow --copy-command wl-copy']]))

-- bare Super_L: on its own press Hyprland's modmask doesn't hold SUPER yet
hl.bind("Super_L", function()
    if glasshouse.on() then
        hl.dispatch(hl.dsp.global("glasshouse:warm"))
    end
end, { non_consuming = true })

hl.layer_rule({
    name = "glasshouse-sanctum",
    match = { namespace = "^(glasshouse-sanctum)$" },
    no_anim = true,
})

hl.layer_rule({
    name = "glasshouse-turn",
    match = { namespace = "^(glasshouse-turn)$" },
    no_anim = true,
})

hl.layer_rule({
    name = "glasshouse-phial",
    match = { namespace = "^(glasshouse-phial)$" },
    no_anim = true,
})

hl.layer_rule({
    name = "glasshouse-cutter",
    match = { namespace = "^(glasshouse-cutter)$" },
    no_anim = true,
})

hl.layer_rule({
    name = "glasshouse-ledger",
    match = { namespace = "^(glasshouse-ledger|glasshouse-ledger-veil)$" },
    no_anim = true,
})

hl.window_rule({
    name = "glasshouse-ledger",
    match = { class = "^(ledgerscene)$" },
    fullscreen = true,
    no_anim = true,
})

hl.on("hyprland.start", function()
    hl.exec_cmd("~/.local/bin/glasshouse run")
    hl.exec_cmd("~/.local/bin/glasshouse-vitrail load")
    hl.exec_cmd("xsettingsd")
    hl.exec_cmd([[sh -c 'm=$(cat ~/.cache/theme-switch/current 2>/dev/null); if [ -n "$m" ] && [ -e ~/.config/hypr/themes/active.lua ]; then echo "$m" > "$XDG_RUNTIME_DIR/nvim-flavour"; else exec ~/.local/bin/theme-switch.sh light; fi']])
end)
