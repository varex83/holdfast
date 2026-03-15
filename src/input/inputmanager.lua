local InputManager = {}
InputManager.__index = InputManager

function InputManager.new()
    local self = setmetatable({}, InputManager)

    self.joysticks = {}
    self.activeJoystick = nil
    self.deadzone = 0.2
    self.lastInputDevice = "keyboard"  -- "keyboard" or "gamepad"

    -- Input action mappings
    self.keyboardMap = {
        move_up = "w",
        move_down = "s",
        move_left = "a",
        move_right = "d",
        confirm = "return",
        cancel = "escape",
        interact = "e",
        ability = "space",
        menu_up = "up",
        menu_down = "down",
    }

    self.gamepadMap = {
        move_up = nil,      -- handled by left stick
        move_down = nil,    -- handled by left stick
        move_left = nil,    -- handled by left stick
        move_right = nil,   -- handled by left stick
        confirm = "a",      -- X button on DualSense
        cancel = "b",       -- Circle button on DualSense
        interact = "x",     -- Square button on DualSense
        ability = "y",      -- Triangle button on DualSense
        menu_up = "dpup",
        menu_down = "dpdown",
    }

    -- DualSense button symbols (UTF-8)
    self.buttonSymbols = {
        a = "✕",        -- Cross
        b = "○",        -- Circle
        x = "□",        -- Square
        y = "△",        -- Triangle
        dpup = "⬆",
        dpdown = "⬇",
        dpleft = "⬅",
        dpright = "➡",
        leftstick = "L",
        rightstick = "R",
    }

    -- Detect connected joysticks
    self:refreshJoysticks()

    return self
end

function InputManager:refreshJoysticks()
    self.joysticks = love.joystick.getJoysticks()
    if #self.joysticks > 0 and not self.activeJoystick then
        self.activeJoystick = self.joysticks[1]
        print("Controller connected: " .. self.activeJoystick:getName())
    end
end

function InputManager:joystickAdded(joystick)
    table.insert(self.joysticks, joystick)
    if not self.activeJoystick then
        self.activeJoystick = joystick
        print("Controller connected: " .. joystick:getName())
    end
end

function InputManager:joystickRemoved(joystick)
    for i, j in ipairs(self.joysticks) do
        if j == joystick then
            table.remove(self.joysticks, i)
            break
        end
    end

    if self.activeJoystick == joystick then
        self.activeJoystick = self.joysticks[1] or nil
        if self.activeJoystick then
            print("Switched to controller: " .. self.activeJoystick:getName())
        else
            print("Controller disconnected")
        end
    end
end

function InputManager:applyDeadzone(value)
    if math.abs(value) < self.deadzone then
        return 0
    end
    -- Rescale to smooth transition after deadzone
    local sign = value > 0 and 1 or -1
    return sign * (math.abs(value) - self.deadzone) / (1 - self.deadzone)
end

function InputManager:getAxis(axisName)
    if not self.activeJoystick then
        return 0
    end

    if not self.activeJoystick:isGamepad() then
        return 0
    end

    local value = self.activeJoystick:getGamepadAxis(axisName)
    return self:applyDeadzone(value)
end

function InputManager:getMoveVector()
    local dx, dy = 0, 0

    -- Keyboard input
    if love.keyboard.isDown(self.keyboardMap.move_right) then dx = dx + 1 end
    if love.keyboard.isDown(self.keyboardMap.move_left) then dx = dx - 1 end
    if love.keyboard.isDown(self.keyboardMap.move_down) then dy = dy + 1 end
    if love.keyboard.isDown(self.keyboardMap.move_up) then dy = dy - 1 end

    if dx ~= 0 or dy ~= 0 then
        self.lastInputDevice = "keyboard"
    end

    -- Gamepad input (overrides keyboard if present)
    if self.activeJoystick then
        local gx = self:getAxis("leftx")
        local gy = self:getAxis("lefty")

        if math.abs(gx) > 0 or math.abs(gy) > 0 then
            dx, dy = gx, gy
            self.lastInputDevice = "gamepad"
        end
    end

    -- Normalize diagonal movement
    local length = math.sqrt(dx * dx + dy * dy)
    if length > 1 then
        dx, dy = dx / length, dy / length
    end

    return dx, dy
