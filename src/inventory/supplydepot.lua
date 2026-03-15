-- Supply Depot
-- Shared base storage accessible by all players.
-- Players deposit by pressing F near the depot tile.

local Class     = require("lib.class")
local Iso       = require("src.rendering.isometric")

local SupplyDepot = Class:extend()

-- Tile distance within which a player can deposit/withdraw.
local INTERACT_RADIUS = 3.0

function SupplyDepot:new(tx, ty, eventBus)
    self.tx       = tx or 0
    self.ty       = ty or 0
    self.eventBus = eventBus
    self._stock   = {}   -- resourceType → amount
end

-- ─── Stock management ────────────────────────────────────────────────────────

function SupplyDepot:add(resourceType, amount)
    self._stock[resourceType] = (self._stock[resourceType] or 0) + amount
end

function SupplyDepot:remove(resourceType, amount)
    local have   = self._stock[resourceType] or 0
    local actual = math.min(amount, have)
    self._stock[resourceType] = have - actual
    if self._stock[resourceType] == 0 then
        self._stock[resourceType] = nil
    end
    return actual
end

function SupplyDepot:count(resourceType)
    return self._stock[resourceType] or 0
end

function SupplyDepot:has(resourceType, amount)
    return (self._stock[resourceType] or 0) >= amount
end

-- Returns a copy of the full stock table.
function SupplyDepot:getStock()
    local copy = {}
    for k, v in pairs(self._stock) do copy[k] = v end
    return copy
end

-- ─── Interaction ─────────────────────────────────────────────────────────────

function SupplyDepot:isNearby(ptx, pty)
    local dx = ptx - self.tx
    local dy = pty - self.ty
    return math.sqrt(dx*dx + dy*dy) <= INTERACT_RADIUS
end

-- Deposit all items from `inventory` into the depot.
function SupplyDepot:depositAll(inventory)
    local items = inventory:clear()
    for rtype, amt in pairs(items) do
        self:add(rtype, amt)
        if self.eventBus then
            self.eventBus:publish("resource_deposited", rtype, amt)
        end
    end
    return items
end

-- Withdraw `amount` of `resourceType` into `inventory`. Returns actual withdrawn.
function SupplyDepot:withdraw(resourceType, amount, inventory)
    local actual = self:remove(resourceType, amount)
    if actual > 0 then
        inventory:add(resourceType, actual)
    end
    return actual
end

-- ─── Rendering ───────────────────────────────────────────────────────────────

-- Draw a placeholder depot marker. Camera transform must be applied.
function SupplyDepot:draw()
    local sx, sy = Iso.tileToScreen(self.tx, self.ty)

    -- Base diamond (dark wood colour)
    love.graphics.setColor(0.45, 0.28, 0.10, 1)
    love.graphics.polygon("fill",
        sx,       sy,
        sx + 32,  sy + 16,
        sx,       sy + 32,
        sx - 32,  sy + 16)

    -- Chest icon (simple rectangle)
    love.graphics.setColor(0.65, 0.42, 0.18, 1)
    love.graphics.rectangle("fill", sx - 10, sy + 4, 20, 14)
    love.graphics.setColor(0.85, 0.70, 0.30, 1)
    love.graphics.rectangle("fill", sx - 10, sy + 4, 20, 6)

    -- Outline
    love.graphics.setColor(0.2, 0.1, 0.0, 1)
    love.graphics.polygon("line",
        sx,       sy,
        sx + 32,  sy + 16,
        sx,       sy + 32,
        sx - 32,  sy + 16)
end

-- Draw a "nearby" indicator (pulsing ring) when player is in range.
function SupplyDepot:drawNearbyHint()
    local sx, sy = Iso.tileToScreen(self.tx, self.ty)
    local alpha  = 0.5 + 0.5 * math.sin(love.timer.getTime() * 3)
    love.graphics.setColor(0.9, 0.8, 0.2, alpha)
    love.graphics.circle("line", sx, sy + 16, 36)
    love.graphics.setFont(love.graphics.newFont(11))
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.print("F: Deposit", sx - 24, sy + 36)
end

SupplyDepot.INTERACT_RADIUS = INTERACT_RADIUS

return SupplyDepot
