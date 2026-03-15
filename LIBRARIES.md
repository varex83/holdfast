# Love2D & Lua Library Reference

A curated list of libraries commonly used in Love2D game development. **Always check this list before implementing functionality from scratch.**

## How to Use This Guide

1. Search this file (Cmd/Ctrl + F) for keywords related to your needs
2. Check the "Common Use Cases" section for typical game features
3. Run `make find-lib FEATURE="your-feature"` to search this file from terminal
4. Visit the links to evaluate if the library fits your needs

---

## Core Game Development

### Physics & Collision

| Library | Description | Link | Stars |
|---------|-------------|------|-------|
| **box2d** | Built into Love2D - Full 2D physics engine | [Love2D Physics](https://love2d.org/wiki/love.physics) | Native |
| **bump.lua** | Simple AABB collision detection, no physics | [kikito/bump.lua](https://github.com/kikito/bump.lua) | 900+ |
| **HC (HardonCollider)** | Lightweight collision detection with shapes | [vrld/HC](https://github.com/vrld/HC) | 400+ |
| **windfield** | Box2D wrapper with easier API | [adnzzzzZ/windfield](https://github.com/adnzzzzZ/windfield) | 800+ |

**Recommendation for Holdfast**: Use **bump.lua** for simple AABB collision (walls, resources, players). It's fast and perfect for non-physics games.

---

### Entity Component System (ECS)

| Library | Description | Link | Stars |
|---------|-------------|------|-------|
| **tiny-ecs** | Minimal, fast ECS for Lua | [bakpakin/tiny-ecs](https://github.com/bakpakin/tiny-ecs) | 600+ |
| **concord** | Feature-rich ECS with Love2D focus | [Tjakka5/Concord](https://github.com/Tjakka5/Concord) | 200+ |
| **nata** | Simple entity pooling system | [tesselode/nata](https://github.com/tesselode/nata) | 100+ |

**Recommendation for Holdfast**: We have a custom ECS in `src/ecs/`. Evaluate **tiny-ecs** if our system becomes complex.

---

### Camera & Viewport

| Library | Description | Link | Stars |
|---------|-------------|------|-------|
| **gamera** | Camera with bounds, smoothing, rotation | [kikito/gamera](https://github.com/kikito/gamera) | 300+ |
| **STALKER-X** | Feature-rich camera (shake, flash, follow) | [adnzzzzZ/STALKER-X](https://github.com/adnzzzzZ/STALKER-X) | 400+ |
| **hump.camera** | Part of hump library, simple camera | [vrld/hump](https://github.com/vrld/hump) | 1000+ |

**Recommendation for Holdfast**: **gamera** for simple follow camera with bounds, or **STALKER-X** for screen shake effects during combat.

---

### Pathfinding

| Library | Description | Link | Stars |
|---------|-------------|------|-------|
| **jumper** | A* pathfinding for grid-based maps | [Yonaba/Jumper](https://github.com/Yonaba/Jumper) | 600+ |
| **pathfun** | Fast grid pathfinding | [apicici/pathfun](https://github.com/apicici/pathfun) | 50+ |

**Recommendation for Holdfast**: **jumper** for monster pathfinding to base during night waves.

---

### State Management

| Library | Description | Link | Stars |
|---------|-------------|------|-------|
| **hump.gamestate** | Simple state machine | [vrld/hump](https://github.com/vrld/hump) | 1000+ |
| **stateful** | State machine for entities | [kikito/stateful.lua](https://github.com/kikito/stateful.lua) | 200+ |
| **roomy** | Scene/room management | [tesselode/roomy](https://github.com/tesselode/roomy) | 100+ |

**Recommendation for Holdfast**: We have custom state machine in `src/core/statemachine.lua`. Use **stateful** for individual entity states if needed.

---

### UI & GUI

| Library | Description | Link | Stars |
|---------|-------------|------|-------|
| **Slab** | Immediate-mode GUI toolkit | [flamendless/Slab](https://github.com/flamendless/Slab) | 300+ |
| **Gspöt** | Retained-mode GUI toolkit | [pgimeno/gspot](https://notabug.org/pgimeno/gspot) | Legacy |
| **SUIT** | Simple immediate-mode UI | [vrld/SUIT](https://github.com/vrld/SUIT) | 400+ |
| **imgui-love** | Dear ImGui for Love2D (debug UIs) | [slages/love-imgui](https://github.com/slages/love-imgui) | 300+ |

**Recommendation for Holdfast**: **SUIT** for simple menus, or **imgui-love** for debug/dev tools only.

---

### Tweening & Animation

| Library | Description | Link | Stars |
|---------|-------------|------|-------|
| **flux** | Fast, simple tweening library | [rxi/flux](https://github.com/rxi/flux) | 400+ |
| **tween.lua** | Easing functions for animations | [kikito/tween.lua](https://github.com/kikito/tween.lua) | 500+ |
| **anim8** | Sprite animation library | [kikito/anim8](https://github.com/kikito/anim8) | 700+ |

**Recommendation for Holdfast**: **anim8** for character sprite animations, **flux** for UI transitions.

---

### Tilemaps

| Library | Description | Link | Stars |
|---------|-------------|------|-------|
| **STI (Simple Tiled Implementation)** | Tiled map loader | [karai17/Simple-Tiled-Implementation](https://github.com/karai17/Simple-Tiled-Implementation) | 800+ |
| **ATL (Advanced Tiled Loader)** | Another Tiled loader (older) | [Kadoba/Advanced-Tiled-Loader](https://github.com/Kadoba/Advanced-Tiled-Loader) | 200+ |

**Recommendation for Holdfast**: **STI** if using Tiled editor, or custom chunk system for procedural generation (preferred).

---

### Noise & Procedural Generation

| Library | Description | Link | Stars |
|---------|-------------|------|-------|
| **love-noise** | Perlin/Simplex noise for Love2D | [love2d/love](https://love2d.org/wiki/love.math.noise) | Native |
| **lua-noise** | Pure Lua noise implementation | [codeflows/lua-noise](https://github.com/codeflows/lua-noise) | 50+ |

**Recommendation for Holdfast**: Use Love2D's built-in `love.math.noise()` for world generation.

---

### Networking

| Library | Description | Link | Stars |
|---------|-------------|------|-------|
| **lua-enet** | ENet bindings for Lua (UDP networking) | [leafo/lua-enet](https://github.com/leafo/lua-enet) | 200+ |
| **sock.lua** | Simple networking wrapper | [camchenry/sock.lua](https://github.com/camchenry/sock.lua) | 400+ |
| **NoobHub** | WebSocket multiplayer server | [Overtorment/NoobHub](https://github.com/Overtorment/NoobHub) | 300+ |

**Recommendation for Holdfast**: **lua-enet** for future multiplayer (client-server authoritative).

---

### Audio

| Library | Description | Link | Stars |
|---------|-------------|------|-------|
| **ripple** | Audio management with tags | [tesselode/ripple](https://github.com/tesselode/ripple) | 100+ |
| **lily** | Async asset loading (images, audio) | [MikuAuahDark/lily](https://github.com/MikuAuahDark/lily) | 100+ |
| **TEsound** | Sound manager | [Ensayia/TEsound](https://github.com/Ensayia/TEsound) | 200+ |

**Recommendation for Holdfast**: **ripple** for managing combat sounds, ambient audio, music tracks.

---

### Utilities

| Library | Description | Link | Stars |
|---------|-------------|------|-------|
| **lume** | Collection of Lua utilities | [rxi/lume](https://github.com/rxi/lume) | 1000+ |
| **moses** | Functional programming utilities | [Yonaba/Moses](https://github.com/Yonaba/Moses) | 600+ |
| **middleclass** | OOP class system | [kikito/middleclass](https://github.com/kikito/middleclass) | 1700+ |
| **classic** | Tiny class system | [rxi/classic](https://github.com/rxi/classic) | 800+ |

**Recommendation for Holdfast**: We use custom class in `lib/class.lua`. **lume** is excellent for general utilities.

---

### Serialization & Save/Load

| Library | Description | Link | Stars |
|---------|-------------|------|-------|
| **binser** | Binary serialization | [bakpakin/binser](https://github.com/bakpakin/binser) | 200+ |
| **bitser** | Fast binary serializer | [gvx/bitser](https://github.com/gvx/bitser) | 150+ |
| **dkjson** | Pure Lua JSON encoder/decoder | [LuaDist/dkjson](https://github.com/LuaDist/dkjson) | 100+ |

**Recommendation for Holdfast**: **dkjson** for human-readable save files, or **binser** for compact binary saves.

---

### Logging & Debugging

| Library | Description | Link | Stars |
|---------|-------------|------|-------|
| **lurker** | Auto-reloader for development | [rxi/lurker](https://github.com/rxi/lurker) | 300+ |
| **lovebird** | Browser-based debug console | [rxi/lovebird](https://github.com/rxi/lovebird) | 400+ |
| **log.lua** | Simple logging library | [rxi/log.lua](https://github.com/rxi/log.lua) | 300+ |

**Recommendation for Holdfast**: **lurker** for hot-reload (better than `make watch`), **log.lua** for logging.

---

## Common Use Cases

### "I need to..." → "Use this library"

| Need | Library | Why |
|------|---------|-----|
| Detect collisions between rectangles | bump.lua | Fast, simple AABB collision |
| Make enemies walk toward the base | jumper | A* pathfinding on grid |
| Animate sprite sheets | anim8 | Standard for sprite animation |
| Load Tiled maps | STI | If using Tiled editor |
| Add a camera that follows player | gamera | Simple, effective camera |
| Manage game states (menu, day, night) | *(custom)* | We have `src/core/statemachine.lua` |
| Serialize save data | dkjson | Human-readable JSON |
| Tween UI elements | flux | Lightweight tweening |
| Play sounds with volume control | ripple | Audio management |
| Network multiplayer | lua-enet | Best for real-time games |
| Generate Perlin noise | love.math.noise | Built into Love2D |
| Hot-reload code changes | lurker | Auto-reload on save |
| Helper functions (map, filter, etc.) | lume | Swiss army knife utilities |
| Debug console in browser | lovebird | Web-based debugging |

---

## Installation Methods

### Method 1: Copy Library Files
```bash
# Download and copy to lib/ directory
cd lib/
curl -O https://raw.githubusercontent.com/kikito/bump.lua/master/bump.lua
```

### Method 2: Git Submodule
```bash
# Add as git submodule
git submodule add https://github.com/kikito/bump.lua lib/bump
```

### Method 3: LuaRocks
```bash
# Install via LuaRocks (if available)
luarocks install bump
```

### Method 4: Manual Download
1. Visit the GitHub repository
2. Download the `.lua` file(s)
3. Place in `lib/` directory
4. Require in your code: `local bump = require("lib.bump")`

---

## Before Adding a Library - Checklist

- [ ] Search this file for existing solutions
- [ ] Check if Love2D has built-in functionality (physics, noise, etc.)
- [ ] Evaluate library activity (last commit, stars, issues)
- [ ] Check license compatibility (MIT, Apache, etc.)
- [ ] Test in a minimal example first
- [ ] Consider bundle size impact
- [ ] Ensure it works with Love2D 11.5+
- [ ] Read the documentation/API
- [ ] Add to this file if useful

---

## Holdfast-Specific Recommendations

### Currently Using
- Custom ECS (`src/ecs/`)
- Custom State Machine (`src/core/statemachine.lua`)
- Custom Class System (`lib/class.lua`)

### Should Consider
- **bump.lua** - For player/enemy/structure collision
- **jumper** - Integrated via `src/ai/pathfinding.lua` for grid-based enemy routing
- **anim8** - Integrated in `src/characters/character.lua` for sprite-sheet playback
- **flux** - Integrated in `src/core/game.lua` and `src/states/teststate.lua` for UI/camera tweens
- **lume** - General utilities
- **dkjson** - Save/load system
- **lurker** - Hot-reload during development

### Avoid For Now
- Box2D physics - Too heavy for this game
- Complex ECS libraries - We have custom solution
- Heavy UI frameworks - Keep it simple

---

## Resources

- [Love2D Wiki Libraries](https://love2d.org/wiki/Category:Libraries)
- [Awesome Love2D](https://github.com/love2d-community/awesome-love2d)
- [LuaRocks](https://luarocks.org/)
- [Lua Users Wiki](http://lua-users.org/wiki/LibrariesAndBindings)

---

## Contributing to This List

When you discover a useful library:
1. Test it in the project
2. Add it to the appropriate section
3. Include: name, description, link, star count, recommendation
4. Update "Common Use Cases" if applicable
5. Commit changes to this file

**Last Updated**: 2026-03-15
