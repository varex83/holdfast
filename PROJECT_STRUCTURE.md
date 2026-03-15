# Holdfast - Project Structure

```
holdfast/
│
├── main.lua                          # Love2D entry point
├── conf.lua                          # Love2D configuration
├── CLAUDE.md                         # Project documentation
├── PROJECT_STRUCTURE.md              # This file
├── IMPLEMENTATION_PLAN.md            # Development roadmap
├── .gitignore                        # Git ignore file
│
├── src/                              # Source code
│   ├── core/                         # Core engine systems
│   │   ├── game.lua                  # Main game state manager
│   │   ├── statemachine.lua          # State machine (menu, day, night, gameover)
│   │   ├── camera.lua                # Camera system with smooth follow
│   │   ├── input.lua                 # Input handling and mapping
│   │   ├── time.lua                  # Delta time and day/night cycle
│   │   └── eventbus.lua              # Event system for decoupled communication
│   │
│   ├── ecs/                          # Entity Component System
│   │   ├── entity.lua                # Entity base class
│   │   ├── component.lua             # Component manager
│   │   ├── system.lua                # System base class
│   │   └── components/               # Individual components
│   │       ├── position.lua
│   │       ├── velocity.lua
│   │       ├── health.lua
│   │       ├── sprite.lua
│   │       ├── collider.lua
│   │       ├── inventory.lua
│   │       └── stats.lua
│   │
│   ├── world/                        # World generation and management
│   │   ├── worldgen.lua              # Perlin noise world generator
│   │   ├── chunk.lua                 # Chunk loading/unloading
│   │   ├── tile.lua                  # Tile data and types
│   │   ├── biome.lua                 # Biome definitions
│   │   └── fogofwar.lua              # Fog of war system
│   │
│   ├── rendering/                    # Rendering systems
│   │   ├── renderer.lua              # Master renderer
│   │   ├── isometric.lua             # Isometric coordinate conversion
│   │   ├── draworder.lua             # Painter's algorithm depth sort
│   │   ├── spritebatch.lua           # Sprite batching optimization
│   │   └── lighting.lua              # Lighting system (torchlight, etc.)
│   │
│   ├── characters/                   # Player character classes
│   │   ├── character.lua             # Base character class
│   │   ├── warrior.lua               # Warrior class
│   │   ├── archer.lua                # Archer class
│   │   ├── engineer.lua              # Engineer class
│   │   ├── scout.lua                 # Scout class
│   │   └── abilities/                # Character abilities
│   │       ├── shieldbash.lua
│   │       ├── volley.lua
│   │       ├── construct.lua
│   │       └── cloak.lua
│   │
│   ├── combat/                       # Combat systems
│   │   ├── combatmanager.lua         # Combat coordination
│   │   ├── hitbox.lua                # Hitbox/hurtbox system
│   │   ├── damage.lua                # Damage calculation
│   │   ├── projectile.lua            # Projectile system (arrows, spit)
│   │   └── cooldown.lua              # Ability cooldown system
│   │
│   ├── ai/                           # AI and pathfinding
│   │   ├── pathfinding.lua           # A* pathfinding
│   │   ├── steering.lua              # Steering behaviors (seek, separate)
│   │   ├── aicontroller.lua          # AI decision making
│   │   └── behaviors/                # Specific AI behaviors
│   │       ├── seek.lua
│   │       ├── separate.lua
│   │       ├── flank.lua
│   │       └── attackstructure.lua
│   │
│   ├── enemies/                      # Enemy types
│   │   ├── enemy.lua                 # Base enemy class
│   │   ├── flyswarm.lua
│   │   ├── shambler.lua
│   │   ├── hound.lua
│   │   ├── brute.lua
│   │   ├── spitter.lua
│   │   ├── wraith.lua
│   │   └── siegebeast.lua
│   │
│   ├── waves/                        # Wave spawning system
│   │   ├── wavemanager.lua           # Wave coordination
│   │   ├── spawner.lua               # Monster spawning logic
│   │   ├── difficulty.lua            # Difficulty scaling
│   │   └── waveconfig.lua            # Wave composition tables
│   │
│   ├── resources/                    # Resource system
│   │   ├── resourcenode.lua          # Resource node (trees, rocks, etc.)
│   │   ├── resourcetype.lua          # Resource type definitions
│   │   ├── harvesting.lua            # Resource harvesting logic
│   │   └── respawn.lua               # Resource respawn system
│   │
│   ├── inventory/                    # Inventory system
│   │   ├── inventory.lua             # Player inventory
│   │   ├── supplydepot.lua           # Shared resource storage
│   │   └── carrycapacity.lua         # Weight/capacity calculations
│   │
│   ├── buildings/                    # Base building system
│   │   ├── buildmanager.lua          # Building placement/upgrade
│   │   ├── structure.lua             # Base structure class
│   │   ├── buildghost.lua            # Ghost preview system
│   │   ├── upgrade.lua               # Upgrade system
│   │   ├── repair.lua                # Repair system
│   │   └── types/                    # Building types
│   │       ├── defensive/
│   │       │   ├── wall.lua
│   │       │   ├── arrowtower.lua
│   │       │   ├── trap.lua
│   │       │   ├── gate.lua
│   │       │   └── moat.lua
│   │       ├── utility/
│   │       │   ├── supplydepot.lua
│   │       │   ├── campfire.lua
│   │       │   ├── forge.lua
│   │       │   ├── watchtower.lua
│   │       │   └── workshop.lua
│   │       └── basecore.lua
│   │
│   ├── ui/                           # User interface
│   │   ├── uimanager.lua             # UI coordination
│   │   ├── hud.lua                   # HUD (health, resources, timer)
│   │   ├── menu.lua                  # Main menu
│   │   ├── classselect.lua           # Class selection screen
│   │   ├── buildmenu.lua             # Building menu (Engineer)
│   │   ├── tooltip.lua               # Tooltip system
│   │   └── debug.lua                 # Debug overlay (F1)
│   │
│   ├── persistence/                  # Save/load system
│   │   ├── savemanager.lua           # Save coordination
│   │   ├── serializer.lua            # Lua table serialization
│   │   ├── chunksave.lua             # Chunk data saving
│   │   └── worldstate.lua            # World state persistence
│   │
│   ├── networking/                   # Multiplayer (future)
│   │   ├── server.lua                # Server authority
│   │   ├── client.lua                # Client input handling
│   │   ├── protocol.lua              # Network protocol
│   │   └── sync.lua                  # State synchronization
│   │
│   └── utils/                        # Utility functions
│       ├── math.lua                  # Math helpers (lerp, clamp, etc.)
│       ├── table.lua                 # Table utilities
│       ├── collision.lua             # AABB collision helpers
│       ├── noise.lua                 # Perlin noise implementation
│       └── timer.lua                 # Timer utilities
│
├── data/                             # Game data and configuration
│   ├── config.lua                    # Game configuration (day length, etc.)
│   ├── constants.lua                 # Game constants
│   ├── classes.lua                   # Class stat definitions
│   ├── resources.lua                 # Resource definitions
│   ├── buildings.lua                 # Building definitions
│   ├── enemies.lua                   # Enemy stat definitions
│   └── waves.lua                     # Wave composition data
│
├── assets/                           # Game assets
│   ├── sprites/                      # Sprite images
│   │   ├── characters/
│   │   ├── enemies/
│   │   ├── buildings/
│   │   ├── resources/
│   │   ├── tiles/
│   │   └── ui/
│   ├── sounds/                       # Sound effects
│   ├── music/                        # Background music
│   └── fonts/                        # Fonts
│
├── lib/                              # External libraries
│   ├── json.lua                      # JSON serialization
│   ├── enet.lua                      # Networking (future)
│   └── class.lua                     # Class implementation helper
│
├── saves/                            # Save files (generated)
│   └── .gitkeep
│
└── tests/                            # Unit tests (optional)
    ├── test_pathfinding.lua
    ├── test_worldgen.lua
    └── test_inventory.lua
```

