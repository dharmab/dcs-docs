# DCS World Agent Documentation

This repository contains documentation for AI agents and developers working with DCS World, the combat flight simulator. The documentation covers mission design, Lua scripting, file formats, and unit data.

> **Note:** This documentation is over 99% generated with [Claude Code](https://claude.ai/claude-code), using sources including:
> - Official DCS World simulator manuals and documentation
> - The [Hoggit Wiki](https://wiki.hoggitworld.com/)
> - [Quaggles' DCS Lua Datamine](https://github.com/Quaggles/dcs-lua-datamine)

## Who This Is For

**AI agents** building tools, generating missions, or automating tasks in DCS World. The structured reference documentation and machine-readable index (`docs/index.json`) support programmatic consumption.

**Novice mission designers** learning to create scenarios. The tutorial documents explain concepts progressively without assuming prior programming experience.

**Developers** building integrations, parsers, or scripting frameworks for DCS World.

## Getting Started

### For Mission Designers

Start with these documents in order:

1. [Mission Editor Guide](docs/mission-editor.md) - Learn the graphical interface for creating missions
2. [Lua Basics](docs/scripting/lua-basics.md) - Essential programming concepts for scripting
3. [Simulator Scripting Engine](docs/scripting/simulator-scripting-engine.md) - Programmatic mission control

### For AI Agents

The documentation index at [docs/index.json](docs/index.json) provides a structured manifest of all files with metadata including type, audience, and description.

Reference documentation follows consistent patterns:
- API methods include signatures, parameters, return types, and examples
- Cross-references via "See Also" sections connect related concepts
- Categorical organization under `docs/scripting/reference/` aids discovery

### For Developers

Key reference materials:
- [MIZ File Format](docs/mission/miz-file-format.md) - Mission archive structure
- [Mission File Schema](docs/mission/mission-file-schema.md) - Mission Lua table specification
- [Unit Reference](docs/units/) - Equipment specifications and capabilities

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
└── units/                    # Unit specifications
    ├── ground.md             # Ground vehicles and air defense
    ├── sea.md                # Naval units
    ├── planes.md             # Fixed-wing aircraft
    └── weapons.md            # Weapons systems

data/                         # Datamined source data
pdf/                          # Legacy PDF manuals
```

## Source Data

Documentation is compiled from multiple sources with different trust levels:

1. **Datamined data** (`data/`) - Extracted from current simulator versions, most reliable
2. **PDF manuals** (`pdf/`) - Official but potentially outdated documentation

When sources conflict, prefer datamined data over PDF content.
