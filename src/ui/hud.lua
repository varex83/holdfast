-- HUD
-- Draws the in-game heads-up display:
--   вЂў Day counter + countdown timer
--   вЂў Player inventory (items + weight bar)
--   вЂў Supply depot indicator when nearby
--   вЂў Control hints

local Class     = require("lib.class")
local Resources = require("data.resources")

local HUD = Class:extend()

-- Layout constants
local PAD       = 12
local BAR_W     = 120
local BAR_H     = 10
local ROW       = 18

function HUD:new()
    self._fontLg = love.graphics.newFont(22)
    self._fontMd = love.graphics.newFont(14)
    self._fontSm = love.graphics.newFont(11)
end

-- в”Ђв”Ђв”Ђ Public draw entry point в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ

function HUD:draw(game, inventory, depot, player, ghost)
    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()

    self:_drawTopBar(game, sw)
    self:_drawInventory(inventory, sh)
    if depot and depot:isNearby(player.tx, player.ty) then
        self:_drawDepotStock(depot, sw)
    end
    if ghost and ghost:isActive() then
        self:_drawBuildMode(ghost, sw, sh)
    end
    self:_drawControls(game.input, sh, sw, ghost)

    love.graphics.setColor(1, 1, 1, 1)
end

-- в”Ђв”Ђв”Ђ Top bar: day + timer в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ

function HUD:_drawTopBar(game, sw)
    love.graphics.setFont(self._fontLg)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Day " .. (game.dayCounter or 1), PAD, PAD)

    local t = game.timeOfDay or 0
    local m = math.floor(t / 60)
    local s = math.floor(t % 60)
    local timeStr = string.format("%02d:%02d", m, s)

    love.graphics.setFont(self._fontMd)
    local tw = self._fontMd:getWidth(timeStr)
    love.graphics.print(timeStr, sw - tw - PAD, PAD + 4)
end

-- в”Ђв”Ђв”Ђ Inventory panel (bottom-left) в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ

function HUD:_drawInventory(inventory, sh)
    if not inventory then return end

    local items = inventory:getItems()
    local count = 0
    for _ in pairs(items) do count = count + 1 end

    -- Background panel
    local panelH = ROW * (count + 2) + BAR_H + PAD * 2
    local panelY = sh - panelH - 30
    love.graphics.setColor(0, 0, 0, 0.55)
    love.graphics.rectangle("fill", PAD - 4, panelY - 4, BAR_W + 8, panelH, 4, 4)

    -- Weight bar
    local ratio = inventory:fillRatio()
    local barColor = ratio > 0.85 and {0.95, 0.25, 0.25} or {0.25, 0.85, 0.35}
    love.graphics.setColor(0.3, 0.3, 0.3, 0.9)
    love.graphics.rectangle("fill", PAD, panelY, BAR_W, BAR_H)
    love.graphics.setColor(barColor[1], barColor[2], barColor[3], 1)
    love.graphics.rectangle("fill", PAD, panelY, BAR_W * ratio, BAR_H)
    love.graphics.setColor(0.7, 0.7, 0.7, 0.8)
    love.graphics.rectangle("line", PAD, panelY, BAR_W, BAR_H)

    love.graphics.setFont(self._fontSm)
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print(
        string.format("%.0f / %.0f kg", inventory:totalWeight(), inventory:capacity()),
        PAD, panelY + BAR_H + 2)

    -- Item rows
    local y = panelY + BAR_H + ROW + 2
    love.graphics.setFont(self._fontMd)
    for rtype, amt in pairs(items) do
        local def = Resources[rtype]
        local c   = def and def.color or {1, 1, 1}
        -- Colour dot
        love.graphics.setColor(c[1], c[2], c[3], 1)
        love.graphics.circle("fill", PAD + 5, y + 7, 5)
        -- Name + amount
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(string.format("%-6s %d", rtype, amt), PAD + 14, y)
        y = y + ROW
    end
end

-- в”Ђв”Ђв”Ђ Depot stock panel (right side, shown when nearby) в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ

function HUD:_drawDepotStock(depot, sw)
    local stock = depot:getStock()
    local count = 0
    for _ in pairs(stock) do count = count + 1 end
    if count == 0 then count = 1 end  -- show "empty" row

    local panelW = 160
    local panelH = ROW * (count + 1) + PAD * 2
    local px = sw - panelW - PAD
    local py = PAD + 40

    love.graphics.setColor(0, 0, 0, 0.55)
    love.graphics.rectangle("fill", px - 4, py - 4, panelW + 8, panelH, 4, 4)

    love.graphics.setFont(self._fontMd)
    love.graphics.setColor(0.9, 0.8, 0.2, 1)
    love.graphics.print("Supply Depot", px, py)

    local y = py + ROW + 4
    love.graphics.setColor(1, 1, 1, 0.9)
    if count == 1 and next(stock) == nil then
        love.graphics.print("(empty)", px, y)
    else
        for rtype, amt in pairs(stock) do
            local def = Resources[rtype]
            local c   = def and def.color or {1, 1, 1}
            love.graphics.setColor(c[1], c[2], c[3], 1)
            love.graphics.circle("fill", px + 5, y + 7, 5)
            love.graphics.setColor(1, 1, 1, 0.9)
            love.graphics.print(string.format("%-6s %d", rtype, amt), px + 14, y)
            y = y + ROW
        end
    end
end

-- в”Ђв”Ђв”Ђ Build mode banner в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ

function HUD:_drawBuildMode(ghost, sw, sh)
    local Buildings = require("data.buildings")
    local btype = ghost:currentType()
    local def   = Buildings[btype]

    local costParts = {}
    for rtype, amt in pairs(def.cost) do
        costParts[#costParts + 1] = amt .. " " .. rtype
    end
    local costStr = #costParts > 0 and table.concat(costParts, ", ") or "free"

    love.graphics.setFont(self._fontMd)
    local text = "BUILD: " .. def.name .. "  (" .. costStr .. ")  |  Move: aim  |  B: cycle type  |  R: place  |  ESC: cancel"
    local tw   = self._fontMd:getWidth(text)

    love.graphics.setColor(0, 0, 0, 0.60)
    love.graphics.rectangle("fill", (sw - tw) * 0.5 - 8, sh - 52, tw + 16, 22, 4, 4)
    love.graphics.setColor(0.3, 1.0, 0.4, 1)
    love.graphics.print(text, (sw - tw) * 0.5, sh - 50)
end

-- в”Ђв”Ђв”Ђ Control hints (bottom) в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ

function HUD:_drawControls(input, sh, sw, ghost)
    if ghost and ghost:isActive() then return end  -- banner replaces hints in build mode

    love.graphics.setFont(self._fontSm)
    love.graphics.setColor(1, 1, 1, 0.75)

    local hints
    if input and input:isUsingGamepad() then
        hints = "Left Stick: move  |  X: harvest  |  RB: build  |  в–і: skip night  |  в—‹: menu  |  в–Ў: deposit"
    else
        hints = "WASD: move  |  E: harvest  |  B: build  |  F: deposit  |  Scroll: zoom  |  ESC: menu"
    end

    local tw = self._fontSm:getWidth(hints)
    love.graphics.print(hints, (sw - tw) * 0.5, sh - 20)
end

return HUD
