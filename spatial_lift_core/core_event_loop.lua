local os = require("os")

local cfg = require("config")
local registration = require("spatial_lift_core.registration")
local teleportation = require("spatial_lift_core.teleportation")
local updates = require("spatial_lift_core.updates")
local utils = require("spatial_lift_core.utils")

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