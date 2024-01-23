local threading = require("thread")
local keyboard = require("keyboard")
local event = require("event")
local shell = require("shell")
local os = require("os")

local cfg = require("config")
local registration = require("spatial_lift_core.registration")
local teleportation = require("spatial_lift_core.teleportation")
local updates = require("spatial_lift_core.updates")
local utils = require("spatial_lift_core.utils")

function onKeyDown(keyboard, key_code, key_char, callback)
    if keyboard.keys[key_code] == key_char then
        callback()
    end
end

return function(states)
    local help_prompt =
        "+--------------------------------------+\n" ..
        "| Welcome to The Spatial Lift program! |\n" ..
        "+--------------------------------------+\n\n" ..
        "Version " .. updates.getCurrentVersion() .. "\n\n" ..
        "Controls:\n\n" ..
        "[L]\t\tShow teleporters list\n" ..
        "[R]\t\tRegister current teleporter and sync with others\n" ..
        "[H]\t\tShow this help page\n" ..
        "[Ctrl] + [C]\tTerminate program\n"

    shell.execute("clear")
    print(help_prompt)

    while true do
        local _, _, _, code, _ = event.pull("key_down")

        onKeyDown(keyboard, code, "c", function()
            if keyboard.isControlDown() then
                print("Terminating...")
                states.stop_execution = true
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
                        print("")
                        if teleportation.request(teleporter_slot) then
                            print("Teleported successfully!")
                        end

                        ---@diagnostic disable-next-line: undefined-field
                        os.sleep(5)
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
            print("Endpoint registration sequence started (timeout: 5s.)...\n")

            local status = registration.request(states)

            print("\nAdded " .. status .. " new endpoints.")
            print("Press [H] to return to the menu.")
        end)

        onKeyDown(keyboard, code, "u", function()
            updates.broadcastUpdate(states)
        end)
    end
end