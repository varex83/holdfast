-- Debug Overlay System
-- Toggle with F1 to show FPS, entity count, and other debug info

local Debug = {}
Debug.__index = Debug

function Debug.new(game)
    local self = setmetatable({}, Debug)
    self.game = game
    self.enabled = false
    self.font = love.graphics.newFont(12)
    self.updateRate = 0.5  -- Update stats every 0.5 seconds
    self.updateTimer = 0
    self.fps = 0
    self.memory = 0
    return self
end

-- Toggle debug overlay
function Debug:toggle()
    self.enabled = not self.enabled
end

-- Set debug overlay enabled state
function Debug:setEnabled(enabled)
    self.enabled = enabled
end

-- Update debug stats
function Debug:update(dt)
    if not self.enabled then return end

    self.updateTimer = self.updateTimer + dt
    if self.updateTimer >= self.updateRate then
        self.updateTimer = 0
        self.fps = love.timer.getFPS()
        self.memory = collectgarbage("count")
    end
end

-- Draw debug overlay
function Debug:draw()
    if not self.enabled then return end

    love.graphics.setFont(self.font)
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 10, 10, 300, 200)

    love.graphics.setColor(0, 1, 0, 1)
    local y = 20
    local lineHeight = 16

    -- FPS
    love.graphics.print("FPS: " .. self.fps, 20, y)
    y = y + lineHeight

    -- Memory
    love.graphics.print(string.format("Memory: %.2f MB", self.memory / 1024), 20, y)
    y = y + lineHeight

    -- Current state
    if self.game and self.game.stateMachine then
        local state = self.game.stateMachine:getCurrentState() or "none"
        love.graphics.print("State: " .. state, 20, y)
        y = y + lineHeight
    end

    -- Entity count
    if self.game and self.game.world then
        love.graphics.print("Entities: " .. self.game.world:getEntityCount(), 20, y)
        y = y + lineHeight
    end

    -- Day counter
    if self.game and self.game.dayCounter then
        love.graphics.print("Day: " .. self.game.dayCounter, 20, y)
        y = y + lineHeight
    end

    -- Time of day
    if self.game and self.game.timeOfDay then
        love.graphics.print(string.format("Time: %.1f", self.game.timeOfDay), 20, y)
        y = y + lineHeight
    end

    -- Mouse position
    local mx, my = love.mouse.getPosition()
    love.graphics.print(string.format("Mouse: %d, %d", mx, my), 20, y)
    y = y + lineHeight

    -- Controls hint
    y = y + lineHeight
    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.print("F1: Toggle Debug", 20, y)

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

return Debug
