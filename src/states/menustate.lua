-- Menu State
-- Main menu with options to start game, load game, settings, quit

local Class = require("lib.class")
local MenuState = Class:extend()

function MenuState:new(game)
    self.game = game
    self.font = nil  -- Lazy loaded
    self.smallFont = nil  -- Lazy loaded
    self.selectedOption = 1
    self.options = {
        "New Game",
        "Load Game",
        "Settings",
        "Quit"
    }
end

function MenuState:enter()
    print("Entered Menu State")
end

function MenuState:exit()
    print("Exited Menu State")
end

function MenuState:update(dt)
    -- Menu doesn't need updates
end

function MenuState:draw()
    -- Lazy load fonts
    if not self.font then
        self.font = love.graphics.newFont(32)
        self.smallFont = love.graphics.newFont(16)
    end

    love.graphics.setFont(self.font)

    -- Title
    local title = "HOLDFAST"
    local titleWidth = self.font:getWidth(title)
    love.graphics.setColor(0.9, 0.9, 0.9, 1)
    love.graphics.print(title, (love.graphics.getWidth() - titleWidth) / 2, 100)

    -- Subtitle
    love.graphics.setFont(self.smallFont)
    local subtitle = "A 2D Cooperative Survival Game"
    local subtitleWidth = self.smallFont:getWidth(subtitle)
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.print(subtitle, (love.graphics.getWidth() - subtitleWidth) / 2, 150)

    -- Menu options
    love.graphics.setFont(self.font)
    local startY = 250
    local spacing = 60

    for i, option in ipairs(self.options) do
        local y = startY + (i - 1) * spacing
        local optionWidth = self.font:getWidth(option)
        local x = (love.graphics.getWidth() - optionWidth) / 2

        if i == self.selectedOption then
            love.graphics.setColor(1, 1, 0, 1)
            love.graphics.print("> " .. option .. " <", x - 40, y)
        else
            love.graphics.setColor(0.6, 0.6, 0.6, 1)
            love.graphics.print(option, x, y)
        end
    end

    -- Version
    love.graphics.setFont(self.smallFont)
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.print("v0.1.0-alpha - Phase 0", 10, love.graphics.getHeight() - 30)

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

function MenuState:keypressed(key, scancode, isrepeat)
    if key == "up" then
        self.selectedOption = self.selectedOption - 1
        if self.selectedOption < 1 then
            self.selectedOption = #self.options
        end
    elseif key == "down" then
        self.selectedOption = self.selectedOption + 1
        if self.selectedOption > #self.options then
            self.selectedOption = 1
        end
    elseif key == "return" or key == "space" then
        self:selectOption()
    elseif key == "escape" then
        love.event.quit()
    end
end

function MenuState:selectOption()
    if self.selectedOption == 1 then
        -- New Game
        self.game.stateMachine:setState("day")
    elseif self.selectedOption == 2 then
        -- Load Game (not implemented yet)
        print("Load Game not implemented yet")
    elseif self.selectedOption == 3 then
        -- Settings (not implemented yet)
        print("Settings not implemented yet")
    elseif self.selectedOption == 4 then
        -- Quit
        love.event.quit()
    end
end

return MenuState
