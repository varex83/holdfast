-- Cooldown System
-- Manages ability cooldowns with support for individual ability tracking,
-- global cooldown (GCD), and visual timer integration.

local Cooldown = {}
Cooldown.__index = Cooldown

-- Default global cooldown duration (in seconds)
local DEFAULT_GCD = 0.5

-- Ability cooldown definitions (in seconds)
-- Based on CLAUDE.md ability specifications
Cooldown.ABILITY_COOLDOWNS = {
    -- Warrior
    shield_bash = 8.0,          -- Knockback and stun ability

    -- Archer
    volley = 10.0,              -- Multi-target arrow spread

    -- Scout
    cloak = 15.0,               -- Invisibility (resets at base)

    -- Engineer
    construct = 0.0,            -- No cooldown, limited by resources
    repair = 1.0,               -- Quick repair action

    -- Generic combat actions
    primary_attack = 0.0,       -- No cooldown on basic attacks
    dodge = 5.0,                -- Potential dodge/roll ability
}

-- Create a new cooldown manager
function Cooldown.new(gcdDuration)
    local self = setmetatable({}, Cooldown)

    -- Global cooldown
    self.gcdDuration = gcdDuration or DEFAULT_GCD
    self.gcdRemaining = 0.0

    -- Per-ability cooldowns
    -- Structure: { ability_name = { duration, remaining, paused } }
    self.cooldowns = {}

    -- Cooldown modifiers (for buffs/debuffs)
    self.modifiers = {}

    -- Event callbacks
    self.callbacks = {
        onCooldownStart = {},
        onCooldownEnd = {},
        onGCDStart = {},
        onGCDEnd = {}
    }

    return self
end

-- Update all cooldown timers
function Cooldown:update(dt)
    -- Update global cooldown
    if self.gcdRemaining > 0 then
        local wasOnGCD = true
        self.gcdRemaining = math.max(0, self.gcdRemaining - dt)

        if self.gcdRemaining == 0 and wasOnGCD then
            self:_triggerCallbacks("onGCDEnd")
        end
    end

    -- Update individual ability cooldowns
    for abilityName, cooldown in pairs(self.cooldowns) do
        if cooldown.remaining > 0 and not cooldown.paused then
            local wasOnCooldown = true
            cooldown.remaining = math.max(0, cooldown.remaining - dt)

            if cooldown.remaining == 0 and wasOnCooldown then
                self:_triggerCallbacks("onCooldownEnd", abilityName)
            end
        end
    end
end

-- Start cooldown for a specific ability
function Cooldown:startCooldown(abilityName, duration, triggerGCD)
    if triggerGCD == nil then triggerGCD = true end

    -- Get duration from ability defaults or use provided duration
    local cooldownDuration = duration or Cooldown.ABILITY_COOLDOWNS[abilityName] or 0

    -- Apply cooldown modifiers
    if self.modifiers[abilityName] then
        cooldownDuration = cooldownDuration * self.modifiers[abilityName]
    end

    -- Initialize or update cooldown data
    if not self.cooldowns[abilityName] then
        self.cooldowns[abilityName] = {
            duration = cooldownDuration,
            remaining = cooldownDuration,
            paused = false
        }
    else
        self.cooldowns[abilityName].duration = cooldownDuration
        self.cooldowns[abilityName].remaining = cooldownDuration
        self.cooldowns[abilityName].paused = false
    end

    -- Trigger global cooldown
    if triggerGCD and self.gcdDuration > 0 then
        self.gcdRemaining = self.gcdDuration
        self:_triggerCallbacks("onGCDStart")
    end

    self:_triggerCallbacks("onCooldownStart", abilityName, cooldownDuration)
end

-- Check if an ability is ready to use
function Cooldown:isReady(abilityName, ignoreGCD)
    -- Check global cooldown
    if not ignoreGCD and self.gcdRemaining > 0 then
        return false
    end

    -- Check ability-specific cooldown
    local cooldown = self.cooldowns[abilityName]
    if not cooldown then
        return true  -- No cooldown recorded, ability is ready
    end

    return cooldown.remaining <= 0
end

-- Get remaining cooldown time for an ability
function Cooldown:getRemaining(abilityName)
    local cooldown = self.cooldowns[abilityName]
    if not cooldown then
        return 0
    end
    return cooldown.remaining
