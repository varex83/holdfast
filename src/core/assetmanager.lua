local Class = require("lib.class")
local json = require("lib.dkjson")

local AssetManager = Class:extend()

local currentManager = nil

local function assertDecode(path, payload)
    local data, pos, err = json.decode(payload, 1, nil)
    assert(data, string.format("Failed to decode JSON '%s' at %s: %s", path, tostring(pos), tostring(err)))
    return data
end

local function readJsonFile(path)
    local payload, err = love.filesystem.read(path)
    assert(payload, string.format("Failed to read JSON file '%s': %s", path, tostring(err)))
    return assertDecode(path, payload)
end

local function getSourceRoot()
    local source = love.filesystem.getSource()
    if source and source ~= "" then
        return source
    end

    return "."
end

local function isAbsolutePath(path)
    return path:match("^/") ~= nil or path:match("^[A-Za-z]:[\\/]")
end

local function resolveSourcePath(path)
    if isAbsolutePath(path) then
        return path
    end

    return string.format("%s/%s", getSourceRoot(), path)
end

local function readTextFromSource(path)
    local handle, err = io.open(resolveSourcePath(path), "rb")
    assert(handle, string.format("Failed to open source file '%s': %s", path, tostring(err)))

    local payload = handle:read("*a")
    handle:close()
    return payload
end

local function writeTextToSource(path, payload)
    local handle, err = io.open(resolveSourcePath(path), "wb")
    assert(handle, string.format("Failed to open source file for writing '%s': %s", path, tostring(err)))

    handle:write(payload)
    handle:close()
end

local function mergeTables(dst, src)
    for key, value in pairs(src or {}) do
        dst[key] = value
    end
end

