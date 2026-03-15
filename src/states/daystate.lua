-- Day State
-- Daytime gameplay - explore, gather resources, build

local Class          = require("lib.class")
local Camera         = require("src.core.camera")
local Character      = require("src.characters.character")
local Iso            = require("src.rendering.isometric")
local DrawOrder      = require("src.rendering.draworder")
local TileBatch      = require("src.rendering.spritebatch")
local Tile           = require("src.world.tile")
local ChunkManager   = require("src.world.chunk")
local FogOfWar       = require("src.world.fogofwar")
local NodeManager    = require("src.resources.nodemanager")
local HarvestManager = require("src.resources.harvesting")
local RespawnManager = require("src.resources.respawn")
local Inventory      = require("src.inventory.inventory")
local SupplyDepot    = require("src.inventory.supplydepot")
local BuildManager   = require("src.buildings.buildmanager")
local BuildGhost     = require("src.buildings.buildghost")
local HUD            = require("src.ui.hud")
local Constants      = require("data.constants")

local DayState = Class:extend()

local CLASS_WORLD_VISUALS = {
    [Constants.CLASS.WARRIOR] = {appearance = "knight_swordman", tint = {1.0, 1.0, 1.0, 1}},
    [Constants.CLASS.ARCHER] = {appearance = "knight_archer", tint = {1.0, 0.96, 0.90, 1}},
    [Constants.CLASS.ENGINEER] = {appearance = "knight_templar", tint = {0.90, 0.92, 1.0, 1}},
    [Constants.CLASS.SCOUT] = {appearance = "knight_spearman", tint = {0.82, 1.0, 0.90, 1}},
}

local function compareEntityDrawEntries(a, b)
    if a.sy == b.sy then
        return (a.order or 0) < (b.order or 0)
    end

    return a.sy < b.sy
end

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

    self.game.tileManager:setProceduralSource(os.time())
    self.chunks = ChunkManager(self.game.tileManager)
    self.fog    = FogOfWar()

    local respawn = RespawnManager(game.config)
    self.nodes    = NodeManager(respawn)
    self.respawn  = respawn
    self.harvest  = HarvestManager(game.eventBus)

    self.playerClass = Constants.CLASS.WARRIOR
    self.player = {
        tx = 0.0,
        ty = 0.0,
        speed = 200,
        ftx = 0,
        fty = 1,
    }
    self.playerCharacter = self:createWorldPlayerCharacter(self.playerClass)
    self.inventory       = Inventory(self.playerClass)

    self.depot = SupplyDepot(2, 2, game.eventBus)
    self.depot:add("wood", 20)
    self.depot:add("stone", 10)

    self.buildings = BuildManager(game.eventBus)
    self.buildings:placeFree("basecore", 0, 0)
    self.ghost = BuildGhost()
    self.hud   = HUD()

    self.debugMode = false
    self.player.speed = self.playerCharacter.stats:getSpeed()
end

function DayState:enter(selectedClass)
    print("Entered Day State")
    self.game.dayCounter = (self.game.dayCounter or 0) + 1
    self.timeRemaining = self.game.config.dayLength

    self:_setPlayerClass(selectedClass)
    self:_ensureValidSpawn()

    local px, py = Iso.tileToScreen(self.player.tx, self.player.ty)
    self.camera:moveTo(px, py)

    self.game.eventBus:publish("day_start", self.game.dayCounter)
end

function DayState:createWorldPlayerCharacter(classType)
    local options = CLASS_WORLD_VISUALS[classType] or CLASS_WORLD_VISUALS[Constants.CLASS.WARRIOR]
    local character = Character.new(classType, 0, 0, options)
    character:setVisualScale(1.58)
    return character
end

function DayState:_setPlayerClass(classType)
    local resolvedClass = classType or self.playerClass or Constants.CLASS.WARRIOR
    local classChanged = resolvedClass ~= self.playerClass or not self.playerCharacter

    self.playerClass = resolvedClass
    if classChanged then
        self.playerCharacter = self:createWorldPlayerCharacter(resolvedClass)
        self.inventory = Inventory(resolvedClass)
    end

    self.player.speed = self.playerCharacter.stats:getSpeed()
end

function DayState:exit()
    print("Exited Day State")
    self.ghost:deactivate()
    self.harvest:cancel()
end

