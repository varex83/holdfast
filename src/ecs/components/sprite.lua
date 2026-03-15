-- Sprite Component
-- Visual representation for entities

local Component = require('src.ecs.component')

local Sprite = {}

-- Create a Sprite component
function Sprite.create(config, entity)
    local component = {
        type = 'sprite',
        entity = entity
    }

    config = config or {}

    -- Color (RGBA 0-1)
    component.r = config.r or 1
    component.g = config.g or 1
    component.b = config.b or 1
    component.a = config.a or 1

    -- Size
    component.width = config.width or 8
    component.height = config.height or 8

    -- Rotation (radians)
    component.rotation = config.rotation or 0

    -- Scale
    component.scaleX = config.scaleX or 1
    component.scaleY = config.scaleY or 1

    -- Shape type ('rectangle', 'circle', 'triangle')
    component.shape = config.shape or 'rectangle'

    -- Image/texture (optional, for future sprite support)
    component.image = config.image
    component.quad = config.quad

    -- Offset from position
    component.offsetX = config.offsetX or 0
    component.offsetY = config.offsetY or 0

    -- Visibility
    component.visible = config.visible ~= false

    -- Layer (for depth sorting)
    component.layer = config.layer or 0

    -- Set color
    function component:setColor(r, g, b, a)
        self.r = r
        self.g = g
        self.b = b
        self.a = a or self.a
    end

    -- Set rotation
    function component:setRotation(angle)
        self.rotation = angle
    end

    -- Rotate by delta
    function component:rotate(delta)
        self.rotation = self.rotation + delta
    end

    -- Set scale
    function component:setScale(x, y)
        self.scaleX = x
        self.scaleY = y or x
    end

    return component
end

return Sprite
