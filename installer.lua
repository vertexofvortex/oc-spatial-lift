local shell = require("shell")
local args = { ... }
local repo = "https://raw.githubusercontent.com/vertexofvortex/oc-spatial-lift/master/"
local scripts = {
    ["gui-lib"] = {},
    ["spatial-lift-core"] = {
        "core_event_loop.lua",
        "registration.lua",
        "teleportation.lua",
        "updates.lua",
        "utils.lua",
    },
    ["spatial-lift-view"] = {
        "view_event_loop.lua"
    },
    [""] = {
        "installer.lua",
        "config.lua",
        "version",
        "spatial-lift.lua",
    },
}

for dir, files in pairs(scripts) do
    local path = ""
    if dir ~= "" then
        path = dir .. "/"
        shell.execute("mkdir " .. dir)
    end

    for i = 1, #files do
        shell.execute("wget -f " .. repo .. "/" .. path .. files[i] .. " " .. path .. files[i])
    end
end
