--- Color Palette Module
-- Centralized color definitions used across the codebase
-- Eliminates hardcoded color values and provides consistent theming

local Colors = {}

-- Color definitions
Colors.WHITE = {1, 1, 1, 1}
Colors.BLACK = {0, 0, 0, 1}
Colors.RED = {1, 0, 0, 1}
Colors.GREEN = {0, 1, 0, 1}
Colors.BLUE = {0, 0, 1, 1}
Colors.YELLOW = {1, 1, 0, 1}
Colors.CYAN = {0, 1, 1, 1}
Colors.MAGENTA = {1, 0, 1, 1}
Colors.ORANGE = {1, 0.5, 0, 1}
Colors.PURPLE = {0.5, 0, 1, 1}
Colors.PINK = {1, 0.75, 0.8, 1}
Colors.BROWN = {0.6, 0.3, 0, 1}
Colors.GRAY = {0.5, 0.5, 0.5, 1}
Colors.LIGHT_GRAY = {0.75, 0.75, 0.75, 1}
Colors.DARK_GRAY = {0.25, 0.25, 0.25, 1}

-- Game-specific colors
Colors.GRASS = {0.2, 0.6, 0.2, 1}
Colors.DIRT = {0.4, 0.3, 0.1, 1}
Colors.STONE = {0.5, 0.5, 0.5, 1}
Colors.WATER = {0.2, 0.4, 0.8, 1}
Colors.SAND = {0.9, 0.8, 0.5, 1}

-- UI colors
Colors.UI_BACKGROUND = {0.1, 0.1, 0.1, 0.8}
Colors.UI_BORDER = {0.3, 0.3, 0.3, 1}
Colors.UI_TEXT = {0.9, 0.9, 0.9, 1}
Colors.UI_HIGHLIGHT = {0.4, 0.6, 1, 1}
Colors.UI_SUCCESS = {0.2, 0.8, 0.2, 1}
Colors.UI_WARNING = {1, 0.8, 0, 1}
Colors.UI_ERROR = {1, 0.2, 0.2, 1}

-- Health bar colors
Colors.HEALTH_FULL = {0.2, 0.8, 0.2, 1}
Colors.HEALTH_MEDIUM = {1, 0.8, 0, 1}
Colors.HEALTH_LOW = {1, 0.2, 0.2, 1}
Colors.HEALTH_BACKGROUND = {0.2, 0.2, 0.2, 0.8}

-- Resource colors
Colors.WOOD = {0.6, 0.3, 0.1, 1}
Colors.IRON = {0.6, 0.6, 0.7, 1}
Colors.ROPE = {0.8, 0.7, 0.4, 1}
Colors.FOOD = {1, 0.4, 0.2, 1}
Colors.CLOTH = {0.9, 0.9, 0.9, 1}

-- Building colors
Colors.BUILDING_VALID = {0.2, 1, 0.2, 0.5}
Colors.BUILDING_INVALID = {1, 0.2, 0.2, 0.5}
Colors.BUILDING_WOOD = {0.6, 0.4, 0.2, 1}
Colors.BUILDING_STONE = {0.5, 0.5, 0.5, 1}
Colors.BUILDING_REINFORCED = {0.3, 0.3, 0.4, 1}

-- Enemy colors
Colors.ENEMY_FLY = {0.4, 0.4, 0.2, 1}
Colors.ENEMY_SHAMBLER = {0.3, 0.5, 0.3, 1}
Colors.ENEMY_HOUND = {0.6, 0.3, 0.2, 1}
Colors.ENEMY_BRUTE = {0.7, 0.2, 0.2, 1}
Colors.ENEMY_SPITTER = {0.4, 0.7, 0.4, 1}
Colors.ENEMY_WRAITH = {0.5, 0.3, 0.7, 0.7}
Colors.ENEMY_SIEGE = {0.8, 0.1, 0.1, 1}

-- Class colors
Colors.WARRIOR = {0.8, 0.2, 0.2, 1}
Colors.ARCHER = {0.2, 0.8, 0.2, 1}
Colors.ENGINEER = {1, 0.8, 0.2, 1}
Colors.SCOUT = {0.4, 0.6, 1, 1}

-- Debug colors
Colors.DEBUG_HITBOX = {1, 0, 0, 0.3}
Colors.DEBUG_PATH = {0, 1, 0, 0.5}
Colors.DEBUG_GRID = {0.3, 0.3, 0.3, 0.3}
Colors.DEBUG_TEXT = {1, 1, 0, 1}

--- Set the current drawing color
-- @param color Color table {r, g, b, a} (values 0-1)
function Colors.set(color)
    if color and #color >= 3 then
        love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end
end

--- Create a new color with modified alpha
-- @param color Base color table
-- @param alpha New alpha value (0-1)
-- @return New color table with modified alpha
function Colors.withAlpha(color, alpha)
    return {color[1], color[2], color[3], alpha}
end

--- Blend two colors
-- @param color1 First color
-- @param color2 Second color
-- @param t Blend factor (0-1, 0=full color1, 1=full color2)
-- @return Blended color
function Colors.blend(color1, color2, t)
    return {
        color1[1] + (color2[1] - color1[1]) * t,
        color1[2] + (color2[2] - color1[2]) * t,
        color1[3] + (color2[3] - color1[3]) * t,
        color1[4] + (color2[4] - color1[4]) * t
    }
end

--- Get health color based on percentage
-- @param healthPct Health percentage (0-1)
-- @return Color table for health bar
function Colors.getHealthColor(healthPct)
    if healthPct > 0.6 then
        return Colors.HEALTH_FULL
    elseif healthPct > 0.3 then
        return Colors.HEALTH_MEDIUM
    else
        return Colors.HEALTH_LOW
    end
end

return Colors
