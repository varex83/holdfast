-- Draw Order System
-- Collects drawables each frame, sorts by layer then isometric Y depth,
-- then flushes them in back-to-front order (painter's algorithm).
--
-- Usage per frame:
--   drawOrder:add(drawFn, screenY, layer)   -- register a drawable
--   drawOrder:flush()                        -- sort + draw + clear

local Class = require("lib.class")
local DrawOrder = Class:extend()

-- Layer constants mirror data/constants.lua LAYER_* values.
-- Import from constants if preferred; duplicated here so this module is
-- self-contained and usable before the game singleton exists.
DrawOrder.LAYER_GROUND         = 1
DrawOrder.LAYER_FLOOR          = 2
DrawOrder.LAYER_STRUCTURE_BASE = 3
DrawOrder.LAYER_RESOURCE       = 4
DrawOrder.LAYER_ITEM           = 5
DrawOrder.LAYER_CHARACTER      = 6
DrawOrder.LAYER_STRUCTURE_TOP  = 7
DrawOrder.LAYER_PROJECTILE     = 8
DrawOrder.LAYER_FX             = 9
DrawOrder.LAYER_UI             = 10

function DrawOrder:new()
    self._list = {}
end

-- Register a drawable for this frame.
-- `drawFn`  : function() ... end  (performs the actual love.graphics calls)
-- `screenY` : world/screen Y used for depth sorting within the same layer
-- `layer`   : integer layer constant (default LAYER_CHARACTER)
function DrawOrder:add(drawFn, screenY, layer)
    self._list[#self._list + 1] = {
        fn     = drawFn,
        y      = screenY or 0,
        layer  = layer or DrawOrder.LAYER_CHARACTER,
    }
end

-- Sort and draw all registered drawables, then clear the list.
function DrawOrder:flush()
    table.sort(self._list, function(a, b)
        if a.layer ~= b.layer then
            return a.layer < b.layer
        end
        return a.y < b.y
    end)

    for _, entry in ipairs(self._list) do
        entry.fn()
    end

    self._list = {}
end

-- Discard all pending drawables without drawing (e.g. on state change).
function DrawOrder:clear()
    self._list = {}
end

return DrawOrder
