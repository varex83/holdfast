-- Build Ghost
-- Preview tile drawn one tile ahead of the player in their facing direction.
-- Pulses green (valid) or red (invalid).

local Class     = require("lib.class")
local Iso       = require("src.rendering.isometric")
local Buildings = require("data.buildings")

local BuildGhost = Class:extend()

local BUILD_ORDER = { "wall", "gate", "campfire" }

function BuildGhost:new()
    self._active     = false
    self._typeIndex  = 1
    self._labelFont  = love.graphics.newFont(11)
end

function BuildGhost:isActive()    return self._active end
function BuildGhost:currentType() return BUILD_ORDER[self._typeIndex] end

function BuildGhost:activate()   self._active = true end
function BuildGhost:deactivate() self._active = false end

function BuildGhost:cycleType()
    self._typeIndex = (self._typeIndex % #BUILD_ORDER) + 1
end

-- Draw the ghost at tile (tx, ty).
function BuildGhost:draw(tx, ty, buildManager, depot, inventory)
    if not self._active then return end

    local btype = self:currentType()
    local def   = Buildings[btype]
    local sx, sy = Iso.tileToScreen(tx, ty)

    local occupied   = buildManager:isOccupied(tx, ty)
    local affordable = buildManager:canAfford(btype, depot, inventory)
    local valid      = not occupied and affordable

    local pulse = 0.50 + 0.25 * math.sin(love.timer.getTime() * 5)

    if valid then
        love.graphics.setColor(0.2, 1.0, 0.2, pulse)
    else
        love.graphics.setColor(1.0, 0.2, 0.2, pulse)
    end

    love.graphics.polygon("fill",
        sx,       sy,
        sx + 32,  sy + 16,
        sx,       sy + 32,
        sx - 32,  sy + 16)

    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.polygon("line",
        sx,       sy,
        sx + 32,  sy + 16,
        sx,       sy + 32,
        sx - 32,  sy + 16)

    love.graphics.setFont(self._labelFont)
    local reason = occupied and " [occupied]" or (not affordable and " [need resources]" or "")
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print(def.name .. reason, sx - 36, sy - 22)

    local costParts = {}
    for rtype, amt in pairs(def.cost) do
        costParts[#costParts + 1] = amt .. " " .. rtype
    end
    love.graphics.setColor(0.8, 0.8, 0.3, 0.85)
    love.graphics.print(#costParts > 0 and table.concat(costParts, ", ") or "free", sx - 36, sy - 10)
end

return BuildGhost
