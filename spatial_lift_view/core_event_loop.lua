local threading = require("thread")
local os = require("os")

local cfg = require("config")
local version = require("version")
local registration = require("spatial_lift_core.registration")
local teleportation = require("spatial_lift_core.teleportation")
local updates = require("spatial_lift_core.updates")
local utils = require("spatial_lift_core.utils")

return function(state)
    local teleporters = utils.getDestinationTeleporters()

    while true do
        local call_state, traceback = pcall(function()
            if state[1] == cfg.states.IDLE then
                local e = teleportation.check_progress
                teleportation.checkForRequests(teleporters, function(progress)
                    if progress == e.INCOMING then
                        state[1] = cfg.states.TELEPORTING
                        print("Incoming teleportation request accepted.")
                        
                    elseif progress == e.TELEPORTATION_COMPLETED then
                        print("Teleportation completed. Welcome aboard!")
                    end
                end)
                state[1] = cfg.states.IDLE
            end

            if state[1] == cfg.states.IDLE then
                local e = registration.check_progress
                registration.checkForRequests(function(progress, data)
                    if progress == e.REQUEST then
                        state[1] = cfg.states.REGISTRATING
                        print("Got a registration request from " .. data .. ".")
                        print("Exchanging markers...")

                    elseif progress == e.EXCHANGED then
                        print("Markers exchange completed.")
                    end
                end)
                state[1] = cfg.states.IDLE
            end

            if state[1] == cfg.states.IDLE then
                local e = updates.check_progress
                local i = version.install_progress
                updates.checkForRequests(function(progress)
                    if progress == e.AVAILABLE then
                        state[1] = cfg.states.UPDATING
                        print("New version is available, updating...")
                        
                    elseif progress == i.FLOPPY_NOT_MOUNTED then
                        print("Cannot mount update floppy, cancelling the update...")
                        
                    elseif progress == i.FLOPPY_MOUNTED then
                        print("Floppy filesystem mounted, copying files...")
                        
                    elseif progress == i.UPDATE_COMPLETED then
                        print("Update completed.")
                    
                    elseif progress == e.RESPONSE_ACCEPTED then
                        print("Update response accepted by a requesting endpoint. Restarting now...")
                        ---@diagnostic disable-next-line: undefined-field
                        os.sleep(1)
                        state[1] = cfg.states.SHUTTING_DOWN
                        threading.current():kill()
                    end
                end)
                state[1] = cfg.states.IDLE
            end
        end)

        if not call_state then
            print(traceback)
        end

        ---@diagnostic disable-next-line: undefined-field
        os.sleep(1)
    end
end