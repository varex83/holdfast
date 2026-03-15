-- Tile System
-- Defines tile rules plus the sprite sources used by the day-state renderer.

local Tile = {}
local loadedAssets = nil

local function getImage(path)
    if not loadedAssets.images[path] then
        loadedAssets.images[path] = love.graphics.newImage(path)
        loadedAssets.images[path]:setFilter("nearest", "nearest")
    end
    return loadedAssets.images[path]
end

local function getAtlas(name, path, tileW, tileH)
    if not loadedAssets.atlases[name] then
        local image = getImage(path)
        local iw, ih = image:getDimensions()
        loadedAssets.atlases[name] = {
            image = image,
            tileW = tileW,
            tileH = tileH,
            columns = math.floor(iw / tileW),
            quads = {}
        }
    end
    return loadedAssets.atlases[name]
end

local function getQuad(atlas, tileId)
    if not atlas.quads[tileId] then
        local x = (tileId % atlas.columns) * atlas.tileW
        local y = math.floor(tileId / atlas.columns) * atlas.tileH
        atlas.quads[tileId] = love.graphics.newQuad(
            x,
            y,
            atlas.tileW,
            atlas.tileH,
            atlas.image:getDimensions()
        )
    end
    return atlas.quads[tileId]
end

local function ensureAssets()
    if loadedAssets then
        return
    end

    loadedAssets = {
        images = {},
        atlases = {}
    }

    getAtlas(
        "ground",
        "assets/The Fan-tasy Tileset (Free)/Art/Ground Tileset/Tileset_Ground.png",
        16,
        16
    )
    getAtlas(
        "road",
        "assets/The Fan-tasy Tileset (Free)/Art/Ground Tileset/Tileset_Road.png",
        16,
        16
    )
    getAtlas(
        "water",
        "assets/The Fan-tasy Tileset (Free)/Art/Water and Sand/Tileset_Water.png",
        16,
        16
    )
end

local function chooseVariant(variants, tx, ty)
    local hash = math.abs(tx * 73856093 + ty * 19349663)
    return variants[(hash % #variants) + 1]
end

local DEFINITIONS = {
    grass = {
        walkable = true,
        color = {0.35, 0.65, 0.25},
        name = "Grass",
        ground = {atlas = "ground", variants = {96, 97, 98, 99, 100, 101, 108, 109, 110, 111, 112, 113}},
    },
    dirt = {
        walkable = true,
        color = {0.60, 0.45, 0.25},
        name = "Dirt",
        ground = {atlas = "road", variants = {48, 49, 50, 54, 55, 56}},
    },
    stone = {
        walkable = true,
        color = {0.55, 0.55, 0.55},
        name = "Stone",
        ground = {atlas = "road", variants = {48, 49, 50, 54, 55, 56}, tint = {0.72, 0.76, 0.80}},
    },
    water = {
        walkable = false,
        color = {0.20, 0.45, 0.80},
        name = "Water",
        ground = {atlas = "water", frames = {26, 32, 38, 44}, frameDuration = 0.18},
    },
    sand = {
        walkable = true,
        color = {0.85, 0.80, 0.50},
        name = "Sand",
        ground = {atlas = "road", variants = {48, 49, 50, 54, 55, 56}, tint = {0.96, 0.90, 0.72}},
    },
    tree = {
        walkable = false,
        color = {0.15, 0.45, 0.15},
        name = "Tree",
        collision = {shape = "circle", radius = 0.12, offsetY = 0.18},
        ground = {atlas = "ground", variants = {96, 97, 98, 99, 100, 101, 108, 109, 110, 111, 112, 113}},
        overlay = {
            variants = {
                "assets/The Fan-tasy Tileset (Free)/Art/Trees and Bushes/Tree_Emerald_1.png",
                "assets/The Fan-tasy Tileset (Free)/Art/Trees and Bushes/Tree_Emerald_2.png",
                "assets/The Fan-tasy Tileset (Free)/Art/Trees and Bushes/Tree_Emerald_3.png",
                "assets/The Fan-tasy Tileset (Free)/Art/Trees and Bushes/Tree_Emerald_4.png",
            },
            scale = 1,
        }
    },
    rock = {
        walkable = false,
        color = {0.40, 0.40, 0.40},
        name = "Rock",
        collision = {shape = "circle", radius = 0.10, offsetY = 0.08},
        ground = {atlas = "road", variants = {48, 49, 50, 54, 55, 56}, tint = {0.72, 0.76, 0.80}},
        overlay = {
            variants = {
                "assets/The Fan-tasy Tileset (Free)/Art/Rocks/Rock_Brown_1.png",
                "assets/The Fan-tasy Tileset (Free)/Art/Rocks/Rock_Brown_2.png",
                "assets/The Fan-tasy Tileset (Free)/Art/Rocks/Rock_Brown_4.png",
                "assets/The Fan-tasy Tileset (Free)/Art/Rocks/Rock_Brown_6.png",
            },
            scale = 1
        }
    },
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

function Tile.isPointWalkable(tileType, localX, localY)
    local def = DEFINITIONS[tileType]
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

    return false
end

-- Returns the placeholder {r, g, b} colour for a tile type.
-- Falls back to magenta so missing tile types are immediately visible.
function Tile.getColor(tileType)
    local def = DEFINITIONS[tileType]
    if def then return def.color end
    return {1, 0, 1}  -- magenta = undefined tile
end

function Tile.getRenderData(tileType, tx, ty, timeSeconds)
    ensureAssets()

    local def = DEFINITIONS[tileType]
    if not def then
        return nil
    end

    local result = {}

    if def.ground then
        local atlas = loadedAssets.atlases[def.ground.atlas]
        local tileId

        if def.ground.frames then
            local frameDuration = def.ground.frameDuration or 0.3
            local frameIndex = (math.floor((timeSeconds or 0) / frameDuration) % #def.ground.frames) + 1
            tileId = def.ground.frames[frameIndex]
        else
            tileId = chooseVariant(def.ground.variants, tx, ty)
        end

        result.ground = {
            image = atlas.image,
            quad = getQuad(atlas, tileId),
            tint = def.ground.tint or {1, 1, 1}
        }
    end

    if def.overlay then
        local path = chooseVariant(def.overlay.variants, tx, ty)
        result.overlay = {
            image = getImage(path),
            scale = def.overlay.scale or 1,
            tint = def.overlay.tint or {1, 1, 1},
            opacity = def.overlay.opacity or 1,
        }
    end

    return result
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
