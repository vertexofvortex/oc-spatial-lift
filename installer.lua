local shell = require("shell")
local args = { ... }
local repo = "https://raw.githubusercontent.com/vertexofvortex/oc-spatial-lift/master/"
local scripts = {
    "installer.lua",
    "main.lua",
    "teleportation.lua",
    "registration.lua",
    "updates.lua",
    "utils.lua",
    "push.lua",
    "pull.lua",
    "config.lua",
    "version",
}
for i = 1, #scripts do
    shell.execute("wget -f " .. repo .. "/" .. scripts[i])
end
