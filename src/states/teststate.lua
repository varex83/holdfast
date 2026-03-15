-- Test State
-- Demonstrates all Phase 1 Developer B systems

local Class = require('lib.class')
local Character = require('src.characters.character')
local CombatManager = require('src.combat.combatmanager')
local ProjectileSystem = require('src.combat.projectilesystem')
local Projectile = require('src.combat.projectile')
local EventBus = require('src.core.eventbus')
local Constants = require('data.constants')
local World = require('src.ecs.world')
local Pathfinding = require('src.ai.pathfinding')

local TestState = Class:extend()

function TestState:new(game)
    self.game = game
    self.name = 'test'
end

function TestState:enter(selectedClass)
    print("=== PHASE 1 TEST STATE ===")
    print("Controls:")
    print("  WASD / Left Stick - Move")
    print("  SPACE / Cross - Attack")
    print("  E / Square - Use Ability")
    print("  1-4 - Switch Class")
    print("  T - Spawn Test Enemy")
    print("  F3 - Toggle Debug")
    print("  ESC - Return to Menu")
    print("")

    self.world = World()
    self.enemyPathfinding = Pathfinding.new({
        originX = -96,
        originY = -96,
        width = 24,
        height = 18,
        cellSize = 64
    })
    self:buildPathfindingArena()

    -- Combat manager
    self.combatManager = CombatManager.new(self.world, EventBus)

    -- Projectile system
    self.projectileSystem = ProjectileSystem(self.world)
    self.world:addSystem(self.projectileSystem)

    -- Create camera
    local Camera = require("src.core.camera")
    local sw, sh = love.graphics.getDimensions()
    self.camera = Camera(sw, sh)
    self.camera:setZoom(1.15)

    local initialClass = selectedClass or Constants.CLASS.WARRIOR

    -- Create player character
    local playerSpawnX, playerSpawnY = self:findWalkableSpawnPosition(400, 300)
    self.player = Character.new(initialClass, playerSpawnX, playerSpawnY)
    self:configureDemoCharacter(self.player, false)
    self.world:addEntity(self.player.entity)

    -- Test enemies (for combat testing)
    self.enemies = {}

    -- Set camera to follow player
    self.camera:moveTo(self.player.position.x, self.player.position.y)

    -- Debug mode
    self.debugMode = false
    self.notice = {alpha = 0, y = 52}

    -- Attack cooldown display
    self.lastAttackTime = 0
    self.attackCooldown = 1.0

    -- UI info
    self.currentClass = self:getClassLabel(initialClass)
    self:showNotice(self.currentClass)

    -- Subscribe to combat events
    EventBus.on(Constants.EVENTS.ENTITY_DIED, function(data)
        print("Entity died:", data.entityId)
        -- Remove from enemies list
        for i, enemy in ipairs(self.enemies) do
            if enemy.entity.id == data.entityId then
                table.remove(self.enemies, i)
                break
            end
        end
    end)

    EventBus.on(Constants.EVENTS.ENTITY_DAMAGED, function(data)
        print(string.format("Entity %d took %d damage (%d/%d HP)",
            data.entity.id, data.damage, data.currentHp, data.maxHp))
    end)
end

function TestState:getClassLabel(classType)
    if classType == Constants.CLASS.WARRIOR then
        return "Warrior"
    elseif classType == Constants.CLASS.ARCHER then
        return "Archer"
    elseif classType == Constants.CLASS.ENGINEER then
        return "Engineer"
    elseif classType == Constants.CLASS.SCOUT then
        return "Scout"
    end

    return "Warrior"
end

function TestState:update(dt)
    -- Toggle debug
    if love.keyboard.wasPressed('f3') then
        self.debugMode = not self.debugMode
    end

    -- Return to menu
    if love.keyboard.wasPressed('escape') then
        self.game.stateMachine:setState('menu')
        return
    end

    -- Switch class with number keys
    if love.keyboard.wasPressed('1') then
        self:switchClass(Constants.CLASS.WARRIOR)
    elseif love.keyboard.wasPressed('2') then
        self:switchClass(Constants.CLASS.ARCHER)
    elseif love.keyboard.wasPressed('3') then
        self:switchClass(Constants.CLASS.ENGINEER)
    elseif love.keyboard.wasPressed('4') then
        self:switchClass(Constants.CLASS.SCOUT)
    end

    -- Spawn test enemy
    if love.keyboard.wasPressed('t') then
        self:spawnTestEnemy()
    end

    -- Player attack
    if love.keyboard.wasPressed('space') then
        self:playerAttack()
    end

    -- Player ability
    if love.keyboard.wasPressed('e') then
        self:playerAbility()
    end

    -- Update player
    self.player:update(dt)

    -- Update enemies
    for _, enemy in ipairs(self.enemies) do
        self:updateEnemyAI(enemy, dt)
        enemy:update(dt)
    end

    -- Update combat manager
    self.combatManager:update(dt)

    -- Update world (projectiles)
    self.world:update(dt)

    -- Update camera to follow player
    self.camera:follow(self.player.position.x, self.player.position.y)

    -- Update camera
    self.camera:update(dt)
