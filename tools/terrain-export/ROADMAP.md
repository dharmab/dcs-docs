# Terrain Export Tool Roadmap

Improvements to be addressed over multiple sessions.

## Lua Script (terrain-sampler.lua)

### [x] Road sampling ignores dynamic bounds detection (2026-01-09)

`sampleRoads()` at line 557 calls `getBounds()` directly instead of using dynamic bounds detection like `sampleGrid()` does. Road sampling may use incorrect bounds when `config.detectBounds = true`.

**Fix:** Check `self.config.detectBounds` and use `detectBoundsFromOrigin()` if enabled, or cache the detected bounds from the terrain sampling phase and reuse them.

**Resolution:** Modified `sampleGrid()` to cache detected bounds in `self.state.detectedBounds`. Updated `sampleRoads()` to use cached bounds first, falling back to dynamic detection or predefined bounds if unavailable.

### [x] Blocking road connectivity phase (2026-01-09)

Lines 749-788 compute road connectivity in a synchronous loop. For maps with many road points, this could cause DCS to freeze or timeout.

**Fix:** Convert to chunked processing like the sampling phases, using `timer.scheduleFunction` to yield between batches.

**Resolution:** Extracted the connectivity computation into a separate `connectivityChunkProcessor` function that tracks state (`connectivityIIndex`, `connectivityJIndex`, `connectivitySegments`, `connectivitySegmentCount`) across scheduled chunks. The processor yields after hitting the sample or time limit, then resumes from where it left off.

### [x] Unused variable (2026-01-09)

Line 249: `prevHeight` is assigned but never used in `detectBoundsFromOrigin()`.

**Fix:** Remove the unused variable.

**Resolution:** Removed the `prevHeight` declaration and its assignment inside the loop.

### [x] Verbose control flow pattern (2026-01-09)

The `repeat...until true` pattern (lines 434, 617, etc.) is used as a break-from-block substitute.

**Fix:** Extract the sampling logic into separate helper functions that return early instead of using the repeat/break pattern.

**Resolution:** Extracted the terrain sampling logic into `sampleTerrainPoint()` and road sampling logic into `sampleRoadPoint()`. Both helper functions handle validation and error logging internally, returning the sample data or nil on failure. The main loop code now simply calls the helper and checks for a non-nil result.

### [x] Magic numbers (2026-01-09)

Several constants are embedded in the code:
- `0.75` distance factor on line 651
- `8` for road neighbor count on line 755
- Various other threshold values

**Fix:** Move these to the config table with descriptive names.

**Resolution:** Added three new config options: `roadProximityFactor` (0.75), `roadNeighborCount` (8), and `connectivityProgressInterval` (50). Updated `sampleRoadPoint()` and `connectivityChunkProcessor()` to use these config values instead of hardcoded numbers.

### [x] Include script version in JSON output (2026-01-09)

The script version is defined (`TerrainSampler.VERSION`) but not included in the export.

**Fix:** Add version to the metadata section of the JSON output.

**Resolution:** Added `version = sampler.VERSION` to the metadata table in `finalizeExport()`, placing it as the first field in the metadata section.

---

## Python Processor (process_terrain.py)

### [x] Incorrect polygon containment test (2026-01-09)

The `region_for_point()` function (lines 406-415) uses bounding box checks instead of proper point-in-polygon tests. Points within the bounding box but outside the actual convex hull are incorrectly classified.

**Fix:** Use `matplotlib.path.Path.contains_point()` or implement a ray-casting algorithm for proper polygon containment.

**Resolution:** Added matplotlib as a dependency and replaced the bounding box check with `matplotlib.path.Path.contains_point()`. The bounding box check is retained as a fast-path optimization before the polygon test.

### [x] Missing input validation (2026-01-09)

No validation of the JSON structure before processing. Malformed exports or version mismatches cause confusing errors.

**Fix:** Add a schema check or key presence validation with clear error messages. Check for required fields: `metadata`, `terrain`, `roads`, `airbases`.

**Resolution:** Added `_validate_data()` method to `TerrainProcessor` that checks for required top-level keys (`metadata`, `terrain`, `roads`, `airbases`), required metadata keys (`theatre`, `exportTime`, `gridResolution`, `bounds`), and required bounds keys (`minX`, `maxX`, `minZ`, `maxZ`). Also validates that `terrain` and `airbases` are lists, and that `roads` contains `points` and `segments` keys. Errors are collected and raised as a `TerrainExportError` with clear messages.

### [ ] Missing type annotations

Several variables lack type hints:
- `data` field in function parameters
- Return types on some helper methods
- Dict value types in several places

**Fix:** Add comprehensive type annotations throughout the module.

### [ ] Connectivity computation efficiency

The `compute_connectivity()` function (lines 397-428) iterates through all road segments and checks against all regions for each segment. O(segments * regions) complexity.

**Fix:** Build a spatial index (grid-based bucketing or R-tree) for regions and use it to quickly look up which region contains a point.

### [ ] Magic limit numbers

Various limits are hardcoded:
- Top 20 regions (line 673)
- Top 15 water bodies (line 704)
- Top 30 connections (line 749)
- DBSCAN parameters (line 354: `eps=10000, min_samples=5`)

**Fix:** Move these to class constants with descriptive names, or make them configurable via command-line arguments.

### [ ] Version compatibility checks

No validation that the JSON export version matches what the processor expects.

**Fix:** Check the script version in the JSON metadata against expected version(s). Warn or fail if there's a mismatch.

---

## Progress Tracking

Mark items with `[x]` when completed and note the date:

```
### [x] Example completed item (2024-01-15)
```
