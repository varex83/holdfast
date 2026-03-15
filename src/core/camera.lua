-- Camera System
-- Smooth lerp follow, zoom controls, screen-space transforms

local Class = require("lib.class")
local Camera = Class:extend()

local LERP_SPEED = 5.0
local ZOOM_MIN   = 0.25
local ZOOM_MAX   = 4.0

function Camera:new(screenW, screenH)
    self.x      = 0
    self.y      = 0
    self.zoom   = 1.0
    self.screenW = screenW or love.graphics.getWidth()
    self.screenH = screenH or love.graphics.getHeight()

    -- Target the camera lerps toward
    self._targetX = 0
    self._targetY = 0
end

-- Immediately snap to a world position
function Camera:moveTo(x, y)
    self.x        = x
    self.y        = y
    self._targetX = x
    self._targetY = y
end

-- Set target for smooth follow; call each frame
function Camera:follow(x, y)
    self._targetX = x
    self._targetY = y
end

function Camera:update(dt)
    local t = math.min(LERP_SPEED * dt, 1)
    self.x = self.x + (self._targetX - self.x) * t
    self.y = self.y + (self._targetY - self.y) * t
end

-- Zoom by a delta (positive = zoom in)
function Camera:adjustZoom(delta)
    self.zoom = math.max(ZOOM_MIN, math.min(ZOOM_MAX, self.zoom + delta))
end

function Camera:setZoom(z)
    self.zoom = math.max(ZOOM_MIN, math.min(ZOOM_MAX, z))
end

-- Push Love2D transform for world drawing; call before drawing world objects
function Camera:apply()
    love.graphics.push()
    love.graphics.translate(self.screenW * 0.5, self.screenH * 0.5)
    love.graphics.scale(self.zoom, self.zoom)
    love.graphics.translate(-self.x, -self.y)
end

-- Pop the transform; call after drawing world objects
function Camera:clear()
    love.graphics.pop()
end

-- Convert world coords → screen pixel coords
function Camera:worldToScreen(wx, wy)
    local sx = (wx - self.x) * self.zoom + self.screenW * 0.5
    local sy = (wy - self.y) * self.zoom + self.screenH * 0.5
    return sx, sy
end

-- Convert screen pixel coords → world coords
function Camera:screenToWorld(sx, sy)
    local wx = (sx - self.screenW * 0.5) / self.zoom + self.x
    local wy = (sy - self.screenH * 0.5) / self.zoom + self.y
    return wx, wy
end

-- Axis-aligned rect visible in world space (useful for culling)
function Camera:getBounds()
    local hw = (self.screenW * 0.5) / self.zoom
    local hh = (self.screenH * 0.5) / self.zoom
    return self.x - hw, self.y - hh, self.x + hw, self.y + hh
end

return Camera
