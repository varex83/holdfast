
## Lua / Love2D Development Prompts

Copy-paste prompts for AI-assisted development, organized by subsystem.

---

### Architecture & Boilerplate

```
I'm building a Love2D game in Lua. Set up a basic game loop with:
- A state machine (menu, day, night, gameover states)
- Delta-time based movement
- A camera system that follows the player with smooth lerp
```

```
Create a Love2D entity-component system in pure Lua. Entities are tables,
components are mixed in. Include: position, velocity, health, sprite, collider.
```

```
Implement a chunk-based infinite world in Love2D using Perlin noise.
Each chunk is 16x16 tiles. Only load/unload chunks near the player.
Store chunks in a table keyed by "x,y" string.
```

---

### Isometric Rendering

```
Write a Love2D isometric tile renderer. Convert between world (tile) coordinates
and screen coordinates. Tiles are 64x32 pixels. Support depth-sorting of sprites
so units behind walls are occluded correctly.
```

```
I have an isometric Love2D game. Implement a draw-order sort so entities
are rendered back-to-front based on their Y position (painter's algorithm).
```

---

### Character & AI

```
Implement a character controller in Love2D for a top-down isometric game.
The character has: speed, a target position to walk toward, and a simple
state machine (idle, walking, attacking, dead).
```

```
Write a simple steering behavior for enemy AI in Love2D:
- Seek: move toward a target position
- Separation: avoid overlapping with other enemies
- Combine both with weighted blending
```

```
Implement pathfinding in Love2D using A* on a 2D grid.
The grid has walkable/blocked tiles. Return a list of tile positions as the path.
```

---

### Combat & Abilities

```
Implement a hitbox/hurtbox system in Love2D using AABB collision.
Attacks register a hitbox for N frames. Entities have a hurtbox.
Hits are only registered once per attack swing.
```

```
Create a cooldown/ability system in Lua. Each ability has:
a cooldown duration, an activate() function, and a visual indicator timer.
Abilities are stored per-entity in a table.
```

---

### Base Building

```
Implement a grid-based building placement system in Love2D.
The player sees a ghost preview snapped to the grid. On click, place the building
if the tiles are clear. Buildings are stored in a 2D table and rendered as sprites.
```

```
Write a structure upgrade system in Lua. Each building has a tier (1–3),
a cost table per tier, and a stats table per tier (hp, defense).
Upgrading mutates the building table in place.
```

---

### Resources & Inventory

```
Implement a resource node system in Love2D. Nodes have a resource type,
quantity, and respawn timer. When a player interacts (within range + key press),
they harvest 1 unit per tick up to their carry capacity.
```

```
Create a player inventory system in Lua. Each player has a carry_capacity
and a table of {resource: amount}. Implement add(), remove(), total_weight(),
and is_full() functions.
```

---

### Wave System

```
Implement a night wave spawner in Love2D. Waves are defined as a list of
{monster_type, count, spawn_delay} entries. Monsters spawn from random
points on a circle radius around the base. Scale HP and count by wave number.
```

```
Write a wave difficulty scaler in Lua. Given a night number, return a table of
monster groups to spawn. Early nights: small swarms. Later nights: mixed types
from multiple directions. Every 10 nights: include a boss unit.
```

---

### Networking (Future)

```
Sketch a client-server architecture for a Love2D co-op game using ENET (lua-enet).
Server is authoritative: it runs simulation and sends state snapshots.
Clients send inputs only. Show the message format and update loop structure.
```

---

### Save / Load

```
Implement a save/load system in Love2D. Serialize the game world (chunk data,
base structures, player inventories, night counter) to a JSON file using
a Lua JSON library. Load and restore full state on game start.
```

---

### Debugging & Dev Tools

```
Add a Love2D debug overlay (toggle with F1) that shows:
- Current FPS
- Entity count
- Chunk load/unload events
- Player position in world and tile coordinates
- All active hitboxes drawn as colored rectangles
```

```
Write a Love2D hot-reload system that watches Lua files for changes
and re-requires them without restarting. Useful during development.
```

---