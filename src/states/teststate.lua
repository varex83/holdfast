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

local TestState = Class:extend()

function TestState:new(game)
    self.game = game
    self.name = 'test'
end

function TestState:enter()
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

    -- Combat manager
    self.combatManager = CombatManager.new(self.world, EventBus)

    -- Projectile system
    self.projectileSystem = ProjectileSystem(self.world)
    self.world:addSystem(self.projectileSystem)

    -- Create camera
    local Camera = require("src.core.camera")
    local sw, sh = love.graphics.getDimensions()
    self.camera = Camera(sw, sh)

    -- Create player character (Warrior by default)
    self.player = Character.new(Constants.CLASS.WARRIOR, 400, 300)
    self.player:setInputManager(self.game.input)
    self.player:setWorld(self.world)
    self.world:addEntity(self.player.entity)

    -- Test enemies (for combat testing)
    self.enemies = {}

    -- Set camera to follow player
    self.camera:moveTo(self.player.position.x, self.player.position.y)

    -- Debug mode
    self.debugMode = false

    -- Attack cooldown display
    self.lastAttackTime = 0
    self.attackCooldown = 1.0

    -- UI info
    self.currentClass = "Warrior"

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
        enemy:update(dt)
    end

    -- Update combat manager
    self.combatManager:update(dt)

    -- Update world (projectiles)
    self.world:update(dt)

    -- Update camera to follow player
    local targetX = self.player.position.x
    local targetY = self.player.position.y
    local lerpFactor = 5 * dt  -- Smooth camera follow
    self.camera.x = self.camera.x + (targetX - self.camera.x) * lerpFactor
    self.camera.y = self.camera.y + (targetY - self.camera.y) * lerpFactor

    -- Update camera
    self.camera:update(dt)
end

function TestState:draw()
    -- Apply camera transform
    self.camera:apply()

    -- Draw grid
    self:drawGrid()

    -- Draw player
    self:drawCharacter(self.player, {r=0.3, g=0.6, b=0.9})

    -- Draw enemies
    for _, enemy in ipairs(self.enemies) do
        self:drawCharacter(enemy, {r=0.9, g=0.3, b=0.3})
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

function TestState:drawCharacter(character, color)
    if not character:isAlive() then
        return
    end

    local pos = character:getPosition()
    local size = 32

    -- Draw body
    love.graphics.setColor(color.r, color.g, color.b, 1)
    love.graphics.rectangle('fill', pos.x - size/2, pos.y - size/2, size, size)

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

    love.graphics.setColor(1, 1, 1, 1)
end

function TestState:switchClass(classType)
    local pos = self.player:getPosition()

    -- Remove old player
    self.world:removeEntity(self.player.entity)

    -- Create new player with new class
    self.player = Character.new(classType, pos.x, pos.y)
    self.player:setInputManager(self.game.input)
    self.player:setWorld(self.world)
    self.world:addEntity(self.player.entity)

    -- Update camera position
    self.camera:moveTo(self.player.position.x, self.player.position.y)

    -- Update class name
    if classType == Constants.CLASS.WARRIOR then
        self.currentClass = "Warrior"
    elseif classType == Constants.CLASS.ARCHER then
        self.currentClass = "Archer"
    elseif classType == Constants.CLASS.ENGINEER then
        self.currentClass = "Engineer"
    elseif classType == Constants.CLASS.SCOUT then
        self.currentClass = "Scout"
    end

    print("Switched to " .. self.currentClass)
end

function TestState:spawnTestEnemy()
    -- Spawn enemy near player
    local playerPos = self.player:getPosition()
    local angle = math.random() * math.pi * 2
    local distance = 200
    local x = playerPos.x + math.cos(angle) * distance
    local y = playerPos.y + math.sin(angle) * distance

    local enemy = Character.new(Constants.CLASS.WARRIOR, x, y)
    enemy.hitbox.team = 'enemy'
    enemy.sprite.r = 0.9
    enemy.sprite.g = 0.3
    enemy.sprite.b = 0.3
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
        print("Cloaked for 3 seconds!")

    elseif classType == Constants.CLASS.ENGINEER then
        -- Heal
        self.player:heal(20)
        print("Healed 20 HP!")
    end
end

function TestState:keypressed(key, scancode, isrepeat)
    -- Track key presses for wasPressed function
    if not self.pressedKeys then
        self.pressedKeys = {}
    end
    self.pressedKeys[key] = true
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
