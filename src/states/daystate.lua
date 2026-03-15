-- Day State
-- Daytime gameplay - explore, gather resources, build

local Class        = require("lib.class")
local Camera       = require("src.core.camera")
local Character    = require("src.characters.character")
local Iso          = require("src.rendering.isometric")
local DrawOrder    = require("src.rendering.draworder")
local TileBatch    = require("src.rendering.spritebatch")
local Tile         = require("src.world.tile")
local WorldGen     = require("src.world.worldgen")
local ChunkManager = require("src.world.chunk")
local FogOfWar     = require("src.world.fogofwar")
local Constants    = require("data.constants")

local DayState = Class:extend()

local CLASS_WORLD_VISUALS = {
    [Constants.CLASS.WARRIOR] = {appearance = "soldier", tint = {1.0, 1.0, 1.0, 1}},
    [Constants.CLASS.ARCHER] = {appearance = "soldier", tint = {1.0, 0.96, 0.90, 1}},
    [Constants.CLASS.ENGINEER] = {appearance = "orc", tint = {0.90, 0.92, 1.0, 1}},
    [Constants.CLASS.SCOUT] = {appearance = "soldier", tint = {0.82, 1.0, 0.90, 1}},
}

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
    self.playerClass = Constants.CLASS.WARRIOR
    self.playerCharacter = self:createWorldPlayerCharacter(self.playerClass)
    self.debugMode = false
end

function DayState:enter(selectedClass)
    print("Entered Day State")
    self.game.dayCounter   = (self.game.dayCounter or 0) + 1
    self.timeRemaining     = self.game.config.dayLength
    self.playerClass = selectedClass or self.playerClass or Constants.CLASS.WARRIOR
    self.playerCharacter = self:createWorldPlayerCharacter(self.playerClass)
    self.player.speed = self.playerCharacter.stats:getSpeed()
    self:_ensureValidSpawn()

    local px, py = Iso.tileToScreen(self.player.tx, self.player.ty)
    self.camera:moveTo(px, py)

    self.game.eventBus:publish("day_start", self.game.dayCounter)
end

function DayState:createWorldPlayerCharacter(classType)
    local options = CLASS_WORLD_VISUALS[classType] or CLASS_WORLD_VISUALS[Constants.CLASS.WARRIOR]
    local character = Character.new(classType, 0, 0, options)
    character.visualScale = 1.58
    return character
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
        self:_movePlayer(dtx, dty)
        self.playerCharacter:setDesiredMovement(dtx, dty)
    else
        self.playerCharacter:setDesiredMovement(0, 0)
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
    self.playerCharacter:updateVisuals(dt)

    if self.game.world then
        self.game.world:update(dt)
    end
end

function DayState:_ensureValidSpawn()
    local spawnTx, spawnTy = self:_findNearestWalkableTile(self.player.tx, self.player.ty)
    self.player.tx = spawnTx
    self.player.ty = spawnTy
end

function DayState:_findNearestWalkableTile(originTx, originTy)
    local startTx = math.floor(originTx + 0.5)
    local startTy = math.floor(originTy + 0.5)

    if self:_canMoveTo(startTx, startTy) then
        return startTx, startTy
    end

    for radius = 1, 12 do
        for dx = -radius, radius do
            for dy = -radius, radius do
                if math.abs(dx) == radius or math.abs(dy) == radius then
                    local tx = startTx + dx
                    local ty = startTy + dy
                    if self:_canMoveTo(tx, ty) then
                        return tx, ty
                    end
                end
            end
        end
    end

    return startTx, startTy
end

function DayState:_canMoveTo(tx, ty)
    local radius = 0.28
    local samplePoints = {
        {tx, ty},
        {tx - radius, ty},
        {tx + radius, ty},
        {tx, ty - radius},
        {tx, ty + radius},
    }

    for _, point in ipairs(samplePoints) do
        local tileX = math.floor(point[1] + 0.5)
        local tileY = math.floor(point[2] + 0.5)
        local tileType = self.chunks:getTile(tileX, tileY)
        local localX = point[1] - tileX
        local localY = point[2] - tileY
        if tileType and not Tile.isPointWalkable(tileType, localX, localY) then
            return false
        end
    end

    return true
