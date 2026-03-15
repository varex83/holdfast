-- Entity Base Class
-- Entities are containers for components

local Class = require("lib.class")
local Entity = Class:extend()

-- Static counter for entity IDs
Entity.nextId = 1

function Entity:new()
    self.id = Entity.nextId
    Entity.nextId = Entity.nextId + 1

    self.components = {}
    self.alive = true
    self.tags = {}
end

-- Add a component to this entity
-- @param name: string - Component name
-- @param component: table - Component data
function Entity:addComponent(name, component)
    self.components[name] = component
    component.entity = self
    return self
end

-- Get a component from this entity
-- @param name: string - Component name
-- @return component: table or nil
function Entity:getComponent(name)
    return self.components[name]
end

-- Check if entity has a component
-- @param name: string - Component name
-- @return has: boolean
function Entity:hasComponent(name)
    return self.components[name] ~= nil
end

-- Check if entity has all specified components
-- @param ...: string - Component names
-- @return has: boolean
function Entity:hasComponents(...)
    for _, name in ipairs({...}) do
        if not self:hasComponent(name) then
            return false
        end
    end
    return true
end

-- Remove a component from this entity
-- @param name: string - Component name
function Entity:removeComponent(name)
    self.components[name] = nil
end

-- Add a tag to this entity
-- @param tag: string - Tag name
function Entity:addTag(tag)
    self.tags[tag] = true
end

-- Check if entity has a tag
-- @param tag: string - Tag name
-- @return has: boolean
function Entity:hasTag(tag)
    return self.tags[tag] == true
end

-- Remove a tag from this entity
-- @param tag: string - Tag name
function Entity:removeTag(tag)
    self.tags[tag] = nil
end

-- Mark entity for removal
function Entity:destroy()
    self.alive = false
end

-- Check if entity is alive
-- @return alive: boolean
function Entity:isAlive()
    return self.alive
end

return Entity
