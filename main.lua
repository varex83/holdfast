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

    -- Initialize game (using class constructor)
    game = Game()
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

function love.wheelmoved(x, y)
    if game then
        game:wheelmoved(x, y)
    end
end

function love.quit()
    if game then
        game:quit()
    end
end

function love.joystickadded(joystick)
    if game then
        game:joystickAdded(joystick)
    end
end

function love.joystickremoved(joystick)
    if game then
        game:joystickRemoved(joystick)
    end
end

function love.gamepadpressed(joystick, button)
    if game then
        game:gamepadPressed(joystick, button)
    end
end

function love.gamepadreleased(joystick, button)
    if game then
        game:gamepadReleased(joystick, button)
    end
end