end

function TestState:draw()
    -- Apply camera transform
    self.camera:apply()

    -- Draw grid
    self:drawGrid()
    self.enemyPathfinding:drawDebug()
    self:drawArenaObstacles()

    -- Draw player
    self:drawCharacter(self.player)

    -- Draw enemies
    for _, enemy in ipairs(self.enemies) do
        self:drawCharacter(enemy)
    end

    -- Draw projectiles
    self.projectileSystem:render()

    -- Debug rendering
    if self.debugMode then
        self.player:drawDebug()
        for _, enemy in ipairs(self.enemies) do
            enemy:drawDebug()
        end
        self.combatManager:drawDebug()
    end

    self.camera:clear()

    -- Draw UI
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
    local size = 32

    character:draw()

    -- Draw health bar
    local health = character.health
    if health then
        local barWidth = 40
        local barHeight = 6
        local barX = pos.x - barWidth/2
        local barY = pos.y - size/2 - 10

        -- Background
        love.graphics.setColor(0.2, 0.2, 0.2, 1)
        love.graphics.rectangle('fill', barX, barY, barWidth, barHeight)

        -- Health
        local healthPercent = health:getHealthPercentage()
        love.graphics.setColor(0, 1, 0, 1)
        love.graphics.rectangle('fill', barX, barY, barWidth * healthPercent, barHeight)

        -- Border
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle('line', barX, barY, barWidth, barHeight)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function TestState:drawUI()
    local padding = 20

    -- Player info
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle('fill', padding, padding, 300, 200)
    love.graphics.setColor(1, 1, 1, 1)

    local y = padding + 10
    love.graphics.print("=== PHASE 1 TEST ===", padding + 10, y)
    y = y + 25

    love.graphics.print(string.format("Class: %s (1-4 to switch)", self.currentClass), padding + 10, y)
    y = y + 20

    local health = self.player.health
    if health then
        love.graphics.print(string.format("HP: %d/%d", health.currentHp, health.maxHp), padding + 10, y)
        y = y + 20
    end

    local stats = self.player.stats
    if stats then
        love.graphics.print(string.format("Speed: %d", stats:getSpeed()), padding + 10, y)
        y = y + 20
        love.graphics.print(string.format("Attack: %d", stats:getAttack()), padding + 10, y)
        y = y + 20
        love.graphics.print(string.format("Armor: %d", stats:getArmor()), padding + 10, y)
        y = y + 20
    end

    love.graphics.print(string.format("State: %s", self.player:getState()), padding + 10, y)
    y = y + 20

    love.graphics.print(string.format("Enemies: %d", #self.enemies), padding + 10, y)
    y = y + 20
    love.graphics.print("Pathfinding: jumper A* demo", padding + 10, y)

    -- Controls
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle('fill', padding, love.graphics.getHeight() - 140, 300, 120)
    love.graphics.setColor(1, 1, 1, 1)

    y = love.graphics.getHeight() - 130
    love.graphics.print("SPACE/Cross - Attack", padding + 10, y)
    y = y + 20
    love.graphics.print("E/Square - Ability", padding + 10, y)
    y = y + 20
    love.graphics.print("T - Spawn Enemy", padding + 10, y)
    y = y + 20
    love.graphics.print("F3 - Debug Mode", padding + 10, y)
    y = y + 20
    love.graphics.print("ESC - Menu", padding + 10, y)

    if self.notice.alpha > 0.01 then
        love.graphics.setColor(0, 0, 0, 0.65 * self.notice.alpha)
        love.graphics.rectangle('fill', love.graphics.getWidth() * 0.5 - 140, self.notice.y - 8, 280, 38)
        love.graphics.setColor(1, 1, 1, self.notice.alpha)
        love.graphics.printf(self.notice.text, 0, self.notice.y, love.graphics.getWidth(), 'center')
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
        {col = 14, row = 13, width = 1, height = 1}
    }

    for _, obstacle in ipairs(self.arenaObstacles) do
        self.enemyPathfinding:setBlockedRect(obstacle.col, obstacle.row, obstacle.width, obstacle.height, true)
    end
end

function TestState:drawArenaObstacles()
    love.graphics.setColor(0.28, 0.16, 0.12, 0.9)
    for _, obstacle in ipairs(self.arenaObstacles) do
        local x, y = self.enemyPathfinding:gridToWorld(obstacle.col, obstacle.row)
        local drawX = x - self.enemyPathfinding.cellSize * 0.5
        local drawY = y - self.enemyPathfinding.cellSize * 0.5
        love.graphics.rectangle(
            'fill',
            drawX,
            drawY,
            obstacle.width * self.enemyPathfinding.cellSize,
            obstacle.height * self.enemyPathfinding.cellSize
        )
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function TestState:updateEnemyAI(enemy, dt)
    if not enemy:isAlive() then
        return
    end

    local targetX, targetY = self:getEnemyTargetPosition(enemy)
    local toPlayerX = self.player.position.x - enemy.position.x
    local toPlayerY = self.player.position.y - enemy.position.y
    local distanceToPlayer = math.sqrt(toPlayerX * toPlayerX + toPlayerY * toPlayerY)
    local meleeRange = enemy.stats:getAttackRange() + 8

    if distanceToPlayer <= meleeRange then
        enemy:setDesiredMovement(0, 0)

        if distanceToPlayer > 0 then
            enemy.facingDirection = math.atan2(toPlayerY, toPlayerX)
        end

        self:enemyAttack(enemy, distanceToPlayer)
        return
    end

    enemy.aiTimer = (enemy.aiTimer or 0) - dt

    if enemy.aiTimer <= 0 then
        enemy.aiTimer = 0.35
        enemy.path = self.enemyPathfinding:findPathWorld(
            enemy.position.x,
            enemy.position.y,
            targetX,
            targetY
        ) or {}
        enemy.pathIndex = 2
    end

    local waypoint = enemy.path and enemy.path[enemy.pathIndex]
    if not waypoint then
        enemy:setDesiredMovement(0, 0)
        return
    end

    local dx = waypoint.x - enemy.position.x
    local dy = waypoint.y - enemy.position.y
    local distance = math.sqrt(dx * dx + dy * dy)

    if distance < 8 then
        enemy.pathIndex = enemy.pathIndex + 1
        waypoint = enemy.path[enemy.pathIndex]
        if not waypoint then
            enemy:setDesiredMovement(0, 0)
            return
        end
        dx = waypoint.x - enemy.position.x
        dy = waypoint.y - enemy.position.y
    end

    enemy:setDesiredMovement(dx, dy)
end

function TestState:getEnemyTargetPosition(enemy)
    local slotRadius = 36
    local slotCount = math.max(#self.enemies, 1)
    local slotIndex = ((enemy.entity.id - 1) % slotCount)
    local orbitSpeed = 0.8
    local baseAngle = (slotIndex / slotCount) * math.pi * 2
    local orbitAngle = baseAngle + love.timer.getTime() * orbitSpeed

    local targetX = self.player.position.x + math.cos(orbitAngle) * slotRadius
    local targetY = self.player.position.y + math.sin(orbitAngle) * slotRadius
    local resolvedX, resolvedY = self:findWalkableSpawnPosition(targetX, targetY)
    return resolvedX, resolvedY
end

function TestState:enemyAttack(enemy, distanceToPlayer)
    if not enemy.stats:canAttack() or not self.combatManager:canAttack(enemy.entity) then
        return
    end

    local facingDir = enemy.facingDirection
    local range = enemy.stats:getAttackRange()
    local offsetDistance = math.min(range * 0.5, distanceToPlayer * 0.5)
    local offsetX = math.cos(facingDir) * offsetDistance
    local offsetY = math.sin(facingDir) * offsetDistance

    local attackId = self.combatManager:registerAttack(enemy.entity, {
        range = range,
        damage = enemy.stats:getAttack(),
        cooldown = 1.0 / math.max(enemy.stats:getAttackSpeed(), 0.1),
        hitboxOffset = {x = offsetX, y = offsetY},
        hitboxSize = {width = range, height = math.max(24, range * 0.7)},
        duration = 0.25,
        knockback = 40,
        hitLimit = 1
    })

    if attackId then
        enemy:triggerAttackAnimation()
    end
end

function TestState:configureDemoCharacter(character, isEnemy)
    character:setInputManager(isEnemy and nil or self.game.input)
    character:setWorld(self.world)
    character:setCollisionChecker(function(instance, x, y)
        return self:canCharacterMoveTo(instance, x, y)
    end)
    character.hitbox.width = 24
    character.hitbox.height = 24
    character.visualScale = isEnemy and 1.1 or 1.15
end

function TestState:canCharacterMoveTo(character, x, y)
    local hitbox = character.hitbox
    if not hitbox then
        return true
    end

    local testPosition = {
        x = x,
        y = y
    }
    local bounds = hitbox:getBounds(testPosition)

    local inset = 6
    local samplePoints = {
        {x = bounds.left + inset, y = bounds.top + inset},
        {x = bounds.right - inset, y = bounds.top + inset},
        {x = bounds.left + inset, y = bounds.bottom - inset},
        {x = bounds.right - inset, y = bounds.bottom - inset},
        {x = bounds.centerX, y = bounds.centerY}
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

    -- Remove old player
    self.world:removeEntity(self.player.entity)

    -- Create new player with new class
    self.player = Character.new(classType, spawnX, spawnY)
    self:configureDemoCharacter(self.player, false)
    self.world:addEntity(self.player.entity)

    -- Update camera position
    self.camera:moveTo(self.player.position.x, self.player.position.y)

    -- Update class name
    self.currentClass = self:getClassLabel(classType)

    self:showNotice("Class: " .. self.currentClass)
    self:pulseCameraZoom()
    print("Switched to " .. self.currentClass)
end

function TestState:spawnTestEnemy()
    -- Spawn enemy near player
    local playerPos = self.player:getPosition()
    local angle = math.random() * math.pi * 2
    local distance = 200
    local x = playerPos.x + math.cos(angle) * distance
    local y = playerPos.y + math.sin(angle) * distance
    x, y = self:findWalkableSpawnPosition(x, y)

    local enemy = Character.new(Constants.CLASS.WARRIOR, x, y, {appearance = "orc"})
    enemy.hitbox.team = 'enemy'
    enemy.sprite.r = 0.9
    enemy.sprite.g = 0.3
    enemy.sprite.b = 0.3
    enemy.aiTimer = 0
    enemy.path = {}
    enemy.pathIndex = 1
    self:configureDemoCharacter(enemy, true)
    self.world:addEntity(enemy.entity)

    table.insert(self.enemies, enemy)
    print("Spawned enemy at", x, y)
end

function TestState:playerAttack()
    if not self.combatManager:canAttack(self.player.entity) then
        print("Attack on cooldown!")
        return
    end

    local stats = self.player.stats

    -- Check if class can attack
    if not stats:canAttack() then
        print("Engineer cannot attack!")
        return
    end

    -- Get attack direction
    local facingDir = self.player.facingDirection
    local range = stats:getAttackRange()

    -- Calculate hitbox offset based on facing direction
    local offsetX = math.cos(facingDir) * range / 2
    local offsetY = math.sin(facingDir) * range / 2

    -- Register attack
    local attackId = self.combatManager:registerAttack(self.player.entity, {
        range = range,
        damage = stats:getAttack(),
        cooldown = 1.0 / stats:getAttackSpeed(),
        hitboxOffset = {x = offsetX, y = offsetY},
        hitboxSize = {width = range, height = range / 2},
        duration = 0.3,
        knockback = 50,
        hitLimit = 10
    })

    if attackId then
        print("Attack!", attackId)
        self.player:triggerAttackAnimation()
        self:pulseCameraZoom()

        -- For ranged classes, spawn projectile
        if self.player.classType == Constants.CLASS.ARCHER then
            Projectile.createArrow(
                self.world,
                self.player.position.x,
                self.player.position.y,
                facingDir,
                self.player.entity,
                'player'
            )
        end
    end
end

function TestState:playerAbility()
    local classType = self.player.classType

    print("Using ability for " .. self.currentClass)

    if classType == Constants.CLASS.ARCHER then
        -- Volley - spawn multiple arrows
        local facingDir = self.player.facingDirection
        Projectile.createVolley(
            self.world,
            self.player.position.x,
            self.player.position.y,
            facingDir,
            self.player.entity,
            'player',
            5
        )
        print("Volley fired!")

    elseif classType == Constants.CLASS.WARRIOR then
        -- Shield Bash - large knockback attack
        local facingDir = self.player.facingDirection
        local range = 80

        local offsetX = math.cos(facingDir) * range / 2
        local offsetY = math.sin(facingDir) * range / 2

        self.combatManager:registerAttack(self.player.entity, {
            range = range,
            damage = self.player.stats:getAttack() * 1.5,
            cooldown = 8.0,
            hitboxOffset = {x = offsetX, y = offsetY},
            hitboxSize = {width = range, height = range},
            duration = 0.5,
            knockback = 300,
            hitLimit = 5
        })
        print("Shield Bash!")

    elseif classType == Constants.CLASS.SCOUT then
        -- Cloak - invulnerability
        self.player.health:setInvulnerable(3.0)
        self:showNotice("Scout Cloak")
        print("Cloaked for 3 seconds!")

    elseif classType == Constants.CLASS.ENGINEER then
        -- Heal
        self.player:heal(20)
        self:showNotice("Engineer Repair Burst")
        print("Healed 20 HP!")
    end
end

function TestState:keypressed(key, scancode, isrepeat)
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
    -- Cleanup
end

-- Store key states for wasPressed
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
