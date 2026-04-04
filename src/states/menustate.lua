-- Menu State
-- Main menu with options to start game, load game, settings, quit

local Class = require("lib.class")
local Camera = require("src.core.camera")
local Character = require("src.characters.character")
local Constants = require("data.constants")
local Classes = require("data.classes")
local ClassSelect = require("src.ui.classselect")
local Iso = require("src.rendering.isometric")
local Tile = require("src.world.tile")
local ChunkManager = require("src.world.chunk")
local MenuState = Class:extend()

local PREVIEW_VISUAL_SCALE = 3.8

function MenuState:new(game)
    self.game = game
    self.font = nil  -- Lazy loaded
    self.titleFont = nil
    self.sectionFont = nil
    self.smallFont = nil  -- Lazy loaded
    self.selectedOption = 1
    self.classSelect = ClassSelect.new(Constants.CLASS.WARRIOR)
    self.options = {
        "Test Phase 1",
        "Asset Manager",
        "New Game",
        "Load Game",
        "Settings",
        "Quit"
    }
    local initialClass = self.classSelect:getSelectedClass()
    self.previewCharacter = Character.new(initialClass, 0, 0, Classes.getVisuals(initialClass))
    self.previewCharacter:setVisualScale(PREVIEW_VISUAL_SCALE)
    self.backgroundSeed = 41721
    self.backgroundTime = 0
    self.backgroundDrift = {x = 0.9, y = 0.45}
    self.backgroundFocus = {tx = -8, ty = -5}
    self.chunks = ChunkManager(self.game.tileManager)
    local sw, sh = love.graphics.getDimensions()
    self.camera = Camera(sw, sh)
    self.camera:setZoom(1.75)
end

function MenuState:enter()
    print("Entered Menu State")
    self.game.tileManager:setProceduralSource(self.backgroundSeed)
    self.backgroundTime = 0
    local wx, wy = Iso.tileToScreen(self.backgroundFocus.tx, self.backgroundFocus.ty)
    self.camera:moveTo(wx, wy)
    self:updatePreviewCharacter()
end

function MenuState:exit()
    print("Exited Menu State")
end

function MenuState:update(dt)
    self.backgroundTime = self.backgroundTime + dt
    self.backgroundFocus.tx = self.backgroundFocus.tx + self.backgroundDrift.x * dt
    self.backgroundFocus.ty = self.backgroundFocus.ty + self.backgroundDrift.y * dt
    self.chunks:update(self.backgroundFocus.tx, self.backgroundFocus.ty)
    local wx, wy = Iso.tileToScreen(self.backgroundFocus.tx, self.backgroundFocus.ty)
    self.camera:follow(wx, wy)
    self.camera:update(dt)
    self.previewCharacter:updateVisuals(dt)
end

function MenuState:draw()
    -- Lazy load fonts
    if not self.font then
        self.titleFont = love.graphics.newFont(54)
        self.font = love.graphics.newFont(28)
        self.sectionFont = love.graphics.newFont(22)
        self.smallFont = love.graphics.newFont(16)
    end

    self:drawBackground()
    self:drawAtmosphere()

    love.graphics.setFont(self.titleFont)

    local title = "HOLDFAST"
    local layout = self:getLayout()
    local titleX = layout.menu.x
    local titleY = 34
    love.graphics.setColor(0.04, 0.06, 0.07, 0.55)
    love.graphics.print(title, titleX + 4, titleY + 4)
    love.graphics.setColor(0.97, 0.95, 0.88, 1)
    love.graphics.print(title, titleX, titleY)

    -- Subtitle
    love.graphics.setFont(self.smallFont)
    local subtitle = "A 2D Cooperative Survival Game"
    love.graphics.setColor(0.86, 0.86, 0.80, 1)
    love.graphics.print(subtitle, titleX + 4, titleY + 62)

    self:drawMenuPanel()

    self:drawClassPanel()

    -- Version
    love.graphics.setFont(self.smallFont)
    love.graphics.setColor(0.82, 0.84, 0.80, 0.92)
    love.graphics.print("v0.1.0-alpha - Prototype Menu", 20, love.graphics.getHeight() - 32)

    -- Control hints
    local input = self.game.input
    local controls
    if input:isUsingGamepad() then
        controls = input:getControlPrompt("up/down", "dpup", "navigate") .. "/" ..
                   input:getPrompt("menu_down") .. "  |  D-PAD LEFT/RIGHT: class  |  " ..
                   input:getControlPrompt("enter", "a", "select") .. "  |  " ..
                   input:getControlPrompt("esc", "b", "quit")
    else
        controls = "UP/DOWN: navigate  |  LEFT/RIGHT: class  |  ENTER: select  |  ESC: quit"
    end
    love.graphics.setColor(0.90, 0.91, 0.87, 0.95)
    love.graphics.print(controls, 20, love.graphics.getHeight() - 54)

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

