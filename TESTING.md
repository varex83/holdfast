# Testing Phase 1 Systems

## How to Run

```bash
cd /Users/bogdanogorodniy/holdfast
love .
```

Or use the Makefile:
```bash
make run
```

## Test Mode

From the main menu, select **"Test Phase 1"** to enter the test environment.

## Controls

### Movement
- **WASD** or **Left Stick** - Move character
- **Arrow Keys** work too

### Combat
- **SPACE** or **Cross Button** - Attack
- **E** or **Square Button** - Use class ability

### Testing
- **1** - Switch to Warrior
- **2** - Switch to Archer
- **3** - Switch to Engineer
- **4** - Switch to Scout
- **T** - Spawn test enemy (for combat testing)
- **F3** - Toggle debug mode (shows hitboxes, states)
- **ESC** - Return to menu

## What's Being Tested

### Character Controller
- ✅ Movement with WASD/gamepad
- ✅ Smooth camera following
- ✅ State machine (idle, walking, attacking, dead)
- ✅ Character switching between classes

### Stats Component
- ✅ Class-specific stats (Warrior, Archer, Engineer, Scout)
- ✅ HP, armor, speed, attack values
- ✅ Damage calculation with armor reduction

### Health Component
- ✅ Damage and healing
- ✅ Health bar display
- ✅ Death and alive states
- ✅ Health regeneration (visible on health bars)

### Combat Manager
- ✅ Melee attacks (Warrior, Scout)
- ✅ Ranged attacks (Archer)
- ✅ Hit detection and damage application
- ✅ Attack cooldowns
- ✅ Knockback on hit
- ✅ Hit visualization (debug mode)

### Projectile System
- ✅ Arrow projectiles (Archer normal attack)
- ✅ Volley ability (5 arrows in arc)
- ✅ Collision detection
- ✅ Team-based filtering (no friendly fire)
- ✅ Projectile lifetime

### Cooldown System
- ✅ Attack cooldowns (varies by class)
- ✅ Ability cooldowns
- ✅ Global cooldown (GCD)

### Hitbox System
- ✅ AABB collision detection
- ✅ Hurtbox for receiving damage
- ✅ Team-based collision (player vs enemy)
- ✅ Debug visualization (F3 to toggle)

## Class Abilities

### Warrior (Press E)
- **Shield Bash** - Large knockback attack in front
- High damage (1.5x attack)
- Large area of effect
- 300 knockback force

### Archer (Press E)
- **Volley** - Fires 5 arrows in a wide arc
- Covers large area
- Great for hitting multiple enemies
- Each arrow does full damage

### Scout (Press E)
- **Cloak** - 3 seconds of invulnerability
- Cannot take damage while cloaked
- Good for escaping or resource gathering

### Engineer (Press E)
- **Self-Heal** - Restores 20 HP
- Engineer cannot attack
- Has highest speed for building/gathering

## Class Stats Comparison

| Class | HP | Armor | Speed | Attack | Range | Special |
|-------|-----|-------|-------|--------|-------|---------|
| **Warrior** | 200 | 10 | 80 | 25 | 50 (melee) | High survivability |
| **Archer** | 100 | 5 | 150 | 15 | 300 (ranged) | Ranged attacks |
| **Engineer** | 80 | 3 | 180 | 0 | 0 | Cannot attack, fastest |
| **Scout** | 120 | 3 | 200 | 8 | 40 (dagger) | Highest speed & carry |

## Testing Workflow

1. **Start the game** - Select "Test Phase 1"
2. **Test movement** - Move around with WASD
3. **Switch classes** - Press 1-4 to test each class
4. **Spawn enemies** - Press T to spawn test enemies nearby
5. **Test combat** - Use SPACE to attack enemies
6. **Test abilities** - Press E to use class-specific abilities
7. **Enable debug** - Press F3 to see hitboxes and internal state
8. **Observe systems**:
   - Health bars decrease when hit
   - Enemies get knocked back
   - Projectiles fly and hit targets
   - Stats differ between classes
   - Cooldowns prevent spam attacks

## Debug Mode (F3)

When debug mode is enabled, you'll see:
- **Green boxes** - Character hitboxes (hurtboxes)
- **Red boxes** - Active attack hitboxes
- **Yellow lines** - Character facing direction
- **State text** - Character state (idle, walking, attacking, dead)
- **Console output** - Damage numbers, events

## Known Behaviors

- Engineer cannot attack (as designed)
- Enemies don't move yet (AI is Phase 2)
- No world/tiles yet (world gen is Phase 2)
- All combat is functional but enemies are stationary targets

## What to Look For

### ✅ Working Features
- Smooth character movement
- Accurate hitbox collision
- Damage calculation with armor
- Health regeneration over time
- Projectiles spawn and fly correctly
- Volley ability fires 5 arrows
- Knockback pushes entities away
- Different stats per class
- Attack cooldowns prevent spam

### 🐛 Report Issues
If you encounter errors or unexpected behavior, check the console output for error messages. Common issues might be:
- Missing component errors
- Nil reference errors
- Collision detection problems
- Rendering issues

## Next Steps

After Phase 1 is verified working:
- Phase 2: Add pathfinding, enemy AI, resource gathering
- Phase 3: Day/night cycle, wave spawning
- Phase 4: Boss enemies, advanced abilities

---

**Phase 1 Complete!** All core combat systems are functional and ready for gameplay integration.
