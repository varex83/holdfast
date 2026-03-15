-- Node Manager
-- Spawns, stores, and provides access to all resource nodes.
-- Syncs with ChunkManager: when a chunk loads its resource map is
-- converted into ResourceNode objects; when a chunk unloads the nodes
-- are kept alive (depleted state + respawn timer must persist).

local Class        = require("lib.class")
local ResourceNode = require("src.resources.resourcenode")

local NodeManager = Class:extend()

local function tileKey(tx, ty) return tx .. "," .. ty end

function NodeManager:new(respawnManager)
    self._nodes   = {}   -- tileKey → ResourceNode
    self._respawn = respawnManager
end

-- Call after ChunkManager:update().  Iterates the chunk's resource map and
-- creates nodes for tiles that don't already have one.
function NodeManager:syncChunk(chunk)
    local ox = chunk.cx * 16
    local oy = chunk.cy * 16
    for lx = 0, 15 do
        for ly = 0, 15 do
            local resType = chunk.resources[lx] and chunk.resources[lx][ly]
            if resType then
                local tx, ty = ox + lx, oy + ly
                local key = tileKey(tx, ty)
                if not self._nodes[key] then
                    self._nodes[key] = ResourceNode(tx, ty, resType)
                end
            end
        end
    end
end

-- Returns the node at (tx, ty) or nil.
function NodeManager:getAt(tx, ty)
    return self._nodes[tileKey(tx, ty)]
end

-- Returns the flat table of all nodes (for iteration).
function NodeManager:getAll()
    return self._nodes
end

-- Mark a node as depleted and queue it for respawn.
function NodeManager:deplete(node)
    node:deplete()
    if self._respawn then
        self._respawn:register(node)
    end
end

-- Draw all ready nodes inside a tile rect that are currently visible (not in fog).
function NodeManager:draw(rect, fog)
    for _, node in pairs(self._nodes) do
        if node:isReady()
            and node.tx >= rect.x1 and node.tx <= rect.x2
            and node.ty >= rect.y1 and node.ty <= rect.y2
            and (not fog or fog:isVisible(node.tx, node.ty))
        then
            node:draw()
        end
    end
end

return NodeManager
