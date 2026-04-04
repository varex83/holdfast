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
local Casino         = require("src.world.casino")
local BuildManager   = require("src.buildings.buildmanager")
local BuildGhost     = require("src.buildings.buildghost")
local HUD            = require("src.ui.hud")
local Constants      = require("data.constants")
local CombatManager  = require("src.combat.combatmanager")

local DayState = Class:extend()

local CLASS_WORLD_VISUALS = {
    [Constants.CLASS.WARRIOR] = {appearance = "knight_swordman", tint = {1.0, 1.0, 1.0, 1}},
    [Constants.CLASS.ARCHER] = {appearance = "knight_archer", tint = {1.0, 0.96, 0.90, 1}},
    [Constants.CLASS.ENGINEER] = {appearance = "knight_templar", tint = {0.90, 0.92, 1.0, 1}},
    [Constants.CLASS.SCOUT] = {appearance = "knight_spearman", tint = {0.82, 1.0, 0.90, 1}},
}

local function compareEntityDrawEntries(a, b)
    if a.sy == b.sy then return (a.order or 0) < (b.order or 0) end
    return a.sy < b.sy
end

-- Convert stick/screen direction to iso tile direction.
-- Uses the same matrix as player movement: dtx = sx/hw + sy/hh, dty = sy/hh - sx/hw.
local ARROW_CURSOR = { up={-1,-1}, down={1,1}, left={-1,1}, right={1,-1} }
local BASE_LAYOUT = {
    basecore = { tx = 0, ty = 0 },
    depot = { tx = 4, ty = 1 },
    casino = { tx = -4, ty = 1 },
    player = { tx = 0, ty = 4 },
}
local BASE_CLEARANCE = {
    basecore = { x1 = -1, y1 = -1, x2 = 1, y2 = 1 },
    depot = { x1 = -1, y1 = -1, x2 = 1, y2 = 1 },
    casino = { x1 = -2, y1 = -1, x2 = 2, y2 = 2 },
    player = { x1 = -1, y1 = -1, x2 = 1, y2 = 1 },
}

local function screenDirToTile(sx, sy)
    local hw, hh = 32, 16
    local dtx = sx / hw + sy / hh
    local dty = sy / hh - sx / hw
    return dtx > 0 and 1 or (dtx < 0 and -1 or 0),
           dty > 0 and 1 or (dty < 0 and -1 or 0)
end

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

    self.worldSeed = os.time()
    self.game.tileManager:setProceduralSource(self.worldSeed)
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
    self.depot:add("wood",  20)
    self.depot:add("stone", 10)
    self.casino = Casino(-2, 2)
    self.casinoInterior = {
        active = false,
        chunks = nil,
        spawn = { tx = 5, ty = 7 },
        table = { tx = 5, ty = 3 },
        returnPlayer = nil,
    }

    self.buildings = BuildManager(game.eventBus)
    self.buildings:placeFree("basecore", 0, 0)
    self.ghost = BuildGhost()
    self.hud   = HUD()
    self.notice = { text = "", alpha = 0, y = 52 }

    self.debugMode = false
    self._stickCooldown = 0
    self._prevMouse = { x = -1, y = -1 }
    self.dash = { active = false, remaining = 0, speed = 10.0, dirX = 0, dirY = 0, cooldown = 0, cooldownTime = 0.7 }
    self.abilityDash = { active = false, remaining = 0, speed = 6.0, dirX = 0, dirY = 0, duration = 0.5 }
    self.combatManager = CombatManager.new(game.world, game.eventBus)
    self.player.speed = self.playerCharacter.stats:getSpeed()
    self.baseLayoutInitialized = false
end

function DayState:_isInCasino()
    return self.casinoInterior.active
end

function DayState:_getActiveChunks()
    return self:_isInCasino() and self.casinoInterior.chunks or self.chunks
end

function DayState:_isNearCasinoTable()
    local dx = self.player.tx - self.casinoInterior.table.tx
    local dy = self.player.ty - self.casinoInterior.table.ty
    return math.sqrt(dx * dx + dy * dy) <= 2.0
end

