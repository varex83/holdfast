-- Character Controller
-- Handles character movement, state management, and basic collision

local Entity = require('src.ecs.entity')
local Position = require('src.ecs.components.position')
local Velocity = require('src.ecs.components.velocity')
local Stats = require('src.ecs.components.stats')
local Health = require('src.ecs.components.health')
local Hitbox = require('src.ecs.components.hitbox')
local Sprite = require('src.ecs.components.sprite')
local EventBus = require('src.core.eventbus')
local AssetManager = require("src.core.assetmanager")
local Constants = require('data.constants')
local Anim8 = require('lib.anim8')

local Character = {}
Character.__index = Character

-- Character states
Character.STATE = {
    IDLE = 'idle',
    WALKING = 'walking',
    ATTACKING = 'attacking',
    DEAD = 'dead'
}

-- Create a new character
function Character.new(classType, x, y, options)
    local self = setmetatable({}, Character)
    options = options or {}

    -- Create entity
    self.entity = Entity()

    -- Add Position component
    self.position = Position.create(x or 0, y or 0, self.entity)
    self.entity:addComponent('position', self.position)

    -- Add Velocity component
    self.velocity = Velocity.create(0, 0, self.entity)
    self.entity:addComponent('velocity', self.velocity)

    -- Add Stats component
    self.stats = Stats.forClass(classType, self.entity)
    self.entity:addComponent('stats', self.stats)

    -- Add Health component
    self.health = Health.fromStats(self.stats, self.entity)
    self.entity:addComponent('health', self.health)

    -- Add Hitbox component (hurtbox for receiving damage)
    self.hitbox = Hitbox.create(32, 32, 0, 0, self.entity)
    self.hitbox.type = 'hurtbox'
    self.hitbox.team = 'player'
    self.entity:addComponent('hitbox', self.hitbox)

    -- Add Sprite component
    self.sprite = Sprite.create({
        width = 32,
        height = 32,
        r = 0.3,
        g = 0.6,
        b = 0.9,
        shape = 'rectangle',
        layer = 3
    }, self.entity)
    self.entity:addComponent('sprite', self.sprite)
    if options.tint then
        self.sprite:setColor(
            options.tint[1] or self.sprite.r,
            options.tint[2] or self.sprite.g,
            options.tint[3] or self.sprite.b,
            options.tint[4] or self.sprite.a
        )
    end

    -- Character state
    self.state = Character.STATE.IDLE
    self.classType = classType
    self.appearance = options.appearance or "soldier"

    -- Movement
    self.moveDirection = {x = 0, y = 0}
    self.isMoving = false

    -- Facing direction (in radians)
    self.facingDirection = 0
    self.animationSpeedScale = 1
    self.attackTimer = 0
    self.attackDuration = 0.35
    self.visualScale = 1.0
    self.baseVisualScale = 1.0
    self.drawOffsetY = 14
    self.drawOriginX = 50
    self.drawOriginY = 60
    self.baseDrawOffsetY = self.drawOffsetY
    self.baseHitbox = {
        width = self.hitbox.width,
        height = self.hitbox.height,
        offsetX = self.hitbox.offsetX,
        offsetY = self.hitbox.offsetY,
    }

    -- Input reference (will be set externally)
    self.inputManager = nil

    -- World reference (for collision detection)
    self.world = nil
    self.collisionChecker = nil

    self:setupVisuals()

    return self
end

local function buildAnimation(setDef, stateDef, image)
    local grid = Anim8.newGrid(setDef.frameWidth, setDef.frameHeight, image:getDimensions())
    return Anim8.newAnimation(grid(stateDef.frames, stateDef.row or 1), stateDef.frameDuration or 0.1)
end

function Character:setupVisuals()
    local assets = AssetManager.getCurrent()
    local setDef = assets:getAnimationSet("appearance." .. self.appearance)

    self.visuals = {
        config = setDef,
        images = {
            idle = assets:getImage(setDef.states.idle.image),
            walk = assets:getImage(setDef.states.walk.image),
            attack = assets:getImage(setDef.states.attack.image)
        }
    }

    self.visuals.animations = {
        idle = buildAnimation(setDef, setDef.states.idle, self.visuals.images.idle),
        walk = buildAnimation(setDef, setDef.states.walk, self.visuals.images.walk),
        attack = buildAnimation(setDef, setDef.states.attack, self.visuals.images.attack)
    }

    self.drawOffsetY = setDef.drawOffsetY or self.drawOffsetY
    self.drawOriginX = setDef.drawOriginX or self.drawOriginX
    self.drawOriginY = setDef.drawOriginY or self.drawOriginY
    self.baseDrawOffsetY = self.drawOffsetY
    self.baseVisualScale = setDef.visualScale or self.visualScale
    self.visualScale = self.baseVisualScale

    if setDef.hitbox then
        self.baseHitbox.width = setDef.hitbox.width or self.baseHitbox.width
        self.baseHitbox.height = setDef.hitbox.height or self.baseHitbox.height
        self.baseHitbox.offsetX = setDef.hitbox.offsetX or self.baseHitbox.offsetX
        self.baseHitbox.offsetY = setDef.hitbox.offsetY or self.baseHitbox.offsetY
    end

    self:refreshScaledCollision()

    self.visuals.current = "idle"
