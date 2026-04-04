local Class = require("lib.class")
local WorldGen = require("src.world.worldgen")
local Tilemap = require("src.world.tilemap")

local TileManager = Class:extend()

local function getLayerByName(map, name)
    if not name then
        return nil
    end

    for _, layer in ipairs(map.layers or {}) do
        if layer.name == name then
            return layer
        end
    end
end

local function layerIndex(layer, x, y)
    return y * layer.width + x + 1
end

function TileManager:new()
    self.source = {
        mode = "procedural",
        seed = 12345,
    }
    self.tilemapState = nil
end

function TileManager:setProceduralSource(seed)
    self.source = {
        mode = "procedural",
        seed = seed or 12345,
    }
    self.tilemapState = nil
    WorldGen.init(self.source.seed)
end

function TileManager:setTilemapSource(tilemapId)
    local def = Tilemap.getDefinition(tilemapId)
    local map = Tilemap.load(tilemapId)
    local layer = getLayerByName(map, def.layer)

    if not layer then
        for _, candidate in ipairs(map.layers or {}) do
            if candidate.type == "tilelayer" then
                layer = candidate
                break
            end
        end
    end

    assert(layer, string.format("Tilemap '%s' does not define a tile layer", tostring(tilemapId)))

    self.source = {
        mode = "tilemap",
        tilemapId = tilemapId,
    }
    self.tilemapState = {
        definition = def,
        map = map,
        layer = layer,
    }
end

function TileManager:getTileData(tx, ty)
    if self.source.mode == "tilemap" then
        return self:_getTilemapTileData(tx, ty)
    end

    return self:_getProceduralTileData(tx, ty)
end

function TileManager:getTileType(tx, ty)
    local data = self:getTileData(tx, ty)
    return data and data.type or nil
end

function TileManager:getResourceType(tx, ty)
    local data = self:getTileData(tx, ty)
    return data and data.resourceType or nil
end

function TileManager:isWithinActiveTilemap(tx, ty)
    if self.source.mode ~= "tilemap" or not self.tilemapState then
        return true
    end

    local def = self.tilemapState.definition
    local layer = self.tilemapState.layer
    local localX = tx - (def.originX or 0)
    local localY = ty - (def.originY or 0)

    return localX >= 0 and localY >= 0 and localX < layer.width and localY < layer.height
end

function TileManager:_getProceduralTileData(tx, ty)
    local tileType = WorldGen.getTileAt(tx, ty)
    return {
        type = tileType,
        resourceType = WorldGen.getResourceAt(tx, ty, tileType),
    }
end

function TileManager:_getTilemapTileData(tx, ty)
    local state = self.tilemapState
    local def = state.definition
    local layer = state.layer
    local localX = tx - (def.originX or 0)
    local localY = ty - (def.originY or 0)

    if localX < 0 or localY < 0 or localX >= layer.width or localY >= layer.height then
        return {
            type = def.outOfBoundsTileType or def.defaultTileType,
            resourceType = nil,
        }
    end

    local gid = layer.data[layerIndex(layer, localX, localY)] or 0
    local gidKey = tostring(gid)
    local tileType = (def.gidToTileType and def.gidToTileType[gidKey]) or def.defaultTileType
    local resourceType = def.gidToResourceType and def.gidToResourceType[gidKey] or nil

    return {
        type = tileType,
        resourceType = resourceType,
        gid = gid,
    }
end

return TileManager
