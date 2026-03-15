local Class = require("lib.class")
local Iso = require("src.rendering.isometric")
local Camera = require("src.core.camera")

local AssetManagerState = Class:extend()

local TABS = { "images", "atlases", "animations", "tiles", "tilemaps" }
local TAB_LABELS = {
    images = "Images",
    atlases = "Atlases",
    animations = "Characters",
    tiles = "Tiles / Props",
    tilemaps = "Tilemaps",
}
local TILE_COLLISION_SHAPES = { "none", "circle", "box" }

local KEY_SIMPLE_ACTIONS = {
    r   = function(s) s:reload() end,
    ["["] = function(s) s:adjustSelectedField(-1) end,
    ["]"] = function(s) s:adjustSelectedField(1) end,
    ["1"] = function(s) s.previewAnimationState = "idle" end,
    ["2"] = function(s) s.previewAnimationState = "walk" end,
    ["3"] = function(s) s.previewAnimationState = "attack" end,
}

local function clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end
    if value > maxValue then
        return maxValue
    end
    return value
end

local function round(value, step)
    step = step or 1
    return math.floor((value / step) + 0.5) * step
end

local function sortedKeys(tbl)
    local keys = {}
    for key in pairs(tbl or {}) do
        keys[#keys + 1] = key
    end
    table.sort(keys)
    return keys
end

local function cycleValue(current, values, delta)
    local index = 1
    for i, value in ipairs(values) do
        if value == current then
            index = i
            break
        end
    end

    index = ((index - 1 + delta) % #values) + 1
    return values[index]
end

local function ensureNumber(value, fallback)
    if type(value) == "number" then
        return value
    end
    return fallback
end

local function parseFirstFrame(frameSpec)
    if type(frameSpec) == "number" then
        return frameSpec
    end

    if type(frameSpec) == "string" then
        local first = frameSpec:match("^(%d+)")
        return tonumber(first) or 1
    end

    return 1
end

function AssetManagerState:new(game)
    self.game = game
    self.name = "asset_manager"
    self.fonts = nil
    self.camera = Camera(love.graphics.getWidth(), love.graphics.getHeight())
    self.camera:setZoom(1)

    self.category = "images"
    self.selection = { images = 1, atlases = 1, animations = 1, tiles = 1, tilemaps = 1 }
    self.fieldSelection = { images = 1, atlases = 1, animations = 1, tiles = 1, tilemaps = 1 }
    self.listScroll = { images = 0, atlases = 0, animations = 0, tiles = 0, tilemaps = 0 }
    self.previewAnimationState = "idle"
    self.documents = nil
    self.assetIds = { images = {}, atlases = {}, animations = {}, tiles = {}, tilemaps = {} }
    self.statusMessage = ""
    self.statusTone = "info"
    self.drag = nil
    self.ui = {}
end

function AssetManagerState:enter()
    self:loadDocuments()
    self:setStatus("Editing runtime JSON config from assets/config.", "info")
end

function AssetManagerState:exit()
    self.drag = nil
end

function AssetManagerState:loadDocuments()
    local assets = self.game.assetManager
    self.documents = {
        manifest = assets:readJsonDocument("assets/config/manifest.json"),
        tiles = assets:readJsonDocument("assets/config/tiles.json"),
        tilemaps = assets:readJsonDocument("assets/config/tilemaps.json"),
    }

    self.assetIds.images = sortedKeys(self.documents.manifest.images)
    self.assetIds.atlases = sortedKeys(self.documents.manifest.atlases)
    self.assetIds.animations = sortedKeys(self.documents.manifest.animationSets)
    self.assetIds.tiles = sortedKeys((self.documents.tiles or {}).tiles)
    self.assetIds.tilemaps = sortedKeys((self.documents.tilemaps or {}).tilemaps)

    for _, tab in ipairs(TABS) do
        self.selection[tab] = clamp(self.selection[tab], 1, math.max(#self.assetIds[tab], 1))
        self.fieldSelection[tab] = 1
    end
end

function AssetManagerState:update(dt)
    self.camera:update(dt)
    self:updateDrag()
end

function AssetManagerState:draw()
    if not self.fonts then
        self.fonts = {
            title = love.graphics.newFont(26),
            heading = love.graphics.newFont(18),
            body = love.graphics.newFont(14),
            small = love.graphics.newFont(12),
        }
    end

    love.graphics.clear(0.09, 0.11, 0.12, 1)

    self.ui = self:computeLayout()

    self:drawShell()
    self:drawTabs()
    self:drawAssetList()
    self:drawPreview()
    self:drawInspector()
    self:drawFooter()

    love.graphics.setColor(1, 1, 1, 1)
end

function AssetManagerState:computeLayout()
    local w, h = love.graphics.getDimensions()
    local padding = 18
    local headerH = 128
    local footerH = 74
    local contentY = padding + headerH
    local contentH = h - padding * 2 - headerH - footerH
    local listW = 280
    local inspectorW = 340
    local previewW = w - padding * 2 - listW - inspectorW - 24

    return {
        frame = { x = padding, y = padding, w = w - padding * 2, h = h - padding * 2 },
        header = { x = padding, y = padding, w = w - padding * 2, h = headerH },
        list = { x = padding, y = contentY, w = listW, h = contentH },
        preview = { x = padding + listW + 12, y = contentY, w = previewW, h = contentH },
        inspector = { x = w - padding - inspectorW, y = contentY, w = inspectorW, h = contentH },
        footer = { x = padding, y = h - padding - footerH, w = w - padding * 2, h = footerH },
    }
end

function AssetManagerState:drawShell()
    local frame = self.ui.frame
    love.graphics.setColor(0.12, 0.14, 0.16, 1)
    love.graphics.rectangle("fill", frame.x, frame.y, frame.w, frame.h, 18, 18)
    love.graphics.setColor(0.33, 0.38, 0.42, 0.7)
    love.graphics.rectangle("line", frame.x, frame.y, frame.w, frame.h, 18, 18)

    love.graphics.setFont(self.fonts.title)
    love.graphics.setColor(0.96, 0.92, 0.82, 1)
    love.graphics.print("Asset Manager", self.ui.header.x + 18, self.ui.header.y + 14)

    love.graphics.setFont(self.fonts.body)
    love.graphics.setColor(0.78, 0.82, 0.84, 1)
    love.graphics.print("Browse all registered assets. Edit character hitboxes and tile collisions here.", self.ui.header.x + 20, self.ui.header.y + 48)
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(0.67, 0.73, 0.77, 1)
    love.graphics.print("Images and atlases are browse-only. Animations and tiles remain editable.", self.ui.header.x + 20, self.ui.header.y + 66)
end

function AssetManagerState:drawTabs()
    local x = self.ui.header.x + 20
    local y = self.ui.header.y + 82
    local tabW = 104
    local tabH = 32

    self.ui.tabs = {}
    for i, tab in ipairs(TABS) do
        local selected = tab == self.category
        local tx = x + (i - 1) * (tabW + 12)
        self.ui.tabs[tab] = { x = tx, y = y, w = tabW, h = tabH }

        love.graphics.setColor(selected and 0.77 or 0.18, selected and 0.64 or 0.2, selected and 0.40 or 0.22, selected and 1 or 0.9)
        love.graphics.rectangle("fill", tx, y, tabW, tabH, 12, 12)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(self.fonts.body)
        love.graphics.printf(TAB_LABELS[tab], tx, y + 8, tabW, "center")
    end
end

function AssetManagerState:drawAssetList()
    local panel = self.ui.list
    local rowH = 30
    local topInset = 52
    local visibleRows = math.max(1, math.floor((panel.h - topInset - 12) / rowH))
    local ids = self.assetIds[self.category]
    local selectedIndex = self.selection[self.category]

    self.listScroll[self.category] = clamp(self.listScroll[self.category], 0, math.max(#ids - visibleRows, 0))
    if selectedIndex <= self.listScroll[self.category] then
        self.listScroll[self.category] = selectedIndex - 1
    elseif selectedIndex > self.listScroll[self.category] + visibleRows then
        self.listScroll[self.category] = selectedIndex - visibleRows
    end

    love.graphics.setColor(0.15, 0.17, 0.19, 1)
    love.graphics.rectangle("fill", panel.x, panel.y, panel.w, panel.h, 16, 16)
    love.graphics.setColor(0.34, 0.38, 0.42, 0.6)
    love.graphics.rectangle("line", panel.x, panel.y, panel.w, panel.h, 16, 16)

    love.graphics.setFont(self.fonts.heading)
    love.graphics.setColor(0.90, 0.92, 0.94, 1)
    love.graphics.print(TAB_LABELS[self.category] or self.category, panel.x + 16, panel.y + 16)

    self.ui.listRows = {}
    local start = self.listScroll[self.category] + 1
    local stop = math.min(#ids, start + visibleRows - 1)
    for index = start, stop do
        local id = ids[index]
        local display = self:getListLabel(self.category, id)
        local rowY = panel.y + topInset + (index - start) * rowH
        local selected = index == selectedIndex

        self.ui.listRows[index] = { x = panel.x + 10, y = rowY, w = panel.w - 20, h = rowH - 4 }
        love.graphics.setColor(selected and 0.76 or 0.19, selected and 0.56 or 0.21, selected and 0.31 or 0.23, selected and 0.92 or 0.85)
        love.graphics.rectangle("fill", panel.x + 10, rowY, panel.w - 20, rowH - 4, 10, 10)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(self.fonts.body)
        love.graphics.print(display, panel.x + 20, rowY + 6)
    end
end

function AssetManagerState:drawPreview()
    local panel = self.ui.preview
    love.graphics.setColor(0.13, 0.15, 0.17, 1)
    love.graphics.rectangle("fill", panel.x, panel.y, panel.w, panel.h, 16, 16)
    love.graphics.setColor(0.34, 0.38, 0.42, 0.6)
    love.graphics.rectangle("line", panel.x, panel.y, panel.w, panel.h, 16, 16)

    love.graphics.setFont(self.fonts.heading)
    love.graphics.setColor(0.9, 0.92, 0.94, 1)
    love.graphics.print("Preview", panel.x + 16, panel.y + 16)

    if self.category == "images" then
        self:drawImagePreview(panel)
    elseif self.category == "atlases" then
        self:drawAtlasPreview(panel)
    elseif self.category == "animations" then
        self:drawAnimationPreview(panel)
    elseif self.category == "tilemaps" then
        self:drawTilemapPreview(panel)
    else
        self:drawTilePreview(panel)
    end
end

function AssetManagerState:drawImagePreview(panel)
    local imageId, def = self:getCurrentImage()
    if not imageId then
        return
    end

    local image = self.game.assetManager:getImage(imageId)
    self:drawTexturePreview(panel, image, nil, imageId, def.path)
end

function AssetManagerState:drawAtlasPreview(panel)
    local atlasId, def = self:getCurrentAtlas()
    if not atlasId then
        return
    end

    local atlas = self.game.assetManager:getAtlas(atlasId)
    self:drawTexturePreview(
        panel,
        atlas.image,
        nil,
        atlasId,
        string.format("%s (%dx%d)", def.path or def.image or "atlas", def.tileWidth or 0, def.tileHeight or 0)
    )
end

function AssetManagerState:drawTexturePreview(panel, image, quad, title, subtitle)
    local previewX = panel.x + 24
    local previewY = panel.y + 54
    local previewW = panel.w - 48
    local previewH = panel.h - 100
    local iw, ih

    if quad then
        local _, _, qw, qh = quad:getViewport()
        iw, ih = qw, qh
    else
        iw, ih = image:getDimensions()
    end

    love.graphics.setColor(0.18, 0.20, 0.22, 1)
    love.graphics.rectangle("fill", previewX, previewY, previewW, previewH, 14, 14)

    local scale = math.min(previewW / iw, previewH / ih)
    love.graphics.setColor(1, 1, 1, 1)
    if quad then
        love.graphics.draw(
            image,
            quad,
            previewX + previewW * 0.5,
            previewY + previewH * 0.5,
            0,
            scale,
            scale,
            iw * 0.5,
            ih * 0.5
        )
    else
        love.graphics.draw(
            image,
            previewX + previewW * 0.5,
            previewY + previewH * 0.5,
            0,
            scale,
            scale,
            iw * 0.5,
            ih * 0.5
        )
    end

    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(0.82, 0.86, 0.89, 1)
    love.graphics.print(title or "", panel.x + 18, panel.y + 38)
    love.graphics.printf(subtitle or "", panel.x + 18, panel.y + panel.h - 34, panel.w - 36, "left")

    self.ui.previewBounds = nil
end

function AssetManagerState:drawAnimationPreview(panel)
    local setId, setDef = self:getCurrentAnimationSet()
    if not setId then
        return
    end

    local stateDef = setDef.states[self.previewAnimationState] or setDef.states.idle or setDef.states.walk or setDef.states.attack
    if not stateDef then
        _, stateDef = next(setDef.states or {})
    end
    if not stateDef then
        return
    end
    local image = self.game.assetManager:getImage(stateDef.image)
    local quad = self:buildAnimationPreviewQuad(setDef, stateDef, image)
    local previewScale = 4
    local cx = panel.x + panel.w * 0.52
    local cy = panel.y + panel.h * 0.62

    love.graphics.setColor(0.18, 0.20, 0.22, 1)
    love.graphics.rectangle("fill", panel.x + 24, panel.y + 54, panel.w - 48, panel.h - 82, 14, 14)
    love.graphics.setColor(0.25, 0.28, 0.31, 1)
    love.graphics.line(panel.x + 24, cy, panel.x + panel.w - 24, cy)
    love.graphics.line(cx, panel.y + 54, cx, panel.y + panel.h - 28)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(
        image,
        quad,
        cx,
        cy + ensureNumber(setDef.drawOffsetY, 0) * previewScale,
        0,
        ensureNumber(setDef.visualScale, 1) * previewScale,
        ensureNumber(setDef.visualScale, 1) * previewScale,
        ensureNumber(setDef.drawOriginX, setDef.frameWidth * 0.5),
        ensureNumber(setDef.drawOriginY, setDef.frameHeight)
    )

    local hitbox = setDef.hitbox or {}
    local bounds = self:getAnimationHitboxBounds(hitbox, cx, cy, previewScale)
    self.ui.previewBounds = {
        kind = "animation",
        panel = panel,
        cx = cx,
        cy = cy,
        scale = previewScale,
        bounds = bounds,
        handles = self:buildRectHandles(bounds),
    }

    love.graphics.setColor(1, 0.45, 0.18, 0.24)
    love.graphics.rectangle("fill", bounds.x, bounds.y, bounds.w, bounds.h)
    love.graphics.setColor(1, 0.55, 0.2, 1)
    love.graphics.rectangle("line", bounds.x, bounds.y, bounds.w, bounds.h)
    self:drawRectHandles(self.ui.previewBounds.handles)

    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(0.82, 0.86, 0.89, 1)
    love.graphics.print("Preview state: " .. self.previewAnimationState .. "  (1/2/3)", panel.x + 18, panel.y + panel.h - 54)
    love.graphics.print("Drag the box to move. Drag a corner to resize symmetrically.", panel.x + 18, panel.y + panel.h - 34)
    love.graphics.print(setId, panel.x + 18, panel.y + 38)
end

function AssetManagerState:_drawTileOverlay(renderData, cx, cy)
    if not (renderData and renderData.overlay) then return end
    local ov = renderData.overlay
    local tint = ov.tint or {1, 1, 1}
    local qw = ov.quad and select(3, ov.quad:getViewport()) or ov.image:getWidth()
    local qh = ov.quad and select(4, ov.quad:getViewport()) or ov.image:getHeight()
    love.graphics.setColor(tint[1], tint[2], tint[3], ov.opacity or 1)
    love.graphics.draw(
        ov.image, ov.quad,
        cx + (ov.ox or 0),
        cy + Iso.TILE_H * 0.5 + (ov.oy or 0),
        0, ov.scale or 1, ov.scale or 1,
        (ov.anchorX or qw * 0.5),
        (ov.anchorY or qh)
    )
end

function AssetManagerState:drawTilePreview(panel)
    local tileId, tileDef = self:getCurrentTile()
    if not tileId then
        return
    end

    local cx = panel.x + panel.w * 0.52
    local cy = panel.y + panel.h * 0.52
    local renderData = self.game.assetManager:getTileRenderData(tileId, 0, 0, love.timer.getTime())

    love.graphics.setColor(0.18, 0.20, 0.22, 1)
    love.graphics.rectangle("fill", panel.x + 24, panel.y + 54, panel.w - 48, panel.h - 82, 14, 14)

    love.graphics.push()
    love.graphics.translate(cx, cy)
    love.graphics.setColor(0.23, 0.27, 0.29, 1)
    love.graphics.polygon("fill", 0, -Iso.TILE_H * 0.5, Iso.TILE_W * 0.5, 0, 0, Iso.TILE_H * 0.5, -Iso.TILE_W * 0.5, 0)
    love.graphics.pop()

    if renderData and renderData.ground then
        local tint = renderData.ground.tint or { 1, 1, 1 }
        love.graphics.setColor(tint[1], tint[2], tint[3], 1)
        love.graphics.push()
        love.graphics.translate(cx, cy - Iso.TILE_H * 0.5)
        Iso.drawTexturedTile(renderData.ground.image, renderData.ground.quad, 0, 0)
        love.graphics.pop()
    end

    self:_drawTileOverlay(renderData, cx, cy)

    local collision = tileDef.collision or {}
    self.ui.previewBounds = {
        kind = "tile",
        panel = panel,
        cx = cx,
        cy = cy,
        collision = collision,
        handles = self:buildTileCollisionHandles(collision, cx, cy),
    }
    self:drawTileCollision(collision, cx, cy)

    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(0.82, 0.86, 0.89, 1)
    love.graphics.print(tileId, panel.x + 18, panel.y + 38)
    love.graphics.print("Circle and box colliders can be dragged in the preview.", panel.x + 18, panel.y + panel.h - 34)
end

function AssetManagerState:drawTilemapPreview(panel)
    local tilemapId, def = self:getCurrentTilemap()
    if not tilemapId then
        return
    end

    local boxX = panel.x + 24
    local boxY = panel.y + 54
    local boxW = panel.w - 48
    local boxH = panel.h - 100

    love.graphics.setColor(0.18, 0.20, 0.22, 1)
    love.graphics.rectangle("fill", boxX, boxY, boxW, boxH, 14, 14)

    local lines = {
        tilemapId,
        def.description or "",
        "Format: " .. tostring(def.format),
        "Path: " .. tostring(def.path),
        "Layer: " .. tostring(def.layer or "auto"),
        "Default Tile: " .. tostring(def.defaultTileType),
        "Out of Bounds: " .. tostring(def.outOfBoundsTileType),
    }

    love.graphics.setFont(self.fonts.body)
    love.graphics.setColor(0.92, 0.93, 0.95, 1)
    local y = boxY + 18
    for _, line in ipairs(lines) do
        love.graphics.printf(line, boxX + 16, y, boxW - 32, "left")
        y = y + 26
    end

    self.ui.previewBounds = nil
end

function AssetManagerState:drawInspector()
    local panel = self.ui.inspector
    love.graphics.setColor(0.15, 0.17, 0.19, 1)
    love.graphics.rectangle("fill", panel.x, panel.y, panel.w, panel.h, 16, 16)
    love.graphics.setColor(0.34, 0.38, 0.42, 0.6)
    love.graphics.rectangle("line", panel.x, panel.y, panel.w, panel.h, 16, 16)

    love.graphics.setFont(self.fonts.heading)
    love.graphics.setColor(0.90, 0.92, 0.94, 1)
    love.graphics.print("Inspector", panel.x + 16, panel.y + 16)

    local fields = self:getEditableFields()
    local selectedField = self.fieldSelection[self.category]
    self.ui.inspectorFields = {}

    local y = panel.y + 54
    for index, field in ipairs(fields) do
        local row = { x = panel.x + 12, y = y, w = panel.w - 24, h = 34 }
        self.ui.inspectorFields[index] = row
        local selected = index == selectedField

        love.graphics.setColor(selected and 0.28 or 0.18, selected and 0.33 or 0.20, selected and 0.37 or 0.22, 1)
        love.graphics.rectangle("fill", row.x, row.y, row.w, row.h, 10, 10)

        love.graphics.setFont(self.fonts.body)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(field.label, row.x + 10, row.y + 8)
        love.graphics.printf(field:formatValue(), row.x + 128, row.y + 8, 92, "right")

        row.minus = { x = row.x + row.w - 70, y = row.y + 5, w = 26, h = 24 }
        row.plus = { x = row.x + row.w - 36, y = row.y + 5, w = 26, h = 24 }
        self:drawMiniButton(row.minus, "-")
        self:drawMiniButton(row.plus, "+")
        y = y + 40
    end
end

function AssetManagerState:drawFooter()
    local panel = self.ui.footer
    love.graphics.setColor(0.12, 0.14, 0.15, 1)
    love.graphics.rectangle("fill", panel.x, panel.y, panel.w, panel.h, 16, 16)
    love.graphics.setColor(0.30, 0.35, 0.39, 0.7)
    love.graphics.rectangle("line", panel.x, panel.y, panel.w, panel.h, 16, 16)

    local tone = {
        info = { 0.84, 0.88, 0.92 },
        success = { 0.58, 0.88, 0.62 },
        error = { 0.95, 0.54, 0.52 },
    }
    local color = tone[self.statusTone] or tone.info

    love.graphics.setFont(self.fonts.body)
    love.graphics.setColor(color[1], color[2], color[3], 1)
    love.graphics.print(self.statusMessage, panel.x + 16, panel.y + 14)

    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(0.82, 0.86, 0.89, 1)
    love.graphics.print("TAB or LEFT/RIGHT switch category   UP/DOWN select asset   A/D select field   [/ ] adjust field   S save edits   R reload   ESC menu", panel.x + 16, panel.y + 42)
end

function AssetManagerState:getListLabel(category, id)
    if category == "tiles" then
        local def = self.documents.tiles and self.documents.tiles.tiles and self.documents.tiles.tiles[id]
        if def and def.name and def.name ~= id then
            return string.format("%s (%s)", def.name, id)
        end
    end

    return id
end

function AssetManagerState:getCurrentImage()
    local ids = self.assetIds.images
    local id = ids[self.selection.images]
    if not id then
        return nil
    end
    return id, self.documents.manifest.images[id]
end

function AssetManagerState:getCurrentAtlas()
    local ids = self.assetIds.atlases
    local id = ids[self.selection.atlases]
    if not id then
        return nil
    end
    return id, self.documents.manifest.atlases[id]
end

function AssetManagerState:buildAnimationPreviewQuad(setDef, stateDef, image)
    local frame = parseFirstFrame(stateDef.frames)
    local frameX = (frame - 1) * setDef.frameWidth
    local frameY = ((stateDef.row or 1) - 1) * setDef.frameHeight
    return love.graphics.newQuad(frameX, frameY, setDef.frameWidth, setDef.frameHeight, image:getDimensions())
end

function AssetManagerState:getAnimationHitboxBounds(hitbox, cx, cy, scale)
    local width = ensureNumber(hitbox.width, 24) * scale
    local height = ensureNumber(hitbox.height, 24) * scale
    local centerX = cx + ensureNumber(hitbox.offsetX, 0) * scale
    local centerY = cy + ensureNumber(hitbox.offsetY, 0) * scale
    return {
        x = centerX - width * 0.5,
        y = centerY - height * 0.5,
        w = width,
        h = height,
        centerX = centerX,
        centerY = centerY,
    }
end

function AssetManagerState:buildRectHandles(bounds)
    local size = 10
    return {
        move = { x = bounds.x, y = bounds.y, w = bounds.w, h = bounds.h },
        tl = { x = bounds.x - size * 0.5, y = bounds.y - size * 0.5, w = size, h = size },
        tr = { x = bounds.x + bounds.w - size * 0.5, y = bounds.y - size * 0.5, w = size, h = size },
        bl = { x = bounds.x - size * 0.5, y = bounds.y + bounds.h - size * 0.5, w = size, h = size },
        br = { x = bounds.x + bounds.w - size * 0.5, y = bounds.y + bounds.h - size * 0.5, w = size, h = size },
    }
end

function AssetManagerState:drawRectHandles(handles)
    love.graphics.setColor(1, 0.74, 0.3, 1)
    for key, handle in pairs(handles) do
        if key ~= "move" then
            love.graphics.rectangle("fill", handle.x, handle.y, handle.w, handle.h, 3, 3)
        end
    end
end

function AssetManagerState:buildTileCollisionHandles(collision, cx, cy)
    if not collision.shape or collision.shape == "none" then
        return {}
    end

    if collision.shape == "circle" then
        local centerX = cx + ensureNumber(collision.offsetX, 0) * Iso.TILE_W
        local centerY = cy + Iso.TILE_H * 0.5 + ensureNumber(collision.offsetY, 0) * Iso.TILE_H
        local radius = ensureNumber(collision.radius, 0.15) * Iso.TILE_W
        return {
            move = { x = centerX - radius, y = centerY - radius, w = radius * 2, h = radius * 2 },
            radius = { x = centerX + radius - 6, y = centerY - 6, w = 12, h = 12 },
            centerX = centerX,
            centerY = centerY,
            radiusValue = radius,
        }
    end

    local width = ensureNumber(collision.width, 0.28) * Iso.TILE_W
    local height = ensureNumber(collision.height, 0.28) * Iso.TILE_H * 2
    local centerX = cx + ensureNumber(collision.offsetX, 0) * Iso.TILE_W
    local centerY = cy + Iso.TILE_H * 0.5 + ensureNumber(collision.offsetY, 0) * Iso.TILE_H
    local bounds = {
        x = centerX - width * 0.5,
        y = centerY - height * 0.5,
        w = width,
        h = height,
    }
    local handles = self:buildRectHandles(bounds)
    handles.centerX = centerX
    handles.centerY = centerY
    return handles
end

function AssetManagerState:drawTileCollision(collision, cx, cy)
    if not collision.shape or collision.shape == "none" then
        return
    end

    if collision.shape == "circle" then
        local centerX = cx + ensureNumber(collision.offsetX, 0) * Iso.TILE_W
        local centerY = cy + Iso.TILE_H * 0.5 + ensureNumber(collision.offsetY, 0) * Iso.TILE_H
        local radius = ensureNumber(collision.radius, 0.15) * Iso.TILE_W
        love.graphics.setColor(1, 0.45, 0.18, 0.20)
        love.graphics.circle("fill", centerX, centerY, radius)
        love.graphics.setColor(1, 0.55, 0.2, 1)
        love.graphics.circle("line", centerX, centerY, radius)
        love.graphics.rectangle("fill", centerX + radius - 6, centerY - 6, 12, 12, 3, 3)
        return
    end

    local width = ensureNumber(collision.width, 0.28) * Iso.TILE_W
    local height = ensureNumber(collision.height, 0.28) * Iso.TILE_H * 2
    local centerX = cx + ensureNumber(collision.offsetX, 0) * Iso.TILE_W
    local centerY = cy + Iso.TILE_H * 0.5 + ensureNumber(collision.offsetY, 0) * Iso.TILE_H
    local bounds = { x = centerX - width * 0.5, y = centerY - height * 0.5, w = width, h = height }

    love.graphics.setColor(1, 0.45, 0.18, 0.20)
    love.graphics.rectangle("fill", bounds.x, bounds.y, bounds.w, bounds.h)
    love.graphics.setColor(1, 0.55, 0.2, 1)
    love.graphics.rectangle("line", bounds.x, bounds.y, bounds.w, bounds.h)
    self:drawRectHandles(self:buildRectHandles(bounds))
end

function AssetManagerState:getCurrentAnimationSet()
    local ids = self.assetIds.animations
    local id = ids[self.selection.animations]
    if not id then
        return nil
    end
    return id, self.documents.manifest.animationSets[id]
end

function AssetManagerState:getCurrentTile()
    local ids = self.assetIds.tiles
    local id = ids[self.selection.tiles]
    if not id then
        return nil
    end
    return id, self.documents.tiles.tiles[id]
end

function AssetManagerState:getCurrentTilemap()
    local ids = self.assetIds.tilemaps
    local id = ids[self.selection.tilemaps]
    if not id then
        return nil
    end
    return id, self.documents.tilemaps.tilemaps[id]
end

function AssetManagerState:_buildTileFields(tileDef)
    tileDef.collision = tileDef.collision or { shape = "none" }
    tileDef.overlay = type(tileDef.overlay) == "table" and tileDef.overlay or {}
    local col = tileDef.collision
    local ov  = tileDef.overlay
    return {
        self:booleanField("Walkable", function() return tileDef.walkable end, function(v) tileDef.walkable = v end),
        self:cycleField("Collision Shape", function() return col.shape or "none" end, function(v)
            col.shape = v
            if v == "circle" then
                col.radius  = col.radius  or 0.12
                col.offsetX = col.offsetX or 0
                col.offsetY = col.offsetY or 0.08
            elseif v == "box" then
                col.width   = col.width   or 0.24
                col.height  = col.height  or 0.20
                col.offsetX = col.offsetX or 0
                col.offsetY = col.offsetY or 0.08
            end
        end, TILE_COLLISION_SHAPES),
        self:numberField("Collision Radius",   function() return col.radius  end, function(v) col.radius  = clamp(v,0.02,1) end, 0.01, 2),
        self:numberField("Collision Width",    function() return col.width   end, function(v) col.width   = clamp(v,0.02,1) end, 0.01, 2),
        self:numberField("Collision Height",   function() return col.height  end, function(v) col.height  = clamp(v,0.02,1) end, 0.01, 2),
        self:numberField("Collision Offset X", function() return col.offsetX end, function(v) col.offsetX = clamp(v,-1,1)  end, 0.01, 2),
        self:numberField("Collision Offset Y", function() return col.offsetY end, function(v) col.offsetY = clamp(v,-1,1)  end, 0.01, 2),
        self:numberField("Overlay Scale",      function() return ov.scale    end, function(v) ov.scale    = clamp(v,0.1,8) end, 0.05, 2),
        self:numberField("Overlay Offset X",   function() return ov.ox       end, function(v) ov.ox       = clamp(v,-256,256) end, 1),
        self:numberField("Overlay Offset Y",   function() return ov.oy       end, function(v) ov.oy       = clamp(v,-256,256) end, 1),
    }
end

function AssetManagerState:_buildAnimationFields(setDef)
    setDef.hitbox = setDef.hitbox or {}
    local hb = setDef.hitbox
    return {
        self:numberField("Draw Origin X",  function() return setDef.drawOriginX end, function(v) setDef.drawOriginX = clamp(v,0,256) end, 1),
        self:numberField("Draw Origin Y",  function() return setDef.drawOriginY end, function(v) setDef.drawOriginY = clamp(v,0,256) end, 1),
        self:numberField("Draw Offset Y",  function() return setDef.drawOffsetY end, function(v) setDef.drawOffsetY = clamp(v,-128,128) end, 1),
        self:numberField("Visual Scale",   function() return setDef.visualScale end, function(v) setDef.visualScale = clamp(v,0.25,8) end, 0.05, 2),
        self:numberField("Hitbox Width",   function() return hb.width    end, function(v) hb.width    = clamp(v,1,256) end, 1),
        self:numberField("Hitbox Height",  function() return hb.height   end, function(v) hb.height   = clamp(v,1,256) end, 1),
        self:numberField("Hitbox Offset X",function() return hb.offsetX  end, function(v) hb.offsetX  = clamp(v,-128,128) end, 1),
        self:numberField("Hitbox Offset Y",function() return hb.offsetY  end, function(v) hb.offsetY  = clamp(v,-128,128) end, 1),
    }
end

function AssetManagerState:getEditableFields()
    if self.category == "images" then
        local _, def = self:getCurrentImage()
        return {
            self:readOnlyField("Path",       def and def.path   or ""),
            self:readOnlyField("Filter",     def and def.filter or "default"),
            self:readOnlyField("Min Filter", def and def.minFilter or "-"),
            self:readOnlyField("Mag Filter", def and def.magFilter or "-"),
        }
    end
    if self.category == "atlases" then
        local _, def = self:getCurrentAtlas()
        return {
            self:readOnlyField("Path",         def and (def.path or def.image) or ""),
            self:readOnlyField("Tile Width",   tostring(def and def.tileWidth  or "")),
            self:readOnlyField("Tile Height",  tostring(def and def.tileHeight or "")),
            self:readOnlyField("Filter",       def and def.filter or "default"),
        }
    end
    if self.category == "animations" then
        local _, setDef = self:getCurrentAnimationSet()
        return self:_buildAnimationFields(setDef)
    end
    if self.category == "tilemaps" then
        local _, def = self:getCurrentTilemap()
        return {
            self:readOnlyField("Path",          def and def.path or ""),
            self:readOnlyField("Format",        def and def.format or ""),
            self:readOnlyField("Layer",         def and tostring(def.layer or "auto") or ""),
            self:readOnlyField("Default Tile",  def and tostring(def.defaultTileType or "") or ""),
            self:readOnlyField("Out of Bounds", def and tostring(def.outOfBoundsTileType or "") or ""),
        }
    end
    local _, tileDef = self:getCurrentTile()
    return self:_buildTileFields(tileDef)
end

function AssetManagerState:readOnlyField(label, value)
    return {
        kind = "readonly",
        label = label,
        adjust = function() end,
        formatValue = function()
            return tostring(value)
        end,
    }
end

function AssetManagerState:numberField(label, getter, setter, step, decimals)
    return {
        kind = "number",
        label = label,
        adjust = function(delta)
            local value = ensureNumber(getter(), 0)
            setter(round(value + delta * step, step))
        end,
        formatValue = function()
            local value = ensureNumber(getter(), 0)
            if decimals then
                return string.format("%." .. decimals .. "f", value)
            end
            return tostring(value)
        end,
    }
end

function AssetManagerState:booleanField(label, getter, setter)
    return {
        kind = "boolean",
        label = label,
        adjust = function(delta)
            if delta ~= 0 then
                setter(not getter())
            end
        end,
        formatValue = function()
            return getter() and "true" or "false"
        end,
    }
end

function AssetManagerState:cycleField(label, getter, setter, values)
    return {
        kind = "cycle",
        label = label,
        adjust = function(delta)
            setter(cycleValue(getter(), values, delta > 0 and 1 or -1))
        end,
        formatValue = function()
            return tostring(getter())
        end,
    }
end

function AssetManagerState:adjustSelectedField(delta)
    local fields = self:getEditableFields()
    local field = fields[self.fieldSelection[self.category]]
    if field then
        field.adjust(delta)
    end
end

function AssetManagerState:setStatus(message, tone)
    self.statusMessage = message
    self.statusTone = tone or "info"
end

function AssetManagerState:save()
    local ok, err = pcall(function()
        self.game.assetManager:writeJsonDocument("assets/config/manifest.json", self.documents.manifest)
        self.game.assetManager:writeJsonDocument("assets/config/tiles.json", self.documents.tiles)
        self.game.assetManager:writeJsonDocument("assets/config/tilemaps.json", self.documents.tilemaps)
        self.game.assetManager:reload()
    end)

    if ok then
        self:setStatus("Saved manifest and tile config back to assets/config.", "success")
    else
        self:setStatus("Save failed: " .. tostring(err), "error")
    end
end

function AssetManagerState:reload()
    local ok, err = pcall(function()
        self:loadDocuments()
        self.game.assetManager:reload()
    end)

    if ok then
        self:setStatus("Reloaded JSON from disk and refreshed runtime asset cache.", "success")
    else
        self:setStatus("Reload failed: " .. tostring(err), "error")
    end
end

function AssetManagerState:keypressed(key)
    if key == "escape" then self.game.stateMachine:setState("menu") return end
    if key == "tab" or key == "right" then
        self.category = cycleValue(self.category, TABS, 1) return
    end
    if key == "left" then self.category = cycleValue(self.category, TABS, -1) return end
    if key == "up" then
        self.selection[self.category] = clamp(self.selection[self.category] - 1, 1, math.max(#self.assetIds[self.category], 1))
        return
    end
    if key == "down" then
        self.selection[self.category] = clamp(self.selection[self.category] + 1, 1, math.max(#self.assetIds[self.category], 1))
        return
    end
    if key == "w" or key == "a" then
        self.fieldSelection[self.category] = clamp(self.fieldSelection[self.category] - 1, 1, #self:getEditableFields())
        return
    end
    if key == "d" then
        self.fieldSelection[self.category] = clamp(self.fieldSelection[self.category] + 1, 1, #self:getEditableFields())
        return
    end
    if key == "s" and not love.keyboard.isDown("lctrl", "rctrl", "lgui", "rgui") then
        self:save() return
    end
    if KEY_SIMPLE_ACTIONS[key] then KEY_SIMPLE_ACTIONS[key](self) end
end

function AssetManagerState:wheelmoved(_, y)
    self.listScroll[self.category] = clamp(self.listScroll[self.category] - y, 0, math.max(#self.assetIds[self.category] - 1, 0))
end

function AssetManagerState:mousepressed(x, y, button)
    if button ~= 1 then
        return
    end

    for tab, rect in pairs(self.ui.tabs or {}) do
        if self:isInside(x, y, rect) then
            self.category = tab
            return
        end
    end

    for index, row in pairs(self.ui.listRows or {}) do
        if self:isInside(x, y, row) then
            self.selection[self.category] = index
            return
        end
    end

    for index, row in ipairs(self.ui.inspectorFields or {}) do
        if self:isInside(x, y, row.minus) then
            self.fieldSelection[self.category] = index
            self:adjustSelectedField(-1)
            return
        end
        if self:isInside(x, y, row.plus) then
            self.fieldSelection[self.category] = index
            self:adjustSelectedField(1)
            return
        end
        if self:isInside(x, y, row) then
            self.fieldSelection[self.category] = index
            return
        end
    end

    self:beginPreviewDrag(x, y)
end

function AssetManagerState:mousereleased(_, _, button)
    if button == 1 then
        self.drag = nil
    end
end

function AssetManagerState:_beginAnimationDrag(x, y, preview)
    local _, setDef = self:getCurrentAnimationSet()
    local hitbox = setDef.hitbox or {}
    for name, handle in pairs(preview.handles or {}) do
        if self:isInside(x, y, handle) then
            self.drag = {
                type    = name == "move" and "animation-move" or "animation-resize",
                scale   = preview.scale,
                cx      = preview.cx,
                cy      = preview.cy,
                startX  = x,
                startY  = y,
                offsetX = ensureNumber(hitbox.offsetX, 0),
                offsetY = ensureNumber(hitbox.offsetY, 0),
                width   = ensureNumber(hitbox.width, 24),
                height  = ensureNumber(hitbox.height, 24),
            }
            return
        end
    end
end

function AssetManagerState:_beginTileDrag(x, y, preview)
    local _, tileDef = self:getCurrentTile()
    tileDef.collision = tileDef.collision or { shape = "none" }
    local collision = tileDef.collision
    if collision.shape == "circle" then
        local handles = preview.handles or {}
        if handles.radius and self:isInside(x, y, handles.radius) then
            self.drag = { type = "tile-circle-radius", cx = preview.cx, cy = preview.cy }
        elseif handles.move and self:isInside(x, y, handles.move) then
            self.drag = {
                type = "tile-circle-move", startX = x, startY = y,
                offsetX = ensureNumber(collision.offsetX, 0),
                offsetY = ensureNumber(collision.offsetY, 0),
            }
        end
        return
    end
    if collision.shape == "box" then
        for name, handle in pairs(preview.handles or {}) do
            if type(handle) == "table" and handle.x and self:isInside(x, y, handle) then
                self.drag = {
                    type    = name == "move" and "tile-box-move" or "tile-box-resize",
                    startX  = x, startY  = y,
                    offsetX = ensureNumber(collision.offsetX, 0),
                    offsetY = ensureNumber(collision.offsetY, 0),
                    width   = ensureNumber(collision.width, 0.24),
                    height  = ensureNumber(collision.height, 0.20),
                    cx = preview.cx, cy = preview.cy,
                }
                return
            end
        end
    end
end

function AssetManagerState:beginPreviewDrag(x, y)
    local preview = self.ui.previewBounds
    if not preview then return end
    if self.category == "animations" and preview.kind == "animation" then
        self:_beginAnimationDrag(x, y, preview)
        return
    end
    if self.category == "tiles" then
        self:_beginTileDrag(x, y, preview)
    end
end

function AssetManagerState:updateDrag()
    if not self.drag or not love.mouse.isDown(1) then
        return
    end

    local x, y = love.mouse.getPosition()

    if self.drag.type == "animation-move" or self.drag.type == "animation-resize" then
        local _, setDef = self:getCurrentAnimationSet()
        setDef.hitbox = setDef.hitbox or {}
        if self.drag.type == "animation-move" then
            setDef.hitbox.offsetX = round(self.drag.offsetX + (x - self.drag.startX) / self.drag.scale, 1)
            setDef.hitbox.offsetY = round(self.drag.offsetY + (y - self.drag.startY) / self.drag.scale, 1)
        else
            local localX = (x - self.drag.cx) / self.drag.scale - ensureNumber(setDef.hitbox.offsetX, 0)
            local localY = (y - self.drag.cy) / self.drag.scale - ensureNumber(setDef.hitbox.offsetY, 0)
            setDef.hitbox.width = clamp(round(math.abs(localX) * 2, 1), 1, 256)
            setDef.hitbox.height = clamp(round(math.abs(localY) * 2, 1), 1, 256)
        end
        return
    end

    local _, tileDef = self:getCurrentTile()
    tileDef.collision = tileDef.collision or {}
    local collision = tileDef.collision

    if self.drag.type == "tile-circle-move" then
        collision.offsetX = clamp(round(self.drag.offsetX + (x - self.drag.startX) / Iso.TILE_W, 0.01), -1, 1)
        collision.offsetY = clamp(round(self.drag.offsetY + (y - self.drag.startY) / Iso.TILE_H, 0.01), -1, 1)
        return
    end

    if self.drag.type == "tile-circle-radius" then
        local preview = self.ui.previewBounds
        local centerX = preview.cx + ensureNumber(collision.offsetX, 0) * Iso.TILE_W
        local centerY = preview.cy + Iso.TILE_H * 0.5 + ensureNumber(collision.offsetY, 0) * Iso.TILE_H
        collision.radius = clamp(round(math.sqrt((x - centerX) ^ 2 + (y - centerY) ^ 2) / Iso.TILE_W, 0.01), 0.02, 1)
        return
    end

    if self.drag.type == "tile-box-move" then
        collision.offsetX = clamp(round(self.drag.offsetX + (x - self.drag.startX) / Iso.TILE_W, 0.01), -1, 1)
        collision.offsetY = clamp(round(self.drag.offsetY + (y - self.drag.startY) / Iso.TILE_H, 0.01), -1, 1)
        return
    end

    if self.drag.type == "tile-box-resize" then
        local preview = self.ui.previewBounds
        local centerX = preview.cx + ensureNumber(collision.offsetX, 0) * Iso.TILE_W
        local centerY = preview.cy + Iso.TILE_H * 0.5 + ensureNumber(collision.offsetY, 0) * Iso.TILE_H
        collision.width = clamp(round(math.abs(x - centerX) * 2 / Iso.TILE_W, 0.01), 0.02, 1)
        collision.height = clamp(round(math.abs(y - centerY) / Iso.TILE_H, 0.01), 0.02, 1)
    end
end

function AssetManagerState:drawMiniButton(rect, label)
    love.graphics.setColor(0.27, 0.30, 0.33, 1)
    love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h, 6, 6)
    love.graphics.setColor(0.95, 0.95, 0.95, 1)
    love.graphics.printf(label, rect.x, rect.y + 5, rect.w, "center")
end

function AssetManagerState:isInside(x, y, rect)
    return rect and x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h
end

return AssetManagerState
