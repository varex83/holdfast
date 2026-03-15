local Projectile = require("src.combat.projectile")

local Volley = {
    id = "volley",
    cooldown = 10.0,
    cost = 0,
    projectileCount = 5,
    arcAngle = math.pi / 4,
}

function Volley.activate(context)
    local actor = context.actor
    local world = context.world
    if not actor or not world then
        return false, "missing_context"
    end

    actor:triggerAttackAnimation()
    local arrows = Projectile.createVolley(
        world,
        actor.position.x,
        actor.position.y,
        actor.facingDirection or 0,
        actor.entity,
        actor.hitbox.team,
        Volley.projectileCount,
        Volley.arcAngle
    )

    return true, {
        projectileCount = #arrows,
        arcAngle = Volley.arcAngle,
    }
end

return Volley
