local Steering = require("src.ai.steering")

local AIController = {}
AIController.__index = AIController

AIController.STATE = {
    IDLE = "idle",
    SEEK = "seek",
    ATTACK = "attack",
    FLEE = "flee",
}

function AIController.new(config)
    local self = setmetatable({}, AIController)
    self.pathfinding = config.pathfinding
    self.acquireTarget = config.acquireTarget
    self.attack = config.attack
    self.pathRefresh = config.pathRefresh or 0.35
    self.separationDistance = config.separationDistance or 28
    return self
end

function AIController:update(actor, context, dt)
    if not actor:isAlive() then
        actor.aiState = AIController.STATE.IDLE
        actor:setDesiredMovement(0, 0)
        return
    end

    if actor.stunnedUntil and actor.stunnedUntil > love.timer.getTime() then
        actor.aiState = AIController.STATE.IDLE
        actor:setDesiredMovement(0, 0)
        return
    end

    if context.player and context.player.cloak and context.player.cloak.active then
        actor.aiState = AIController.STATE.IDLE
        actor:setDesiredMovement(0, 0)
        return
    end

    local target = self.acquireTarget and self.acquireTarget(actor, context) or nil
    if not target then
        actor.aiState = AIController.STATE.IDLE
        actor:setDesiredMovement(0, 0)
        return
    end

    local dx = target.x - actor.position.x
    local dy = target.y - actor.position.y
    local distance = math.sqrt(dx * dx + dy * dy)
    local attackRange = actor.stats:getAttackRange() + 8

    if actor.health and actor.health.currentHp <= actor.health.maxHp * 0.2 then
        actor.aiState = AIController.STATE.FLEE
        actor:setDesiredMovement(-dx, -dy)
        return
    end

    if distance <= attackRange then
        actor.aiState = AIController.STATE.ATTACK
        actor:setDesiredMovement(0, 0)
        actor.facingDirection = math.atan2(dy, dx)
        if self.attack then
            self.attack(actor, target, context)
        end
        return
    end

    actor.aiState = AIController.STATE.SEEK
    actor.aiTimer = (actor.aiTimer or 0) - dt

    if actor.aiTimer <= 0 then
        actor.aiTimer = self.pathRefresh
        actor.path = self.pathfinding and self.pathfinding:findPathWorld(
            actor.position.x,
            actor.position.y,
            target.x,
            target.y
        ) or nil
        actor.pathIndex = 2
    end

    local pathNode = actor.path and actor.path[actor.pathIndex]
    local seekTarget = pathNode or target
    local seekVector = Steering.seek(actor.position, seekTarget, 1)
    local separateVector = Steering.separate(actor, context.neighbors or {}, self.separationDistance)
    local movement = Steering.weightedBlend({
        {vector = seekVector, weight = 0.8},
        {vector = separateVector, weight = 0.2},
    })

    if pathNode then
        local pathDx = pathNode.x - actor.position.x
        local pathDy = pathNode.y - actor.position.y
        if math.sqrt(pathDx * pathDx + pathDy * pathDy) < 8 then
            actor.pathIndex = actor.pathIndex + 1
        end
    end

    actor:setDesiredMovement(movement.x, movement.y)
end

return AIController
