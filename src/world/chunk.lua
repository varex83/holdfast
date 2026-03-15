-- Chunk System
-- Divides the infinite world into 16×16 tile chunks.
-- Chunks are generated on demand and cached; distant chunks are unloaded.

local Class    = require("lib.class")
local WorldGen = require("src.world.worldgen")

local ChunkManager = Class:extend()

local CHUNK_SIZE   = 16   -- tiles per chunk side
local LOAD_RADIUS  = 4    -- chunks to keep loaded around the player chunk
local UNLOAD_EXTRA = 2    -- unload chunks beyond LOAD_RADIUS + this margin

-- ─── Helpers ─────────────────────────────────────────────────────────────────

-- Convert world tile coords → chunk coords
local function tileToChunk(tx, ty)
    return math.floor(tx / CHUNK_SIZE), math.floor(ty / CHUNK_SIZE)
end

-- Convert chunk coords → world tile origin
local function chunkOrigin(cx, cy)
    return cx * CHUNK_SIZE, cy * CHUNK_SIZE
end

local function chunkKey(cx, cy)
    return cx .. "," .. cy
end

-- ─── ChunkManager ────────────────────────────────────────────────────────────

function ChunkManager:new()
    self._chunks = {}   -- key → chunk table
end

-- Returns (or generates) the chunk at chunk coords (cx, cy).
function ChunkManager:getChunk(cx, cy)
    local key = chunkKey(cx, cy)
    if not self._chunks[key] then
        self._chunks[key] = self:_generate(cx, cy)
    end
    return self._chunks[key]
end

-- Returns the tile type at world tile coords (tx, ty).
function ChunkManager:getTile(tx, ty)
    local cx, cy = tileToChunk(tx, ty)
    local chunk  = self:getChunk(cx, cy)
    local lx = tx - cx * CHUNK_SIZE
    local ly = ty - cy * CHUNK_SIZE
    return chunk.tiles[lx][ly]
end

-- Returns the resource type at world tile coords, or nil.
function ChunkManager:getResource(tx, ty)
    local cx, cy = tileToChunk(tx, ty)
    local chunk  = self:getChunk(cx, cy)
    local lx = tx - cx * CHUNK_SIZE
    local ly = ty - cy * CHUNK_SIZE
    return chunk.resources[lx] and chunk.resources[lx][ly] or nil
end

-- Call each frame with the player's tile position.
-- Ensures all chunks within LOAD_RADIUS are generated; unloads far chunks.
function ChunkManager:update(playerTx, playerTy)
    local pcx, pcy = tileToChunk(playerTx, playerTy)

    -- Load nearby chunks
    for dx = -LOAD_RADIUS, LOAD_RADIUS do
        for dy = -LOAD_RADIUS, LOAD_RADIUS do
            self:getChunk(pcx + dx, pcy + dy)
        end
    end

    -- Unload distant chunks
    local limit = LOAD_RADIUS + UNLOAD_EXTRA
    for key, chunk in pairs(self._chunks) do
        if math.abs(chunk.cx - pcx) > limit or math.abs(chunk.cy - pcy) > limit then
            self._chunks[key] = nil
        end
    end
end

-- Iterate over all tiles in loaded chunks within a screen-visible rect.
-- Calls callback(tx, ty, tileType) for each tile.
-- visRect = {x1, y1, x2, y2} in TILE coordinates.
function ChunkManager:eachVisibleTile(visRect, callback)
    local tx1 = math.floor(visRect.x1) - 1
    local ty1 = math.floor(visRect.y1) - 1
    local tx2 = math.ceil(visRect.x2)  + 1
    local ty2 = math.ceil(visRect.y2)  + 1

    -- Clamp to loaded chunk area to avoid generating off-screen chunks
    local cx1, cy1 = tileToChunk(tx1, ty1)
    local cx2, cy2 = tileToChunk(tx2, ty2)

    for cx = cx1, cx2 do
        for cy = cy1, cy2 do
            local key = chunkKey(cx, cy)
            local chunk = self._chunks[key]
            if chunk then
                local ox, oy = chunkOrigin(cx, cy)
                for lx = 0, CHUNK_SIZE - 1 do
                    for ly = 0, CHUNK_SIZE - 1 do
                        callback(ox + lx, oy + ly, chunk.tiles[lx][ly])
                    end
                end
            end
        end
    end
end

-- ─── Chunk generation ────────────────────────────────────────────────────────

function ChunkManager:_generate(cx, cy)
    local ox, oy = chunkOrigin(cx, cy)
    local tiles     = {}
    local resources = {}

    for lx = 0, CHUNK_SIZE - 1 do
        tiles[lx]     = {}
        resources[lx] = {}
        for ly = 0, CHUNK_SIZE - 1 do
            local tileType         = WorldGen.getTileAt(ox + lx, oy + ly)
            tiles[lx][ly]          = tileType
            resources[lx][ly]      = WorldGen.getResourceAt(ox + lx, oy + ly, tileType)
        end
    end

    return {
        cx        = cx,
        cy        = cy,
        tiles     = tiles,
        resources = resources,
    }
end

-- ─── Constants re-exported ───────────────────────────────────────────────────

ChunkManager.CHUNK_SIZE  = CHUNK_SIZE
ChunkManager.tileToChunk = tileToChunk

return ChunkManager
