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
    self._fontHint = love.graphics.newFont(15)
    self._fontHintKey = love.graphics.newFont(13)
end

-- в”Ђв”Ђв”Ђ Public draw entry point в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ

function HUD:draw(game, inventory, depot, player, ghost, context)
    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()
    local inCasino = context and context.inCasino

    self:_drawTopBar(game, sw)
    self:_drawInventory(inventory, sh)
    if not inCasino and depot and depot:isNearby(player.tx, player.ty) then
        self:_drawDepotStock(depot, sw)
    end
    if not inCasino and ghost and ghost:isActive() then
        self:_drawBuildMode(ghost, sw, sh)
    end
    self:_drawControls(game.input, sh, sw, ghost, context)

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

    local items = inventory.getSortedItems and inventory:getSortedItems() or {}
    local count = #items

    -- Background panel
    local panelH = ROW * (count + 2) + BAR_H + PAD * 2
    local panelY = sh - panelH - 30
    love.graphics.setColor(0, 0, 0, 0.55)
    love.graphics.rectangle("fill", PAD - 4, panelY - 4, BAR_W + 8, panelH, 4, 4)

    -- Weight bar
    local ratio = inventory:fillRatio()
    local fillRatio = math.min(1, ratio)
    local barColor = ratio > 0.85 and {0.95, 0.25, 0.25} or {0.25, 0.85, 0.35}
    love.graphics.setColor(0.3, 0.3, 0.3, 0.9)
    love.graphics.rectangle("fill", PAD, panelY, BAR_W, BAR_H)
    love.graphics.setColor(barColor[1], barColor[2], barColor[3], 1)
    love.graphics.rectangle("fill", PAD, panelY, BAR_W * fillRatio, BAR_H)
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
    for _, entry in ipairs(items) do
        local rtype = entry.resourceType
        local amt = entry.amount
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
    local stock = depot.getSortedItems and depot:getSortedItems() or {}
    local count = #stock
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
    if #stock == 0 then
        love.graphics.print("(empty)", px, y)
    else
        for _, entry in ipairs(stock) do
            local rtype = entry.resourceType
            local amt = entry.amount
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
    local resourceTypes = {}
    for rtype in pairs(def.cost) do
        resourceTypes[#resourceTypes + 1] = rtype
    end
    table.sort(resourceTypes)

    for _, rtype in ipairs(resourceTypes) do
        local amt = def.cost[rtype]
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

function HUD:_drawHintChip(x, y, keyText, descText)
    local keyPadX = 8
    local chipH = 28

    love.graphics.setFont(self._fontHintKey)
    local keyW = self._fontHintKey:getWidth(keyText) + keyPadX * 2
    love.graphics.setColor(0.94, 0.88, 0.62, 0.95)
    love.graphics.rectangle("fill", x, y, keyW, chipH, 8, 8)
    love.graphics.setColor(0.10, 0.11, 0.12, 1)
    love.graphics.printf(keyText, x, y + 6, keyW, "center")

    love.graphics.setFont(self._fontHint)
    love.graphics.setColor(0.94, 0.96, 0.98, 0.96)
    love.graphics.print(descText, x + keyW + 8, y + 5)

    return keyW + 8 + self._fontHint:getWidth(descText)
end

function HUD:_drawHintRow(x, y, items)
    local cursorX = x
    for i, item in ipairs(items) do
        cursorX = cursorX + self:_drawHintChip(cursorX, y, item.key, item.label)
        if i < #items then
            cursorX = cursorX + 18
        end
    end
end

function HUD:_drawControls(input, sh, sw, ghost, context)
    if ghost and ghost:isActive() and not (context and context.inCasino) then return end  -- banner replaces hints in build mode

    local rows
    local panelW = math.min(sw - 32, 880)
    local panelH = 88
    local panelX = (sw - panelW) * 0.5
    local panelY = sh - panelH - 14

    if context and context.inCasino and context.slotUIActive and input and input:isUsingGamepad() then
        rows = {
            {
                { key = "D-PAD L/R", label = "Stake " .. (context.slotStakeLabel or "100%") },
                { key = "A", label = context.slotSpinActive and "Spinning" or "Run Machine" },
                { key = "B", label = "Leave Machine" },
            },
            {
                { key = "GOLD", label = "Adjust exact wager" },
            }
        }
    elseif context and context.inCasino and context.slotUIActive then
        rows = {
            {
                { key = "LEFT / RIGHT", label = "Stake " .. (context.slotStakeLabel or "100%") },
                { key = "G", label = context.slotSpinActive and "Spinning" or "Run Machine" },
                { key = "ESC", label = "Leave Machine" },
            },
            {
                { key = "GOLD", label = "Adjust exact wager" },
            }
        }
    elseif context and context.inCasino and input and input:isUsingGamepad() then
        rows = {
            {
                { key = "L STICK", label = "Move" },
                { key = "A", label = "Use Slots" },
                { key = "B", label = "Leave" },
            },
            {
                { key = "SLOT", label = "Approach machine" },
            }
        }
    elseif context and context.inCasino then
        rows = {
            {
                { key = "WASD / ARROWS", label = "Move" },
                { key = "G", label = "Use Slots" },
                { key = "ESC", label = "Leave" },
            },
            {
                { key = "SLOT", label = "Approach machine" },
            }
        }
    elseif input and input:isUsingGamepad() then
        rows = {
            {
                { key = "L STICK", label = "Move" },
                { key = "A", label = "Attack" },
                { key = "Y", label = "Ability" },
                { key = "X", label = "Harvest" },
            },
            {
                { key = "RB", label = "Build" },
                { key = "LB", label = "Base Action" },
                { key = "B", label = "Menu" },
            }
        }
    else
        rows = {
            {
                { key = "WASD / ARROWS", label = "Move" },
                { key = "SPACE", label = "Attack" },
                { key = "Q", label = "Ability" },
                { key = "SHIFT", label = "Dash" },
            },
            {
                { key = "E", label = "Harvest" },
                { key = "B", label = "Build" },
                { key = "F", label = "Deposit" },
                { key = "H", label = "Sell" },
                { key = "G", label = "Enter Casino" },
                { key = "ESC", label = "Menu" },
            }
        }
    end

    love.graphics.setColor(0.03, 0.04, 0.05, 0.82)
    love.graphics.rectangle("fill", panelX, panelY, panelW, panelH, 14, 14)
    love.graphics.setColor(0.78, 0.72, 0.48, 0.92)
    love.graphics.rectangle("line", panelX, panelY, panelW, panelH, 14, 14)

    love.graphics.setFont(self._fontSm)
    love.graphics.setColor(0.92, 0.94, 0.95, 0.9)
    love.graphics.print("CONTROLS", panelX + 14, panelY + 8)

    self:_drawHintRow(panelX + 14, panelY + 28, rows[1])
    self:_drawHintRow(panelX + 14, panelY + 56, rows[2])
end

return HUD
