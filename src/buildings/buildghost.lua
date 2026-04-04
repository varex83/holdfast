-- Build Ghost
-- Shows a placement preview. Cursor can be moved via mouse, arrow keys,
-- or gamepad right stick (handled externally via moveCursor / updateFromMouse).

local Class     = require("lib.class")
local AssetManager = require("src.core.assetmanager")
local Iso       = require("src.rendering.isometric")
local Buildings = require("data.buildings")

local BuildGhost = Class:extend()

local function getImage(spriteDef)
    if not spriteDef then
        return nil
    end

    local assets = AssetManager.getCurrent()
    if spriteDef.asset then
        return assets:getImage(spriteDef.asset)
    end

    if spriteDef.path then
        return assets:getImageFromRef(spriteDef.path, spriteDef)
    end

    return nil
end

local BUILD_ORDER = { "wall", "gate", "campfire" }

function BuildGhost:new()
    self._active     = false
    self._typeIndex  = 1
    self._tx         = 0
    self._ty         = 0
    self._labelFont  = love.graphics.newFont(11)
end

function BuildGhost:isActive()    return self._active end
function BuildGhost:currentType() return BUILD_ORDER[self._typeIndex] end
function BuildGhost:cursorTile()  return self._tx, self._ty end

function BuildGhost:activate(ptx, pty)
    self._active = true
    self._tx     = math.floor((ptx or 0) + 0.5)
    self._ty     = math.floor((pty or 0) + 0.5)
end

function BuildGhost:deactivate()
    self._active = false
end

function BuildGhost:cycleType()
    self._typeIndex = (self._typeIndex % #BUILD_ORDER) + 1
end

-- Move cursor by (dx, dy) tiles.
function BuildGhost:moveCursor(dx, dy)
    self._tx = self._tx + dx
    self._ty = self._ty + dy
end

-- Snap cursor to the tile currently under the mouse.
-- `camera` is the Camera instance (provides screenToWorld).
function BuildGhost:updateFromMouse(camera)
    local mx, my      = love.mouse.getPosition()
    local wx, wy      = camera:screenToWorld(mx, my)
    local tx, ty      = Iso.screenToTile(wx, wy)
    self._tx          = math.floor(tx + 0.5)
    self._ty          = math.floor(ty + 0.5)
end

function BuildGhost:_drawSprite(def, valid, pulse)
    local spriteDef = def.sprite
    local image = getImage(spriteDef)
    if not image then return end
    local tint = valid and {0.7, 1.0, 0.7, pulse} or {1.0, 0.5, 0.5, pulse}
    Iso.drawProp(image, self._tx, self._ty, {
        scale   = spriteDef.scale or 1,
        ox      = spriteDef.ox or 0,
        oy      = spriteDef.oy or 0,
        anchorX = spriteDef.anchorX,
        anchorY = spriteDef.anchorY,
        r = tint[1], g = tint[2], b = tint[3], a = tint[4],
    })
end

function BuildGhost:_drawLabels(def, sx, sy, occupied, affordable)
    local reason = occupied and " [occupied]" or (not affordable and " [need resources]" or "")
    love.graphics.setFont(self._labelFont)
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print(def.name .. reason, sx - 36, sy - 22)

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
    love.graphics.setColor(0.8, 0.8, 0.3, 0.85)
    love.graphics.print(#costParts > 0 and table.concat(costParts, ", ") or "free", sx - 36, sy - 10)
end

-- Draw the ghost at the cursor tile.
function BuildGhost:draw(buildManager, depot, inventory)
    if not self._active then return end

    local btype = self:currentType()
    local def   = Buildings[btype]
    local sx, sy = Iso.tileToScreen(self._tx, self._ty)

    local occupied   = buildManager:isOccupied(self._tx, self._ty)
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

    self:_drawSprite(def, valid, pulse)
    self:_drawLabels(def, sx, sy, occupied, affordable)
end

return BuildGhost
