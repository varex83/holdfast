--- Vector Math Utility Module
-- Provides common 2D vector operations to eliminate duplicate math code
-- across the codebase.

local Vector = {}

--- Calculate the distance between two points
-- @param x1 First point x coordinate
-- @param y1 First point y coordinate
-- @param x2 Second point x coordinate
-- @param y2 Second point y coordinate
-- @return The Euclidean distance between the two points
function Vector.distance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

--- Calculate the magnitude (length) of a vector
-- @param x Vector x component
-- @param y Vector y component
-- @return The magnitude of the vector
function Vector.magnitude(x, y)
    return math.sqrt(x * x + y * y)
end

--- Normalize a vector to unit length
-- @param x Vector x component
-- @param y Vector y component
-- @return Normalized x and y components (0, 0 if zero vector)
function Vector.normalize(x, y)
    local mag = Vector.magnitude(x, y)
    if mag == 0 then
        return 0, 0
    end
    return x / mag, y / mag
end

--- Calculate the dot product of two vectors
-- @param x1 First vector x component
-- @param y1 First vector y component
-- @param x2 Second vector x component
-- @param y2 Second vector y component
-- @return The dot product
function Vector.dot(x1, y1, x2, y2)
    return x1 * x2 + y1 * y2
end

--- Calculate the angle between two points
-- @param x1 First point x coordinate
-- @param y1 First point y coordinate
-- @param x2 Second point x coordinate
-- @param y2 Second point y coordinate
-- @return The angle in radians
function Vector.angle(x1, y1, x2, y2)
    return math.atan2(y2 - y1, x2 - x1)
end

--- Calculate the angle of a vector
-- @param x Vector x component
-- @param y Vector y component
-- @return The angle in radians
function Vector.angleOf(x, y)
    return math.atan2(y, x)
end

--- Rotate a vector by an angle
-- @param x Vector x component
-- @param y Vector y component
-- @param angle Rotation angle in radians
-- @return Rotated x and y components
function Vector.rotate(x, y, angle)
    local cos = math.cos(angle)
    local sin = math.sin(angle)
    return x * cos - y * sin, x * sin + y * cos
end

--- Linear interpolation between two vectors
-- @param x1 Start vector x component
-- @param y1 Start vector y component
-- @param x2 End vector x component
-- @param y2 End vector y component
-- @param t Interpolation factor (0-1)
-- @return Interpolated x and y components
function Vector.lerp(x1, y1, x2, y2, t)
    return x1 + (x2 - x1) * t, y1 + (y2 - y1) * t
end

--- Scale a vector by a scalar
-- @param x Vector x component
-- @param y Vector y component
-- @param scale Scaling factor
-- @return Scaled x and y components
function Vector.scale(x, y, scale)
    return x * scale, y * scale
end

--- Add two vectors
-- @param x1 First vector x component
-- @param y1 First vector y component
-- @param x2 Second vector x component
-- @param y2 Second vector y component
-- @return Sum x and y components
function Vector.add(x1, y1, x2, y2)
    return x1 + x2, y1 + y2
end

--- Subtract two vectors
-- @param x1 First vector x component
-- @param y1 First vector y component
-- @param x2 Second vector x component
-- @param y2 Second vector y component
-- @return Difference x and y components
function Vector.subtract(x1, y1, x2, y2)
    return x1 - x2, y1 - y2
end

--- Limit the magnitude of a vector
-- @param x Vector x component
-- @param y Vector y component
-- @param maxMag Maximum magnitude
-- @return Limited x and y components
function Vector.limit(x, y, maxMag)
    local mag = Vector.magnitude(x, y)
    if mag > maxMag then
        return Vector.scale(x, y, maxMag / mag)
    end
    return x, y
end

return Vector
