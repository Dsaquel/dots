local glasshouse = require("glasshouse")
local M = {}

local function frame(w, chrome, plugin)
    hl.config({
        general = {
            gaps_in = chrome and 16 or 7,
            gaps_out = chrome and 34 or { top = 18, right = 14, bottom = 16, left = 14 },
            float_gaps = 16,
            border_size = chrome and 0 or 2,
            col = { active_border = w.active, inactive_border = w.inactive },
            layout = "dwindle",
            resize_on_border = true,
            hover_icon_on_border = true,
        },
        decoration = {
            rounding = chrome and 8 or 13,
            rounding_power = chrome and 2 or 3.4,
            shadow = { enabled = not chrome },
            glow = { enabled = not chrome },
            dim_inactive = not chrome,
        },
    })
    if plugin then
        hl.animation({ leaf = "windowsOut", enabled = false, speed = 1.67, bezier = "kaienCut" })
        hl.config({ plugin = { vitrail = { world = w.world, screens = glasshouse.screens() } } })
    elseif chrome then
        hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.67, bezier = "kaienCut", style = "popin 100%" })
    else
        hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.67, bezier = "kaienCut", style = "popin 93%" })
    end
end

local function stop()
    if _G.glasshouse_watch then
        pcall(function() _G.glasshouse_watch:set_enabled(false) end)
        _G.glasshouse_watch = nil
    end
end

