-- Day State
-- Daytime gameplay - explore, gather resources, build

local Class        = require("lib.class")
local Camera       = require("src.core.camera")
local Iso          = require("src.rendering.isometric")
local DrawOrder    = require("src.rendering.draworder")
local TileBatch    = require("src.rendering.spritebatch")
local Tile         = require("src.world.tile")
local WorldGen     = require("src.world.worldgen")
local ChunkManager = require("src.world.chunk")
local FogOfWar     = require("src.world.fogofwar")

local DayState = Class:extend()

function DayState:new(game)
    self.game          = game
    self.font          = love.graphics.newFont(24)
    self.smallFont     = love.graphics.newFont(14)
    self.timeRemaining = 600

    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()

    self.camera    = Camera(sw, sh)
    self.drawOrder = DrawOrder()
    self.tileBatch = TileBatch()

    WorldGen.init(os.time())
    self.chunks = ChunkManager()
    self.fog    = FogOfWar()

    self.player = { tx = 0.0, ty = 0.0, speed = 200 }  -- pixels/sec on screen
end

function DayState:enter()
    print("Entered Day State")
    self.game.dayCounter   = (self.game.dayCounter or 0) + 1
    self.timeRemaining     = self.game.config.dayLength

    local px, py = Iso.tileToScreen(self.player.tx, self.player.ty)
    self.camera:moveTo(px, py)

    self.game.eventBus:publish("day_start", self.game.dayCounter)
end

function DayState:exit()
    print("Exited Day State")
end

function DayState:update(dt)
    self.timeRemaining  = self.timeRemaining - dt
    self.game.timeOfDay = self.timeRemaining

    if self.timeRemaining <= 0 then
        self.game.stateMachine:setState("night")
        return
    end

    -- Movement via input manager (keyboard + gamepad).
    -- getMoveVector() returns normalised screen-space direction (right=+sdx, down=+sdy).
    -- Convert to tile-space using iso projection inverse so screen speed is constant
    -- regardless of direction (tiles are 64×32, so naive mapping would make
    -- horizontal movement look twice as fast as vertical).
    --   dtx = (sdx/HALF_W + sdy/HALF_H) / 2
    --   dty = (sdy/HALF_H - sdx/HALF_W) / 2
    local sdx, sdy = self.game.input:getMoveVector()
    if sdx ~= 0 or sdy ~= 0 then
        local spd  = self.player.speed * dt
        local hw, hh = 32, 16   -- TILE_W/2, TILE_H/2
        local dtx = (sdx * spd / hw + sdy * spd / hh) / 2
        local dty = (sdy * spd / hh - sdx * spd / hw) / 2
        self.player.tx = self.player.tx + dtx
        self.player.ty = self.player.ty + dty
    end

    -- Right stick pans camera; otherwise camera follows player
    local rx, ry = self.game.input:getRightStick()
    if math.abs(rx) > 0 or math.abs(ry) > 0 then
        local cameraSpeed = 300
        self.camera.x = self.camera.x + rx * cameraSpeed * dt
        self.camera.y = self.camera.y + ry * cameraSpeed * dt
    else
        local px, py = Iso.tileToScreen(self.player.tx, self.player.ty)
        self.camera:follow(px, py)
    end

    -- Update world systems
    self.chunks:update(self.player.tx, self.player.ty)
    self.fog:update(self.player.tx, self.player.ty)

    -- Cache tile types for all visible tiles while chunks are loaded
    local ptx = math.floor(self.player.tx + 0.5)
    local pty = math.floor(self.player.ty + 0.5)
    local r   = FogOfWar.VISION_RADIUS
    for ddx = -r, r do
        for ddy = -r, r do
            if ddx * ddx + ddy * ddy <= r * r then
                local tx, ty = ptx + ddx, pty + ddy
                local tileType = self.chunks:getTile(tx, ty)
                self.fog:cacheType(tx, ty, tileType)
            end
        end
    end

    self.camera:update(dt)

    if self.game.world then
        self.game.world:update(dt)
    end
end

