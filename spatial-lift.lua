while true do
    -- Libraries
    local threading = require("thread")
    local component = require("component")

    -- Modules
    local cfg = require("config")
    local utils = require("spatial-lift-core/utils")
    local updates = require("spatial-lift-core/updates")
    local updates = require("spatial-lift-core/registration")
    local updates = require("spatial-lift-core/teleportation")
    local core-event-loop = require("spatial-lift-core/core-event-loop")
    local view-event-loop = require("spatial-lift-view/view-event-loop")

    -- Components
    local transposer = component.proxy(component.list("transposer")())
    local redstone = component.proxy(component.list("redstone")())

    -- Variables
    local states = {
        registering_mode = false,
        update_mode = false,
        stop_execution = false,
    }

    -- Threads
    local core_thread = threading.create(core-event-loop, utils, updates, registration, teleportation, transposer, redstone, cfg, states)
    local view_thread = threading.create(view-event-loop, updates, utils, registration, teleportation, transposer, redstone, cfg, states)

    threading.waitForAny({core_thread, view_thread})

    if core_thread == "running" then
        core_thread:kill()
    elseif view_thread == "running" then
        view_thread:kill()
    end

    -- If the stop_execution variable has not been set to true
    -- Then either the program crashed
    -- Or an update has been installed and the program needs to be restarted
    if states.stop_execution then
        break
    end
end