-- Test State
-- Demonstrates Phase 2 Developer B systems

local Class = require("lib.class")
local CombatManager = require("src.combat.combatmanager")
local ProjectileSystem = require("src.combat.projectilesystem")
local Projectile = require("src.combat.projectile")
local EventBus = require("src.core.eventbus")
local Constants = require("data.constants")
local Classes = require("data.classes")
local World = require("src.ecs.world")
local Pathfinding = require("src.ai.pathfinding")
local Warrior = require("src.characters.warrior")
local Archer = require("src.characters.archer")
local Engineer = require("src.characters.engineer")
local Scout = require("src.characters.scout")
local Cloak = require("src.characters.abilities.cloak")
local Shambler = require("src.enemies.shambler")

local TestState = Class:extend()

function TestState:new(game)
    self.game = game
    self.name = "test"
end

function TestState:enter(selectedClass)
    print("=== PHASE 2 TEST STATE ===")
    print("Controls:")
    print("  WASD / Left Stick - Move")
    print("  SPACE / Cross - Attack")
    print("  E / Square - Use Ability")
    print("  1-4 - Switch Class")
    print("  T - Spawn Shambler")
    print("  F3 - Toggle Debug")
    print("  ESC - Return to Menu")
    print("")

    self.world = World()
    self.enemyPathfinding = Pathfinding.new({
        originX = -96,
        originY = -96,
        width = 24,
        height = 18,
        cellSize = 64,
    })
    self:buildPathfindingArena()

    self.combatManager = CombatManager.new(self.world, EventBus)
    self.projectileSystem = ProjectileSystem(self.world)
    self.world:addSystem(self.projectileSystem)

    local Camera = require("src.core.camera")
    local sw, sh = love.graphics.getDimensions()
    self.camera = Camera(sw, sh)
    self.camera:setZoom(1.15)

    local initialClass = selectedClass or Constants.CLASS.WARRIOR
    local playerSpawnX, playerSpawnY = self:findWalkableSpawnPosition(400, 300)
    self.player = self:createClassCharacter(initialClass, playerSpawnX, playerSpawnY)
    self:configureDemoCharacter(self.player, false)
    self.world:addEntity(self.player.entity)

    self.enemies = {}
    self.camera:moveTo(self.player.position.x, self.player.position.y)
    self.debugMode = false
    self.notice = {alpha = 0, y = 52}
    self.currentClass = self:getClassLabel(initialClass)
    self:showNotice(self.currentClass)

    EventBus.on(Constants.EVENTS.ENTITY_DIED, function(data)
        for i = #self.enemies, 1, -1 do
            local enemy = self.enemies[i]
            if enemy.character.entity.id == data.entity.id then
                table.remove(self.enemies, i)
            end
        end
    end)
end

function TestState:createClassCharacter(classType, x, y)
    if classType == Constants.CLASS.ARCHER then
        return Archer.new(x, y)
    elseif classType == Constants.CLASS.ENGINEER then
        return Engineer.new(x, y)
    elseif classType == Constants.CLASS.SCOUT then
        return Scout.new(x, y)
    end

    return Warrior.new(x, y)
end

function TestState:getClassLabel(classType)
    local classDef = Classes.get(classType)
    return classDef and classDef.label or "Warrior"
end

function TestState:update(dt)
    if love.keyboard.wasPressed("f3") then
        self.debugMode = not self.debugMode
    end

    if love.keyboard.wasPressed("escape") then
        self.game.stateMachine:setState("menu")
        return
    end

    if love.keyboard.wasPressed("1") then
        self:switchClass(Constants.CLASS.WARRIOR)
    elseif love.keyboard.wasPressed("2") then
        self:switchClass(Constants.CLASS.ARCHER)
    elseif love.keyboard.wasPressed("3") then
        self:switchClass(Constants.CLASS.ENGINEER)
    elseif love.keyboard.wasPressed("4") then
        self:switchClass(Constants.CLASS.SCOUT)
    end

    if love.keyboard.wasPressed("t") then
        self:spawnTestEnemy()
    end

    if love.keyboard.wasPressed("space") then
        self:playerAttack()
    end

    if love.keyboard.wasPressed("e") then
        self:playerAbility()
    end

    self.player:update(dt)
    if self.player.classType == Constants.CLASS.SCOUT then
        Cloak.update(self.player, dt)
    end
    if self.player.cooldowns then
        self.player.cooldowns:update(dt)
    end

    local neighbors = self:getEnemyCharacters()
    for _, enemy in ipairs(self.enemies) do
        enemy:update(dt, {
            neighbors = neighbors,
            player = self.player,
        })
    end

    self.combatManager:update(dt)
    self.world:update(dt)
    self.camera:follow(self.player.position.x, self.player.position.y)
    self.camera:update(dt)
end

