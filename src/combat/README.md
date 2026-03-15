# Combat System

## Overview

The combat system handles projectiles, collisions, and damage calculations for Holdfast.

## Collision Detection

### Using bump.lua for Spatial Partitioning

The `CollisionManager` wraps the `bump.lua` library to provide efficient AABB collision detection using spatial partitioning. This is critical for performance when dealing with 100+ entities during night waves.

### Performance Comparison

- **Without bump.lua**: O(n × m) - Every projectile checks against every entity
- **With bump.lua**: O(log n) - Only checks entities in nearby spatial cells

### Usage Example

```lua
local CollisionManager = require('src.combat.collisionmanager')
local ProjectileSystem = require('src.combat.projectilesystem')

-- Create collision manager
local collisionManager = CollisionManager:new()

-- Create projectile system with collision manager
local projectileSystem = ProjectileSystem:new(world, collisionManager)

-- The system will automatically:
-- 1. Sync entities with collision manager each frame
-- 2. Use spatial partitioning for collision queries
-- 3. Clean up removed entities from collision world
```

### Backward Compatibility

The `ProjectileSystem` works both with and without the `CollisionManager`:

- **With CollisionManager**: Uses optimized spatial partitioning (recommended)
- **Without CollisionManager**: Falls back to brute-force collision checks

```lua
-- Without collision manager (fallback mode)
local projectileSystem = ProjectileSystem:new(world)

-- With collision manager (optimized mode)
local projectileSystem = ProjectileSystem:new(world, collisionManager)
```

## Systems

### ProjectileSystem

Handles projectile movement, physics, and collision detection.

**Features:**
- Gravity simulation
- Homing projectiles
- Piercing projectiles
- Team-based collision filtering
- Damage application with armor calculation

**Required Components:**
- `position` - Entity position
- `velocity` - Movement velocity
- `projectiledata` - Projectile-specific data
- `hitbox` - Collision bounds

**Optional Components:**
- `sprite` - Visual representation

## Components

### ProjectileData

Stores projectile-specific data like damage, lifetime, piercing, homing, etc.

See `src/ecs/components/projectiledata.lua` for details.

### Hitbox

Defines collision bounds and team affiliation.

See `src/ecs/components/hitbox.lua` for details.

## Future Enhancements

- Projectile pooling for better memory management
- Trajectory prediction for homing projectiles
- Area-of-effect damage
- Status effects (poison, slow, etc.)
