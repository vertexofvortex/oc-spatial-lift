local os = require("os")

local cfg = require("config")
local registration = require("registration")
local teleportation = require("teleportation")
local updates = require("updates")
local utils = require("utils")

return function(states)
    local teleporters = utils.getDestinationTeleporters()

    while true do
        local state, traceback = pcall(function()
            teleportation.checkForRequests(teleporters)

            if not states.registering_mode then
                registration.checkForRequests()
            end

            -- TODO: check if in tp. or reg. process
            if not states.update_mode then
                updates.checkForRequests(states)
            end
        end)

        if not state then
            print(traceback)
        end

        ---@diagnostic disable-next-line: undefined-field
        os.sleep(1)
    end
end