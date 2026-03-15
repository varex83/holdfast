local Character = require("src.characters.character")
local Classes = require("data.classes")
local Cooldown = require("src.combat.cooldown")
local Constants = require("data.constants")

local Engineer = {}

function Engineer.new(x, y)
    local classDef = Classes.get(Constants.CLASS.ENGINEER)
    local character = Character.new(Constants.CLASS.ENGINEER, x, y, classDef.visuals)
    character.cooldowns = Cooldown.new()
    character.canBuild = true
    return character
end

return Engineer