function MenuState:drawBackground()
    love.graphics.clear(0.18, 0.22, 0.25, 1)
    self.camera:apply()

    local drawList = self:_buildDrawList()
    local worldTime = love.timer.getTime()
    local entityDrawList = {}

    for _, e in ipairs(drawList) do
        local renderData = Tile.getRenderData(e.t, e.tx, e.ty, worldTime)

        if renderData and renderData.ground then
            local tint = renderData.ground.tint
            Iso.drawTexturedTile(
                renderData.ground.image,
                renderData.ground.quad,
                e.tx,
                e.ty,
                tint[1] * 0.92,
                tint[2] * 0.92,
                tint[3] * 0.92,
                1
            )
        else
            local c = Tile.getColor(e.t)
            Iso.drawTile(e.tx, e.ty, c[1] * 0.92, c[2] * 0.92, c[3] * 0.92, 1)
        end

        if renderData and renderData.overlay then
            local tint = renderData.overlay.tint
            entityDrawList[#entityDrawList + 1] = {
                sy = e.sy + Iso.TILE_H,
                draw = function()
                    Iso.drawProp(renderData.overlay.image, e.tx, e.ty, {
                        quad = renderData.overlay.quad,
                        scale = renderData.overlay.scale,
                        ox = renderData.overlay.ox,
                        oy = renderData.overlay.oy,
                        anchorX = renderData.overlay.anchorX,
                        anchorY = renderData.overlay.anchorY,
                        r = tint[1] * 0.96,
                        g = tint[2] * 0.96,
                        b = tint[3] * 0.96,
                        a = 0.98
                    })
                end
            }
        end
    end

    table.sort(entityDrawList, function(a, b)
        return a.sy < b.sy
    end)

    for _, entry in ipairs(entityDrawList) do
        entry.draw()
    end

    self.camera:clear()
end

function MenuState:drawAtmosphere()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local layout = self:getLayout()

    love.graphics.setColor(0.04, 0.05, 0.06, 0.20)
    love.graphics.rectangle("fill", 0, 0, w, h)

    love.graphics.setColor(0.05, 0.06, 0.07, 0.58)
    love.graphics.rectangle("fill", layout.menu.x, layout.menu.y, layout.menu.w, layout.menu.h, 24, 24)

    love.graphics.setColor(0.05, 0.06, 0.07, 0.54)
    love.graphics.rectangle("fill", layout.class.x, layout.class.y, layout.class.w, layout.class.h, 24, 24)
end

