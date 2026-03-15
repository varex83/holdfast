-- Combat Manager
-- Handles damage calculation, attack timing, and hit detection
-- Integrates with Stats, Health, and Hitbox components

local CombatManager = {}
CombatManager.__index = CombatManager

function CombatManager.new(world, eventBus)
    local self = setmetatable({}, CombatManager)

    self.world = world
    self.eventBus = eventBus

    -- Active attacks tracking (for cooldowns and timing)
    self.activeAttacks = {}

    -- Attack hit tracking (prevent multiple hits from same attack)
    self.attackHits = {}

    -- Next attack ID for unique tracking
    self.nextAttackId = 1

    return self
end

-- Register an attack from an attacker entity
function CombatManager:registerAttack(attacker, attackData)
    if not self:validateAttacker(attacker) then
        return nil
    end

    local position = attacker:getComponent("position")
    if not position then
        return nil
    end

    local damage = self:getAttackDamage(attacker, attackData)
    local attack = self:createAttackRecord(attacker, attackData, damage)

    self:setCooldown(attacker.id, attackData.cooldown or 1.0)
    self.attackHits[attack.id] = attack

    self:broadcastAttackStarted(attacker.id, attack.id, position)

    return attack.id
end

-- Validate if attacker can perform an attack
function CombatManager:validateAttacker(attacker)
    if not attacker or not attacker:isAlive() then
        return false
    end

    local attackerId = attacker.id
    if self.activeAttacks[attackerId] then
        local cooldownRemaining = self.activeAttacks[attackerId].cooldownEnd - love.timer.getTime()
        if cooldownRemaining > 0 then
            return false
        end
    end

    return true
end

-- Get attack damage from attacker stats or attackData
function CombatManager:getAttackDamage(attacker, attackData)
    if attackData.damage then
        return attackData.damage
    end

    local stats = attacker:getComponent("stats")
    if stats then
        return stats:getAttack() or 10
    end

    return 10
end

-- Create an attack record
function CombatManager:createAttackRecord(attacker, attackData, damage)
    local attackId = self.nextAttackId
    self.nextAttackId = self.nextAttackId + 1

    return {
        id = attackId,
        attacker = attacker,
        attackerId = attacker.id,
        damage = damage,
        range = attackData.range or 50,
        hitboxOffset = attackData.hitboxOffset or {x = 0, y = 0},
        hitboxSize = attackData.hitboxSize or {width = 32, height = 32},
        knockback = attackData.knockback or 0,
        hitLimit = attackData.hitLimit or math.huge,
        startTime = love.timer.getTime(),
        duration = attackData.duration or 0.2,
        hitCount = 0,
        hitEntities = {}
    }
end

-- Set attack cooldown for an entity
function CombatManager:setCooldown(attackerId, cooldownDuration)
    self.activeAttacks[attackerId] = {
        cooldownEnd = love.timer.getTime() + cooldownDuration
    }
end

-- Broadcast attack started event
function CombatManager:broadcastAttackStarted(attackerId, attackId, position)
    if self.eventBus then
        self.eventBus.emit("combat:attack_started", {
            attackerId = attackerId,
            attackId = attackId,
            position = {x = position.x, y = position.y}
        })
    end
end

-- Update combat system
function CombatManager:update(dt)
    local currentTime = love.timer.getTime()

    -- Clean up expired attacks
    local expiredAttacks = {}
    for attackId, attack in pairs(self.attackHits) do
        if currentTime - attack.startTime > attack.duration then
            table.insert(expiredAttacks, attackId)
        end
    end

    for _, attackId in ipairs(expiredAttacks) do
        self.attackHits[attackId] = nil
    end

    -- Process active attacks
    for attackId, attack in pairs(self.attackHits) do
        self:processAttack(attack)
    end
end

-- Process a single attack, checking for hits
function CombatManager:processAttack(attack)
    if not attack.attacker or not attack.attacker:isAlive() then
        return
    end

    -- Get attacker position
    local attackerPos = attack.attacker:getComponent("position")
    if not attackerPos then
        return
    end

    -- Calculate attack hitbox in world space
    local attackBox = {
        x = attackerPos.x + attack.hitboxOffset.x - attack.hitboxSize.width / 2,
        y = attackerPos.y + attack.hitboxOffset.y - attack.hitboxSize.height / 2,
        width = attack.hitboxSize.width,
        height = attack.hitboxSize.height
    }

    -- Get all entities in world
    local entities = self.world.entities or {}

    for _, target in ipairs(entities) do
        -- Skip if target is the attacker
        if target ~= attack.attacker and target:isAlive() then
            -- Check if we've already hit this entity with this attack
            if not attack.hitEntities[target.id] then
                -- Check if we've reached hit limit
                if attack.hitCount < attack.hitLimit then
                    -- Check for collision
                    if self:checkHit(attackBox, target) then
                        self:applyDamage(attack, target)
                        attack.hitEntities[target.id] = true
                        attack.hitCount = attack.hitCount + 1
                    end
                end
            end
        end
    end
end

