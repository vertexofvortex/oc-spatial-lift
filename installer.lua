local shell = require("shell")
local args = { ... }
local repo = "https://raw.githubusercontent.com/vertexofvortex/oc-spatial-lift/master/"
local scripts = {
    ["gui_lib"] = {},
    ["spatial_lift_core"] = {
        "registration.lua",
        "teleportation.lua",
        "updates.lua",
        "utils.lua",
    },
    ["spatial_lift_view"] = {
        "core_event_loop.lua",
        "view_event_loop.lua",
    },
    [""] = {
        "installer.lua",
        "main.lua",
        "starter.lua",
        "config.lua",
        "constants.lua",
        "uncacher.lua",
        "version.lua",
        "version",
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
