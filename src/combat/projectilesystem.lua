-- Projectile System
-- Updates projectile movement, handles collisions, and applies damage

local System = require('src.ecs.system')
local EventBus = require('src.core.eventbus')
local Constants = require('data.constants')

local ProjectileSystem = System:extend()

function ProjectileSystem:new(world, collisionManager)
    ProjectileSystem.super.new(self, world)
    self.name = 'ProjectileSystem'
    self.collisionManager = collisionManager -- Optional: uses bump.lua for spatial partitioning
    return self
end

-- Update all projectiles
function ProjectileSystem:update(dt)
    -- Sync collision manager with world entities if using spatial partitioning
    if self.collisionManager then
        self:syncCollisionManager()
    end

    local entitiesToRemove = {}

    for _, entity in ipairs(self.world:getEntitiesWithComponents({'position', 'velocity', 'projectiledata'})) do
        local shouldRemove = self:updateProjectile(entity, dt, entitiesToRemove)
        if shouldRemove then
            table.insert(entitiesToRemove, entity)
        end
    end

    -- Remove expired/hit projectiles
    for _, entity in ipairs(entitiesToRemove) do
        -- Remove from collision manager first
        if self.collisionManager then
            self.collisionManager:removeEntity(entity)
        end
        self.world:removeEntity(entity)
    end
end

-- Sync collision manager with ECS world
function ProjectileSystem:syncCollisionManager()
    if not self.collisionManager then
        return
    end

    -- Add new entities with hitboxes to collision manager
    local entities = self.world:getEntitiesWithComponents({'position', 'hitbox'})
    for _, entity in ipairs(entities) do
        if not self.collisionManager:hasEntity(entity) then
            self.collisionManager:addEntity(entity)
        else
            -- Update existing entity positions
            self.collisionManager:updateEntity(entity)
        end
    end
end

-- Update a single projectile
function ProjectileSystem:updateProjectile(entity, dt, entitiesToRemove)
    local position = entity:getComponent('position')
    local velocity = entity:getComponent('velocity')
    local projectileData = entity:getComponent('projectiledata')
    local sprite = entity:getComponent('sprite')

    -- Update lifetime
    projectileData.currentLifetime = projectileData.currentLifetime + dt

    -- Check if expired
    if projectileData:hasExpired() then
        self:emitExpiredEvent(entity, position)
        return true
    end

    self:applyPhysics(velocity, projectileData, dt)
    self:applyHoming(position, velocity, projectileData, dt)

    -- Update position
    position:move(velocity.vx * dt, velocity.vy * dt)

    -- Update sprite rotation
    if sprite then
        sprite:setRotation(velocity:getDirection())
    end

    -- Check collisions
    return self:checkProjectileCollisions(entity, position, projectileData)
end

-- Emit projectile expired event
function ProjectileSystem:emitExpiredEvent(entity, position)
    EventBus.emit(Constants.EVENTS.PROJECTILE_EXPIRED, {
        projectile = entity,
        position = { x = position.x, y = position.y }
    })
end

-- Apply gravity to projectile
function ProjectileSystem:applyPhysics(velocity, projectileData, dt)
    if projectileData.gravity > 0 then
        velocity.vy = velocity.vy + projectileData.gravity * dt
    end
end

-- Apply homing behavior
function ProjectileSystem:applyHoming(position, velocity, projectileData, dt)
    if not projectileData.homing or not projectileData.homingTarget then
        return
    end

    local targetPos = projectileData.homingTarget:getComponent('position')
    if not targetPos then
        return
    end

    local dx = targetPos.x - position.x
    local dy = targetPos.y - position.y
    local targetAngle = math.atan2(dy, dx)
    local currentAngle = velocity:getDirection()

    -- Normalize angle to [-pi, pi]
    local angleDiff = targetAngle - currentAngle
    if angleDiff > math.pi then angleDiff = angleDiff - 2 * math.pi end
    if angleDiff < -math.pi then angleDiff = angleDiff + 2 * math.pi end

    local turnSpeed = projectileData.homingStrength * dt
    local newAngle = currentAngle + math.max(-turnSpeed, math.min(turnSpeed, angleDiff))

    local speed = velocity:getSpeed()
    velocity:setFromPolar(speed, newAngle)
end

-- Check projectile collisions with all entities
function ProjectileSystem:checkProjectileCollisions(entity, position, projectileData)
    -- Use optimized spatial partitioning if collision manager available
    if self.collisionManager then
        return self:checkProjectileCollisionsOptimized(entity, position, projectileData)
    end

    -- Fallback to brute force collision checking
    local hitbox = entity:getComponent('hitbox')
    if not hitbox then
        return false
    end

    local projectileBounds = hitbox:getBounds(position)

    for _, otherEntity in ipairs(self.world.entities) do
        if self:shouldCheckCollision(entity, otherEntity, projectileData) then
            local hit = self:checkEntityCollision(entity, otherEntity, hitbox, projectileBounds, position, projectileData)
            if hit then
                return true
            end
        end
    end

    return false
end