function DayState:_updateMovement(dt)
    local sdx, sdy = self.game.input:getMoveVector()
    if sdx ~= 0 or sdy ~= 0 then
        local spd = self.player.speed * dt
        local hw, hh = 32, 16
        local dtx = (sdx * spd / hw + sdy * spd / hh) / 2
        local dty = (sdy * spd / hh - sdx * spd / hw) / 2

        self:_movePlayer(dtx, dty)
        self.playerCharacter:setDesiredMovement(dtx, dty)

        local fx = dtx > 0 and 1 or (dtx < 0 and -1 or 0)
        local fy = dty > 0 and 1 or (dty < 0 and -1 or 0)
        if fx ~= 0 or fy ~= 0 then
            self.player.ftx = fx
            self.player.fty = fy
        end
    else
        self.playerCharacter:setDesiredMovement(0, 0)
    end

    self.playerCharacter:updateState()
end

function DayState:_updateCamera(dt)
    local rx, ry = self.game.input:getRightStick()
    if math.abs(rx) > 0 or math.abs(ry) > 0 then
        self.camera.x = self.camera.x + rx * 300 * dt
        self.camera.y = self.camera.y + ry * 300 * dt
    else
        local px, py = Iso.tileToScreen(self.player.tx, self.player.ty)
        self.camera:follow(px, py)
    end

    self.camera:update(dt)
end

function DayState:_updateWorld()
    self.chunks:update(self.player.tx, self.player.ty)
    self.fog:update(self.player.tx, self.player.ty)

    local ptx = math.floor(self.player.tx + 0.5)
    local pty = math.floor(self.player.ty + 0.5)
    local r = FogOfWar.VISION_RADIUS
    for ddx = -r, r do
        for ddy = -r, r do
            if ddx * ddx + ddy * ddy <= r * r then
                local tx = ptx + ddx
                local ty = pty + ddy
                self.fog:cacheType(tx, ty, self.chunks:getTile(tx, ty))
            end
        end
    end

    for _, chunk in pairs(self.chunks._chunks) do
        self.nodes:syncChunk(chunk)
    end
end

function DayState:update(dt)
    self.timeRemaining = self.timeRemaining - dt
    self.game.timeOfDay = self.timeRemaining

    if self.timeRemaining <= 0 then
        self.game.stateMachine:setState("night")
        return
    end

    self:_updateMovement(dt)
    self:_updateCamera(dt)
    self:_updateWorld()

    self.harvest:update(dt, self.player.tx, self.player.ty, self.nodes, self.inventory)
    self.respawn:update(dt)
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

        local building = self.buildings:getAt(tileX, tileY)
        if building and building.def and building.def.blocksMovement then
            return false
        end

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

function DayState:_getPropOpacity(image, tx, ty, quad)
    local psx, psy = Iso.tileToScreen(self.player.tx, self.player.ty)
    local osx, osy = Iso.tileToScreen(tx, ty)
    local iw, ih
    if quad then
        local _, _, qw, qh = quad:getViewport()
        iw, ih = qw, qh
    else
        iw, ih = image:getDimensions()
    end

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

