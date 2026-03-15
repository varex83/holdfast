-- Tile System
-- Defines tile rules plus the sprite sources used by the day-state renderer.

local Tile = {}
local AssetManager = require("src.core.assetmanager")

-- ─── Public API ──────────────────────────────────────────────────────────────

-- Returns the full definition table for a tile type, or nil if unknown.
function Tile.get(tileType)
    return AssetManager.getCurrent():getTileDefinition(tileType)
end

-- Returns true if characters may walk on/through this tile type.
function Tile.isWalkable(tileType)
    local def = Tile.get(tileType)
    return def and def.walkable or false
end

function Tile.isPointWalkable(tileType, localX, localY)
    local def = Tile.get(tileType)
    if not def then
        return false
    end

    if def.walkable then
        return true
    end

    if not def.collision then
        return false
    end

    if def.collision.shape == "circle" then
        local radius = def.collision.radius or 0.5
        local offsetX = def.collision.offsetX or 0
        local offsetY = def.collision.offsetY or 0
        local dx = localX - offsetX
        local dy = localY - offsetY
        return (dx * dx + dy * dy) > (radius * radius)
    end

    if def.collision.shape == "box" then
        local width = def.collision.width or 0.5
        local height = def.collision.height or 0.5
        local offsetX = def.collision.offsetX or 0
        local offsetY = def.collision.offsetY or 0
        return math.abs(localX - offsetX) > (width * 0.5) or math.abs(localY - offsetY) > (height * 0.5)
    end

    return false
end

-- Returns the placeholder {r, g, b} colour for a tile type.
-- Falls back to magenta so missing tile types are immediately visible.
function Tile.getColor(tileType)
    local def = Tile.get(tileType)
    if def then return def.color end
    return {1, 0, 1}  -- magenta = undefined tile
end

function Tile.getRenderData(tileType, tx, ty, timeSeconds)
    return AssetManager.getCurrent():getTileRenderData(tileType, tx, ty, timeSeconds)
end

-- Returns all registered tile type keys (useful for iteration/debug).
function Tile.allTypes()
    return AssetManager.getCurrent():allTileTypes()
end

return Tile