-- Returns tile rect {x1,y1,x2,y2} covering the visible screen area.
function DayState:_visibleTileRect()
    local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
    local corners = {
        { self.camera:screenToWorld(0,  0)  },
        { self.camera:screenToWorld(sw, 0)  },
        { self.camera:screenToWorld(0,  sh) },
        { self.camera:screenToWorld(sw, sh) },
    }
    local txMin, tyMin =  math.huge,  math.huge
    local txMax, tyMax = -math.huge, -math.huge
    for _, c in ipairs(corners) do
        local tx, ty = Iso.screenToTile(c[1], c[2])
        if tx < txMin then txMin = tx end
        if ty < tyMin then tyMin = ty end
        if tx > txMax then txMax = tx end
        if ty > tyMax then tyMax = ty end
    end
    local m = 6
    return math.floor(txMin)-m, math.floor(tyMin)-m,
           math.ceil(txMax)+m,  math.ceil(tyMax)+m
end

-- Builds the sorted list of explored tiles to draw this frame.
function DayState:_buildDrawList(x1, y1, x2, y2)
    local list = {}
    for tx = x1, x2 do
        for ty = y1, y2 do
            local state = self.fog:getState(tx, ty)
            if state ~= "hidden" then
                local tileType = state == "visible"
                    and self.chunks:getTile(tx, ty)
                    or  self.fog:getCachedType(tx, ty)
                if tileType then
                    local _, sy = Iso.tileToScreen(tx, ty)
                    list[#list+1] = { sy=sy, tx=tx, ty=ty, t=tileType, visible=(state=="visible") }
                end
            end
        end
    end
    table.sort(list, function(a, b) return a.sy < b.sy end)
    return list
end

function DayState:draw()
    love.graphics.clear(0.50, 0.70, 0.90, 1)

    self.camera:apply()

    local x1, y1, x2, y2 = self:_visibleTileRect()
    local drawList = self:_buildDrawList(x1, y1, x2, y2)
    table.sort(drawList, function(a, b) return a.sy < b.sy end)

    -- Pass 1: tile fills
    for _, e in ipairs(drawList) do
        local c   = Tile.getColor(e.t)
        local dim = e.visible and 1 or 0.5
        self.tileBatch:addTile(e.tx, e.ty, c[1]*dim, c[2]*dim, c[3]*dim, 1)
    end
    self.tileBatch:flush()

    -- Pass 2: outlines on visible tiles only
    for _, e in ipairs(drawList) do
        if e.visible then
            self.tileBatch:addTile(e.tx, e.ty, 0, 0, 0, 1)
        end
    end
    self.tileBatch:flushOutlines(0, 0, 0, 0.20)
    self.tileBatch:clear()

    -- Placeholder player dot
    local psx, psy = Iso.tileToScreen(self.player.tx, self.player.ty)
    love.graphics.setColor(1, 0.9, 0.1, 1)
    love.graphics.circle("fill", psx, psy + 8, 10)
    love.graphics.setColor(0.6, 0.5, 0.0, 1)
    love.graphics.circle("line", psx, psy + 8, 10)

    self.camera:clear()

    -- HUD
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(self.font)
    love.graphics.print("Day " .. self.game.dayCounter, 20, 20)

    local minutes = math.floor(self.timeRemaining / 60)
    local seconds = math.floor(self.timeRemaining % 60)
    love.graphics.print(string.format("Time: %02d:%02d", minutes, seconds), 20, 50)

    love.graphics.setFont(self.smallFont)
    love.graphics.print(
        string.format("Tile: (%.0f, %.0f)", self.player.tx, self.player.ty), 20, 84)

    local input = self.game.input
    local controls
    if input:isUsingGamepad() then
        controls = "Left Stick: move  |  Right Stick: camera  |  " ..
                   input:getControlPrompt("space", "y", "skip to night") .. "  |  " ..
                   input:getControlPrompt("esc", "b", "menu")
    else
        controls = "WASD: move  |  Scroll: zoom  |  SPACE: skip to night  |  ESC: menu"
    end
    love.graphics.print(controls, 20, love.graphics.getHeight() - 22)

    love.graphics.setColor(1, 1, 1, 1)
end

function DayState:keypressed(key, scancode, isrepeat)
    if key == "escape" then
        self.game.stateMachine:setState("menu")
    elseif key == "space" then
        self.game.stateMachine:setState("night")
    end
end

function DayState:gamepadPressed(joystick, button)
    if button == "b" then
        self.game.stateMachine:setState("menu")
    elseif button == "y" then
        self.game.stateMachine:setState("night")
    end
end

function DayState:wheelmoved(x, y)
    self.camera:adjustZoom(y * 0.1)
end

return DayState
