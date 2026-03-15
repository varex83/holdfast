-- Position Component
-- Stores entity position in world coordinates

local Component = require('src.ecs.component')

local Position = {}

-- Create a Position component
function Position.create(x, y, entity)
    local component = {
        type = 'position',
        entity = entity
    }

    component.x = x or 0
    component.y = y or 0

    -- Set position
    function component:set(newX, newY)
        self.x = newX
        self.y = newY
    end

    -- Move by delta
    function component:move(dx, dy)
        self.x = self.x + dx
        self.y = self.y + dy
    end

    -- Get position as table
    function component:get()
        return { x = self.x, y = self.y }
    end

    -- Get distance to another position
    function component:distanceTo(otherX, otherY)
        local dx = otherX - self.x
        local dy = otherY - self.y
        return math.sqrt(dx * dx + dy * dy)
    end

    -- Get angle to another position (in radians)
    function component:angleTo(otherX, otherY)
        return math.atan2(otherY - self.y, otherX - self.x)
    end

    return component
end

return Position
