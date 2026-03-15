-- Resource Type Definitions
-- Each entry describes one gatherable resource.

return {
    wood = {
        name         = "Wood",
        weight       = 2,           -- carry-weight units per item
        color        = {0.55, 0.35, 0.15},  -- placeholder render colour
        harvestTime  = 3.0,         -- seconds to harvest one batch
        yieldMin     = 2,           -- min items per harvest
        yieldMax     = 4,
        sourceTiles  = {"tree"},    -- tile types this spawns on
        biomes       = {"forest", "plains"},
    },

    iron = {
        name         = "Iron",
        weight       = 5,
        color        = {0.60, 0.60, 0.65},
        harvestTime  = 5.0,
        yieldMin     = 1,
        yieldMax     = 2,
        sourceTiles  = {"rock"},
        biomes       = {"caves", "plains"},
    },

    stone = {
        name         = "Stone",
        weight       = 4,
        color        = {0.50, 0.50, 0.50},
        harvestTime  = 4.0,
        yieldMin     = 2,
        yieldMax     = 3,
        sourceTiles  = {"rock", "grass", "dirt"},
        biomes       = {"plains", "caves"},
    },

    rope = {
        name         = "Rope",
        weight       = 1,
        color        = {0.75, 0.70, 0.40},
        harvestTime  = 2.0,
        yieldMin     = 1,
        yieldMax     = 3,
        sourceTiles  = {"grass", "sand"},
        biomes       = {"plains", "desert"},
    },

    food = {
        name         = "Food",
        weight       = 1,
        color        = {0.90, 0.30, 0.30},
        harvestTime  = 1.5,
        yieldMin     = 1,
        yieldMax     = 2,
        sourceTiles  = {"grass", "dirt"},
        biomes       = {"plains", "forest"},
    },

    cloth = {
        name         = "Cloth",
        weight       = 1,
        color        = {0.85, 0.85, 0.90},
        harvestTime  = 2.5,
        yieldMin     = 1,
        yieldMax     = 2,
        sourceTiles  = {"grass"},
        biomes       = {"plains"},
    },
}
