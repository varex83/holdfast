-- Building
-- A single placed structure in the world.

local Class     = require("lib.class")
local Iso       = require("src.rendering.isometric")
local Buildings = require("data.buildings")

local Building = Class:extend()

function Building:new(btype, tx, ty)
    local def    = Buildings[btype]
    self.btype   = btype
    self.tx      = tx
    self.ty      = ty
    self.def     = def
    self.hp      = def.hp
    self.maxHp   = def.hp
end

function Building:isAlive()
    return self.hp > 0
end

function Building:takeDamage(amount)
    self.hp = math.max(0, self.hp - amount)
end

function Building:screenY()
    local _, sy = Iso.tileToScreen(self.tx, self.ty)
    return sy
end

-- Draw the building as an isometric diamond with a label.
-- Camera transform must already be applied.
function Building:draw()
    local sx, sy = Iso.tileToScreen(self.tx, self.ty)
    local c      = self.def.color

    -- Fill
    love.graphics.setColor(c[1], c[2], c[3], 1)
    love.graphics.polygon("fill",
        sx,       sy,
        sx + 32,  sy + 16,
        sx,       sy + 32,
        sx - 32,  sy + 16)

    -- Campfire flame
    if self.btype == "campfire" then
        love.graphics.setColor(1, 0.3, 0.1, 0.9)
        love.graphics.circle("fill", sx, sy + 10, 7)
        love.graphics.setColor(1, 0.8, 0.1, 0.8)
        love.graphics.circle("fill", sx, sy + 10, 4)
    end

    -- Outline
    love.graphics.setColor(0, 0, 0, 0.45)
    love.graphics.polygon("line",
        sx,       sy,
        sx + 32,  sy + 16,
        sx,       sy + 32,
        sx - 32,  sy + 16)

    -- HP bar when damaged
    if self.hp < self.maxHp then
        local ratio = self.hp / self.maxHp
        local bw    = 32
        love.graphics.setColor(0.7, 0.1, 0.1, 0.85)
        love.graphics.rectangle("fill", sx - bw / 2, sy - 6, bw, 4)
        love.graphics.setColor(0.1, 0.8, 0.1, 0.85)
        love.graphics.rectangle("fill", sx - bw / 2, sy - 6, bw * ratio, 4)
    end
end

return Building