function TestState:draw()
    self.camera:apply()
    self:drawGrid()
    self.enemyPathfinding:drawDebug()
    self:drawArenaObstacles()

    self:drawCharacter(self.player)
    for _, enemy in ipairs(self.enemies) do
        self:drawCharacter(enemy.character)
    end

    self.projectileSystem:render()

    if self.debugMode then
        self.player:drawDebug()
        for _, enemy in ipairs(self.enemies) do
            enemy.character:drawDebug()
        end
        self.combatManager:drawDebug()
    end

    self.camera:clear()
    self:drawUI()
end

function TestState:drawGrid()
    love.graphics.setColor(0.2, 0.2, 0.2, 0.5)
    local gridSize = 64
    local startX = math.floor(self.camera.x / gridSize) * gridSize
    local startY = math.floor(self.camera.y / gridSize) * gridSize

    for x = startX - gridSize * 10, startX + gridSize * 20, gridSize do
        love.graphics.line(x, startY - gridSize * 10, x, startY + gridSize * 20)
    end

    for y = startY - gridSize * 10, startY + gridSize * 20, gridSize do
        love.graphics.line(startX - gridSize * 10, y, startX + gridSize * 20, y)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function TestState:drawCharacter(character)
    if not character:isAlive() then
        return
    end

    local pos = character:getPosition()
    character:draw()

    if character.health then
        local barWidth = 40
        local barHeight = 6
        local barX = pos.x - barWidth / 2
        local barY = pos.y - 26
        local healthPercent = character.health:getHealthPercentage()

        love.graphics.setColor(0.2, 0.2, 0.2, 1)
        love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)
        love.graphics.setColor(0, 1, 0, 1)
        love.graphics.rectangle("fill", barX, barY, barWidth * healthPercent, barHeight)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("line", barX, barY, barWidth, barHeight)
    end
end

