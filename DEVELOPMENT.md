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

### Libraries & Dependencies

| Command | Description |
|---------|-------------|
| `make libs` | Show recommended libraries for common features |
| `make find-lib FEATURE="..."` | Search for libraries by feature keyword |

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

## Library Discovery Workflow

**IMPORTANT**: Always check for existing libraries before implementing functionality from scratch.

### Quick Start

```bash
# Show recommended libraries for common features
make libs

# Search for specific functionality
make find-lib FEATURE="collision"
make find-lib FEATURE="pathfinding"
make find-lib FEATURE="camera"
```

### Step-by-Step Process

1. **Identify the need**
   - "I need to add collision detection"
   - "I need pathfinding for enemies"
   - "I need to animate sprites"

2. **Search for libraries**
   ```bash
   make find-lib FEATURE="collision"
   ```

3. **Review LIBRARIES.md**
   - Open `LIBRARIES.md` and read the full section
   - Check library stars, last update, license
   - Read the "Recommendation for Holdfast" notes

4. **Evaluate the library**
   - Does it solve the exact problem?
   - Is it actively maintained?
   - Is it lightweight enough?
   - Does it work with Love2D 11.5+?

5. **Test before committing**
   - Create a minimal test file
   - Verify it works in your environment
   - Check performance impact

6. **Install and integrate**
   ```bash
   # Download to lib/ directory
   cd lib/
   curl -O https://raw.githubusercontent.com/user/repo/master/lib.lua

   # Or use git submodule
   git submodule add https://github.com/user/repo lib/libname
   ```

7. **Document the decision**
   - Update `LIBRARIES.md` if you found a new library
   - Add notes about why you chose it
   - Update this README if it's a core dependency

### Example Workflow

```bash
# Need: Collision detection for players and walls
$ make find-lib FEATURE="collision"

# Output shows:
#   - box2d (too heavy, full physics)
#   - bump.lua (perfect for AABB)
#   - HC (good for circles/polygons)

# Decision: Use bump.lua for simple AABB collision

# Install
$ cd lib/
$ curl -O https://raw.githubusercontent.com/kikito/bump.lua/master/bump.lua

# Use in code
-- In your Lua file:
local bump = require("lib.bump")
```

### Common Pitfalls to Avoid

- **Don't reinvent the wheel** - Search first, implement last
- **Don't add bloat** - Use lightweight libraries when possible
- **Don't skip evaluation** - Test before committing to a library
- **Don't ignore licenses** - Check MIT/Apache/BSD compatibility
- **Don't use unmaintained libs** - Prefer active projects

### When to Write Custom Code

Write custom code when:
- No suitable library exists
- Existing libraries are too heavy/complex
- You need very specific behavior
- The feature is trivial (< 50 lines)

### When to Use a Library

Use a library when:
- Complex algorithm (A*, physics, noise)
- Well-tested solution exists
- Standard pattern (ECS, tweening, animation)
- Saves significant development time

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
