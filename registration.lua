local utils = require("utils")
local cfg = require("config")

local registration = {}

function registration.request(transposer, states)
    states.registering_mode = true

    if transposer.getStackInSlot(cfg.transposer_sides.STORAGE, cfg.storage_slots.CURRENT_MARKER) == nil then
        print("Put 64 named markers in the first slot of internal buffer before initiating registration sequence.")

        return false
    end

    local markers_count = transposer.getStackInSlot(
        cfg.transposer_sides.STORAGE, cfg.storage_slots.CURRENT_MARKER
    ).size

    transposer.transferItem(
        cfg.transposer_sides.STORAGE,
        cfg.transposer_sides.ENDCHEST,
        markers_count - 1,
        cfg.storage_slots.CURRENT_MARKER,
        cfg.endchest_slots.REG_REQUEST
    )

    local request_timeout_timer = 0
    local response_counter = 1

    print("#", "Status  ", "Name\n")

    while true do
        if transposer.getStackInSlot(cfg.transposer_sides.ENDCHEST, cfg.endchest_slots.REG_ACCEPT) ~= nil then
            request_timeout_timer = 0

            print(response_counter, "ACCEPTED",
                transposer.getStackInSlot(cfg.transposer_sides.ENDCHEST, cfg.endchest_slots.REG_ACCEPT).label)

            local new_marker_slot = utils.getFirstAvailableSlot(
                transposer.getAllStacks(cfg.transposer_sides.STORAGE).getAll()
            ) + 1

            -- TODO: отлов ошибки, если все слоты заполнены

            transposer.transferItem(
                cfg.transposer_sides.ENDCHEST,
                cfg.transposer_sides.STORAGE,
                1,
                cfg.endchest_slots.REG_ACCEPT,
                new_marker_slot
            )

            response_counter = response_counter + 1
        end

        if request_timeout_timer >= 5 then
            print("\nNo registration response has been detected in the last 5 seconds.")
            print("Consider the registration completed.")

            local remaining_self_markers = transposer.getStackInSlot(
                cfg.transposer_sides.ENDCHEST, cfg.endchest_slots.REG_REQUEST
            )

            transposer.transferItem(
                cfg.transposer_sides.ENDCHEST,
                cfg.transposer_sides.STORAGE,
                remaining_self_markers.size,
                cfg.endchest_slots.REG_REQUEST,
                cfg.storage_slots.CURRENT_MARKER
            )

            states.registering_mode = false

            return (markers_count - 1) - remaining_self_markers.size
        end

        request_timeout_timer = request_timeout_timer + 1

        ---@diagnostic disable-next-line: undefined-field
        os.sleep(1)
    end
end

function registration.checkForRequests(transposer)
    if transposer.getStackInSlot(cfg.transposer_sides.ENDCHEST, cfg.endchest_slots.REG_REQUEST) == nil then
        return false
    end

    if transposer.getStackInSlot(
            cfg.transposer_sides.ENDCHEST, cfg.endchest_slots.REG_REQUEST
        ).label == transposer.getStackInSlot(
            cfg.transposer_sides.STORAGE, cfg.storage_slots.CURRENT_MARKER
        ).label then
        return false
    end

    while true do
        local request_item_stack = transposer.getStackInSlot(cfg.transposer_sides.ENDCHEST,
            cfg.endchest_slots.REG_REQUEST)
        local storage_inventory = transposer.getAllStacks(cfg.transposer_sides.STORAGE).getAll()

        if utils.findItemByLabel(storage_inventory, request_item_stack.label) ~= nil then
            return false
        end

        if transposer.transferItem(
                cfg.transposer_sides.STORAGE, cfg.transposer_sides.ENDCHEST, 1, cfg.storage_slots.CURRENT_MARKER, cfg.endchest_slots.REG_ACCEPT
            ) == 1 then
            print("Got a registration request from " .. request_item_stack.label .. ".")
            print("Exchanging markers...")

            local new_marker_slot = utils.getFirstAvailableSlot(
                transposer.getAllStacks(cfg.transposer_sides.STORAGE).getAll()
            ) + 1

            -- transposer.transferItem(inv.STORAGE, inv.ENDCHEST, 1, 1, slot.REG_ACCEPT)
            transposer.transferItem(
                cfg.transposer_sides.ENDCHEST, cfg.transposer_sides.STORAGE, 1, cfg.endchest_slots.REG_REQUEST,
                new_marker_slot
            )

            print("Markers exchange completed.")

            return true
        end
    end
end

return registration