function TestState:drawUI()
    local padding = 20

    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", padding, padding, 320, 220)
    love.graphics.setColor(1, 1, 1, 1)

    local y = padding + 10
    love.graphics.print("=== PHASE 2 TEST ===", padding + 10, y)
    y = y + 25
    love.graphics.print(string.format("Class: %s (1-4 to switch)", self.currentClass), padding + 10, y)
    y = y + 20
    love.graphics.print(string.format("HP: %d/%d", self.player.health.currentHp, self.player.health.maxHp), padding + 10, y)
    y = y + 20
    love.graphics.print(string.format("Speed: %d", self.player.stats:getSpeed()), padding + 10, y)
    y = y + 20
    love.graphics.print(string.format("Attack: %d", self.player.stats:getAttack()), padding + 10, y)
    y = y + 20
    love.graphics.print(string.format("Armor: %d", self.player.stats:getArmor()), padding + 10, y)
    y = y + 20
    love.graphics.print(string.format("Enemies: %d", #self.enemies), padding + 10, y)
    y = y + 20
    love.graphics.print("Pathfinding: A* + cache, AI seek/attack", padding + 10, y)

    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", padding, love.graphics.getHeight() - 140, 320, 120)
    love.graphics.setColor(1, 1, 1, 1)

    y = love.graphics.getHeight() - 130
    love.graphics.print("SPACE/Cross - Attack", padding + 10, y)
    y = y + 20
    love.graphics.print("E/Square - Ability", padding + 10, y)
    y = y + 20
    love.graphics.print("T - Spawn Shambler", padding + 10, y)
    y = y + 20
    love.graphics.print("F3 - Debug Mode", padding + 10, y)
    y = y + 20
    love.graphics.print("ESC - Menu", padding + 10, y)

    if self.notice.alpha > 0.01 then
        love.graphics.setColor(0, 0, 0, 0.65 * self.notice.alpha)
        love.graphics.rectangle("fill", love.graphics.getWidth() * 0.5 - 140, self.notice.y - 8, 280, 38)
        love.graphics.setColor(1, 1, 1, self.notice.alpha)
        love.graphics.printf(self.notice.text, 0, self.notice.y, love.graphics.getWidth(), "center")
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function TestState:buildPathfindingArena()
    self.arenaObstacles = {
        {col = 8, row = 3, width = 1, height = 3},
        {col = 8, row = 7, width = 1, height = 4},
        {col = 15, row = 7, width = 1, height = 4},
        {col = 15, row = 12, width = 1, height = 3},
        {col = 10, row = 5, width = 4, height = 1},
        {col = 11, row = 13, width = 2, height = 1},
        {col = 14, row = 13, width = 1, height = 1},
    }

    for _, obstacle in ipairs(self.arenaObstacles) do
        self.enemyPathfinding:setBlockedRect(obstacle.col, obstacle.row, obstacle.width, obstacle.height, true)
    end
end

function TestState:drawArenaObstacles()
    love.graphics.setColor(0.28, 0.16, 0.12, 0.9)
    for _, obstacle in ipairs(self.arenaObstacles) do
        local x, y = self.enemyPathfinding:gridToWorld(obstacle.col, obstacle.row)
        love.graphics.rectangle(
            "fill",
            x - self.enemyPathfinding.cellSize * 0.5,
            y - self.enemyPathfinding.cellSize * 0.5,
            obstacle.width * self.enemyPathfinding.cellSize,
            obstacle.height * self.enemyPathfinding.cellSize
        )
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function TestState:getEnemyTargetPosition(enemyCharacter)
    local slotRadius = 36
    local slotCount = math.max(#self.enemies, 1)
    local slotIndex = ((enemyCharacter.entity.id - 1) % slotCount)
    local baseAngle = (slotIndex / slotCount) * math.pi * 2
    local orbitAngle = baseAngle + love.timer.getTime() * 0.8
    local targetX = self.player.position.x + math.cos(orbitAngle) * slotRadius
    local targetY = self.player.position.y + math.sin(orbitAngle) * slotRadius
    return self:findWalkableSpawnPosition(targetX, targetY)
end

function TestState:getDistanceToPlayer(enemyCharacter)
    local dx = self.player.position.x - enemyCharacter.position.x
    local dy = self.player.position.y - enemyCharacter.position.y
    return math.sqrt(dx * dx + dy * dy)
end

function TestState:enemyAttack(enemyCharacter, distanceToPlayer)
    if not enemyCharacter.stats:canAttack() or not self.combatManager:canAttack(enemyCharacter.entity) then
        return
    end

    local facingDir = enemyCharacter.facingDirection
    local range = enemyCharacter.stats:getAttackRange()
    local offsetDistance = math.min(range * 0.5, distanceToPlayer * 0.5)
    local attackId = self.combatManager:registerAttack(enemyCharacter.entity, {
        range = range,
        damage = enemyCharacter.stats:getAttack(),
        cooldown = 1.0 / math.max(enemyCharacter.stats:getAttackSpeed(), 0.1),
        hitboxOffset = {
            x = math.cos(facingDir) * offsetDistance,
            y = math.sin(facingDir) * offsetDistance,
        },
        hitboxSize = {width = range, height = math.max(24, range * 0.7)},
        duration = 0.25,
        knockback = 40,
        hitLimit = 1,
    })

    if attackId then
        enemyCharacter:triggerAttackAnimation()
    end
end

function TestState:getEnemyCharacters()
    local neighbors = {}
    for _, enemy in ipairs(self.enemies) do
        if enemy.character:isAlive() then
            neighbors[#neighbors + 1] = enemy.character
        end
    end
    return neighbors
end

function TestState:configureDemoCharacter(character, isEnemy)
    character:setInputManager(isEnemy and nil or self.game.input)
    character:setWorld(self.world)
    character:setCollisionChecker(function(instance, x, y)
        return self:canCharacterMoveTo(instance, x, y)
    end)
    character.hitbox.width = 24
    character.hitbox.height = 24
    character:setVisualScale(isEnemy and 1.1 or 1.15)
end

function TestState:canCharacterMoveTo(character, x, y)
    local bounds = character.hitbox:getBounds({x = x, y = y})
    local inset = 6
    local samplePoints = {
        {x = bounds.left + inset, y = bounds.top + inset},
        {x = bounds.right - inset, y = bounds.top + inset},
        {x = bounds.left + inset, y = bounds.bottom - inset},
        {x = bounds.right - inset, y = bounds.bottom - inset},
        {x = bounds.centerX, y = bounds.centerY},
    }

    for _, point in ipairs(samplePoints) do
        local col, row = self.enemyPathfinding:worldToGrid(point.x, point.y)
        if not self.enemyPathfinding:isWalkable(col, row) then
            return false
        end
    end

    return true
end

function TestState:findWalkableSpawnPosition(x, y)
    local col, row = self.enemyPathfinding:worldToGrid(x, y)
    if self.enemyPathfinding:isWalkable(col, row) then
        return x, y
    end

    for radius = 1, 4 do
        for dy = -radius, radius do
            for dx = -radius, radius do
                local testCol = col + dx
                local testRow = row + dy
                if self.enemyPathfinding:isWalkable(testCol, testRow) then
                    return self.enemyPathfinding:gridToWorld(testCol, testRow)
                end
            end
        end
    end

    return x, y
end

function TestState:showNotice(text)
    self.notice.text = text
    self.notice.alpha = 0
    self.notice.y = 36
    self.game.tweens:stop(self.notice)
    self.game.tweens:to(self.notice, 0.18, {alpha = 1, y = 52}):ease("quadout"):oncomplete(function()
        self.game.tweens:to(self.notice, 0.35, {alpha = 0, y = 58}):delay(0.8)
    end)
end

function TestState:pulseCameraZoom()
    self.game.tweens:stop(self.camera)
    local baseZoom = self.camera.zoom
    self.game.tweens:to(self.camera, 0.12, {zoom = math.min(4.0, baseZoom + 0.08)}):ease("quadout"):oncomplete(function()
        self.game.tweens:to(self.camera, 0.18, {zoom = baseZoom}):ease("quadinout")
    end)
end

function TestState:switchClass(classType)
    local pos = self.player:getPosition()
    local spawnX, spawnY = self:findWalkableSpawnPosition(pos.x, pos.y)
    self.world:removeEntity(self.player.entity)
    self.player = self:createClassCharacter(classType, spawnX, spawnY)
    self:configureDemoCharacter(self.player, false)
    self.world:addEntity(self.player.entity)
    self.camera:moveTo(self.player.position.x, self.player.position.y)
    self.currentClass = self:getClassLabel(classType)
    self:showNotice("Class: " .. self.currentClass)
    self:pulseCameraZoom()
end

function TestState:spawnTestEnemy()
    local playerPos = self.player:getPosition()
    local angle = math.random() * math.pi * 2
    local distance = 200
    local x = playerPos.x + math.cos(angle) * distance
    local y = playerPos.y + math.sin(angle) * distance
    x, y = self:findWalkableSpawnPosition(x, y)

    local enemy = Shambler.new(x, y, {
        pathfinding = self.enemyPathfinding,
        acquireTarget = function(actor, context)
            local targetX, targetY = self:getEnemyTargetPosition(actor)
            return {
                x = targetX,
                y = targetY,
                entity = context.player and context.player.entity or nil,
            }
        end,
        attack = function(actor)
            self:enemyAttack(actor, self:getDistanceToPlayer(actor))
        end,
    })
    self:configureDemoCharacter(enemy.character, true)
    self.world:addEntity(enemy.character.entity)
    self.enemies[#self.enemies + 1] = enemy
end

function TestState:playerAttack()
    if not self.combatManager:canAttack(self.player.entity) then
        return
    end

    local stats = self.player.stats
    if not stats:canAttack() then
        return
    end

    local facingDir = self.player.facingDirection
    local range = stats:getAttackRange()
    local attackId = self.combatManager:registerAttack(self.player.entity, {
        range = range,
        damage = stats:getAttack(),
        cooldown = 1.0 / math.max(stats:getAttackSpeed(), 0.1),
        hitboxOffset = {
            x = math.cos(facingDir) * range / 2,
            y = math.sin(facingDir) * range / 2,
        },
        hitboxSize = {width = range, height = math.max(24, range / 2)},
        duration = 0.3,
        knockback = 50,
        hitLimit = 10,
    })

    if attackId then
        self.player:triggerAttackAnimation()
        self:pulseCameraZoom()

        if self.player.classType == Constants.CLASS.ARCHER then
            Projectile.createArrow(
                self.world,
                self.player.position.x,
                self.player.position.y,
                facingDir,
                self.player.entity,
                "player"
            )
        end
    end
end

function TestState:playerAbility()
    local classType = self.player.classType

    if classType == Constants.CLASS.ARCHER and self.player.cooldowns then
        local ok = self.player.cooldowns:activate("volley", {
            actor = self.player,
            world = self.world,
        })
        if ok then
            self:showNotice("Volley")
        end
    elseif classType == Constants.CLASS.WARRIOR and self.player.cooldowns then
        local ok = self.player.cooldowns:activate("shield_bash", {
            actor = self.player,
            world = self.world,
            combatManager = self.combatManager,
        })
        if ok then
            self:showNotice("Shield Bash")
        end
    elseif classType == Constants.CLASS.SCOUT and self.player.cooldowns then
        local ok = self.player.cooldowns:activate("cloak", {
            actor = self.player,
        })
        if ok then
            self:showNotice("Scout Cloak")
        end
    elseif classType == Constants.CLASS.ENGINEER then
        self.player:heal(20)
        self:showNotice("Engineer Repair Burst")
    end
end

function TestState:keypressed(key)
    if key == "=" or key == "+" then
        self.camera:adjustZoom(0.1)
    elseif key == "-" then
        self.camera:adjustZoom(-0.1)
    elseif key == "0" then
        self.camera:setZoom(1.15)
    end
end

function TestState:wheelmoved(x, y)
    self.camera:adjustZoom(y * 0.1)
end

function TestState:exit()
end

love.keyboard.wasPressed = function(key)
    if not love.keyboard._pressedKeys then
        love.keyboard._pressedKeys = {}
    end

    if love.keyboard.isDown(key) and not love.keyboard._pressedKeys[key] then
        love.keyboard._pressedKeys[key] = true
        return true
    elseif not love.keyboard.isDown(key) then
        love.keyboard._pressedKeys[key] = false
    end

    return false
end

return TestState
