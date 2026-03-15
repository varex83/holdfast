local Character = require("src.characters.character")
local Classes = require("data.classes")
local Cooldown = require("src.combat.cooldown")
local Volley = require("src.characters.abilities.volley")
local Constants = require("data.constants")

local Archer = {}

function Archer.new(x, y)
    local classDef = Classes.get(Constants.CLASS.ARCHER)
    local character = Character.new(Constants.CLASS.ARCHER, x, y, classDef.visuals)
    character.cooldowns = Cooldown.new()
    character.cooldowns:registerAbility(Volley.id, Volley)
    character.classAbility = Volley
    return character
end

return Archer
