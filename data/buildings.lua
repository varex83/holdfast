-- Building Definitions
-- Each entry: hp, cost table, blocksMovement, color, and type-specific fields.

return {
    wall = {
        name            = "Wooden Wall",
        hp              = 100,
        cost            = { wood = 3 },
        blocksMovement  = true,
        color           = { 0.55, 0.35, 0.15 },
        sprite          = {
            asset = "buildings.wall.segment",
            scale = 1.0,
            anchorY = 30,
            oy = 2,
        },
    },
    gate = {
        name            = "Gate",
        hp              = 80,
        cost            = { wood = 5 },
        blocksMovement  = false,
        color           = { 0.40, 0.24, 0.08 },
        sprite          = {
            asset = "buildings.gate.citywall",
            scale = 0.9,
            anchorY = 96,
            oy = 4,
        },
    },
    campfire = {
        name            = "Campfire",
        hp              = 50,
        cost            = { wood = 2 },
        blocksMovement  = false,
        color           = { 1.00, 0.50, 0.10 },
        regenRadius     = 3,
        sprite          = {
            asset = "props.campfire",
            scale = 1.0,
            anchorY = 26,
            oy = 3,
        },
    },
    basecore = {
        name            = "Base Core",
        hp              = 500,
        cost            = {},        -- placed free at game start
        blocksMovement  = true,
        color           = { 0.80, 0.80, 0.20 },
        sprite          = {
            asset = "buildings.basecore.house_hay_1",
            scale = 0.85,
            anchorY = 91,
            oy = 4,
        },
    },
}
