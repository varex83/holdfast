-- Inventory System
-- Tracks resources carried by a single player.
-- Weight capacity varies by class (Scout > Engineer > Archer > Warrior).

local ItemContainer = require("src.inventory.itemcontainer")
local Resources = require("data.resources")

local Inventory = ItemContainer:extend()

-- Max carry weight per class (in weight units)
local CLASS_CAPACITY = {
    scout    = 20,
    engineer = 15,
    archer   = 12,
    warrior  = 8,
}
local DEFAULT_CAPACITY = 12

function Inventory:new(class)
    Inventory.super.new(self)
    self._capacity = CLASS_CAPACITY[class] or DEFAULT_CAPACITY
    self._weight = 0
end

-- Returns the weight of one unit of a resource type.
local function unitWeight(resourceType)
    local def = Resources[resourceType]
    return def and def.weight or 1
end

-- Add `amount` units of `resourceType`. Returns actual amount added
-- (may be less if near capacity).
function Inventory:add(resourceType, amount)
    resourceType = self:_normalizeResourceType(resourceType)
    amount = self:_normalizeAmount(amount)
    if amount == 0 then
        return 0
    end

    local w = unitWeight(resourceType)
    local canAdd = math.floor((self._capacity - self._weight) / w)
    local actual = math.min(amount, canAdd)
    if actual <= 0 then
        return 0
    end

    Inventory.super.add(self, resourceType, actual)
    self._weight = self._weight + actual * w
    return actual
end

-- Remove `amount` units. Returns actual amount removed.
function Inventory:remove(resourceType, amount)
    resourceType = self:_normalizeResourceType(resourceType)
    local actual = Inventory.super.remove(self, resourceType, amount)
    if actual <= 0 then
        return 0
    end

    self._weight = self._weight - actual * unitWeight(resourceType)
    if self._weight < 0 then
        self._weight = 0
    end
    return actual
end

-- Returns amount held of a resource type.
function Inventory:count(resourceType)
    return Inventory.super.count(self, resourceType)
end

-- Returns total carry weight currently used.
function Inventory:totalWeight()
    return self._weight
end

-- Returns max carry weight for this class.
function Inventory:capacity()
    return self._capacity
end

-- Returns 0..1 fill fraction.
function Inventory:fillRatio()
    return self._weight / self._capacity
end

function Inventory:isFull()
    return self._weight >= self._capacity
end

function Inventory:isEmpty()
    return self._weight == 0
end

-- Returns a copy of the items table (resourceType → amount).
function Inventory:getItems()
    return Inventory.super.getItems(self)
end

-- Empty the inventory completely. Returns the items that were removed.
function Inventory:clear()
    local removed = Inventory.super.clear(self)
    self._weight = 0
    return removed
end

return Inventory