end

function DayState:_movePlayer(dtx, dty)
    local targetTx = self.player.tx + dtx
    local targetTy = self.player.ty + dty

    if self:_canMoveTo(targetTx, targetTy) then
        self.player.tx = targetTx
        self.player.ty = targetTy
        return
    end

    if self:_canMoveTo(targetTx, self.player.ty) then
        self.player.tx = targetTx
    end

    if self:_canMoveTo(self.player.tx, targetTy) then
        self.player.ty = targetTy
    end
end

function DayState:_getMovementSamplePoints(tx, ty)
    local radius = 0.28
    return {
        {tx, ty},
        {tx - radius, ty},
        {tx + radius, ty},
        {tx, ty - radius},
        {tx, ty + radius},
    }
end

function DayState:_getPropOpacity(image, tx, ty)
    local psx, psy = Iso.tileToScreen(self.player.tx, self.player.ty)
    local osx, osy = Iso.tileToScreen(tx, ty)
    local iw, ih = image:getDimensions()

    local propLeft = osx - iw * 0.5
    local propRight = osx + iw * 0.5
    local propTop = osy + Iso.TILE_H * 0.5 - ih
    local propBottom = osy + Iso.TILE_H * 0.5

    local playerWidth = 28
    local playerTop = psy - 42
    local playerBottom = psy + 18

    local overlapsHorizontally = (psx + playerWidth * 0.5) > propLeft and (psx - playerWidth * 0.5) < propRight
    local overlapsVertically = playerBottom > propTop and playerTop < propBottom

    if overlapsHorizontally and overlapsVertically and psy < propBottom then
        return 0.5
    end

    return 1
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

    local worldTime = love.timer.getTime()
    local entityDrawList = {}
    for _, e in ipairs(drawList) do
        local dim = e.visible and 1 or 0.5
        local renderData = Tile.getRenderData(e.t, e.tx, e.ty, worldTime)

        if renderData and renderData.ground then
            local tint = renderData.ground.tint
            Iso.drawTexturedTile(
                renderData.ground.image,
                renderData.ground.quad,
                e.tx,
                e.ty,
                tint[1] * dim,
                tint[2] * dim,
                tint[3] * dim,
                1
            )
        else
            local c = Tile.getColor(e.t)
            Iso.drawTile(e.tx, e.ty, c[1] * dim, c[2] * dim, c[3] * dim, 1)
        end

        if renderData and renderData.overlay then
            local tint = renderData.overlay.tint
            local opacity = self:_getPropOpacity(renderData.overlay.image, e.tx, e.ty)
            entityDrawList[#entityDrawList + 1] = {
                sy = e.sy + Iso.TILE_H,
                draw = function()
                    Iso.drawProp(renderData.overlay.image, e.tx, e.ty, {
                        scale = renderData.overlay.scale,
                        r = tint[1] * dim,
                        g = tint[2] * dim,
                        b = tint[3] * dim,
                        a = opacity
                    })
                end
            }
        end

        if e.visible then
            local sx, sy = Iso.tileToScreen(e.tx, e.ty)
            love.graphics.setColor(0, 0, 0, 0.12)
            love.graphics.polygon("line",
                sx, sy,
                sx + Iso.TILE_W * 0.5, sy + Iso.TILE_H * 0.5,
                sx, sy + Iso.TILE_H,
                sx - Iso.TILE_W * 0.5, sy + Iso.TILE_H * 0.5
            )
        end
    end
    love.graphics.setColor(1, 1, 1, 1)

    local psx, psy = Iso.tileToScreen(self.player.tx, self.player.ty)
    self.playerCharacter.position.x = psx
    self.playerCharacter.position.y = psy + 2
    entityDrawList[#entityDrawList + 1] = {
        sy = psy + 18,
        draw = function()
            self.playerCharacter:draw()
        end
    }

    table.sort(entityDrawList, function(a, b)
        return a.sy < b.sy
    end)

    for _, entry in ipairs(entityDrawList) do
        entry.draw()
    end

    if self.debugMode then
        self:drawDebugWorld(drawList)
    end

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

    if self.debugMode then
        self:drawDebugUI()
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function DayState:drawDebugWorld(drawList)
    for _, e in ipairs(drawList) do
        if e.visible then
            local def = Tile.get(e.t)
            if def and def.collision and def.collision.shape == "circle" then
                local offsetX = def.collision.offsetX or 0
                local offsetY = def.collision.offsetY or 0
                local sx, sy = Iso.tileToScreen(e.tx + offsetX, e.ty + offsetY)
                local radius = def.collision.radius * Iso.TILE_W
                love.graphics.setColor(1, 0.45, 0.15, 0.8)
                love.graphics.circle("line", sx, sy + Iso.TILE_H * 0.5, radius)
            elseif e.t == "water" then
                local sx, sy = Iso.tileToScreen(e.tx, e.ty)
                love.graphics.setColor(0.15, 0.7, 1, 0.45)
                love.graphics.polygon("line",
                    sx, sy,
                    sx + Iso.TILE_W * 0.5, sy + Iso.TILE_H * 0.5,
                    sx, sy + Iso.TILE_H,
                    sx - Iso.TILE_W * 0.5, sy + Iso.TILE_H * 0.5
                )
            end
        end
    end

    local psx, psy = Iso.tileToScreen(self.player.tx, self.player.ty)
    love.graphics.setColor(0.25, 1, 0.35, 0.85)
    love.graphics.rectangle("line", psx - 16, psy - 14, 32, 32)

    for _, point in ipairs(self:_getMovementSamplePoints(self.player.tx, self.player.ty)) do
        local sx, sy = Iso.tileToScreen(point[1], point[2])
        love.graphics.setColor(1, 1, 0.15, 0.95)
        love.graphics.circle("fill", sx, sy + 10, 3)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function DayState:drawDebugUI()
    local px, py = Iso.tileToScreen(self.player.tx, self.player.ty)
    local tileType = self.chunks:getTile(math.floor(self.player.tx + 0.5), math.floor(self.player.ty + 0.5))
    local lines = {
        "=== WORLD DEBUG ===",
        string.format("Tile Pos: %.2f, %.2f", self.player.tx, self.player.ty),
        string.format("Screen Pos: %.0f, %.0f", px, py),
        "Tile: " .. tostring(tileType),
        string.format("Zoom: %.2f", self.camera.zoom),
        string.format("Loaded Chunks: %d", self:_countLoadedChunks()),
        "F3: Toggle World Debug",
    }

    local panelX = love.graphics.getWidth() - 250
    local panelY = 20
    local lineHeight = 18
    local panelH = 16 + #lines * lineHeight

    love.graphics.setFont(self.smallFont)
    love.graphics.setColor(0, 0, 0, 0.72)
    love.graphics.rectangle("fill", panelX, panelY, 230, panelH)

    love.graphics.setColor(0.5, 1, 0.5, 1)
    local y = panelY + 10
    for _, line in ipairs(lines) do
        love.graphics.print(line, panelX + 12, y)
        y = y + lineHeight
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function DayState:_countLoadedChunks()
    local count = 0
    for _ in pairs(self.chunks._chunks) do
        count = count + 1
    end
    return count
end

function DayState:keypressed(key, scancode, isrepeat)
    if key == "escape" then
        self.game.stateMachine:setState("menu")
    elseif key == "space" then
        self.game.stateMachine:setState("night")
    elseif key == "f3" then
        self.debugMode = not self.debugMode
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
