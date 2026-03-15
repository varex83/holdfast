# Library Check Workflow

This file serves as a checklist and workflow guide for checking existing libraries before implementing new functionality. Use this when you (or Claude) are about to implement a new feature.

## Pre-Implementation Checklist

Before writing any implementation code, complete these steps:

### 1. Identify the Feature
- [ ] What functionality do I need?
- [ ] Is this a common game development pattern?
- [ ] Can I describe it in 1-2 keywords? (e.g., "collision", "pathfinding", "animation")

### 2. Search for Existing Solutions

```bash
# Quick recommendations
make libs

# Search for specific feature
make find-lib FEATURE="<keyword>"
```

- [ ] Ran `make libs` to see common recommendations
- [ ] Ran `make find-lib` with relevant keyword(s)
- [ ] Reviewed LIBRARIES.md for full details

### 3. Check Built-in Love2D Features

Before adding external libraries, check if Love2D has built-in support:

| Feature | Built-in Love2D Module |
|---------|----------------------|
| Physics | `love.physics` (Box2D) |
| Noise generation | `love.math.noise()` |
| Audio | `love.audio` |
| Graphics/sprites | `love.graphics` |
| Keyboard/mouse | `love.keyboard`, `love.mouse` |
| Filesystem | `love.filesystem` |
| Timers | `love.timer` |

- [ ] Checked Love2D documentation for built-in features
- [ ] Verified built-in features won't work for this use case

### 4. Evaluate Library Options

For each candidate library, check:

- [ ] **GitHub stars**: > 100 stars preferred
- [ ] **Last updated**: Within last 2 years
- [ ] **License**: MIT, Apache, BSD (compatible)
- [ ] **Dependencies**: Minimal or none
- [ ] **Love2D compatibility**: Works with 11.5+
- [ ] **Size**: Check file size (prefer < 1000 lines for single file)
- [ ] **Documentation**: Has README/wiki with examples
- [ ] **Issues**: Active maintenance, low critical bugs

### 5. Test in Isolation

- [ ] Create a test file in `tests/lib_test_<name>.lua`
- [ ] Test basic functionality
- [ ] Measure performance impact if critical
- [ ] Verify it works in your environment

### 6. Make Decision

Decision Matrix:

| Criteria | Weight | Score (1-5) | Notes |
|----------|--------|-------------|-------|
| Solves exact problem | 5x | ___ | |
| Well maintained | 3x | ___ | |
| Lightweight | 2x | ___ | |
| Good docs | 2x | ___ | |
| Community support | 1x | ___ | |
| **Total** | | **___** | |

- Score 40+: Use the library
- Score 25-39: Consider carefully
- Score < 25: Write custom code

- [ ] Calculated decision score
- [ ] Made final decision (use library / write custom)

### 7. Implementation

If using a library:

```bash
# Download to lib/
cd lib/
curl -O <library-url>

# Or use git submodule
git submodule add <repo-url> lib/<name>
```

- [ ] Library downloaded to `lib/` directory
- [ ] Added to `.gitignore` if needed (usually not)
- [ ] Tested `require("lib.<name>")` works
- [ ] Created wrapper/facade if needed

If writing custom:

- [ ] Documented why no library was suitable
- [ ] Kept implementation simple (< 200 lines preferred)
- [ ] Added comments explaining algorithm
- [ ] Wrote unit tests

### 8. Documentation

- [ ] Updated `LIBRARIES.md` if found new library
- [ ] Updated project docs if major dependency
- [ ] Added usage notes to relevant files
- [ ] Committed changes with clear message

## Common Holdfast Features → Libraries

Quick reference for typical features needed in this project:

| Feature Needed | Recommended Library | Alternative |
|----------------|-------------------|-------------|
| AABB collision detection | bump.lua | HC, custom |
| A* pathfinding | jumper | pathfun, custom |
| Sprite animation | anim8 | custom frames |
| Camera follow/zoom | gamera | STALKER-X, custom |
| Tweening/easing | flux | tween.lua |
| JSON save/load | dkjson | binser (binary) |
| Utility functions | lume | custom |
| Hot-reload code | lurker | love-hotswap |
| Perlin noise | love.math.noise | love-noise |
| UI menus | SUIT | Slab, custom |
| Audio management | ripple | custom |
| Networking | lua-enet | sock.lua |

## Questions to Ask Before Implementing

1. **Is this a solved problem?**
   - If yes → Use a library
   - If no → Consider if you need to solve it

2. **How complex is the algorithm?**
   - Simple (< 50 lines) → Write custom
   - Medium (50-200 lines) → Check for library first
   - Complex (> 200 lines) → Strongly prefer library

3. **How critical is performance?**
   - Critical → Profile library vs custom
   - Normal → Prefer library for development speed
   - Not critical → Definitely use library

4. **Will this need to scale?**
   - Yes → Use well-tested library
   - No → Custom is fine

5. **Is this core to the game?**
   - Core mechanic → Consider custom for full control
   - Supporting feature → Use library to save time

## Red Flags (Don't Use These Libraries)

- Last updated > 3 years ago
- No license or unclear license
- Requires complex build steps
- Only works with old Love2D versions
- Has critical unresolved issues
- Adds > 5MB to project size for simple features
- Requires many dependencies
- No examples or documentation

## Example Decision Process

### Example 1: Need collision detection

1. Search: `make find-lib FEATURE="collision"`
2. Results: box2d, bump.lua, HC
3. Evaluate:
   - box2d: Too heavy (full physics engine)
   - bump.lua: Perfect (AABB only, 400 lines, well maintained)
   - HC: Good but overkill (supports shapes we don't need)
4. Decision: **Use bump.lua**
5. Install: `curl -O https://raw.githubusercontent.com/kikito/bump.lua/master/bump.lua`

### Example 2: Need day/night cycle

1. Search: `make find-lib FEATURE="timer"`
2. Results: Some timing libraries, but none for day/night
3. Check built-in: `love.timer.getTime()` provides what we need
4. Complexity: ~30 lines of code
5. Decision: **Write custom** (too simple for library)

### Example 3: Need particle effects

1. Search: `make find-lib FEATURE="particles"`
2. Results: Some libraries, but...
3. Check built-in: `love.graphics.newParticleSystem()` exists!
4. Decision: **Use Love2D built-in**

## Maintenance

This workflow should be followed by:
- Developers implementing new features
- Claude when asked to add functionality
- Code reviewers checking PRs

Update this file if you discover:
- New useful libraries
- Better decision criteria
- Common pitfalls to avoid

---

**Last Updated**: 2026-03-15
**Owner**: Holdfast Development Team
