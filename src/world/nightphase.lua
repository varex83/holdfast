--- Night Phase
-- Handles night-specific gameplay logic: waves, combat, enemy spawning

local Class = require("lib.class")

local NightPhase = Class:extend()

function NightPhase:new(eventBus)
    self.eventBus = eventBus

    -- Night-specific state
    self.waveManager = nil  -- TODO: Implement wave system
    self.enemySpawner = nil  -- TODO: Implement enemy spawning
end

--- Enter night phase
-- @param worldState The world state context
function NightPhase:enter(worldState)
    print("Entering Night Phase")

    -- TODO: Initialize wave manager
    -- TODO: Start enemy spawning

    -- Publish night start event
    self.eventBus:publish("night_start", worldState.phaseManager:getDayNumber())
end

--- Exit night phase
-- @param worldState The world state context
function NightPhase:exit(worldState)
    print("Exiting Night Phase")

    -- TODO: Clean up wave state
    -- TODO: Remove remaining enemies
end

--- Update night-specific logic
-- @param dt Delta time
-- @param worldState The world state context
function NightPhase:update(dt, worldState)
    -- TODO: Update wave manager
    -- TODO: Update enemy spawning
    -- TODO: Check win condition (all enemies defeated)

    -- For now, just update ECS world (which will handle any combat entities)
    -- The worldState.world update is handled in WorldState:update()
end

--- Draw night-specific UI/elements
-- @param worldState The world state context
function NightPhase:draw(worldState)
    -- Draw night-specific UI
    love.graphics.setColor(1, 0.3, 0.3, 1)

    local font = love.graphics.getFont()
    love.graphics.print("WAVE ACTIVE", 20, 80)

    love.graphics.setColor(1, 1, 1, 1)
end

--- Handle night-specific input
-- @param key The key pressed
-- @param worldState The world state context
function NightPhase:keypressed(key, worldState)
    -- Space - skip to day (debug)
    if key == "space" then
        return "transition_day"  -- Signal to transition
    end
end

--- Queue night-specific entity draws
-- @param entityDrawList The list to add draw calls to
-- @param worldState The world state context
function NightPhase:queueEntityDraws(entityDrawList, worldState)
    -- TODO: Queue enemy draws
    -- TODO: Queue wave indicators
    -- TODO: Queue combat effects

    -- For now, buildings still draw at night
    local Iso = require("src.rendering.isometric")

    if worldState.dayPhase and worldState.dayPhase.buildManager and worldState.fog then
        for _, building in ipairs(worldState.dayPhase.buildManager:getAll()) do
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

--- Get background color for night
-- @return table Color {r, g, b, a}
function NightPhase:getBackgroundColor()
    return {0.1, 0.1, 0.2, 1}  -- Dark blue for night
end

return NightPhase
