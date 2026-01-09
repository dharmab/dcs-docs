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
- **Terrain Regions**: Mountain, hill, flat, valley regions with polygon vertices
- **Water Bodies**: Seas, lakes, reservoirs with boundaries
- **Settlements**: Detected from road density clustering
- **Connectivity**: Which regions connect via roads

## How This Works

This tool works in two stages: first, a script running inside DCS World collects raw terrain data; then, a Python program processes that data into useful geographic features like mountain ranges, valleys, and settlements.

### Why This Is Necessary

Some games give you direct access to their map data—you can ask "what cities are on this map?" and get a list back. DCS World doesn't work that way. The game knows where airports are, can tell you the elevation and surface type (land, water, road, or runway) at any point, and can find roads nearby, but it has no built-in way to say "here are all the interesting locations on this map."

So we have to figure it out ourselves. We sample thousands of elevation measurements across the map, then use algorithms to detect patterns: clusters of roads probably mean a town exists there, a region of steep terrain is probably a mountain range, and so on.

### Stage 1: Data Extraction (Inside DCS)

DCS World stores detailed terrain data internally, but there's no "export" button. The workaround is to run a script *inside* the game that queries terrain data point-by-point and saves the results.

When you load an export mission, an embedded script starts sampling the terrain after 30 seconds. Imagine dropping a surveyor onto the map who measures the ground elevation and surface type (land, water, or road) at thousands of locations arranged in a grid.

**Adaptive resolution** makes this efficient. Flat, featureless terrain doesn't need many measurements—a sample every 5 kilometers is enough. But mountainous areas with rapidly changing elevation need finer detail. The script works in three passes:

1. Sample the entire map at coarse spacing (5km apart)
2. Find "interesting" areas where elevation changes rapidly between neighboring samples, then resample those at 2.5km spacing
3. The most complex areas get a final pass at 1km spacing

This is the same principle behind image and video compression: spend more data on complex regions, less on simple ones.

The script also traces the road network and collects airport information (runway dimensions, parking spots). All this data gets saved as JSON—a structured text format that other programs can easily read.

### Stage 2: Processing (Python)

The Python script reads the JSON file and transforms raw numbers into geographic features.

**Building the elevation map:** The samples from different resolution passes get combined into a single grid. When multiple samples cover the same area, the finer-resolution measurement takes priority.

**Classifying terrain:** The script calculates two properties for each grid cell:

- *Slope* measures steepness—how quickly elevation changes as you move horizontally. A flat parking lot has near-zero slope; a cliff face has very high slope. This is calculated from the *gradient*, which is the rate of elevation change in each direction.

- *Prominence* measures how much a point rises above its surroundings. A 500-meter hill in flat Kansas has high prominence; a 500-meter bump in the Rockies might have low prominence because everything around it is also high.

These properties determine terrain type:
- Flat terrain has low slope (under 5°) regardless of absolute elevation—a high plateau is still "flat"
- Mountains have steep slopes (15°+) and high prominence
- Hills have moderate slope but aren't extreme enough to be mountains
- Valleys sit below the local average elevation in non-flat areas

**Finding distinct regions:** After classifying each grid cell, the code groups adjacent cells of the same type into regions. This uses *connected component labeling*, an algorithm that works like a flood-fill in image editing—start at one cell, spread to all neighbors of the same type, and mark them as one region. Each region gets a *convex hull* boundary, which is the smallest polygon that completely contains all the region's points (imagine stretching a rubber band around a set of pushpins).

**Detecting water bodies:** Water surfaces get grouped the same way. Large bodies touching the map edge are labeled "sea"; smaller interior bodies become "lakes."

**Finding settlements:** Real cities and towns don't exist in DCS's data, so we infer them from road density. The script uses *DBSCAN* (Density-Based Spatial Clustering of Applications with Noise), a clustering algorithm that finds groups of points packed closely together. Unlike some clustering methods, DBSCAN doesn't require you to specify how many clusters to find—it discovers them automatically by looking for dense neighborhoods. Clusters with enough road points are marked as settlements.

Settlement names come from their *MGRS grid location*. MGRS (Military Grid Reference System) divides the world into labeled grid squares; instead of inventing fake city names, each settlement is named after its grid coordinates.

**Analyzing connectivity:** The script checks which terrain regions roads connect. A *spatial index* makes this fast. Without an index, you'd have to check every road segment against every region—millions of comparisons. The spatial index divides the map into a grid of buckets; each road segment and region gets assigned to buckets based on its *bounding box* (the smallest rectangle that contains it). When checking connectivity, you only compare items that share a bucket.

The final output is a markdown document describing the map's geography in a format ready for AI-assisted mission generation.

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
