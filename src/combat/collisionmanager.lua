-- Collision Manager
-- Wraps bump.lua for spatial partitioning and AABB collision detection
-- Integrates with the ECS system to manage entity collisions efficiently

local bump = require('lib.bump')

local CollisionManager = {}

function CollisionManager:new()
    local instance = {}
    setmetatable(instance, { __index = self })

    -- Create bump world for spatial partitioning
    instance.world = bump.newWorld(64) -- 64px cell size

    -- Track entities in bump world (entity.id -> true)
    instance.trackedEntities = {}

    return instance
end

-- Add an entity to the collision world
function CollisionManager:addEntity(entity)
    if self.trackedEntities[entity.id] then
        return -- Already tracked
    end

    local position = entity:getComponent('position')
    local hitbox = entity:getComponent('hitbox')

    if not position or not hitbox then
        return
    end

    local bounds = hitbox:getBounds(position)
    local x = bounds.left
    local y = bounds.top
    local w = bounds.right - bounds.left
    local h = bounds.bottom - bounds.top

    -- Add to bump world (using entity as the item)
    self.world:add(entity, x, y, w, h)
    self.trackedEntities[entity.id] = true
end

-- Update an entity's position in the collision world
function CollisionManager:updateEntity(entity)
    if not self.trackedEntities[entity.id] then
        return
    end

    local position = entity:getComponent('position')
    local hitbox = entity:getComponent('hitbox')

    if not position or not hitbox then
        self:removeEntity(entity)
        return
    end

    local bounds = hitbox:getBounds(position)
    local x = bounds.left
    local y = bounds.top
    local w = bounds.right - bounds.left
    local h = bounds.bottom - bounds.top

    -- Update position in bump world
    self.world:update(entity, x, y, w, h)
end

-- Remove an entity from the collision world
function CollisionManager:removeEntity(entity)
    if not self.trackedEntities[entity.id] then
        return
    end

    self.world:remove(entity)
    self.trackedEntities[entity.id] = nil
end

-- Check if entity exists in collision world
function CollisionManager:hasEntity(entity)
    return self.trackedEntities[entity.id] ~= nil
end

-- Query for entities in a rectangular area
-- Returns array of entities that overlap the given bounds
function CollisionManager:queryRect(x, y, w, h, filter)
    local items, len = self.world:queryRect(x, y, w, h, filter)
    return items
end

-- Query for entities at a point
function CollisionManager:queryPoint(x, y, filter)
    local items, len = self.world:queryPoint(x, y, filter)
    return items
end

-- Check collision between a specific entity and others in the world
-- Returns the first entity it collides with, or nil
-- filter: optional function(item, other) -> should collide (boolean)
function CollisionManager:checkCollision(entity, filter)
    if not self.trackedEntities[entity.id] then
        return nil
    end

    local position = entity:getComponent('position')
    local hitbox = entity:getComponent('hitbox')

    if not position or not hitbox then
        return nil
    end

    local bounds = hitbox:getBounds(position)
    local x = bounds.left
    local y = bounds.top
    local w = bounds.right - bounds.left
    local h = bounds.bottom - bounds.top

    -- Query nearby entities
    local items = self.world:queryRect(x, y, w, h, filter)

    -- Return first collision (excluding self)
    for _, item in ipairs(items) do
        if item.id ~= entity.id then
            return item
        end
    end

    return nil
end

-- Get all entities that collide with the given entity
-- filter: optional function(item, other) -> should collide (boolean)
function CollisionManager:getCollisions(entity, filter)
    if not self.trackedEntities[entity.id] then
        return {}
    end

    local position = entity:getComponent('position')
    local hitbox = entity:getComponent('hitbox')

    if not position or not hitbox then
        return {}
    end

    local bounds = hitbox:getBounds(position)
    local x = bounds.left
    local y = bounds.top
    local w = bounds.right - bounds.left
    local h = bounds.bottom - bounds.top

    -- Query nearby entities
    local items = self.world:queryRect(x, y, w, h, filter)

    -- Filter out self
    local collisions = {}
    for _, item in ipairs(items) do
        if item.id ~= entity.id then
            table.insert(collisions, item)
        end
    end

    return collisions
end

-- Sync all entities with the collision world
-- Call this when entities are added/removed from ECS world
function CollisionManager:syncWithWorld(ecsWorld)
    -- Get all entities with hitboxes
    local entities = ecsWorld:getEntitiesWithComponents({'position', 'hitbox'})

    -- Add new entities
    for _, entity in ipairs(entities) do
        if not self.trackedEntities[entity.id] then
            self:addEntity(entity)
        end
    end

    -- Remove entities that no longer exist
    local toRemove = {}
    for entityId, _ in pairs(self.trackedEntities) do
        local found = false
        for _, entity in ipairs(entities) do
            if entity.id == entityId then
                found = true
                break
            end
        end
        if not found then
            -- Find entity by ID to remove
            for id, tracked in pairs(self.trackedEntities) do
                if id == entityId then
                    -- We need the entity object to remove it from bump
                    -- For now, we'll handle this through removeEntity calls
                    table.insert(toRemove, entityId)
                    break
                end
            end
        end
    end
end

-- Clear all entities from the collision world
function CollisionManager:clear()
    self.world = bump.newWorld(64)
    self.trackedEntities = {}
end

-- Get debug info
function CollisionManager:getDebugInfo()
    local count = 0
    for _ in pairs(self.trackedEntities) do
        count = count + 1
    end

    return {
        entityCount = count,
        cellSize = 64
    }
end

return CollisionManager
