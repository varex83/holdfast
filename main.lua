-- Holdfast - Main Entry Point
-- A 2D cooperative survival game built with Love2D

-- Add lib directory to path for external libraries
package.path = package.path .. ";lib/?.lua"

-- Require core systems
local Game = require("src.core.game")

-- Global game instance
local game

function love.load()
    -- Set random seed
    math.randomseed(os.time())

    -- Initialize game
    game = Game.new()
    game:load()

    print("Holdfast initialized successfully!")
end

function love.update(dt)
    if game then
        game:update(dt)
    end
end

function love.draw()
    if game then
        game:draw()
    end
end

function love.keypressed(key, scancode, isrepeat)
    if game then
        game:keypressed(key, scancode, isrepeat)
    end
end

function love.keyreleased(key, scancode)
    if game then
        game:keyreleased(key, scancode)
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    if game then
        game:mousepressed(x, y, button, istouch, presses)
    end
end

function love.mousereleased(x, y, button, istouch, presses)
    if game then
        game:mousereleased(x, y, button, istouch, presses)
    end
end

function love.quit()
    if game then
        game:quit()
    end
end
