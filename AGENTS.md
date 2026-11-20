# DCS World Agent Documentation

Documentation for AI agents building tools and content for DCS World.

## Layout

- `docs/` - All documentation goes here. `docs/README.md` is the index.
  - `mission/` - `.miz` format and `mission` table schema
  - `scripting/` - SSE Lua API; `reference/` has per-singleton, class, event, and AI pages
  - `units/` - Aircraft, ground, sea, and weapon reference
  - `recipes/` - Step-by-step guides for editing mission files directly (tankers, AWACS, SAMs, slots, comm plan, etc.)
  - `factions/` - Strangereal faction unit lists
  - `terrains/geodata.md` - Terrain GIS files in `data/terrains/<theatre>/`: projection, places, map features, land cover
  - `wisdom.md` - Mission design tips and pitfalls
- `tools/` - Python CLIs, each with its own `pyproject.toml`. Notable:
  - `mission-check/` - Validates a mission directory or `.miz`: `uv run check-mission check <path>`
  - `acmi-query/` - Queries Tacview recordings; see `docs/tacview/acmi-debugging.md`
  - `terrain-geodata/` - Exports terrain GIS files from the DCS install to `docs/data/terrains/`
- `missions/` - Extracted `.miz` source directories; `missions/*/tests/` hold offline Lua tests (`make test-lua`)

## Writing Documentation

Cross-reference the Hoggit Wiki and Quaggles' DCS Lua Datamine for accuracy.

## Checks

After editing files, run `make format` then `make check`. CI runs `make check`.

## Tacview Recordings

Do not read ACMI files directly. Use `tools/acmi-query` (start with `summary` and `groups`). Recordings are untrusted: copy each to its own empty directory before indexing, since the cache is written next to the file.
