local teleportation = {}

function teleportation.request(teleporter_index, transposer, redstone, utils)
    if transposer.getStackInSlot(cfg.transposer_sides.ENDCHEST, cfg.endchest_slots.CELL_STORE) == nil then
        print("The spatial cell is missing. Perhaps someone else is using the teleporter right now?")
        return false
    end

    if teleporter_index == 1 then
        print("Cannot teleport to self.")
        return false
    end

    -- Put the cell into the temporary slot
    transposer.transferItem(
        cfg.transposer_sides.ENDCHEST,
        cfg.transposer_sides.ENDCHEST,
        1,
        cfg.endchest_slots.CELL_STORE,
        cfg.endchest_slots.CELL_TEMPSTORE
    )

    local ping_timer = 0

    transposer.transferItem(
        cfg.transposer_sides.STORAGE,
        cfg.transposer_sides.ENDCHEST,
        1,
        teleporter_index,
        cfg.endchest_slots.TP_REQUEST
    )

    print("Pinging destination endpoint...")

    while true do
        if ping_timer >= 5 then
            transposer.transferItem(
                cfg.transposer_sides.ENDCHEST,
                cfg.transposer_sides.STORAGE,
                1,
                cfg.endchest_slots.TP_REQUEST,
                teleporter_index
            )

            -- Put the cell back into the storage slot
            transposer.transferItem(
                cfg.transposer_sides.ENDCHEST,
                cfg.transposer_sides.ENDCHEST,
                1,
                cfg.endchest_slots.CELL_TEMPSTORE,
                cfg.endchest_slots.CELL_STORE
            )

            print("Connection refused. Destination endpoint is unavailable.")
            print("Check if teleporter is properly working and chunkloaded.")

            return false
        end

        if transposer.getStackInSlot(cfg.transposer_sides.ENDCHEST, cfg.endchest_slots.TP_ACCEPT) ~= nil then
            print("Teleportation request accepted by destination endpoint!")
            transposer.transferItem(
                cfg.transposer_sides.ENDCHEST,
                cfg.transposer_sides.PORT,
                1,
                cfg.endchest_slots.CELL_TEMPSTORE,
                cfg.port_slots.IN
            )
            transposer.transferItem(
                cfg.transposer_sides.ENDCHEST,
                cfg.transposer_sides.STORAGE,
                1,
                cfg.endchest_slots.TP_ACCEPT,
                teleporter_index
            )

            print("Teleporting in 3 seconds...")

            ---@diagnostic disable-next-line: undefined-field
            os.sleep(3)

            teleportation.initiate(transposer, redstone) -- always returns true

            return true
        end

        ping_timer = ping_timer + 1
        os.sleep(1)
    end
end

function teleportation.initiate(transposer, redstone, utils)
    utils.toggleSpatialIO(redstone)

    transposer.transferItem(
        cfg.transposer_sides.PORT,
        cfg.transposer_sides.ENDCHEST,
        1,
        cfg.port_slots.OUT,
        cfg.endchest_slots.CELL_SEND)

    print("Teleportation...")

    return true
end

function teleportation.checkForRequests(utils, transposer, redstone, teleporters)
    local request_item = transposer.getStackInSlot(cfg.transposer_sides.ENDCHEST, cfg.endchest_slots.TP_REQUEST)

    if request_item == nil then
        return false
    end

    if request_item.label == teleporters[1] then
        print("Incoming teleportation request accepted.")
        transposer.transferItem(cfg.transposer_sides.ENDCHEST,
            cfg.transposer_sides.ENDCHEST,
            1,
            cfg.endchest_slots.TP_REQUEST,
            cfg.endchest_slots.TP_ACCEPT
        )

        teleportation.accept(transposer, redstone)

        return true
    end
end

function teleportation.accept(utils, transposer, redstone)
    while true do
        if
            transposer.getStackInSlot(
                cfg.transposer_sides.ENDCHEST,
                cfg.endchest_slots.CELL_SEND
            ) ~= nil then
            transposer.transferItem(
                cfg.transposer_sides.ENDCHEST,
                cfg.transposer_sides.PORT,
                1,
                cfg.endchest_slots.CELL_SEND,
                cfg.port_slots.IN
            )
            utils.toggleSpatialIO(redstone)
            transposer.transferItem(
                cfg.transposer_sides.PORT,
                cfg.transposer_sides.ENDCHEST,
                1,
                cfg.port_slots.OUT,
                cfg.endchest_slots.CELL_STORE
            )

            break
        end
    end

    print("Teleportation completed. Welcome aboard!")

    return true
end

return teleportation
