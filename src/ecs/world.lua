-- ECS World
-- Manages entities and systems

local Class = require("lib.class")
local World = Class:extend()

function World:new()
    self.entities = {}
    self.systems = {}
    self.toAdd = {}
    self.toRemove = {}
end

-- Add an entity to the world
-- @param entity: Entity
function World:addEntity(entity)
    table.insert(self.toAdd, entity)
end

-- Remove an entity from the world
-- @param entity: Entity
function World:removeEntity(entity)
    table.insert(self.toRemove, entity)
end

-- Get all entities
-- @return entities: table
function World:getEntities()
    return self.entities
end

-- Get entities with specific tag
-- @param tag: string
-- @return entities: table
function World:getEntitiesWithTag(tag)
    local result = {}
    for _, entity in ipairs(self.entities) do
        if entity:hasTag(tag) then
            table.insert(result, entity)
        end
    end
    return result
end

-- Get entities with specific components
-- @param ...: string - Component names
-- @return entities: table
function World:getEntitiesWithComponents(...)
    local required = {...}
    local result = {}

    for _, entity in ipairs(self.entities) do
        if entity:hasComponents(unpack(required)) then
            table.insert(result, entity)
        end
    end

    return result
end

-- Add a system to the world
-- @param system: System
function World:addSystem(system)
    table.insert(self.systems, system)
    table.sort(self.systems, function(a, b)
        return a.priority < b.priority
    end)
    system:init()
end

-- Update all systems
-- @param dt: number - Delta time
function World:update(dt)
    -- Add pending entities
    for _, entity in ipairs(self.toAdd) do
        table.insert(self.entities, entity)
    end
    self.toAdd = {}

    -- Remove dead/pending entities
    for i = #self.entities, 1, -1 do
        local entity = self.entities[i]
        if not entity:isAlive() then
            table.remove(self.entities, i)
        end
    end

    for _, entity in ipairs(self.toRemove) do
        for i = #self.entities, 1, -1 do
            if self.entities[i] == entity then
                table.remove(self.entities, i)
                break
            end
        end
    end
    self.toRemove = {}

    -- Update systems
    for _, system in ipairs(self.systems) do
        system:update(dt)
    end
end

-- Draw all systems
function World:draw()
    for _, system in ipairs(self.systems) do
        system:draw()
    end
end

-- Clear all entities
function World:clear()
    self.entities = {}
    self.toAdd = {}
    self.toRemove = {}
end

-- Get entity count
-- @return count: number
function World:getEntityCount()
    return #self.entities
end

return World
