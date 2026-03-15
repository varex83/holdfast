-- Night State
-- Night gameplay - defend against waves

local Class = require("lib.class")
local NightState = Class:extend()

function NightState:new(game)
    self.game = game
    self.font = nil  -- Lazy loaded
    self.smallFont = nil  -- Lazy loaded
    self.timeRemaining = 300  -- 5 minutes
end

function NightState:enter()
    print("Entered Night State")
    self.timeRemaining = self.game.config.nightLength

    -- Publish night start event
    self.game.eventBus:publish("night_start", self.game.dayCounter)
end

function NightState:exit()
    print("Exited Night State")
end

function NightState:update(dt)
    self.timeRemaining = self.timeRemaining - dt
    self.game.timeOfDay = self.timeRemaining

    if self.timeRemaining <= 0 then
        -- Survived the night, transition to day
        self.game.stateMachine:setState("day")
    end

    -- Update ECS world
    if self.game.world then
        self.game.world:update(dt)
    end
end

function NightState:draw()
    -- Lazy load fonts
    if not self.font then
        self.font = love.graphics.newFont(24)
        self.smallFont = love.graphics.newFont(14)
    end

    -- Clear background with night color
    love.graphics.clear(0.1, 0.1, 0.2, 1)

    -- Draw ECS world
    if self.game.world then
        self.game.world:draw()
    end

    -- Draw HUD
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(self.font)

    -- Night indicator
    love.graphics.print("NIGHT " .. self.game.dayCounter, 20, 20)

    -- Time remaining
    local minutes = math.floor(self.timeRemaining / 60)
    local seconds = math.floor(self.timeRemaining % 60)
    love.graphics.print(string.format("Time: %02d:%02d", minutes, seconds), 20, 50)

    -- Warning
    love.graphics.setColor(1, 0.3, 0.3, 1)
    love.graphics.print("WAVE ACTIVE", 20, 80)

    -- Instruction
    love.graphics.setFont(self.smallFont)
    love.graphics.setColor(1, 1, 1, 1)

    local input = self.game.input
    if input:isUsingGamepad() then
        love.graphics.print(input:getControlPrompt("space", "y", "skip to day (demo)"),
                           20, love.graphics.getHeight() - 40)
        love.graphics.print(input:getControlPrompt("esc", "b", "return to menu"),
                           20, love.graphics.getHeight() - 20)
    else
        love.graphics.print("Press SPACE to skip to day (demo)", 20, love.graphics.getHeight() - 40)
        love.graphics.print("Press ESC to return to menu", 20, love.graphics.getHeight() - 20)
    end

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

function NightState:keypressed(key, scancode, isrepeat)
    if key == "escape" then
        self.game.stateMachine:setState("menu")
    elseif key == "space" then
        -- Skip to day (for testing)
        self.game.stateMachine:setState("day")
    end
end

function NightState:gamepadPressed(joystick, button)
    if button == "b" then  -- Circle button on DualSense
        self.game.stateMachine:setState("menu")
    elseif button == "y" then  -- Triangle button on DualSense
        -- Skip to day (for testing)
        self.game.stateMachine:setState("day")
    end
end

return NightState
