local Character = require("src.characters.character")
local AIController = require("src.ai.aicontroller")
local Constants = require("data.constants")

local Shambler = {}
Shambler.__index = Shambler

function Shambler.new(x, y, config)
    local self = setmetatable({}, Shambler)
    config = config or {}

    self.character = Character.new(Constants.CLASS.WARRIOR, x, y, {
        appearance = "goblin_maceman",
        tint = {0.92, 0.48, 0.42, 1.0},
    })
    self.character.hitbox.team = "enemy"
    self.character.stats.maxHp = 140
    self.character.stats.baseArmor = 2
    self.character.stats.baseSpeed = 70
    self.character.stats.baseAttack = 14
    self.character.stats.baseAttackRange = 42
    self.character.health.maxHp = 140
    self.character.health.currentHp = 140
    self.character.enemyType = Constants.ENEMY_SHAMBLER
    self.character.aiController = AIController.new({
        pathfinding = config.pathfinding,
        acquireTarget = config.acquireTarget,
        attack = config.attack,
    })

    return self
end

function Shambler:update(dt, context)
    self.character.aiController:update(self.character, context, dt)
    self.character:update(dt)
end

function Shambler:isAlive()
    return self.character:isAlive()
end

return Shambler
