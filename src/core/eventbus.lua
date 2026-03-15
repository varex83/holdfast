-- Event Bus System
-- Provides decoupled communication between systems via publish/subscribe pattern

local EventBus = {}
EventBus.__index = EventBus

function EventBus.new()
    local self = setmetatable({}, EventBus)
    self.listeners = {}
    return self
end

-- Subscribe to an event
-- @param event: string - The event name
-- @param callback: function - The function to call when event is published
-- @param context: table - Optional context to pass to callback
-- @return id: number - Unique subscription ID for unsubscribing
function EventBus:subscribe(event, callback, context)
    if not self.listeners[event] then
        self.listeners[event] = {}
    end

    local id = #self.listeners[event] + 1
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
    if self.listeners[event] then
        self.listeners[event][id] = nil
    end
end

-- Publish an event to all subscribers
-- @param event: string - The event name
-- @param ...: any - Additional arguments to pass to callbacks
function EventBus:publish(event, ...)
    if not self.listeners[event] then
        return
    end

    for _, listener in pairs(self.listeners[event]) do
        if listener.context then
            listener.callback(listener.context, ...)
        else
            listener.callback(...)
        end
    end
end

-- Clear all listeners for an event
-- @param event: string - The event name to clear
function EventBus:clear(event)
    if event then
        self.listeners[event] = nil
    else
        self.listeners = {}
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
EventBus.emit = function(event, data)
    globalBus:publish(event, data)
end

-- Add static on method for global bus
EventBus.on = function(event, callback)
    return globalBus:subscribe(event, callback)
end

return EventBus
