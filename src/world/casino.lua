local Class = require("lib.class")
local AssetManager = require("src.core.assetmanager")
local Iso = require("src.rendering.isometric")

local Casino = Class:extend()

local INTERACT_RADIUS = 3.0
local SLOT_SYMBOLS = { "CHERRY", "BELL", "STAR", "7" }
local SLOT_PAYTABLE = {
    { symbols = { "7", "7", "7" }, multiplier = 25, label = "777 jackpot" },
    { symbols = { "STAR", "STAR", "STAR" }, multiplier = 12, label = "Triple star" },
    { symbols = { "BELL", "BELL", "BELL" }, multiplier = 6, label = "Triple bell" },
    { symbols = { "CHERRY", "CHERRY", "CHERRY" }, multiplier = 4, label = "Triple cherry" },
    { symbols = { "CHERRY", "CHERRY", "*" }, multiplier = 2, label = "Two cherries" },
    { symbols = { "CHERRY", "*", "*" }, multiplier = 1, label = "Single cherry" },
}

local function matchesPattern(reels, pattern)
    for i = 1, #pattern do
        if pattern[i] ~= "*" and reels[i] ~= pattern[i] then
            return false
        end
    end

    return true
end

local function evaluateSpin(reels)
    for _, entry in ipairs(SLOT_PAYTABLE) do
        if matchesPattern(reels, entry.symbols) then
            return entry
        end
    end

    return nil
end

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

function Casino:rollSlotReels()
    return {
        SLOT_SYMBOLS[love.math.random(#SLOT_SYMBOLS)],
        SLOT_SYMBOLS[love.math.random(#SLOT_SYMBOLS)],
        SLOT_SYMBOLS[love.math.random(#SLOT_SYMBOLS)],
    }
end

function Casino:beginSlotSpin(stakeItems)
    if not stakeItems then
        return false, "Bring gold to the slot machine."
    end

    local totalIn = 0
    for _, amount in pairs(stakeItems) do
        totalIn = totalIn + amount
    end
    if totalIn <= 0 then
        return false, "Choose a gold stake before spinning."
    end

    return true, {
        items = stakeItems,
        totalIn = totalIn,
        reels = self:rollSlotReels(),
    }
end

function Casino:resolveSlotSpin(spin, inventory)
    local left, middle, right = spin.reels[1], spin.reels[2], spin.reels[3]
    local payoutEntry = evaluateSpin(spin.reels)
    local multiplier = payoutEntry and payoutEntry.multiplier or 0

    local totalOut = 0
    if multiplier > 0 then
        for resourceType, amount in pairs(spin.items) do
            local payout = amount * multiplier
            inventory:forceAdd(resourceType, payout)
            totalOut = totalOut + payout
        end
    end

    local reels = string.format("[%s | %s | %s]", left, middle, right)
    if multiplier >= 12 then
        return true, string.format("Slots jackpot %s  %s pays %dx: %d gold -> %d gold.", reels, payoutEntry.label, multiplier, spin.totalIn, totalOut)
    elseif multiplier > 0 then
        return true, string.format("Slots win %s  %s pays %dx: %d gold -> %d gold.", reels, payoutEntry.label, multiplier, spin.totalIn, totalOut)
    end

    return true, string.format("Slots lost %s  %d gold gone.", reels, spin.totalIn)
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
    love.graphics.print("G: Slots (777 pays 25x)", sx - 52, sy + 36)
end

Casino.INTERACT_RADIUS = INTERACT_RADIUS
Casino.SLOT_SYMBOLS = SLOT_SYMBOLS
Casino.SLOT_PAYTABLE = SLOT_PAYTABLE

return Casino
