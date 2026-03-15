-- Game Over State
-- Shown when base is destroyed

local Class = require("lib.class")
local GameOverState = Class:extend()

function GameOverState:new(game)
    self.game = game
    self.font = love.graphics.newFont(48)
    self.smallFont = love.graphics.newFont(24)
end

function GameOverState:enter()
    print("Entered Game Over State")
    -- Publish game over event
    self.game.eventBus:publish("base_destroyed")
end

function GameOverState:exit()
    print("Exited Game Over State")
end

function GameOverState:update(dt)
    -- No updates needed
end

function GameOverState:draw()
    -- Dark background
    love.graphics.clear(0.15, 0, 0, 1)

    love.graphics.setFont(self.font)

    -- Game Over text
    local text = "GAME OVER"
    local textWidth = self.font:getWidth(text)
    love.graphics.setColor(1, 0.2, 0.2, 1)
    love.graphics.print(text, (love.graphics.getWidth() - textWidth) / 2, 200)

    -- Stats
    love.graphics.setFont(self.smallFont)
    love.graphics.setColor(0.9, 0.9, 0.9, 1)
    local statsText = "You survived " .. (self.game.dayCounter or 0) .. " days"
    local statsWidth = self.smallFont:getWidth(statsText)
    love.graphics.print(statsText, (love.graphics.getWidth() - statsWidth) / 2, 300)

    -- Instructions
    local instText = "Press ENTER to return to menu"
    local instWidth = self.smallFont:getWidth(instText)
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.print(instText, (love.graphics.getWidth() - instWidth) / 2, 400)

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

function GameOverState:keypressed(key, scancode, isrepeat)
    if key == "return" or key == "escape" then
        -- Reset game and return to menu
        self.game.dayCounter = 0
        self.game.stateMachine:setState("menu")
    end
end

return GameOverState
