local sides = require("sides")

local config = {
    transposer_sides = {
        ENDCHEST = sides.top,
        STORAGE = sides.north,
        PORT = sides.south,
        DRIVE = sides.west,
    },

    redstone_sides = {
        PORT = sides.bottom,
    },

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

    updates = {
        disable_updates = false,
        update_floppy_address = "8a6",
    },
}

return config
