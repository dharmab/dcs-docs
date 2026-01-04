# DCS World Agent Documentation

This repository contains documentation for AI agents to use as context when generating tools and content for the flight simulator "DCS World".

## Directory Structure

- `pdf/` - PDF manuals for older versions of DCS World. These should be only partially trusted as the simulator has changed significantly since these were created.
- `data/` - Outputs from dataminers. These can be more accurately trusted since they are regularly updated with new simulator versions.
- `docs/` - Generated markdown documentation. All documentation output should be placed here.

## Available Documentation

The `docs/` directory contains the following documentation:

- `mission/` - Mission file format documentation:
  - `miz-file-format.md` - The .miz archive format, including the structure of contained files (mission, theatre, warehouses, options, l10n resources)
  - `mission-file-schema.md` - Complete schema reference for the `mission` Lua table, documenting all top-level keys and nested structures
- `mission-editor.md` - Guide to the DCS World Mission Editor GUI, including unit placement, waypoints, tasking, and triggers
- `scripting/` - Scripting and automation documentation:
  - `simulator-scripting-engine.md` - The SSE Lua scripting API for programmatic mission control
  - `concepts.md` - Fundamental concepts (coordinate systems, time values, angles)
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
  - `sea.md` - Naval units including carriers, destroyers, submarines, and civilian vessels
  - `planes.md` - Fixed-wing aircraft with pylons, loadouts, and capabilities
  - `weapons.md` - Weapons systems including missiles, bombs, and rockets

## Trust Hierarchy

When information conflicts between sources:

1. **Most trusted:** `data/` - Datamined information from current simulator versions
2. **Less trusted:** `pdf/` - Legacy PDF manuals that may contain outdated information

## Terminology

- **SSE** - Simulator Scripting Engine, the Lua scripting API for DCS World missions
- **MIZ** - The mission file format, a ZIP archive containing Lua tables and embedded resources
- **ME** - Mission Editor, the graphical interface for creating missions

## Generating Documentation

When creating new documentation:

1. Place all generated markdown files in the `docs/` directory
2. Cross-reference datamined data in `data/` for accuracy
3. Use PDF manuals in `pdf/` as supplementary context, but verify against datamined sources when possible
4. Note any discrepancies between sources in the documentation
