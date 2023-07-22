local utils = require("utils")

local teleportation = {}

function teleportation.initiateTeleportation(transposer, inv, slot, redstone)
    utils.toggleSpatialIO(redstone)
    transposer.transferItem(inv.PORT, inv.ENDCHEST, 1, 2, slot.CELL_SEND)

    print("Teleportation...")

    return true
end

function teleportation.acceptTeleportation(transposer, inv, slot, redstone)
    while true do
        if transposer.getStackInSlot(inv.ENDCHEST, slot.CELL_SEND) ~= nil then
            transposer.transferItem(inv.ENDCHEST, inv.PORT, 1, slot.CELL_SEND, 1)
            utils.toggleSpatialIO(redstone)
            transposer.transferItem(inv.PORT, inv.ENDCHEST, 1, 2, slot.CELL_STORE)

            break
        end
    end

    print("Teleportation completed. Welcome aboard!")

    return true
end

function teleportation.requestTeleportation(transposer, inv, slot, teleporter_index, redstone)
    if transposer.getStackInSlot(inv.ENDCHEST, slot.CELL_STORE) == nil then
        print("The spatial cell is missing. Perhaps someone else is using the teleporter right now?")

        return false
    end

    if teleporter_index == 1 then
        print("Cannot teleport to itself.")

        return false
    end

    -- Put the cell into the temporary slot
    transposer.transferItem(inv.ENDCHEST, inv.ENDCHEST, 1, slot.CELL_STORE, slot.CELL_TEMPSTORE)

    local ping_timer = 0

    transposer.transferItem(inv.STORAGE, inv.ENDCHEST, 1, teleporter_index, slot.TP_REQUEST)

    print("Pinging destination endpoint...")

    while true do
        if ping_timer >= 5 then
            transposer.transferItem(inv.ENDCHEST, inv.STORAGE, 1, slot.TP_REQUEST, teleporter_index)

            -- Put the cell back into the storage slot
            transposer.transferItem(inv.ENDCHEST, inv.ENDCHEST, 1, slot.CELL_TEMPSTORE, slot.CELL_STORE)

            print("Connection refused. Destination endpoint is unavailable.")
            print("Check if teleporter is properly working and chunkloaded.")

            return false
        end

        if transposer.getStackInSlot(inv.ENDCHEST, slot.TP_ACCEPT) ~= nil then
            print("Teleportation request accepted by destination endpoint!")
            transposer.transferItem(inv.ENDCHEST, inv.PORT, 1, slot.CELL_TEMPSTORE, 1)
            transposer.transferItem(inv.ENDCHEST, inv.STORAGE, 1, slot.TP_ACCEPT, teleporter_index)

            print("Teleporting in 3 seconds...")

            ---@diagnostic disable-next-line: undefined-field
            os.sleep(3)

            teleportation.initiateTeleportation(transposer, inv, slot, redstone) -- always returns true

            return true
        end

        ping_timer = ping_timer + 1
        os.sleep(1)
    end
end

function teleportation.checkTeleportationRequests(transposer, inv, slot, teleporters, redstone)
    local request_item = transposer.getStackInSlot(inv.ENDCHEST, slot.TP_REQUEST)

    if request_item == nil then
        return false
    end

    if request_item.label == teleporters[1] then
        print("Incoming teleportation request accepted.")
        transposer.transferItem(inv.ENDCHEST, inv.ENDCHEST, 1, slot.TP_REQUEST, slot.TP_ACCEPT)

        teleportation.acceptTeleportation(transposer, inv, slot, redstone)

        return true
    end
end

return teleportation
