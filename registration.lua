local utils = require("utils")

local registration = {}

function registration.requestRegistration(transposer, inv, slot, states)
    states.registering_mode = true

    if transposer.getStackInSlot(inv.STORAGE, 1) == nil then
        print("Put 64 named markers in the first slot of internal buffer before initiating registration sequence.")

        return false
    end

    -- TODO: enum for buffer slots
    local markers_count = transposer.getStackInSlot(inv.STORAGE, 1).size
    transposer.transferItem(inv.STORAGE, inv.ENDCHEST, markers_count - 1, 1, slot.REG_REQUEST)

    local request_timeout_timer = 0
    local response_counter = 1

    print("#", "Status  ", "Name\n")

    while true do
        if transposer.getStackInSlot(inv.ENDCHEST, slot.REG_ACCEPT) ~= nil then
            request_timeout_timer = 0

            print(response_counter, "ACCEPTED", transposer.getStackInSlot(inv.ENDCHEST, slot.REG_ACCEPT).label)

            local new_marker_slot = utils.getFirstAvailableSlot(
                transposer.getAllStacks(inv.STORAGE).getAll()
            ) + 1

            -- TODO: отлов ошибки, если все слоты заполнены

            transposer.transferItem(inv.ENDCHEST, inv.STORAGE, 1, slot.REG_ACCEPT, new_marker_slot)

            response_counter = response_counter + 1
        end

        if request_timeout_timer >= 5 then
            print("\nNo registration response has been detected in the last 5 seconds.")
            print("Consider the registration completed.")

            local remaining_self_markers = transposer.getStackInSlot(inv.ENDCHEST, slot.REG_REQUEST)

            transposer.transferItem(inv.ENDCHEST, inv.STORAGE, remaining_self_markers.size, slot.REG_REQUEST, 1)

            states.registering_mode = false

            return (markers_count - 1) - remaining_self_markers.size
        end

        request_timeout_timer = request_timeout_timer + 1

        ---@diagnostic disable-next-line: undefined-field
        os.sleep(1)
    end
end

function registration.checkRegistrationRequests(transposer, inv, slot)
    if transposer.getStackInSlot(inv.ENDCHEST, slot.REG_REQUEST) == nil then
        return false
    end

    if transposer.getStackInSlot(inv.ENDCHEST, slot.REG_REQUEST).label == transposer.getStackInSlot(inv.STORAGE, 1).label then
        return false
    end

    while true do
        local request_item_stack = transposer.getStackInSlot(inv.ENDCHEST, slot.REG_REQUEST)
        local storage_inventory = transposer.getAllStacks(inv.STORAGE).getAll()

        if utils.findItemByLabel(storage_inventory, request_item_stack.label) ~= nil then
            return false
        end

        if transposer.transferItem(inv.STORAGE, inv.ENDCHEST, 1, 1, slot.REG_ACCEPT) == 1 then
            print("Got a registration request from " .. request_item_stack.label .. ".")
            print("Exchanging markers...")

            local new_marker_slot = utils.getFirstAvailableSlot(
                transposer.getAllStacks(inv.STORAGE).getAll()
            ) + 1

            -- transposer.transferItem(inv.STORAGE, inv.ENDCHEST, 1, 1, slot.REG_ACCEPT)
            transposer.transferItem(inv.ENDCHEST, inv.STORAGE, 1, slot.REG_REQUEST, new_marker_slot)

            print("Markers exchange completed.")

            return true
        end
    end
end

return registration
