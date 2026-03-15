-- Hitbox Component
-- AABB collision box for entities

local Component = require('src.ecs.component')

local Hitbox = {}

-- Create a Hitbox component
function Hitbox.create(width, height, offsetX, offsetY, entity)
    local component = {
        type = 'hitbox',
        entity = entity
    }

    component.width = width or 32
    component.height = height or 32
    component.offsetX = offsetX or 0
    component.offsetY = offsetY or 0

    -- Type can be 'hurtbox' (receives damage) or 'hitbox' (deals damage)
    component.type = 'hurtbox'

    -- Team for collision filtering (e.g., 'player', 'enemy')
    component.team = nil

    -- Get AABB bounds (requires position component on entity)
    function component:getBounds(position)
        local x = position.x + self.offsetX
        local y = position.y + self.offsetY

        return {
            left = x - self.width / 2,
            right = x + self.width / 2,
            top = y - self.height / 2,
            bottom = y + self.height / 2,
            centerX = x,
            centerY = y
        }
    end

    -- Check collision with another hitbox
    function component:collidesWith(otherBounds)
        local myBounds = self:getBounds()

        return not (
            myBounds.right < otherBounds.left or
            myBounds.left > otherBounds.right or
            myBounds.bottom < otherBounds.top or
            myBounds.top > otherBounds.bottom
        )
    end

    -- Check if a point is inside the hitbox
    function component:containsPoint(x, y, position)
        local bounds = self:getBounds(position)
        return x >= bounds.left and x <= bounds.right and
               y >= bounds.top and y <= bounds.bottom
    end

    return component
end

return Hitbox
