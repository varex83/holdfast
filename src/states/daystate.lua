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
local PawnShop       = require("src.world.pawnshop")
local BuildManager   = require("src.buildings.buildmanager")
local BuildGhost     = require("src.buildings.buildghost")
local HUD            = require("src.ui.hud")
local Constants      = require("data.constants")
local CombatManager  = require("src.combat.combatmanager")

local DayState = Class:extend()
local SLOT_SYMBOLS = Casino.SLOT_SYMBOLS or { "CHERRY", "BELL", "STAR", "7" }
local SLOT_PAYTABLE = Casino.SLOT_PAYTABLE or {}
local SLOT_SYMBOL_INDEX = {}

for index, symbol in ipairs(SLOT_SYMBOLS) do
    SLOT_SYMBOL_INDEX[symbol] = index
end

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
    pawnshop = { tx = 0, ty = -4 },
    player = { tx = 0, ty = 4 },
}
local BASE_CLEARANCE = {
    basecore = { x1 = -1, y1 = -1, x2 = 1, y2 = 1 },
    depot = { x1 = -1, y1 = -1, x2 = 1, y2 = 1 },
    casino = { x1 = -2, y1 = -1, x2 = 2, y2 = 2 },
    pawnshop = { x1 = -1, y1 = -1, x2 = 1, y2 = 1 },
    player = { x1 = -1, y1 = -1, x2 = 1, y2 = 1 },
}

local function screenDirToTile(sx, sy)
    local hw, hh = 32, 16
    local dtx = sx / hw + sy / hh
    local dty = sy / hh - sx / hw
    return dtx > 0 and 1 or (dtx < 0 and -1 or 0),
           dty > 0 and 1 or (dty < 0 and -1 or 0)
end

local function clamp(value, minValue, maxValue)
    return math.max(minValue, math.min(maxValue, value))
end

local function easeOutCubic(t)
    return 1 - (1 - t) ^ 3
end

local function copyArray(values)
    local copy = {}
    for i = 1, #values do
        copy[i] = values[i]
    end
    return copy
end

local function getSlotSymbolAt(position)
    local symbolCount = #SLOT_SYMBOLS
    local wrapped = ((math.floor(position) % symbolCount) + symbolCount) % symbolCount
    return SLOT_SYMBOLS[wrapped + 1]
end

