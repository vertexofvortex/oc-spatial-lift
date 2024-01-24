-- Libraries
local threading = require("thread")

while true do
    -- Modules
    local core_event_loop = require("spatial_lift_view.core_event_loop")
    local view_event_loop = require("spatial_lift_view.view_event_loop")

    -- Variables
    local states = {
        registering_mode = false,
        update_mode = false,
        stop_execution = false,
    }

    -- Threads
    local core_thread = threading.create(core_event_loop, states)
    local view_thread = threading.create(view_event_loop, states)

    threading.waitForAny({core_thread, view_thread})

    core_thread:kill()
    view_thread:kill()

    -- OpenOS caches the modules, so it's better to forcefully unload them
    -- if we want the update to apply correctly
    package.loaded.config = nil
    package.loaded.version = nil
    package.loaded.spatial_lift_view.core_event_loop = nil
    package.loaded.spatial_lift_view.view_event_loop = nil
    package.loaded.spatial_lift_core.registration = nil
    package.loaded.spatial_lift_core.teleportation = nil
    package.loaded.spatial_lift_core.updates = nil
    package.loaded.spatial_lift_core.utils = nil

    -- If the stop_execution variable has not been set to true
    -- Then either the program crashed
    -- Or an update has been installed and the program needs to be restarted
    if states.stop_execution then
        break
    end
end