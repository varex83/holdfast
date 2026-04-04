--- World State
-- Unified game state for both day and night phases
-- Handles shared infrastructure: camera, chunks, rendering, player

local Class = require("lib.class")
local Camera = require("src.core.camera")
local CharacterFactory = require("src.characters.characterfactory")
local Iso = require("src.rendering.isometric")
local DrawOrder = require("src.rendering.draworder")
local TileBatch = require("src.rendering.spritebatch")
local Tile = require("src.world.tile")
local ChunkManager = require("src.world.chunk")
local FogOfWar = require("src.world.fogofwar")
local NodeManager = require("src.resources.nodemanager")
local RespawnManager = require("src.resources.respawn")
local Inventory = require("src.inventory.inventory")
local HUD = require("src.ui.hud")
local Constants = require("data.constants")
local PhaseManager = require("src.world.phasemanager")
local DayPhase = require("src.world.dayphase")
local NightPhase = require("src.world.nightphase")

local WorldState = Class:extend()

local function compareEntityDrawEntries(a, b)
    if a.sy == b.sy then
        return (a.order or 0) < (b.order or 0)
    end
    return a.sy < b.sy
end

local function screenDirToTile(sx, sy)
    local hw, hh = 32, 16
    local dtx = sx / hw + sy / hh
    local dty = sy / hh - sx / hw
    return dtx > 0 and 1 or (dtx < 0 and -1 or 0),
           dty > 0 and 1 or (dty < 0 and -1 or 0)
end

function WorldState:new(game)
    self.game = game
    self.font = love.graphics.newFont(24)
    self.smallFont = love.graphics.newFont(14)
    self.hud = HUD()
    self:_resetSessionState(Constants.CLASS.WARRIOR)
end

function WorldState:_createSeed()
    return self.game.config.worldSeed or os.time()
end

function WorldState:_resetSessionState(selectedClass)
    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()

    self.camera = Camera(sw, sh)
    self.drawOrder = DrawOrder()
    self.tileBatch = TileBatch()
    self._stickCooldown = 0
    self._prevMouse = { x = -1, y = -1 }
    self.debugMode = false

    self.game.tileManager:setProceduralSource(self:_createSeed())
    self.chunks = ChunkManager(self.game.tileManager)
    self.fog = FogOfWar()

    local respawn = RespawnManager(self.game.config)
    self.nodes = NodeManager(respawn)
    self.respawn = respawn

    self.phaseManager = PhaseManager(self.game.config)
    self.dayPhase = DayPhase(self.game.eventBus)
    self.nightPhase = NightPhase(self.game.eventBus)
    self.currentPhase = self.dayPhase

    self.player = {
        tx = 0.0,
        ty = 0.0,
        speed = 0,
        ftx = 0,
        fty = 1,
    }
    self.playerClass = selectedClass or Constants.CLASS.WARRIOR
    self.playerCharacter = self:createWorldPlayerCharacter(self.playerClass)
    self.inventory = Inventory(self.playerClass)
    self.player.speed = self.playerCharacter.stats:getSpeed()
end

function WorldState:enter(selectedClass)
    print("Entered World State")
    self:_resetSessionState(selectedClass or self.playerClass)

    self.phaseManager:reset()
    self.phaseManager:transition(PhaseManager.PHASE.DAY)
    self.currentPhase = self.dayPhase
    self.currentPhase:enter(self)
    self:_syncGameClock()

    self:_ensureValidSpawn()

    local px, py = Iso.tileToScreen(self.player.tx, self.player.ty)
    self.camera:moveTo(px, py)
end

function WorldState:exit()
    print("Exited World State")
    if self.currentPhase and self.currentPhase.exit then
        self.currentPhase:exit(self)
    end
end

function WorldState:createWorldPlayerCharacter(classType)
    local character = CharacterFactory.create(classType, 0, 0)
    character:setVisualScale(1.58)
    return character
end

