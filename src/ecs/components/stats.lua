-- Stats Component
-- Manages character attributes (HP, armor, speed, attack, etc.)
-- Supports class-based stat definitions and stat modifiers

local Component = require('src.ecs.component')
local Constants = require('data.constants')

local Stats = {}

-- Base stats for each character class (from CLAUDE.md)
local BASE_STATS = {
    [Constants.CLASS.WARRIOR] = {
        maxHp = 200,
        armor = 10,
        speed = 80,
        attack = 25,
        attackRange = 50,    -- Melee, short range
        attackSpeed = 1.0,   -- Attacks per second
        carryCapacity = 50   -- Lowest carry capacity
    },
    [Constants.CLASS.ARCHER] = {
        maxHp = 100,
        armor = 5,
        speed = 150,
        attack = 15,
        attackRange = 300,   -- Ranged, medium range
        attackSpeed = 0.8,
        carryCapacity = 75
    },
    [Constants.CLASS.ENGINEER] = {
        maxHp = 80,
        armor = 3,
        speed = 180,
        attack = 0,          -- Cannot fight
        attackRange = 0,
        attackSpeed = 0,
        carryCapacity = 100  -- Good carry capacity for building materials
    },
    [Constants.CLASS.SCOUT] = {
        maxHp = 120,
        armor = 3,
        speed = 200,         -- Highest speed
        attack = 8,          -- Low damage
        attackRange = 40,    -- Dagger, very short range
        attackSpeed = 1.2,   -- Fast attacks
        carryCapacity = 120  -- Highest carry capacity
    }
}

-- Create a Stats component
function Stats.create(classType, entity)
    local baseStats = BASE_STATS[classType]
    if not baseStats then
        error("Invalid class type: " .. tostring(classType))
    end

    local component = {
        type = 'stats',
        entity = entity
    }

    -- Base stats (permanent)
    component.classType = classType
    component.maxHp = baseStats.maxHp
    component.baseArmor = baseStats.armor
    component.baseSpeed = baseStats.speed
    component.baseAttack = baseStats.attack
    component.baseAttackRange = baseStats.attackRange
    component.baseAttackSpeed = baseStats.attackSpeed
    component.carryCapacity = baseStats.carryCapacity

    -- Current HP (managed by Health component typically)
    component.currentHp = baseStats.maxHp

    -- Stat modifiers (temporary buffs/debuffs)
    component.modifiers = {
        armor = 0,
        speed = 0,
        attack = 0,
        attackRange = 0,
        attackSpeed = 0
    }

    -- Get effective armor (with modifiers)
    function component:getArmor()
        return math.max(0, self.baseArmor + self.modifiers.armor)
    end

    -- Get effective speed (with modifiers)
    function component:getSpeed()
        return math.max(0, self.baseSpeed + self.modifiers.speed)
    end

    -- Get effective attack (with modifiers)
    function component:getAttack()
        return math.max(0, self.baseAttack + self.modifiers.attack)
    end

    -- Get effective attack range (with modifiers)
    function component:getAttackRange()
        return math.max(0, self.baseAttackRange + self.modifiers.attackRange)
    end

    -- Get effective attack speed (with modifiers)
    function component:getAttackSpeed()
        return math.max(0, self.baseAttackSpeed + self.modifiers.attackSpeed)
    end

    -- Calculate damage reduction from armor (diminishing returns)
    -- Formula: armor / (armor + 100) gives 0-100% reduction
    function component:getDamageReduction()
        local armor = self:getArmor()
        return armor / (armor + 100)
    end

    -- Calculate effective damage after armor
    function component:calculateDamageAfterArmor(rawDamage)
        local reduction = self:getDamageReduction()
        return rawDamage * (1 - reduction)
    end

    -- HP management helpers
    function component:setHp(value)
        self.currentHp = math.max(0, math.min(value, self.maxHp))
    end

    function component:takeDamage(amount)
        self:setHp(self.currentHp - amount)
        return self.currentHp
    end

    function component:heal(amount)
        self:setHp(self.currentHp + amount)
        return self.currentHp
    end

    function component:isAlive()
        return self.currentHp > 0
    end

    function component:isFullHealth()
        return self.currentHp >= self.maxHp
    end

    function component:getHealthPercentage()
        return self.currentHp / self.maxHp
    end

    -- Apply a temporary stat modifier
    function component:applyModifier(stat, value)
        if self.modifiers[stat] ~= nil then
            self.modifiers[stat] = self.modifiers[stat] + value
        end
    end

    -- Reset all modifiers
    function component:resetModifiers()
        for stat in pairs(self.modifiers) do
            self.modifiers[stat] = 0
        end
    end

    -- Check if this class can attack
    function component:canAttack()
        return self.baseAttack > 0
    end

    return component
end

-- Factory method: Create stats for a specific class
function Stats.forClass(classType, entity)
    return Stats.create(classType, entity)
end

-- Get base stats for a class (without creating component)
function Stats.getBaseStatsForClass(classType)
    return BASE_STATS[classType]
end

-- Check if a class can attack
function Stats.canClassAttack(classType)
    local baseStats = BASE_STATS[classType]
    return baseStats and baseStats.attack > 0
end

return Stats