end

function Character:refreshScaledCollision()
    local scaleRatio = self.baseVisualScale ~= 0 and (self.visualScale / self.baseVisualScale) or 1
    self.hitbox.width = self.baseHitbox.width * scaleRatio
    self.hitbox.height = self.baseHitbox.height * scaleRatio
    self.hitbox.offsetX = self.baseHitbox.offsetX * scaleRatio
    self.hitbox.offsetY = self.baseHitbox.offsetY * scaleRatio
    self.drawOffsetY = self.baseDrawOffsetY * scaleRatio
end

function Character:setVisualScale(scale)
    self.visualScale = scale or self.baseVisualScale or 1
    self:refreshScaledCollision()
end

function Character:setDesiredMovement(x, y)
    local length = math.sqrt(x * x + y * y)
    if length > 0 then
        self.moveDirection.x = x / length
        self.moveDirection.y = y / length
        self.isMoving = true
        self.facingDirection = math.atan2(self.moveDirection.y, self.moveDirection.x)
    else
        self.moveDirection.x = 0
        self.moveDirection.y = 0
        self.isMoving = false
    end
end

function Character:triggerAttackAnimation()
    self.attackTimer = self.attackDuration
    self.state = Character.STATE.ATTACKING
    if self.visuals and self.visuals.animations.attack then
        self.visuals.animations.attack:gotoFrame(1)
    end
end

-- Set input manager
function Character:setInputManager(inputManager)
    self.inputManager = inputManager
end

-- Set world reference
function Character:setWorld(world)
    self.world = world
end

function Character:setCollisionChecker(collisionChecker)
    self.collisionChecker = collisionChecker
end

-- Update character
function Character:update(dt)
    if not self.entity:isAlive() then
        self.state = Character.STATE.DEAD
        return
    end

    if self.attackTimer > 0 then
        self.attackTimer = math.max(0, self.attackTimer - dt)
        if self.attackTimer == 0 and self.state == Character.STATE.ATTACKING then
            self.state = self.isMoving and Character.STATE.WALKING or Character.STATE.IDLE
        end
    end

    -- Update health regeneration
    if self.health then
        self.health:update(dt)
    end

    -- Handle input and movement
    if self.inputManager then
        self:handleInput(dt)
    end

    -- Update velocity based on movement
    self:updateMovement(dt)

    -- Apply velocity to position (with collision)
    self:applyVelocity(dt)

    -- Update state
    self:updateState()
    self:updateVisuals(dt)
end

-- Handle input
function Character:handleInput(dt)
    -- Get movement input (returns x, y)
    local mx, my = self.inputManager:getMoveVector()

    -- Normalize diagonal movement
    local length = math.sqrt(mx * mx + my * my)
    if length > 0 then
        self.moveDirection.x = mx / length
        self.moveDirection.y = my / length
        self.isMoving = true

        -- Update facing direction
        self.facingDirection = math.atan2(my, mx)
    else
        self.moveDirection.x = 0
        self.moveDirection.y = 0
        self.isMoving = false
    end
end

-- Update movement velocity
function Character:updateMovement(dt)
    if self.state == Character.STATE.DEAD or self.state == Character.STATE.ATTACKING then
        -- Stop movement when dead or attacking
        self.velocity.vx = 0
        self.velocity.vy = 0
        return
    end

    if self.isMoving then
        local speed = self.stats:getSpeed()
        self.velocity.vx = self.moveDirection.x * speed
        self.velocity.vy = self.moveDirection.y * speed
    else
        -- Apply friction
        local friction = 10
        self.velocity.vx = self.velocity.vx * math.max(0, 1 - friction * dt)
        self.velocity.vy = self.velocity.vy * math.max(0, 1 - friction * dt)

        -- Stop if velocity is very small
        if math.abs(self.velocity.vx) < 1 then self.velocity.vx = 0 end
        if math.abs(self.velocity.vy) < 1 then self.velocity.vy = 0 end
    end
end

-- Apply velocity to position with collision detection
function Character:applyVelocity(dt)
    if self.velocity.vx == 0 and self.velocity.vy == 0 then
        return
    end

    -- Calculate new position
    local newX = self.position.x + self.velocity.vx * dt
    local newY = self.position.y + self.velocity.vy * dt

    -- Check collision with world tiles
    if self:canMoveTo(newX, newY) then
        self.position.x = newX
        self.position.y = newY
    else
        -- Try sliding along walls
        -- Try X movement only
        if self:canMoveTo(newX, self.position.y) then
            self.position.x = newX
        end

        -- Try Y movement only
        if self:canMoveTo(self.position.x, newY) then
            self.position.y = newY
        end
    end
