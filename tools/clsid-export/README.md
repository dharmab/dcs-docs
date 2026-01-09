# CLSID Export Tool

Generates a bidirectional lookup table mapping DCS weapon display names to CLSIDs (Class IDs) used in mission files.

## Usage

```bash
cd tools/clsid-export
uv run generate-clsid-lookup
```

The script clones the latest [dcs-lua-datamine](https://github.com/Quaggles/dcs-lua-datamine) repository into a temporary directory, parses all launcher definitions, and outputs `docs/data/clsid-lookup.json`.

## Output Format

```json
{
  "version": "1.0.0",
  "dcs_version": "2.9.23.18431",
  "generated": "2026-01-09T12:00:00Z",
  "by_clsid": {
    "{BRU-32 GBU-24}": {
      "displayName": "GBU-24",
      "category": 1,
      "origin": "F-14B AI by Heatblur Simulations"
    }
  },
  "by_display_name": {
    "GBU-24": ["{BRU-32 GBU-24}"]
  }
}
```

The `by_display_name` index maps to arrays because multiple CLSIDs can share the same display name (different aircraft modules may define the same weapon differently).

## jq Examples

### Find CLSIDs for a weapon by display name

```bash
jq '.by_display_name["GBU-24"]' docs/data/clsid-lookup.json
```

### Find display name for a CLSID

```bash
jq '.by_clsid["{BRU-32 GBU-24}"].displayName' docs/data/clsid-lookup.json
```

### List all weapons containing "Maverick" (case-insensitive)

```bash
jq '.by_display_name | keys | map(select(test("Maverick"; "i")))' docs/data/clsid-lookup.json
```

### Get all CLSIDs for bombs (category 1)

```bash
jq '[.by_clsid | to_entries[] | select(.value.category == 1) | .key]' docs/data/clsid-lookup.json
```

### Find all weapons from a specific module

```bash
jq '[.by_clsid | to_entries[] | select(.value.origin | test("Heatblur")) | {clsid: .key, name: .value.displayName}]' docs/data/clsid-lookup.json
```

### Count weapons by category

```bash
jq '[.by_clsid | to_entries[] | .value.category] | group_by(.) | map({category: .[0], count: length})' docs/data/clsid-lookup.json
```

## Development

Install dependencies and run linting:

```bash
uv sync --group dev
uv run ruff check .
uv run ty check
```
