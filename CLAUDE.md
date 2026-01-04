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
  - `csg-setup.md` - Creating a U.S. Navy Carrier Strike Group with Stennis, TACAN/ICLS configuration, and wind-aligned routes
  - `player-slots.md` - Adding player-controllable aircraft slots at airfields, including singleplayer slots, traditional multiplayer slots, and dynamic spawn templates

## Terminology

- **SSE** - Simulator Scripting Engine, the Lua scripting API for DCS World missions
- **MIZ** - The mission file format, a ZIP archive containing Lua tables and embedded resources
- **ME** - Mission Editor, the graphical interface for creating missions

## Generating Documentation

When creating new documentation:

1. Place all generated markdown files in the `docs/` directory
2. Cross-reference external sources such as the Hoggit Wiki and Quaggles' DCS Lua Datamine for accuracy
