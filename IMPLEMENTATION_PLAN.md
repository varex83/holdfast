# Holdfast - Implementation Plan
## 2 Developer Independent Work Strategy

This plan divides work into **Developer A** (World & Systems) and **Developer B** (Combat & Gameplay), with minimal cross-dependencies. Each phase includes independent tasks that can proceed in parallel.

---

## Development Phases

### Phase 0: Foundation (Week 1)
**Both developers work together on shared foundation**

#### Shared Tasks
- [ ] Set up project structure and Git repository
- [ ] Create `main.lua` and `conf.lua` with basic Love2D setup
- [ ] Implement basic state machine (menu, day, night states)
- [ ] Set up ECS foundation (entity, component, system base classes)
- [ ] Create event bus for cross-system communication
- [ ] Define shared data files (`data/config.lua`, `data/constants.lua`)
- [ ] Set up debug overlay system (F1 toggle)

#### Definition of Done
- Game launches with a basic menu
- Can transition between states
- Entities can be created with components
- Debug overlay shows FPS and basic stats

---

## Phase 1: Core Systems (Weeks 2-3)

### Developer A: World & Rendering

#### Week 2
- [ ] **Camera System** (`src/core/camera.lua`)
  - Smooth lerp follow
  - Zoom controls
  - Screen boundaries

- [ ] **Isometric Renderer** (`src/rendering/isometric.lua`)
  - World ↔ screen coordinate conversion
  - 64x32 tile rendering
  - Grid snapping utilities

- [ ] **Draw Order System** (`src/rendering/draworder.lua`)
  - Y-sorting for painter's algorithm
  - Sprite depth sorting
  - Layer management

- [ ] **Basic Tile System** (`src/world/tile.lua`)
  - Tile type definitions
  - Walkability flags
  - Placeholder sprites

#### Week 3
- [ ] **World Generation** (`src/world/worldgen.lua`)
  - Perlin noise implementation
  - Biome generation (forest, plains, caves)
  - Resource node placement

- [ ] **Chunk System** (`src/world/chunk.lua`)
  - 16x16 tile chunks
  - Load/unload based on distance
  - Chunk caching

- [ ] **Fog of War** (`src/world/fogofwar.lua`)
  - Tile-based visibility
  - Exploration tracking
  - Render fog overlay

- [ ] **Sprite Batching** (`src/rendering/spritebatch.lua`)
  - Batch tiles per frame
  - Optimization for large maps

#### Deliverables
- Infinite procedurally generated world
- Smooth camera following player placeholder
- Isometric rendering with proper depth sorting
- Fog of war reveals as player moves

---

### Developer B: Character & Combat

#### Week 2
- [ ] **Input System** (`src/core/input.lua`)
  - Keyboard/mouse mapping
  - Action binding system
  - Gamepad support (optional)

- [ ] **Character Controller** (`src/characters/character.lua`)
  - Movement state machine (idle, walking, attacking)
  - Keyboard movement (WASD)
  - Speed and velocity
  - Basic collision with world tiles

- [ ] **Character Stats System** (`src/ecs/components/stats.lua`)
  - HP, armor, speed, attack
  - Stat scaling by class

- [ ] **Health Component** (`src/ecs/components/health.lua`)
  - Take damage
  - Die/respawn
  - Health regeneration

#### Week 3
- [ ] **Hitbox/Hurtbox System** (`src/combat/hitbox.lua`)
  - AABB collision detection
  - Attack hitbox creation
  - Hit registration (once per swing)

- [ ] **Combat Manager** (`src/combat/combatmanager.lua`)
  - Damage calculation
  - Attack timing
  - Hit feedback

- [ ] **Cooldown System** (`src/combat/cooldown.lua`)
  - Ability cooldown tracking
  - Visual timer display
  - Global cooldown (GCD)

- [ ] **Projectile System** (`src/combat/projectile.lua`)
  - Arrow/spit projectile movement
  - Collision with entities
  - Projectile lifetime

#### Deliverables
- Player can move around world with keyboard
- Player can attack (melee or ranged placeholder)
- Damage system functional
- Hit detection working