end

-- Get cooldown progress as a percentage
function Cooldown:getProgress(abilityName)
    local cooldown = self.cooldowns[abilityName]
    if not cooldown or cooldown.duration == 0 then
        return 1.0
    end

    return 1.0 - (cooldown.remaining / cooldown.duration)
end

-- Get remaining GCD time
function Cooldown:getGCDRemaining()
    return self.gcdRemaining
end

-- Check if global cooldown is active
function Cooldown:isOnGCD()
    return self.gcdRemaining > 0
end

-- Reset a specific ability cooldown
function Cooldown:reset(abilityName)
    if self.cooldowns[abilityName] then
        self.cooldowns[abilityName].remaining = 0
        self:_triggerCallbacks("onCooldownEnd", abilityName)
    end
end

-- Reset all ability cooldowns
function Cooldown:resetAll(includeGCD)
    if includeGCD == nil then includeGCD = true end

    for abilityName, _ in pairs(self.cooldowns) do
        self:reset(abilityName)
    end

    if includeGCD then
        self.gcdRemaining = 0
        self:_triggerCallbacks("onGCDEnd")
    end
end

-- Pause a specific ability cooldown
function Cooldown:pause(abilityName)
    if self.cooldowns[abilityName] then
        self.cooldowns[abilityName].paused = true
    end
end

-- Resume a specific ability cooldown
function Cooldown:resume(abilityName)
    if self.cooldowns[abilityName] then
        self.cooldowns[abilityName].paused = false
    end
end

-- Set a cooldown modifier for an ability
function Cooldown:setModifier(abilityName, multiplier)
    self.modifiers[abilityName] = multiplier
end

-- Remove a cooldown modifier for an ability
function Cooldown:removeModifier(abilityName)
    self.modifiers[abilityName] = nil
end

-- Clear all cooldown modifiers
function Cooldown:clearModifiers()
    self.modifiers = {}
end

-- Reduce cooldown time for a specific ability
function Cooldown:reduce(abilityName, amount)
    if self.cooldowns[abilityName] then
        self.cooldowns[abilityName].remaining = math.max(0, self.cooldowns[abilityName].remaining - amount)

        if self.cooldowns[abilityName].remaining == 0 then
            self:_triggerCallbacks("onCooldownEnd", abilityName)
        end
    end
end

-- Special: Reset scout cloak cooldown when at base
function Cooldown:updateCloakCooldown(isAtBase)
    if isAtBase and self.cooldowns.cloak then
        self:reset("cloak")
    end
end

-- Register a callback for cooldown events
function Cooldown:on(event, callback)
    if not self.callbacks[event] then
        error("Invalid cooldown event: " .. tostring(event))
    end

    table.insert(self.callbacks[event], callback)
    return #self.callbacks[event]
end

-- Unregister a callback
function Cooldown:off(event, id)
    if self.callbacks[event] then
        table.remove(self.callbacks[event], id)
    end
end

-- Get all active cooldowns (for UI display)
function Cooldown:getActiveCooldowns()
    local active = {}

    for abilityName, cooldown in pairs(self.cooldowns) do
        if cooldown.remaining > 0 then
            table.insert(active, {
                name = abilityName,
                remaining = cooldown.remaining,
                duration = cooldown.duration,
                progress = self:getProgress(abilityName)
            })
        end
    end

    return active
end

-- Get cooldown data for UI rendering
function Cooldown:getUIData(abilityName)
    local ready = self:isReady(abilityName)
    local remaining = self:getRemaining(abilityName)
    local progress = self:getProgress(abilityName)
    local duration = self.cooldowns[abilityName] and self.cooldowns[abilityName].duration or 0

    return {
        ready = ready,
        remaining = remaining,
        duration = duration,
        progress = progress,
        onGCD = self:isOnGCD()
    }
end

-- Internal: Trigger event callbacks
function Cooldown:_triggerCallbacks(event, ...)
    if self.callbacks[event] then
        for _, callback in ipairs(self.callbacks[event]) do
            callback(...)
        end
    end
end

-- Export predefined ability cooldowns for reference
Cooldown.getDefaultCooldown = function(abilityName)
    return Cooldown.ABILITY_COOLDOWNS[abilityName] or 0
end

return Cooldown