function DayState:_enterCasino()
    if self:_isInCasino() then
        return
    end

    self.harvest:cancel()
    self.ghost:deactivate()
    self.casinoInterior.returnPlayer = {
        tx = self.player.tx,
        ty = self.player.ty,
        ftx = self.player.ftx,
        fty = self.player.fty,
    }
    self.casinoInterior.active = true
    self.game.tileManager:setTilemapSource("interior.casino")
    self.casinoInterior.chunks = ChunkManager(self.game.tileManager)
    self.player.tx = self.casinoInterior.spawn.tx
    self.player.ty = self.casinoInterior.spawn.ty
    self.player.ftx = 0
    self.player.fty = -1

    local px, py = Iso.tileToScreen(self.player.tx, self.player.ty)
    self.camera:moveTo(px, py)
    self:_showNotice("Entered the casino.")
end

function DayState:_exitCasino()
    if not self:_isInCasino() then
        return
    end

    local returnPlayer = self.casinoInterior.returnPlayer or {
        tx = 0,
        ty = 0,
        ftx = 0,
        fty = 1,
    }

    self.casinoInterior.active = false
    self.casinoInterior.chunks = nil
    self.casinoInterior.returnPlayer = nil
    self.game.tileManager:setProceduralSource(self.worldSeed)
    self.player.tx = returnPlayer.tx
    self.player.ty = returnPlayer.ty
    self.player.ftx = returnPlayer.ftx
    self.player.fty = returnPlayer.fty

    local px, py = Iso.tileToScreen(self.player.tx, self.player.ty)
    self.camera:moveTo(px, py)
    self:_showNotice("Left the casino.")
end

function DayState:enter(selectedClass)
    print("Entered Day State")
    self.game.tileManager:setProceduralSource(self.worldSeed)
    self.game.dayCounter = (self.game.dayCounter or 0) + 1
    self.timeRemaining = self.game.config.dayLength

    self:_setPlayerClass(selectedClass)
    self:_ensureBaseLayout()
    self:_ensureValidSpawn()
    self:_syncPlayerCharacterPosition()
    self.game.world:clear()
    self.game.world:addEntity(self.playerCharacter.entity)

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
    local classChanged  = resolvedClass ~= self.playerClass or not self.playerCharacter

    self.playerClass = resolvedClass
    if classChanged then
        self.playerCharacter = self:createWorldPlayerCharacter(resolvedClass)
        self.inventory = Inventory(resolvedClass)
    end

    self.player.speed = self.playerCharacter.stats:getSpeed()
end

function DayState:exit()
    print("Exited Day State")
    if self:_isInCasino() then
        self.casinoInterior.active = false
        self.casinoInterior.chunks = nil
        self.casinoInterior.returnPlayer = nil
        self.game.tileManager:setProceduralSource(self.worldSeed)
    end
    self.ghost:deactivate()
    self.harvest:cancel()
    self.dash.active = false
    self.abilityDash.active = false
end

function DayState:_updateMovement(dt)
    if self.dash.active then
        self:_updateDash(dt)
        return
    end
    local sdx, sdy = self.game.input:getMoveVector()
    if sdx ~= 0 or sdy ~= 0 then
        local spd    = self.player.speed * dt
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

    if self.ghost:isActive() then
        -- Right stick drives build cursor instead of camera
        self._stickCooldown = self._stickCooldown - dt
        if self._stickCooldown <= 0 and (math.abs(rx) > 0.4 or math.abs(ry) > 0.4) then
            local ctx, cty = screenDirToTile(rx, ry)
            if ctx ~= 0 or cty ~= 0 then
                self.ghost:moveCursor(ctx, cty)
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

function DayState:_updateBuildCursor()
    if self:_isInCasino() or not self.ghost:isActive() then return end
    local mx, my = love.mouse.getPosition()
    if mx ~= self._prevMouse.x or my ~= self._prevMouse.y then
        self._prevMouse.x = mx
        self._prevMouse.y = my
        self.ghost:updateFromMouse(self.camera)
    end
end

