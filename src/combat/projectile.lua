-- Projectile Factory
-- Creates projectile entities with all necessary components

local Entity = require('src.ecs.entity')
local Position = require('src.ecs.components.position')
local Velocity = require('src.ecs.components.velocity')
local Hitbox = require('src.ecs.components.hitbox')
local ProjectileData = require('src.ecs.components.projectiledata')
local Sprite = require('src.ecs.components.sprite')

local Projectile = {}

-- Get default projectile configuration
local function getDefaultConfig()
    return {
        x = 0,
        y = 0,
        speed = 300,
        direction = 0,
        hitboxWidth = 8,
        hitboxHeight = 8,
        team = 'neutral',
        damage = 10,
        lifetime = 5.0,
        piercing = false,
        maxPierceCount = 1,
        gravity = 0,
        projectileType = 'generic',
        r = 1,
        g = 1,
        b = 1,
        a = 1,
        width = 8,
        height = 8,
        shape = 'rectangle',
        layer = 5
    }
end

-- Merge user config with defaults
local function mergeConfig(config)
    local defaults = getDefaultConfig()
    config = config or {}

    for key, value in pairs(defaults) do
        if config[key] == nil then
            config[key] = value
        end
    end

    return config
end

-- Create a generic projectile
function Projectile.create(world, userConfig)
    local config = mergeConfig(userConfig)
    local entity = Entity()

    Projectile.addPositionComponent(entity, config)
    Projectile.addVelocityComponent(entity, config)
    Projectile.addHitboxComponent(entity, config)
    Projectile.addProjectileDataComponent(entity, config)
    Projectile.addSpriteComponent(entity, config)

    if world then
        world:addEntity(entity)
    end

    return entity
end

-- Add Position component
function Projectile.addPositionComponent(entity, config)
    local position = Position.create(config.x, config.y, entity)
    entity:addComponent('position', position)
end

-- Add Velocity component
function Projectile.addVelocityComponent(entity, config)
    local velocity = Velocity.create(0, 0, entity)
    velocity:setFromPolar(config.speed, config.direction)
    entity:addComponent('velocity', velocity)
end

-- Add Hitbox component
function Projectile.addHitboxComponent(entity, config)
    local hitbox = Hitbox.create(
        config.hitboxWidth,
        config.hitboxHeight,
        0, 0,
        entity
    )
    hitbox.type = 'hitbox'
    hitbox.team = config.team
    entity:addComponent('hitbox', hitbox)
end

-- Add ProjectileData component
function Projectile.addProjectileDataComponent(entity, config)
    local projectileData = ProjectileData.create({
        damage = config.damage,
        owner = config.owner,
        team = config.team,
        lifetime = config.lifetime,
        piercing = config.piercing,
        maxPierceCount = config.maxPierceCount,
        gravity = config.gravity,
        projectileType = config.projectileType
    }, entity)
    entity:addComponent('projectiledata', projectileData)
end

-- Add Sprite component
function Projectile.addSpriteComponent(entity, config)
    local sprite = Sprite.create({
        r = config.r,
        g = config.g,
        b = config.b,
        a = config.a,
        width = config.width,
        height = config.height,
        rotation = config.direction,
        shape = config.shape,
        layer = config.layer
    }, entity)
    entity:addComponent('sprite', sprite)
end

-- Create an arrow projectile (Archer)
function Projectile.createArrow(world, x, y, direction, owner, team)
    return Projectile.create(world, {
        x = x,
        y = y,
        direction = direction,
        speed = 400,
        damage = 15,
        owner = owner,
        team = team or 'player',
        hitboxWidth = 6,
        hitboxHeight = 6,
        width = 16,
        height = 4,
        r = 0.6,
        g = 0.4,
        b = 0.2,
        shape = 'rectangle',
        lifetime = 3.0,
        projectileType = 'arrow'
    })
end

-- Create a spit projectile (Spitter enemy)
function Projectile.createSpit(world, x, y, direction, owner, team)
    return Projectile.create(world, {
        x = x,
        y = y,
        direction = direction,
        speed = 250,
        damage = 8,
        owner = owner,
        team = team or 'enemy',
        hitboxWidth = 10,
        hitboxHeight = 10,
        width = 10,
        height = 10,
        r = 0.2,
        g = 0.8,
        b = 0.2,
        a = 0.8,
        shape = 'circle',
        lifetime = 4.0,
        gravity = 50,
        projectileType = 'spit'
    })
end

-- Create multiple arrows in an arc (Archer's Volley ability)
function Projectile.createVolley(world, x, y, baseDirection, owner, team, arrowCount, arcAngle)
    arrowCount = arrowCount or 5
    arcAngle = arcAngle or math.pi / 4
    local angleStep = arcAngle / (arrowCount - 1)
    local startAngle = baseDirection - arcAngle / 2

    local arrows = {}

    for i = 1, arrowCount do
        local direction = startAngle + (i - 1) * angleStep
        local arrow = Projectile.createArrow(world, x, y, direction, owner, team)
        table.insert(arrows, arrow)
    end

    return arrows
end

-- Create a projectile from entity position toward target
function Projectile.createTowardTarget(world, config, targetX, targetY)
    local dx = targetX - config.x
    local dy = targetY - config.y
    local direction = math.atan2(dy, dx)

    config.direction = direction
    return Projectile.create(world, config)
end

return Projectile