function WorldState:_setPlayerClass(classType)
    local resolvedClass = classType or self.playerClass or Constants.CLASS.WARRIOR
    local classChanged = resolvedClass ~= self.playerClass or not self.playerCharacter

    self.playerClass = resolvedClass
    if classChanged then
        self.playerCharacter = self:createWorldPlayerCharacter(resolvedClass)
        self.inventory = Inventory(resolvedClass)
    end

    self.player.speed = self.playerCharacter.stats:getSpeed()
end

function WorldState:_syncGameClock()
    self.game.dayCounter = self.phaseManager:getDayNumber()
    self.game.timeOfDay = self.phaseManager:getTimeRemaining()
end

function WorldState:_ensureValidSpawn()
    local spawnTx, spawnTy = self:_findNearestWalkableTile(self.player.tx, self.player.ty)
    self.player.tx = spawnTx
    self.player.ty = spawnTy
end

function WorldState:_findNearestWalkableTile(originTx, originTy)
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

function WorldState:_canMoveTo(tx, ty)
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

        -- Check buildings from day phase
        if self.dayPhase.buildManager then
            local building = self.dayPhase.buildManager:getAt(tileX, tileY)
            if building and building.def and building.def.blocksMovement then
                return false
            end
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

function WorldState:_movePlayer(dtx, dty)
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

function WorldState:_updateMovement(dt)
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

function WorldState:_updateCamera(dt)
    local rx, ry = self.game.input:getRightStick()

    if self.phaseManager:isDay() and self.dayPhase.buildGhost and self.dayPhase.buildGhost:isActive() then
        self._stickCooldown = self._stickCooldown - dt
        if self._stickCooldown <= 0 and (math.abs(rx) > 0.4 or math.abs(ry) > 0.4) then
            local ctx, cty = screenDirToTile(rx, ry)
            if ctx ~= 0 or cty ~= 0 then
                self.dayPhase.buildGhost:moveCursor(ctx, cty)
                self._stickCooldown = 0.15
            end
        end
        local px, py = Iso.tileToScreen(self.player.tx, self.player.ty)
        self.camera:follow(px, py)
    elseif math.abs(rx) > 0 or math.abs(ry) > 0 then
        self.camera.x = self.camera.x + rx * 300 * dt
        self.camera.y = self.camera.y + ry * 300 * dt
    else
        local px, py = Iso.tileToScreen(self.player.tx, self.player.ty)
        self.camera:follow(px, py)
    end

    self.camera:update(dt)
end

function WorldState:_updateBuildCursor()
    if not self.phaseManager:isDay() then
        return
    end

    if not self.dayPhase.buildGhost or not self.dayPhase.buildGhost:isActive() then
        return
    end

    local mx, my = love.mouse.getPosition()
    if mx ~= self._prevMouse.x or my ~= self._prevMouse.y then
        self._prevMouse.x = mx
        self._prevMouse.y = my
        self.dayPhase.buildGhost:updateFromMouse(self.camera)
    end
end

function WorldState:_updateWorld()
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

function WorldState:update(dt)
    local shouldTransition = self.phaseManager:update(dt)
    self:_syncGameClock()

    if shouldTransition then
        self:_transitionPhase()
        return
    end

    self:_updateMovement(dt)
    self:_updateCamera(dt)
    self:_updateBuildCursor()
    self:_updateWorld()

    self.currentPhase:update(dt, self)
    self.respawn:update(dt)
    self.playerCharacter:updateVisuals(dt)
    if self.game.world then
        self.game.world:update(dt)
    end
end

function WorldState:_transitionPhase()
    if self.phaseManager:isDay() then
        self:_setCurrentPhase(PhaseManager.PHASE.NIGHT)
    else
        self:_setCurrentPhase(PhaseManager.PHASE.DAY)
    end
end

function WorldState:_setCurrentPhase(phase)
    if self.currentPhase and self.currentPhase.exit then
        self.currentPhase:exit(self)
    end

    self.phaseManager:transition(phase)
    self.currentPhase = phase == PhaseManager.PHASE.DAY and self.dayPhase or self.nightPhase

    self.currentPhase:enter(self)
    self:_syncGameClock()
    self:_ensureValidSpawn()
