# Development Guide for Holdfast

## Quick Start

```bash
# First time setup
make init

# Run the game
make run

# Run in development mode (with debug overlay)
make dev

# Watch for changes and auto-reload
make watch
```

## Makefile Commands

### Development Workflow

| Command | Description |
|---------|-------------|
| `make help` | Show all available commands |
| `make run` | Run the game with Love2D |
| `make dev` | Run in development mode with debug overlay |
| `make watch` | Auto-reload on file changes (requires entr) |

### Code Quality

| Command | Description |
|---------|-------------|
| `make lint` | Lint Lua code with luacheck |
| `make format` | Format code with stylua (optional) |
| `make test` | Run test suite |
| `make validate` | Run all checks (lint + test) |

### Building & Distribution

| Command | Description |
|---------|-------------|
| `make build` | Create .love file for distribution |
| `make build-all` | Build for all platforms |
| `make package-macos` | Create macOS .app bundle |
| `make package-linux` | Create Linux package |
| `make package-windows` | Create Windows executable |

### Utilities

| Command | Description |
|---------|-------------|
| `make clean` | Remove build artifacts |
| `make stats` | Show project statistics |
| `make install-deps` | Install development dependencies |
| `make init` | First-time project setup |

## Development Environment Setup

### macOS

```bash
# Install Love2D
brew install love

# Install development dependencies
make install-deps

# Add luarocks binaries to PATH (add to ~/.zshrc or ~/.bash_profile)
export PATH=$HOME/.luarocks/bin:$PATH
```

### Linux (Debian/Ubuntu)

```bash
# Install Love2D
sudo apt-get install love

# Install dependencies
sudo apt-get install luarocks entr

# Install Lua tools
luarocks install --local luacheck
luarocks install --local busted

# Add to PATH
export PATH=$HOME/.luarocks/bin:$PATH
```

### Linux (Fedora/RHEL)

```bash
# Install Love2D
sudo dnf install love

# Install dependencies
sudo dnf install luarocks entr

# Install Lua tools
luarocks install --local luacheck
luarocks install --local busted
```

### Windows

1. Download Love2D from https://love2d.org/
2. Add Love2D to your PATH
3. Install luarocks from https://luarocks.org/
4. Run `make install-deps` in Git Bash or WSL

## Recommended Development Tools

### Code Editor Setup

#### VS Code Extensions
- **Lua** by sumneko - Language server with excellent autocomplete
- **Love2D Support** - Snippets and Love2D API support
- **vscode-lua-format** - Auto-formatting

#### VS Code Settings (`.vscode/settings.json`)
```json
{
  "Lua.runtime.version": "LuaJIT",
  "Lua.diagnostics.globals": ["love"],
  "Lua.workspace.library": ["${3rd}/love2d/library"]
}
```

### Auto-Reload During Development

The `make watch` command uses `entr` to automatically restart the game when files change:

```bash
make watch
```

This is the recommended way to develop - edit code, save, and instantly see changes.

### Debug Overlay

Press **F1** in-game to toggle the debug overlay showing:
- FPS
- Entity count
- Memory usage
- Current game state
- Player position

## Project Structure

```
holdfast/
├── main.lua              # Entry point
├── conf.lua              # Love2D configuration
├── src/                  # Source code
│   ├── core/            # Core systems (state machine, event bus)
│   ├── ecs/             # Entity Component System
│   ├── states/          # Game states (menu, day, night, gameover)
│   ├── systems/         # ECS systems
│   └── ui/              # UI components
├── assets/              # Game assets (sprites, sounds, fonts)
├── data/                # Game data (config, constants)
├── lib/                 # Third-party libraries
├── tests/               # Test files
├── saves/               # Save files (gitignored)
└── build/               # Build output (gitignored)
```

## Testing

### Running Tests

```bash
make test
```

### Writing Tests

Place test files in `tests/` directory. Use the `busted` framework:

```lua
describe("Player", function()
    it("should start with full health", function()
        local player = Player.new()
        assert.equals(100, player.health)
    end)
end)
```

## Code Style Guidelines

- **Indentation**: 4 spaces (no tabs)
- **Naming**:
  - Variables/functions: `snake_case`
  - Classes: `PascalCase`
  - Constants: `UPPER_SNAKE_CASE`
- **Line length**: Max 120 characters
- **Comments**: Use `--` for single line, `--[[ ]]` for multi-line

### Example

```lua
-- Good
local function calculate_damage(base_damage, armor)
    return math.max(0, base_damage - armor)
end

-- Bad
local function CalculateDamage(baseDamage,armor)
return baseDamage-armor
end
```

## Git Workflow

### Commit Messages

Follow conventional commits:

```
feat: add warrior shield bash ability
fix: resolve collision detection bug
docs: update development guide
refactor: simplify pathfinding algorithm
test: add unit tests for inventory system
```

### Branch Naming

- `feature/feature-name` - New features
- `fix/bug-description` - Bug fixes
- `refactor/component-name` - Code refactoring
- `docs/what-changed` - Documentation updates

## Performance Tips

1. **Profile before optimizing**: Use the debug overlay to identify bottlenecks
2. **Batch sprite drawing**: Use sprite batches for static tiles
3. **Chunk-based rendering**: Only render visible chunks
4. **Pool objects**: Reuse entity instances instead of creating new ones
5. **Limit collision checks**: Use spatial partitioning (quadtree)

## Troubleshooting

### Game won't start

1. Check Love2D is installed: `love --version`
2. Verify you're in the project root directory
3. Check for syntax errors: `make lint`

### Auto-reload not working

1. Install entr: `brew install entr` (macOS) or `apt-get install entr` (Linux)
2. Make sure you're running `make watch`, not `make run`

### Build fails

1. Run `make clean` to remove old artifacts
2. Check for lint errors: `make lint`
3. Verify all dependencies are installed: `make install-deps`

## Resources

- [Love2D Documentation](https://love2d.org/wiki/Main_Page)
- [Lua 5.1 Reference](https://www.lua.org/manual/5.1/)
- [Love2D Forums](https://love2d.org/forums/)
- [Project Design Doc](CLAUDE.md)
- [Implementation Plan](IMPLEMENTATION_PLAN.md)

## Getting Help

1. Check the [CLAUDE.md](CLAUDE.md) for game design details
2. Read the [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) for architecture info
3. Run `make help` for available commands
4. Check existing code in `src/` for examples
