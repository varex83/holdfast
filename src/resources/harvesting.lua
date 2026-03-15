-- Harvesting System
-- Manages the active harvest action: proximity check, progress bar,
-- and depletion on completion.  One harvest action at a time per player.

local Class    = require("lib.class")
local Iso      = require("src.rendering.isometric")

local HarvestManager = Class:extend()

local INTERACT_RADIUS = 2.0   -- tile distance to start harvesting
local BAR_W           = 40
local BAR_H           = 6

function HarvestManager:new(eventBus)
    self.eventBus  = eventBus
    self._active   = nil   -- { node, progress, duration }
end

-- Returns the nearest ready node within INTERACT_RADIUS of (ptx, pty),
-- or nil if none.
function HarvestManager:nearestNode(ptx, pty, nodeManager)
    local best, bestDist = nil, INTERACT_RADIUS
    for _, node in pairs(nodeManager:getAll()) do
        if node:isReady() then
            local dx = node.tx - ptx
            local dy = node.ty - pty
            local d  = math.sqrt(dx*dx + dy*dy)
            if d < bestDist then
                bestDist = d
                best     = node
            end
        end
    end
    return best
end

-- Call when player presses E. Starts harvesting the nearest eligible node.
-- Returns true if a harvest was started.
function HarvestManager:tryStart(ptx, pty, nodeManager, inventory)
    if self._active then return false end  -- already harvesting
    if inventory and inventory:isFull() then return false end
    local node = self:nearestNode(ptx, pty, nodeManager)
    if not node then return false end

    self._active = { node = node, progress = 0, duration = node.harvestTime }
    return true
end

-- Cancel any in-progress harvest (e.g. player moved too far).
function HarvestManager:cancel()
    self._active = nil
end

function HarvestManager:isActive()
    return self._active ~= nil
end

function HarvestManager:update(dt, ptx, pty, nodeManager, inventory)
    if not self._active then return end

    local a    = self._active
    local node = a.node

    -- Cancel if node was depleted by someone else or player wandered off
    if not node:isReady() then
        self._active = nil
        return
    end

    local dx = node.tx - ptx
    local dy = node.ty - pty
    if math.sqrt(dx*dx + dy*dy) > INTERACT_RADIUS + 0.5 then
        self._active = nil
        return
    end

    a.progress = a.progress + dt
    if a.progress >= a.duration then
        -- Harvest complete
        local amount = node:roll()
        if nodeManager and nodeManager.deplete then
            nodeManager:deplete(node)
        else
            node:deplete()
        end

        if inventory then
            inventory:add(node.resourceType, amount)
        end

        if self.eventBus then
            self.eventBus:publish("resource_collected", node.resourceType, amount)
        end

        self._active = nil
    end
end

-- Draw the progress bar above the active node.
-- Camera transform must already be applied.
function HarvestManager:draw()
    if not self._active then return end

    local a    = self._active
    local pct  = a.progress / a.duration
    local sx, sy = Iso.tileToScreen(a.node.tx, a.node.ty)
    local bx   = sx - BAR_W * 0.5
    local by   = sy - 24

    -- Background
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", bx, by, BAR_W, BAR_H)

    -- Fill
    love.graphics.setColor(0.2, 0.9, 0.2, 1)
    love.graphics.rectangle("fill", bx, by, BAR_W * pct, BAR_H)

    -- Border
    love.graphics.setColor(1, 1, 1, 0.6)
    love.graphics.rectangle("line", bx, by, BAR_W, BAR_H)
end

-- Draw a highlight ring around the nearest harvestable node (only if visible).
function HarvestManager:drawHint(ptx, pty, nodeManager, fog)
    local node = self:nearestNode(ptx, pty, nodeManager)
    if not node then return end
    if fog and not fog:isVisible(node.tx, node.ty) then return end

    local sx, sy = Iso.tileToScreen(node.tx, node.ty)
    love.graphics.setColor(1, 1, 0.3, 0.6 + 0.4 * math.sin(love.timer.getTime() * 4))
    love.graphics.circle("line", sx, sy - 4, 12)
end

HarvestManager.INTERACT_RADIUS = INTERACT_RADIUS

return HarvestManager
