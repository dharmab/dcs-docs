# DCS World Documentation

This directory contains documentation for DCS World mission design and scripting. It is written for two audiences: novice mission designers learning the tools, and developers (including AI agents) building automation and content.

## Learning Path

If you're new to DCS World mission creation, work through these documents in order:

1. **[Mission Editor Guide](mission-editor.md)** - Learn the graphical interface for creating missions, including unit placement, route planning, triggers, and AI tasking
2. **[Lua Basics](scripting/lua-basics.md)** - Essential Lua programming concepts for scripting
3. **[Simulator Scripting Engine](scripting/simulator-scripting-engine.md)** - Programmatic mission control through the SSE API
4. **[Scripting API Reference](#scripting-api-reference)** - Detailed API documentation for specific functions and objects

## Tutorials

| Document                                                                           | Description                                            |
| ---------------------------------------------------------------------------------- | ------------------------------------------------------ |
| [mission-editor.md](mission-editor.md)                                             | Guide to the Mission Editor GUI for creating scenarios |
| [scripting/lua-basics.md](scripting/lua-basics.md)                                 | Lua language fundamentals for DCS scripting            |
| [scripting/simulator-scripting-engine.md](scripting/simulator-scripting-engine.md) | Overview of the SSE scripting API                      |

## Mission File Format

| Document                                                         | Description                        |
| ---------------------------------------------------------------- | ---------------------------------- |
| [mission/miz-file-format.md](mission/miz-file-format.md)         | Structure of .miz mission archives |
| [mission/mission-file-schema.md](mission/mission-file-schema.md) | Schema for the mission Lua table   |

## Recipes

The [recipes/](recipes/) directory contains step-by-step guides for editing the mission Lua file directly.

| Document                                                           | Description                                                |
| ------------------------------------------------------------------ | ---------------------------------------------------------- |
| [recipes/weather-time.md](recipes/weather-time.md)                 | Weather, fog, haze, and time of day                        |
| [recipes/player-slots.md](recipes/player-slots.md)                 | Player aircraft slots at an airfield                       |
| [recipes/comm-plan.md](recipes/comm-plan.md)                       | Standard UHF frequency plan                                |
| [recipes/tanker-setup.md](recipes/tanker-setup.md)                 | Aerial refueling tankers with TACAN                        |
| [recipes/awacs-setup.md](recipes/awacs-setup.md)                   | AWACS and AEW&C aircraft                                   |
| [recipes/air-to-air-setup.md](recipes/air-to-air-setup.md)         | AI fighters for CAP, sweep, intercept, and escort          |
| [recipes/air-intercept-script.md](recipes/air-intercept-script.md) | Script that spawns interceptors when aircraft enter a zone |
| [recipes/sam-site-setup.md](recipes/sam-site-setup.md)             | SAM site composition and placement                         |
| [recipes/convoy-route.md](recipes/convoy-route.md)                 | Ground convoys that drive on roads                         |
| [recipes/artillery-battery.md](recipes/artillery-battery.md)       | Artillery battery that fires continuously at a point       |
| [recipes/ground-firefight.md](recipes/ground-firefight.md)         | Front-line firefight between AI ground forces              |
| [recipes/jtac-setup.md](recipes/jtac-setup.md)                     | AI JTACs and FACs for close air support                    |
| [recipes/csg-setup.md](recipes/csg-setup.md)                       | U.S. Navy carrier strike group                             |
| [recipes/restore-unit-life.md](recipes/restore-unit-life.md)       | Workarounds for healing a unit without `unit:setLife()`    |

## Mission Design

| Document               | Description                                          |
| ---------------------- | ---------------------------------------------------- |
| [wisdom.md](wisdom.md) | Mission design tips that don't fit a specific recipe |

## Scripting API Reference

The [scripting/reference/](scripting/reference/) directory contains detailed API documentation organized by category.

### Singletons

Singletons are global namespace objects.

| Document                                                              | Description                                |
| --------------------------------------------------------------------- | ------------------------------------------ |
| [env](scripting/reference/singletons/env.md)                          | Logging and environment information        |
| [timer](scripting/reference/singletons/timer.md)                      | Mission time and scheduled functions       |
| [world](scripting/reference/singletons/world.md)                      | Event handlers and object searches         |
| [coalition](scripting/reference/singletons/coalition.md)              | Coalition-related operations               |
| [trigger](scripting/reference/singletons/trigger.md)                  | Trigger zones and actions                  |
| [coord](scripting/reference/singletons/coord.md)                      | Coordinate conversions                     |
| [land](scripting/reference/singletons/land.md)                        | Terrain queries                            |
| [atmosphere](scripting/reference/singletons/atmosphere.md)            | Weather conditions                         |
| [missionCommands](scripting/reference/singletons/mission-commands.md) | F10 radio menu                             |
| [net](scripting/reference/singletons/net.md)                          | Chat, player information, and slot control |

### Classes

Classes are object types.

| Document                                                           | Description                        |
| ------------------------------------------------------------------ | ---------------------------------- |
| [Object](scripting/reference/classes/object.md)                    | Base object type                   |
| [CoalitionObject](scripting/reference/classes/coalition-object.md) | Objects with coalition affiliation |
| [Unit](scripting/reference/classes/unit.md)                        | Aircraft, vehicles, ships          |
| [Group](scripting/reference/classes/group.md)                      | Collections of units               |
| [StaticObject](scripting/reference/classes/static-object.md)       | Non-moving scenery                 |
| [Airbase](scripting/reference/classes/airbase.md)                  | Airports, FARPs, carriers          |
| [Weapon](scripting/reference/classes/weapon.md)                    | Missiles, bombs, projectiles       |
| [Spot](scripting/reference/classes/spot.md)                        | Laser and IR designators           |
| [Controller](scripting/reference/classes/controller.md)            | AI behavior control                |

### AI

| Document                                             | Description            |
| ---------------------------------------------------- | ---------------------- |
| [ai/tasks.md](scripting/reference/ai/tasks.md)       | AI task definitions    |
| [ai/commands.md](scripting/reference/ai/commands.md) | AI command definitions |
| [ai/options.md](scripting/reference/ai/options.md)   | AI behavior options    |

### Events

| Document                                                 | Description            |
| -------------------------------------------------------- | ---------------------- |
| [events/events.md](scripting/reference/events/events.md) | Event system reference |

### Types

| Document                                                         | Description                 |
| ---------------------------------------------------------------- | --------------------------- |
| [types/coordinates.md](scripting/reference/types/coordinates.md) | Vec2, Vec3, Position3 types |

### Enums

| Document                                                     | Description             |
| ------------------------------------------------------------ | ----------------------- |
| [enums/coalition.md](scripting/reference/enums/coalition.md) | Coalition enumeration   |
| [enums/ai.md](scripting/reference/enums/ai.md)               | AI-related enumerations |

### Server Hooks

| Document                                                           | Description           |
| ------------------------------------------------------------------ | --------------------- |
| [hooks/server-hooks.md](scripting/reference/hooks/server-hooks.md) | Server-side scripting |

## Unit Reference

The [units/](units/) directory contains equipment and capability data.

| Document                                         | Description                                              |
| ------------------------------------------------ | -------------------------------------------------------- |
| [units/planes/](units/planes/index.md)           | Fixed-wing aircraft with pylons and loadouts             |
| [units/helicopters/](units/helicopters/index.md) | Helicopters with pylons and loadouts                     |
| [units/ww2-planes.md](units/ww2-planes.md)       | World War II aircraft with pylons and loadouts           |
| [units/ground.md](units/ground.md)               | Ground vehicles, armor, artillery, air defense, infantry |
| [units/sea.md](units/sea.md)                     | Ships, carriers, submarines                              |
| [units/weapons.md](units/weapons.md)             | Missiles, bombs, rockets                                 |

## Factions

| Document                        | Description                                        |
| ------------------------------- | -------------------------------------------------- |
| [factions/](factions/README.md) | Unit lists for Strangereal nations from Ace Combat |

## Terrain Reference

| Document                                              | Description                                                                                    |
| ----------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| [terrain-geodata](../tools/terrain-geodata/README.md) | Projections, land cover and elevation rasters, and map features for every terrain as GIS files |

## Debugging

| Document                                    | Description                                                            |
| ------------------------------------------- | ---------------------------------------------------------------------- |
| [acmi-query](../tools/acmi-query/README.md) | Reading Tacview ACMI recordings to debug AI behavior and spawn scripts |
