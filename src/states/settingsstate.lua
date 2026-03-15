-- Settings State
-- Placeholder settings screen for future options

local Class = require("lib.class")
local SettingsState = Class:extend()

function SettingsState:new(game)
    self.game = game
    self.titleFont = nil
    self.font = nil
    self.smallFont = nil
    self.selectedOption = 1
    self.notice = "Placeholder menu. Real settings will be added here."
    self.options = {
        {
            label = "Display",
            value = "Placeholder",
            description = "Resolution, fullscreen, and graphics quality will live here."
        },
        {
            label = "Audio",
            value = "Placeholder",
            description = "Master, music, and SFX controls will be added here."
        },
        {
            label = "Controls",
            value = "Placeholder",
            description = "Keyboard and gamepad remapping will be added here."
        },
        {
            label = "Gameplay",
            value = "Placeholder",
            description = "Accessibility and game rules will be exposed here."
        },
        {
            label = "Back",
            value = "Menu",
            description = "Return to the main menu."
        }
    }
end

function SettingsState:enter()
    self.selectedOption = 1
    self.notice = "Placeholder menu. Real settings will be added here."
end

function SettingsState:update(dt)
    -- Placeholder state has no background animation yet.
end

function SettingsState:draw()
    if not self.titleFont then
        self.titleFont = love.graphics.newFont(42)
        self.font = love.graphics.newFont(24)
        self.smallFont = love.graphics.newFont(16)
    end

    local w, h = love.graphics.getDimensions()
    local panelX = math.floor((w - 760) * 0.5)
    local panelY = math.floor((h - 470) * 0.5)
    local panelW = 760
    local panelH = 470

    love.graphics.clear(0.16, 0.20, 0.22, 1)

    love.graphics.setColor(0.04, 0.05, 0.06, 0.30)
    love.graphics.rectangle("fill", 0, 0, w, h)

    love.graphics.setColor(0.05, 0.06, 0.07, 0.70)
    love.graphics.rectangle("fill", panelX, panelY, panelW, panelH, 26, 26)
    love.graphics.setColor(0.78, 0.72, 0.48, 0.90)
    love.graphics.rectangle("line", panelX, panelY, panelW, panelH, 26, 26)

    love.graphics.setFont(self.titleFont)
    love.graphics.setColor(0.97, 0.95, 0.88, 1)
    love.graphics.print("Settings", panelX + 34, panelY + 28)

    love.graphics.setFont(self.smallFont)
    love.graphics.setColor(0.86, 0.84, 0.76, 1)
    love.graphics.print("Placeholder screen for future configuration options.", panelX + 36, panelY + 82)

    local listX = panelX + 28
    local listY = panelY + 128
    local rowH = 58

    love.graphics.setFont(self.font)
    for i, option in ipairs(self.options) do
        local y = listY + (i - 1) * rowH
        local selected = i == self.selectedOption

        if selected then
            love.graphics.setColor(0.78, 0.72, 0.48, 0.96)
            love.graphics.rectangle("fill", listX, y, panelW - 56, 48, 16, 16)
            love.graphics.setColor(0.10, 0.11, 0.12, 1)
        else
            love.graphics.setColor(0.18, 0.20, 0.22, 0.82)
            love.graphics.rectangle("fill", listX, y, panelW - 56, 48, 16, 16)
            love.graphics.setColor(0.90, 0.91, 0.92, 1)
        end

        love.graphics.print(option.label, listX + 22, y + 10)

        if selected then
            love.graphics.setColor(0.16, 0.17, 0.18, 0.92)
        else
            love.graphics.setColor(0.76, 0.72, 0.56, 1)
        end
        love.graphics.printf(option.value, listX + 270, y + 10, panelW - 360, "right")
    end

    local selected = self.options[self.selectedOption]
    love.graphics.setColor(0.10, 0.11, 0.12, 0.84)
    love.graphics.rectangle("fill", panelX + 28, panelY + panelH - 108, panelW - 56, 56, 18, 18)
    love.graphics.setFont(self.smallFont)
    love.graphics.setColor(0.88, 0.89, 0.86, 1)
    love.graphics.printf(selected.description, panelX + 46, panelY + panelH - 92, panelW - 92)

    love.graphics.setColor(0.74, 0.77, 0.74, 1)
    love.graphics.printf(self.notice, panelX + 36, panelY + panelH - 36, panelW - 72, "center")

    local input = self.game.input
    local controls
    if input:isUsingGamepad() then
        controls = input:getControlPrompt("up/down", "dpup", "navigate") .. "/" ..
            input:getPrompt("menu_down") .. "  |  " ..
            input:getControlPrompt("enter", "a", "select") .. "  |  " ..
            input:getControlPrompt("esc", "b", "back")
    else
        controls = "UP/DOWN: navigate  |  ENTER: select  |  ESC: back"
    end

    love.graphics.setColor(0.90, 0.91, 0.87, 0.95)
    love.graphics.print(controls, 20, h - 54)
    love.graphics.setColor(1, 1, 1, 1)
end

function SettingsState:moveSelection(delta)
    self.selectedOption = self.selectedOption + delta
    if self.selectedOption < 1 then
        self.selectedOption = #self.options
    elseif self.selectedOption > #self.options then
        self.selectedOption = 1
    end
end

function SettingsState:activateSelection()
    local option = self.options[self.selectedOption]
    if option.label == "Back" then
        self.game.stateMachine:setState("menu")
        return
    end

    self.notice = option.label .. " is a placeholder for now."
end

function SettingsState:keypressed(key, scancode, isrepeat)
    if key == "up" then
        self:moveSelection(-1)
    elseif key == "down" then
        self:moveSelection(1)
    elseif key == "return" or key == "space" then
        self:activateSelection()
    elseif key == "escape" then
        self.game.stateMachine:setState("menu")
    end
end

function SettingsState:gamepadPressed(joystick, button)
    if button == "dpup" then
        self:moveSelection(-1)
    elseif button == "dpdown" then
        self:moveSelection(1)
    elseif button == "a" then
        self:activateSelection()
    elseif button == "b" then
        self.game.stateMachine:setState("menu")
    end
end

return SettingsState