local function watch(w)
    stop()
    local last, ticks = "", 0
    _G.glasshouse_watch = hl.timer(function()
        ticks = ticks + 1
        if ticks % 20 == 0 and not glasshouse.on() then
            stop()
            local plugin = glasshouse.vitrail()
            frame(w, plugin, plugin)
            return
        end
        local p = {}
        for _, win in ipairs(hl.get_windows()) do
            p[#p + 1] = win.address .. ":" .. win.at.x .. "," .. win.at.y .. "," .. win.size.x .. "," .. win.size.y
        end
        local s = table.concat(p, ";")
        if s ~= last then
            last = s
            hl.dispatch(hl.dsp.event("glasshouse>>geometry"))
        end
    end, { timeout = 50, type = "repeat" })
end

local function pointer_stop()
    if _G.glasshouse_pointer_watch then
        pcall(function() _G.glasshouse_pointer_watch:set_enabled(false) end)
        _G.glasshouse_pointer_watch = nil
    end
end

function _G.glasshouse_pointer(on)
    pointer_stop()
    if not on then
        return
    end
    local lx, ly, ticks = nil, nil, 0
    _G.glasshouse_pointer_watch = hl.timer(function()
        ticks = ticks + 1
        if ticks % 60 == 0 and not glasshouse.on() then
            pointer_stop()
            return
        end
        local p = hl.get_cursor_pos()
        if not p then
            return
        end
        local x, y = math.floor(p.x), math.floor(p.y)
        if x ~= lx or y ~= ly then
            lx, ly = x, y
            hl.dispatch(hl.dsp.event("ghpointer>>" .. x .. "," .. y))
        end
    end, { timeout = 16, type = "repeat" })
end

function M.apply(w)
    local shell, plugin = glasshouse.on(), glasshouse.vitrail()
    local function built(dir)
        local f = io.open(os.getenv("HOME") .. "/" .. dir .. "/index.theme", "r")
        return f ~= nil and f:close()
    end
    local cursor = built(".local/share/icons/" .. w.cursor) and w.cursor or "Adwaita"
    hl.env("GTK_THEME", built(".themes/" .. w.gtk) and w.gtk or w.gtk_fallback)
    hl.env("XCURSOR_THEME", cursor)
    hl.env("HYPRCURSOR_THEME", cursor)

    hl.config({
        decoration = {
            active_opacity = 1.0,
            inactive_opacity = 1.0,
            fullscreen_opacity = 1.0,
            blur = {
                enabled = true,
                size = 7,
                passes = 2,
                new_optimizations = true,
                ignore_opacity = true,
                noise = 0.012,
                contrast = 1.05,
                brightness = 0.96,
                vibrancy = 0.15,
                vibrancy_darkness = 0.05,
                xray = true,
                special = false,
                popups = true,
                popups_ignorealpha = 0.2,
            },
            shadow = {
                range = 24,
                render_power = 3,
                offset = { 0, 6 },
                scale = 1.0,
                sharp = false,
                color = w.shadow,
                color_inactive = w.shadow_inactive,
            },
            glow = {
                range = 18,
                render_power = 2,
                color = w.glow,
                color_inactive = "rgba(00000000)",
            },
            dim_strength = w.dim,
            dim_special = 0.30,
        },
        group = {
            col = { border_active = w.group_active, border_inactive = w.group_inactive },
            groupbar = {
                enabled = true,
                height = 22,
                font_size = 11,
                gradients = false,
                rounding = 8,
                text_color = w.text,
                col = { active = w.bar_active, inactive = w.bar_inactive },
            },
        },
        animations = { enabled = true },
        misc = { bell_sound = "none" },
        dwindle = {
            preserve_split = true,
            smart_split = false,
            smart_resizing = true,
        },
    })
    hl.curve("glassOut",   { type = "bezier", points = { {0.33, 1.00}, {0.68, 1.00} } })
    hl.curve("kaienGlide", { type = "bezier", points = { {0.20, 0.90}, {0.24, 1.00} } })
    hl.curve("kaienCut",   { type = "bezier", points = { {0.10, 0.56}, {0.30, 1.00} } })
    hl.curve("kaienInk",   { type = "bezier", points = { {0.24, 0.28}, {0.16, 1.00} } })

    hl.animation({ leaf = "global",        enabled = true, speed = 2.78, bezier = "kaienGlide" })
    hl.animation({ leaf = "windows",       enabled = true, speed = 3.33, bezier = "glassOut", style = "popin 92%" })
    hl.animation({ leaf = "windowsIn",     enabled = true, speed = 3.33, bezier = "glassOut", style = "popin 92%" })
    hl.animation({ leaf = "windowsMove",   enabled = true, speed = 2.78, bezier = "kaienGlide" })
    frame(w, shell or plugin, plugin)

    hl.animation({ leaf = "layers",        enabled = true, speed = 1.67, bezier = "glassOut", style = "fade" })
    hl.animation({ leaf = "layersIn",      enabled = true, speed = 1.67, bezier = "glassOut", style = "fade" })
    hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.11, bezier = "kaienCut", style = "fade" })

    hl.animation({ leaf = "workspaces",    enabled = true, speed = 2.22, bezier = "kaienGlide", style = "slidefade 12%" })
    hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 2.22, bezier = "kaienGlide", style = "slidefade 12%" })
    hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.39, bezier = "kaienCut",   style = "slidefade 12%" })

    hl.animation({ leaf = "specialWorkspace",    enabled = true, speed = 3.33, bezier = "glassOut", style = "slidefadevert -16%" })
    hl.animation({ leaf = "specialWorkspaceIn",  enabled = true, speed = 3.33, bezier = "glassOut", style = "slidefadevert -18%" })
    hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 2.22, bezier = "kaienCut", style = "slidefadevert -12%" })

    hl.animation({ leaf = "fade",          enabled = true, speed = 1.39, bezier = "kaienInk" })
    hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.67, bezier = "kaienInk" })
    hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.11, bezier = "kaienCut" })
    hl.animation({ leaf = "fadeSwitch",    enabled = true, speed = 1.67, bezier = "kaienInk" })
    hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.11, bezier = "kaienInk" })
    hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 0.83, bezier = "kaienCut" })
    hl.animation({ leaf = "fadePopupsIn",  enabled = true, speed = 0.83, bezier = "kaienInk" })
    hl.animation({ leaf = "fadePopupsOut", enabled = true, speed = 0.56, bezier = "kaienCut" })
    hl.animation({ leaf = "fadeDpms",      enabled = true, speed = 6.67, bezier = "kaienInk" })

    hl.animation({ leaf = "border",        enabled = true, speed = 2.22, bezier = "kaienInk" })
    hl.animation({ leaf = "fadeShadow",    enabled = true, speed = 2.50, bezier = "kaienInk" })
    hl.animation({ leaf = "fadeGlow",      enabled = true, speed = 2.78, bezier = "kaienInk" })
    hl.animation({ leaf = "fadeDim",       enabled = true, speed = 3.06, bezier = "kaienInk" })

    hl.animation({ leaf = "borderangle",   enabled = true, speed = 6.67, bezier = "kaienGlide", style = "once" })
    hl.animation({ leaf = "shadowangle",   enabled = true, speed = 6.67, bezier = "kaienGlide", style = "once" })
    hl.animation({ leaf = "glowangle",     enabled = true, speed = 6.67, bezier = "kaienGlide", style = "once" })

    hl.animation({ leaf = "zoomFactor",    enabled = true, speed = 3.33, bezier = "glassOut" })
    hl.animation({ leaf = "monitorAdded",  enabled = true, speed = 3.33, bezier = "glassOut" })

    hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
    hl.gesture({ fingers = 3, direction = "vertical", action = "special" })

    if shell then
        watch(w)
    else
        stop()
    end

    _G.glasshouse_announce = function()
        if glasshouse.on() then
            frame(w, true, glasshouse.vitrail())
            watch(w)
        end
    end
end

return M
