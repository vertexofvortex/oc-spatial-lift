-- Libraries
local threading = require("thread")
local cfg = require("config")

while true do
    -- Modules
    local core_event_loop = require("spatial_lift_view.core_event_loop")
    local view_event_loop = require("spatial_lift_view.view_event_loop")

    -- Variables
    local state = {cfg.states.IDLE}

    -- Threads
    local core_thread = threading.create(core_event_loop, state)
    local view_thread = threading.create(view_event_loop, state)

    threading.waitForAny({core_thread, view_thread})

    core_thread:kill()
    view_thread:kill()

    -- OpenOS caches the modules, so it's better to forcefully unload them
    -- if we want the update to apply correctly
    package.loaded["config"] = nil
    package.loaded["version"] = nil
    package.loaded["spatial_lift_view.core_event_loop"] = nil
    package.loaded["spatial_lift_view.view_event_loop"] = nil
    package.loaded["spatial_lift_core.registration"] = nil
    package.loaded["spatial_lift_core.teleportation"] = nil
    package.loaded["spatial_lift_core.updates"] = nil
    package.loaded["spatial_lift_core.utils"] = nil

    -- If the state is not SHUTTING_DOWN
    -- Then either the program crashed
    -- Or an update has been installed and the program needs to be restarted
    if state[1] == cfg.states.SHUTTING_DOWN then
        break
    end
end