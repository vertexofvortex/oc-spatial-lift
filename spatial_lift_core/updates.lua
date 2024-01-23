local io = require("io")
local shell = require("shell")
local fs = require("filesystem")

local cfg = require("config")
local utils = require("spatial_lift_core.utils")

local updates = {}

-- Get current program version from file
function updates.getCurrentVersion()
    local version_file = io.open("./version")
    local version_text = version_file:read("*a")
    local version = tonumber(version_text)

    return version
end

-- Checks for an update requests in a background
function updates.checkForRequests(states)
    if utils.getStackInSlot(cfg.transposer_sides.ENDCHEST, cfg.endchest_slots.UPD_BROADCAST) == nil then
        return false
    end

    if not updates.checkShouldUpdate(
            tonumber(utils.getStackInSlot(cfg.transposer_sides.ENDCHEST, cfg.endchest_slots.UPD_BROADCAST).label)
        ) then
        print("Current version is newer or at least the same as available update. Skipping.")

        return false
    else
        print("New version is available, updating...")
    end

    states.update_mode = true

    -- Waits until it can grab floppy disk from the update broadcast slot...
    while true do
        if utils.transferItem(cfg.transposer_sides.ENDCHEST, cfg.transposer_sides.DRIVE, 1,
                cfg.endchest_slots.UPD_BROADCAST, 1) == 1 then
            break
        end
    end

    -- ...and then makes install
    updates.install()

    -- When installation completed/failed (doesn't matter), places it's marker item
    -- to the update response slot
    utils.transferItem(cfg.transposer_sides.STORAGE, cfg.transposer_sides.ENDCHEST, 1,
        cfg.storage_slots.CURRENT_MARKER, cfg.endchest_slots.UPD_RESPONSE)

    -- Waits update response accept from the first endpoint
    while true do
        if utils.getStackInSlot(cfg.transposer_sides.ENDCHEST, cfg.endchest_slots.UPD_RESPONSE_ACCEPT) ~= nil then
            print("Update response accepted by a requesting endpoint.")

            break
        end
    end

    -- Grabs it's own marker back to the storage
    utils.transferItem(cfg.transposer_sides.ENDCHEST, cfg.transposer_sides.STORAGE, 1,
        cfg.endchest_slots.UPD_RESPONSE_ACCEPT, cfg.storage_slots.CURRENT_MARKER)

    -- Returns back a floppy disk
    utils.transferItem(cfg.transposer_sides.DRIVE, cfg.transposer_sides.ENDCHEST, 1, 1,
        cfg.endchest_slots.UPD_BROADCAST)

    states.update_mode = false
end

-- Checks current version and new available version,
-- checks if updates disabled by configuration file.
-- Returns true if update should be installed and false if not
function updates.checkShouldUpdate(update_version)
    print(updates.getCurrentVersion())

    if update_version > updates.getCurrentVersion() then
        return true
    else
        return false
    end
end

function updates.broadcastUpdate(states)
    if utils.getStackInSlot(cfg.transposer_sides.DRIVE, 1) == nil then
        print("No floppy detected in the drive.")

        return false
    end

    print("Broadcasting the update...")

    states.update_mode = true

    local update_responses = {}
    local request_timeout_timer = 0

    utils.transferItem(
        cfg.transposer_sides.DRIVE,
        cfg.transposer_sides.ENDCHEST,
        1,
        1,
        cfg.endchest_slots.UPD_BROADCAST
    )

    while true do
        if utils.getStackInSlot(cfg.transposer_sides.ENDCHEST, cfg.endchest_slots.UPD_RESPONSE) ~= nil then
            request_timeout_timer = 0

            print("Detected response from " ..
            utils.getStackInSlot(cfg.transposer_sides.ENDCHEST, cfg.endchest_slots.UPD_RESPONSE).label ..
                ", consider this endpoint has installed an update.")

            update_responses[utils.getStackInSlot(cfg.transposer_sides.ENDCHEST, cfg.endchest_slots.UPD_RESPONSE).label] = true

            utils.transferItem(
                cfg.transposer_sides.ENDCHEST,
                cfg.transposer_sides.ENDCHEST,
                1,
                cfg.endchest_slots.UPD_RESPONSE,
                cfg.endchest_slots.UPD_RESPONSE_ACCEPT
            )
        end

        if request_timeout_timer >= 5 then
            utils.transferItem(
                cfg.transposer_sides.ENDCHEST,
                cfg.transposer_sides.DRIVE,
                1,
                cfg.endchest_slots.UPD_BROADCAST,
                1
            )

            print("request timeout")

            states.update_mode = false

            return update_responses
        end

        request_timeout_timer = request_timeout_timer + 1

        ---@diagnostic disable-next-line: undefined-field
        os.sleep(1)
    end
end

-- Installs an update
function updates.install()
    local files = {
        "installer.lua",
        "main.lua",
        "teleportation.lua",
        "registration.lua",
        "updates.lua",
        "utils.lua",
        "push.lua",
        "pull.lua",
        "version",
    }
    local mount_timeout_timer = 0

    while true do
        if fs.exists(string.format("/mnt/%s", cfg.updates.update_floppy_address)) then
            print("Floppy filesystem mounted, copying files...")
            mount_timeout_timer = 0

            break
        end

        if mount_timeout_timer > 5 then
            print("Cannot mount update floppy, cancelling the update...")

            return false
        end

        mount_timeout_timer = mount_timeout_timer + 1

        ---@diagnostic disable-next-line: undefined-field
        os.sleep(1)
    end

    for _, file in pairs(files) do
        local status, traceback = pcall(function()
            shell.execute(
                string.format("cp /mnt/%s/%s ./%s", cfg.updates.update_floppy_address, file, file)
            )
        end)

        if not status then print(traceback) end
    end

    print("Update completed.")

    return true
end

return updates