end

--  ═══════════════════════════════════════════════════════════════════════════
--  RENDERING
-- ═══════════════════════════════════════════════════════════════════════════

function WorldState:_ghostTile()
    local ptx = math.floor(self.player.tx + 0.5)
    local pty = math.floor(self.player.ty + 0.5)
    return ptx + self.player.ftx, pty + self.player.fty
end

function WorldState:_visibleTileRect()
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

function WorldState:_buildDrawList(x1, y1, x2, y2)
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

function WorldState:_drawTileGround(entry, renderData, dim)
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

function WorldState:_getPropOpacity(image, tx, ty, quad)
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

function WorldState:_queueTileOverlay(entry, renderData, dim, entityDrawList)
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

function WorldState:_drawVisibleTileOutline(_entry)
    -- Tile grid outline disabled — too prominent at full map visibility.
end

function WorldState:_drawTerrain(drawList, worldTime, entityDrawList)
    for _, entry in ipairs(drawList) do
        local dim = entry.visible and 1 or 0.5
        local renderData = Tile.getRenderData(entry.t, entry.tx, entry.ty, worldTime)

        self:_drawTileGround(entry, renderData, dim)
        self:_queueTileOverlay(entry, renderData, dim, entityDrawList)
        self:_drawVisibleTileOutline(entry)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function WorldState:_shouldDrawNode(node, x1, y1, x2, y2)
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

function WorldState:_queueVisibleNodeDraws(entityDrawList, x1, y1, x2, y2)
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

function WorldState:_queuePlayerDraw(entityDrawList)
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

function WorldState:_sortAndDrawEntities(entityDrawList)
    table.sort(entityDrawList, compareEntityDrawEntries)

    for _, entry in ipairs(entityDrawList) do
        entry.draw()
    end
end

function WorldState:draw()
    -- Get background color from current phase
    local bgColor = {0.50, 0.70, 0.90, 1}  -- Day default
    if self.phaseManager:isNight() then
        bgColor = self.nightPhase:getBackgroundColor()
    end
    love.graphics.clear(bgColor[1], bgColor[2], bgColor[3], bgColor[4])

    self.camera:apply()

    local x1, y1, x2, y2 = self:_visibleTileRect()
    local drawList = self:_buildDrawList(x1, y1, x2, y2)
    local worldTime = love.timer.getTime()
    local entityDrawList = {}

    -- Draw terrain and queue overlay props
    self:_drawTerrain(drawList, worldTime, entityDrawList)

    -- Queue phase-specific entity draws
    self.currentPhase:queueEntityDraws(entityDrawList, self)

    -- Queue resource nodes
    self:_queueVisibleNodeDraws(entityDrawList, x1, y1, x2, y2)

    -- Queue player
    self:_queuePlayerDraw(entityDrawList)

    -- Sort and draw all entities by screen Y
    self:_sortAndDrawEntities(entityDrawList)

    -- Draw phase-specific overlays (harvest hints, etc.)
    if self.phaseManager:isDay() and self.dayPhase.harvestManager then
        self.dayPhase.harvestManager:drawHint(self.player.tx, self.player.ty, self.nodes, self.fog)
        self.dayPhase.harvestManager:draw()

        if self.dayPhase.buildGhost then
            self.dayPhase.buildGhost:draw(self.dayPhase.buildManager, self.dayPhase.depot)
        end
    end

    if self.debugMode then
        self:drawDebugWorld(drawList)
    end

    self.camera:clear()

    -- Draw HUD
    self.hud:draw(self.game, self.inventory, self.dayPhase.depot, self.player, self.dayPhase.buildGhost)

    -- Draw phase-specific UI
    self.currentPhase:draw(self)

    if self.debugMode then
        self:drawDebugUI()
    end

    love.graphics.setColor(1, 1, 1, 1)
end