---

## Phase 2: Gameplay Core (Weeks 4-6)

### Developer A: Resources & Building

#### Week 4
- [ ] **Resource Node System** (`src/resources/resourcenode.lua`)
  - Tree, rock, plant nodes
  - Harvest interaction (E key)
  - Yield amounts

- [ ] **Resource Types** (`src/resources/resourcetype.lua`, `data/resources.lua`)
  - Wood, iron, rope, stone, food, cloth definitions
  - Resource weights
  - Spawn rules per biome

- [ ] **Harvesting Logic** (`src/resources/harvesting.lua`)
  - Gather over time (progress bar)
  - Add to inventory on completion
  - Node depletion

- [ ] **Respawn System** (`src/resources/respawn.lua`)
  - Timer-based respawn
  - Distance check from base
  - Visual respawn indicators

#### Week 5
- [ ] **Inventory System** (`src/inventory/inventory.lua`)
  - Add/remove resources
  - Weight-based carry capacity
  - Capacity by class (Scout > Engineer > Archer > Warrior)

- [ ] **Supply Depot** (`src/inventory/supplydepot.lua`)
  - Shared base storage
  - Deposit/withdraw UI
  - Resource totals display

- [ ] **HUD - Resources** (`src/ui/hud.lua`)
  - Current inventory display
  - Carry weight bar
  - Supply depot indicator when nearby

#### Week 6
- [ ] **Build Manager** (`src/buildings/buildmanager.lua`)
  - Grid-based placement
  - Cost validation against supply depot
  - Place/cancel building

- [ ] **Build Ghost** (`src/buildings/buildghost.lua`)
  - Preview sprite (green/red based on valid placement)
  - Snap to grid
  - Collision check with tiles and entities

- [ ] **Building Types - Utility** (`src/buildings/types/utility/`)
  - Supply Depot
  - Campfire (HP regen zone)
  - Base Core (win/lose condition)

- [ ] **Building Types - Defensive** (`src/buildings/types/defensive/`)
  - Wooden Wall
  - Gate

#### Deliverables
- Resource nodes spawn in world
- Players can harvest resources
- Inventory system with carry limits
- Can place basic buildings (walls, supply depot)
- Building costs deduct from shared storage

---

### Developer B: Character Classes & AI Foundation

#### Week 4
- [ ] **Class Definitions** (`data/classes.lua`)
  - Warrior, Archer, Engineer, Scout stat tables
  - Ability definitions

- [ ] **Class Implementations** (`src/characters/`)
  - `warrior.lua`: High HP, melee attack
  - `archer.lua`: Medium HP, ranged attack
  - `engineer.lua`: No combat, building permissions
  - `scout.lua`: High speed, low damage

- [ ] **Class Selection UI** (`src/ui/classselect.lua`)
  - Menu showing 4 classes
  - Stats preview
  - Select and spawn

#### Week 5
- [ ] **Ability System Base** (`src/combat/cooldown.lua` enhancement)
  - Ability activation framework
  - Cooldown per ability
  - Energy/mana cost (if applicable)

- [ ] **Warrior Ability - Shield Bash** (`src/characters/abilities/shieldbash.lua`)
  - Cone knockback
  - Stun duration
  - Cooldown

- [ ] **Archer Ability - Volley** (`src/characters/abilities/volley.lua`)
  - Spread of projectiles
  - Arc angle
  - Cooldown

- [ ] **Scout Ability - Cloak** (`src/characters/abilities/cloak.lua`)
  - Invisibility to enemies
  - Duration timer
  - Visual transparency effect

#### Week 6
- [ ] **Pathfinding** (`src/ai/pathfinding.lua`)
  - A* algorithm on tile grid
  - Walkable tile check
  - Path caching

- [ ] **Steering Behaviors** (`src/ai/steering.lua`)
  - Seek: move toward target
  - Separate: avoid overlap
  - Weighted blend

- [ ] **AI Controller** (`src/ai/aicontroller.lua`)
  - State machine (idle, seek, attack, flee)
  - Target acquisition
  - Attack decision

