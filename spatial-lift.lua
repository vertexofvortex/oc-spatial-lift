while true do
    -- Libraries
    local threading = require("thread")
    local component = require("component")

    -- Modules
    local cfg = require("config")
    local utils = require("spatial-lift-core/utils")
    local updates = require("spatial-lift-core/updates")
    local registration = require("spatial-lift-core/registration")
    local teleportation = require("spatial-lift-core/teleportation")
    local core_event_loop = require("spatial-lift-core/core_event_loop")
    local view_event_loop = require("spatial-lift-view/view_event_loop")

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
    local core_thread = threading.create(core_event_loop, utils, updates, registration, teleportation, transposer, redstone, cfg, states)
    local view_thread = threading.create(view_event_loop, utils, updates, registration, teleportation, transposer, redstone, cfg, states)

    threading.waitForAny({core_thread, view_thread})

    if core_thread:status() == "running" then
        core_thread:kill()
    elseif view_thread:status() == "running" then
        view_thread:kill()
    end

    -- If the stop_execution variable has not been set to true
    -- Then either the program crashed
    -- Or an update has been installed and the program needs to be restarted
    if states.stop_execution then
        break
    end
end