-- Check if attack hitbox collides with target hurtbox
function CombatManager:checkHit(attackBox, target)
    -- Try to get Hitbox component
    local hitbox = target:getComponent("hitbox")
    local targetPos = target:getComponent("position")

    if hitbox and targetPos then
        local targetBounds = hitbox:getBounds(targetPos)
        return self:checkAABBCollision(attackBox, {
            x = targetBounds.left,
            y = targetBounds.top,
            width = targetBounds.right - targetBounds.left,
            height = targetBounds.bottom - targetBounds.top
        })
    end

    -- Fallback: use Position component with default size
    if targetPos then
        local defaultSize = 32 -- Default entity size
        local targetBox = {
            x = targetPos.x - defaultSize / 2,
            y = targetPos.y - defaultSize / 2,
            width = defaultSize,
            height = defaultSize
        }
        return self:checkAABBCollision(attackBox, targetBox)
    end

    return false
end

-- AABB collision detection
function CombatManager:checkAABBCollision(box1, box2)
    return box1.x < box2.x + box2.width and
           box1.x + box1.width > box2.x and
           box1.y < box2.y + box2.height and
           box1.y + box1.height > box2.y
end

-- Apply damage to target
function CombatManager:applyDamage(attack, target)
    -- Calculate final damage
    local finalDamage = self:calculateDamage(attack, target)

    -- Try to apply damage to Health component
    local health = target:getComponent("health")
    if health then
        local wasAlive = health:isAlive()
        health:takeDamage(finalDamage)

        -- Check for death
        if wasAlive and not health:isAlive() then
            self:handleDeath(target)
        end
    else
        -- Fallback to Stats component
        local stats = target:getComponent("stats")
        if stats then
            local wasAlive = stats:isAlive()
            stats:takeDamage(finalDamage)

            if wasAlive and not stats:isAlive() then
                self:handleDeath(target)
            end
        end
    end

    -- Apply knockback if any
    if attack.knockback > 0 then
        self:applyKnockback(attack, target)
    end

    -- Broadcast hit event
    if self.eventBus then
        self.eventBus.emit("combat:hit", {
            attackerId = attack.attackerId,
            targetId = target.id,
            damage = finalDamage,
            attackId = attack.id
        })
    end
end

-- Calculate final damage after armor reduction
function CombatManager:calculateDamage(attack, target)
    local baseDamage = attack.damage

    -- Get target armor
    local armor = 0
    local stats = target:getComponent("stats")
    if stats then
        armor = stats:getArmor() or 0
    end

    -- Use Stats component's damage calculation if available
    if stats and stats.calculateDamageAfterArmor then
        return stats:calculateDamageAfterArmor(baseDamage)
    end

    -- Fallback damage reduction formula: damage * (100 / (100 + armor))
    local damageMultiplier = 100 / (100 + armor)
    local finalDamage = baseDamage * damageMultiplier

    -- Ensure minimum 1 damage
    return math.max(1, math.floor(finalDamage))
end

-- Apply knockback to target
function CombatManager:applyKnockback(attack, target)
    local velocity = target:getComponent("velocity")
    if not velocity then
        return
    end

    -- Calculate knockback direction
    local attackerPos = attack.attacker:getComponent("position")
    local targetPos = target:getComponent("position")

    if not attackerPos or not targetPos then
        return
    end

    -- Calculate direction vector
    local dx = targetPos.x - attackerPos.x
    local dy = targetPos.y - attackerPos.y
    local distance = math.sqrt(dx * dx + dy * dy)

    if distance > 0 then
        -- Normalize and apply knockback
        dx = dx / distance
        dy = dy / distance

        velocity.vx = velocity.vx + dx * attack.knockback
        velocity.vy = velocity.vy + dy * attack.knockback

        -- Broadcast knockback event
        if self.eventBus then
            self.eventBus.emit("combat:knockback", {
                targetId = target.id,
                force = attack.knockback,
                direction = {x = dx, y = dy}
            })
        end
    end
end

-- Handle entity death
function CombatManager:handleDeath(entity)
    -- Broadcast death event
    if self.eventBus then
        self.eventBus.emit("combat:death", {
            entityId = entity.id
        })
    end
end

-- Check if entity can attack (not on cooldown)
function CombatManager:canAttack(entity)
    if not entity or not entity:isAlive() then
        return false
    end

    local entityId = entity.id
    if not self.activeAttacks[entityId] then
        return true
    end

    local cooldownRemaining = self.activeAttacks[entityId].cooldownEnd - love.timer.getTime()
    return cooldownRemaining <= 0
end

-- Get attack cooldown remaining
function CombatManager:getAttackCooldown(entity)
    if not entity or not entity:isAlive() then
        return 0
    end

    local entityId = entity.id
    if not self.activeAttacks[entityId] then
        return 0
    end

    local cooldownRemaining = self.activeAttacks[entityId].cooldownEnd - love.timer.getTime()
    return math.max(0, cooldownRemaining)
end

-- Clear all attacks and cooldowns
function CombatManager:clear()
    self.activeAttacks = {}
    self.attackHits = {}
    self.nextAttackId = 1
end

-- Draw debug visualization (optional)
function CombatManager:drawDebug()
    -- Draw active attack hitboxes
    love.graphics.setColor(1, 0, 0, 0.3)
    for _, attack in pairs(self.attackHits) do
        if attack.attacker and attack.attacker:isAlive() then
            local attackerPos = attack.attacker:getComponent("position")
            if attackerPos then
                local x = attackerPos.x + attack.hitboxOffset.x - attack.hitboxSize.width / 2
                local y = attackerPos.y + attack.hitboxOffset.y - attack.hitboxSize.height / 2
                local w = attack.hitboxSize.width
                local h = attack.hitboxSize.height

                love.graphics.rectangle("line", x, y, w, h)
            end
        end
    end
    love.graphics.setColor(1, 1, 1, 1)
end

return CombatManager
