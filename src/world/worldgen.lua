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
-- Uses two separate elevation signals:
--   shore – very smooth (2 octaves, low frequency) for clean water/beach borders
--   elev  – full detail (4 octaves) for land biome selection only
--   moist – medium-scale vegetation moisture
--   temp  – large-scale temperature (tree species)
function WorldGen.getTileAt(tx, ty)
    local scale = 0.04

    -- Smooth, low-frequency boundary used only for water/shore/sand thresholds.
    -- Fewer octaves = no small dips that create water islands inside beach zones.
    local shore = octaveNoise(tx * scale * 0.7,        ty * scale * 0.7,        2, 0.5, 2.0)

    -- Full-detail elevation for land biome height (highland/rock detection).
    local elev  = octaveNoise(tx * scale,               ty * scale,               4, 0.5, 2.0)

    local moist = octaveNoise(tx * scale * 0.75 + 200,  ty * scale * 0.75 + 200,  3, 0.5, 2.0)
    local temp  = octaveNoise(tx * scale * 0.5  + 400,  ty * scale * 0.5  + 400,  2, 0.6, 2.0)

    -- ── Water (decided by smooth shore signal) ────────────────────────────────
    if shore < -0.42 then return "water" end

    -- Shore fringe: use temp (slow-varying) for plant patches vs plain water
    if shore < -0.28 then
        if temp >  0.40 then return "lily_pad" end
        if temp < -0.40 then return "cattail"  end
        return "water"
    end

    -- ── Shore ─────────────────────────────────────────────────────────────────
    if shore < -0.14 then return "beach" end
    if shore < -0.02 then return "sand"  end

    -- ── Land (decided by full-detail elev + moist + temp) ────────────────────

    -- Rocky highlands
    if elev > 0.52 then return "rock" end
    if elev > 0.42 and moist < 0.0 then return "rock" end

    -- Forest zones driven by moisture bands
    if moist > 0.45 then
        if elev > 0.05 then
            if temp < -0.20 then return "birch" end
            return "tree"
        end
        if temp > 0.30 then return "mushroom" end
        return "flower"
    end

    if moist > 0.15 then
        if elev > 0.18 then
            if temp < -0.15 then return "birch" end
            return "tree"
        end
        if temp > 0.20 then return "flower" end
        return "tall_grass"
    end

    if moist < -0.30 then return "dirt" end
    return "grass"
end

-- Returns a resource type string if a resource node should spawn at (tx, ty),
-- or nil if no node. Called once when a chunk is first generated.
function WorldGen.getResourceAt(tx, ty, tileType)
    local resourceMap = {
        tree  = "wood",
        birch = "wood",
        rock  = "iron",
    }
    if resourceMap[tileType] then
        local h = (tx * 374761393 + ty * 1234567891) % 100
        if h < 60 then return resourceMap[tileType] end
    end

    -- Occasional stone nodes on open ground
    if tileType == "grass" or tileType == "dirt" or
       tileType == "flower" or tileType == "tall_grass" then
        local h = (tx * 987654321 + ty * 123456789) % 100
        if h < 3 then return "stone" end
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
