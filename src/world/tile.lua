-- Tile System
-- Defines all tile types with walkability flags and placeholder render colours.
-- When real sprites are added, swap the `color` entries for `image` paths and
-- load them via love.graphics.newImage in a separate asset loader.

local Tile = {}

-- ─── Tile definitions ────────────────────────────────────────────────────────
-- Each entry:
--   walkable  bool   Can characters/enemies move through this tile?
--   color     {r,g,b} Placeholder fill colour (used until sprites exist)
--   name      string  Human-readable label (debug, UI tooltips)

local DEFINITIONS = {
    grass  = { walkable = true,  color = {0.35, 0.65, 0.25}, name = "Grass"  },
    dirt   = { walkable = true,  color = {0.60, 0.45, 0.25}, name = "Dirt"   },
    stone  = { walkable = true,  color = {0.55, 0.55, 0.55}, name = "Stone"  },
    water  = { walkable = false, color = {0.20, 0.45, 0.80}, name = "Water"  },
    sand   = { walkable = true,  color = {0.85, 0.80, 0.50}, name = "Sand"   },
    tree   = { walkable = false, color = {0.15, 0.45, 0.15}, name = "Tree"   },
    rock   = { walkable = false, color = {0.40, 0.40, 0.40}, name = "Rock"   },
}

-- ─── Public API ──────────────────────────────────────────────────────────────

-- Returns the full definition table for a tile type, or nil if unknown.
function Tile.get(tileType)
    return DEFINITIONS[tileType]
end

-- Returns true if characters may walk on/through this tile type.
function Tile.isWalkable(tileType)
    local def = DEFINITIONS[tileType]
    return def and def.walkable or false
end

-- Returns the placeholder {r, g, b} colour for a tile type.
-- Falls back to magenta so missing tile types are immediately visible.
function Tile.getColor(tileType)
    local def = DEFINITIONS[tileType]
    if def then return def.color end
    return {1, 0, 1}  -- magenta = undefined tile
end

-- Returns all registered tile type keys (useful for iteration/debug).
function Tile.allTypes()
    local types = {}
    for k in pairs(DEFINITIONS) do
        types[#types + 1] = k
    end
    table.sort(types)
    return types
end

return Tile
