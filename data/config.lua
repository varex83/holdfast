-- Game Configuration
-- Tweakable game settings

return {
    -- Day/Night Cycle
    dayLength = 600,           -- 10 minutes (600 seconds)
    nightLength = 300,         -- 5 minutes (300 seconds)
    dawnDuration = 5,          -- Transition time in seconds
    duskDuration = 5,          -- Transition time in seconds

    -- World Generation
    chunkSize = 16,            -- Tiles per chunk (16x16)
    tileSize = 64,             -- Tile width in pixels (isometric)
    tileHeight = 32,           -- Tile height in pixels (isometric)
    worldSeed = nil,           -- nil = random seed each game
    chunkLoadRadius = 2,       -- Load chunks within this radius of player
    chunkUnloadRadius = 3,     -- Unload chunks beyond this radius

    -- Resource System
    resourceRespawnDistance = 100,  -- Tiles from base before respawn
    resourceRespawnTime = 300,      -- 5 minutes base respawn time
    baseResourceDensity = 0.15,     -- 15% of tiles have resources

    -- Player Settings
    playerSpeed = 150,         -- Base movement speed (pixels/sec)
    playerVisionRadius = 10,   -- Tiles visible around player

    -- Combat
    attackRange = 50,          -- Melee attack range in pixels
    arrowSpeed = 300,          -- Projectile speed
    globalCooldown = 0.5,      -- Seconds between actions

    -- Building
    buildGridSize = 64,        -- Grid snap size for building placement
    buildRangeFromCore = 50,   -- Max tiles from base core

    -- Wave System
    firstNightNumber = 1,      -- Which night first wave occurs
    waveScalingInterval = 5,   -- +5% stats every N nights
    bossInterval = 10,         -- Boss appears every N nights

    -- Debug
    debugMode = false,         -- Enable debug features
    godMode = false,           -- Player invulnerability
    showColliders = false,     -- Draw collision boxes
    unlimitedResources = false -- Infinite resources
}
