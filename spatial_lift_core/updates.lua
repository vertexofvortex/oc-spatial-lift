local cfg = require("config")
local version = require("version")
local utils = require("spatial_lift_core.utils")

local updates = {}

updates.broadcast_progress = {
    NO_FLOPPY = {},
    BROADCASTING = {},
    RESPONSE_DETECTED = {},
    TIMEOUT = {},
}

function updates.broadcastUpdate(states, progress_callback)
    local e = updates.broadcast_progress

    if utils.getStackInSlot(cfg.transposer_sides.DRIVE, 1) == nil then
        progress_callback(e.NO_FLOPPY, nil)
        return
    end

    progress_callback(e.BROADCASTING, nil)
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
            
            progress_callback(e.RESPONSE_DETECTED, utils.getStackInSlot(cfg.transposer_sides.ENDCHEST, cfg.endchest_slots.UPD_RESPONSE).label)
            update_responses[utils.getStackInSlot(cfg.transposer_sides.ENDCHEST, cfg.endchest_slots.UPD_RESPONSE).label] = true

            utils.transferItem(
                cfg.transposer_sides.ENDCHEST,
                cfg.transposer_sides.ENDCHEST,
                1,
                cfg.endchest_slots.UPD_RESPONSE,
                cfg.endchest_slots.UPD_RESPONSE_ACCEPT
            )
        end

        if request_timeout_timer >= 10 then
            utils.transferItem(
                cfg.transposer_sides.ENDCHEST,
                cfg.transposer_sides.DRIVE,
                1,
                cfg.endchest_slots.UPD_BROADCAST,
                1
            )

            states.update_mode = false

            return
        end

        request_timeout_timer = request_timeout_timer + 1

        ---@diagnostic disable-next-line: undefined-field
        os.sleep(1)
    end
end

updates.check_progress = {
    AVAILABLE = {},
    RESPONSE_ACCEPTED = {},
}

function updates.checkForRequests(states, progress_callback)
    local e = updates.check_progress

    if utils.getStackInSlot(cfg.transposer_sides.ENDCHEST, cfg.endchest_slots.UPD_BROADCAST) == nil then
        return
    end

    if not updates.checkShouldUpdate(
            tonumber(utils.getStackInSlot(cfg.transposer_sides.ENDCHEST, cfg.endchest_slots.UPD_BROADCAST).label)
        ) then
        return
    else
        progress_callback(e.AVAILABLE)
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
    version.install(progress_callback)

    -- When installation completed/failed (doesn't matter), places it's marker item
    -- to the update response slot
    utils.transferItem(cfg.transposer_sides.STORAGE, cfg.transposer_sides.ENDCHEST, 1,
        cfg.storage_slots.CURRENT_MARKER, cfg.endchest_slots.UPD_RESPONSE)

    -- Waits update response accept from the first endpoint
    while true do
        if utils.getStackInSlot(cfg.transposer_sides.ENDCHEST, cfg.endchest_slots.UPD_RESPONSE_ACCEPT) ~= nil then
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
    progress_callback(e.RESPONSE_ACCEPTED)
end

return updates
