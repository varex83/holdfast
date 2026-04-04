local CharacterFactory = require("src.characters.characterfactory")
local Constants = require("data.constants")

local Archer = {}

function Archer.new(x, y)
    return CharacterFactory.create(Constants.CLASS.ARCHER, x, y)
end

return Archer
