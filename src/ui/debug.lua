-- Debug Overlay System
-- Toggle with F1 to show FPS, entity count, and other debug info

local Debug = {}
Debug.__index = Debug

function Debug.new(game)
    local self = setmetatable({}, Debug)
    self.game = game
    self.enabled = false
    self.font = nil  -- Created on first draw
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

-- Collect lines of debug text from game state
function Debug:_collectLines()
    local lines = {
        "FPS: " .. self.fps,
        string.format("Memory: %.2f MB", self.memory / 1024),
    }
    local g = self.game
    if g and g.stateMachine then
        lines[#lines+1] = "State: " .. (g.stateMachine:getCurrentState() or "none")
    end
    if g and g.world then
        lines[#lines+1] = "Entities: " .. g.world:getEntityCount()
    end
    if g and g.dayCounter then
        lines[#lines+1] = "Day: " .. g.dayCounter
    end
    if g and g.timeOfDay then
        lines[#lines+1] = string.format("Time: %.1f", g.timeOfDay)
    end
    local mx, my = love.mouse.getPosition()
    lines[#lines+1] = string.format("Mouse: %d, %d", mx, my)
    if g and g.input then
        local has = g.input:hasController()
        lines[#lines+1] = "Controller: " .. (has and "Connected" or "None")
        if has then lines[#lines+1] = "Name: " .. g.input:getControllerName() end
    end
    return lines
end

-- Draw debug overlay
function Debug:draw()
    if not self.enabled then return end

    if not self.font then self.font = love.graphics.newFont(12) end

    local lineHeight = 16
    local lines = self:_collectLines()
    local height = (#lines + 2) * lineHeight

    love.graphics.setFont(self.font)
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 10, 10, 300, height)

    love.graphics.setColor(0, 1, 0, 1)
    local y = 20
    for _, line in ipairs(lines) do
        love.graphics.print(line, 20, y)
        y = y + lineHeight
    end

    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.print("F1: Toggle Debug", 20, y + lineHeight)
    love.graphics.setColor(1, 1, 1, 1)
end

return Debug
