# AGENTS.md
## Project: **Holdfast** *(working title)*

> A 2D cooperative survival game built with Love2D. Gather resources by day, defend your base by night. Built in Lua with a top-down isometric perspective inspired by Factorio and The Forest.

---

## Table of Contents

1. [Overview](#overview)
2. [Core Pillars](#core-pillars)
3. [World & Perspective](#world--perspective)
4. [Characters & Classes](#characters--classes)
5. [Resources](#resources)
6. [Base Building](#base-building)
7. [Night Waves](#night-waves)
8. [Game Loop](#game-loop)
9. [Multiplayer](#multiplayer)
10. [Technical Stack](#technical-stack)
11. [Lua / Love2D Development Prompts](#lua--love2d-development-prompts)
12. [Stretch Goals](#stretch-goals)

---

## Overview

**Holdfast** is a 2D cooperative survival game built with **Love2D**, rendered in a top-down isometric style inspired by Factorio. Players work together to manually gather resources, build and upgrade a shared base, and survive increasingly difficult monster attacks each night. During the day, players venture out to collect materials and fortify defenses. At night, they must hold the line.

---

## Core Pillars

1. **Cooperative Survival** — Players share a base and must coordinate roles to survive.
2. **Manual Resource Collection** — No automation; players physically travel to resource nodes and carry materials back.
3. **Progressive Threat** — Each night wave is harder than the last. The pressure never stops.
4. **Base Building** — The base is freely editable. Players place, upgrade, and repair structures as they see fit.
5. **Role Diversity** — Each character class has a distinct niche; no single class can do everything.

---

## World & Perspective

- **View:** Top-down isometric-style (Factorio-like), 2D sprites with depth illusion via layering and tile offsets.
- **World:** Procedurally generated infinite map with biomes containing different resource distributions.
- **Day/Night Cycle:** Fixed-length days (~10–15 minutes real time). Night triggers a wave. Repeats infinitely.
- **Infinite Generation:** The world extends infinitely in all directions. Resources respawn on a timer far from the base.

---

## Characters & Classes

Players choose a class at session start. Respeccing requires a Workshop structure and a cooldown.

### Warrior
| Stat | Value |
|------|-------|
| Attack | High (melee, short range) |
| Armor | High |
| HP | High |
| Speed | Low |

**Ability — Shield Bash:** Knocks back a group of enemies in a short cone, briefly stunning them.

---

### Archer
| Stat | Value |
|------|-------|
| Attack | Medium (ranged, medium range) |
| Armor | Medium |
| HP | Low |
| Speed | Medium |

**Ability — Volley:** Fires a spread of arrows in a wide arc, hitting multiple targets simultaneously.

---

### Engineer
| Stat | Value |
|------|-------|
| Attack | None (cannot fight) |
| Armor | Low |
| HP | Low |
| Speed | High |

**Ability — Construct:** The only class able to place and upgrade buildings. Can repair structures mid-combat. Carries a limited build inventory.

---

### Scout
| Stat | Value |
|------|-------|
| Attack | Low (dagger, very short range) |
| Armor | Low |
| HP | Medium |
| Speed | High |

**Ability — Cloak:** Becomes invisible to enemy units for a short duration. Used to safely collect resources, scout monster spawn locations, or slip through enemy lines at night. Cooldown resets on return to base.

---

## Resources

Resources are gathered manually and physically carried back to base. Each player has a weight-limited carry capacity (Scouts carry most efficiently; Warriors least).

| Resource | Source | Primary Use |
|----------|--------|-------------|
| **Wood** | Trees / forests | Walls, floors, basic structures |
| **Iron** | Ore nodes / caves | Weapons, reinforced walls, traps |
| **Rope** | Fiber plants / reeds | Bridges, catapults, archer towers |
| **Stone** | Rock outcrops | Foundations, towers, heavy walls |
| **Food** | Berry bushes / hunting | Player stamina / HP regen |
| **Cloth** | Cotton plants | Bandages, armor upgrades |

A **Supply Depot** building at base stockpiles resources for Engineer use.

---

## Base Building

The base is a freely editable shared space. Only Engineers can place or upgrade structures; all players can interact with them.

### Defensive Structures
| Structure | Notes |
|-----------|-------|
| Wooden / Stone / Reinforced Wall | Upgrade tiers; higher tiers resist Brutes and Wraiths |
| Arrow Tower | Manned by Archer for full rate-of-fire; auto-fires at reduced rate when empty |
| Spike Trap / Bear Trap | Placed in choke points; single-use, reloadable |
| Gate | Lockable; can be opened/closed by any player |
| Moat | Dug by Engineer; fill with water (slow) or oil (ignitable) |

### Resource & Utility Structures
| Structure | Notes |
|-----------|-------|
| Supply Depot | Central resource storage shared by all players |
| Campfire / Forge | Passive HP regen zone; required for crafting gear |
| Watchtower | Clears fog of war in a radius around it |
| Workshop | Enables gear and ability upgrades; required for respeccing |

### Upgrade System
- All structures have **3 upgrade tiers** (Wood → Stone → Reinforced).
- Upgrades require stored materials and Engineer labor time.
- Damaged structures lose effectiveness proportionally; must be repaired by an Engineer.
- The **Base Core** is the lose condition — if it's destroyed, the run ends.

---

## Night Waves

Every night, monsters spawn from the edges of the explored map and converge on the base. Wave difficulty scales with night number.

### Monster Roster

| Monster | HP | Attack | Speed | Special |
|---------|----|--------|-------|---------|
| **Fly Swarm** | Very Low | Very Low | High | Massive groups; ignores traps; overwhelms through numbers |
| **Shambler** | Medium | Medium | Low | Basic ground unit; slowly breaks wooden walls |
| **Hound** | Low | Medium | Very High | Fast flanker; targets isolated players |
| **Brute** | High | High | Low | Smashes structures directly; prioritizes walls over players |
| **Spitter** | Low | Medium (ranged) | Medium | Hangs back and pelts defenses; must be pushed out |
| **Wraith** | Medium | High | High | Phases through wooden walls; countered by stone or torchlight |
| **Siege Beast** *(boss)* | Very High | Very High | Very Low | Appears on milestone nights (10, 20, 30…); requires full team coordination |

### Difficulty Scaling

| Nights | Active Monster Types | Notes |
|--------|---------------------|-------|
| 1–3 | Fly Swarms, Shamblers | Small groups, single direction |
| 4–7 | + Hounds, Spitters | Groups grow; flanking begins |
| 8–9 | + Brutes | Multi-direction assaults |
| 10, 20, 30… | All types + Siege Beast | Boss wave; flat stat buff applies |
| Every 5 nights | All types | +5% HP and damage across the board |

---

## Game Loop

```
DAY PHASE
├── Explore world (fog of war lifts as players move)
├── Gather resources — Scouts cloak to reach dangerous areas safely
├── Carry resources back to base Supply Depot
├── Engineer places / upgrades / repairs structures
├── Warriors and Archers escort gatherers or patrol perimeter
└── Nightfall timer counts down — all players converge on base

NIGHT PHASE
├── Monsters spawn from map edges and converge on base
├── Warriors hold melee chokepoints at gates
├── Archers man towers and target high-priority threats
├── Engineers repair damage in real time during the fight
├── Scouts use Cloak to flank, redirect, or assassinate Spitters
└── Wave ends when all monsters are dead

PROGRESSION
├── Each survived night unlocks new craftable structure types
├── Resources and base state persist between days
├── Dead players respawn at dawn (no permadeath by default)
└── Game ends if the Base Core structure is destroyed
```

---

## Multiplayer

- **Cooperative only** — no PvP.
- **Session-based** — players join a shared world hosted by one player or a dedicated server.
- **Persistent world option** — world state (day counter, base layout, resources) saves between sessions.
- **Recommended player count:** 1–4; scalable to 8 with proportionally larger wave sizes.

---

## Technical Stack

| Concern | Choice |
|---------|--------|
| Engine | Love2D (Lua) |
| Rendering | 2D isometric tile maps, sprite batching, painter's algorithm depth sort |
| Map Generation | Perlin noise biome generation, infinite chunk loading |
| Save System | Lua serialization to JSON per chunk; base state serialized separately |
| Networking *(future)* | lua-enet, client-server authoritative model |

---

## Stretch Goals

- **Seasonal modifiers** — blizzard nights slow players; fire nights spread to wooden structures.
- **NPC survivors** — find and rescue survivors in the world who perform passive base tasks.
- **Tech tree** — unlock new building tiers and character abilities by surviving milestone nights.
- **Asymmetric threat nights** — some nights spawn a single monster type in extreme numbers instead of mixed waves.
- **Underground layer** — caves with rare resources guarded by permanent monster spawners.
- **Turret automation** — Engineers can craft auto-turrets powered by a resource (e.g. iron) as a late-game option.