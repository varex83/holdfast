-- Day State
-- Daytime gameplay - explore, gather resources, build

local Class     = require("lib.class")
local Camera    = require("src.core.camera")
local Iso       = require("src.rendering.isometric")
local DrawOrder = require("src.rendering.draworder")
local Tile      = require("src.world.tile")

local DayState = Class:extend()

-- How many tiles to draw around the player placeholder (view radius)
local VIEW_RADIUS = 12

-- Simple placeholder tile grid: a flat patch of grass with a few trees/rocks
local function makePlaceholderGrid(radius)
    local grid = {}
    math.randomseed(42)  -- deterministic so it looks the same every run
    local types = {"grass", "grass", "grass", "grass", "dirt", "tree", "rock"}
    for tx = -radius, radius do
        grid[tx] = {}
        for ty = -radius, radius do
            local t = types[math.random(#types)]
            -- Force walkable border so player isn't immediately stuck
            if math.abs(tx) == radius or math.abs(ty) == radius then
                t = "grass"
            end
            grid[tx][ty] = t
        end
    end
    return grid
end

function DayState:new(game)
    self.game          = game
    self.font          = love.graphics.newFont(24)
    self.smallFont     = love.graphics.newFont(14)
    self.timeRemaining = 600  -- 10 minutes

    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()

    self.camera    = Camera(sw, sh)
    self.drawOrder = DrawOrder()

    -- Placeholder player position in world (tile) space
    self.player = { tx = 0, ty = 0, speed = 4 }  -- speed in tiles/sec

    -- Simple placeholder tile grid
    self.grid = makePlaceholderGrid(VIEW_RADIUS)
end

function DayState:enter()
    print("Entered Day State")
    self.game.dayCounter   = (self.game.dayCounter or 0) + 1
    self.timeRemaining     = self.game.config.dayLength

    -- Centre camera on player
    local px, py = Iso.tileToScreen(self.player.tx, self.player.ty)
    self.camera:moveTo(px, py)

    self.game.eventBus:publish("day_start", self.game.dayCounter)
end

function DayState:exit()
    print("Exited Day State")
end

function DayState:update(dt)
    -- Timer
    self.timeRemaining = self.timeRemaining - dt
    self.game.timeOfDay = self.timeRemaining

    if self.timeRemaining <= 0 then
        self.game.stateMachine:setState("night")
        return
    end

    -- Player movement using input manager (supports both keyboard and gamepad)
    local dx, dy = self.game.input:getMoveVector()
    if dx ~= 0 or dy ~= 0 then
        self.player.tx = self.player.tx + dx * self.player.speed * dt
        self.player.ty = self.player.ty + dy * self.player.speed * dt
    end

    -- Right stick camera control (gamepad only)
    local rx, ry = self.game.input:getRightStick()
    if math.abs(rx) > 0 or math.abs(ry) > 0 then
        -- Move camera in screen space (not tile space)
        local cameraSpeed = 300  -- pixels per second
        self.camera.x = self.camera.x + rx * cameraSpeed * dt
        self.camera.y = self.camera.y + ry * cameraSpeed * dt
    else
        -- Camera follows player (in screen space) when right stick not used
        local px, py = Iso.tileToScreen(self.player.tx, self.player.ty)
        self.camera:follow(px, py)
    end

    self.camera:update(dt)

    -- ECS world update
    if self.game.world then
        self.game.world:update(dt)
    end
end

function DayState:draw()
    -- Sky / background
    love.graphics.clear(0.50, 0.70, 0.90, 1)

    -- ── World (camera-transformed) ──────────────────────────────────────────
    self.camera:apply()

    -- Queue tiles
    for tx, col in pairs(self.grid) do
        for ty, tileType in pairs(col) do
            local sx, sy = Iso.tileToScreen(tx, ty)
            local c = Tile.getColor(tileType)
            -- Capture locals for the closure
            local _tx, _ty, _c = tx, ty, c
            self.drawOrder:add(function()
                Iso.drawTile(_tx, _ty, _c[1], _c[2], _c[3], 1)
            end, sy, DrawOrder.LAYER_GROUND)
        end
    end

    -- Queue placeholder player (yellow diamond on top of tiles)
    local ptx, pty = self.player.tx, self.player.ty
    local _, psy   = Iso.tileToScreen(ptx, pty)
    self.drawOrder:add(function()
        -- Draw a small yellow circle to represent the player
        local sx, sy = Iso.tileToScreen(ptx, pty)
        love.graphics.setColor(1, 0.9, 0.1, 1)
        love.graphics.circle("fill", sx, sy + 8, 10)
        love.graphics.setColor(0.6, 0.5, 0, 1)
        love.graphics.circle("line", sx, sy + 8, 10)
    end, psy, DrawOrder.LAYER_CHARACTER)

    -- Flush draw order (painter's algorithm)
    self.drawOrder:flush()

    self.camera:clear()

    -- ── HUD (screen-space, no camera transform) ─────────────────────────────
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(self.font)
    love.graphics.print("Day " .. self.game.dayCounter, 20, 20)

    local minutes = math.floor(self.timeRemaining / 60)
    local seconds = math.floor(self.timeRemaining % 60)
    love.graphics.print(string.format("Time: %02d:%02d", minutes, seconds), 20, 50)

    love.graphics.setFont(self.smallFont)
    love.graphics.print(string.format("Tile: (%.0f, %.0f)", self.player.tx, self.player.ty), 20, 84)

    -- Dynamic control hints based on input device
    local input = self.game.input
    local controls
    if input:isUsingGamepad() then
        controls = "Left Stick: move  |  Right Stick: camera  |  " ..
                   input:getControlPrompt("space", "y", "skip to night") .. "  |  " ..
                   input:getControlPrompt("esc", "b", "menu")
    else
        controls = "WASD: move  |  Scroll: zoom  |  SPACE: skip to night  |  ESC: menu"
    end
    love.graphics.print(controls, 20, love.graphics.getHeight() - 22)

    love.graphics.setColor(1, 1, 1, 1)
end

function DayState:keypressed(key, scancode, isrepeat)
    if key == "escape" then
        self.game.stateMachine:setState("menu")
    elseif key == "space" then
        self.game.stateMachine:setState("night")
    end
end

function DayState:gamepadPressed(joystick, button)
    print("DayState: gamepad button pressed: " .. button)  -- Debug output

    -- B button (Circle on DualSense) opens menu
    if button == "b" then
        self.game.stateMachine:setState("menu")
    -- Y button (Triangle on DualSense) skips to night
    elseif button == "y" then
        self.game.stateMachine:setState("night")
    end
end

function DayState:wheelmoved(x, y)
    self.camera:adjustZoom(y * 0.1)
end

return DayState
