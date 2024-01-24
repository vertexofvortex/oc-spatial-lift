-- NOTE: This file is supposed to be as minimalistic as possible
--       because it won't be reloaded when installing an update
--       DO NOT edit unless it's something really crucial

while true do
    -- OpenOS caches the modules, so it's better to forcefully unload them
    -- if we want the updates to apply correctly    
    package.loaded["uncacher"] = nil
    require("uncacher")

    -- Needed to determine whether we need to close or restart the app
    local constants = require("constants")
    local state = {constants.states.IDLE}
    
    -- Start the app
    local starter = require("starter")
    starter(state)
    
    -- If the state is not SHUTTING_DOWN
    -- Then either the program has crashed
    -- Or an update has been installed and the program needs to be restarted
    if state[1] == constants.states.SHUTTING_DOWN then
        break
    end
end