function DayState:_updateWorld()
    local activeChunks = self:_getActiveChunks()
    activeChunks:update(self.player.tx, self.player.ty)

    if self:_isInCasino() then
        return
    end

    self.fog:update(self.player.tx, self.player.ty)

    local ptx = math.floor(self.player.tx + 0.5)
    local pty = math.floor(self.player.ty + 0.5)
    local r   = FogOfWar.VISION_RADIUS
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
    if self.dash.cooldown > 0 then
        self.dash.cooldown = math.max(0, self.dash.cooldown - dt)
    end
    if self.playerCharacter and self.playerCharacter.attackTimer and self.playerCharacter.attackTimer > 0 then
        self.playerCharacter.attackTimer = math.max(0, self.playerCharacter.attackTimer - dt)
        if self.playerCharacter.attackTimer == 0 and self.playerCharacter.state == self.playerCharacter.STATE.ATTACKING then
            self.playerCharacter.state = self.playerCharacter.isMoving and self.playerCharacter.STATE.WALKING or self.playerCharacter.STATE.IDLE
        end
    end
    self.timeRemaining = self.timeRemaining - dt
    self.game.timeOfDay = self.timeRemaining

    if self.timeRemaining <= 0 then
        self.game.stateMachine:setState("night")
        return
    end

    if self.abilityDash.active then
        self:_updateAbilityDash(dt)
    else
        self:_updateMovement(dt)
    end
    self:_updateCamera(dt)
    self:_updateBuildCursor()
    self:_updateWorld()

    if not self:_isInCasino() then
        self.harvest:update(dt, self.player.tx, self.player.ty, self.nodes, self.inventory)
        self.respawn:update(dt)
        self.combatManager:update(dt)
        if self.game.world then self.game.world:update(dt) end
    end

    self.playerCharacter:updateVisuals(dt)
    self:_syncPlayerCharacterPosition()
end

function DayState:_ensureValidSpawn()
    local spawnTx, spawnTy = self:_findNearestWalkableTile(self.player.tx, self.player.ty)
    self.player.tx = spawnTx
    self.player.ty = spawnTy
end

function DayState:_isWalkableOutdoorTile(tx, ty)
    local tileType = self.chunks:getTile(tx, ty)
    return tileType and Tile.isWalkable(tileType) or false
end

function DayState:_canPlaceBaseLayout(originTx, originTy)
    local positions = {
        { name = "basecore", offset = BASE_LAYOUT.basecore },
        { name = "depot", offset = BASE_LAYOUT.depot },
        { name = "casino", offset = BASE_LAYOUT.casino },
        { name = "player", offset = BASE_LAYOUT.player },
    }

    for _, entry in ipairs(positions) do
        local footprint = BASE_CLEARANCE[entry.name]
        for dx = footprint.x1, footprint.x2 do
            for dy = footprint.y1, footprint.y2 do
                local tx = originTx + entry.offset.tx + dx
                local ty = originTy + entry.offset.ty + dy
                if not self:_isWalkableOutdoorTile(tx, ty) then
                    return false
                end
            end
        end
    end

    return true
end

function DayState:_findBaseLayoutOrigin(originTx, originTy)
    local startTx = math.floor(originTx + 0.5)
    local startTy = math.floor(originTy + 0.5)

    if self:_canPlaceBaseLayout(startTx, startTy) then
        return startTx, startTy
    end

    for radius = 1, 24 do
        for dx = -radius, radius do
            for dy = -radius, radius do
                if math.abs(dx) == radius or math.abs(dy) == radius then
                    local tx = startTx + dx
                    local ty = startTy + dy
                    if self:_canPlaceBaseLayout(tx, ty) then
                        return tx, ty
                    end
                end
            end
        end
    end

    return startTx, startTy
end

function DayState:_moveBaseCore(tx, ty)
    local baseCore = self.buildings:getBaseCore()
    if baseCore and (baseCore.tx ~= tx or baseCore.ty ~= ty) then
        self.buildings:remove(baseCore.tx, baseCore.ty)
        self.buildings:placeFree("basecore", tx, ty)
    end
end

function DayState:_ensureBaseLayout()
    if self.baseLayoutInitialized then
        return
    end

    local originTx, originTy = self:_findBaseLayoutOrigin(0, 0)
    self:_moveBaseCore(originTx + BASE_LAYOUT.basecore.tx, originTy + BASE_LAYOUT.basecore.ty)
    self.depot.tx = originTx + BASE_LAYOUT.depot.tx
    self.depot.ty = originTy + BASE_LAYOUT.depot.ty
    self.casino.tx = originTx + BASE_LAYOUT.casino.tx
    self.casino.ty = originTy + BASE_LAYOUT.casino.ty
    self.player.tx = originTx + BASE_LAYOUT.player.tx
    self.player.ty = originTy + BASE_LAYOUT.player.ty
    self.player.ftx = 0
    self.player.fty = -1
    self.baseLayoutInitialized = true
end