-- Optimized collision check using bump.lua spatial partitioning
function ProjectileSystem:checkProjectileCollisionsOptimized(entity, position, projectileData)
    local hitbox = entity:getComponent('hitbox')
    if not hitbox then
        return false
    end

    -- Create filter function for bump.lua queries
    local function collisionFilter(item, other)
        if not self:shouldCheckCollision(item, other, projectileData) then
            return false
        end

        local otherHitbox = other:getComponent('hitbox')
        if not otherHitbox or otherHitbox.type ~= 'hurtbox' then
            return false
        end

        if not self:shouldCollide(hitbox.team, otherHitbox.team) then
            return false
        end

        return true
    end

    -- Query nearby entities using spatial partitioning
    local nearbyEntities = self.collisionManager:getCollisions(entity, collisionFilter)

    -- Check collisions with filtered nearby entities
    local projectileBounds = hitbox:getBounds(position)
    for _, otherEntity in ipairs(nearbyEntities) do
        if projectileData:canHit(otherEntity) then
            -- Apply damage and effects
            self:applyDamage(entity, otherEntity, projectileData)
            projectileData:markHit(otherEntity)

            EventBus.emit(Constants.EVENTS.PROJECTILE_HIT, {
                projectile = entity,
                target = otherEntity,
                damage = projectileData.damage,
                position = { x = position.x, y = position.y }
            })

            if projectileData:shouldDespawnOnHit() then
                return true
            end
        end
    end

    return false
end

-- Check if should check collision between projectile and entity
function ProjectileSystem:shouldCheckCollision(entity, otherEntity, projectileData)
    if otherEntity.id == entity.id then
        return false
    end

    if projectileData.owner and otherEntity.id == projectileData.owner.id then
        return false
    end

    return true
end

-- Check collision between projectile and a single entity
function ProjectileSystem:checkEntityCollision(entity, otherEntity, hitbox, projectileBounds, position, projectileData)
    local otherHitbox = otherEntity:getComponent('hitbox')
    local otherPosition = otherEntity:getComponent('position')

    if not otherHitbox or not otherPosition or otherHitbox.type ~= 'hurtbox' then
        return false
    end

    if not self:shouldCollide(hitbox.team, otherHitbox.team) then
        return false
    end

    local otherBounds = otherHitbox:getBounds(otherPosition)
    if not self:checkAABB(projectileBounds, otherBounds) then
        return false
    end

    if not projectileData:canHit(otherEntity) then
        return false
    end

    -- Apply damage and effects
    self:applyDamage(entity, otherEntity, projectileData)
    projectileData:markHit(otherEntity)

    EventBus.emit(Constants.EVENTS.PROJECTILE_HIT, {
        projectile = entity,
        target = otherEntity,
        damage = projectileData.damage,
        position = { x = position.x, y = position.y }
    })

    return projectileData:shouldDespawnOnHit()
end

-- Check if two teams should collide
function ProjectileSystem:shouldCollide(team1, team2)
    if not team1 or not team2 then
        return true
    end

    -- Same team doesn't collide
    if team1 == team2 then
        return false
    end

    -- Player projectiles hit enemies, and vice versa
    if (team1 == 'player' and team2 == 'enemy') or
       (team1 == 'enemy' and team2 == 'player') then
        return true
    end

    -- Neutral hits everything
    if team1 == 'neutral' or team2 == 'neutral' then
        return true
    end

    return false
end

-- AABB collision check
function ProjectileSystem:checkAABB(bounds1, bounds2)
    return not (
        bounds1.right < bounds2.left or
        bounds1.left > bounds2.right or
        bounds1.bottom < bounds2.top or
        bounds1.top > bounds2.bottom
    )
end

-- Apply damage to target
function ProjectileSystem:applyDamage(projectileEntity, targetEntity, projectileData)
    local health = targetEntity:getComponent('health')
    local stats = targetEntity:getComponent('stats')

    local damage = projectileData.damage

    -- Apply armor reduction if target has stats
    if stats then
        damage = stats:calculateDamageAfterArmor(damage)
    end

    -- Apply damage to health component
    if health then
        health:takeDamage(damage)
    elseif stats then
        -- Fallback to stats component if no health component
        stats:takeDamage(damage)
    end
end

-- Render projectiles
function ProjectileSystem:render()
    local entities = self.world:getEntitiesWithComponents({'position', 'sprite'})

    for _, entity in ipairs(entities) do
        -- Only render projectiles
        local projectileData = entity:getComponent('projectiledata')
        if projectileData then
            local position = entity:getComponent('position')
            local sprite = entity:getComponent('sprite')

            if sprite and sprite.visible then
                love.graphics.push()
                love.graphics.translate(position.x, position.y)
                love.graphics.rotate(sprite.rotation)
                love.graphics.scale(sprite.scaleX, sprite.scaleY)

                -- Set color
                love.graphics.setColor(sprite.r, sprite.g, sprite.b, sprite.a)

                -- Draw shape
                if sprite.shape == 'rectangle' then
                    love.graphics.rectangle('fill', -sprite.width/2, -sprite.height/2, sprite.width, sprite.height)
                elseif sprite.shape == 'circle' then
                    love.graphics.circle('fill', 0, 0, sprite.width/2)
                elseif sprite.shape == 'triangle' then
                    love.graphics.polygon('fill',
                        sprite.width/2, 0,
                        -sprite.width/2, sprite.height/2,
                        -sprite.width/2, -sprite.height/2
                    )
                end

                love.graphics.pop()

                -- Debug: Draw hitbox
                if love.keyboard.isDown('f3') then
                    local hitbox = entity:getComponent('hitbox')
                    if hitbox then
                        local bounds = hitbox:getBounds(position)
                        love.graphics.setColor(1, 0, 0, 0.3)
                        love.graphics.rectangle('line',
                            bounds.left, bounds.top,
                            bounds.right - bounds.left,
                            bounds.bottom - bounds.top
                        )
                    end
                end
            end
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return ProjectileSystem
