-- Supply Depot
-- Shared base storage accessible by all players.
-- Players deposit by pressing F near the depot tile.

local ItemContainer = require("src.inventory.itemcontainer")
local AssetManager = require("src.core.assetmanager")
local Iso       = require("src.rendering.isometric")

local SupplyDepot = ItemContainer:extend()

local function getDepotImage()
    return AssetManager.getCurrent():getImage("props.supply_depot")
end

-- Tile distance within which a player can deposit/withdraw.
local INTERACT_RADIUS = 3.0

function SupplyDepot:new(tx, ty, eventBus)
    SupplyDepot.super.new(self)
    self.tx       = tx or 0
    self.ty       = ty or 0
    self.eventBus = eventBus
    self._hintFont = nil
end

-- ─── Stock management ────────────────────────────────────────────────────────

-- Returns a copy of the full stock table.
function SupplyDepot:getStock()
    return self:getItems()
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
    if not inventory then
        return 0
    end

    resourceType = self:_normalizeResourceType(resourceType)
    amount = math.min(self:_normalizeAmount(amount), self:count(resourceType))
    if amount == 0 then
        return 0
    end

    local actual = inventory:add(resourceType, amount)
    if actual <= 0 then
        return 0
    end

    SupplyDepot.super.remove(self, resourceType, actual)
    return actual
end

function SupplyDepot:_getHintFont()
    if not self._hintFont then
        self._hintFont = love.graphics.newFont(11)
    end

    return self._hintFont
end

-- ─── Rendering ───────────────────────────────────────────────────────────────

function SupplyDepot:draw()
    local sx, sy = Iso.tileToScreen(self.tx, self.ty)
    local image = getDepotImage()

    love.graphics.setColor(0.45, 0.28, 0.10, 0.22)
    love.graphics.polygon("fill", sx, sy, sx + 32, sy + 16, sx, sy + 32, sx - 32, sy + 16)
    Iso.drawProp(image, self.tx, self.ty, {
        scale = 1.0,
        anchorY = 22,
        oy = 4,
    })
    love.graphics.setColor(0.2, 0.1, 0.0, 0.9)
    love.graphics.polygon("line", sx, sy, sx + 32, sy + 16, sx, sy + 32, sx - 32, sy + 16)
end

-- Draw a "nearby" indicator (pulsing ring) when player is in range.
function SupplyDepot:drawNearbyHint()
    local sx, sy = Iso.tileToScreen(self.tx, self.ty)
    local alpha  = 0.5 + 0.5 * math.sin(love.timer.getTime() * 3)
    love.graphics.setColor(0.9, 0.8, 0.2, alpha)
    love.graphics.circle("line", sx, sy + 16, 36)
    love.graphics.setFont(self:_getHintFont())
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.print("F: Deposit", sx - 24, sy + 36)
end

SupplyDepot.INTERACT_RADIUS = INTERACT_RADIUS

return SupplyDepot
