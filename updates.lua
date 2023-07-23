local updates = {}

-- Checks for an updates in a background
function updates.check()
    return false
end

-- Checks current version and new available version,
-- checks if updates disabled by configuration file.
-- Returns true if update should be installed and false if not
function updates.checkShouldUpdate()
    return false
end

-- Installs an update
function updates.install()
    return false
end

return updates