end

-- Check if character can move to position
function Character:canMoveTo(x, y)
    if self.collisionChecker then
        return self.collisionChecker(self, x, y)
    end

    -- TODO: Implement proper tile collision when world/chunk system is ready
    return true
end

-- Update character state
function Character:updateState()
    if not self.entity:isAlive() then
        self.state = Character.STATE.DEAD
        return
    end

    if self.state == Character.STATE.ATTACKING and self.attackTimer > 0 then
        -- Stay in attacking state until animation finishes
        return
    end

    if self.isMoving then
        self.state = Character.STATE.WALKING
    else
        self.state = Character.STATE.IDLE
    end
end

function Character:updateVisuals(dt)
    if not self.visuals then
        return
    end

    if self.state == Character.STATE.ATTACKING then
        self.visuals.current = "attack"
    elseif self.isMoving then
        self.visuals.current = "walk"
    else
        self.visuals.current = "idle"
    end

    local animation = self.visuals.animations[self.visuals.current]
    if animation then
        animation:update(dt * self.animationSpeedScale)
    end
end

-- Start attack
function Character:attack()
    if self.state == Character.STATE.DEAD then
        return false
    end

    if not self.stats:canAttack() then
        return false
    end

    self:triggerAttackAnimation()

    -- Broadcast attack event
    EventBus.emit(Constants.EVENTS.PLAYER_ATTACK, {
        entity = self.entity,
        position = {x = self.position.x, y = self.position.y},
        direction = self.facingDirection,
        classType = self.classType
    })

    return true
end

function Character:draw()
    if not self:isAlive() then
        return
    end

    if not self.visuals then
        love.graphics.setColor(self.sprite.r, self.sprite.g, self.sprite.b, self.sprite.a)
        love.graphics.rectangle('fill', self.position.x - 16, self.position.y - 16, 32, 32)
        love.graphics.setColor(1, 1, 1, 1)
        return
    end

    local image = self.visuals.images[self.visuals.current]
    local animation = self.visuals.animations[self.visuals.current]
    local scaleX = self.visualScale
    if math.cos(self.facingDirection) < -0.1 then
        scaleX = -scaleX
    end

    love.graphics.setColor(self.sprite.r, self.sprite.g, self.sprite.b, self.sprite.a)
    animation:draw(
        image,
        self.position.x,
        self.position.y + self.drawOffsetY,
        0,
        scaleX,
        self.visualScale,
        self.drawOriginX,
        self.drawOriginY
    )
    love.graphics.setColor(1, 1, 1, 1)
end

-- Use ability
function Character:useAbility()
    if self.state == Character.STATE.DEAD then
        return false
    end

    -- Broadcast ability event
    EventBus.emit(Constants.EVENTS.PLAYER_ABILITY, {
        entity = self.entity,
        position = {x = self.position.x, y = self.position.y},
        direction = self.facingDirection,
        classType = self.classType
    })

    return true
end

-- Take damage
function Character:takeDamage(amount)
    if self.health then
        return self.health:takeDamage(amount)
    end
    return 0
end

-- Heal
function Character:heal(amount)
    if self.health then
        return self.health:heal(amount)
    end
    return 0
end

-- Check if alive
function Character:isAlive()
    return self.entity:isAlive()
end

-- Get position
function Character:getPosition()
    return {x = self.position.x, y = self.position.y}
end

-- Set position
function Character:setPosition(x, y)
    self.position.x = x
    self.position.y = y
end

-- Get state
function Character:getState()
    return self.state
end

-- Get class type
function Character:getClassType()
    return self.classType
end

-- Render debug info
function Character:drawDebug()
    love.graphics.setColor(0, 1, 0, 0.5)

    -- Draw hitbox
    if self.hitbox and self.position then
        local bounds = self.hitbox:getBounds(self.position)
        love.graphics.rectangle('line',
            bounds.left, bounds.top,
            bounds.right - bounds.left,
            bounds.bottom - bounds.top
        )
    end

    -- Draw facing direction
    love.graphics.setColor(1, 1, 0, 1)
    local dirLength = 30
    local endX = self.position.x + math.cos(self.facingDirection) * dirLength
    local endY = self.position.y + math.sin(self.facingDirection) * dirLength
    love.graphics.line(self.position.x, self.position.y, endX, endY)

    -- Draw state
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(self.state, self.position.x - 20, self.position.y - 50)

    love.graphics.setColor(1, 1, 1, 1)
end

return Character
