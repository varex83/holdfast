# Holdfast

A 2D cooperative survival game built with Love2D. Gather resources by day, defend your base by night.

## Quick Start

### Prerequisites
- [Love2D 11.5+](https://love2d.org/)
- Git

### Running the Game
```bash
love .
```

## Project Documentation

- **[CLAUDE.md](CLAUDE.md)** - Complete game design document
- **[PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)** - Codebase organization and architecture
- **[IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md)** - Development roadmap for 2 developers

## For Developers

### Project Structure
```
holdfast/
├── src/           # Source code
│   ├── core/      # Engine systems (game loop, state machine, camera)
│   ├── ecs/       # Entity component system
│   ├── world/     # World generation and chunks
│   ├── rendering/ # Isometric rendering
│   ├── characters/# Player classes
│   ├── combat/    # Combat systems
│   ├── ai/        # Pathfinding and AI
│   ├── enemies/   # Enemy types
│   ├── waves/     # Wave spawning
│   ├── resources/ # Resource gathering
│   ├── buildings/ # Base building
│   └── ui/        # User interface
├── data/          # Game configuration
├── assets/        # Sprites, sounds, fonts
└── lib/           # External libraries
```

### Development Workflow

1. **Check the implementation plan** - See [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md)
2. **Pick your role** - Developer A (World & Systems) or Developer B (Combat & Gameplay)
3. **Create feature branch** - `git checkout -b feature/your-feature-name`
4. **Implement and test** - Follow the project structure guidelines
5. **Submit PR to dev branch** - Code review required
6. **Weekly integration** - Friday sync and merge to main

### Coding Standards

- Use **camelCase** for local variables and functions
- Use **PascalCase** for classes and modules
- Each module returns a single table
- Document complex functions with comments
- Keep functions under 50 lines when possible
- No global variables (except Love2D callbacks)

### Testing Your Code

Run with debug overlay:
```bash
love . --debug
```

Toggle debug view in-game with `F1`.

## Architecture Highlights

### Entity Component System
```lua
local entity = Entity.new()
entity:addComponent(Position, {x = 0, y = 0})
entity:addComponent(Velocity, {vx = 0, vy = 0})
entity:addComponent(Health, {hp = 100, maxHp = 100})
```

### Isometric Coordinate Conversion
```lua
local screenX, screenY = Isometric.worldToScreen(worldX, worldY)
local worldX, worldY = Isometric.screenToWorld(screenX, screenY)
```

### Event System
```lua
EventBus:emit("enemyKilled", {enemyType = "shambler", position = {x, y}})
EventBus:on("enemyKilled", function(data) ... end)
```

## Current Status

**Phase**: Phase 0 - Foundation ✅ COMPLETE
**Version**: 0.1.0-alpha
**Playable**: Menu and state transitions working

### Phase 0 Complete
- ✅ Project directory structure
- ✅ Love2D configuration (main.lua, conf.lua)
- ✅ State machine (menu, day, night, gameover)
- ✅ ECS foundation (Entity, Component, System, World)
- ✅ Event bus for cross-system communication
- ✅ Game configuration files
- ✅ Debug overlay (F1 to toggle)

The game now launches with a basic menu and can transition between states!

See [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) for detailed progress tracking.

## License

TBD

## Credits

Built with [Love2D](https://love2d.org/)
