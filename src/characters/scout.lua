local CharacterFactory = require("src.characters.characterfactory")
local Constants = require("data.constants")

local Scout = {}

function Scout.new(x, y)
    return CharacterFactory.create(Constants.CLASS.SCOUT, x, y)
end

return Scout