local function chooseVariant(variants, tx, ty)
    local hash = math.abs(tx * 73856093 + ty * 19349663)
    return variants[(hash % #variants) + 1]
end

local function sortedKeys(tbl)
    local keys = {}
    for key in pairs(tbl or {}) do
        keys[#keys + 1] = key
    end
    table.sort(keys)
    return keys
end

local function hasOverlayDefinition(def)
    if type(def) ~= "table" then
        return false
    end

    return def.atlas ~= nil
        or def.atlases ~= nil
        or def.image ~= nil
        or def.images ~= nil
end

function AssetManager:new(manifestPath)
    self.manifestPath = manifestPath or "assets/config/manifest.json"
    self.manifest = nil
    self.data = {
        images = {},
        atlases = {},
        animationSets = {},
        collisionProfiles = {},
        tiles = {},
        tilemaps = {},
    }
    self.cache = {
        imagesById = {},
        imagesByPath = {},
        atlases = {},
        tilemaps = {},
    }
    self._sti = nil
end

function AssetManager:setCurrent()
    currentManager = self
end

function AssetManager.getCurrent()
    assert(currentManager, "AssetManager has not been initialized yet")
    return currentManager
end

function AssetManager:load()
    self.manifest = readJsonFile(self.manifestPath)

    self.data.images = self.manifest.images or {}
    self.data.atlases = self.manifest.atlases or {}
    self.data.animationSets = self.manifest.animationSets or {}
    self.data.collisionProfiles = self.manifest.collisionProfiles or {}
    self.data.tiles = {}
    self.data.tilemaps = {}

    if self.manifest.tilesPath then
        mergeTables(self.data.tiles, (readJsonFile(self.manifest.tilesPath) or {}).tiles)
    end
    mergeTables(self.data.tiles, self.manifest.tiles)

    if self.manifest.tilemapsPath then
        mergeTables(self.data.tilemaps, (readJsonFile(self.manifest.tilemapsPath) or {}).tilemaps)
    end
    mergeTables(self.data.tilemaps, self.manifest.tilemaps)

    self.cache.imagesById = {}
    self.cache.imagesByPath = {}
    self.cache.atlases = {}
    self.cache.tilemaps = {}
end

function AssetManager:reload()
    self:load()
end

function AssetManager:_loadImageByPath(path, def)
    if not self.cache.imagesByPath[path] then
        local image = love.graphics.newImage(path)
        local filter = (def and def.filter) or "nearest"
        local minFilter = (def and def.minFilter) or filter
        local magFilter = (def and def.magFilter) or filter
        image:setFilter(minFilter, magFilter)
        self.cache.imagesByPath[path] = image
    end

    return self.cache.imagesByPath[path]
end

function AssetManager:getImage(id)
    local def = self.data.images[id]
    assert(def, string.format("Unknown image asset id '%s'", tostring(id)))

    if not self.cache.imagesById[id] then
        self.cache.imagesById[id] = self:_loadImageByPath(def.path, def)
    end

    return self.cache.imagesById[id]
end

function AssetManager:getImageFromRef(ref, options)
    if self.data.images[ref] then
        return self:getImage(ref)
    end

    return self:_loadImageByPath(ref, options)
end

function AssetManager:getAtlas(id)
    local atlas = self.cache.atlases[id]
    if atlas then
        return atlas
    end

    local def = self.data.atlases[id]
    assert(def, string.format("Unknown atlas id '%s'", tostring(id)))

    local image = def.image and self:getImage(def.image) or self:getImageFromRef(def.path, def)
    local iw, ih = image:getDimensions()

    atlas = {
        image = image,
        tileWidth = def.tileWidth,
        tileHeight = def.tileHeight,
        columns = math.floor(iw / def.tileWidth),
        quads = {},
    }

    self.cache.atlases[id] = atlas
    return atlas
end

function AssetManager:getQuad(atlasId, tileId)
    local atlas = self:getAtlas(atlasId)

    if not atlas.quads[tileId] then
        local x = (tileId % atlas.columns) * atlas.tileWidth
        local y = math.floor(tileId / atlas.columns) * atlas.tileHeight
        atlas.quads[tileId] = love.graphics.newQuad(
            x,
            y,
            atlas.tileWidth,
            atlas.tileHeight,
            atlas.image:getDimensions()
        )
    end

    return atlas.quads[tileId]
end

function AssetManager:getAnimationSet(id)
    local def = self.data.animationSets[id]
    assert(def, string.format("Unknown animation set '%s'", tostring(id)))
    return def
end

function AssetManager:getCollisionProfile(id)
    return self.data.collisionProfiles[id]
end

function AssetManager:getTileDefinition(tileType)
    return self.data.tiles[tileType]
end

function AssetManager:_resolveGroundData(def, tx, ty, timeSeconds)
    if not def.ground then return nil end
    local atlasId = def.ground.atlas
    if def.ground.atlases then
        atlasId = chooseVariant(def.ground.atlases, tx, ty)
    end

    local tileId
    if def.ground.frames then
        local frameDuration = def.ground.frameDuration or 0.3
        local frameIndex = (math.floor((timeSeconds or 0) / frameDuration) % #def.ground.frames) + 1
        tileId = def.ground.frames[frameIndex]
    elseif def.ground.tileIds then
        tileId = chooseVariant(def.ground.tileIds, tx, ty)
    else
        tileId = chooseVariant(def.ground.variants, tx, ty)
    end

    local atlas = self:getAtlas(atlasId)
    return {
        image = atlas.image,
        quad = self:getQuad(atlasId, tileId),
        tint = def.ground.tint or {1, 1, 1},
    }
end

function AssetManager:_resolveOverlayImageData(def, tx, ty)
    if def.overlay.atlas or def.overlay.atlases then
        local atlasId = def.overlay.atlas
        if def.overlay.atlases then
            atlasId = chooseVariant(def.overlay.atlases, tx, ty)
        end

        local tileId = def.overlay.tileId or 0
        if def.overlay.tileIds then
            tileId = chooseVariant(def.overlay.tileIds, tx, ty)
        end

        local atlas = self:getAtlas(atlasId)
        return atlas.image, self:getQuad(atlasId, tileId)
    else
        local imageRef = def.overlay.image
        if def.overlay.images then
            imageRef = chooseVariant(def.overlay.images, tx, ty)
        end

        return self:getImageFromRef(imageRef, def.overlay), nil
    end
end

function AssetManager:getTileRenderData(tileType, tx, ty, timeSeconds)
    local def = self:getTileDefinition(tileType)
    if not def then
        return nil
    end

    local result = {}

    result.ground = self:_resolveGroundData(def, tx, ty, timeSeconds)

    if hasOverlayDefinition(def.overlay) then
        local overlay = {
            scale = def.overlay.scale or 1,
            tint = def.overlay.tint or {1, 1, 1},
            opacity = def.overlay.opacity or 1,
            ox = def.overlay.ox,
            oy = def.overlay.oy,
            anchorX = def.overlay.anchorX,
            anchorY = def.overlay.anchorY,
        }

        overlay.image, overlay.quad = self:_resolveOverlayImageData(def, tx, ty)

        result.overlay = overlay
    end

    return result
end

function AssetManager:allTileTypes()
    return sortedKeys(self.data.tiles)
end

function AssetManager:getTilemapDefinition(id)
    return self.data.tilemaps[id]
end

function AssetManager:getTilemap(id)
    if self.cache.tilemaps[id] then
        return self.cache.tilemaps[id]
    end

    local def = self:getTilemapDefinition(id)
    assert(def, string.format("Unknown tilemap '%s'", tostring(id)))
    assert(def.format == "tiled_lua", string.format("Unsupported tilemap format '%s' for '%s'", tostring(def.format), tostring(id)))

    if not self._sti then
        self._sti = require("lib.sti")
    end

    local map = self._sti(def.path)
    if def.offsetX then
        map.offsetx = def.offsetX
    end
    if def.offsetY then
        map.offsety = def.offsetY
    end

    self.cache.tilemaps[id] = map
    return map
end

function AssetManager:list(section)
    return sortedKeys(self.data[section] or {})
end

function AssetManager:getSourcePath(path)
    return resolveSourcePath(path)
end

function AssetManager:readJsonDocument(path)
    return assertDecode(path, readTextFromSource(path))
end

function AssetManager:writeJsonDocument(path, document)
    local payload = json.encode(document, { indent = true })
    assert(payload, string.format("Failed to encode JSON document '%s'", tostring(path)))
    writeTextToSource(path, payload .. "\n")
end

return AssetManager
