# DCS World Scripting Documentation

This directory contains documentation for the DCS World Simulator Scripting Engine (SSE).

## Getting Started

If you're new to DCS scripting, read these documents in order:

1. **[lua-basics.md](lua-basics.md)** - Learn the Lua programming language fundamentals
2. **[simulator-scripting-engine.md](simulator-scripting-engine.md)** - Understand how scripts interact with the simulation
3. **API Reference** - Look up specific functions as needed

## API Reference

The [reference/](reference/) directory contains detailed documentation for every API element:

### Singletons

Global objects that provide access to game functionality:

| Singleton | Purpose |
|-----------|---------|
| [env](reference/singletons/env.md) | Logging and environment information |
| [timer](reference/singletons/timer.md) | Mission time and scheduled execution |
| [world](reference/singletons/world.md) | Event system and object queries |
| [coalition](reference/singletons/coalition.md) | Coalition-related operations |
| [trigger](reference/singletons/trigger.md) | Trigger zones and scripted actions |
| [coord](reference/singletons/coord.md) | Coordinate system conversions |
| [land](reference/singletons/land.md) | Terrain height and surface queries |
| [atmosphere](reference/singletons/atmosphere.md) | Weather conditions |
| [missionCommands](reference/singletons/mission-commands.md) | F10 radio menu management |

### Classes

Object types you'll work with in scripts:

| Class | Description |
|-------|-------------|
| [Unit](reference/classes/unit.md) | Aircraft, helicopters, ground vehicles, ships |
| [Group](reference/classes/group.md) | Collections of units |
| [Object](reference/classes/object.md) | Base class for all game objects |
| [CoalitionObject](reference/classes/coalition-object.md) | Objects with coalition affiliation |
| [StaticObject](reference/classes/static-object.md) | Non-moving scenery elements |
| [Airbase](reference/classes/airbase.md) | Airports, FARPs, and carriers |
| [Weapon](reference/classes/weapon.md) | Missiles, bombs, and projectiles |
| [Controller](reference/classes/controller.md) | AI behavior control interface |
| [Spot](reference/classes/spot.md) | Laser and IR designators |

### AI System

Documentation for controlling AI behavior:

| Document | Content |
|----------|---------|
| [tasks.md](reference/ai/tasks.md) | AI task definitions (attack, orbit, land, etc.) |
| [commands.md](reference/ai/commands.md) | AI instant commands (set frequency, activate beacon) |
| [options.md](reference/ai/options.md) | AI behavior options (ROE, reaction to threat) |

### Other Reference

| Document | Content |
|----------|---------|
| [events.md](reference/events/events.md) | Event types and handler registration |
| [coordinates.md](reference/types/coordinates.md) | Vec2, Vec3, and Position3 types |
| [coalition.md](reference/enums/coalition.md) | Coalition enumeration values |
| [ai.md](reference/enums/ai.md) | AI-related enumerations |
| [server-hooks.md](reference/hooks/server-hooks.md) | Server-side scripting (outside mission sandbox) |

## Scripting Environments

DCS provides two separate scripting environments:

**Mission Scripts** run inside the simulation sandbox with restricted filesystem access. Most of this documentation covers mission scripting.

**Server Hooks** run outside the sandbox with full system access. See [server-hooks.md](reference/hooks/server-hooks.md) for that API.

These environments cannot share state directly.
