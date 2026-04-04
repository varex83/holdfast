--- Phase Manager
-- Manages the day/night cycle and phase transitions

local Class = require("lib.class")
local PhaseManager = Class:extend()

-- Phase constants
PhaseManager.PHASE = {
    DAY = "day",
    NIGHT = "night"
}

function PhaseManager:new(config)
    self.config = config or {}

    -- Current phase state
    self.currentPhase = PhaseManager.PHASE.DAY
    self.dayNumber = 0
    self.timeRemaining = self.config.dayLength or 600  -- 10 minutes default

    -- Phase durations (can be overridden by config)
    self.dayLength = self.config.dayLength or 600
    self.nightLength = self.config.nightLength or 300
end

--- Transition to a new phase
-- @param newPhase Phase constant (PHASE.DAY or PHASE.NIGHT)
function PhaseManager:transition(newPhase)
    if newPhase == PhaseManager.PHASE.DAY then
        self.currentPhase = PhaseManager.PHASE.DAY
        self.dayNumber = self.dayNumber + 1
        self.timeRemaining = self.dayLength
    elseif newPhase == PhaseManager.PHASE.NIGHT then
        self.currentPhase = PhaseManager.PHASE.NIGHT
        self.timeRemaining = self.nightLength
    end
end

--- Update phase timer
-- @param dt Delta time in seconds
-- @return boolean True if phase should transition
function PhaseManager:update(dt)
    self.timeRemaining = self.timeRemaining - dt

    if self.timeRemaining <= 0 then
        return true  -- Signal phase transition needed
    end

    return false
end

--- Get current phase
-- @return string Current phase (PHASE.DAY or PHASE.NIGHT)
function PhaseManager:getCurrentPhase()
    return self.currentPhase
end

--- Get day number
-- @return number Current day number
function PhaseManager:getDayNumber()
    return self.dayNumber
end

--- Get time remaining in current phase
-- @return number Seconds remaining
function PhaseManager:getTimeRemaining()
    return self.timeRemaining
end

--- Get formatted time string
-- @return string Time formatted as MM:SS
function PhaseManager:getTimeString()
    local minutes = math.floor(self.timeRemaining / 60)
    local seconds = math.floor(self.timeRemaining % 60)
    return string.format("%02d:%02d", minutes, seconds)
end

--- Check if currently day
-- @return boolean True if day phase
function PhaseManager:isDay()
    return self.currentPhase == PhaseManager.PHASE.DAY
end

--- Check if currently night
-- @return boolean True if night phase
function PhaseManager:isNight()
    return self.currentPhase == PhaseManager.PHASE.NIGHT
end

--- Reset to day 1
function PhaseManager:reset()
    self.currentPhase = PhaseManager.PHASE.DAY
    self.dayNumber = 0
    self.timeRemaining = self.dayLength
end

--- Set phase (for testing/debugging)
-- @param phase Phase to set
-- @param dayNum Optional day number to set
function PhaseManager:setPhase(phase, dayNum)
    self.currentPhase = phase
    if dayNum then
        self.dayNumber = dayNum
    end

    if phase == PhaseManager.PHASE.DAY then
        self.timeRemaining = self.dayLength
    else
        self.timeRemaining = self.nightLength
    end
end

return PhaseManager
