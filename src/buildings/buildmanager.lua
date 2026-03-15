-- Build Manager
-- Tracks all placed buildings; handles placement, removal, and drawing.

local Class     = require("lib.class")
local Building  = require("src.buildings.building")
local Buildings = require("data.buildings")

local BuildManager = Class:extend()

function BuildManager:new(eventBus)
    self.eventBus   = eventBus
    self._buildings = {}   -- ordered list
    self._grid      = {}   -- "tx,ty" -> Building
end

-- в”Ђв”Ђв”Ђ Helpers в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ

local function key(tx, ty)
    return tx .. "," .. ty
end

function BuildManager:isOccupied(tx, ty)
    return self._grid[key(tx, ty)] ~= nil
end

function BuildManager:getAt(tx, ty)
    return self._grid[key(tx, ty)]
end

-- в”Ђв”Ђв”Ђ Cost helpers в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ

function BuildManager:canAfford(btype, depot, inventory)
    local def = Buildings[btype]
    if not def then return false end
    for rtype, amt in pairs(def.cost) do
        local depotCount = depot and depot:count(rtype) or 0
        local invCount = inventory and inventory:count(rtype) or 0
        if depotCount + invCount < amt then return false end
    end
    return true
end

local function deductCost(def, depot, inventory)
    for rtype, amt in pairs(def.cost) do
        local remaining = amt
        if depot and remaining > 0 then
            local fromDepot = math.min(remaining, depot:count(rtype))
            if fromDepot > 0 then
                depot:remove(rtype, fromDepot)
                remaining = remaining - fromDepot
            end
        end
        if inventory and remaining > 0 then
            inventory:remove(rtype, remaining)
        end
    end
end

-- в”Ђв”Ђв”Ђ Placement в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ

-- Place a building at (tx, ty). Deducts cost from depot.
-- Returns true on success.
function BuildManager:place(btype, tx, ty, depot, inventory)
    if self:isOccupied(tx, ty) then return false end
    if not self:canAfford(btype, depot, inventory) then return false end

    local def = Buildings[btype]
    deductCost(def, depot, inventory)

    local b = Building(btype, tx, ty)
    self._buildings[#self._buildings + 1] = b
    self._grid[key(tx, ty)] = b

    if self.eventBus then
        self.eventBus:publish("building_placed", btype, tx, ty)
    end
    return true
end

-- Place without cost (e.g. Base Core at game start).
function BuildManager:placeFree(btype, tx, ty)
    if self:isOccupied(tx, ty) then return false end
    local b = Building(btype, tx, ty)
    self._buildings[#self._buildings + 1] = b
    self._grid[key(tx, ty)] = b
    return true
end

function BuildManager:remove(tx, ty)
    local b = self._grid[key(tx, ty)]
    if not b then return false end
    self._grid[key(tx, ty)] = nil
    for i, v in ipairs(self._buildings) do
        if v == b then table.remove(self._buildings, i); break end
    end
    return true
end

-- в”Ђв”Ђв”Ђ Query в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ

function BuildManager:getAll()
    return self._buildings
end

-- Returns the Base Core building, or nil.
function BuildManager:getBaseCore()
    for _, b in ipairs(self._buildings) do
        if b.btype == "basecore" then return b end
    end
end

-- в”Ђв”Ђв”Ђ Draw в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ

-- Draw all buildings visible through fog, sorted by screen Y.
function BuildManager:draw(fog)
    -- Collect visible buildings
    local visible = {}
    for _, b in ipairs(self._buildings) do
        local state = fog and fog:getState(b.tx, b.ty) or "visible"
        if state ~= "hidden" then
            visible[#visible + 1] = b
        end
    end

    -- Sort back-to-front
    table.sort(visible, function(a, b) return a:screenY() < b:screenY() end)

    for _, b in ipairs(visible) do
        b:draw()
    end
end

return BuildManager
