# DCS World Agent Documentation

This repository contains documentation for AI agents to use as context when generating tools and content for the flight simulator "DCS World".

## Directory Structure

- `docs/` - Generated markdown documentation. All documentation output should be placed here.

## Available Documentation

The `docs/` directory contains the following documentation:

- `mission/` - Mission file format documentation:
  - `miz-file-format.md` - The .miz archive format, including the structure of contained files (mission, theatre, warehouses, options, l10n resources)
  - `mission-file-schema.md` - Complete schema reference for the `mission` Lua table, documenting all top-level keys and nested structures
- `mission-editor.md` - Guide to the DCS World Mission Editor GUI, including unit placement, waypoints, tasking, and triggers
- `scripting/` - Scripting and automation documentation:
  - `simulator-scripting-engine.md` - The SSE Lua scripting API for programmatic mission control
  - `lua-basics.md` - Lua language basics for DCS scripting
  - `reference/` - API reference documentation:
    - `singletons/` - Global namespace objects (world, trigger, coalition, timer, env, coord, land, atmosphere, mission-commands)
    - `classes/` - Object types (Unit, Group, Object, Airbase, Weapon, Controller, Spot, StaticObject, CoalitionObject)
    - `events/` - Event system reference
    - `ai/` - AI control system (tasks, commands, options)
    - `enums/` - Enumerations (coalition, AI enums)
    - `types/` - Type definitions (Vec2, Vec3, Position3)
    - `hooks/` - Server-side scripting hooks
- `units/` - Unit and equipment reference documentation:
  - `ground.md` - Ground units including vehicles, armor, artillery, air defense systems, and infantry
  - `helicopters.md` - Rotary-wing aircraft with sensors, armament, and capabilities
  - `sea.md` - Naval units including carriers, destroyers, submarines, and civilian vessels
  - `planes.md` - Fixed-wing aircraft with pylons, loadouts, and capabilities
  - `ww2-planes.md` - World War II era fixed-wing aircraft with pylons, loadouts, and capabilities
  - `weapons.md` - Weapons systems including missiles, bombs, and rockets
- `recipes/` - Step-by-step guides for common mission setup tasks (for AI agents editing mission files directly):
  - `air-intercept-script.md` - Dynamic air intercept script that spawns enemy interceptors from red airfields when players enter defense zones, with scaled response and customizable aircraft/loadouts
  - `air-to-air-setup.md` - Configuring AI fighter aircraft for Combat Air Patrol, Fighter Sweep, Intercept, and Strike Escort roles with proper tasking and AI options
  - `artillery-battery.md` - Creating artillery batteries with continuous fire for visual spectacle and SEAD/DEAD gameplay
  - `awacs-setup.md` - Configuring AWACS/AEW&C aircraft with orbit patterns, EPLRS datalink, and radio frequencies
  - `csg-setup.md` - Creating a U.S. Navy Carrier Strike Group with Stennis, TACAN/ICLS configuration, and wind-aligned routes
  - `ground-firefight.md` - Setting up dramatic front-line firefights with sustained suppressive fire using FireAtPoint tasks
  - `jtac-setup.md` - Configuring AI JTACs and FACs for Close Air Support with laser designation, smoke marking, and radio communication
  - `player-slots.md` - Adding player-controllable aircraft slots at airfields, including singleplayer slots, traditional multiplayer slots, and dynamic spawn templates
  - `sam-site-setup.md` - Deploying SAM sites with proper radar/launcher compositions, layered defense placement, and IADS configuration
- `wisdom.md` - General mission design tips and best practices covering performance, player experience, AI behavior, and common pitfalls
- `factions/` - Faction unit lists for mission generation (Strangereal setting):
  - `isaf-2004.md` - ISAF during the Early Continental War
  - `erusea-2004.md` - Erusea during the Early Continental War
  - `isaf-2005.md` - ISAF during the Late Continental War
  - `erusea-2005.md` - Free Erusea during the Late Continental War
  - `osea-2010.md` - Osea during the Circum-Pacific War
  - `yuktobania-2010.md` - Yuktobania during the Circum-Pacific War
  - `belka-1995.md` - Belka during the Belkan War
  - `allied-forces-1995.md` - Allied Forces during the Belkan War

## Terminology

- **SSE** - Simulator Scripting Engine, the Lua scripting API for DCS World missions
- **MIZ** - The mission file format, a ZIP archive containing Lua tables and embedded resources
- **ME** - Mission Editor, the graphical interface for creating missions

## Generating Documentation

When creating new documentation:

1. Place all generated markdown files in the `docs/` directory
2. Cross-reference external sources such as the Hoggit Wiki and Quaggles' DCS Lua Datamine for accuracy
