-- Velocity Component
-- Stores entity velocity for movement

local Component = require('src.ecs.component')

local Velocity = {}

-- Create a Velocity component
function Velocity.create(vx, vy, entity)
    local component = {
        type = 'velocity',
        entity = entity
    }

    component.vx = vx or 0
    component.vy = vy or 0

    -- Set velocity
    function component:set(newVx, newVy)
        self.vx = newVx
        self.vy = newVy
    end

    -- Add acceleration
    function component:add(dvx, dvy)
        self.vx = self.vx + dvx
        self.vy = self.vy + dvy
    end

    -- Get speed (magnitude)
    function component:getSpeed()
        return math.sqrt(self.vx * self.vx + self.vy * self.vy)
    end

    -- Get direction (angle in radians)
    function component:getDirection()
        return math.atan2(self.vy, self.vx)
    end

    -- Set from speed and direction
    function component:setFromPolar(speed, direction)
        self.vx = speed * math.cos(direction)
        self.vy = speed * math.sin(direction)
    end

    -- Normalize to unit vector
    function component:normalize()
        local speed = self:getSpeed()
        if speed > 0 then
            self.vx = self.vx / speed
            self.vy = self.vy / speed
        end
    end

    -- Scale velocity
    function component:scale(factor)
        self.vx = self.vx * factor
        self.vy = self.vy * factor
    end

    return component
end

return Velocity