function DayState:_findNearestWalkableTile(originTx, originTy)
    local startTx = math.floor(originTx + 0.5)
    local startTy = math.floor(originTy + 0.5)

    if self:_canMoveTo(startTx, startTy) then return startTx, startTy end

    for radius = 1, 12 do
        for dx = -radius, radius do
            for dy = -radius, radius do
                if math.abs(dx) == radius or math.abs(dy) == radius then
                    local tx = startTx + dx
                    local ty = startTy + dy
                    if self:_canMoveTo(tx, ty) then return tx, ty end
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

        if not self:_isInCasino() then
            local building = self.buildings:getAt(tileX, tileY)
            if building and building.def and building.def.blocksMovement then
                return false
            end
        end

        local tileType = self:_getActiveChunks():getTile(tileX, tileY)
        local localX   = point[1] - tileX
        local localY   = point[2] - tileY
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

    if self:_canMoveTo(targetTx, self.player.ty) then self.player.tx = targetTx end
    if self:_canMoveTo(self.player.tx, targetTy) then self.player.ty = targetTy end
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

    local propLeft   = osx - iw * 0.5
    local propRight  = osx + iw * 0.5
    local propTop    = osy + Iso.TILE_H * 0.5 - ih
    local propBottom = osy + Iso.TILE_H * 0.5

    local playerWidth  = 28
    local playerTop    = psy - 42
    local playerBottom = psy + 18

    local overH = (psx + playerWidth * 0.5) > propLeft and (psx - playerWidth * 0.5) < propRight
    local overV = playerBottom > propTop and playerTop < propBottom

    if overH and overV and psy < propBottom then return 0.5 end
    return 1
end

function DayState:_ghostTile()
    local ptx = math.floor(self.player.tx + 0.5)
    local pty = math.floor(self.player.ty + 0.5)
    return ptx + self.player.ftx, pty + self.player.fty
end

function DayState:_syncPlayerCharacterPosition()
    local psx, psy = Iso.tileToScreen(self.player.tx, self.player.ty)
    self.playerCharacter.position.x = psx
    self.playerCharacter.position.y = psy + 2
end

function DayState:_startDash()
    if self.dash.active then return end
    if self.abilityDash.active then return end
    if self.dash.cooldown > 0 then return end
    local dx = self.player.ftx
    local dy = self.player.fty
    if dx == 0 and dy == 0 then return end
    self.dash.active = true
    self.dash.remaining = 1.0  -- tiles
    self.dash.dirX = dx
    self.dash.dirY = dy
    self.dash.cooldown = self.dash.cooldownTime
end

function DayState:_updateDash(dt)
    local step = math.min(self.dash.remaining, self.dash.speed * dt)
    if step <= 0 then
        self.dash.active = false
        return
    end

    local movedX = self.dash.dirX * step
    local movedY = self.dash.dirY * step
    local beforeTx = self.player.tx
    local beforeTy = self.player.ty
    self:_movePlayer(movedX, movedY)

    if self.player.tx == beforeTx and self.player.ty == beforeTy then
        self.dash.active = false
        return
    end

    self.dash.remaining = self.dash.remaining - step
    if self.dash.remaining <= 0 then
        self.dash.active = false
    end
end

function DayState:_startAbilityDash()
    if self.abilityDash.active then return end
    if self.dash.active then return end
    local dx = self.player.ftx
    local dy = self.player.fty
    if dx == 0 and dy == 0 then return end
    self.abilityDash.active = true
    self.abilityDash.remaining = self.abilityDash.duration
    self.abilityDash.dirX = dx
    self.abilityDash.dirY = dy
end

function DayState:_updateAbilityDash(dt)
    local stepTime = math.min(self.abilityDash.remaining, dt)
    if stepTime <= 0 then
        self.abilityDash.active = false
        return
    end

    local step = self.abilityDash.speed * stepTime
    local dtx = self.abilityDash.dirX * step
    local dty = self.abilityDash.dirY * step
    local beforeTx = self.player.tx
    local beforeTy = self.player.ty
    self:_movePlayer(dtx, dty)

    if self.player.tx == beforeTx and self.player.ty == beforeTy then
        self.abilityDash.active = false
        return
    end

    self.abilityDash.remaining = self.abilityDash.remaining - stepTime
    if self.abilityDash.remaining <= 0 then
        self.abilityDash.active = false
    end
end

