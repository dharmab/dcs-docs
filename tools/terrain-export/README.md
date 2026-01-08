# DCS Terrain Export Tool

Exports terrain and airport data from DCS World for use as LLM context in mission generation.

## Overview

This tool consists of two parts:

1. **Lua script** (`terrain-sampler.lua`) - Runs inside DCS to export raw terrain data
2. **Python script** (`process_terrain.py`) - Processes the export into markdown documentation

## Part A: DCS Export (Windows machine with DCS installed)

### Prerequisites

You must temporarily desanitize `MissionScripting.lua` to enable file I/O. By default, DCS disables the `io` and `lfs` Lua modules to prevent malicious scripts from accessing the filesystem. The terrain exporter needs these modules to write the JSON output file.

**Location:** Find `MissionScripting.lua` in your DCS installation:

- Steam: `C:\Program Files (x86)\Steam\steamapps\common\DCSWorld\Scripts\MissionScripting.lua`
- Standalone: `C:\Program Files\Eagle Dynamics\DCS World\Scripts\MissionScripting.lua`

**Before (default, sanitized):**

```lua
do
    sanitizeModule('os')
    sanitizeModule('io')
    sanitizeModule('lfs')
    _G['require'] = nil
    _G['loadlib'] = nil
    _G['package'] = nil
end
```

**After (desanitized for export):**

Comment out the `io` and `lfs` lines by adding `--` at the start:

```lua
do
    sanitizeModule('os')
    --sanitizeModule('io')
    --sanitizeModule('lfs')
    _G['require'] = nil
    _G['loadlib'] = nil
    _G['package'] = nil
end
```

### Re-sanitizing After Export

After you have finished exporting terrain data, you should restore the original `MissionScripting.lua` to re-enable security protections. This prevents untrusted missions from accessing your filesystem.

Either:
1. Remove the `--` comment markers you added, or
2. Restore from the backup copy you made before editing

If you regularly play multiplayer missions from untrusted sources, keeping the file sanitized is recommended.

### Running the Export

1. Copy `terrain-sampler.lua` to `Saved Games/DCS/Scripts/`

2. Copy the appropriate `.miz` file from `missions/` to your DCS Missions folder

3. Open DCS World and load the mission (e.g., `caucasus-terrain-export.miz`)

4. Run the mission (can be single player)

5. Wait for the "Terrain export complete!" message (may take 1-2 minutes for large maps)

6. Find the JSON output at:
   ```
   Saved Games/DCS/TerrainExport/{theatre}-terrain.json
   ```

7. Copy the JSON file to the machine running the Python processor

### Available Missions

Pre-generated export missions are provided in the `missions/` directory:

- `caucasus-terrain-export.miz`
- `syria-terrain-export.miz`
- `nevada-terrain-export.miz`
- `persiangulf-terrain-export.miz`
- `marianaislands-terrain-export.miz`
- `falklands-terrain-export.miz`
- `sinai-terrain-export.miz`
- `kola-terrain-export.miz`
- `afghanistan-terrain-export.miz`

To regenerate the missions (e.g., after modifying the trigger):

```bash
python generate_missions.py
```

### Export Contents

The Lua script exports:

- **Terrain grid samples** (5km resolution): elevation, surface type (land/water/road)
- **Road network**: road points and connectivity segments
- **Airbases**: name, position, category, parking spots (with Term_Index and Term_Type), runways

## Part B: Processing (machine with Python)

### Prerequisites

Install [uv](https://docs.astral.sh/uv/) for Python project management.

### Running the Processor

1. Place the JSON file in `tools/terrain-export/data/`

2. Run the processor:
   ```bash
   cd tools/terrain-export
   uv run process-terrain data/{theatre}-terrain.json -o ../../docs/maps/{theatre}.md
   ```

3. Review the generated markdown in `docs/maps/{theatre}.md`

### Output Format

The generated markdown includes:

- **Overview**: Map bounds, terrain summary statistics
- **Airports**: Full parking spot data with Term_Index, Term_Type, positions
- **Terrain Regions**: Mountain, hill, plain, valley regions with polygon vertices
- **Water Bodies**: Seas, lakes, reservoirs with boundaries
- **Settlements**: Detected from road density clustering
- **Connectivity**: Which regions connect via roads

## Supported Theatres

The Lua script has predefined bounds for:

- Caucasus
- Syria
- Nevada
- Persian Gulf
- Mariana Islands
- Falklands
- Sinai
- Kola
- Afghanistan

Other theatres will use fallback bounds and may need adjustment.

## Troubleshooting

### Export fails with "Could not open file"

Ensure MissionScripting.lua is properly desanitized and the DCS saved games folder is writable.

### Export takes very long

The default 5km grid resolution results in ~20,000 samples for large maps. This is intentional to balance detail with export time. You can increase `gridResolution` in the Lua script for faster exports with less detail.

### Missing airbases

The script only exports airbases that exist at mission start. Ships and FARPs placed in the mission will not appear unless they're part of the map's default configuration.

### Term_Type values

Parking spot `Term_Type` values indicate aircraft size restrictions. Common values observed:

- 16: Small aircraft
- 40: Medium aircraft (fighters)
- 68: Large aircraft (bombers, transports)
- 72: Helicopter pads
- 104: Hardened aircraft shelters

Exact values vary by airbase and should be validated against actual DCS behavior.
