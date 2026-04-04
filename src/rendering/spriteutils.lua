--- Sprite Utility Module
-- Provides common sprite loading and rendering operations

local SpriteUtils = {}

--- Load an image from a sprite definition
-- @param spriteDef Sprite definition table with path field
-- @return Love2D Image object or nil if failed
function SpriteUtils.loadImage(spriteDef)
    if not spriteDef or not spriteDef.path then
        return nil
    end

    local success, result = pcall(function()
        return love.graphics.newImage(spriteDef.path)
    end)

    if success then
        return result
    else
        print("Warning: Failed to load image: " .. tostring(spriteDef.path))
        return nil
    end
end

--- Draw an isometric diamond shape
-- Used for building footprints and placeholders
-- @param sx Screen x coordinate (center)
-- @param sy Screen y coordinate (center)
-- @param width Diamond width
-- @param height Diamond height
-- @param fillColor Fill color table {r, g, b, a}
-- @param outlineColor Optional outline color table
function SpriteUtils.drawIsoDiamond(sx, sy, width, height, fillColor, outlineColor)
    width = width or 32
    height = height or 16

    local halfW = width / 2
    local halfH = height / 2

    -- Diamond vertices (top, right, bottom, left)
    local vertices = {
        sx, sy - halfH,           -- Top
        sx + halfW, sy,           -- Right
        sx, sy + halfH,           -- Bottom
        sx - halfW, sy            -- Left
    }

    -- Draw fill
    if fillColor then
        love.graphics.setColor(fillColor[1], fillColor[2], fillColor[3], fillColor[4] or 1)
        love.graphics.polygon('fill', vertices)
    end

    -- Draw outline
    if outlineColor then
        love.graphics.setColor(outlineColor[1], outlineColor[2], outlineColor[3], outlineColor[4] or 1)
        love.graphics.polygon('line', vertices)
    end

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

--- Draw an isometric rectangle
-- Used for wall segments and rectangular buildings
-- @param sx Screen x coordinate (center)
-- @param sy Screen y coordinate (top)
-- @param width Rectangle width
-- @param depth Isometric depth
-- @param height Rectangle height
-- @param fillColor Fill color table
-- @param outlineColor Optional outline color table
function SpriteUtils.drawIsoRect(sx, sy, width, depth, height, fillColor, outlineColor)
    width = width or 32
    depth = depth or 16
    height = height or 32

    local halfW = width / 2
    local halfD = depth / 2

    -- Top face (diamond)
    local topVertices = {
        sx, sy,                   -- Top
        sx + halfW, sy + halfD,   -- Right
        sx, sy + depth,           -- Bottom
        sx - halfW, sy + halfD    -- Left
    }

    -- Front face (left side)
    local frontVertices = {
        sx - halfW, sy + halfD,
        sx, sy + depth,
        sx, sy + depth + height,
        sx - halfW, sy + halfD + height
    }

    -- Right face
    local rightVertices = {
        sx, sy + depth,
        sx + halfW, sy + halfD,
        sx + halfW, sy + halfD + height,
        sx, sy + depth + height
    }

    -- Draw faces
    if fillColor then
        love.graphics.setColor(fillColor[1], fillColor[2], fillColor[3], fillColor[4] or 1)

        -- Draw darker shades for depth
        local frontShade = {fillColor[1] * 0.7, fillColor[2] * 0.7, fillColor[3] * 0.7, fillColor[4] or 1}
        local rightShade = {fillColor[1] * 0.85, fillColor[2] * 0.85, fillColor[3] * 0.85, fillColor[4] or 1}

        love.graphics.setColor(frontShade)
        love.graphics.polygon('fill', frontVertices)

        love.graphics.setColor(rightShade)
        love.graphics.polygon('fill', rightVertices)

        love.graphics.setColor(fillColor)
        love.graphics.polygon('fill', topVertices)
    end

    -- Draw outlines
    if outlineColor then
        love.graphics.setColor(outlineColor[1], outlineColor[2], outlineColor[3], outlineColor[4] or 1)
        love.graphics.polygon('line', topVertices)
        love.graphics.polygon('line', frontVertices)
        love.graphics.polygon('line', rightVertices)
    end

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

--- Draw a sprite with optional offset and scale
-- @param image Love2D Image object
-- @param x Screen x coordinate
-- @param y Screen y coordinate
-- @param offsetX Optional x offset (default: center)
-- @param offsetY Optional y offset (default: center)
-- @param scaleX Optional x scale (default: 1)
-- @param scaleY Optional y scale (default: 1)
-- @param rotation Optional rotation in radians (default: 0)
function SpriteUtils.drawSprite(image, x, y, offsetX, offsetY, scaleX, scaleY, rotation)
    if not image then return end

    local width = image:getWidth()
    local height = image:getHeight()

    offsetX = offsetX or (width / 2)
    offsetY = offsetY or (height / 2)
    scaleX = scaleX or 1
    scaleY = scaleY or 1
    rotation = rotation or 0

    love.graphics.draw(image, x, y, rotation, scaleX, scaleY, offsetX, offsetY)
end

--- Create a simple colored rectangle image
-- Useful for placeholder sprites
-- @param width Rectangle width
-- @param height Rectangle height
-- @param color Color table {r, g, b, a}
-- @return Love2D Canvas that can be used as an image
function SpriteUtils.createColoredRect(width, height, color)
    local canvas = love.graphics.newCanvas(width, height)

    love.graphics.setCanvas(canvas)
    love.graphics.clear()
    love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
    love.graphics.rectangle('fill', 0, 0, width, height)
    love.graphics.setCanvas()

    love.graphics.setColor(1, 1, 1, 1)

    return canvas
end

--- Batch load multiple sprites from definitions
-- @param spriteDefs Table of sprite definitions {name = {path = "..."}, ...}
-- @return Table of loaded images {name = Image, ...}
function SpriteUtils.loadSprites(spriteDefs)
    local sprites = {}

    for name, def in pairs(spriteDefs) do
        sprites[name] = SpriteUtils.loadImage(def)
    end

    return sprites
end

return SpriteUtils
