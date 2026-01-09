# DCS World Agent Documentation

This repository contains documentation for AI agents and developers working with DCS World, the combat flight simulator. The documentation covers mission design, Lua scripting, file formats, and unit data.

> **Note:** This documentation is over 99% generated with [Claude Code](https://claude.ai/claude-code), using sources including:
> - Official DCS World simulator manuals and documentation
> - The [Hoggit Wiki](https://wiki.hoggitworld.com/)
> - [Quaggles' DCS Lua Datamine](https://github.com/Quaggles/dcs-lua-datamine)
> - [RocketmanAL's SEAD Reference Guide](https://www.digitalcombatsimulator.com/en/files/3332084/)

## Who This Is For

**AI agents** building tools, generating missions, or automating tasks in DCS World. The structured reference documentation and machine-readable index (`docs/index.json`) support programmatic consumption.

**Novice mission designers** learning to create scenarios. The tutorial documents explain concepts progressively without assuming prior programming experience.

## Getting Started

### For Mission Creators

Start with these documents in order:

1. [Mission Editor Guide](docs/mission-editor.md) - Learn the graphical interface for creating missions
2. [Lua Basics](docs/scripting/lua-basics.md) - Essential programming concepts for scripting
3. [Simulator Scripting Engine](docs/scripting/simulator-scripting-engine.md) - Programmatic mission control

The [recipes](docs/recipes/) directory contains step-by-step guides for common mission setup tasks like configuring AWACS, tankers, carrier groups, and SAM sites.

### For AI Agents

The documentation index at [docs/index.json](docs/index.json) provides a structured manifest of all files with metadata including type, audience, and description.

Reference documentation follows consistent patterns:
- API methods include signatures, parameters, return types, and examples
- Cross-references via "See Also" sections connect related concepts
- Categorical organization under `docs/scripting/reference/` aids discovery

## Repository Structure

```
docs/
├── README.md                 # Documentation index
├── index.json                # Machine-readable file manifest
├── mission-editor.md         # Mission Editor tutorial
├── mission/                  # File format specifications
├── scripting/                # Scripting documentation
│   ├── lua-basics.md         # Lua language primer
│   ├── simulator-scripting-engine.md  # SSE overview
│   └── reference/            # API reference
│       ├── singletons/       # Global objects (env, timer, world, etc.)
│       ├── classes/          # Object types (Unit, Group, Airbase, etc.)
│       ├── events/           # Event system
│       ├── ai/               # AI control (tasks, commands, options)
│       ├── enums/            # Enumerations
│       ├── types/            # Type definitions
│       └── hooks/            # Server-side scripting
├── units/                    # Unit specifications
│   ├── ground.md             # Ground vehicles and air defense
│   ├── helicopters.md        # Rotary-wing aircraft
│   ├── sea.md                # Naval units
│   ├── planes.md             # Fixed-wing aircraft
│   ├── ww2-planes.md         # WWII-era aircraft
│   └── weapons.md            # Weapons systems
├── recipes/                  # Step-by-step mission setup guides
│   ├── air-intercept-script.md
│   ├── artillery-battery.md
│   ├── awacs-setup.md
│   ├── csg-setup.md
│   ├── ground-firefight.md
│   ├── player-slots.md
│   ├── sam-site-setup.md
│   └── tanker-setup.md
└── factions/                 # Fictional faction unit lists (Strangereal)
    ├── allied-forces-1995.md
    ├── belka-1995.md
    ├── erusea-2004.md
    ├── erusea-2005.md
    ├── isaf-2004.md
    ├── isaf-2005.md
    ├── osea-2010.md
    └── yuktobania-2010.md
```
