local shell = require("shell")
local args = { ... }
local repo = "https://raw.githubusercontent.com/vertexofvortex/oc-spatial-lift/master/"
local scripts = {
    ["gui-lib"] = {},
    ["spatial-lift-core"] = {
        "teleportation.lua",
        "registration.lua",
        "utils.lua",
        "updates.lua",
    },
    ["spatial-lift-view"] = {
    },
    [""] = {
        "installer.lua",
        "config.lua",
        "version",
        "spatial-lift.lua",
    },
}
for dir, files in pairs(scripts) do
    if dir ~= "" then
        path = dir .. "/"
        shell.execute("mkdir " .. dir)
    else
        path = ""
    end

    for i = 1, #files do
        shell.execute("wget -f " .. repo .. "/" .. path .. files[i] .. " " .. path .. files[i])
    end
end
