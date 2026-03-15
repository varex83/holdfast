-- Main Game Manager
-- Coordinates all game systems and state

local Class = require("lib.class")
local EventBus = require("src.core.eventbus")
local StateMachine = require("src.core.statemachine")
local World = require("src.ecs.world")
local Debug = require("src.ui.debug")
local InputManager = require("src.input.inputmanager")

-- States
local MenuState = require("src.states.menustate")
local DayState = require("src.states.daystate")
local NightState = require("src.states.nightstate")
local GameOverState = require("src.states.gameoverstate")

local Game = Class:extend()

function Game:new()
    -- Load config
    self.config = require("data.config")
    self.constants = require("data.constants")

    -- Core systems
    self.eventBus = EventBus.new()
    self.stateMachine = StateMachine(self.eventBus)
    self.world = World()
    self.debug = Debug.new(self)
    self.input = InputManager.new()

    -- Game state
    self.dayCounter = 0
    self.timeOfDay = 0
end

function Game:load()
    print("Loading Holdfast...")
    print("Version: " .. self.constants.VERSION)

    -- Initialize states
    local menuState = MenuState(self)
    local dayState = DayState(self)
    local nightState = NightState(self)
    local gameOverState = GameOverState(self)

    self.stateMachine:addState("menu", menuState)
    self.stateMachine:addState("day", dayState)
    self.stateMachine:addState("night", nightState)
    self.stateMachine:addState("gameover", gameOverState)

    -- Start in menu state
    self.stateMachine:setState("menu")

    -- Subscribe to events
    self:setupEventListeners()

    print("Game loaded successfully!")
end

function Game:setupEventListeners()
    -- Day/Night transitions
    self.eventBus:subscribe("day_start", function(dayNumber)
        print("Day " .. dayNumber .. " started")
    end)

    self.eventBus:subscribe("night_start", function(dayNumber)
        print("Night " .. dayNumber .. " started")
    end)

    -- Game over
    self.eventBus:subscribe("base_destroyed", function()
        print("Base destroyed! Game over!")
    end)
end

function Game:update(dt)
    -- Update debug
    self.debug:update(dt)

    -- Update state machine
    self.stateMachine:update(dt)
end

function Game:draw()
    -- Draw current state
    self.stateMachine:draw()

    -- Draw debug overlay on top
    self.debug:draw()
end

function Game:keypressed(key, scancode, isrepeat)
    -- Notify input manager
    self.input:notifyKeyPressed()

    -- Debug toggle
    if key == "f1" then
        self.debug:toggle()
        return
    end

    -- Forward to current state
    self.stateMachine:keypressed(key, scancode, isrepeat)
end

function Game:keyreleased(key, scancode)
    self.stateMachine:keyreleased(key, scancode)
end

function Game:mousepressed(x, y, button, istouch, presses)
    self.stateMachine:mousepressed(x, y, button, istouch, presses)
end

function Game:mousereleased(x, y, button, istouch, presses)
    self.stateMachine:mousereleased(x, y, button, istouch, presses)
end

function Game:wheelmoved(x, y)
    self.stateMachine:wheelmoved(x, y)
end

function Game:joystickAdded(joystick)
    self.input:joystickAdded(joystick)
end

function Game:joystickRemoved(joystick)
    self.input:joystickRemoved(joystick)
end

function Game:gamepadPressed(joystick, button)
    self.input:notifyGamepadPressed()
    self.stateMachine:gamepadPressed(joystick, button)
end

function Game:gamepadReleased(joystick, button)
    self.stateMachine:gamepadReleased(joystick, button)
end

function Game:quit()
    print("Shutting down Holdfast...")
    -- Save game state if needed
    -- Cleanup resources
end

return Game