--  ═══════════════════════════════════════════════════════════════════════════
--  DEBUG RENDERING
-- ═══════════════════════════════════════════════════════════════════════════

function WorldState:_getMovementSamplePoints(tx, ty)
    local radius = 0.28
    return {
        {tx, ty},
        {tx - radius, ty},
        {tx + radius, ty},
        {tx, ty - radius},
        {tx, ty + radius},
    }
end

function WorldState:drawDebugWorld(drawList)
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
            end
        end
    end

    local psx, psy = Iso.tileToScreen(self.player.tx, self.player.ty)
    self.playerCharacter.position.x = psx
    self.playerCharacter.position.y = psy + 2

    if self.playerCharacter.hitbox and self.playerCharacter.position then
        local playerBounds = self.playerCharacter.hitbox:getBounds(self.playerCharacter.position)
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

function WorldState:drawDebugUI()
    local px, py = Iso.tileToScreen(self.player.tx, self.player.ty)
    local tileType = self.chunks:getTile(math.floor(self.player.tx + 0.5), math.floor(self.player.ty + 0.5))
    local lines = {
        "=== WORLD DEBUG ===",
        string.format("Phase: %s (Day %d)", self.phaseManager:getCurrentPhase(), self.phaseManager:getDayNumber()),
        string.format("Time: %s", self.phaseManager:getTimeString()),
        string.format("Tile Pos: %.2f, %.2f", self.player.tx, self.player.ty),
        string.format("Screen Pos: %.0f, %.0f", px, py),
        "Tile: " .. tostring(tileType),
        string.format("Visible Colliders: %d", self.debugVisibleColliderCount or 0),
        string.format("Zoom: %.2f", self.camera.zoom),
        string.format("Loaded Chunks: %d", self:_countLoadedChunks()),
        "F3: Toggle Debug",
    }

    local panelX = love.graphics.getWidth() - 280
    local panelY = 20
    local lineHeight = 18
    local panelH = 16 + #lines * lineHeight

    love.graphics.setFont(self.smallFont)
    love.graphics.setColor(0, 0, 0, 0.72)
    love.graphics.rectangle("fill", panelX, panelY, 260, panelH)

    love.graphics.setColor(0.5, 1, 0.5, 1)
    local y = panelY + 10
    for _, line in ipairs(lines) do
        love.graphics.print(line, panelX + 12, y)
        y = y + lineHeight
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function WorldState:_countLoadedChunks()
    local count = 0
    for _ in pairs(self.chunks._chunks) do
        count = count + 1
    end
    return count
end

-- ═══════════════════════════════════════════════════════════════════════════
--  INPUT HANDLING
-- ═══════════════════════════════════════════════════════════════════════════

function WorldState:keypressed(key, scancode, isrepeat)
    if key == "escape" then
        if self.dayPhase.buildGhost and self.dayPhase.buildGhost:isActive() then
            self.dayPhase.buildGhost:deactivate()
        else
            self.game.stateMachine:setState("menu")
        end
        return
    elseif key == "f3" then
        self.debugMode = not self.debugMode
        return
    end

    local phaseResult = self.currentPhase:keypressed(key, self)
    self:_applyPhaseResult(phaseResult)
end

function WorldState:gamepadPressed(joystick, button)
    if button == "b" then
        if self.dayPhase.buildGhost and self.dayPhase.buildGhost:isActive() then
            self.dayPhase.buildGhost:deactivate()
        else
            self.game.stateMachine:setState("menu")
        end
        return
    end

    local phaseResult = self.currentPhase:keypressed(button, self)
    self:_applyPhaseResult(phaseResult)
end

function WorldState:_applyPhaseResult(phaseResult)
    if phaseResult == "transition_night" then
        self:_setCurrentPhase(PhaseManager.PHASE.NIGHT)
    elseif phaseResult == "transition_day" then
        self:_setCurrentPhase(PhaseManager.PHASE.DAY)
    end
end

function WorldState:wheelmoved(_x, y)
    self.camera:adjustZoom(y * 0.1)
end

return WorldState
