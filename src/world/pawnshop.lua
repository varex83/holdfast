local Class = require("lib.class")
local AssetManager = require("src.core.assetmanager")
local Iso = require("src.rendering.isometric")
local Resources = require("data.resources")

local PawnShop = Class:extend()

local INTERACT_RADIUS = 3.0

local function getPawnShopImage()
    return AssetManager.getCurrent():getImage("props.supply_depot")
end

function PawnShop:new(tx, ty)
    self.tx = tx or 0
    self.ty = ty or 0
end

function PawnShop:isNearby(ptx, pty)
    local dx = ptx - self.tx
    local dy = pty - self.ty
    return math.sqrt(dx * dx + dy * dy) <= INTERACT_RADIUS
end

function PawnShop:sellInventory(inventory)
    if not inventory then
        return false, "Bring goods to the pawn shop."
    end

    local items = inventory:getItems()
    local goldEarned = 0
    local soldAnything = false

    for resourceType, amount in pairs(items) do
        if resourceType ~= "gold" and amount > 0 then
            local def = Resources[resourceType]
            local goldValue = def and def.goldValue or 0
            if goldValue > 0 then
                inventory:remove(resourceType, amount)
                goldEarned = goldEarned + amount * goldValue
                soldAnything = true
            end
        end
    end

    if not soldAnything then
        return false, "Bring resources to sell for gold."
    end

    inventory:forceAdd("gold", goldEarned)
    return true, string.format("Pawn shop deal: +%d gold.", goldEarned)
end

function PawnShop:draw()
    local sx, sy = Iso.tileToScreen(self.tx, self.ty)
    local image = getPawnShopImage()

    love.graphics.setColor(0.28, 0.22, 0.08, 0.22)
    love.graphics.polygon("fill", sx, sy, sx + 32, sy + 16, sx, sy + 32, sx - 32, sy + 16)
    Iso.drawProp(image, self.tx, self.ty, {
        scale = 1.0,
        anchorY = 22,
        oy = 4,
        r = 1.0,
        g = 0.88,
        b = 0.54,
        a = 1.0,
    })
    love.graphics.setColor(0.56, 0.40, 0.10, 0.95)
    love.graphics.polygon("line", sx, sy, sx + 32, sy + 16, sx, sy + 32, sx - 32, sy + 16)
end

function PawnShop:drawNearbyHint()
    local sx, sy = Iso.tileToScreen(self.tx, self.ty)
    local alpha = 0.5 + 0.5 * math.sin(love.timer.getTime() * 3)

    love.graphics.setColor(0.98, 0.84, 0.22, alpha)
    love.graphics.circle("line", sx, sy + 16, 36)
    love.graphics.setFont(love.graphics.newFont(11))
    love.graphics.setColor(1, 0.98, 0.90, alpha)
    love.graphics.print("H: Sell for Gold", sx - 38, sy + 36)
end

PawnShop.INTERACT_RADIUS = INTERACT_RADIUS

return PawnShop