function DayState:_attackPlayer(damageMultiplier, rangeMultiplier, cooldown)
    if not self.combatManager:canAttack(self.playerCharacter.entity) then
        return false
    end

    local stats = self.playerCharacter.stats
    if not stats:canAttack() then
        return false
    end

    local facingDir = self.playerCharacter.facingDirection
    local range = stats:getAttackRange() * (rangeMultiplier or 1.0)
    local offsetX = math.cos(facingDir) * range / 2
    local offsetY = math.sin(facingDir) * range / 2

    local attackId = self.combatManager:registerAttack(self.playerCharacter.entity, {
        range = range,
        damage = stats:getAttack() * (damageMultiplier or 1.0),
        cooldown = cooldown or (1.0 / stats:getAttackSpeed()),
        hitboxOffset = {x = offsetX, y = offsetY},
        hitboxSize = {width = range, height = range / 2},
        duration = 0.3,
        knockback = 50,
        hitLimit = 10
    })

    if attackId then
        self.playerCharacter:triggerAttackAnimation()
    end
    return attackId ~= nil
end

function DayState:_useAbility()
    local classType = self.playerCharacter.classType

    if classType == Constants.CLASS.WARRIOR then
        local ok = self:_attackPlayer(1.6, 1.8, 2.0)
        if ok then
            self:_startAbilityDash()
        end
    elseif classType == Constants.CLASS.ARCHER then
        self:_attackPlayer(1.3, 1.4, 2.0)
    elseif classType == Constants.CLASS.SCOUT then
        if self.playerCharacter.health then
            self.playerCharacter.health:setInvulnerable(1.5)
        end
    elseif classType == Constants.CLASS.ENGINEER then
        self.playerCharacter:heal(20)
    else
        self.playerCharacter:useAbility()
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
    return math.floor(txMin) - m, math.floor(tyMin) - m,
           math.ceil(txMax)  + m, math.ceil(tyMax)  + m
end

