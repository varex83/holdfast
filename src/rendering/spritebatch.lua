-- Sprite Batch
-- Reduces draw calls by grouping isometric tile polygons by colour.
-- Usage:
--   batch:addTile(tx, ty, r, g, b, a)   -- queue a tile
--   batch:flush()                         -- draw all queued tiles + clear
--
-- When real sprite sheets are available, swap addTile to use a SpriteBatch
-- (love.graphics.newSpriteBatch) keyed by texture instead of colour.

local Class = require("lib.class")
local Iso   = require("src.rendering.isometric")

local TileBatch = Class:extend()

local TILE_W = Iso.TILE_W
local TILE_H = Iso.TILE_H

-- Pre-build the diamond vertex offsets (relative to tile screen origin)
local VERTS = {
    0,           0,           -- top
    TILE_W * 0.5, TILE_H * 0.5, -- right
    0,           TILE_H,      -- bottom
    -TILE_W * 0.5, TILE_H * 0.5  -- left
}

function TileBatch:new()
    -- Groups tiles by colour key "r,g,b,a"
    -- Each group: { r, g, b, a, polys = {{x1,y1,...}, ...} }
    self._groups = {}
    self._order  = {}  -- insertion-order list of colour keys
end

local function colorKey(r, g, b, a)
    -- Round to 2 dp to avoid key explosion from float noise
    return string.format("%.2f,%.2f,%.2f,%.2f", r, g, b, a)
end

-- Queue a tile at tile coords (tx, ty) with colour (r, g, b, a).
function TileBatch:addTile(tx, ty, r, g, b, a)
    a = a or 1
    local key = colorKey(r, g, b, a)
    local group = self._groups[key]
    if not group then
        group = { r = r, g = g, b = b, a = a, verts = {} }
        self._groups[key] = group
        self._order[#self._order + 1] = key
    end

    local sx, sy = Iso.tileToScreen(tx, ty)
    local v = group.verts
    local n = #v
    -- Append 4 vertices (x,y pairs) for this tile's diamond
    v[n+1]  = sx + VERTS[1];  v[n+2]  = sy + VERTS[2]
    v[n+3]  = sx + VERTS[3];  v[n+4]  = sy + VERTS[4]
    v[n+5]  = sx + VERTS[5];  v[n+6]  = sy + VERTS[6]
    v[n+7]  = sx + VERTS[7];  v[n+8]  = sy + VERTS[8]
end

-- Draw all queued tiles grouped by colour, then clear.
function TileBatch:flush()
    for _, key in ipairs(self._order) do
        local g = self._groups[key]
        love.graphics.setColor(g.r, g.g, g.b, g.a)
        -- Draw each diamond as a separate polygon (4 verts at a time)
        local v = g.verts
        for i = 1, #v, 8 do
            love.graphics.polygon("fill",
                v[i],   v[i+1],
                v[i+2], v[i+3],
                v[i+4], v[i+5],
                v[i+6], v[i+7]
            )
        end
    end
    self:clear()
end

-- Optionally draw outlines in a second pass (cheaper than per-tile outline).
function TileBatch:flushOutlines(r, g, b, a)
    love.graphics.setColor(r or 0, g or 0, b or 0, a or 0.25)
    for _, key in ipairs(self._order) do
        local gv = self._groups[key].verts
        for i = 1, #gv, 8 do
            love.graphics.polygon("line",
                gv[i],   gv[i+1],
                gv[i+2], gv[i+3],
                gv[i+4], gv[i+5],
                gv[i+6], gv[i+7]
            )
        end
    end
end

function TileBatch:clear()
    self._groups = {}
    self._order  = {}
end

return TileBatch
