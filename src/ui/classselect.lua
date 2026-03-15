local Classes = require("data.classes")

local ClassSelect = {}
ClassSelect.__index = ClassSelect

function ClassSelect.new(initialClass)
    local self = setmetatable({}, ClassSelect)
    self.order = Classes.order
    self.selectedIndex = 1

    if initialClass then
        for i, classType in ipairs(self.order) do
            if classType == initialClass then
                self.selectedIndex = i
                break
            end
        end
    end

    return self
end

function ClassSelect:getSelectedClass()
    return self.order[self.selectedIndex]
end

function ClassSelect:getSelectedDefinition()
    return Classes.get(self:getSelectedClass())
end

function ClassSelect:change(delta)
    self.selectedIndex = self.selectedIndex + delta
    if self.selectedIndex < 1 then
        self.selectedIndex = #self.order
    elseif self.selectedIndex > #self.order then
        self.selectedIndex = 1
    end
end

function ClassSelect:draw(panel, fonts)
    local classDef = self:getSelectedDefinition()
    local stats = classDef.stats

    love.graphics.setColor(0.72, 0.64, 0.34, 0.9)
    love.graphics.rectangle("line", panel.x, panel.y, panel.w, panel.h, 24, 24)

    love.graphics.setFont(fonts.section)
    love.graphics.setColor(0.85, 0.82, 0.62, 1)
    love.graphics.print("Selected Survivor", panel.x + 26, panel.y + 28)

    love.graphics.setFont(fonts.title)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(classDef.label, panel.x + 24, panel.y + 68)

    love.graphics.setFont(fonts.small)
    love.graphics.setColor(0.86, 0.88, 0.90, 1)
    love.graphics.printf(classDef.summary, panel.x + 26, panel.y + 140, panel.w - 52)

    love.graphics.setColor(0.10, 0.11, 0.12, 0.92)
    love.graphics.rectangle("fill", panel.x + 24, panel.y + 194, panel.w - 48, 168, 20, 20)

    local y = panel.y + 216
    local x = panel.x + 42
    love.graphics.setColor(0.95, 0.95, 0.92, 1)
    love.graphics.print("HP: " .. stats.maxHp, x, y)
    y = y + 22
    love.graphics.print("Armor: " .. stats.armor, x, y)
    y = y + 22
    love.graphics.print("Speed: " .. stats.speed, x, y)
    y = y + 22
    love.graphics.print("Attack: " .. stats.attack, x, y)
    y = y + 22
    love.graphics.print("Range: " .. stats.attackRange, x, y)
    y = y + 22
    love.graphics.print("Ability: " .. classDef.ability.label, x, y)

    love.graphics.setColor(0.82, 0.84, 0.86, 1)
    love.graphics.printf("<  left / right  >", panel.x + 26, panel.y + panel.h - 48, panel.w - 52, "center")
    love.graphics.setColor(0.66, 0.70, 0.72, 1)
    love.graphics.printf("Enter starts with selected class", panel.x + 26, panel.y + panel.h - 22, panel.w - 52, "center")
    love.graphics.setColor(1, 1, 1, 1)
end

return ClassSelect
