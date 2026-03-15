-- Isometric Renderer
-- Converts between tile (world) coordinates and screen coordinates.
-- Tile size: 64 wide × 32 tall (standard 2:1 isometric diamond).

local Iso = {}

local TILE_W = 64
local TILE_H = 32

-- Tile (integer grid) → screen pixel offset (relative to world origin)
-- The origin tile (0,0) maps to screen (0,0).
function Iso.tileToScreen(tx, ty)
    local sx = (tx - ty) * (TILE_W * 0.5)
    local sy = (tx + ty) * (TILE_H * 0.5)
    return sx, sy
end

-- Screen pixel (relative to world origin) → tile coords (may be fractional)
function Iso.screenToTile(sx, sy)
    local tx = (sx / (TILE_W * 0.5) + sy / (TILE_H * 0.5)) * 0.5
    local ty = (sy / (TILE_H * 0.5) - sx / (TILE_W * 0.5)) * 0.5
    return tx, ty
end

-- Snap continuous tile coords to the nearest integer tile
function Iso.snapToGrid(tx, ty)
    return math.floor(tx + 0.5), math.floor(ty + 0.5)
end

-- Draw a coloured diamond for a tile at tile position (tx, ty).
-- `r,g,b,a` are optional Love2D colour components (defaults to white).
-- The diamond top-left vertex is placed at the screen position returned by
-- tileToScreen, so the camera transform must already be applied.
function Iso.drawTile(tx, ty, r, g, b, a)
    local sx, sy = Iso.tileToScreen(tx, ty)
    r = r or 1; g = g or 1; b = b or 1; a = a or 1

    love.graphics.setColor(r, g, b, a)
    -- Diamond polygon (top, right, bottom, left vertices)
    love.graphics.polygon("fill",
        sx,              sy,               -- top
        sx + TILE_W*0.5, sy + TILE_H*0.5, -- right
        sx,              sy + TILE_H,      -- bottom
        sx - TILE_W*0.5, sy + TILE_H*0.5  -- left
    )

    -- Outline
    love.graphics.setColor(r * 0.6, g * 0.6, b * 0.6, a)
    love.graphics.polygon("line",
        sx,              sy,
        sx + TILE_W*0.5, sy + TILE_H*0.5,
        sx,              sy + TILE_H,
        sx - TILE_W*0.5, sy + TILE_H*0.5
    )
end

-- Draw a sprite (Love2D Image/Quad) centered on a tile.
-- `ox`, `oy` are optional pixel offsets for fine-tuning sprite alignment.
function Iso.drawSprite(image, tx, ty, ox, oy)
    local sx, sy = Iso.tileToScreen(tx, ty)
    ox = ox or 0
    oy = oy or 0
    local iw, ih = image:getDimensions()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(image, sx - iw * 0.5 + ox, sy - ih * 0.5 + oy)
end

-- Highlight the tile under the mouse cursor (useful for build ghost previews).
-- `camera` must expose :screenToWorld(sx, sy).
function Iso.getHoveredTile(camera)
    local mx, my = love.mouse.getPosition()
    local wx, wy = camera:screenToWorld(mx, my)
    local tx, ty = Iso.screenToTile(wx, wy)
    return Iso.snapToGrid(tx, ty)
end

-- Expose tile dimensions for other modules
Iso.TILE_W = TILE_W
Iso.TILE_H = TILE_H

return Iso
