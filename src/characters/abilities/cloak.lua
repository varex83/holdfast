local Cloak = {
    id = "cloak",
    cooldown = 15.0,
    cost = 0,
    duration = 3.0,
    alpha = 0.35,
}

function Cloak.activate(context)
    local actor = context.actor
    if not actor then
        return false, "missing_context"
    end

    actor.cloak = {
        active = true,
        remaining = Cloak.duration,
        alpha = Cloak.alpha,
    }
    actor.sprite.a = Cloak.alpha
    if actor.health then
        actor.health:setInvulnerable(Cloak.duration)
    end

    return true, {
        duration = Cloak.duration,
        alpha = Cloak.alpha,
    }
end

function Cloak.update(actor, dt)
    if not actor or not actor.cloak or not actor.cloak.active then
        return
    end

    actor.cloak.remaining = math.max(0, actor.cloak.remaining - dt)
    if actor.cloak.remaining <= 0 then
        actor.cloak.active = false
        actor.sprite.a = 1
    else
        actor.sprite.a = actor.cloak.alpha
    end
end

return Cloak
