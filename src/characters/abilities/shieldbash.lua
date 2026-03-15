local ShieldBash = {
    id = "shield_bash",
    cooldown = 8.0,
    cost = 0,
    stunDuration = 1.25,
    coneAngle = math.pi / 2,
    range = 84,
    knockback = 320,
}

local function angleDelta(a, b)
    local delta = (a - b + math.pi) % (math.pi * 2) - math.pi
    return math.abs(delta)
end

function ShieldBash.activate(context)
    local actor = context.actor
    local world = context.world
    local combatManager = context.combatManager
    if not actor or not world or not combatManager then
        return false, "missing_context"
    end

    local position = actor:getPosition()
    local facing = actor.facingDirection or 0
    local hitCount = 0

    for _, entity in ipairs(world.entities or {}) do
        if entity ~= actor.entity and entity:isAlive() then
            local hitbox = entity:getComponent("hitbox")
            local entityPosition = entity:getComponent("position")
            if hitbox and entityPosition and hitbox.team ~= actor.hitbox.team then
                local dx = entityPosition.x - position.x
                local dy = entityPosition.y - position.y
                local distance = math.sqrt(dx * dx + dy * dy)
                if distance <= ShieldBash.range then
                    local angle = math.atan2(dy, dx)
                    if angleDelta(angle, facing) <= ShieldBash.coneAngle * 0.5 then
                        combatManager:applyDamage({
                            attacker = actor.entity,
                            attackerId = actor.entity.id,
                            damage = math.floor(actor.stats:getAttack() * 1.5),
                            knockback = ShieldBash.knockback,
                            id = "shield_bash",
                        }, entity)
                        entity.stunnedUntil = love.timer.getTime() + ShieldBash.stunDuration
                        hitCount = hitCount + 1
                    end
                end
            end
        end
    end

    actor:triggerAttackAnimation()
    return true, {hits = hitCount, stunDuration = ShieldBash.stunDuration}
end

return ShieldBash
