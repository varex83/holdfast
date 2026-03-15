-- Day State
-- Daytime gameplay - explore, gather resources, build

local Class          = require("lib.class")
local Camera         = require("src.core.camera")
local Iso            = require("src.rendering.isometric")
local DrawOrder      = require("src.rendering.draworder")
local TileBatch      = require("src.rendering.spritebatch")
local Tile           = require("src.world.tile")
local WorldGen       = require("src.world.worldgen")
local ChunkManager   = require("src.world.chunk")
local FogOfWar       = require("src.world.fogofwar")
local NodeManager    = require("src.resources.nodemanager")
local HarvestManager = require("src.resources.harvesting")
local RespawnManager = require("src.resources.respawn")
local Inventory      = require("src.inventory.inventory")
local SupplyDepot    = require("src.inventory.supplydepot")
local HUD            = require("src.ui.hud")

local DayState = Class:extend()

function DayState:new(game)
    self.game          = game
    self.font          = love.graphics.newFont(24)
    self.smallFont     = love.graphics.newFont(14)
    self.timeRemaining = 270

    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()

    self.camera    = Camera(sw, sh)
    self.drawOrder = DrawOrder()
    self.tileBatch = TileBatch()

    WorldGen.init(os.time())
    self.chunks  = ChunkManager()
    self.fog     = FogOfWar()

    local respawn = RespawnManager(game.config)
    self.nodes    = NodeManager(respawn)
    self.respawn  = respawn
    self.harvest  = HarvestManager(game.eventBus)

    self.inventory = Inventory("scout")   -- placeholder class; set by class select later
    self.depot     = SupplyDepot(2, 2, game.eventBus)  -- base depot at tile (2,2)
    self.hud       = HUD()

    self.player = { tx = 0.0, ty = 0.0, speed = 200 }
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

    -- Movement
    local sdx, sdy = self.game.input:getMoveVector()
    if sdx ~= 0 or sdy ~= 0 then
        local spd    = self.player.speed * dt
        local hw, hh = 32, 16
        local dtx = (sdx * spd / hw + sdy * spd / hh) / 2
        local dty = (sdy * spd / hh - sdx * spd / hw) / 2
        self.player.tx = self.player.tx + dtx
        self.player.ty = self.player.ty + dty
    end

    -- Camera
    local rx, ry = self.game.input:getRightStick()
    if math.abs(rx) > 0 or math.abs(ry) > 0 then
        self.camera.x = self.camera.x + rx * 300 * dt
        self.camera.y = self.camera.y + ry * 300 * dt
    else
        local px, py = Iso.tileToScreen(self.player.tx, self.player.ty)
        self.camera:follow(px, py)
    end

    -- World systems
    self.chunks:update(self.player.tx, self.player.ty)
    self.fog:update(self.player.tx, self.player.ty)

    -- Sync resource nodes from loaded chunks and cache tile types
    local ptx = math.floor(self.player.tx + 0.5)
    local pty = math.floor(self.player.ty + 0.5)
    local r   = FogOfWar.VISION_RADIUS
    for ddx = -r, r do
        for ddy = -r, r do
            if ddx * ddx + ddy * ddy <= r * r then
                local tx, ty = ptx + ddx, pty + ddy
                self.fog:cacheType(tx, ty, self.chunks:getTile(tx, ty))
            end
        end
    end

    -- Sync nodes from all loaded chunks
    for _, chunk in pairs(self.chunks._chunks) do
        self.nodes:syncChunk(chunk)
    end

    -- Resource systems
    self.harvest:update(dt, self.player.tx, self.player.ty, self.nodes, self.inventory)
    self.respawn:update(dt)

    self.camera:update(dt)

    if self.game.world then self.game.world:update(dt) end
end

-- Returns tile bounds covering the visible screen.
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

-- Sorted draw list of explored tiles.
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

    -- Pass 1: tile fills
    for _, e in ipairs(drawList) do
        local c   = Tile.getColor(e.t)
        local dim = e.visible and 1 or 0.5
        self.tileBatch:addTile(e.tx, e.ty, c[1]*dim, c[2]*dim, c[3]*dim, 1)
    end
    self.tileBatch:flush()

    -- Pass 2: outlines
    for _, e in ipairs(drawList) do
        if e.visible then
            self.tileBatch:addTile(e.tx, e.ty, 0, 0, 0, 1)
        end
    end
    self.tileBatch:flushOutlines(0, 0, 0, 0.20)
    self.tileBatch:clear()

    -- Resource nodes
    self.nodes:draw({ x1=x1, y1=y1, x2=x2, y2=y2 }, self.fog)
    self.harvest:drawHint(self.player.tx, self.player.ty, self.nodes, self.fog)
    self.harvest:draw()

    -- Player and depot depth-sorted (painter's algorithm by screen Y)
    local psx, psy   = Iso.tileToScreen(self.player.tx, self.player.ty)
    local _, dsy     = Iso.tileToScreen(self.depot.tx,  self.depot.ty)
    local depotVis   = self.fog:isVisible(self.depot.tx, self.depot.ty)

    local function drawPlayer()
        love.graphics.setColor(1, 0.9, 0.1, 1)
        love.graphics.circle("fill", psx, psy + 8, 10)
        love.graphics.setColor(0.6, 0.5, 0.0, 1)
        love.graphics.circle("line", psx, psy + 8, 10)
    end

    local function drawDepot()
        if depotVis then
            self.depot:draw()
            if self.depot:isNearby(self.player.tx, self.player.ty) then
                self.depot:drawNearbyHint()
            end
        end
    end

    -- Object with smaller screen-Y is further back → draw first
    if psy + 8 < dsy + 16 then
        drawDepot() ; drawPlayer()
    else
        drawPlayer() ; drawDepot()
    end

    self.camera:clear()

    self.hud:draw(self.game, self.inventory, self.depot, self.player)
end

function DayState:keypressed(key, scancode, isrepeat)
    if key == "escape" then
        self.game.stateMachine:setState("menu")
    elseif key == "e" then
        self.harvest:tryStart(self.player.tx, self.player.ty, self.nodes, self.inventory)
    elseif key == "f" then
        if self.depot:isNearby(self.player.tx, self.player.ty) then
            self.depot:depositAll(self.inventory)
        end
    end
end

function DayState:gamepadPressed(joystick, button)
    if button == "b" then
        self.game.stateMachine:setState("menu")
    elseif button == "x" then
        self.harvest:tryStart(self.player.tx, self.player.ty, self.nodes, self.inventory)
    elseif button == "square" or button == "leftshoulder" then
        if self.depot:isNearby(self.player.tx, self.player.ty) then
            self.depot:depositAll(self.inventory)
        end
    end
end

function DayState:wheelmoved(x, y)
    self.camera:adjustZoom(y * 0.1)
end

return DayState
