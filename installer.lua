local shell = require("shell")
local args = { ... }
local repo = "https://raw.githubusercontent.com/vertexofvortex/oc-spatial-lift/master/"
local scripts = {
    "gui-lib" = {},
    "spatial-lift-core" = {
        "teleportation.lua",
        "registration.lua",
        "utils.lua",
    },
    "spatial-lift-view" = {
    },
    "" = {
        "installer.lua",
        "config.lua",
        "updates.lua",
        "version",
        "spatial-lift.lua",
    },
}
for dir, files in scripts do
    for i = 1, #files do
        shell.execute("wget -f " .. repo .. "/" .. dir .. "/" .. files[i])
    end
end
