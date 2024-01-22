local sides = require("sides")

local utils = {}

-- Returns the first empty slot index in inventory (starting with zero)
function utils.getFirstAvailableSlot(inventory)
    for slot_index, item_stack in pairs(inventory) do
        if item_stack.label == nil then
            return slot_index
        end
    end
end

-- Returns the first slot index (starting with zero) which contains an item with provided label
-- and returns nil if item not found
function utils.findItemByLabel(inventory, item_label)
    for slot_index, item_stack in pairs(inventory) do
        if item_stack ~= nil and item_stack.label == item_label then
            return slot_index
        end
    end

    return nil
end

function utils.getDestinationTeleporters(transposer, cfg)
    local marker_items = transposer.getAllStacks(cfg.transposer_sides.STORAGE).getAll()
    local teleporters_list = {}

    for slot, marker_item in pairs(marker_items) do
        teleporters_list[slot + 1] = marker_item.label
    end

    return teleporters_list
end

function utils.toggleSpatialIO(redstone, cfg)
    redstone.setOutput(cfg.redstone_sides.PORT, 15)

    ---@diagnostic disable-next-line: undefined-field
    os.sleep(0.2)
    redstone.setOutput(cfg.redstone_sides.PORT, 0)

    return true
end

return utils
