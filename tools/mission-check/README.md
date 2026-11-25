# mission-check

Validates a DCS MIZ file or unpacked MIZ directory. Validation includes:

- The required files exist and parse as Lua
- The `mission` table matches the schema
- Warehouse entries for airfields, ships, and FARPs are valid
- Groups and units have the required fields
- Dynamic spawn templates are valid
- Group and unit IDs are unique
- Airfield references are consistent

## Usage

You must use [uv](https://docs.astral.sh/uv/) to run this tool. Trying to run it
with just `python check_mission.py` will not work.

```bash
cd tools/mission-check
# Check an extracted mission directory
uv run check-mission check ../../missions/operation-infinity/src
# Check a packed .miz file
uv run check-mission check ~/Saved\ Games/DCS/Missions/example.miz
```

The tool exits with status 0 when the mission passes, 1 when a check fails, and
2 when the path is missing or is not a directory or `.miz` file.

## Development

```bash
# Install the tool and the dev dependencies (ruff, ty)
uv sync --group dev
# Lint the code
uv run ruff check .
# Type check the code
uv run ty check
```