## Module Responsibilities

### Core Systems
- **game.lua**: Master game state, coordinates all subsystems
- **statemachine.lua**: Manages menu → day → night → gameover transitions
- **camera.lua**: Smooth camera follow, zoom, screen shake
- **input.lua**: Keyboard/mouse/gamepad mapping
- **time.lua**: Delta time, day/night timer, time scaling

### ECS (Entity Component System)
- **entity.lua**: Entity creation, component attachment
- **component.lua**: Component registration and management
- **system.lua**: System update loop base class

### World
- **worldgen.lua**: Procedural generation using Perlin noise
- **chunk.lua**: 16x16 tile chunks, load/unload based on player position
- **tile.lua**: Tile type registry, walkability, resource nodes
- **biome.lua**: Forest, plains, caves, etc.

### Rendering
- **isometric.lua**: World ↔ screen coordinate conversion (64x32 tiles)
- **draworder.lua**: Y-sorting for painter's algorithm
- **spritebatch.lua**: Batch rendering for performance

### Combat & AI
- **hitbox.lua**: AABB collision for attacks
- **pathfinding.lua**: A* on tile grid
- **steering.lua**: Seek, separate, flocking behaviors
- **aicontroller.lua**: Enemy decision tree

### Buildings
- **buildmanager.lua**: Placement grid snapping, cost validation
- **upgrade.lua**: Tier 1 → 2 → 3 upgrades
- **repair.lua**: Engineer repair mechanics

### Waves
- **wavemanager.lua**: Night timer, spawn coordination
- **difficulty.lua**: Night number → monster composition + stats

### Persistence
- **savemanager.lua**: JSON serialization of world state
- **chunksave.lua**: Save/load individual chunks on demand

## File Naming Conventions

- **PascalCase** for classes: `Character`, `Warrior`, `WaveManager`
- **camelCase** for modules: `pathfinding.lua`, `worldgen.lua`
- **lowercase** for data files: `config.lua`, `enemies.lua`

## Love2D Entry Points

### main.lua
```lua
function love.load()
  -- Initialize game
end

function love.update(dt)
  -- Update game state
end

function love.draw()
  -- Render game
end
```

### conf.lua
```lua
function love.conf(t)
  t.window.width = 1280
  t.window.height = 720
  t.window.title = "Holdfast"
  t.version = "11.5"
end
```

## Dependencies

Required Lua libraries:
- **json.lua**: For save/load serialization
- **class.lua**: OOP helper (middleclass or similar)
- **enet** (future): Multiplayer networking

## Development Guidelines

1. Each module should be self-contained and testable
2. Use the eventbus for cross-system communication
3. Keep data files separate from logic
4. Use constants instead of magic numbers
5. All positions stored in world coordinates, converted to screen for rendering
6. Batch all sprite draws per frame for performance
7. Chunk loading must be async to prevent frame drops
