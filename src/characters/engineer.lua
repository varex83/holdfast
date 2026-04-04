local CharacterFactory = require("src.characters.characterfactory")
local Constants = require("data.constants")

local Engineer = {}

function Engineer.new(x, y)
    return CharacterFactory.create(Constants.CLASS.ENGINEER, x, y)
end

return Engineer
