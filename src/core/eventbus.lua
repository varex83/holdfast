-- Event Bus System
-- Provides decoupled communication between systems via publish/subscribe pattern

local EventBus = {}
EventBus.__index = EventBus

function EventBus.new()
    local self = setmetatable({}, EventBus)
    self.listeners = {}
    self.nextListenerId = {}
    self.emit = function(event, ...)
        return self:publish(event, ...)
    end
    self.on = function(event, callback, context)
        return self:subscribe(event, callback, context)
    end
    self.off = function(event, id)
        return self:unsubscribe(event, id)
    end
    return self
end

-- Subscribe to an event
-- @param event: string - The event name
-- @param callback: function - The function to call when event is published
-- @param context: table - Optional context to pass to callback
-- @return id: number - Unique subscription ID for unsubscribing
function EventBus:subscribe(event, callback, context)
    assert(type(event) == "string" and event ~= "", "Event name must be a non-empty string")
    assert(type(callback) == "function", "Event callback must be a function")

    if not self.listeners[event] then
        self.listeners[event] = {}
        self.nextListenerId[event] = 0
    end

    local id = self.nextListenerId[event] + 1
    self.nextListenerId[event] = id
    self.listeners[event][id] = {
        callback = callback,
        context = context
    }

    return id
end

-- Unsubscribe from an event
-- @param event: string - The event name
-- @param id: number - The subscription ID returned from subscribe
function EventBus:unsubscribe(event, id)
    local listeners = self.listeners[event]
    if listeners and id ~= nil then
        listeners[id] = nil
        return true
    end

    return false
end

-- Publish an event to all subscribers
-- @param event: string - The event name
-- @param ...: any - Additional arguments to pass to callbacks
function EventBus:publish(event, ...)
    local listeners = self.listeners[event]
    if not listeners then
        return 0
    end

    local snapshot = {}
    for id, listener in pairs(listeners) do
        snapshot[#snapshot + 1] = { id = id, listener = listener }
    end

    table.sort(snapshot, function(a, b)
        return a.id < b.id
    end)

    local delivered = 0
    for _, entry in ipairs(snapshot) do
        local current = self.listeners[event] and self.listeners[event][entry.id]
        if current == entry.listener then
            if current.context then
                current.callback(current.context, ...)
            else
                current.callback(...)
            end
            delivered = delivered + 1
        end
    end

    return delivered
end

-- Clear all listeners for an event
-- @param event: string - The event name to clear
function EventBus:clear(event)
    if event then
        self.listeners[event] = nil
        self.nextListenerId[event] = nil
    else
        self.listeners = {}
        self.nextListenerId = {}
    end
end

-- Get count of listeners for an event
-- @param event: string - The event name
-- @return count: number - Number of subscribers
function EventBus:getListenerCount(event)
    if not self.listeners[event] then
        return 0
    end
    local count = 0
    for _ in pairs(self.listeners[event]) do
        count = count + 1
    end
    return count
end

-- Global singleton for convenience
local globalBus = EventBus.new()

-- Add static emit method for global bus
EventBus.emit = function(event, ...)
    return globalBus:publish(event, ...)
end

-- Add static on method for global bus
EventBus.on = function(event, callback, context)
    return globalBus:subscribe(event, callback, context)
end

EventBus.off = function(event, id)
    return globalBus:unsubscribe(event, id)
end

return EventBus