function MenuState:drawMenuPanel()
    local panel = self:getLayout().menu
    local panelX = panel.x
    local panelY = panel.y
    local panelW = panel.w
    local panelH = panel.h
    local rowH = 68
    local itemHeight = 56
    local headerGap = 34
    local totalHeight = self.sectionFont:getHeight() + headerGap + (#self.options * rowH - (rowH - itemHeight))
    local startY = panelY + (panelH - totalHeight) * 0.5 + self.sectionFont:getHeight() + headerGap + 10

    love.graphics.setColor(0.78, 0.72, 0.48, 0.9)
    love.graphics.rectangle("line", panelX, panelY, panelW, panelH, 24, 24)

    love.graphics.setFont(self.sectionFont)
    love.graphics.setColor(0.85, 0.82, 0.62, 1)
    love.graphics.print("Choose Experience", panelX + 32, startY - self.sectionFont:getHeight() - headerGap)

    love.graphics.setFont(self.font)
    for i, option in ipairs(self.options) do
        local y = startY + (i - 1) * rowH
        local selected = i == self.selectedOption

        if selected then
            love.graphics.setColor(0.78, 0.72, 0.48, 0.95)
            love.graphics.rectangle("fill", panelX + 22, y - 8, panelW - 44, 56, 16, 16)
            love.graphics.setColor(0.10, 0.11, 0.12, 1)
            love.graphics.print(option, panelX + 48, y)
            love.graphics.setColor(0.10, 0.11, 0.12, 1)
            love.graphics.print(">", panelX + panelW - 56, y)
        else
            love.graphics.setColor(0.18, 0.20, 0.22, 0.78)
            love.graphics.rectangle("fill", panelX + 22, y - 8, panelW - 44, 56, 16, 16)
            love.graphics.setColor(0.86, 0.88, 0.90, 1)
            love.graphics.print(option, panelX + 48, y)
        end
    end
end

function MenuState:drawClassPanel()
    local panel = self:getLayout().class
    local panelX = panel.x
    local panelY = panel.y
    local panelW = panel.w
    local panelH = panel.h
    self.classSelect:draw(panel, {
        section = self.sectionFont,
        title = self.titleFont,
        small = self.smallFont,
    })

    local previewX = panelX + panelW * 0.5
    local previewY = panelY + 334
    local shadowY = previewY + self.previewCharacter.drawOffsetY + 6
    local shadowW = 16 * self.previewCharacter.visualScale
    local shadowH = 4.5 * self.previewCharacter.visualScale

    love.graphics.setColor(0.16, 0.19, 0.20, 0.72)
    love.graphics.ellipse("fill", previewX, shadowY, shadowW, shadowH)
    love.graphics.setColor(1, 1, 1, 1)
    self.previewCharacter.position.x = previewX
    self.previewCharacter.position.y = previewY
    self.previewCharacter:draw()

    love.graphics.setColor(1, 1, 1, 1)
end

function MenuState:getLayout()
    local w, h = love.graphics.getDimensions()
    local menuW = 430
    local menuH = 512
    local classW = 322
    local classH = 460
    local sidePadding = 42

    local menuY = math.floor((h - menuH) * 0.5) + 22
    local classY = math.floor((h - classH) * 0.5) + 18

    return {
        menu = {
            x = sidePadding,
            y = menuY,
            w = menuW,
            h = menuH,
        },
        class = {
            x = w - classW - sidePadding,
            y = classY,
            w = classW,
            h = classH,
        }
    }
end

function MenuState:updatePreviewCharacter()
    local selectedClass = self.classSelect:getSelectedClass()
    self.previewCharacter = Character.new(selectedClass, 0, 0, Classes.getVisuals(selectedClass))
    self.previewCharacter:setVisualScale(PREVIEW_VISUAL_SCALE)
    self.previewCharacter:setDesiredMovement(0, 0)
end

function MenuState:_visibleTileRect()
    local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
    local corners = {
        { self.camera:screenToWorld(0,  0)  },
        { self.camera:screenToWorld(sw, 0)  },
        { self.camera:screenToWorld(0,  sh) },
        { self.camera:screenToWorld(sw, sh) },
    }
    local txMin, tyMin = math.huge, math.huge
    local txMax, tyMax = -math.huge, -math.huge

    for _, c in ipairs(corners) do
        local tx, ty = Iso.screenToTile(c[1], c[2])
        if tx < txMin then txMin = tx end
        if ty < tyMin then tyMin = ty end
        if tx > txMax then txMax = tx end
        if ty > tyMax then tyMax = ty end
    end

    local margin = 8
    return math.floor(txMin) - margin, math.floor(tyMin) - margin,
           math.ceil(txMax) + margin, math.ceil(tyMax) + margin
end

function MenuState:_buildDrawList()
    local x1, y1, x2, y2 = self:_visibleTileRect()
    local list = {}
    for tx = x1, x2 do
        for ty = y1, y2 do
            local tileType = self.chunks:getTile(tx, ty)
            local _, sy = Iso.tileToScreen(tx, ty)
            list[#list + 1] = {tx = tx, ty = ty, t = tileType, sy = sy}
        end
    end
    table.sort(list, function(a, b)
        return a.sy < b.sy
    end)
    return list
end

function MenuState:changeClass(delta)
    self.classSelect:change(delta)
    self:updatePreviewCharacter()
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
    elseif key == "left" then
        self:changeClass(-1)
    elseif key == "right" then
        self:changeClass(1)
    elseif key == "return" or key == "space" then
        self:selectOption()
    elseif key == "escape" then
        love.event.quit()
    end
end

function MenuState:gamepadPressed(joystick, button)
    if button == "dpup" then
        self.selectedOption = self.selectedOption - 1
        if self.selectedOption < 1 then
            self.selectedOption = #self.options
        end
    elseif button == "dpdown" then
        self.selectedOption = self.selectedOption + 1
        if self.selectedOption > #self.options then
            self.selectedOption = 1
        end
    elseif button == "dpleft" then
        self:changeClass(-1)
    elseif button == "dpright" then
        self:changeClass(1)
    elseif button == "a" then  -- X button on DualSense (Cross)
        self:selectOption()
    elseif button == "b" then  -- Circle button on DualSense
        love.event.quit()
    end
end

function MenuState:selectOption()
    local selectedClass = self.classSelect:getSelectedClass()
    if self.selectedOption == 1 then
        -- Test Phase 1
        self.game.stateMachine:setState("test", selectedClass)
    elseif self.selectedOption == 2 then
        self.game.stateMachine:setState("asset_manager")
    elseif self.selectedOption == 3 then
        -- New Game
        self.game.stateMachine:setState("world", selectedClass)
    elseif self.selectedOption == 4 then
        -- Load Game (not implemented yet)
        print("Load Game not implemented yet")
    elseif self.selectedOption == 5 then
        -- Settings
        self.game.stateMachine:setState("settings")
    elseif self.selectedOption == 6 then
        -- Quit
        love.event.quit()
    end
end

return MenuState
