-- Day State
-- Daytime gameplay - explore, gather resources, build

local Class = require("lib.class")
local DayState = Class:extend()

function DayState:new(game)
    self.game = game
    self.font = love.graphics.newFont(24)
    self.timeRemaining = 600  -- 10 minutes
end

function DayState:enter()
    print("Entered Day State")
    self.game.dayCounter = (self.game.dayCounter or 0) + 1
    self.timeRemaining = self.game.config.dayLength

    -- Publish day start event
    self.game.eventBus:publish("day_start", self.game.dayCounter)
end

function DayState:exit()
    print("Exited Day State")
end

function DayState:update(dt)
    self.timeRemaining = self.timeRemaining - dt
    self.game.timeOfDay = self.timeRemaining

    if self.timeRemaining <= 0 then
        -- Transition to night
        self.game.stateMachine:setState("night")
    end

    -- Update ECS world
    if self.game.world then
        self.game.world:update(dt)
    end
end

function DayState:draw()
    -- Clear background with day color
    love.graphics.clear(0.5, 0.7, 0.9, 1)

    -- Draw ECS world
    if self.game.world then
        self.game.world:draw()
    end

    -- Draw HUD
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(self.font)

    -- Day counter
    love.graphics.print("Day " .. self.game.dayCounter, 20, 20)

    -- Time remaining
    local minutes = math.floor(self.timeRemaining / 60)
    local seconds = math.floor(self.timeRemaining % 60)
    love.graphics.print(string.format("Time: %02d:%02d", minutes, seconds), 20, 50)

    -- Instruction
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.print("Press SPACE to skip to night (demo)", 20, love.graphics.getHeight() - 40)
    love.graphics.print("Press ESC to return to menu", 20, love.graphics.getHeight() - 20)

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

function DayState:keypressed(key, scancode, isrepeat)
    if key == "escape" then
        self.game.stateMachine:setState("menu")
    elseif key == "space" then
        -- Skip to night (for testing)
        self.game.stateMachine:setState("night")
    end
end

return DayState
