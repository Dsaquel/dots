hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("XDG_SESSION_TYPE", "wayland")

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")

require("keybinds")
require("autostart")
require("rules")

hl.config({
    input = {
        follow_mouse = 1,
        sensitivity = 0,
    },

    binds = {
        hide_special_on_workspace_change = true,
    },
})

for _, layer in ipairs({ "theme", "local" }) do
    if package.searchpath(layer, package.path) then
        require(layer)
    end
end
