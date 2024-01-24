local threading = require("thread")
local keyboard = require("keyboard")
local event = require("event")
local shell = require("shell")
local os = require("os")

local cfg = require("config")
local version = require("version")
local registration = require("spatial_lift_core.registration")
local teleportation = require("spatial_lift_core.teleportation")
local updates = require("spatial_lift_core.updates")
local utils = require("spatial_lift_core.utils")

local function onKeyDown(keyboard, key_code, key_char, callback)
    if keyboard.keys[key_code] == key_char then
        callback()
    end
end

return function(state)
    local help_prompt =
        "+--------------------------------------+\n" ..
        "| Welcome to The Spatial Lift program! |\n" ..
        "+--------------------------------------+\n\n" ..
        "Version " .. version.getCurrentVersion() .. "\n\n" ..
        "Controls:\n\n" ..
        "[L]\t\tShow teleporters list\n" ..
        "[R]\t\tRegister current teleporter and sync with others\n" ..
        "[U]\t\tBroadcast an update\n" ..
        "[H]\t\tShow this help page\n" ..
        "[Ctrl] + [C]\tTerminate program\n"

    shell.execute("clear")
    print(help_prompt)

    while true do
        local _, _, _, code, _ = event.pull("key_down")

        if state[1] == cfg.states.IDLE then
            onKeyDown(keyboard, code, "c", function()
                if keyboard.isControlDown() then
                    print("Terminating...")
                    state[1] = cfg.states.SHUTTING_DOWN
                    threading.current():kill()
                end
            end)

            onKeyDown(keyboard, code, "h", function()
                shell.execute("clear")
                print(help_prompt)
            end)

            onKeyDown(keyboard, code, "l", function()
                shell.execute("clear")
                local teleporters = utils.getDestinationTeleporters()

                print("Available destinations:\n")

                for slot, teleporter_name in pairs(teleporters) do
                    print("[" .. slot .. "]", teleporter_name)
                end

                print("\nPress the corresponding button to teleport\n")

                local _, _, _, code_teleport, _ = event.pull("key_down")

                for teleporter_slot, teleporter_name in pairs(teleporters) do
                    onKeyDown(keyboard, code_teleport, tostring(teleporter_slot), function()
                        print("Are you sure you want to teleport to " .. teleporter_name .. " destination? Y/n")

                        local _, _, _, code_confirmation, _ = event.pull("key_down")

                        onKeyDown(keyboard, code_confirmation, "y", function()
                            state[1] = cfg.states.TELEPORTING
                            print("")
                            local e = teleportation.request_progress
                            teleportation.request(teleporter_slot, function(progress)
                                if progress == e.CELL_MISSING then
                                    print("The spatial cell is missing. Perhaps someone else is using the teleporter right now?")

                                elseif progress == e.SELF_TELEPORT then
                                    print("Cannot teleport to self.")
                                
                                elseif progress == e.START_PINGING then
                                    print("Pinging destination endpoint...")
                                
                                elseif progress == e.NO_RESPONSE then
                                    print("Connection refused. Destination endpoint is unavailable.")
                                    print("Check if teleporter is properly working and chunkloaded.")

                                elseif progress == e.ACCEPTED then
                                    print("Teleportation request accepted by destination endpoint!")
                                    print("Teleporting in 3 seconds...")

                                elseif progress == e.SUCCESS then
                                    print("Teleportation...")
                                    print("Teleported successfully!")
                                end
                            end)
                            
                            ---@diagnostic disable-next-line: undefined-field
                            os.sleep(5)
                            state[1] = cfg.states.IDLE
                            shell.execute("clear")
                            print(help_prompt)
                        end)

                        onKeyDown(keyboard, code_confirmation, "n", function()
                            print("Cancelling...")

                            ---@diagnostic disable-next-line: undefined-field
                            os.sleep(1)
                            shell.execute("clear")
                            print(help_prompt)
                        end)
                    end)
                end
            end)

            onKeyDown(keyboard, code, "r", function()
                state[1] = cfg.states.REGISTRATING
                local response_counter = 0
                local e = registration.request_progress
                registration.request(function(progress, data)
                    if progress == e.NO_MARKERS then
                        print("Put 64 named markers in the first slot of internal buffer before initiating registration sequence.")  

                    elseif progress == e.INITIATE then
                        print("Endpoint registration sequence started (timeout: 5s.)...\n")
                        print("#", "Status  ", "Name\n")

                    elseif progress == e.REGISTRATED then
                        response_counter = response_counter + 1
                        print(response_counter, "ACCEPTED", data)

                    elseif progress == e.FINISH then
                        print("\nNo registration response has been detected in the last 5 seconds.")
                        print("Consider the registration completed.")
                        print("\nAdded " .. response_counter .. " new endpoints.")
                        print("Press [H] to return to the menu.")
                    end
                end)
                state[1] = cfg.states.IDLE
            end)

            onKeyDown(keyboard, code, "u", function()
                state[1] = cfg.states.UPDATING
                local e = updates.broadcast_progress
                updates.broadcastUpdate(function(progress, data)
                    if progress == e.NO_FLOPPY then
                        print("No floppy detected in the drive.")

                    elseif progress == e.BROADCASTING then
                        print("Broadcasting the update...")
                    
                    elseif progress == e.RESPONSE_DETECTED then
                        print("Detected response from " .. data .. ", consider this endpoint has installed an update.")

                    elseif progress == e.TIMEOUT then
                        print("\nNo update response has been detected in the last 10 seconds.")
                        print("Consider the update completed.")
                        
                        print("Should this computer be updated? Y/n")
                        local _, _, _, code_confirmation, _ = event.pull("key_down")

                        onKeyDown(keyboard, code_confirmation, "y", function()
                            local e = version.install_progress
                            version.install(function(progress)
                                if progress == e.FLOPPY_NOT_MOUNTED then
                                    print("Cannot mount update floppy, cancelling the update...")
                                    
                                elseif progress == e.FLOPPY_MOUNTED then
                                print("Floppy filesystem mounted, copying files...")
                                    
                                elseif progress == e.UPDATE_COMPLETED then
                                    print("Update completed. Restarting now.")
                                    ---@diagnostic disable-next-line: undefined-field
                                    os.sleep(1)
                                    state[1] = cfg.states.SHUTTING_DOWN
                                    threading.current():kill()
                                end
                            end)
                        end)

                        onKeyDown(keyboard, code_confirmation, "n", function()
                            shell.execute("clear")
                            print(help_prompt)
                        end)
                    end
                end)
                state[1] = cfg.states.IDLE
            end)
        elseif state[1] == cfg.states.REGISTRATING then
            print("There is currently an ongoing registration")
        elseif state[1] == cfg.states.TELEPORTING then
            print("There is currently an ongoing teleportation")
        elseif state[1] == cfg.states.UPDATING then
            print("There is currently an ongoing update")
        end
    end
end