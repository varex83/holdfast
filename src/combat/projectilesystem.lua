-- Projectile System
-- Updates projectile movement, handles collisions, and applies damage

local System = require('src.ecs.system')
local EventBus = require('src.core.eventbus')
local Constants = require('data.constants')

local ProjectileSystem = System:extend()

function ProjectileSystem:new(world)
    ProjectileSystem.super.new(self, world)
    self.name = 'ProjectileSystem'
    return self
end

-- Update all projectiles
function ProjectileSystem:update(dt)
    local entitiesToRemove = {}

    -- Get all entities with projectile components
    for _, entity in ipairs(self.world:getEntitiesWithComponents({'position', 'velocity', 'projectiledata'})) do
        local position = entity:getComponent('position')
        local velocity = entity:getComponent('velocity')
        local projectileData = entity:getComponent('projectiledata')
        local sprite = entity:getComponent('sprite')
        local shouldContinue = false

        -- Update lifetime
        projectileData.currentLifetime = projectileData.currentLifetime + dt

        -- Check if expired
        if projectileData:hasExpired() then
            table.insert(entitiesToRemove, entity)
            EventBus.emit(Constants.EVENTS.PROJECTILE_EXPIRED, {
                projectile = entity,
                position = { x = position.x, y = position.y }
            })
            shouldContinue = true
        end

        if not shouldContinue then
            -- Apply gravity (optional)
            if projectileData.gravity > 0 then
                velocity.vy = velocity.vy + projectileData.gravity * dt
            end

            -- Apply homing (optional)
            if projectileData.homing and projectileData.homingTarget then
                local target = projectileData.homingTarget
                local targetPos = target:getComponent('position')

                if targetPos then
                    local dx = targetPos.x - position.x
                    local dy = targetPos.y - position.y
                    local targetAngle = math.atan2(dy, dx)
                    local currentAngle = velocity:getDirection()

                    -- Smoothly turn toward target
                    local angleDiff = targetAngle - currentAngle
                    -- Normalize angle to [-pi, pi]
                    if angleDiff > math.pi then angleDiff = angleDiff - 2 * math.pi end
                    if angleDiff < -math.pi then angleDiff = angleDiff + 2 * math.pi end

                    local turnSpeed = projectileData.homingStrength * dt
                    local newAngle = currentAngle + math.max(-turnSpeed, math.min(turnSpeed, angleDiff))

                    local speed = velocity:getSpeed()
                    velocity:setFromPolar(speed, newAngle)
                end
            end

            -- Update position
            position:move(velocity.vx * dt, velocity.vy * dt)

            -- Update sprite rotation to match direction
            if sprite then
                sprite:setRotation(velocity:getDirection())
            end

            -- Check collisions with other entities
            local hitbox = entity:getComponent('hitbox')
            if hitbox then
                local projectileBounds = hitbox:getBounds(position)

                -- Check all entities for collision
                for _, otherEntity in ipairs(self.world.entities) do
                    if not shouldContinue then
                        -- Don't collide with self or owner
                        if otherEntity.id ~= entity.id and
                           (not projectileData.owner or otherEntity.id ~= projectileData.owner.id) then

                            local otherHitbox = otherEntity:getComponent('hitbox')
                            local otherPosition = otherEntity:getComponent('position')

                            -- Check if other entity has hurtbox
                            if otherHitbox and otherPosition and otherHitbox.type == 'hurtbox' then
                                -- Check team (don't hit friendly entities)
                                if self:shouldCollide(hitbox.team, otherHitbox.team) then
                                    local otherBounds = otherHitbox:getBounds(otherPosition)

                                    -- AABB collision check
                                    if self:checkAABB(projectileBounds, otherBounds) then
                                        -- Can we hit this entity?
                                        if projectileData:canHit(otherEntity) then
                                            -- Apply damage
                                            self:applyDamage(entity, otherEntity, projectileData)

                                            -- Mark as hit
                                            projectileData:markHit(otherEntity)

                                            -- Emit hit event
                                            EventBus.emit(Constants.EVENTS.PROJECTILE_HIT, {
                                                projectile = entity,
                                                target = otherEntity,
                                                damage = projectileData.damage,
                                                position = { x = position.x, y = position.y }
                                            })

                                            -- Check if should despawn
                                            if projectileData:shouldDespawnOnHit() then
                                                table.insert(entitiesToRemove, entity)
                                                shouldContinue = true
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- Remove expired/hit projectiles
    for _, entity in ipairs(entitiesToRemove) do
        self.world:removeEntity(entity)
    end
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
