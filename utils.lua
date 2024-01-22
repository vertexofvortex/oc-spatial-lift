local sides = require("sides")
local component = require("component")

local transposer = component.proxy(component.list("transposer")())
local redstone = component.proxy(component.list("redstone")())

local cfg = require("config")

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

function utils.getDestinationTeleporters()
    local marker_items = transposer.getAllStacks(cfg.transposer_sides.STORAGE).getAll()
    local teleporters_list = {}

    for slot, marker_item in pairs(marker_items) do
        teleporters_list[slot + 1] = marker_item.label
    end

    return teleporters_list
end

function utils.toggleSpatialIO()
    redstone.setOutput(cfg.redstone_sides.PORT, 15)

    ---@diagnostic disable-next-line: undefined-field
    os.sleep(0.2)
    redstone.setOutput(cfg.redstone_sides.PORT, 0)

    return true
end

function utils.getStackInSlot(side, slot)
    return transposer.getStackInSlot(side, slot)
end

function utils.transferItem(from_side, to_side, amount, from_slot, to_slot)
    return transposer.transferItem(from_side, to_side, amount, from_slot, to_slot)
end

function utils.getAllStacks(side)
    return transposer.getAllStacks(side)
end

return utils
