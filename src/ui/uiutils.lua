--- UI Utility Module
-- Provides common UI rendering operations (progress bars, fonts, etc.)

local UIUtils = {}

-- Font cache to prevent creating duplicate fonts
local fontCache = {}

--- Draw a progress bar
-- @param x Bar x coordinate (top-left)
-- @param y Bar y coordinate (top-left)
-- @param width Bar width
-- @param height Bar height
-- @param progress Progress value (0-1)
-- @param fillColor Fill color table {r, g, b, a}
-- @param backgroundColor Background color table (optional)
-- @param borderColor Border color table (optional)
-- @param label Optional text label to display in center
function UIUtils.drawProgressBar(x, y, width, height, progress, fillColor, backgroundColor, borderColor, label)
    progress = math.max(0, math.min(1, progress))

    -- Draw background
    if backgroundColor then
        love.graphics.setColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4] or 1)
        love.graphics.rectangle('fill', x, y, width, height)
    end

    -- Draw fill
    if progress > 0 and fillColor then
        love.graphics.setColor(fillColor[1], fillColor[2], fillColor[3], fillColor[4] or 1)
        love.graphics.rectangle('fill', x, y, width * progress, height)
    end

    -- Draw border
    if borderColor then
        love.graphics.setColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4] or 1)
        love.graphics.rectangle('line', x, y, width, height)
    end

    -- Draw label
    if label then
        local font = love.graphics.getFont()
        local textWidth = font:getWidth(label)
        local textHeight = font:getHeight()

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(label,
            x + (width - textWidth) / 2,
            y + (height - textHeight) / 2)
    end

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

--- Draw a vertical progress bar
-- @param x Bar x coordinate (top-left)
-- @param y Bar y coordinate (top-left)
-- @param width Bar width
-- @param height Bar height
-- @param progress Progress value (0-1)
-- @param fillColor Fill color table
-- @param backgroundColor Background color table (optional)
-- @param borderColor Border color table (optional)
function UIUtils.drawProgressBarVertical(x, y, width, height, progress, fillColor, backgroundColor, borderColor)
    progress = math.max(0, math.min(1, progress))

    -- Draw background
    if backgroundColor then
        love.graphics.setColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4] or 1)
        love.graphics.rectangle('fill', x, y, width, height)
    end

    -- Draw fill (from bottom up)
    if progress > 0 and fillColor then
        local fillHeight = height * progress
        love.graphics.setColor(fillColor[1], fillColor[2], fillColor[3], fillColor[4] or 1)
        love.graphics.rectangle('fill', x, y + height - fillHeight, width, fillHeight)
    end

    -- Draw border
    if borderColor then
        love.graphics.setColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4] or 1)
        love.graphics.rectangle('line', x, y, width, height)
    end

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

--- Get or create a font (cached)
-- @param size Font size
-- @param fontPath Optional path to font file (default: Love2D default font)
-- @return Love2D Font object
function UIUtils.getFont(size, fontPath)
    local key = (fontPath or "default") .. "_" .. size

    if not fontCache[key] then
        if fontPath then
            local success, font = pcall(function()
                return love.graphics.newFont(fontPath, size)
            end)
            if success then
                fontCache[key] = font
            else
                print("Warning: Failed to load font: " .. fontPath)
                fontCache[key] = love.graphics.newFont(size)
            end
        else
            fontCache[key] = love.graphics.newFont(size)
        end
    end

    return fontCache[key]
end

--- Lazy load fonts for a state
-- Initializes fonts only when first accessed
-- @param state State object to add lazy font loading to
-- @param fontDefinitions Table of font definitions {name = {size=12, path="..."}, ...}
function UIUtils.lazyLoadFonts(state, fontDefinitions)
    state._fonts = state._fonts or {}
    state._fontDefs = fontDefinitions

    -- Create metatable for lazy loading
    local fontProxy = setmetatable({}, {
        __index = function(_, key)
            if not state._fonts[key] and state._fontDefs[key] then
                local def = state._fontDefs[key]
                state._fonts[key] = UIUtils.getFont(def.size, def.path)
            end
            return state._fonts[key]
        end
    })

    state.fonts = fontProxy
