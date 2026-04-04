local Class = require("lib.class")
local AssetManager = require("src.core.assetmanager")
local Iso = require("src.rendering.isometric")

local Casino = Class:extend()

local INTERACT_RADIUS = 3.0
local WIN_CHANCE = 0.30

local function getCasinoImage()
    return AssetManager.getCurrent():getImage("buildings.basecore.house_hay_1")
end

function Casino:new(tx, ty)
    self.tx = tx or 0
    self.ty = ty or 0
end

function Casino:isNearby(ptx, pty)
    local dx = ptx - self.tx
    local dy = pty - self.ty
    return math.sqrt(dx * dx + dy * dy) <= INTERACT_RADIUS
end

function Casino:gambleInventory(inventory, depot)
    if not inventory or inventory:isEmpty() then
        return false, "Bring resources to gamble."
    end

    local items = inventory:clear()
    local won = love.math.random() < WIN_CHANCE
    local totalIn = 0
    for _, amount in pairs(items) do
        totalIn = totalIn + amount
    end

    if won then
        local totalOut = 0
        for resourceType, amount in pairs(items) do
            local doubledAmount = amount * 2
            depot:add(resourceType, doubledAmount)
            totalOut = totalOut + doubledAmount
        end
        return true, string.format("Casino win! %d -> %d resources sent to depot.", totalIn, totalOut)
    end

    return true, string.format("Casino lost. %d resources vanished.", totalIn)
end

function Casino:draw()
    local sx, sy = Iso.tileToScreen(self.tx, self.ty)
    local image = getCasinoImage()

    love.graphics.setColor(0.95, 0.78, 0.18, 0.20)
    love.graphics.polygon("fill", sx, sy, sx + 32, sy + 16, sx, sy + 32, sx - 32, sy + 16)
    Iso.drawProp(image, self.tx, self.ty, {
        scale = 0.55,
        anchorY = 91,
        oy = 4,
        r = 1.0,
        g = 0.96,
        b = 0.82,
        a = 1.0,
    })
    love.graphics.setColor(0.85, 0.68, 0.12, 0.95)
    love.graphics.polygon("line", sx, sy, sx + 32, sy + 16, sx, sy + 32, sx - 32, sy + 16)
end

function Casino:drawNearbyHint()
    local sx, sy = Iso.tileToScreen(self.tx, self.ty)
    local alpha = 0.5 + 0.5 * math.sin(love.timer.getTime() * 3)
    local font = love.graphics.newFont(11)

    love.graphics.setColor(0.96, 0.80, 0.22, alpha)
    love.graphics.circle("line", sx, sy + 16, 36)
    love.graphics.setFont(font)
    love.graphics.setColor(1, 0.98, 0.90, alpha)
    love.graphics.print("G: Gamble (30% double)", sx - 54, sy + 36)
end

Casino.INTERACT_RADIUS = INTERACT_RADIUS
Casino.WIN_CHANCE = WIN_CHANCE

return Casino
