#!/usr/bin/env python3
"""
Generate TerrainData.lua, a land cover mask for ground unit placement, and
tests/mock_terrain.lua, the terrain behind the offline test mock.

Usage:
    uv run python generate_terrain_data.py

Reads docs/data/terrains/Caucasus/landcover.tif and writes a mask of cells
where ground units should not spawn (forest, water, and ground outside the
terrain mesh). DCS scripting cannot detect forest, so the mission looks up
this mask before its runtime slope and surface checks.

Each mask row is a string of comma-separated run lengths, alternating open and
blocked and starting with open. Strings keep the Lua constant count low and are
decoded only when the mission first samples that row.

mock_terrain.lua holds the surface type at full raster resolution, the road
lines from features.gpkg, and the projection from terrain.json. The mission
does not load it.
"""

import json
import sqlite3
import struct
import sys
from pathlib import Path

import numpy as np
import rasterio
from rasterio.windows import from_bounds

THEATRE = "Caucasus"

# Mission area in DCS coordinates: every target aerodrome plus 40 nm and margin,
# and the approach corridors from Krymsk. Clipped to the raster extent.
X_MIN = -400_000
X_MAX = 50_000
Z_MIN = 250_000
Z_MAX = 980_000

# The mock terrain also covers the carrier operating area west of the mission
# area, which only the test mock's surface types need
MOCK_Z_MIN = 150_000

# Each mask cell covers FACTOR x FACTOR raster pixels (100 m pixels -> 200 m cells)
FACTOR = 2

# Land cover classes from tools/terrain-geodata/README.md
NODATA = 0
FOREST = 3
RIVER = 6
LAKE = 7
SEA = 8
BLOCKED_CLASSES = (NODATA, FOREST, RIVER, LAKE, SEA)

RULE = "-- " + "=" * 77

# land.SurfaceType values for each land cover class. The raster has no roads;
# the mock reports ROAD near the road lines instead.
SURFACE_LAND = 1
SURFACE_SHALLOW_WATER = 2
SURFACE_WATER = 3
SURFACE_RUNWAY = 5
RUNWAY = 9
SURFACE_BY_CLASS = {
    RIVER: SURFACE_SHALLOW_WATER,
    LAKE: SURFACE_WATER,
    SEA: SURFACE_WATER,
    RUNWAY: SURFACE_RUNWAY,
}

# Road vertices are rounded to whole metres. Vertices closer than this to the
# line through their neighbours are dropped to keep the file small.
ROAD_SIMPLIFY_TOLERANCE_M = 2

# GeoPackage binary header: magic, version, flags, srs_id, then an envelope
# whose size the flags give
GPKG_HEADER_SIZE = 8
GPKG_ENVELOPE_SIZES = {0: 0, 1: 32, 2: 48, 3: 48, 4: 64}
WKB_LINESTRING = 2


def get_script_dir() -> Path:
    return Path(__file__).parent.resolve()


def read_window(
    landcover: Path, z_min: float = Z_MIN
) -> tuple[np.ndarray, float, float, float]:
    """
    Read the land cover classes inside the mission area, from z_min east.

    Returns:
        (classes, north_x, west_z, pixel_size): rows run north to south.
    """
    with rasterio.open(landcover) as src:
        extent = src.bounds
        window = from_bounds(
            max(z_min, extent.left),
            max(X_MIN, extent.bottom),
            min(Z_MAX, extent.right),
            min(X_MAX, extent.top),
            src.transform,
        )
        window = window.round_offsets().round_lengths()
        data = src.read(1, window=window)
        transform = src.window_transform(window)
    return data, transform.f, transform.c, transform.a


