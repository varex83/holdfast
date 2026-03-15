-- Building Definitions
-- Each entry: hp, cost table, blocksMovement, color, and type-specific fields.

return {
    wall = {
        name            = "Wooden Wall",
        hp              = 100,
        cost            = { wood = 3 },
        blocksMovement  = true,
        color           = { 0.55, 0.35, 0.15 },
    },
    gate = {
        name            = "Gate",
        hp              = 80,
        cost            = { wood = 5 },
        blocksMovement  = false,
        color           = { 0.40, 0.24, 0.08 },
    },
    campfire = {
        name            = "Campfire",
        hp              = 50,
        cost            = { wood = 2 },
        blocksMovement  = false,
        color           = { 1.00, 0.50, 0.10 },
        regenRadius     = 3,
    },
    basecore = {
        name            = "Base Core",
        hp              = 500,
        cost            = {},        -- placed free at game start
        blocksMovement  = true,
        color           = { 0.80, 0.80, 0.20 },
    },
}