- [ ] **Basic Enemy - Shambler** (`src/enemies/shambler.lua`)
  - Walks toward base
  - Attacks walls/players
  - Low speed, medium HP

#### Deliverables
- 4 playable character classes with distinct stats
- 3 class abilities functional (shield bash, volley, cloak)
- Pathfinding working on tile grid
- Basic enemy AI (shambler) seeks and attacks

---

## Phase 3: Day/Night & Waves (Weeks 7-8)

### Developer A: Day/Night Cycle & Building Advanced

#### Week 7
- [ ] **Time System** (`src/core/time.lua`)
  - Day/night cycle timer (10-15 min configurable)
  - Dawn/dusk transitions
  - Event triggers on phase change

- [ ] **HUD - Timer** (`src/ui/hud.lua` enhancement)
  - Day counter display
  - Nightfall countdown
  - Phase indicator (Day/Night)

- [ ] **Lighting System** (`src/rendering/lighting.lua`)
  - Darken world at night
  - Torch/campfire light radius
  - Player vision cone at night

#### Week 8
- [ ] **Upgrade System** (`src/buildings/upgrade.lua`)
  - Tier 1 → 2 → 3 progression
  - Upgrade costs (wood → stone → reinforced)
  - Stat changes on upgrade (HP, defense)

- [ ] **Repair System** (`src/buildings/repair.lua`)
  - Engineer repair action
  - HP restoration over time
  - Cost resources from supply depot

- [ ] **Advanced Buildings** (`src/buildings/types/defensive/`)
  - Stone Wall (tier 2)
  - Reinforced Wall (tier 3)
  - Arrow Tower (manneable by Archer)
  - Spike Trap (single-use, reloadable)

- [ ] **Building Damage** (`src/buildings/structure.lua` enhancement)
  - Take damage from enemy attacks
  - Visual damage states (cracks, fire)
  - Destruction and debris

#### Deliverables
- Day/night cycle with visible timer
- World darkens at night
- Buildings can be upgraded through 3 tiers
- Buildings can be damaged and repaired
- Arrow tower functional

---

### Developer B: Enemy Roster & Wave System

#### Week 7
- [ ] **Enemy Base Class** (`src/enemies/enemy.lua`)
  - HP, attack, speed, special ability
  - Death/loot drop
  - Shared behaviors

- [ ] **Enemy Types** (`src/enemies/`)
  - `flyswarm.lua`: Very low HP, high speed, swarm AI
  - `hound.lua`: Fast flanker, targets isolated players
  - `brute.lua`: High HP, attacks structures
  - `spitter.lua`: Ranged, hangs back
  - `wraith.lua`: Phases through wooden walls

- [ ] **Enemy Behaviors** (`src/ai/behaviors/`)
  - `seek.lua`: Move to target
  - `flank.lua`: Circle around player
  - `attackstructure.lua`: Prioritize walls/base

#### Week 8
- [ ] **Wave Manager** (`src/waves/wavemanager.lua`)
  - Trigger on nightfall
  - Spawn coordination
  - Wave end detection (all enemies dead)

- [ ] **Spawner** (`src/waves/spawner.lua`)
  - Spawn on circle radius around base
  - Spawn delay/intervals
  - Multi-direction spawning

- [ ] **Difficulty Scaling** (`src/waves/difficulty.lua`)
  - Night number → enemy types
  - Night 1-3: Swarms + Shamblers
  - Night 4-7: + Hounds + Spitters
  - Night 8+: + Brutes + Wraiths
  - +5% HP/damage every 5 nights

- [ ] **Wave Config** (`data/waves.lua`)
  - Wave composition tables
  - Spawn counts per night
  - Boss wave triggers (nights 10, 20, 30)

#### Deliverables
- 6 enemy types implemented with distinct behaviors
- Wave spawning system triggers at nightfall
- Enemies spawn and path to base
- Difficulty scales with night number
- Wave ends when all enemies killed

---

## Phase 4: Boss & Polish (Weeks 9-10)

### Developer A: Save/Load & UI Polish

