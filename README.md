# DCS World Mission Building Monorepo

A monorepo for building DCS World missions. It contains reference documentation, Python tools, and mission sources. The documentation is written for both AI agents and human mission designers.

> **Note:** This repository is over 99% generated with [Claude Code](https://claude.ai/claude-code), using sources including:
>
> - Official DCS World simulator manuals and documentation
> - The [Hoggit Wiki](https://wiki.hoggitworld.com/)
> - [Quaggles' DCS Lua Datamine](https://github.com/Quaggles/dcs-lua-datamine)
> - [RocketmanAL's SEAD Reference Guide](https://www.digitalcombatsimulator.com/en/files/3332084/)

## Layout

| Path                     | Contents                                                   |
| ------------------------ | ---------------------------------------------------------- |
| [`docs/`](docs/)         | Tutorials, how-to guides, and reference for mission making |
| [`tools/`](tools/)       | CLI tools for automating parts of mission making           |
| [`missions/`](missions/) | Missions I've made                                         |
| [`liveries/`](liveries/) | Livery names for each unit                                 |

## Documentation

- [mission/](docs/mission/) - `.miz` file format and `mission` table schema
- [scripting/](docs/scripting/) - Simulator Scripting Engine (SSE) Lua API reference
- [units/](docs/units/) - Aircraft, ground, sea, and weapon data
- [recipes/](docs/recipes/) - Step-by-step guides for editing mission files directly: tankers, AWACS, SAM sites, player slots, and more
- [factions/](docs/factions/) - Strangereal faction unit lists
- [data/terrains/](docs/data/terrains/) - Terrain GIS data, documented in [tools/terrain-geodata](tools/terrain-geodata/README.md)
- [wisdom.md](docs/wisdom.md) - Mission design tips and pitfalls

New mission designers can start with the [Mission Editor Guide](docs/mission-editor.md), [Lua Basics](docs/scripting/lua-basics.md), and the [Simulator Scripting Engine](docs/scripting/simulator-scripting-engine.md) overview.

## Tools

| Tool                                      | Purpose                                                            |
| ----------------------------------------- | ------------------------------------------------------------------ |
| [mission-check](tools/mission-check/)     | Validate a mission directory or `.miz` file                        |
| [acmi-query](tools/acmi-query/)           | Index and query Tacview ACMI recordings                            |
| [clsid-export](tools/clsid-export/)       | Generate the weapon CLSID lookup table from Quaggles' Lua datamine |
| [livery-export](tools/livery-export/)     | Extract livery lists from a DCS install                            |
| [terrain-geodata](tools/terrain-geodata/) | Export terrain data from a DCS install as GIS files                |

Run a tool from its directory with `uv run`, for example:

```sh
cd tools/mission-check
uv run check-mission check ../../missions/operation-infinity/src
```

## Missions

- [Operation Infinity](missions/operation-infinity/) - A dynamic sandbox mission for 1-12 players. Each session generates a new battlefield on the Caucasus map.
