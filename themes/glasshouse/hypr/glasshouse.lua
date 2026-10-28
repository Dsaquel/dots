local M = {}

function M.on()
    local f = io.open((os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/glasshouse.on", "r")
    if not f then
        return false
    end
    local pid = f:read("*l")
    f:close()
    if not pid or not pid:match("^%d+$") then
        return false
    end
    local c = io.open("/proc/" .. pid .. "/comm", "r")
    if not c then
        return false
    end
    local comm = c:read("*l")
    c:close()
    return comm == "qs" or comm == "quickshell"
end

function M.vitrail()
    for _, p in ipairs(hl.get_loaded_plugins()) do
        if p.name == "vitrail" then
            return true
        end
    end
    return false
end

function M.screens()
    local env = os.getenv("GLASSHOUSE_SCREENS")
    if env and env ~= "" then
        return env
    end
    local mons = hl.get_monitors()
    table.sort(mons, function(a, b) return a.x < b.x or (a.x == b.x and a.y < b.y) end)
    local parts = {}
    for i, m in ipairs(mons) do
        local first, last = #mons == 1 and 1 or 5 * i - 4, #mons == 1 and 10 or 5 * i
        parts[i] = m.name .. "=" .. (i == 1 and "main" or "side") .. ":" .. first .. "-" .. last
    end
    return table.concat(parts, ",")
end

return M
