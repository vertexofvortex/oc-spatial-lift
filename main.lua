-- Libraries
local threading = require("thread")
local component = require("component")
local sides = require("sides")
local shell = require("shell")
local keyboard = require("keyboard")
local event = require("event")

-- Modules
local utils = require("utils")
local teleportation = require("teleportation")
local registration = require("registration")

-- Components
local transposer = component.proxy(component.list("transposer")())
local redstone = component.proxy(component.list("redstone")())

-- Constants
local inv = {
    ENDCHEST = sides.top,
    STORAGE = sides.north,
    PORT = sides.south,
}

local slot = {
    CELL_STORE = 27,
    CELL_TEMPSTORE = 26,
    CELL_SEND = 25,
    TP_REQUEST = 24,
    TP_ACCEPT = 23,
    REG_REQUEST = 18,
    REG_ACCEPT = 17,
}

-- Scheme of the enderchest inventory:
-- . . . . . . . . .
-- . . . . . . . . .
-- . . . . x x x x x
--         ^ ^ ^ ^ ^
--         | | | | |
--         | | | | Cell storage slot
--         | | | Temporary cell storage slot
--         | | Cell send slot
--         | Teleportation request with endpoint code
--         Teleportation request accept (same item as request)

-- Scheme of internal inventory:
--  - first slot - current endpoint
--  - other slots - destination endpoints

local teleporters = {}
local states = {
    registering_mode = false
}

local main_thread = threading.create(function()
    teleporters = utils.getDestinationTeleporters(transposer, inv)

    while true do
        local state, traceback = pcall(function()
            teleportation.checkTeleportationRequests(transposer, inv, slot, teleporters, redstone)

            if not states.registering_mode then
                registration.checkRegistrationRequests(transposer, inv, slot)
            end
        end)

        if not state then
            print(traceback)
        end

        ---@diagnostic disable-next-line: undefined-field
        os.sleep(1)
    end
end)

-- A thread for the program control
local control_thread = threading.create(function()
    local help_prompt =
        "+--------------------------------------+\n" ..
        "| Welcome to The Spatial Lift program! |\n" ..
        "+--------------------------------------+\n\n" ..
        "Controls:\n\n" ..
        "[L]\t\tShow teleporters list\n" ..
        "[R]\t\tRegister current teleporter and sync with others\n" ..
        "[H]\t\tShow this help page\n" ..
        "[Ctrl] + [C]\tTerminate program\n"

    shell.execute("clear")
    print(help_prompt)

    while true do
        local _, _, _, code, _ = event.pull("key_down")

        utils.onKeyDown(keyboard, code, "c", function()
            if keyboard.isControlDown() then
                print("Terminating...")

                main_thread:kill()
                control_thread:kill()
            end
        end)

        utils.onKeyDown(keyboard, code, "h", function()
            shell.execute("clear")
            print(help_prompt)
        end)

        utils.onKeyDown(keyboard, code, "l", function()
            shell.execute("clear")
            teleporters = utils.getDestinationTeleporters(transposer, inv)

            print("Available destinations:\n")

            for slot, teleporter_name in pairs(teleporters) do
                print("[" .. slot .. "]", teleporter_name)
            end

            print("\nPress the corresponding button to teleport\n")

            local _, _, _, code_teleport, _ = event.pull("key_down")

            for teleporter_slot, teleporter_name in pairs(teleporters) do
                utils.onKeyDown(keyboard, code_teleport, tostring(teleporter_slot), function()
                    print("Are you sure you want to teleport to " .. teleporter_name .. " destination? Y/n")

                    local _, _, _, code_confirmation, _ = event.pull("key_down")

                    utils.onKeyDown(keyboard, code_confirmation, "y", function()
                        print("")
                        teleportation.requestTeleportation(transposer, inv, slot, teleporter_slot, redstone)
                        print("Teleported successfully!")

                        ---@diagnostic disable-next-line: undefined-field
                        os.sleep(5)
                        shell.execute("clear")
                        print(help_prompt)
                    end)

                    utils.onKeyDown(keyboard, code_confirmation, "n", function()
                        print("Cancelling...")

                        ---@diagnostic disable-next-line: undefined-field
                        os.sleep(1)
                        shell.execute("clear")
                        print(help_prompt)
                    end)
                end)
            end
        end)

        utils.onKeyDown(keyboard, code, "r", function()
            print("Endpoint registration sequence started (timeout: 5s.)...\n")

            local status = registration.requestRegistration(transposer, inv, slot, states)

            print("\nAdded " .. status .. " new endpoints.")
            print("Press [H] to return to the menu.")
        end)
    end
end)
