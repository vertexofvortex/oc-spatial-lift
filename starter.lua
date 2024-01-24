-- Libraries
local threading = require("thread")

-- Modules
local core_event_loop = require("spatial_lift_view.core_event_loop")
local view_event_loop = require("spatial_lift_view.view_event_loop")

return function(state)
    local core_thread = threading.create(core_event_loop, state)
    local view_thread = threading.create(view_event_loop, state)

    threading.waitForAny({core_thread, view_thread})

    core_thread:kill()
    view_thread:kill()
end