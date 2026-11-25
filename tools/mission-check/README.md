# mission-check

Validates a DCS MIZ file or unpacked MIZ directory. Validation includes:

- The `mission`, `warehouses`, `dictionary`, and `mapResource` files exist and
  parse as Lua, and `options` parses when present
- `mission.theatre` matches the `theatre` file when present
- The `mission` table matches the schema
- Warehouse entries for airfields, ships, and FARPs are valid
- Groups and units have the required fields, and valid `skill` and `alt_type`
  values. Static units have no `skill`.
- Dynamic spawn templates are valid
- Group and unit IDs are unique
- Airfield references are consistent
- Each country is assigned to the coalition it is placed under, and to only one
  coalition
- Units starting from airfield parking have `parking` (a string or integer) and
  a string `parking_id`
- TACAN beacons have a valid channel and mode, a `system` that matches the
  mode, and a frequency that matches the channel
- Every `DictKey_*` and `ResKey_*` in the mission exists in `dictionary` and
  `mapResource`, every `mapResource` file exists, and no dictionary ID is
  greater than `maxDictId`

## Usage

You must use [uv](https://docs.astral.sh/uv/) to run this tool. Trying to run it
with just `python check_mission.py` will not work.

```bash
# Check an extracted mission directory
uv run check-mission check ../../missions/operation-infinity/src
# Check a packed .miz file
uv run check-mission check ~/Saved\ Games/DCS/Missions/example.miz
```

The tool exits with status 0 when the mission passes, 1 when a check fails, and
2 when the path is missing or is not a directory or `.miz` file.

## Development

```bash
# Install the tool and the dev dependencies (ruff, ty, pytest)
uv sync --group dev
# Run the tests
uv run pytest
# Lint the code
uv run ruff check .
# Type check the code
uv run ty check
```