-- Builds the sorted list of explored tiles to draw this frame.
function DayState:_buildDrawList(x1, y1, x2, y2)
    local list = {}
    local activeChunks = self:_getActiveChunks()

    if self:_isInCasino() then
        for tx = x1, x2 do
            for ty = y1, y2 do
                local tileType = activeChunks:getTile(tx, ty)
                if tileType then
                    local _, sy = Iso.tileToScreen(tx, ty)
                    list[#list + 1] = { sy = sy, tx = tx, ty = ty, t = tileType, visible = true }
                end
            end
        end
        table.sort(list, function(a, b) return a.sy < b.sy end)
        return list
    end

    for tx = x1, x2 do
        for ty = y1, y2 do
            local state = self.fog:getState(tx, ty)
            if state ~= "hidden" then
                local tileType = state == "visible"
                    and activeChunks:getTile(tx, ty)
                    or  self.fog:getCachedType(tx, ty)
                if tileType then
                    local _, sy = Iso.tileToScreen(tx, ty)
                    list[#list + 1] = { sy = sy, tx = tx, ty = ty, t = tileType, visible = (state == "visible") }
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
            entry.tx, entry.ty,
            tint[1] * dim, tint[2] * dim, tint[3] * dim, 1)
        return
    end

    local color = Tile.getColor(entry.t)
    Iso.drawTile(entry.tx, entry.ty, color[1] * dim, color[2] * dim, color[3] * dim, 1)
end

function DayState:_queueTileOverlay(entry, renderData, dim, entityDrawList)
    if not renderData or not renderData.overlay then return end

    local overlay = renderData.overlay
    local tint = overlay.tint
    local opacity = self:_getPropOpacity(overlay.image, entry.tx, entry.ty, overlay.quad)
    entityDrawList[#entityDrawList + 1] = {
        sy    = entry.sy + Iso.TILE_H,
        order = 10,
        draw  = function()
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

function DayState:_drawVisibleTileOutline(_entry)
    -- Tile grid outline disabled — too prominent at full map visibility.
end

function DayState:_drawTerrain(drawList, worldTime, entityDrawList)
    for _, entry in ipairs(drawList) do
        local dim        = entry.visible and 1 or 0.5
        local renderData = Tile.getRenderData(entry.t, entry.tx, entry.ty, worldTime)
        self:_drawTileGround(entry, renderData, dim)
        self:_queueTileOverlay(entry, renderData, dim, entityDrawList)
        self:_drawVisibleTileOutline(entry)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function DayState:_queueVisibleBuildingDraws(entityDrawList)
    if self:_isInCasino() then
        return
    end

    for _, building in ipairs(self.buildings:getAll()) do
        if self.fog:getState(building.tx, building.ty) ~= "hidden" then
            entityDrawList[#entityDrawList + 1] = {
                sy    = building:screenY(),
                order = 20,
                draw  = function() building:draw() end
            }
        end
    end
end

function DayState:_shouldDrawNode(node, x1, y1, x2, y2)
    if self:_isInCasino() then
        return false
    end

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
                sy    = sy,
                order = 30,
                draw  = function() node:draw() end
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

function DayState:_drawCasino()
    if self:_isInCasino() then
        return
    end

    self.casino:draw()
    if self.casino:isNearby(self.player.tx, self.player.ty) then
        local sx, sy = Iso.tileToScreen(self.casino.tx, self.casino.ty)
        local alpha = 0.5 + 0.5 * math.sin(love.timer.getTime() * 3)
        love.graphics.setColor(0.96, 0.80, 0.22, alpha)
        love.graphics.circle("line", sx, sy + 16, 36)
        love.graphics.setColor(1, 0.98, 0.90, alpha)
        love.graphics.setFont(love.graphics.newFont(11))
        love.graphics.print("G: Enter Casino", sx - 38, sy + 36)
    end
end

function DayState:_drawCasinoTable()
    local tx = self.casinoInterior.table.tx
    local ty = self.casinoInterior.table.ty
    local sx, sy = Iso.tileToScreen(tx, ty)
    local alpha = 0.55 + 0.35 * math.sin(love.timer.getTime() * 3.5)

    love.graphics.setColor(0.86, 0.12, 0.12, 0.80)
    love.graphics.polygon("fill",
        sx, sy + 4,
        sx + 22, sy + 16,
        sx, sy + 28,
        sx - 22, sy + 16)
    love.graphics.setColor(0.95, 0.80, 0.22, 0.95)
    love.graphics.polygon("line",
        sx, sy + 4,
        sx + 22, sy + 16,
        sx, sy + 28,
        sx - 22, sy + 16)

    if self:_isNearCasinoTable() then
        love.graphics.setColor(0.95, 0.80, 0.22, alpha)
        love.graphics.circle("line", sx, sy + 16, 34)
        love.graphics.setColor(1, 0.98, 0.90, alpha)
        love.graphics.setFont(love.graphics.newFont(11))
        love.graphics.print("G: Gamble  |  ESC: Leave", sx - 58, sy + 38)
    end
end

function DayState:_queueDepotDraw(entityDrawList)
    if self:_isInCasino() then return end
    if self.fog:getState(self.depot.tx, self.depot.ty) == "hidden" then return end
    local _, depotSy = Iso.tileToScreen(self.depot.tx, self.depot.ty)
    entityDrawList[#entityDrawList + 1] = {
        sy    = depotSy,
        order = 40,
        draw  = function() self:_drawDepot() end
    }
end

function DayState:_queueCasinoDraw(entityDrawList)
    if self:_isInCasino() then return end
    if self.fog:getState(self.casino.tx, self.casino.ty) == "hidden" then return end
    local _, casinoSy = Iso.tileToScreen(self.casino.tx, self.casino.ty)
    entityDrawList[#entityDrawList + 1] = {
        sy    = casinoSy,
        order = 41,
        draw  = function() self:_drawCasino() end
    }
end

function DayState:_queueCasinoTableDraw(entityDrawList)
    if not self:_isInCasino() then
        return
    end

    local _, sy = Iso.tileToScreen(self.casinoInterior.table.tx, self.casinoInterior.table.ty)
    entityDrawList[#entityDrawList + 1] = {
        sy = sy,
        order = 45,
        draw = function() self:_drawCasinoTable() end
    }
end

function DayState:_queuePlayerDraw(entityDrawList)
    local psx, psy = Iso.tileToScreen(self.player.tx, self.player.ty)
    self.playerCharacter.position.x = psx
    self.playerCharacter.position.y = psy + 2
    entityDrawList[#entityDrawList + 1] = {
        sy    = psy + 18,
        order = 50,
        draw  = function() self.playerCharacter:draw() end
    }
end

function DayState:_sortAndDrawEntities(entityDrawList)
    table.sort(entityDrawList, compareEntityDrawEntries)
    for _, entry in ipairs(entityDrawList) do entry.draw() end
end

function DayState:draw()
    love.graphics.clear(0.50, 0.70, 0.90, 1)

    self.camera:apply()

    local x1, y1, x2, y2 = self:_visibleTileRect()
    local drawList        = self:_buildDrawList(x1, y1, x2, y2)
    local worldTime       = love.timer.getTime()
    local entityDrawList  = {}

    self:_drawTerrain(drawList, worldTime, entityDrawList)
    self:_queueVisibleBuildingDraws(entityDrawList)
    self:_queueVisibleNodeDraws(entityDrawList, x1, y1, x2, y2)
    self:_queueDepotDraw(entityDrawList)
    self:_queueCasinoDraw(entityDrawList)
    self:_queueCasinoTableDraw(entityDrawList)
    self:_queuePlayerDraw(entityDrawList)
    self:_sortAndDrawEntities(entityDrawList)

    if not self:_isInCasino() then
        if not self.ghost:isActive() and not self.inventory:isFull() then
            self.harvest:drawHint(self.player.tx, self.player.ty, self.nodes, self.fog)
        end
        self.harvest:draw()
        self.ghost:draw(self.buildings, self.depot, self.inventory)
    end

    if self.debugMode then self:drawDebugWorld(drawList) end

    self.camera:clear()

    self.hud:draw(self.game, self.inventory, self.depot, self.player, self.ghost, {
        inCasino = self:_isInCasino(),
    })
    if self:_isInCasino() then
        self:_drawCasinoOverlay()
    end
    self:_drawNotice()

    if self.debugMode then self:drawDebugUI() end

    love.graphics.setColor(1, 1, 1, 1)
end

function DayState:_drawDebugTile(e)
    local def = Tile.get(e.t)
    if def and def.collision and def.collision.shape == "circle" then
        local ox = def.collision.offsetX or 0
        local oy = def.collision.offsetY or 0
        local sx, sy = Iso.tileToScreen(e.tx + ox, e.ty + oy)
        love.graphics.setColor(1, 0.45, 0.15, 0.8)
        love.graphics.circle("line", sx, sy + Iso.TILE_H * 0.5, def.collision.radius * Iso.TILE_W)
        return true
    elseif def and def.collision and def.collision.shape == "box" then
        local ox = def.collision.offsetX or 0
        local oy = def.collision.offsetY or 0
        local w  = (def.collision.width  or 0.25) * Iso.TILE_W
        local h  = (def.collision.height or 0.25) * Iso.TILE_H * 2
        local sx, sy = Iso.tileToScreen(e.tx + ox, e.ty + oy)
        love.graphics.setColor(1, 0.45, 0.15, 0.8)
        love.graphics.rectangle("line", sx - w * 0.5, sy + Iso.TILE_H * 0.5 - h * 0.5, w, h)
        return true
    elseif e.t == "water" then
        local sx, sy = Iso.tileToScreen(e.tx, e.ty)
        love.graphics.setColor(0.15, 0.7, 1, 0.45)
        love.graphics.polygon("line",
            sx, sy,
            sx + Iso.TILE_W * 0.5, sy + Iso.TILE_H * 0.5,
            sx, sy + Iso.TILE_H,
            sx - Iso.TILE_W * 0.5, sy + Iso.TILE_H * 0.5)
    end
    return false
end

function DayState:drawDebugWorld(drawList)
    local visibleColliderCount = 0

    for _, e in ipairs(drawList) do
        if e.visible and self:_drawDebugTile(e) then
            visibleColliderCount = visibleColliderCount + 1
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

function DayState:drawDebugUI()
    local px, py     = Iso.tileToScreen(self.player.tx, self.player.ty)
    local tileType   = self:_getActiveChunks():getTile(
        math.floor(self.player.tx + 0.5), math.floor(self.player.ty + 0.5))
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

    local panelX     = love.graphics.getWidth() - 250
    local panelY     = 20
    local lineHeight = 18
    local panelH     = 16 + #lines * lineHeight

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
    for _ in pairs(self:_getActiveChunks()._chunks) do count = count + 1 end
    return count
end

function DayState:_showNotice(text)
    self.notice.text = text
    self.notice.alpha = 0
    self.notice.y = 36
    self.game.tweens:stop(self.notice)
    self.game.tweens:to(self.notice, 0.18, { alpha = 1, y = 52 }):ease("quadout"):oncomplete(function()
        self.game.tweens:to(self.notice, 0.35, { alpha = 0, y = 58 }):delay(1.0)
    end)
end

function DayState:_drawNotice()
    if self.notice.alpha <= 0.01 or self.notice.text == "" then
        return
    end

    love.graphics.setFont(self.smallFont)
    love.graphics.setColor(0, 0, 0, 0.70 * self.notice.alpha)
    love.graphics.rectangle("fill", love.graphics.getWidth() * 0.5 - 220, self.notice.y - 8, 440, 38, 8, 8)
    love.graphics.setColor(1, 0.97, 0.88, self.notice.alpha)
    love.graphics.printf(self.notice.text, 0, self.notice.y, love.graphics.getWidth(), "center")
end

function DayState:_drawCasinoOverlay()
    love.graphics.setFont(self.smallFont)
    love.graphics.setColor(0, 0, 0, 0.72)
    love.graphics.rectangle("fill", 16, 56, 310, 64, 10, 10)
    love.graphics.setColor(0.95, 0.80, 0.22, 1)
    love.graphics.print("CASINO FLOOR", 28, 68)
    love.graphics.setColor(1, 0.97, 0.88, 0.95)
    love.graphics.print("Reach the table and press G to gamble.", 28, 88)
    love.graphics.print("Press ESC to leave the building.", 28, 104)
end

function DayState:_keypressedBuild(key)
    if self:_isInCasino() then
        return
    end

    if key == "b" then
        if self.ghost:isActive() then self.ghost:cycleType()
        else self.ghost:activate(self.player.tx, self.player.ty) end
    elseif key == "r" and self.ghost:isActive() then
        local tx, ty = self.ghost:cursorTile()
        self.buildings:place(self.ghost:currentType(), tx, ty, self.depot, self.inventory)
    elseif ARROW_CURSOR[key] and self.ghost:isActive() then
        local d = ARROW_CURSOR[key]
        self.ghost:moveCursor(d[1], d[2])
    end
end

function DayState:_keypressedAction(key)
    if self:_isInCasino() then
        if key == "g" and self:_isNearCasinoTable() then
            local _, message = self.casino:gambleInventory(self.inventory, self.depot)
            self:_showNotice(message)
        end
        return
    end

    if key == "space" then
        if not self.ghost:isActive() then self:_attackPlayer(1.0, 1.0) end
    elseif key == "q" then
        if not self.ghost:isActive() then self:_useAbility() end
    elseif key == "lshift" or key == "rshift" then
        self:_startDash()
    elseif key == "e" then
        if not self.ghost:isActive() then
            self.harvest:tryStart(self.player.tx, self.player.ty, self.nodes, self.inventory)
        end
    elseif key == "f" then
        if self.depot:isNearby(self.player.tx, self.player.ty) then
            self.depot:depositAll(self.inventory)
        end
    elseif key == "g" then
        if self.casino:isNearby(self.player.tx, self.player.ty) then
            self:_enterCasino()
        end
    end
end

function DayState:keypressed(key, scancode, isrepeat)
    if isrepeat then return end
    if key == "escape" then
        if self:_isInCasino() then self:_exitCasino()
        elseif self.ghost:isActive() then self.ghost:deactivate()
        else self.game.stateMachine:setState("menu") end
    elseif key == "f3" then
        self.debugMode = not self.debugMode
    else
        self:_keypressedBuild(key)
        self:_keypressedAction(key)
    end
end

function DayState:gamepadPressed(joystick, button)
    if self:_isInCasino() then
        if button == "b" then
            self:_exitCasino()
        elseif button == "a" and self:_isNearCasinoTable() then
            local _, message = self.casino:gambleInventory(self.inventory, self.depot)
            self:_showNotice(message)
        end
        return
    end

    if button == "b" then
        if self.ghost:isActive() then
            self.ghost:deactivate()
        else
            self.game.stateMachine:setState("menu")
        end
    elseif button == "rightshoulder" then
        if self.ghost:isActive() then
            self.ghost:cycleType()
        else
            self.ghost:activate(self.player.tx, self.player.ty)
        end
    elseif button == "a" then
        if self.ghost:isActive() then
            local tx, ty = self.ghost:cursorTile()
            self.buildings:place(self.ghost:currentType(), tx, ty, self.depot, self.inventory)
        else
            self:_attackPlayer(1.0, 1.0)
        end
    elseif button == "y" then
        if not self.ghost:isActive() then
            self:_useAbility()
        end
    elseif button == "x" then
        if not self.ghost:isActive() then
            self.harvest:tryStart(self.player.tx, self.player.ty, self.nodes, self.inventory)
        end
    elseif button == "square" or button == "leftshoulder" then
        if self.depot:isNearby(self.player.tx, self.player.ty) then
            self.depot:depositAll(self.inventory)
        elseif self.casino:isNearby(self.player.tx, self.player.ty) then
            self:_enterCasino()
        end
    end
end

function DayState:wheelmoved(x, y)
    self.camera:adjustZoom(y * 0.1)
end

return DayState
