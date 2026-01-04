# DCS World Documentation

This repository contains documentation for DCS World mission design and scripting. The documentation is structured to serve two audiences: novice mission designers learning the tools, and developers (including AI agents) building automation and content.

## Learning Path

If you're new to DCS World mission creation, work through these documents in order:

1. **[Mission Editor Guide](mission-editor.md)** - Learn the graphical interface for creating missions, including unit placement, route planning, triggers, and AI tasking
2. **[Lua Basics](scripting/lua-basics.md)** - Essential Lua programming concepts for scripting
3. **[Simulator Scripting Engine](scripting/simulator-scripting-engine.md)** - Programmatic mission control through the SSE API
4. **Reference Documentation** - Detailed API documentation for specific functions and objects

## Documentation Structure

### Tutorials

| Document | Description |
|----------|-------------|
| [mission-editor.md](mission-editor.md) | Guide to the Mission Editor GUI for creating scenarios |
| [scripting/lua-basics.md](scripting/lua-basics.md) | Lua language fundamentals for DCS scripting |
| [scripting/simulator-scripting-engine.md](scripting/simulator-scripting-engine.md) | Overview of the SSE scripting API |

### Mission File Format

| Document | Description |
|----------|-------------|
| [mission/miz-file-format.md](mission/miz-file-format.md) | Structure of .miz mission archives |
| [mission/mission-file-schema.md](mission/mission-file-schema.md) | Schema for the mission Lua table |

### Scripting API Reference

The [scripting/reference/](scripting/reference/) directory contains detailed API documentation organized by category:

**Singletons** (Global namespace objects)
- [env](scripting/reference/singletons/env.md) - Logging and environment information
- [timer](scripting/reference/singletons/timer.md) - Mission time and scheduled functions
- [world](scripting/reference/singletons/world.md) - Event handlers and object searches
- [coalition](scripting/reference/singletons/coalition.md) - Coalition-related operations
- [trigger](scripting/reference/singletons/trigger.md) - Trigger zones and actions
- [coord](scripting/reference/singletons/coord.md) - Coordinate conversions
- [land](scripting/reference/singletons/land.md) - Terrain queries
- [atmosphere](scripting/reference/singletons/atmosphere.md) - Weather conditions
- [missionCommands](scripting/reference/singletons/mission-commands.md) - F10 radio menu

**Classes** (Object types)
- [Unit](scripting/reference/classes/unit.md) - Aircraft, vehicles, ships
- [Group](scripting/reference/classes/group.md) - Collections of units
- [Object](scripting/reference/classes/object.md) - Base object type
- [CoalitionObject](scripting/reference/classes/coalition-object.md) - Objects with coalition affiliation
- [StaticObject](scripting/reference/classes/static-object.md) - Non-moving scenery
- [Airbase](scripting/reference/classes/airbase.md) - Airports, FARPs, carriers
- [Weapon](scripting/reference/classes/weapon.md) - Missiles, bombs, projectiles
- [Controller](scripting/reference/classes/controller.md) - AI behavior control
- [Spot](scripting/reference/classes/spot.md) - Laser and IR designators

**Other Reference**
- [events/events.md](scripting/reference/events/events.md) - Event system reference
- [ai/tasks.md](scripting/reference/ai/tasks.md) - AI task definitions
- [ai/commands.md](scripting/reference/ai/commands.md) - AI command definitions
- [ai/options.md](scripting/reference/ai/options.md) - AI behavior options
- [enums/coalition.md](scripting/reference/enums/coalition.md) - Coalition enumeration
- [enums/ai.md](scripting/reference/enums/ai.md) - AI-related enumerations
- [types/coordinates.md](scripting/reference/types/coordinates.md) - Vec2, Vec3, Position3 types
- [hooks/server-hooks.md](scripting/reference/hooks/server-hooks.md) - Server-side scripting

### Unit Reference

The [units/](units/) directory contains equipment and capability data:

| Document | Description |
|----------|-------------|
| [units/ground.md](units/ground.md) | Ground vehicles, armor, artillery, air defense, infantry |
| [units/sea.md](units/sea.md) | Ships, carriers, submarines |
| [units/planes.md](units/planes.md) | Fixed-wing aircraft with pylons and loadouts |
| [units/weapons.md](units/weapons.md) | Missiles, bombs, rockets |

## Source Data

This documentation is compiled from multiple sources:

- **Datamined data** (`data/` directory) - Current information extracted from the simulator
- **PDF manuals** (`pdf/` directory) - Official documentation for older DCS versions

When sources conflict, trust datamined sources over PDF manuals, as PDFs may contain outdated information.
