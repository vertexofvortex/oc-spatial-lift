-- Libraries
local threading = require("thread")

while true do
    -- Modules
    local core_event_loop = require("spatial-lift/core_event_loop")
    local view_event_loop = require("spatial-lift/view_event_loop")

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