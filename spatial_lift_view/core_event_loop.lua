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
            local e = teleportation.check_progress
            teleportation.checkForRequests(teleporters, function(progress)
                if progress == e.INCOMING then
                    print("Incoming teleportation request accepted.")
                    
                elseif progress == e.TELEPORTATION_COMPLETED then
                    print("Teleportation completed. Welcome aboard!")
                end
            end)

            if not states.registering_mode then
                local e = registration.check_progress
                registration.checkForRequests(function(progress, data)
                    if progress == e.REQUEST then
                        print("Got a registration request from " .. data .. ".")
                        print("Exchanging markers...")

                    elseif progress == e.EXCHANGED then
                        print("Markers exchange completed.")
                    end
                end)
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