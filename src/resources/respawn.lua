-- Respawn System
-- Tracks depleted resource nodes and respawns them after a timer.
-- Nodes closer to the base respawn slower (or not at all until the player
-- moves away), matching the config values.

local Class = require("lib.class")

local RespawnManager = Class:extend()

-- Default respawn time in seconds (overridden by config).
local DEFAULT_RESPAWN_TIME = 300   -- 5 minutes
-- Minimum tile distance from base for a node to respawn.
local MIN_DIST_FROM_BASE   = 20

function RespawnManager:new(config)
    self._config  = config or {}
    self._queue   = {}   -- list of { node, timer }
    self._baseX   = 0    -- base core tile position (set when base is placed)
    self._baseY   = 0
end

-- Update the known base position (call when base core is placed/moved).
function RespawnManager:setBasePosition(tx, ty)
    self._baseX = tx
    self._baseY = ty
end

-- Register a depleted node for future respawn.
function RespawnManager:register(node)
    local respawnTime = self._config.resourceRespawnTime or DEFAULT_RESPAWN_TIME
    self._queue[#self._queue + 1] = { node = node, timer = respawnTime }
end

-- Returns true if the node is far enough from base to respawn.
function RespawnManager:_isFarEnough(node)
    local minDist = self._config.resourceRespawnDistance or MIN_DIST_FROM_BASE
    local dx = node.tx - self._baseX
    local dy = node.ty - self._baseY
    return (dx*dx + dy*dy) >= (minDist * minDist)
end

function RespawnManager:update(dt)
    local i = 1
    while i <= #self._queue do
        local entry = self._queue[i]
        entry.timer = entry.timer - dt

        if entry.timer <= 0 and self:_isFarEnough(entry.node) then
            entry.node:respawn()
            table.remove(self._queue, i)
        else
            i = i + 1
        end
    end
end

-- Number of nodes currently waiting to respawn (debug/UI).
function RespawnManager:pendingCount()
    return #self._queue
end

return RespawnManager
