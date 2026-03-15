-- Fog of War
-- Tracks which tiles the player has explored.
-- Stores the tile type when first revealed so explored chunks can be
-- drawn even after they have been unloaded from memory.

local Class = require("lib.class")
local Iso   = require("src.rendering.isometric")

local FogOfWar = Class:extend()

local VISION_RADIUS = 7

local function tileKey(tx, ty)
    return tx .. "," .. ty
end

function FogOfWar:new()
    -- _explored[key] = tileType string (persists forever)
    self._explored = {}
    -- _visible[key]  = true           (rebuilt every frame)
    self._visible  = {}
end

-- Rebuild the current-frame visibility set.
function FogOfWar:update(playerTx, playerTy)
    self._visible = {}
    local ptx = math.floor(playerTx + 0.5)
    local pty = math.floor(playerTy + 0.5)
    local r   = VISION_RADIUS
    for dx = -r, r do
        for dy = -r, r do
            if dx * dx + dy * dy <= r * r then
                local key = tileKey(ptx + dx, pty + dy)
                self._visible[key] = true
                -- Mark as explored with a placeholder type if not yet known
                if not self._explored[key] then
                    self._explored[key] = "?"
                end
            end
        end
    end
end

-- Store (or update) the tile type for a tile — call while the chunk is loaded.
function FogOfWar:cacheType(tx, ty, tileType)
    local key = tileKey(tx, ty)
    if self._explored[key] then
        self._explored[key] = tileType
    end
end

-- Returns the cached tile type string, or nil if never explored.
function FogOfWar:getCachedType(tx, ty)
    local v = self._explored[tileKey(tx, ty)]
    if v and v ~= "?" then return v end
    return nil
end

-- Returns "visible" | "explored" | "hidden"
function FogOfWar:getState(tx, ty)
    local key = tileKey(tx, ty)
    if self._visible[key]  then return "visible"  end
    if self._explored[key] then return "explored" end
    return "hidden"
end

function FogOfWar:isVisible(tx, ty)
    return self._visible[tileKey(tx, ty)] == true
end

function FogOfWar:isExplored(tx, ty)
    return self._explored[tileKey(tx, ty)] ~= nil
end

FogOfWar.VISION_RADIUS = VISION_RADIUS

return FogOfWar
