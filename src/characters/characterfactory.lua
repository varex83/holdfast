--- Character Factory
-- Creates character instances with class-specific abilities and stats
-- Eliminates duplicate code across warrior/archer/engineer/scout files

local Character = require("src.characters.character")
local Classes = require("data.classes")
local Cooldown = require("src.combat.cooldown")

local CharacterFactory = {}

-- Map ability IDs to their module paths
local ABILITY_MODULES = {
    shield_bash = "src.characters.abilities.shieldbash",
    volley = "src.characters.abilities.volley",
    cloak = "src.characters.abilities.cloak",
    -- construct = "src.characters.abilities.construct",  -- TODO: Implement construct ability
}

--- Create a character of the specified class
-- @param classType Class type constant (e.g., Constants.CLASS.WARRIOR)
-- @param x Initial x position
-- @param y Initial y position
-- @return Character instance with abilities and stats configured
function CharacterFactory.create(classType, x, y)
    -- Get class definition
    local classDef = Classes.get(classType)
    if not classDef then
        error("Unknown class type: " .. tostring(classType))
    end

    -- Create base character with visuals
    local character = Character.new(classType, x, y, classDef.visuals)

    -- Create cooldown manager
    character.cooldowns = Cooldown.new()
    character.canBuild = classDef.permissions and classDef.permissions.canBuild or false

    -- Load and register class ability if it has one
    local abilityDef = classDef.ability
    if abilityDef and abilityDef.id then
        local abilityModulePath = ABILITY_MODULES[abilityDef.id]

        if abilityModulePath then
            -- Dynamically load the ability module
            local success, abilityModule = pcall(require, abilityModulePath)

            if success and abilityModule then
                character.cooldowns:registerAbility(abilityModule.id, abilityModule)
                character.classAbility = abilityModule
            else
                print("Warning: Failed to load ability module: " .. abilityModulePath .. " (" .. tostring(abilityModule) .. ")")
            end
        else
            print("Warning: No ability module mapped for: " .. abilityDef.id)
        end
    end

    return character
end

--- Create a character with custom visuals (for world rendering)
-- @param classType Class type constant
-- @param x Initial x position
-- @param y Initial y position
-- @param customVisuals Custom visual configuration (appearance, tint, etc.)
-- @return Character instance
function CharacterFactory.createWithVisuals(classType, x, y, customVisuals)
    local character = CharacterFactory.create(classType, x, y)

    -- Override visuals if provided
    if customVisuals then
        -- This would require Character to support visual updates
        -- For now, we just note this feature for future implementation
        -- character:setVisuals(customVisuals)
    end

    return character
end

return CharacterFactory
