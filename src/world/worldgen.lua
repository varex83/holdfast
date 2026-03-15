-- World Generation
-- Perlin noise-based infinite world with biomes and resource node placement.
-- Uses Love2D's built-in love.math.noise() function.

local WorldGen = {}

-- ─── Seed offset for deterministic world generation ─────────────────────────

local seedOffsetX = 0
local seedOffsetY = 0

-- ─── Noise wrapper ──────────────────────────────────────────────────────────

-- Wrapper around love.math.noise that converts [0,1] range to [-1,1]
-- and applies seed offset for deterministic generation
local function noise2d(x, y)
    local value = love.math.noise(x + seedOffsetX, y + seedOffsetY)
    return value * 2 - 1  -- convert [0,1] to [-1,1]
end

-- Octave noise for more natural terrain
local function octaveNoise(x, y, octaves, persistence, lacunarity)
    local value    = 0
    local amp      = 1
    local freq     = 1
    local maxValue = 0
    for _ = 1, octaves do
        value    = value + noise2d(x * freq, y * freq) * amp
        maxValue = maxValue + amp
        amp      = amp  * persistence
        freq     = freq * lacunarity
    end
    return value / maxValue  -- normalise to roughly [-1, 1]
end

-- ─── Tile selection ──────────────────────────────────────────────────────────

-- Returns the tile type string for a given world tile coordinate.
-- Two noise layers:
--   elevation – large features (water, plains, hills)
--   detail    – small features (trees, rocks, dirt patches)
function WorldGen.getTileAt(tx, ty)
    local scale = 0.04  -- lower = larger features

    local elev   = octaveNoise(tx * scale,        ty * scale,        4, 0.5, 2.0)
    local detail = octaveNoise(tx * scale * 3 + 100, ty * scale * 3 + 100, 2, 0.5, 2.0)

    -- Water at low elevation
    if elev < -0.35 then return "water" end

    -- Sandy shores
    if elev < -0.20 then return "sand" end

    -- Stone outcrops at high elevation + high detail
    if elev > 0.35 and detail > 0.2 then return "rock" end

    -- Dense forest in mid-high elevation
    if elev > 0.10 and detail > 0.30 then return "tree" end

    -- Dirt patches
    if detail < -0.25 then return "dirt" end

    -- Default: grass
    return "grass"
end

-- Returns a resource type string if a resource node should spawn at (tx, ty),
-- or nil if no node. Called once when a chunk is first generated.
function WorldGen.getResourceAt(tx, ty, tileType)
    -- Resources only spawn on specific tile types
    local resourceMap = {
        tree = "wood",
        rock = "iron",   -- ore underneath rock outcrops
    }
    if resourceMap[tileType] then
        -- Sparse placement: use a simple hash so it's deterministic
        local h = (tx * 374761393 + ty * 1234567891) % 100
        if h < 60 then  -- 60% chance on eligible tile
            return resourceMap[tileType]
        end
    end

    -- Occasional stone nodes on plain grass/dirt
    if tileType == "grass" or tileType == "dirt" then
        local h = (tx * 987654321 + ty * 123456789) % 100
        if h < 3 then return "stone" end  -- 3% chance
    end

    return nil
end

-- ─── Initialisation ──────────────────────────────────────────────────────────

function WorldGen.init(seed)
    -- Set seed offsets for deterministic world generation
    -- Using large prime number multipliers to spread seed values
    seed = seed or 12345
    math.randomseed(seed)
    seedOffsetX = math.random() * 10000
    seedOffsetY = math.random() * 10000
end

return WorldGen