def build_mask(landcover: Path) -> tuple[np.ndarray, float, float, float]:
    """
    Downsample the land cover raster to a blocked mask.

    A cell is blocked when at least half of its pixels are blocked.

    Returns:
        (mask, north_x, west_z, cell_size): mask rows run north to south.
    """
    # GIS easting is DCS z, northing is DCS x
    data, north_x, west_z, pixel = read_window(landcover)

    rows = data.shape[0] // FACTOR * FACTOR
    cols = data.shape[1] // FACTOR * FACTOR
    blocked = np.isin(data[:rows, :cols], BLOCKED_CLASSES)
    blocks = blocked.reshape(rows // FACTOR, FACTOR, cols // FACTOR, FACTOR)
    mask = blocks.sum(axis=(1, 3)) * 2 >= FACTOR * FACTOR
    return mask, north_x, west_z, pixel * FACTOR


def surface_types(classes: np.ndarray) -> np.ndarray:
    surface = np.full(classes.shape, SURFACE_LAND, dtype=np.uint8)
    for land_class, surface_type in SURFACE_BY_CLASS.items():
        surface[classes == land_class] = surface_type
    return surface


def value_runs(row: np.ndarray) -> list[int]:
    """Alternating value and run length pairs."""
    edges = np.flatnonzero(np.diff(row)) + 1
    starts = np.concatenate(([0], edges))
    lengths = np.diff(np.concatenate((starts, [len(row)])))
    pairs = np.column_stack((row[starts], lengths))
    return pairs.ravel().tolist()


def parse_linestring(blob: bytes) -> list[tuple[float, float]]:
    """Decode a GeoPackage LineString into (easting, northing) points."""
    flags = blob[3]
    envelope_size = GPKG_ENVELOPE_SIZES[(flags >> 1) & 0b111]
    wkb = blob[GPKG_HEADER_SIZE + envelope_size :]
    order = "<" if wkb[0] == 1 else ">"
    geometry_type, count = struct.unpack_from(order + "II", wkb, 1)
    if geometry_type != WKB_LINESTRING:
        raise ValueError(f"expected a LineString, got WKB type {geometry_type}")
    flat = struct.unpack_from(order + "d" * (2 * count), wkb, 9)
    return list(zip(flat[0::2], flat[1::2], strict=True))


def simplify(points: list[tuple[float, float]], tolerance: float) -> list:
    """Douglas-Peucker line simplification."""
    if len(points) < 3:
        return points
    (ax, ay), (bx, by) = points[0], points[-1]
    dx, dy = bx - ax, by - ay
    length = (dx * dx + dy * dy) ** 0.5
    worst, worst_distance = 0, 0.0
    for i in range(1, len(points) - 1):
        px, py = points[i]
        if length == 0:
            distance = ((px - ax) ** 2 + (py - ay) ** 2) ** 0.5
        else:
            distance = abs(dy * (px - ax) - dx * (py - ay)) / length
        if distance > worst_distance:
            worst, worst_distance = i, distance
    if worst_distance <= tolerance:
        return [points[0], points[-1]]
    left = simplify(points[: worst + 1], tolerance)
    right = simplify(points[worst:], tolerance)
    return left[:-1] + right


def in_mock_area(points: list[tuple[float, float]]) -> bool:
    for easting, northing in points:
        inside_x = X_MIN <= northing <= X_MAX
        inside_z = MOCK_Z_MIN <= easting <= Z_MAX
        if inside_x and inside_z:
            return True
    return False


def read_roads(features: Path) -> list[str]:
    """Road lines that touch the mock area, as "x,z,x,z,..." strings."""
    roads = []
    with sqlite3.connect(f"file:{features}?mode=ro", uri=True) as db:
        for (blob,) in db.execute("SELECT geom FROM roads ORDER BY fid"):
            points = parse_linestring(blob)
            if not in_mock_area(points):
                continue
            points = simplify(points, ROAD_SIMPLIFY_TOLERANCE_M)
            # GIS easting is DCS z, northing is DCS x
            coords = [f"{round(n)},{round(e)}" for e, n in points]
            roads.append(",".join(coords))
    return roads


def render_mock_lua(
    surface: np.ndarray,
    north_x: float,
    west_z: float,
    pixel: float,
    roads: list[str],
    crs: dict,
) -> str:
    # Same plain templating as render_lua: the strings hold only digits,
    # commas, and minus signs
    lines = [
        RULE,
        "-- MOCK TERRAIN",
        f"-- Generated by generate_terrain_data.py from {THEATRE} landcover.tif,",
        "-- features.gpkg, and terrain.json. Test data for dcs_mock.lua; the mission",
        "-- does not load it. Do not edit; rerun the generator.",
        RULE,
        "",
        "return {",
        f'    theatre = "{THEATRE}",',
        "    -- Transverse Mercator on WGS84; DCS x is northing, z is easting",
        "    projection = {",
        f"        centralMeridian = {crs['central_meridian']!r},",
        f"        scaleFactor = {crs['scale_factor']!r},",
        f"        falseEasting = {crs['false_easting']!r},",
        f"        falseNorthing = {crs['false_northing']!r},",
        "    },",
        "    surface = {",
        f"        cellSize = {pixel:g},",
        f"        northX = {north_x:g}, -- DCS x of the grid's north edge",
        f"        westZ = {west_z:g}, -- DCS z of the grid's west edge",
        f"        columns = {surface.shape[1]},",
        "        -- land.SurfaceType and run length pairs per row, north to south",
        "        rows = {",
    ]
    for row in surface:
        lines.append(f'            "{",".join(map(str, value_runs(row)))}",')
    lines += [
        "        },",
        "    },",
        "    -- Road lines that touch the mock area, as x,z,x,z,... in DCS metres",
        "    roads = {",
    ]
    lines += [f'        "{road}",' for road in roads]
    lines += ["    },", "}", ""]
    return "\n".join(lines)


def write_mock_terrain(terrain_dir: Path, output: Path) -> None:
    landcover = terrain_dir / "landcover.tif"
    classes, north_x, west_z, pixel = read_window(landcover, MOCK_Z_MIN)
    surface = surface_types(classes)
    roads = read_roads(terrain_dir / "features.gpkg")
    crs = json.loads((terrain_dir / "terrain.json").read_text())["crs"]
    output.write_text(render_mock_lua(surface, north_x, west_z, pixel, roads, crs))
    print(
        f"Wrote {output.name}: {surface.shape[0]} x {surface.shape[1]} cells of "
        f"{pixel:g} m, {len(roads)} roads, {output.stat().st_size / 1024:.0f} KB"
    )


def run_lengths(row: np.ndarray) -> list[int]:
    """Run lengths alternating open and blocked, starting with open."""
    edges = np.flatnonzero(np.diff(row.astype(np.int8))) + 1
    bounds = np.concatenate(([0], edges, [len(row)]))
    runs = np.diff(bounds).tolist()
    if row[0]:
        runs = [0, *runs]
    return runs


def render_lua(mask: np.ndarray, north_x: float, west_z: float, cell: float) -> str:
    # Plain string templating instead of a Lua AST printer: the output matches
    # stylua's format exactly, so `make check` passes without reformatting. The
    # rows hold only digits and commas, so nothing needs escaping. Switch to an
    # AST or a Lua string-escaping helper if this ever emits text from the data.
    lines = [
        RULE,
        "-- TERRAIN DATA",
        f"-- Generated by generate_terrain_data.py from {THEATRE} landcover.tif.",
        "-- Do not edit; rerun the generator after a terrain export update.",
        RULE,
        "",
        "TerrainData = {",
        f'    theatre = "{THEATRE}",',
        f"    cellSize = {cell:g},",
        f"    northX = {north_x:g}, -- DCS x of the mask's north edge",
        f"    westZ = {west_z:g}, -- DCS z of the mask's west edge",
        f"    columns = {mask.shape[1]},",
        "    -- Run lengths per row, north to south, alternating open and blocked",
        "    rows = {",
    ]
    lines += [f'        "{",".join(map(str, run_lengths(row)))}",' for row in mask]
    lines += ["    },", "}", ""]
    return "\n".join(lines)


def main() -> int:
    script_dir = get_script_dir()
    terrain_dir = script_dir.parents[1] / "docs" / "data" / "terrains" / THEATRE
    landcover = terrain_dir / "landcover.tif"
    output = script_dir / "src" / "l10n" / "DEFAULT" / "TerrainData.lua"

    mask, north_x, west_z, cell = build_mask(landcover)
    output.write_text(render_lua(mask, north_x, west_z, cell))
    print(
        f"Wrote {output.name}: {mask.shape[0]} x {mask.shape[1]} cells of {cell:g} m, "
        f"{mask.mean():.0%} blocked, {output.stat().st_size / 1024:.0f} KB"
    )
    write_mock_terrain(terrain_dir, script_dir / "tests" / "mock_terrain.lua")
    return 0


if __name__ == "__main__":
    sys.exit(main())
