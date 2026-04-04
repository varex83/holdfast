--- Day Phase
-- Handles day-specific gameplay logic: harvesting, building, exploration

local Class = require("lib.class")
local HarvestManager = require("src.resources.harvesting")
local BuildManager = require("src.buildings.buildmanager")
local BuildGhost = require("src.buildings.buildghost")
local SupplyDepot = require("src.inventory.supplydepot")

local DayPhase = Class:extend()

function DayPhase:new(eventBus)
    self.eventBus = eventBus

    -- Day-specific managers
    self.harvestManager = nil  -- Initialized in enter()
    self.buildManager = nil
    self.buildGhost = nil
    self.depot = nil
end

--- Enter day phase
-- @param worldState The world state context
function DayPhase:enter(worldState)
    print("Entering Day Phase")

    -- Initialize day-specific systems if not already created
    if not self.harvestManager then
        self.harvestManager = HarvestManager(self.eventBus)
    end

    if not self.buildManager then
        self.buildManager = BuildManager(self.eventBus)
        -- Place initial base core if first day
        if worldState.phaseManager:getDayNumber() == 1 then
            self.buildManager:placeFree("basecore", 0, 0)
        end
    end

    if not self.buildGhost then
        self.buildGhost = BuildGhost()
    end

    if not self.depot then
        self.depot = SupplyDepot(2, 2, self.eventBus)
        -- Initial resources for testing
        self.depot:add("wood", 20)
        self.depot:add("stone", 10)
    end

    -- Publish day start event
    self.eventBus:publish("day_start", worldState.phaseManager:getDayNumber())
end

--- Exit day phase
-- @param worldState The world state context
function DayPhase:exit(worldState)
    print("Exiting Day Phase")
    if self.buildGhost then
        self.buildGhost:deactivate()
    end

    if self.harvestManager then
        self.harvestManager:cancel()
    end
end

--- Update day-specific logic
-- @param dt Delta time
-- @param worldState The world state context
function DayPhase:update(dt, worldState)
    -- Update harvesting
    if self.harvestManager and worldState.player then
        self.harvestManager:update(
            dt,
            worldState.player.tx,
            worldState.player.ty,
            worldState.nodes,
            worldState.inventory
        )
    end
end

--- Draw day-specific UI/elements
-- @param worldState The world state context
function DayPhase:draw(worldState)
    -- World-space drawing is queued from WorldState while the camera is active.
    -- Keep this hook for screen-space day-only UI if needed.
end

--- Handle day-specific input
-- @param key The key pressed
-- @param worldState The world state context
function DayPhase:keypressed(key, worldState)
    if key == "f" or key == "square" or key == "leftshoulder" then
        if self.depot and worldState.player and worldState.inventory then
            if self.depot:isNearby(worldState.player.tx, worldState.player.ty) then
                self.depot:depositAll(worldState.inventory)
            end
        end
        return
    end

    if key == "b" or key == "rightshoulder" then
        if self.buildGhost then
            if self.buildGhost:isActive() then
                self.buildGhost:cycleType()
            else
                local tx, ty = worldState:_ghostTile()
                self.buildGhost:activate(tx, ty)
            end
        end
        return
    end

    if key == "r" or key == "a" then
        if self.buildGhost and self.buildGhost:isActive() and self.buildManager and self.depot then
            local tx, ty = worldState:_ghostTile()
            self.buildManager:place(self.buildGhost:currentType(), tx, ty, self.depot)
        end
        return
    end

    if key == "e" or key == "x" then
        if self.buildGhost and self.buildGhost:isActive() then
            return
        end

        if self.harvestManager and worldState.player and worldState.nodes and worldState.inventory then
            self.harvestManager:tryStart(
                worldState.player.tx,
                worldState.player.ty,
                worldState.nodes,
                worldState.inventory
            )
        end
        return
    end

    -- Space - skip to night (debug)
    if key == "space" then
        return "transition_night"  -- Signal to transition
    end
end

--- Queue day-specific entity draws
-- @param entityDrawList The list to add draw calls to
-- @param worldState The world state context
function DayPhase:queueEntityDraws(entityDrawList, worldState)
    local Iso = require("src.rendering.isometric")

    -- Queue depot draw
    if self.depot and worldState.fog then
        if worldState.fog:getState(self.depot.tx, self.depot.ty) ~= "hidden" then
            local _, depotSy = Iso.tileToScreen(self.depot.tx, self.depot.ty)
            table.insert(entityDrawList, {
                sy = depotSy,
                order = 40,
                draw = function()
                    self.depot:draw()
                    if self.depot:isNearby(worldState.player.tx, worldState.player.ty) then
                        self.depot:drawNearbyHint()
                    end
                end
            })
        end
    end

    -- Queue building draws
    if self.buildManager and worldState.fog then
        for _, building in ipairs(self.buildManager:getAll()) do
            if worldState.fog:getState(building.tx, building.ty) ~= "hidden" then
                table.insert(entityDrawList, {
                    sy = building:screenY(),
                    order = 20,
                    draw = function()
                        building:draw()
                    end
                })
            end
        end
    end
end

--- Get the harvest manager
-- @return HarvestManager
function DayPhase:getHarvestManager()
    return self.harvestManager
end

--- Get the build manager
-- @return BuildManager
function DayPhase:getBuildManager()
    return self.buildManager
end

--- Get the supply depot
-- @return SupplyDepot
function DayPhase:getDepot()
    return self.depot
end

return DayPhase