local function drawStarShape(cx, cy, outerRadius, innerRadius, alpha)
    local points = {}
    for i = 0, 9 do
        local angle = -math.pi * 0.5 + i * math.pi / 5
        local radius = i % 2 == 0 and outerRadius or innerRadius
        points[#points + 1] = cx + math.cos(angle) * radius
        points[#points + 1] = cy + math.sin(angle) * radius
    end

    love.graphics.setColor(0.98, 0.82, 0.16, alpha)
    love.graphics.polygon("fill", points)
    love.graphics.setColor(0.76, 0.56, 0.10, alpha)
    love.graphics.polygon("line", points)
end

local function drawSlotSymbol(symbol, cx, cy, size, alpha, font)
    if symbol == "CHERRY" then
        local radius = size * 0.20
        local stemY = cy - size * 0.25
        love.graphics.setLineWidth(math.max(1, size * 0.06))
        love.graphics.setColor(0.24, 0.52, 0.14, alpha)
        love.graphics.line(cx - radius * 0.2, stemY, cx - radius * 1.1, stemY - size * 0.18)
        love.graphics.line(cx + radius * 0.2, stemY, cx + radius * 0.9, stemY - size * 0.18)
        love.graphics.setColor(0.86, 0.10, 0.16, alpha)
        love.graphics.circle("fill", cx - radius * 0.95, cy + size * 0.05, radius)
        love.graphics.circle("fill", cx + radius * 0.95, cy + size * 0.05, radius)
        love.graphics.setColor(1, 0.78, 0.82, alpha * 0.45)
        love.graphics.circle("fill", cx - radius * 1.2, cy - size * 0.02, radius * 0.28)
        love.graphics.circle("fill", cx + radius * 0.7, cy - size * 0.02, radius * 0.28)
        return
    end

    if symbol == "BELL" then
        local bellW = size * 0.55
        local bellH = size * 0.52
        love.graphics.setColor(0.97, 0.78, 0.18, alpha)
        love.graphics.arc("fill", "open", cx, cy + size * 0.02, bellW * 0.5, math.pi, math.pi * 2, 24)
        love.graphics.rectangle("fill", cx - bellW * 0.48, cy, bellW * 0.96, bellH * 0.32, bellW * 0.10, bellW * 0.10)
        love.graphics.setColor(0.83, 0.61, 0.10, alpha)
        love.graphics.arc("line", "open", cx, cy + size * 0.02, bellW * 0.5, math.pi, math.pi * 2, 24)
        love.graphics.line(cx - bellW * 0.5, cy + bellH * 0.18, cx + bellW * 0.5, cy + bellH * 0.18)
        love.graphics.setColor(0.63, 0.42, 0.08, alpha)
        love.graphics.circle("fill", cx, cy + bellH * 0.28, size * 0.07)
        return
    end

    if symbol == "STAR" then
        drawStarShape(cx, cy, size * 0.28, size * 0.12, alpha)
        return
    end

    if symbol == "*" then
        drawStarShape(cx, cy, size * 0.22, size * 0.10, alpha)
        return
    end

    love.graphics.setFont(font)
    love.graphics.setColor(0.84, 0.08, 0.12, alpha)
    love.graphics.printf("7", cx - size * 0.25, cy - size * 0.36, size * 0.5, "center")
end

local function slotGlyph(symbol)
    if symbol == "CHERRY" then return "C" end
    if symbol == "BELL" then return "B" end
    if symbol == "STAR" then return "*" end
    if symbol == "*" then return "*" end
    return "7"
end

function DayState:new(game)
    self.game          = game
    self.font          = love.graphics.newFont(24)
    self.smallFont     = love.graphics.newFont(14)
    self.slotTitleFont = love.graphics.newFont(18)
    self.slotFont      = love.graphics.newFont(26)
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
    self.pawnShop = PawnShop(0, -2)
    self.casinoInterior = {
        active = false,
        chunks = nil,
        spawn = { tx = 5, ty = 7 },
        slotMachine = { tx = 5, ty = 3 },
        slotUIActive = false,
        stakeAmount = 0,
        slotSpin = {
            active = false,
            elapsed = 0,
            duration = 2.65,
            reels = { "CHERRY", "CHERRY", "CHERRY" },
            displayReels = { "CHERRY", "CHERRY", "CHERRY" },
            reelStates = nil,
            reelStartTimes = { 0.00, 0.10, 0.22 },
            reelStopTimes = { 1.75, 2.15, 2.65 },
            pending = nil,
        },
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

function DayState:_isWithinActiveMap(tx, ty)
    return self.game.tileManager:isWithinActiveTilemap(tx, ty)
end

function DayState:_isNearSlotMachine()
    local dx = self.player.tx - self.casinoInterior.slotMachine.tx
    local dy = self.player.ty - self.casinoInterior.slotMachine.ty
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
    self.casinoInterior.slotUIActive = false
    self.casinoInterior.slotSpin.active = false
    self.casinoInterior.slotSpin.pending = nil
    self.casinoInterior.slotSpin.reelStates = nil
    self.casinoInterior.stakeAmount = 0
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
        self.casinoInterior.slotUIActive = false
        self.casinoInterior.slotSpin.active = false
        self.casinoInterior.slotSpin.pending = nil
        self.casinoInterior.stakeAmount = 0
        self.game.tileManager:setProceduralSource(self.worldSeed)
    end
    self.ghost:deactivate()
    self.harvest:cancel()
    self.dash.active = false
    self.abilityDash.active = false
end

function DayState:_updateMovement(dt)
    if self:_isInCasino() and self.casinoInterior.slotUIActive then
        self.playerCharacter:setDesiredMovement(0, 0)
        self.playerCharacter:updateState()
        return
    end

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
    self:_updateCasinoSpin(dt)

    if not self:_isInCasino() then
        self.harvest:update(dt, self.player.tx, self.player.ty, self.nodes, self.inventory)
        self.respawn:update(dt)
        self.combatManager:update(dt)
        if self.game.world then self.game.world:update(dt) end
    end

    self.playerCharacter:updateVisuals(dt)
    self:_syncPlayerCharacterPosition()
end

function DayState:_startSlotSpin()
    local stakeItems, totalIn = self:_buildSlotStake()
    if totalIn <= 0 then
        self:_showNotice("Bring more gold for that stake.", 2.8)
        return
    end

    for resourceType, amount in pairs(stakeItems) do
        self.inventory:remove(resourceType, amount)
    end

    local ok, result = self.casino:beginSlotSpin(stakeItems)
    if not ok then
        for resourceType, amount in pairs(stakeItems) do
            self.inventory:forceAdd(resourceType, amount)
        end
        self:_showNotice(result, 2.8)
        return
    end

    local spin = self.casinoInterior.slotSpin
    spin.active = true
    spin.elapsed = 0
    spin.pending = result
    spin.duration = spin.reelStopTimes[#spin.reelStopTimes]

    local startReels = copyArray(spin.reels)
    spin.displayReels = copyArray(startReels)
    spin.reelStates = {}

    for i = 1, 3 do
        local startIndex = SLOT_SYMBOL_INDEX[startReels[i]] or 1
        local resultIndex = SLOT_SYMBOL_INDEX[result.reels[i]] or 1
        local extraLoops = 15 + (i - 1) * 4
        local targetPosition = startIndex + extraLoops * #SLOT_SYMBOLS + ((resultIndex - startIndex) % #SLOT_SYMBOLS)

        spin.reelStates[i] = {
            startPosition = startIndex - 1,
            position = startIndex - 1,
            targetPosition = targetPosition - 1,
        }
    end
end

function DayState:_openSlotMachineUI()
    self.casinoInterior.slotUIActive = true
    self:_normalizeSlotStake(true)
end

function DayState:_closeSlotMachineUI()
    if self.casinoInterior.slotSpin.active then
        return
    end

    self.casinoInterior.slotUIActive = false
end

function DayState:_formatSlotStake()
    local _, totalIn = self:_buildSlotStake()
    local totalGold = self.inventory:count("gold")

    return string.format("%d gold selected  |  %d available", totalIn, totalGold)
end

function DayState:_buildSlotStake()
    local totalIn = self:_normalizeSlotStake(false)

    return { gold = totalIn }, totalIn
end

function DayState:_normalizeSlotStake(resetIfEmpty)
    local goldAmount = self.inventory:count("gold")
    if goldAmount <= 0 then
        self.casinoInterior.stakeAmount = 0
        return 0
    end

    if resetIfEmpty and self.casinoInterior.stakeAmount <= 0 then
        self.casinoInterior.stakeAmount = 1
    end

    self.casinoInterior.stakeAmount = math.max(1, math.min(self.casinoInterior.stakeAmount, goldAmount))
    return self.casinoInterior.stakeAmount
end

function DayState:_changeSlotStake(direction)
    if self.casinoInterior.slotSpin.active then
        return
    end

    local currentStake = self:_normalizeSlotStake(true)
    if currentStake <= 0 then
        return
    end

    local nextStake = currentStake + direction
    self.casinoInterior.stakeAmount = nextStake
    self:_normalizeSlotStake(false)
end

function DayState:_currentStakeLabel()
    return tostring(self:_normalizeSlotStake(false)) .. "g"
end

function DayState:_updateCasinoSpin(dt)
    if not self:_isInCasino() then
        return
    end

    local spin = self.casinoInterior.slotSpin
    if self.casinoInterior.slotUIActive and not spin.active and not self:_isNearSlotMachine() then
        self:_closeSlotMachineUI()
        return
    end

    if not spin.active then
        return
    end

    spin.elapsed = spin.elapsed + dt

    for i = 1, 3 do
        local reelState = spin.reelStates and spin.reelStates[i]
        if reelState then
            local startTime = spin.reelStartTimes[i] or 0
            local stopTime = spin.reelStopTimes[i] or spin.duration

            if spin.elapsed <= startTime then
                reelState.position = reelState.startPosition
            elseif spin.elapsed >= stopTime then
                reelState.position = reelState.targetPosition
            else
                local progress = clamp((spin.elapsed - startTime) / (stopTime - startTime), 0, 1)
                local travel = easeOutCubic(progress ^ 0.72)
                reelState.position = reelState.startPosition + (reelState.targetPosition - reelState.startPosition) * travel
            end

            spin.displayReels[i] = getSlotSymbolAt(reelState.position + 0.5)
        end
    end

    if spin.elapsed >= spin.duration then
        spin.active = false
        spin.reels = copyArray(spin.pending.reels)
        spin.displayReels = copyArray(spin.pending.reels)
        spin.reelStates = nil
        local _, message = self.casino:resolveSlotSpin(spin.pending, self.inventory)
        spin.pending = nil
        self:_showNotice(message, 4.2)
    end
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
        { name = "pawnshop", offset = BASE_LAYOUT.pawnshop },
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
    self.pawnShop.tx = originTx + BASE_LAYOUT.pawnshop.tx
    self.pawnShop.ty = originTy + BASE_LAYOUT.pawnshop.ty
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

        if self:_isInCasino() and not self:_isWithinActiveMap(tileX, tileY) then
            return false
        end

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
                if self:_isWithinActiveMap(tx, ty) then
                    local tileType = activeChunks:getTile(tx, ty)
                    if tileType then
                        local _, sy = Iso.tileToScreen(tx, ty)
                        list[#list + 1] = { sy = sy, tx = tx, ty = ty, t = tileType, visible = true }
                    end
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

function DayState:_drawPawnShop()
    if self:_isInCasino() then
        return
    end

    self.pawnShop:draw()
    if self.pawnShop:isNearby(self.player.tx, self.player.ty) then
        self.pawnShop:drawNearbyHint()
    end
end

function DayState:_drawSlotMachine()
    local tx = self.casinoInterior.slotMachine.tx
    local ty = self.casinoInterior.slotMachine.ty
    local sx, sy = Iso.tileToScreen(tx, ty)
    local alpha = 0.55 + 0.35 * math.sin(love.timer.getTime() * 3.5)
    local spin = self.casinoInterior.slotSpin

    love.graphics.setColor(0.70, 0.12, 0.12, 0.88)
    love.graphics.rectangle("fill", sx - 18, sy - 10, 36, 40, 6, 6)
    love.graphics.setColor(0.95, 0.80, 0.22, 0.95)
    love.graphics.rectangle("line", sx - 18, sy - 10, 36, 40, 6, 6)
    love.graphics.setColor(0.12, 0.12, 0.12, 1)
    love.graphics.rectangle("fill", sx - 12, sy - 4, 24, 12, 4, 4)
    love.graphics.setColor(1, 0.95, 0.65, 1)
    love.graphics.rectangle("line", sx - 12, sy - 4, 24, 12, 4, 4)
    love.graphics.setFont(love.graphics.newFont(8))
    love.graphics.setColor(0.96, 0.94, 0.86, 1)
    love.graphics.printf(slotGlyph(spin.displayReels[1]) .. " " .. slotGlyph(spin.displayReels[2]) .. " " .. slotGlyph(spin.displayReels[3]), sx - 12, sy - 2, 24, "center")

    if spin.active then
        love.graphics.setColor(0.95, 0.80, 0.22, alpha)
        love.graphics.circle("line", sx, sy + 16, 34)
        love.graphics.setColor(1, 0.98, 0.90, alpha)
        love.graphics.setFont(love.graphics.newFont(11))
        love.graphics.print("Spinning...", sx - 28, sy + 38)
    elseif self:_isNearSlotMachine() then
        love.graphics.setColor(0.95, 0.80, 0.22, alpha)
        love.graphics.circle("line", sx, sy + 16, 34)
        love.graphics.setColor(1, 0.98, 0.90, alpha)
        love.graphics.setFont(love.graphics.newFont(11))
        if self.casinoInterior.slotUIActive then
            love.graphics.print("G: Spin Slots  |  ESC: Close", sx - 62, sy + 38)
        else
            love.graphics.print("G: Use Slots", sx - 28, sy + 38)
        end
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

function DayState:_queuePawnShopDraw(entityDrawList)
    if self:_isInCasino() then return end
    if self.fog:getState(self.pawnShop.tx, self.pawnShop.ty) == "hidden" then return end
    local _, pawnShopSy = Iso.tileToScreen(self.pawnShop.tx, self.pawnShop.ty)
    entityDrawList[#entityDrawList + 1] = {
        sy = pawnShopSy,
        order = 42,
        draw = function() self:_drawPawnShop() end
    }
end

function DayState:_queueSlotMachineDraw(entityDrawList)
    if not self:_isInCasino() then
        return
    end

    local _, sy = Iso.tileToScreen(self.casinoInterior.slotMachine.tx, self.casinoInterior.slotMachine.ty)
    entityDrawList[#entityDrawList + 1] = {
        sy = sy,
        order = 45,
        draw = function() self:_drawSlotMachine() end
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
    self:_queuePawnShopDraw(entityDrawList)
    self:_queueSlotMachineDraw(entityDrawList)
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
        slotUIActive = self.casinoInterior.slotUIActive,
        slotSpinActive = self.casinoInterior.slotSpin.active,
        slotStakeLabel = self:_currentStakeLabel(),
    })
    if self:_isInCasino() and self.casinoInterior.slotUIActive then
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

function DayState:_showNotice(text, holdTime)
    self.notice.text = text
    self.notice.alpha = 0
    self.notice.y = 36
    self.game.tweens:stop(self.notice)
    holdTime = holdTime or 1.0
    self.game.tweens:to(self.notice, 0.18, { alpha = 1, y = 52 }):ease("quadout"):oncomplete(function()
        self.game.tweens:to(self.notice, 0.35, { alpha = 0, y = 58 }):delay(holdTime)
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
    local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
    local spin = self.casinoInterior.slotSpin
    local panelW, panelH = 560, 362
    local panelX = (sw - panelW) * 0.5
    local panelY = 34
    local reelY = panelY + 64
    local reelW = 116
    local reelH = 92
    local reelGap = 24
    local firstReelX = panelX + 58

    local function drawSymbolLabel(symbol, x, y, w, alpha, scale)
        love.graphics.push()
        love.graphics.translate(x + w * 0.5, y)
        love.graphics.scale(scale, scale)
        drawSlotSymbol(symbol, 0, 0, 52, alpha, self.slotFont)
        love.graphics.pop()
    end

    local function drawPaytableEntry(x, y, entry)
        local iconBox = 42
        local gap = 8
        local startX = x + 16

        love.graphics.setColor(1, 1, 1, 0.06)
        love.graphics.rectangle("fill", x, y, 248, 34, 8, 8)
        love.graphics.setColor(0.90, 0.72, 0.18, 0.35)
        love.graphics.rectangle("line", x, y, 248, 34, 8, 8)

        for i = 1, 3 do
            local boxX = startX + (i - 1) * (iconBox + gap)
            love.graphics.setColor(0.96, 0.94, 0.88, 0.95)
            love.graphics.rectangle("fill", boxX, y + 4, iconBox, 26, 6, 6)
            love.graphics.setColor(0.76, 0.58, 0.12, 0.9)
            love.graphics.rectangle("line", boxX, y + 4, iconBox, 26, 6, 6)
            drawSlotSymbol(entry.symbols[i], boxX + iconBox * 0.5, y + 17, 22, 1, self.smallFont)
        end

        love.graphics.setFont(self.smallFont)
        love.graphics.setColor(1, 0.97, 0.88, 0.95)
        love.graphics.printf(string.format("%dx", entry.multiplier), x + 166, y + 8, 66, "center")
    end

    local function drawReel(x, y, index)
        local reelState = spin.reelStates and spin.reelStates[index]
        local active = spin.active and spin.elapsed < spin.reelStopTimes[index]
        local position = reelState and reelState.position or ((SLOT_SYMBOL_INDEX[spin.displayReels[index]] or 1) - 1)
        local rowHeight = 42
        local centerY = y + reelH * 0.5
        local baseIndex = math.floor(position)
        local offset = position - baseIndex

        love.graphics.setColor(0.88, 0.70, 0.20, 1)
        love.graphics.rectangle("fill", x - 8, y - 8, reelW + 16, reelH + 16, 12, 12)
        love.graphics.setColor(0.97, 0.95, 0.90, 1)
        love.graphics.rectangle("fill", x, y, reelW, reelH, 10, 10)
        love.graphics.setColor(0.76, 0.58, 0.12, 1)
        love.graphics.rectangle("line", x, y, reelW, reelH, 10, 10)

        love.graphics.setScissor(x, y, reelW, reelH)
        for relativeIndex = -2, 2 do
            local symbol = getSlotSymbolAt(baseIndex + relativeIndex)
            local symbolY = centerY + (relativeIndex - offset) * rowHeight
            local distance = math.abs(symbolY - centerY)
            local alpha = active and clamp(1 - distance / (rowHeight * 2.6), 0.16, 0.92) or clamp(1 - distance / (rowHeight * 1.7), 0.10, 1.0)
            local scale = active and (1.0 - math.min(distance / (rowHeight * 9), 0.08)) or 1.0
            drawSymbolLabel(symbol, x, symbolY, reelW, alpha, scale)
        end
        love.graphics.setScissor()

        love.graphics.setColor(1, 1, 1, 0.22)
        love.graphics.rectangle("line", x + 10, y + reelH * 0.5 - 20, reelW - 20, 40, 8, 8)

        love.graphics.setColor(0.95, 0.95, 0.95, 0.10)
        love.graphics.rectangle("fill", x + 2, y + 2, reelW - 4, 18, 8, 8)
        love.graphics.setColor(0.10, 0.08, 0.05, active and 0.18 or 0.12)
        love.graphics.rectangle("fill", x + 4, y, reelW - 8, 18)
        love.graphics.rectangle("fill", x + 4, y + reelH - 18, reelW - 8, 18)
    end

    love.graphics.setColor(0, 0, 0, 0.76)
    love.graphics.rectangle("fill", panelX, panelY, panelW, panelH, 18, 18)
    love.graphics.setColor(0.86, 0.68, 0.16, 1)
    love.graphics.rectangle("line", panelX, panelY, panelW, panelH, 18, 18)

    love.graphics.setFont(self.slotTitleFont)
    love.graphics.setColor(0.98, 0.84, 0.22, 1)
    love.graphics.printf("HOLDFAST SLOTS", panelX, panelY + 18, panelW, "center")

    for i = 1, 3 do
        drawReel(firstReelX + (i - 1) * (reelW + reelGap), reelY, i)
    end

    love.graphics.setFont(self.smallFont)
    love.graphics.setColor(1, 0.97, 0.88, 0.95)
    if spin.active then
        love.graphics.printf("Spinning reels...", panelX, panelY + 172, panelW, "center")
    else
        love.graphics.printf("Stake:", panelX, panelY + 168, panelW, "center")
        love.graphics.printf(self:_formatSlotStake(), panelX + 24, panelY + 190, panelW - 48, "center")
        love.graphics.printf("LEFT / RIGHT: Adjust Gold Stake   G: Run Machine   ESC: Leave Machine", panelX, panelY + 222, panelW, "center")
    end

    love.graphics.setColor(0.98, 0.84, 0.22, 0.92)
    love.graphics.printf("Paytable", panelX, panelY + 252, panelW, "center")

    local paytableX = panelX + 22
    local paytableY = panelY + 278
    local columnGap = 268
    local rowGap = 40
    for i, entry in ipairs(SLOT_PAYTABLE) do
        local column = (i - 1) % 2
        local row = math.floor((i - 1) / 2)
        drawPaytableEntry(paytableX + column * columnGap, paytableY + row * rowGap, entry)
    end
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
        if self.casinoInterior.slotUIActive and key == "left" then
            self:_changeSlotStake(-1)
        elseif self.casinoInterior.slotUIActive and key == "right" then
            self:_changeSlotStake(1)
        elseif key == "g" and self.casinoInterior.slotUIActive and not self.casinoInterior.slotSpin.active then
            self:_startSlotSpin()
        elseif key == "g" and self:_isNearSlotMachine() and not self.casinoInterior.slotSpin.active then
            if self.casinoInterior.slotUIActive then
                self:_startSlotSpin()
            else
                self:_openSlotMachineUI()
            end
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
    elseif key == "h" then
        if self.pawnShop:isNearby(self.player.tx, self.player.ty) then
            local _, message = self.pawnShop:sellInventory(self.inventory)
            self:_showNotice(message, 2.8)
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
        if self:_isInCasino() then
            if self.casinoInterior.slotUIActive and not self.casinoInterior.slotSpin.active then
                self:_closeSlotMachineUI()
            else
                self:_exitCasino()
            end
        elseif self.ghost:isActive() then
            self.ghost:deactivate()
        else
            self.game.stateMachine:setState("menu")
        end
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
            if self.casinoInterior.slotUIActive and not self.casinoInterior.slotSpin.active then
                self:_closeSlotMachineUI()
            else
                self:_exitCasino()
            end
        elseif self.casinoInterior.slotUIActive and button == "dpleft" then
            self:_changeSlotStake(-1)
        elseif self.casinoInterior.slotUIActive and button == "dpright" then
            self:_changeSlotStake(1)
        elseif button == "a" and self.casinoInterior.slotUIActive and not self.casinoInterior.slotSpin.active then
            self:_startSlotSpin()
        elseif button == "a" and self:_isNearSlotMachine() and not self.casinoInterior.slotSpin.active then
            if self.casinoInterior.slotUIActive then
                self:_startSlotSpin()
            else
                self:_openSlotMachineUI()
            end
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
        if self.pawnShop:isNearby(self.player.tx, self.player.ty) then
            local _, message = self.pawnShop:sellInventory(self.inventory)
            self:_showNotice(message, 2.8)
        elseif self.depot:isNearby(self.player.tx, self.player.ty) then
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
