local Character = require("src.characters.character")
local Classes = require("data.classes")
local Cooldown = require("src.combat.cooldown")
local Cloak = require("src.characters.abilities.cloak")
local Constants = require("data.constants")

local Scout = {}

function Scout.new(x, y)
    local classDef = Classes.get(Constants.CLASS.SCOUT)
    local character = Character.new(Constants.CLASS.SCOUT, x, y, classDef.visuals)
    character.cooldowns = Cooldown.new()
    character.cooldowns:registerAbility(Cloak.id, Cloak)
    character.classAbility = Cloak
    return character
end

return Scout
