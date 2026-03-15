-- State Machine
-- Manages game states: menu, day, night, gameover

local Class = require("lib.class")
local StateMachine = Class:extend()

function StateMachine:new(eventBus)
    self.eventBus = eventBus
    self.states = {}
    self.currentState = nil
    self.previousState = nil
end

-- Register a state
-- @param name: string - The state name
-- @param state: table - State object with enter, exit, update, draw methods
function StateMachine:addState(name, state)
    self.states[name] = state
end

-- Transition to a new state
-- @param name: string - The state name to transition to
-- @param ...: any - Additional arguments to pass to the new state's enter method
function StateMachine:setState(name, ...)
    if not self.states[name] then
        print("Warning: State '" .. name .. "' does not exist")
        return
    end

    -- Exit current state
    if self.currentState and self.states[self.currentState].exit then
        self.states[self.currentState]:exit()
    end

    -- Store previous state
    self.previousState = self.currentState
    self.currentState = name

    -- Publish state change event
    if self.eventBus then
        self.eventBus:publish("state_changed", self.currentState, self.previousState)
    end

    -- Enter new state
    if self.states[self.currentState].enter then
        self.states[self.currentState]:enter(...)
    end

    print("State changed: " .. (self.previousState or "nil") .. " -> " .. self.currentState)
end

-- Get current state name
function StateMachine:getCurrentState()
    return self.currentState
end

-- Get previous state name
function StateMachine:getPreviousState()
    return self.previousState
end

-- Update current state
function StateMachine:update(dt)
    if self.currentState and self.states[self.currentState].update then
        self.states[self.currentState]:update(dt)
    end
end

-- Draw current state
function StateMachine:draw()
    if self.currentState and self.states[self.currentState].draw then
        self.states[self.currentState]:draw()
    end
end

-- Forward keypressed to current state
function StateMachine:keypressed(key, scancode, isrepeat)
    if self.currentState and self.states[self.currentState].keypressed then
        self.states[self.currentState]:keypressed(key, scancode, isrepeat)
    end
end

-- Forward keyreleased to current state
function StateMachine:keyreleased(key, scancode)
    if self.currentState and self.states[self.currentState].keyreleased then
        self.states[self.currentState]:keyreleased(key, scancode)
    end
end

-- Forward mousepressed to current state
function StateMachine:mousepressed(x, y, button, istouch, presses)
    if self.currentState and self.states[self.currentState].mousepressed then
        self.states[self.currentState]:mousepressed(x, y, button, istouch, presses)
    end
end

-- Forward mousereleased to current state
function StateMachine:mousereleased(x, y, button, istouch, presses)
    if self.currentState and self.states[self.currentState].mousereleased then
        self.states[self.currentState]:mousereleased(x, y, button, istouch, presses)
    end
end

-- Forward mouse wheel to current state
function StateMachine:wheelmoved(x, y)
    if self.currentState and self.states[self.currentState].wheelmoved then
        self.states[self.currentState]:wheelmoved(x, y)
    end
end

return StateMachine
