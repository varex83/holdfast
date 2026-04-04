--- Item Container Base Class
-- Provides common functionality for storing and managing resource items
-- Used as a base for Inventory and SupplyDepot

local Class = require("lib.class")
local ItemContainer = Class:extend()

function ItemContainer:new()
    self._items = {} -- resourceType → amount
end

function ItemContainer:_normalizeResourceType(resourceType)
    assert(type(resourceType) == "string" and resourceType ~= "", "resourceType must be a non-empty string")
    return resourceType
end

function ItemContainer:_normalizeAmount(amount)
    amount = tonumber(amount) or 0
    assert(amount >= 0, "amount must be non-negative")
    return math.floor(amount)
end

--- Add items to the container
-- @param resourceType Type of resource to add
-- @param amount Number of items to add
-- @return Actual amount added (may be less if capacity limited in subclass)
function ItemContainer:add(resourceType, amount)
    resourceType = self:_normalizeResourceType(resourceType)
    amount = self:_normalizeAmount(amount)
    if amount == 0 then
        return 0
    end

    self._items[resourceType] = (self._items[resourceType] or 0) + amount
    return amount
end

--- Remove items from the container
-- @param resourceType Type of resource to remove
-- @param amount Number of items to remove
-- @return Actual amount removed (may be less if not enough in container)
function ItemContainer:remove(resourceType, amount)
    resourceType = self:_normalizeResourceType(resourceType)
    amount = self:_normalizeAmount(amount)
    if amount == 0 then
        return 0
    end

    local have = self._items[resourceType] or 0
    local actual = math.min(amount, have)
    self._items[resourceType] = have - actual

    -- Clean up zero entries
    if self._items[resourceType] == 0 then
        self._items[resourceType] = nil
    end

    return actual
end

--- Get count of a specific resource
-- @param resourceType Type of resource to count
-- @return Number of items in container
function ItemContainer:count(resourceType)
    resourceType = self:_normalizeResourceType(resourceType)
    return self._items[resourceType] or 0
end

--- Check if container has at least the specified amount
-- @param resourceType Type of resource to check
-- @param amount Amount required
-- @return true if container has >= amount of the resource
function ItemContainer:has(resourceType, amount)
    resourceType = self:_normalizeResourceType(resourceType)
    amount = self:_normalizeAmount(amount)
    return (self._items[resourceType] or 0) >= amount
end

--- Get a copy of all items
-- @return Table of resourceType → amount
function ItemContainer:getItems()
    local copy = {}
    for k, v in pairs(self._items) do
        copy[k] = v
    end
    return copy
end

function ItemContainer:getSortedItems()
    local items = {}
    for resourceType, amount in pairs(self._items) do
        items[#items + 1] = {
            resourceType = resourceType,
            amount = amount,
        }
    end

    table.sort(items, function(a, b)
        return a.resourceType < b.resourceType
    end)

    return items
end

--- Clear all items from the container
-- @return Table of items that were removed
function ItemContainer:clear()
    local removed = self:getItems()
    self._items = {}
    return removed
end

--- Check if container is empty
-- @return true if no items in container
function ItemContainer:isEmpty()
    for _ in pairs(self._items) do
        return false
    end
    return true
end

--- Get total number of item types (not count)
-- @return Number of different resource types in container
function ItemContainer:getTypeCount()
    local count = 0
    for _ in pairs(self._items) do
        count = count + 1
    end
    return count
end

return ItemContainer