#### Week 9
- [ ] **Save Manager** (`src/persistence/savemanager.lua`)
  - Save world state to JSON
  - Save player inventories
  - Save base structures
  - Save day counter

- [ ] **Chunk Saving** (`src/persistence/chunksave.lua`)
  - Serialize chunk tile data
  - Save resource node states
  - Lazy load chunks on game start

- [ ] **Load Manager**
  - Load saved world state
  - Restore player position and class
  - Restore base structures

#### Week 10
- [ ] **UI Polish** (`src/ui/`)
  - Main menu with New Game / Load Game / Settings
  - Build menu for Engineer (hotbar of buildings)
  - Tooltip system (hover over buildings/resources)
  - Death screen and respawn UI

- [ ] **HUD Enhancements**
  - Health bar with armor indicator
  - Ability cooldown icons
  - Wave counter (Night X / Wave Y)

- [ ] **Settings Menu**
  - Volume controls
  - Key rebinding
  - Graphics settings (if applicable)

#### Deliverables
- Save/load system functional
- Can resume from saved games
- Polished UI and menus
- Tooltips and visual feedback

---

### Developer B: Boss & Advanced AI

#### Week 9
- [ ] **Siege Beast** (`src/enemies/siegebeast.lua`)
  - Very high HP (boss-tier)
  - Very high damage (smashes tier 2 walls)
  - Very low speed (telegraphed attacks)
  - Spawns on nights 10, 20, 30

- [ ] **Boss Mechanics**
  - Phase transitions (enrage at 50% HP)
  - Special attacks (AOE ground slam)
  - Requires team coordination
  - Extended aggro range

- [ ] **Advanced AI Behaviors** (`src/ai/behaviors/`)
  - Boss aggro management (targets highest threat)
  - Coordinated flanking (hounds work together)
  - Structure priority (brutes ignore players if wall nearby)

#### Week 10
- [ ] **Combat Polish**
  - Hit effects (blood, sparks)
  - Screen shake on heavy hits
  - Death animations
  - Loot drops from enemies

- [ ] **Ability Polish**
  - Visual effects for all abilities
  - Sound effects
  - Impact feedback (knockback, stun visuals)

- [ ] **Balance Tuning**
  - Adjust enemy stats based on playtesting
  - Tweak class stats
  - Adjust resource costs
  - Fine-tune wave difficulty curve

#### Deliverables
- Siege Beast boss fully implemented
- Boss waves on milestone nights
- Polished combat with effects and feedback
- Game balanced for 1-4 player co-op

---

## Phase 5: Stretch Goals & Multiplayer (Weeks 11+)

### Both Developers

#### Multiplayer Foundation (Week 11-12)
- [ ] **Server** (`src/networking/server.lua`)
  - Authoritative game simulation
  - State snapshot broadcasting
  - Client connection handling

- [ ] **Client** (`src/networking/client.lua`)
  - Input sending
  - State interpolation
  - Prediction and reconciliation

- [ ] **Protocol** (`src/networking/protocol.lua`)
  - Message format definitions
  - Serialization/deserialization
  - Packet prioritization

#### Stretch Goals (Week 13+)
- [ ] **Tech Tree** - Unlock buildings by surviving nights
- [ ] **Seasonal Modifiers** - Blizzard/fire nights
- [ ] **NPC Survivors** - Rescue and recruit helpers
- [ ] **Underground Layer** - Cave biome with rare resources
- [ ] **Asymmetric Threat Nights** - Single enemy type in massive numbers
- [ ] **Turret Automation** - Late-game auto-turrets

---

## Integration Points

### Weekly Sync Points
Every Friday, both developers sync and integrate:
1. **Code Review**: Review each other's merged code
2. **Integration Test**: Play together to verify systems interact correctly
3. **Bug Bash**: Fix cross-system bugs
4. **Planning**: Adjust next week's tasks based on progress

### Critical Integration Milestones

#### Milestone 1 (End of Phase 1)
- Character can move in generated world
- Camera follows character
- Combat system hits entities
- Debug overlay shows all stats

