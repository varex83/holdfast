--- Math Utility Module
-- Provides common mathematical operations and safe float comparisons

local MathUtils = {}

-- Epsilon for float comparison
local EPSILON = 0.0001

--- Clamp a value between min and max
-- @param value The value to clamp
-- @param min Minimum value
-- @param max Maximum value
-- @return Clamped value
function MathUtils.clamp(value, min, max)
    if value < min then return min end
    if value > max then return max end
    return value
end

--- Linear interpolation
-- @param a Start value
-- @param b End value
-- @param t Interpolation factor (0-1)
-- @return Interpolated value
function MathUtils.lerp(a, b, t)
    return a + (b - a) * t
end

--- Get the sign of a number
-- @param x The number
-- @return 1 if positive, -1 if negative, 0 if zero
function MathUtils.sign(x)
    if x > 0 then return 1 end
    if x < 0 then return -1 end
    return 0
end

--- Check if two floats are approximately equal
-- @param a First value
-- @param b Second value
-- @param epsilon Optional epsilon value (default: 0.0001)
-- @return true if values are within epsilon of each other
function MathUtils.approximately(a, b, epsilon)
    epsilon = epsilon or EPSILON
    return math.abs(a - b) < epsilon
end

--- Check if a float is approximately zero
-- @param x The value to check
-- @param epsilon Optional epsilon value (default: 0.0001)
-- @return true if value is within epsilon of zero
function MathUtils.approximatelyZero(x, epsilon)
    epsilon = epsilon or EPSILON
    return math.abs(x) < epsilon
end

--- Round a number to the nearest integer
-- @param x The number to round
-- @return Rounded value
function MathUtils.round(x)
    return math.floor(x + 0.5)
end

--- Round a number to a specific number of decimal places
-- @param x The number to round
-- @param decimals Number of decimal places
-- @return Rounded value
function MathUtils.roundTo(x, decimals)
    local mult = 10 ^ decimals
    return math.floor(x * mult + 0.5) / mult
end

--- Map a value from one range to another
-- @param value The value to map
-- @param inMin Input range minimum
-- @param inMax Input range maximum
-- @param outMin Output range minimum
-- @param outMax Output range maximum
-- @return Mapped value
function MathUtils.map(value, inMin, inMax, outMin, outMax)
    return (value - inMin) * (outMax - outMin) / (inMax - inMin) + outMin
end

--- Wrap a value to a range
-- @param value The value to wrap
-- @param min Range minimum
-- @param max Range maximum
-- @return Wrapped value
function MathUtils.wrap(value, min, max)
    local range = max - min
    while value < min do
        value = value + range
    end
    while value >= max do
        value = value - range
    end
    return value
end

--- Check if a value is within a range (inclusive)
-- @param value The value to check
-- @param min Range minimum
-- @param max Range maximum
-- @return true if value is in range
function MathUtils.inRange(value, min, max)
    return value >= min and value <= max
end

return MathUtils
