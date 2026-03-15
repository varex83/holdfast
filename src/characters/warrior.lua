local Character = require("src.characters.character")
local Classes = require("data.classes")
local Cooldown = require("src.combat.cooldown")
local ShieldBash = require("src.characters.abilities.shieldbash")
local Constants = require("data.constants")

local Warrior = {}

function Warrior.new(x, y)
    local classDef = Classes.get(Constants.CLASS.WARRIOR)
    local character = Character.new(Constants.CLASS.WARRIOR, x, y, classDef.visuals)
    character.cooldowns = Cooldown.new()
    character.cooldowns:registerAbility(ShieldBash.id, ShieldBash)
    character.classAbility = ShieldBash
    return character
end

return Warrior