#### Milestone 2 (End of Phase 2)
- Resources can be harvested and stored
- Buildings can be placed and have collision
- Enemies spawn and pathfind to base
- All 4 character classes playable

#### Milestone 3 (End of Phase 3)
- Day/night cycle triggers waves
- Waves spawn at night with scaling difficulty
- Buildings can be damaged and repaired
- Game loop complete (day → night → survive/die)

#### Milestone 4 (End of Phase 4)
- Boss waves functional
- Save/load working
- UI polished
- Game ready for alpha testing

---

## Testing Strategy

### Developer A Tests
- World generation consistency
- Chunk loading performance
- Resource respawn timers
- Building placement validation
- Save/load integrity

### Developer B Tests
- Pathfinding performance with 100+ enemies
- Combat hit detection accuracy
- Class balance (1v1, 1v5, etc.)
- Wave difficulty progression
- Boss fight mechanics

### Shared Tests
- Full game loop (day 1 → night 10)
- Performance with max entities
- Memory leaks during long sessions
- All 4 classes in multiplayer (future)

---

## Risk Mitigation

### High-Risk Items
1. **Chunk loading performance** - Mitigate with aggressive caching and lazy loading
2. **Pathfinding with 100+ enemies** - Use spatial hashing and path caching
3. **Multiplayer sync** - Start with client-server prototype early (Phase 5)
4. **Wave balance** - Continuous playtesting from Phase 3 onward

### Dependency Management
- **Developer B** depends on Developer A's world generation for enemy pathfinding
  - **Mitigation**: Developer A delivers tile walkability system by Week 3
- **Developer A** depends on Developer B's entity system for building collision
  - **Mitigation**: Developer B delivers hitbox system by Week 3

---

## Communication Protocol

### Daily Standups (Async)
Each developer posts in shared chat:
- What I did yesterday
- What I'm doing today
- Any blockers

### Weekly Sync (Live)
Friday video call:
- Demo completed features
- Integration testing
- Plan next week
- Review/merge PRs

### Git Workflow
- **main** branch: Always stable, tagged releases
- **dev** branch: Integration branch
- **feature/** branches: Individual features
- PR required for merge to dev
- Weekly merge from dev → main after integration test

---

## Deliverable Timeline

| Week | Developer A | Developer B | Joint Milestone |
|------|-------------|-------------|-----------------|
| 1 | Foundation setup | Foundation setup | Basic game loop |
| 2 | Camera + isometric rendering | Character controller + input | Player moves in world |
| 3 | World gen + chunks | Combat + hitboxes | Integrated core systems |
| 4 | Resources + harvesting | Character classes | Resources collectible |
| 5 | Inventory + supply depot | Abilities + pathfinding | All classes playable |
| 6 | Building placement | Basic enemy AI | Buildings placeable |
| 7 | Day/night cycle | Enemy roster complete | Day/night functional |
| 8 | Building upgrades | Wave system | Full game loop |
| 9 | Save/load | Boss implementation | Game saveable |
| 10 | UI polish | Combat polish | Alpha release ready |
| 11-12 | Multiplayer networking | Multiplayer networking | Co-op functional |
| 13+ | Stretch goals | Stretch goals | Feature expansion |

---

## Success Criteria

### Alpha Release (End of Phase 4)
- [ ] Single player can complete day 1 → night 10
- [ ] All 4 character classes functional with abilities
- [ ] Full resource → build → defend loop working
- [ ] 6 enemy types with distinct behaviors
- [ ] Boss wave on night 10
- [ ] Save/load functional
- [ ] No game-breaking bugs

### Beta Release (End of Phase 5)
- [ ] 2-4 player co-op working
- [ ] Balanced for multiplayer
- [ ] Stretch goals implemented
- [ ] Performance optimized (60 FPS with 100+ entities)
- [ ] Full audio and visual polish

---

## Notes

- This plan assumes 20-30 hours/week per developer
- Adjust timelines based on actual velocity after Phase 1
- Priorities: **Core loop first, polish later**
- Test continuously, don't wait until end
- Keep scope tight; move nice-to-haves to stretch goals