function DayState:_ghostTile()
    local ptx = math.floor(self.player.tx + 0.5)
    local pty = math.floor(self.player.ty + 0.5)
    return ptx + self.player.ftx, pty + self.player.fty
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
    return math.floor(txMin) - m, math.floor(tyMin) - m,
           math.ceil(txMax) + m, math.ceil(tyMax) + m
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
                    or self.fog:getCachedType(tx, ty)
                if tileType then
                    local _, sy = Iso.tileToScreen(tx, ty)
                    list[#list + 1] = {sy = sy, tx = tx, ty = ty, t = tileType, visible = (state == "visible")}
                end
            end
        end
    end
    table.sort(list, function(a, b) return a.sy < b.sy end)
    return list
end

function DayState:_drawTileGround(entry, renderData, dim)
    if renderData and renderData.ground then
        local tint = renderData.ground.tint
        Iso.drawTexturedTile(
            renderData.ground.image,
            renderData.ground.quad,
            entry.tx,
            entry.ty,
            tint[1] * dim,
            tint[2] * dim,
            tint[3] * dim,
            1
        )
        return
    end

    local color = Tile.getColor(entry.t)
    Iso.drawTile(entry.tx, entry.ty, color[1] * dim, color[2] * dim, color[3] * dim, 1)
end

function DayState:_queueTileOverlay(entry, renderData, dim, entityDrawList)
    if not renderData or not renderData.overlay then
        return
    end

    local overlay = renderData.overlay
    local tint = overlay.tint
    local opacity = self:_getPropOpacity(overlay.image, entry.tx, entry.ty, overlay.quad)
    entityDrawList[#entityDrawList + 1] = {
        sy = entry.sy + Iso.TILE_H,
        order = 10,
        draw = function()
            Iso.drawProp(overlay.image, entry.tx, entry.ty, {
                quad = overlay.quad,
                scale = overlay.scale,
                ox = overlay.ox,
                oy = overlay.oy,
                anchorX = overlay.anchorX,
                anchorY = overlay.anchorY,
                r = tint[1] * dim,
                g = tint[2] * dim,
                b = tint[3] * dim,
                a = opacity,
            })
        end
    }
end

function DayState:_drawVisibleTileOutline(entry)
    if not entry.visible then
        return
    end

    local sx, sy = Iso.tileToScreen(entry.tx, entry.ty)
    love.graphics.setColor(0, 0, 0, 0.12)
    love.graphics.polygon("line",
        sx, sy,
        sx + Iso.TILE_W * 0.5, sy + Iso.TILE_H * 0.5,
        sx, sy + Iso.TILE_H,
        sx - Iso.TILE_W * 0.5, sy + Iso.TILE_H * 0.5
    )
end

function DayState:_drawTerrain(drawList, worldTime, entityDrawList)
    for _, entry in ipairs(drawList) do
        local dim = entry.visible and 1 or 0.5
        local renderData = Tile.getRenderData(entry.t, entry.tx, entry.ty, worldTime)

        self:_drawTileGround(entry, renderData, dim)
        self:_queueTileOverlay(entry, renderData, dim, entityDrawList)
        self:_drawVisibleTileOutline(entry)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function DayState:_queueVisibleBuildingDraws(entityDrawList)
    for _, building in ipairs(self.buildings:getAll()) do
        if self.fog:getState(building.tx, building.ty) ~= "hidden" then
            entityDrawList[#entityDrawList + 1] = {
                sy = building:screenY(),
                order = 20,
                draw = function()
                    building:draw()
                end
            }
        end
    end
end

function DayState:_shouldDrawNode(node, x1, y1, x2, y2)
    local tileType = self.chunks:getTile(node.tx, node.ty)
    if node.tx < x1 or node.tx > x2 or node.ty < y1 or node.ty > y2 then
        return false
    end

    if not self.fog:isVisible(node.tx, node.ty) then
        return false
    end

    if node:isReady() then
        return tileType ~= "tree" and tileType ~= "rock"
    end

    return node.resourceType == "wood"
end

function DayState:_queueVisibleNodeDraws(entityDrawList, x1, y1, x2, y2)
    for _, node in pairs(self.nodes:getAll()) do
        if self:_shouldDrawNode(node, x1, y1, x2, y2) then
            local _, sy = Iso.tileToScreen(node.tx, node.ty)
            entityDrawList[#entityDrawList + 1] = {
                sy = sy,
                order = 30,
                draw = function()
                    node:draw()
                end
            }
        end
    end
end

function DayState:_drawDepot()
    self.depot:draw()
    if self.depot:isNearby(self.player.tx, self.player.ty) then
        self.depot:drawNearbyHint()
    end
end

function DayState:_queueDepotDraw(entityDrawList)
    if self.fog:getState(self.depot.tx, self.depot.ty) == "hidden" then
        return
    end

    local _, depotSy = Iso.tileToScreen(self.depot.tx, self.depot.ty)
    entityDrawList[#entityDrawList + 1] = {
        sy = depotSy,
        order = 40,
        draw = function()
            self:_drawDepot()
        end
    }
end

function DayState:_queuePlayerDraw(entityDrawList)
    local psx, psy = Iso.tileToScreen(self.player.tx, self.player.ty)
    self.playerCharacter.position.x = psx
    self.playerCharacter.position.y = psy + 2
    entityDrawList[#entityDrawList + 1] = {
        sy = psy + 18,
        order = 50,
        draw = function()
            self.playerCharacter:draw()
        end
    }
end

function DayState:_sortAndDrawEntities(entityDrawList)
    table.sort(entityDrawList, compareEntityDrawEntries)

    for _, entry in ipairs(entityDrawList) do
        entry.draw()
    end
end

function DayState:draw()
    love.graphics.clear(0.50, 0.70, 0.90, 1)

    self.camera:apply()

    local x1, y1, x2, y2 = self:_visibleTileRect()
    local drawList = self:_buildDrawList(x1, y1, x2, y2)
    local worldTime = love.timer.getTime()
    local entityDrawList = {}

    self:_drawTerrain(drawList, worldTime, entityDrawList)
    self:_queueVisibleBuildingDraws(entityDrawList)
    self:_queueVisibleNodeDraws(entityDrawList, x1, y1, x2, y2)
    self:_queueDepotDraw(entityDrawList)
    self:_queuePlayerDraw(entityDrawList)
    self:_sortAndDrawEntities(entityDrawList)

    self.harvest:drawHint(self.player.tx, self.player.ty, self.nodes, self.fog)
    self.harvest:draw()

    local gtx, gty = self:_ghostTile()
    self.ghost:draw(gtx, gty, self.buildings, self.depot)

    if self.debugMode then
        self:drawDebugWorld(drawList)
    end

    self.camera:clear()

    self.hud:draw(self.game, self.inventory, self.depot, self.player, self.ghost)

    if self.debugMode then
        self:drawDebugUI()
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function DayState:drawDebugWorld(drawList)
    local visibleColliderCount = 0

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
                visibleColliderCount = visibleColliderCount + 1
            elseif def and def.collision and def.collision.shape == "box" then
                local offsetX = def.collision.offsetX or 0
                local offsetY = def.collision.offsetY or 0
                local width = (def.collision.width or 0.25) * Iso.TILE_W
                local height = (def.collision.height or 0.25) * Iso.TILE_H * 2
                local sx, sy = Iso.tileToScreen(e.tx + offsetX, e.ty + offsetY)
                love.graphics.setColor(1, 0.45, 0.15, 0.8)
                love.graphics.rectangle("line", sx - width * 0.5, sy + Iso.TILE_H * 0.5 - height * 0.5, width, height)
                visibleColliderCount = visibleColliderCount + 1
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
    self.playerCharacter.position.x = psx
    self.playerCharacter.position.y = psy + 2

    local playerBounds = nil
    if self.playerCharacter.hitbox and self.playerCharacter.position then
        playerBounds = self.playerCharacter.hitbox:getBounds(self.playerCharacter.position)
        love.graphics.setColor(0.2, 0.95, 1, 0.9)
        love.graphics.rectangle(
            "line",
            playerBounds.left,
            playerBounds.top,
            playerBounds.right - playerBounds.left,
            playerBounds.bottom - playerBounds.top
        )
    end

    for _, point in ipairs(self:_getMovementSamplePoints(self.player.tx, self.player.ty)) do
        local sx, sy = Iso.tileToScreen(point[1], point[2])
        love.graphics.setColor(1, 1, 0.15, 0.95)
        love.graphics.circle("fill", sx, sy + 10, 3)
    end

    self.debugVisibleColliderCount = visibleColliderCount

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
        string.format("Visible Tile Colliders: %d", self.debugVisibleColliderCount or 0),
        string.format(
            "Player Hitbox: %dx%d (%d,%d)",
            self.playerCharacter.hitbox and self.playerCharacter.hitbox.width or 0,
            self.playerCharacter.hitbox and self.playerCharacter.hitbox.height or 0,
            self.playerCharacter.hitbox and self.playerCharacter.hitbox.offsetX or 0,
            self.playerCharacter.hitbox and self.playerCharacter.hitbox.offsetY or 0
        ),
        string.format("Zoom: %.2f", self.camera.zoom),
        string.format("Loaded Chunks: %d", self:_countLoadedChunks()),
        "Orange: tile collider  Cyan: player hitbox  Yellow: move samples",
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
        if self.ghost:isActive() then
            self.ghost:deactivate()
        else
            self.game.stateMachine:setState("menu")
        end
    elseif key == "space" then
        self.game.stateMachine:setState("night")
    elseif key == "f3" then
        self.debugMode = not self.debugMode
    elseif key == "b" then
        if self.ghost:isActive() then
            self.ghost:cycleType()
        else
            self.ghost:activate()
        end
    elseif key == "r" then
        if self.ghost:isActive() then
            local tx, ty = self:_ghostTile()
            self.buildings:place(self.ghost:currentType(), tx, ty, self.depot)
        end
    elseif key == "e" then
        if not self.ghost:isActive() then
            self.harvest:tryStart(self.player.tx, self.player.ty, self.nodes, self.inventory)
        end
    elseif key == "f" then
        if self.depot:isNearby(self.player.tx, self.player.ty) then
            self.depot:depositAll(self.inventory)
        end
    end
end

function DayState:gamepadPressed(joystick, button)
    if button == "b" then
        if self.ghost:isActive() then
            self.ghost:deactivate()
        else
            self.game.stateMachine:setState("menu")
        end
    elseif button == "y" then
        self.game.stateMachine:setState("night")
    elseif button == "rightshoulder" then
        if self.ghost:isActive() then
            self.ghost:cycleType()
        else
            self.ghost:activate()
        end
    elseif button == "a" then
        if self.ghost:isActive() then
            local tx, ty = self:_ghostTile()
            self.buildings:place(self.ghost:currentType(), tx, ty, self.depot)
        end
    elseif button == "x" then
        if not self.ghost:isActive() then
            self.harvest:tryStart(self.player.tx, self.player.ty, self.nodes, self.inventory)
        end
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
