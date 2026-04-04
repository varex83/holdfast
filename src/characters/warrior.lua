local CharacterFactory = require("src.characters.characterfactory")
local Constants = require("data.constants")

local Warrior = {}

function Warrior.new(x, y)
    return CharacterFactory.create(Constants.CLASS.WARRIOR, x, y)
end

return Warrior
