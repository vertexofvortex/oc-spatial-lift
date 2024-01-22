return function(utils, updates, registration, teleportation, transposer, redstone, cfg, states)
    local teleporters = utils.getDestinationTeleporters(transposer)

    while true do
        local state, traceback = pcall(function()
            teleportation.checkForRequests(teleporters, utils, transposer, redstone, cfg)

            if not states.registering_mode then
                registration.checkForRequests(utils, transposer, cfg)
            end

            -- TODO: check if in tp. or reg. process
            if not states.update_mode then
                updates.checkForRequests(transposer, states)
            end
        end)

        if not state then
            print(traceback)
        end

        ---@diagnostic disable-next-line: undefined-field
        os.sleep(1)
    end
end