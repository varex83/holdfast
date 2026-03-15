local AssetManager = require("src.core.assetmanager")

local Tilemap = {}

function Tilemap.getDefinition(id)
    return AssetManager.getCurrent():getTilemapDefinition(id)
end

function Tilemap.load(id)
    return AssetManager.getCurrent():getTilemap(id)
end

return Tilemap