end

function InputManager:isActionPressed(action)
    -- Check keyboard
    local keyboardKey = self.keyboardMap[action]
    if keyboardKey and love.keyboard.isDown(keyboardKey) then
        return true
    end

    -- Check gamepad
    if self.activeJoystick and self.activeJoystick:isGamepad() then
        local gamepadButton = self.gamepadMap[action]
        if gamepadButton then
            -- Handle D-pad separately (it's an axis on some controllers)
            if gamepadButton == "dpup" then
                return self.activeJoystick:isGamepadDown(gamepadButton)
            elseif gamepadButton == "dpdown" then
                return self.activeJoystick:isGamepadDown(gamepadButton)
            elseif gamepadButton == "dpleft" then
                return self.activeJoystick:isGamepadDown(gamepadButton)
            elseif gamepadButton == "dpright" then
                return self.activeJoystick:isGamepadDown(gamepadButton)
            else
                return self.activeJoystick:isGamepadDown(gamepadButton)
            end
        end
    end

    return false
end

function InputManager:isActionJustPressed(action, key, joystickButton)
    -- Check if this key/button press matches the action
    local keyboardKey = self.keyboardMap[action]
    if key and keyboardKey == key then
        return true
    end

    if joystickButton and self.gamepadMap[action] then
        if joystickButton == self.gamepadMap[action] then
            return true
        end
    end

    return false
end

function InputManager:getRightStick()
    if not self.activeJoystick or not self.activeJoystick:isGamepad() then
        return 0, 0
    end

    local rx = self:getAxis("rightx")
    local ry = self:getAxis("righty")

    return rx, ry
end

function InputManager:getTriggers()
    if not self.activeJoystick or not self.activeJoystick:isGamepad() then
        return 0, 0
    end

    local lt = self:getAxis("triggerleft")
    local rt = self:getAxis("triggerright")

    -- Triggers range from -1 to 1, normalize to 0 to 1
    lt = (lt + 1) / 2
    rt = (rt + 1) / 2

    return lt, rt
end

function InputManager:isButtonDown(button)
    if not self.activeJoystick or not self.activeJoystick:isGamepad() then
        return false
    end

    return self.activeJoystick:isGamepadDown(button)
end

function InputManager:getControllerName()
    if self.activeJoystick then
        return self.activeJoystick:getName()
    end
    return "No Controller"
end

function InputManager:hasController()
    return self.activeJoystick ~= nil
end

function InputManager:vibrate(leftMotor, rightMotor, duration)
    if not self.activeJoystick then
        return false
    end

    -- DualSense and most modern controllers support vibration
    if self.activeJoystick:isVibrationSupported() then
        self.activeJoystick:setVibration(leftMotor or 0, rightMotor or 0, duration or -1)
        return true
    end

    return false
end

function InputManager:stopVibration()
    if self.activeJoystick and self.activeJoystick:isVibrationSupported() then
        self.activeJoystick:setVibration(0, 0)
    end
end

function InputManager:notifyKeyPressed()
    self.lastInputDevice = "keyboard"
end

function InputManager:notifyGamepadPressed()
    self.lastInputDevice = "gamepad"
end

function InputManager:isUsingGamepad()
    return self.lastInputDevice == "gamepad" and self.activeJoystick ~= nil
end

function InputManager:getPrompt(action)
    if self:isUsingGamepad() then
        local button = self.gamepadMap[action]
        if button then
            return self.buttonSymbols[button] or button
        end
        -- Special cases
        if action == "move" then
            return "Left Stick"
        elseif action == "camera" then
            return "Right Stick"
        end
    else
        local key = self.keyboardMap[action]
        if key then
            return key:upper()
        end
        -- Special cases
        if action == "move" then
            return "WASD"
        elseif action == "camera" then
            return "Mouse Wheel"
        end
    end
    return "?"
end

function InputManager:getControlPrompt(keyboardKey, gamepadButton, description)
    if self:isUsingGamepad() then
        local symbol = self.buttonSymbols[gamepadButton] or gamepadButton
        return symbol .. ": " .. description
    else
        return keyboardKey:upper() .. ": " .. description
    end
end

return InputManager
