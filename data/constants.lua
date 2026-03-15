-- Game Constants
-- Fixed values that should not be changed during gameplay

return {
    -- Game Info
    GAME_TITLE = "Holdfast",
    VERSION = "0.1.0-alpha",

    -- Screen
    SCREEN_WIDTH = 1280,
    SCREEN_HEIGHT = 720,

    -- States
    STATE_MENU = "menu",
    STATE_DAY = "day",
    STATE_NIGHT = "night",
    STATE_GAMEOVER = "gameover",

    -- Layers (for rendering depth sort)
    LAYER_GROUND = 1,
    LAYER_FLOOR = 2,
    LAYER_STRUCTURE_BASE = 3,
    LAYER_RESOURCE = 4,
    LAYER_ITEM = 5,
    LAYER_CHARACTER = 6,
    LAYER_STRUCTURE_TOP = 7,
    LAYER_PROJECTILE = 8,
    LAYER_FX = 9,
    LAYER_UI = 10,

    -- Resource Types
    RESOURCE_WOOD = "wood",
    RESOURCE_IRON = "iron",
    RESOURCE_ROPE = "rope",
    RESOURCE_STONE = "stone",
    RESOURCE_FOOD = "food",
    RESOURCE_CLOTH = "cloth",

    -- Character Classes
    CLASS_WARRIOR = "warrior",
    CLASS_ARCHER = "archer",
    CLASS_ENGINEER = "engineer",
    CLASS_SCOUT = "scout",

    -- Character Classes (nested for convenience)
    CLASS = {
        WARRIOR = "warrior",
        ARCHER = "archer",
        ENGINEER = "engineer",
        SCOUT = "scout",
    },

    -- Enemy Types
    ENEMY_FLYSWARM = "flyswarm",
    ENEMY_SHAMBLER = "shambler",
    ENEMY_HOUND = "hound",
    ENEMY_BRUTE = "brute",
    ENEMY_SPITTER = "spitter",
    ENEMY_WRAITH = "wraith",
    ENEMY_SIEGEBEAST = "siegebeast",

    -- Building Types
    BUILDING_WALL_WOOD = "wall_wood",
    BUILDING_WALL_STONE = "wall_stone",
    BUILDING_WALL_REINFORCED = "wall_reinforced",
    BUILDING_GATE = "gate",
    BUILDING_ARROW_TOWER = "arrow_tower",
    BUILDING_SPIKE_TRAP = "spike_trap",
    BUILDING_SUPPLY_DEPOT = "supply_depot",
    BUILDING_CAMPFIRE = "campfire",
    BUILDING_FORGE = "forge",
    BUILDING_WATCHTOWER = "watchtower",
    BUILDING_WORKSHOP = "workshop",
    BUILDING_BASE_CORE = "base_core",

    -- Tile Types
    TILE_GRASS = "grass",
    TILE_DIRT = "dirt",
    TILE_STONE = "stone",
    TILE_WATER = "water",
    TILE_SAND = "sand",
    TILE_TREE = "tree",
    TILE_ROCK = "rock",

    -- Biomes
    BIOME_PLAINS = "plains",
    BIOME_FOREST = "forest",
    BIOME_CAVES = "caves",
    BIOME_DESERT = "desert",

    -- Events
    EVENT_DAY_START = "day_start",
    EVENT_NIGHT_START = "night_start",
    EVENT_WAVE_START = "wave_start",
    EVENT_WAVE_END = "wave_end",
    EVENT_PLAYER_DEATH = "player_death",
    EVENT_PLAYER_RESPAWN = "player_respawn",
    EVENT_BASE_DESTROYED = "base_destroyed",
    EVENT_RESOURCE_COLLECTED = "resource_collected",
    EVENT_BUILDING_PLACED = "building_placed",
    EVENT_BUILDING_DESTROYED = "building_destroyed",
    EVENT_ENEMY_SPAWNED = "enemy_spawned",
    EVENT_ENEMY_KILLED = "enemy_killed",

    -- Events (nested for convenience)
    EVENTS = {
        DAY_START = "day_start",
        NIGHT_START = "night_start",
        WAVE_START = "wave_start",
        WAVE_END = "wave_end",
        PLAYER_DEATH = "player_death",
        PLAYER_RESPAWN = "player_respawn",
        PLAYER_ATTACK = "player_attack",
        PLAYER_ABILITY = "player_ability",
        BASE_DESTROYED = "base_destroyed",
        RESOURCE_COLLECTED = "resource_collected",
        BUILDING_PLACED = "building_placed",
        BUILDING_DESTROYED = "building_destroyed",
        ENEMY_SPAWNED = "enemy_spawned",
        ENEMY_KILLED = "enemy_killed",
        ENTITY_DAMAGED = "entity_damaged",
        ENTITY_HEALED = "entity_healed",
        ENTITY_DIED = "entity_died",
        ENTITY_RESPAWNED = "entity_respawned",
        PROJECTILE_HIT = "projectile_hit",
        PROJECTILE_EXPIRED = "projectile_expired",
    },

    -- Physics
    GRAVITY = 0,  -- Top-down game, no gravity

    -- Math
    PI = math.pi,
    TWO_PI = math.pi * 2,
    HALF_PI = math.pi / 2,
}
