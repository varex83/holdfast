-- Projectile Factory
-- Creates projectile entities with all necessary components

local Entity = require('src.ecs.entity')
local Position = require('src.ecs.components.position')
local Velocity = require('src.ecs.components.velocity')
local Hitbox = require('src.ecs.components.hitbox')
local ProjectileData = require('src.ecs.components.projectiledata')
local Sprite = require('src.ecs.components.sprite')

local Projectile = {}

-- Create a generic projectile
function Projectile.create(world, config)
    config = config or {}

    -- Create entity
    local entity = Entity()

    -- Add Position component
    local position = Position.create(config.x or 0, config.y or 0, entity)
    entity:addComponent('position', position)

    -- Add Velocity component
    local speed = config.speed or 300
    local direction = config.direction or 0
    local velocity = Velocity.create(0, 0, entity)
    velocity:setFromPolar(speed, direction)
    entity:addComponent('velocity', velocity)

    -- Add Hitbox component
    local hitbox = Hitbox.create(
        config.hitboxWidth or 8,
        config.hitboxHeight or 8,
        0, 0,
        entity
    )
    hitbox.type = 'hitbox'
    hitbox.team = config.team or 'neutral'
    entity:addComponent('hitbox', hitbox)

    -- Add ProjectileData component
    local projectileData = ProjectileData.create({
        damage = config.damage or 10,
        owner = config.owner,
        team = config.team or 'neutral',
        lifetime = config.lifetime or 5.0,
        piercing = config.piercing or false,
        maxPierceCount = config.maxPierceCount or 1,
        gravity = config.gravity or 0,
        projectileType = config.projectileType or 'generic'
    }, entity)
    entity:addComponent('projectiledata', projectileData)

    -- Add Sprite component
    local sprite = Sprite.create({
        r = config.r or 1,
        g = config.g or 1,
        b = config.b or 1,
        a = config.a or 1,
        width = config.width or 8,
        height = config.height or 8,
        rotation = direction,
        shape = config.shape or 'rectangle',
        layer = config.layer or 5
    }, entity)
    entity:addComponent('sprite', sprite)

    -- Add to world
    if world then
        world:addEntity(entity)
    end

    return entity
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
function Projectile.createVolley(world, x, y, baseDirection, owner, team, arrowCount)
    arrowCount = arrowCount or 5
    local arcAngle = math.pi / 4  -- 45 degrees spread
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
