-- ProjectileData Component
-- Stores projectile-specific data (damage, lifetime, owner, etc.)

local Component = require('src.ecs.component')

local ProjectileData = {}

-- Create a ProjectileData component
function ProjectileData.create(config, entity)
    local component = {
        type = 'projectiledata',
        entity = entity
    }

    config = config or {}

    -- Damage dealt on hit
    component.damage = config.damage or 10

    -- Owner entity (who fired the projectile)
    component.owner = config.owner

    -- Team (for collision filtering)
    component.team = config.team or 'neutral'

    -- Lifetime in seconds
    component.maxLifetime = config.lifetime or 5.0
    component.currentLifetime = 0

    -- Piercing (can hit multiple targets)
    component.piercing = config.piercing or false
    component.maxPierceCount = config.maxPierceCount or 1
    component.pierceCount = 0

    -- Entities already hit (prevents hitting same entity multiple times)
    component.hitEntities = {}

    -- Gravity (optional, for arc projectiles)
    component.gravity = config.gravity or 0

    -- Homing (optional, for guided projectiles)
    component.homing = config.homing or false
    component.homingTarget = config.homingTarget
    component.homingStrength = config.homingStrength or 0

    -- Projectile type (for special behaviors)
    component.projectileType = config.projectileType or 'generic'

    -- Mark this entity as a projectile
    component.isProjectile = true

    -- Check if projectile has expired
    function component:hasExpired()
        return self.currentLifetime >= self.maxLifetime
    end

    -- Check if can hit target
    function component:canHit(targetEntity)
        -- Already hit this entity
        if self.hitEntities[targetEntity.id] then
            return false
        end

        -- Piercing check
        if not self.piercing and self.pierceCount >= self.maxPierceCount then
            return false
        end

        return true
    end

    -- Mark entity as hit
    function component:markHit(targetEntity)
        self.hitEntities[targetEntity.id] = true
        self.pierceCount = self.pierceCount + 1
    end

    -- Check if should despawn after hit
    function component:shouldDespawnOnHit()
        return not self.piercing or self.pierceCount >= self.maxPierceCount
    end

    return component
end

return ProjectileData
