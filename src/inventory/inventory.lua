-- Inventory System
-- Tracks resources carried by a single player.
-- Weight capacity varies by class (Scout > Engineer > Archer > Warrior).

local Class     = require("lib.class")
local Resources = require("data.resources")

local Inventory = Class:extend()

-- Max carry weight per class (in weight units)
local CLASS_CAPACITY = {
    scout    = 20,
    engineer = 15,
    archer   = 12,
    warrior  = 8,
}
local DEFAULT_CAPACITY = 12

function Inventory:new(class)
    self._items    = {}   -- resourceType → amount
    self._capacity = CLASS_CAPACITY[class] or DEFAULT_CAPACITY
    self._weight   = 0
end

-- Returns the weight of one unit of a resource type.
local function unitWeight(resourceType)
    local def = Resources[resourceType]
    return def and def.weight or 1
end

-- Add `amount` units of `resourceType`. Returns actual amount added
-- (may be less if near capacity).
function Inventory:add(resourceType, amount)
    local w       = unitWeight(resourceType)
    local canAdd  = math.floor((self._capacity - self._weight) / w)
    local actual  = math.min(amount, canAdd)
    if actual <= 0 then return 0 end

    self._items[resourceType] = (self._items[resourceType] or 0) + actual
    self._weight = self._weight + actual * w
    return actual
end

-- Add `amount` units even if it exceeds the normal carry capacity.
-- Used for special cases like casino payouts that should remain re-bettable.
function Inventory:forceAdd(resourceType, amount)
    if amount <= 0 then return 0 end

    self._items[resourceType] = (self._items[resourceType] or 0) + amount
    self._weight = self._weight + amount * unitWeight(resourceType)
    return amount
end

-- Remove `amount` units. Returns actual amount removed.
function Inventory:remove(resourceType, amount)
    local have   = self._items[resourceType] or 0
    local actual = math.min(amount, have)
    if actual <= 0 then return 0 end

    self._items[resourceType] = have - actual
    if self._items[resourceType] == 0 then
        self._items[resourceType] = nil
    end
    self._weight = self._weight - actual * unitWeight(resourceType)
    return actual
end

-- Returns amount held of a resource type.
function Inventory:count(resourceType)
    return self._items[resourceType] or 0
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
    local copy = {}
    for k, v in pairs(self._items) do copy[k] = v end
    return copy
end

-- Empty the inventory completely. Returns the items that were removed.
function Inventory:clear()
    local removed = self:getItems()
    self._items  = {}
    self._weight = 0
    return removed
end

return Inventory
