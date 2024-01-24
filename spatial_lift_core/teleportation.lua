local cfg = require("config")
local constants = require("constants")
local utils = require("spatial_lift_core.utils")

local teleportation = {}

teleportation.request_progress = {
    CELL_MISSING = {},
    SELF_TELEPORT = {},
    START_PINGING = {},
    NO_RESPONSE = {},
    ACCEPTED = {},
    SUCCESS = {},
}

function teleportation.request(teleporter_index, progress_callback)
    local e = teleportation.request_progress
    
    if utils.getStackInSlot(cfg.transposer_sides.ENDCHEST, constants.endchest_slots.CELL_STORE) == nil then
        progress_callback(e.CELL_MISSING)
        return
    end

    if teleporter_index == 1 then
        progress_callback(e.SELF_TELEPORT)
        return
    end

    -- Put the cell into the temporary slot
    utils.transferItem(
        cfg.transposer_sides.ENDCHEST,
        cfg.transposer_sides.ENDCHEST,
        1,
        constants.endchest_slots.CELL_STORE,
        constants.endchest_slots.CELL_TEMPSTORE
    )

    local ping_timer = 0

    utils.transferItem(
        cfg.transposer_sides.STORAGE,
        cfg.transposer_sides.ENDCHEST,
        1,
        teleporter_index,
        constants.endchest_slots.TP_REQUEST
    )

    progress_callback(teleportation.request_progress.START_PINGING)

    while true do
        if ping_timer >= 5 then
            utils.transferItem(
                cfg.transposer_sides.ENDCHEST,
                cfg.transposer_sides.STORAGE,
                1,
                constants.endchest_slots.TP_REQUEST,
                teleporter_index
            )

            -- Put the cell back into the storage slot
            utils.transferItem(
                cfg.transposer_sides.ENDCHEST,
                cfg.transposer_sides.ENDCHEST,
                1,
                constants.endchest_slots.CELL_TEMPSTORE,
                constants.endchest_slots.CELL_STORE
            )

            progress_callback(e.NO_RESPONSE)
            return
        end

        if utils.getStackInSlot(cfg.transposer_sides.ENDCHEST, constants.endchest_slots.TP_ACCEPT) ~= nil then
            progress_callback(e.ACCEPTED)
            utils.transferItem(
                cfg.transposer_sides.ENDCHEST,
                cfg.transposer_sides.PORT,
                1,
                constants.endchest_slots.CELL_TEMPSTORE,
                constants.port_slots.IN
            )
            utils.transferItem(
                cfg.transposer_sides.ENDCHEST,
                cfg.transposer_sides.STORAGE,
                1,
                constants.endchest_slots.TP_ACCEPT,
                teleporter_index
            )

            ---@diagnostic disable-next-line: undefined-field
            os.sleep(3)

            teleportation.initiate() -- always returns true
            
            progress_callback(e.SUCCESS)
            return
        end

        ping_timer = ping_timer + 1
        os.sleep(1)
    end
end

function teleportation.initiate()
    utils.toggleSpatialIO()

    utils.transferItem(
        cfg.transposer_sides.PORT,
        cfg.transposer_sides.ENDCHEST,
        1,
        constants.port_slots.OUT,
        constants.endchest_slots.CELL_SEND)

    return true
end

teleportation.check_progress = {
    INCOMING = {},
    TELEPORTATION_COMPLETED = {},
}

function teleportation.checkForRequests(teleporters, progress_callback)
    local e = teleportation.check_progress
    local request_item = utils.getStackInSlot(cfg.transposer_sides.ENDCHEST, constants.endchest_slots.TP_REQUEST)

    if request_item == nil then
        return
    end

    if request_item.label == teleporters[1] then
        progress_callback(e.INCOMING)
        utils.transferItem(cfg.transposer_sides.ENDCHEST,
            cfg.transposer_sides.ENDCHEST,
            1,
            constants.endchest_slots.TP_REQUEST,
            constants.endchest_slots.TP_ACCEPT
        )

        teleportation.accept()
        progress_callback(e.TELEPORTATION_COMPLETED)
        return
    end
end

function teleportation.accept()
    while true do
        if
            utils.getStackInSlot(
                cfg.transposer_sides.ENDCHEST,
                constants.endchest_slots.CELL_SEND
            ) ~= nil then
            utils.transferItem(
                cfg.transposer_sides.ENDCHEST,
                cfg.transposer_sides.PORT,
                1,
                constants.endchest_slots.CELL_SEND,
                constants.port_slots.IN
            )
            utils.toggleSpatialIO()
            utils.transferItem(
                cfg.transposer_sides.PORT,
                cfg.transposer_sides.ENDCHEST,
                1,
                constants.port_slots.OUT,
                constants.endchest_slots.CELL_STORE
            )

            break
        end
    end

    return true
end

return teleportation
