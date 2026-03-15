-- System Base Class
-- Systems operate on entities with specific component combinations

local Class = require("lib.class")
local System = Class:extend()

function System:new(world)
    self.world = world
    self.enabled = true
    self.priority = 0  -- Lower numbers update first
end

-- Called once when system is added to world
function System:init()
end

-- Filter entities that this system operates on
-- Override this to specify required components
-- @param entity: Entity
-- @return matches: boolean
function System:filter(entity)
    return true
end

-- Update system
-- @param dt: number - Delta time
function System:update(dt)
    if not self.enabled then return end

    for _, entity in ipairs(self.world:getEntities()) do
        if entity:isAlive() and self:filter(entity) then
            self:process(entity, dt)
        end
    end
end

-- Process a single entity
-- Override this in derived systems
-- @param entity: Entity
-- @param dt: number - Delta time
function System:process(entity, dt)
end

-- Draw system
function System:draw()
    if not self.enabled then return end

    for _, entity in ipairs(self.world:getEntities()) do
        if entity:isAlive() and self:filter(entity) then
            self:render(entity)
        end
    end
end

-- Render a single entity
-- Override this in derived systems
-- @param entity: Entity
function System:render(entity)
end

-- Enable/disable system
function System:setEnabled(enabled)
    self.enabled = enabled
end

return System
