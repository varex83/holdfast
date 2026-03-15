-- Health Component
-- Manages entity health, damage, death, and regeneration

local Component = require('src.ecs.component')
local EventBus = require('src.core.eventbus')
local Constants = require('data.constants')

local Health = {}

-- Create a Health component
function Health.create(maxHp, entity)
    local component = {
        type = 'health',
        entity = entity
    }

    -- Health values
    component.maxHp = maxHp or 100
    component.currentHp = maxHp or 100

    -- Regeneration
    component.regenRate = 0  -- HP per second
    component.regenDelay = 5.0  -- Seconds after taking damage before regen starts
    component.timeSinceDamage = 0

    -- Death state
    component.isDead = false

    -- Invulnerability (temporary)
    component.isInvulnerable = false
    component.invulnerabilityDuration = 0

    -- Take damage
    function component:takeDamage(amount)
        if self.isInvulnerable or self.isDead then
            return 0
        end

        local oldHp = self.currentHp
        self.currentHp = math.max(0, self.currentHp - amount)
        local actualDamage = oldHp - self.currentHp

        -- Reset regen timer
        self.timeSinceDamage = 0

        -- Broadcast damage event
        EventBus.emit(Constants.EVENTS.ENTITY_DAMAGED, {
            entity = entity,
            damage = actualDamage,
            currentHp = self.currentHp,
            maxHp = self.maxHp
        })

        -- Check for death
        if self.currentHp <= 0 and not self.isDead then
            self:die()
        end

        return actualDamage
    end

    -- Heal
    function component:heal(amount)
        if self.isDead then
            return 0
        end

        local oldHp = self.currentHp
        self.currentHp = math.min(self.maxHp, self.currentHp + amount)
        local actualHeal = self.currentHp - oldHp

        if actualHeal > 0 then
            EventBus.emit(Constants.EVENTS.ENTITY_HEALED, {
                entity = entity,
                heal = actualHeal,
                currentHp = self.currentHp,
                maxHp = self.maxHp
            })
        end

        return actualHeal
    end

    -- Set HP directly
    function component:setHp(value)
        self.currentHp = math.max(0, math.min(value, self.maxHp))

        if self.currentHp <= 0 and not self.isDead then
            self:die()
        end
    end

    -- Set max HP and optionally adjust current HP
    function component:setMaxHp(value, adjustCurrent)
        local ratio = self.currentHp / self.maxHp
        self.maxHp = math.max(1, value)

        if adjustCurrent then
            self.currentHp = math.floor(self.maxHp * ratio)
        else
            self.currentHp = math.min(self.currentHp, self.maxHp)
        end
    end

    -- Check if alive
    function component:isAlive()
        return not self.isDead and self.currentHp > 0
    end

    -- Check if at full health
    function component:isFullHealth()
        return self.currentHp >= self.maxHp
    end

    -- Get health percentage
    function component:getHealthPercentage()
        return self.currentHp / self.maxHp
    end

    -- Handle death
    function component:die()
        if self.isDead then
            return
        end

        self.isDead = true
        self.currentHp = 0

        EventBus.emit(Constants.EVENTS.ENTITY_DIED, {
            entity = entity
        })
    end

    -- Respawn
    function component:respawn(hp)
        self.isDead = false
        self.currentHp = hp or self.maxHp
        self.timeSinceDamage = 0

        EventBus.emit(Constants.EVENTS.ENTITY_RESPAWNED, {
            entity = entity,
            hp = self.currentHp
        })
    end

    -- Set regeneration rate
    function component:setRegenRate(rate, delay)
        self.regenRate = rate or 0
        self.regenDelay = delay or 5.0
    end

    -- Set invulnerability
    function component:setInvulnerable(duration)
        self.isInvulnerable = true
        self.invulnerabilityDuration = duration or 0
    end

    -- Update (for regeneration and invulnerability)
    function component:update(dt)
        if self.isDead then
            return
        end

        -- Update invulnerability
        if self.isInvulnerable then
            self.invulnerabilityDuration = self.invulnerabilityDuration - dt
            if self.invulnerabilityDuration <= 0 then
                self.isInvulnerable = false
            end
        end

        -- Update regeneration
        if self.regenRate > 0 and not self:isFullHealth() then
            self.timeSinceDamage = self.timeSinceDamage + dt

            if self.timeSinceDamage >= self.regenDelay then
                local regenAmount = self.regenRate * dt
                self:heal(regenAmount)
            end
        end
    end

    return component
end

-- Create Health from Stats component
function Health.fromStats(statsComponent, entity)
    if not statsComponent then
        return Health.create(100, entity)
    end

    return Health.create(statsComponent.maxHp, entity)
end

return Health
