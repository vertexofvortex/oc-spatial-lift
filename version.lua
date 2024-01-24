local threading = require("thread")
local io = require("io")
local shell = require("shell")
local fs = require("filesystem")

local cfg = require("config")

local version = {}

-- Get current program version from file
function version.getCurrentVersion()
    local version_file = io.open("./version")
    if version_file == nil then
        return 0.0
    end

    local version_text = version_file:read("*a")
    local version_number = tonumber(version_text)
    return version_number
end

-- Checks current version and new available version,
-- checks if updates disabled by configuration file.
-- Returns true if update should be installed and false if not
function version.checkShouldUpdate(update_version)
    return not cfg.updates.disable_updates and update_version > version.getCurrentVersion()
end


version.install_progress = {
    FLOPPY_NOT_MOUNTED = {},
    FLOPPY_MOUNTED = {},
    UPDATE_COMPLETED = {},
}

function version.install(progress_callback)
    local e = version.install_progress
    local mount_timeout_timer = 0

    while true do
        if fs.exists(string.format("/mnt/%s", cfg.updates.update_floppy_address)) then
            progress_callback(e.FLOPPY_MOUNTED)
            break
        end

        if mount_timeout_timer > 5 then
            progress_callback(e.FLOPPY_NOT_MOUNTED)
            return
        end

        mount_timeout_timer = mount_timeout_timer + 1

        ---@diagnostic disable-next-line: undefined-field
        os.sleep(1)
    end

    -- First save the config file
    shell.execute("mv config.lua config.lua.local")
    -- Copy everything from the floppy
    shell.execute("cp -r /mnt/" .. cfg.updates.update_floppy_address .. "/* ./")
    -- Restore the original config
    shell.execute("mv config.lua.local config.lua") 

    progress_callback(e.UPDATE_COMPLETED)
end

return version