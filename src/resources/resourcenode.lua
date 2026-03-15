-- Resource Node
-- Represents a single harvestable node in the world (tree, rock, plant…).
-- Nodes are stored in the NodeManager keyed by tile position.

local Class     = require("lib.class")
local Resources = require("data.resources")
local Iso       = require("src.rendering.isometric")
local AssetManager = require("src.core.assetmanager")

local ResourceNode = Class:extend()

-- Node states
ResourceNode.STATE_READY    = "ready"     -- available to harvest
ResourceNode.STATE_DEPLETED = "depleted"  -- harvested out, waiting to respawn

function ResourceNode:new(tx, ty, resourceType)
    self.tx           = tx
    self.ty           = ty
    self.resourceType = resourceType
    self.state        = ResourceNode.STATE_READY

    local def        = Resources[resourceType]
    self.harvestTime = def and def.harvestTime or 3.0
    self.yieldMin    = def and def.yieldMin    or 1
    self.yieldMax    = def and def.yieldMax    or 2
    self.color       = def and def.color       or {1, 0, 1}
end

-- Returns a random yield amount for one harvest.
function ResourceNode:roll()
    return math.random(self.yieldMin, self.yieldMax)
end

function ResourceNode:deplete()
    self.state = ResourceNode.STATE_DEPLETED
end

function ResourceNode:respawn()
    self.state = ResourceNode.STATE_READY
end

function ResourceNode:isReady()
    return self.state == ResourceNode.STATE_READY
end

-- Draw a coloured dot above the tile to indicate the resource.
-- Camera transform must already be applied.
function ResourceNode:draw()
    if self.state == ResourceNode.STATE_DEPLETED then
        if self.resourceType == "wood" then
            local assets = AssetManager.getCurrent()
            local atlas = assets:getAtlas("trees.small_oak")
            Iso.drawProp(atlas.image, self.tx, self.ty, {
                quad = assets:getQuad("trees.small_oak", 0),
                scale = 1.6,
                anchorX = 16,
                anchorY = 58,
                oy = 2,
            })
        end
        return
    end

    local sx, sy = Iso.tileToScreen(self.tx, self.ty)
    local c = self.color

    -- Filled circle
    love.graphics.setColor(c[1], c[2], c[3], 1)
    love.graphics.circle("fill", sx, sy - 4, 7)

    -- Outline
    love.graphics.setColor(c[1]*0.6, c[2]*0.6, c[3]*0.6, 1)
    love.graphics.circle("line", sx, sy - 4, 7)
end

return ResourceNode
