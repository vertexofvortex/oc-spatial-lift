local sides = require("sides")


-- This configuration is local to just one teleporter
-- Any changes made here won't be redistributed through the network
-- Also this file won't be rewritten during updates

-- USER CONFIGURATION STARTS HERE
local config = {
    transposer_sides = {
        ENDCHEST = sides.top,
        STORAGE = sides.north,
        PORT = sides.south,
        DRIVE = sides.east,
    },

    redstone_sides = {
        PORT = sides.bottom,
    },

    updates = {
        disable_updates = false,
        update_floppy_address = "54d",
    },
}
-- USER CONFIGURATION ENDS HERE


-- The constants module includes default configuration in case something is missing
local constants = require("constants")

return config