end

--- Draw a text with shadow
-- @param text Text to draw
-- @param x Text x coordinate
-- @param y Text y coordinate
-- @param color Text color table (optional, default: white)
-- @param shadowColor Shadow color table (optional, default: black)
-- @param shadowOffset Shadow offset in pixels (optional, default: 1)
function UIUtils.drawTextWithShadow(text, x, y, color, shadowColor, shadowOffset)
    color = color or {1, 1, 1, 1}
    shadowColor = shadowColor or {0, 0, 0, 0.5}
    shadowOffset = shadowOffset or 1

    -- Draw shadow
    love.graphics.setColor(shadowColor[1], shadowColor[2], shadowColor[3], shadowColor[4] or 1)
    love.graphics.print(text, x + shadowOffset, y + shadowOffset)

    -- Draw text
    love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
    love.graphics.print(text, x, y)

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

--- Draw a simple panel/box
-- @param x Panel x coordinate
-- @param y Panel y coordinate
-- @param width Panel width
-- @param height Panel height
-- @param backgroundColor Background color (optional)
-- @param borderColor Border color (optional)
-- @param borderWidth Border width (optional, default: 1)
function UIUtils.drawPanel(x, y, width, height, backgroundColor, borderColor, borderWidth)
    borderWidth = borderWidth or 1

    -- Draw background
    if backgroundColor then
        love.graphics.setColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4] or 1)
        love.graphics.rectangle('fill', x, y, width, height)
    end

    -- Draw border
    if borderColor then
        love.graphics.setColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4] or 1)
        love.graphics.setLineWidth(borderWidth)
        love.graphics.rectangle('line', x, y, width, height)
        love.graphics.setLineWidth(1)
    end

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

--- Draw centered text
-- @param text Text to draw
-- @param x Center x coordinate
-- @param y Center y coordinate
-- @param color Text color (optional)
function UIUtils.drawCenteredText(text, x, y, color)
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(text)
    local textHeight = font:getHeight()

    if color then
        love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
    end

    love.graphics.print(text, x - textWidth / 2, y - textHeight / 2)

    love.graphics.setColor(1, 1, 1, 1)
end

--- Draw a tooltip
-- @param text Tooltip text
-- @param x Mouse x coordinate
-- @param y Mouse y coordinate
-- @param backgroundColor Background color (optional)
-- @param textColor Text color (optional)
-- @param padding Padding around text (optional, default: 5)
function UIUtils.drawTooltip(text, x, y, backgroundColor, textColor, padding)
    backgroundColor = backgroundColor or {0.1, 0.1, 0.1, 0.9}
    textColor = textColor or {1, 1, 1, 1}
    padding = padding or 5

    local font = love.graphics.getFont()
    local textWidth = font:getWidth(text)
    local textHeight = font:getHeight()

    local boxWidth = textWidth + padding * 2
    local boxHeight = textHeight + padding * 2

    -- Adjust position to keep on screen
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    if x + boxWidth > screenWidth then
        x = screenWidth - boxWidth
    end
    if y + boxHeight > screenHeight then
        y = screenHeight - boxHeight
    end

    -- Draw background
    love.graphics.setColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4] or 1)
    love.graphics.rectangle('fill', x, y, boxWidth, boxHeight)

    -- Draw border
    love.graphics.setColor(0.3, 0.3, 0.3, 1)
    love.graphics.rectangle('line', x, y, boxWidth, boxHeight)

    -- Draw text
    love.graphics.setColor(textColor[1], textColor[2], textColor[3], textColor[4] or 1)
    love.graphics.print(text, x + padding, y + padding)

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

return UIUtils
