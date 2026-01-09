# DCS Terrain Export Tool

Exports terrain and airport data from DCS World for use as LLM context in mission generation.

## Overview

This tool consists of two parts:

1. **Mission files** (`missions/*.miz`) - Pre-built missions with embedded Lua script that exports terrain data
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

1. Copy the appropriate `.miz` file from `missions/` to your DCS Missions folder

2. Open DCS World and load the mission (e.g., `caucasus-terrain-export.miz`)

3. Run the mission (can be single player)

4. The terrain export script will automatically run 30 seconds after mission start

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

To regenerate the missions (e.g., after modifying the terrain sampler script):

```bash
uv run python generate_missions.py
```

The terrain sampler Lua script (`terrain-sampler.lua`) is embedded directly into each mission file during generation.

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

## How This Works

The terrain exporter is a two-stage pipeline that extracts geographic data from DCS World and transforms it into readable documentation.

Other flight simulators and games expose map features through discoverable APIs—Arma 3, for example, provides functions to query settlement locations, named areas, and points of interest. DCS World's scripting API is more limited. You can query airbases (via `world.getAirbases`), find nearby road points and compute paths along the road network (via `land.getClosestPointOnRoads` and `land.findPathOnRoads`), and sample terrain elevation and surface type at any coordinate. But there's no way to enumerate cities, towns, or named settlements; no API to list geographic regions or terrain features; and no method to discover "what significant locations exist on this map." This limitation is why we need a pipeline that samples the terrain exhaustively and then infers higher-level features (settlements, terrain regions, connectivity) through post-processing.

### Stage 1: Data Extraction (Lua inside DCS)

DCS World is a flight simulator with detailed 3D terrain data, but there's no direct way to export this data. The workaround is to run a Lua script *inside* DCS that queries the game's APIs and writes the results to a file.

When you load one of the export missions, the embedded Lua script wakes up 30 seconds after the mission starts and begins sampling the terrain. Think of it like dropping a virtual surveyor onto the map who methodically measures the elevation and surface type at thousands of points arranged in a grid pattern.

The script uses **adaptive resolution sampling** to balance detail against export time:

1. First, it samples the entire map at coarse resolution (5km between points).
2. It analyzes each coarse cell to identify "interesting" areas—places with high elevation variance, steep gradients between neighboring cells, or lots of road points.
3. Areas that score high on the interest metric get resampled at medium resolution (2.5km), and the most interesting areas get a fine pass (1km).

This is similar to how image compression works: flat, boring areas get fewer samples while complex terrain gets more detail.

The script also queries the game's road network API to find road points and trace connections between them, and it collects data about all the airports including runway dimensions and parking spots.

Everything gets serialized to JSON and written to a file in the DCS saved games folder.

### Stage 2: Processing (Python)

The Python processor reads the JSON and turns raw samples into higher-level features. This involves several image-processing and clustering techniques:

**Building the grid:** The multi-resolution samples get combined into a 2D elevation grid at the finest resolution. When samples overlap, the finer-resolution sample wins.

**Terrain classification:** The processor uses a sliding window to compute *local relief* (the difference between the highest and lowest points in a small neighborhood) and *local average elevation*. These features feed into simple threshold rules:
- Mountains: very high elevation, or moderate elevation with high relief
- Hills: moderate elevation, not already classified as mountain
- Plains: low elevation with low relief
- Valleys: lower than surrounding terrain, not fitting other categories

**Finding regions:** After classification, the code uses *connected component labeling* (a standard image-processing algorithm) to group adjacent cells of the same type into distinct regions. Each region gets a convex hull polygon that approximates its boundary.

**Water body detection:** Similar logic identifies connected areas of water surface type. Bodies touching the map edge and covering a large area are labeled "sea"; smaller interior bodies become "lakes" or "reservoirs."

**Settlement detection:** The processor runs DBSCAN clustering on the road point coordinates. DBSCAN groups points that are close together into clusters without needing to specify the number of clusters in advance—it just looks for dense neighborhoods. Clusters with enough road points become "settlements," named after their MGRS grid location.

**Connectivity analysis:** Road segments are checked to see which terrain regions they connect. A spatial index (a grid of buckets) makes this efficient—instead of checking every segment against every region, the code only checks against regions whose bounding boxes overlap the relevant grid cell.

The final output is a markdown document with tables and summaries ready for an AI model to use when generating missions.

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
