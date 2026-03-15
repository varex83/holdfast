-- World Generation
-- Perlin noise-based infinite world with biomes and resource node placement.

local WorldGen = {}

-- ─── Permutation table (classic Perlin) ─────────────────────────────────────

local P = {}

local function buildPermutation(seed)
    math.randomseed(seed or 12345)
    local base = {}
    for i = 0, 255 do base[i] = i end
    -- Fisher-Yates shuffle
    for i = 255, 1, -1 do
        local j = math.random(0, i)
        base[i], base[j] = base[j], base[i]
    end
    -- Double the table to avoid index wrapping
    for i = 0, 511 do P[i] = base[i % 256] end
end

-- ─── Perlin helpers ──────────────────────────────────────────────────────────

local function fade(t)  return t * t * t * (t * (t * 6 - 15) + 10) end
local function lerp(a, b, t) return a + t * (b - a) end

local function grad(hash, x, y)
    local h = hash % 4
    if h == 0 then return  x + y
    elseif h == 1 then return -x + y
    elseif h == 2 then return  x - y
    else               return -x - y
    end
end

local function noise2d(x, y)
    local xi = math.floor(x) % 256
    local yi = math.floor(y) % 256
    local xf = x - math.floor(x)
    local yf = y - math.floor(y)

    local u = fade(xf)
    local v = fade(yf)

    local aa = P[P[xi]     + yi]
    local ab = P[P[xi]     + yi + 1]
    local ba = P[P[xi + 1] + yi]
    local bb = P[P[xi + 1] + yi + 1]

    return lerp(
        lerp(grad(aa, xf,     yf    ), grad(ba, xf - 1, yf    ), u),
        lerp(grad(ab, xf,     yf - 1), grad(bb, xf - 1, yf - 1), u),
        v
    )
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
    buildPermutation(seed)
end

return WorldGen
