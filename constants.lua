local sides = require("sides")

local constants = {
    endchest_slots = {
        CELL_STORE = 27,
        CELL_TEMPSTORE = 26,
        CELL_SEND = 25,

        TP_REQUEST = 24,
        TP_ACCEPT = 23,

        REG_REQUEST = 18,
        REG_ACCEPT = 17,

        UPD_BROADCAST = 10,
        UPD_RESPONSE = 11,
        UPD_RESPONSE_ACCEPT = 12,
    },

    storage_slots = {
        CURRENT_MARKER = 1
    },

    port_slots = {
        IN = 1,
        OUT = 2,
    },

    states = {
        IDLE = {},
        TELEPORTING = {},
        REGISTRATING = {},
        UPDATING = {},
        SHUTTING_DOWN = {},
    },
}

local default_config = {
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

-- User might have an outdated configuration file with missing values
-- So we add missing information from the default config
local cfg = require("config")
for section, configs in pairs(default_config) do
    if cfg[section] == nil then
        cfg[section] = configs
    else
        for key, val in pairs(default_config[section]) do
            if cfg[section][key] == nil then
                cfg[section][key] = val
            end
        end
    end
end

return constants
