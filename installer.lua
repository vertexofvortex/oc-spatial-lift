local shell = require("shell")
local args = { ... }
local repo = "https://raw.githubusercontent.com/vertexofvortex/oc-spatial-lift/master/"
local scripts = {
    "installer.lua",
    "main.lua",
    "teleportation.lua",
    "registration.lua",
    "utils.lua",
    "push.lua",
    "pull.lua",
}
for i = 1, #scripts do
    shell.execute("wget -f " .. repo .. "/" .. scripts[i])
end
