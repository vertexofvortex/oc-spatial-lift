local cfg = require("config")
local utils = require("spatial_lift_core.utils")

local registration = {}

registration.request_progress = {
    NO_MARKERS = {},
    INITIATE = {},
    REGISTRATED = {},
    FINISH = {},
}

function registration.request(progress_callback)
    local e = registration.request_progress

    if utils.getStackInSlot(cfg.transposer_sides.STORAGE, cfg.storage_slots.CURRENT_MARKER) == nil then
        progress_callback(e.NO_MARKERS, nil)
        return
    end

    local markers_count = utils.getStackInSlot(cfg.transposer_sides.STORAGE, cfg.storage_slots.CURRENT_MARKER).size

    utils.transferItem(
        cfg.transposer_sides.STORAGE,
        cfg.transposer_sides.ENDCHEST,
        markers_count - 1,
        cfg.storage_slots.CURRENT_MARKER,
        cfg.endchest_slots.REG_REQUEST
    )

    local request_timeout_timer = 0

    progress_callback(e.INITIATE, nil)

    while true do
        if utils.getStackInSlot(cfg.transposer_sides.ENDCHEST, cfg.endchest_slots.REG_ACCEPT) ~= nil then
            request_timeout_timer = 0

            progress_callback(e.REGISTRATED, utils.getStackInSlot(cfg.transposer_sides.ENDCHEST, cfg.endchest_slots.REG_ACCEPT).label)

            local new_marker_slot = utils.getFirstAvailableSlot(
                utils.getAllStacks(cfg.transposer_sides.STORAGE).getAll()
            ) + 1

            -- TODO: отлов ошибки, если все слоты заполнены

            utils.transferItem(
                cfg.transposer_sides.ENDCHEST,
                cfg.transposer_sides.STORAGE,
                1,
                cfg.endchest_slots.REG_ACCEPT,
                new_marker_slot
            )
        end

        if request_timeout_timer >= 5 then
            progress_callback(e.FINISH, nil)

            local remaining_self_markers = utils.getStackInSlot(
                cfg.transposer_sides.ENDCHEST, cfg.endchest_slots.REG_REQUEST
            )

            utils.transferItem(
                cfg.transposer_sides.ENDCHEST,
                cfg.transposer_sides.STORAGE,
                remaining_self_markers.size,
                cfg.endchest_slots.REG_REQUEST,
                cfg.storage_slots.CURRENT_MARKER
            )
            return
        end

        request_timeout_timer = request_timeout_timer + 1

        ---@diagnostic disable-next-line: undefined-field
        os.sleep(1)
    end
end

registration.check_progress = {
    REQUEST = {},
    EXCHANGED = {},
}

function registration.checkForRequests(progress_callback)
    local e = registration.check_progress
    if utils.getStackInSlot(cfg.transposer_sides.ENDCHEST, cfg.endchest_slots.REG_REQUEST) == nil then
        return
    end

    if utils.getStackInSlot(
            cfg.transposer_sides.ENDCHEST, cfg.endchest_slots.REG_REQUEST
        ).label == utils.getStackInSlot(
            cfg.transposer_sides.STORAGE, cfg.storage_slots.CURRENT_MARKER
        ).label then
        return
    end

    while true do
        local request_item_stack = utils.getStackInSlot(cfg.transposer_sides.ENDCHEST,
            cfg.endchest_slots.REG_REQUEST)
        local storage_inventory = utils.getAllStacks(cfg.transposer_sides.STORAGE).getAll()

        if utils.findItemByLabel(storage_inventory, request_item_stack.label) ~= nil then
            return
        end

        if utils.transferItem(
                cfg.transposer_sides.STORAGE, cfg.transposer_sides.ENDCHEST, 1, cfg.storage_slots.CURRENT_MARKER, cfg.endchest_slots.REG_ACCEPT
            ) == 1 then
            
            progress_callback(e.REQUEST, request_item_stack.label)

            local new_marker_slot = utils.getFirstAvailableSlot(
                utils.getAllStacks(cfg.transposer_sides.STORAGE).getAll()
            ) + 1

            -- transposer.transferItem(inv.STORAGE, inv.ENDCHEST, 1, 1, slot.REG_ACCEPT)
            utils.transferItem(
                cfg.transposer_sides.ENDCHEST, cfg.transposer_sides.STORAGE, 1, cfg.endchest_slots.REG_REQUEST,
                new_marker_slot
            )

            progress_callback(e.EXCHANGED, nil)

            return
        end
    end
end

return registration
