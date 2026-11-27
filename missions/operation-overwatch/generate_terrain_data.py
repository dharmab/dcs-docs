#!/usr/bin/env python3
"""
Generate TerrainData.lua: the area of operations and a mask of tasking sites.

Usage:
    uv run python generate_terrain_data.py

Reads docs/data/terrains/Afghanistan/ and writes
src/l10n/DEFAULT/TerrainData.lua with:

- areaOfOperations: the Kandahar and Helmand province outlines, merged into one
  polygon. The province borders in features.gpkg do not join into closed
  polygons, so the generator widens them by BORDER_GAP_M to close the gaps,
  takes the province areas between them, and merges the two provinces.
- A 200 m mask of tasking sites. A site is open ground or farmland with
  compounds (land cover `town`) nearby but not a city, on flat ground, away from
  airfields. These are the green zones along the Helmand and Arghandab rivers,
  where the Firefight scenario places a patrol pinned by insurgents in
  compounds.

Each mask row is a string of comma-separated run lengths, alternating non-site
and site and starting with non-site. siteCounts lists the number of site cells
in each row, so the mission can pick a site uniformly without decoding every
row.
"""

import csv
import sqlite3
import sys
from pathlib import Path

import humanize
import numpy as np
import rasterio
import shapely
import structlog
from rasterio.features import rasterize
from rasterio.warp import Resampling, reproject
from rasterio.windows import from_bounds
from scipy import ndimage, signal
from shapely.geometry import Point, Polygon
from shapely.ops import polygonize, unary_union

log = structlog.get_logger()

THEATRE = "Afghanistan"

# A place inside each province of the area of operations, from places.csv
PROVINCE_PLACES = ("Kandahar", "Lashkar Gah")

# Half-width added to the border lines to close gaps between their ends
BORDER_GAP_M = 1000
# Closing distance that removes the strip left between the two provinces
PROVINCE_SEAM_M = 2000
# Polygon simplification tolerance for the Lua area of operations
AREA_SIMPLIFY_M = 500

# Land cover classes from tools/terrain-geodata/README.md
LAND = 1
FIELD = 2
TOWN = 4
RUNWAY = 9
SITE_CLASSES = (LAND, FIELD)
ELEVATION_NODATA = -32768

# Fraction of town pixels within COMPOUND_RADIUS_M of a site: enough for
# compounds the enemy can fire from, not so many that the site is in a village
COMPOUND_RADIUS_M = 1000
MIN_COMPOUND_FRACTION = 0.03
MAX_COMPOUND_FRACTION = 0.25
# Fraction of town pixels within CITY_RADIUS_M of a site. Keeps sites out of
# Kandahar City, Lashkar Gah, and the other large towns.
CITY_RADIUS_M = 3000
MAX_CITY_FRACTION = 0.12
# Taskings stay clear of airfields
MIN_RUNWAY_DISTANCE_M = 5000
# Highest minus lowest elevation in the 3 x 3 km block around a site. Rejects
# mountain valleys, where ground units have no flat ground to stand on.
MAX_RELIEF_M = 150
RELIEF_BLOCK_PIXELS = 3

# Each mask cell covers FACTOR x FACTOR land cover pixels (100 m -> 200 m). A
# cell is a site only when all of its pixels are.
FACTOR = 2

# GeoPackage binary header: magic, version, flags, srs_id, then an envelope
# whose size the flags give
GPKG_HEADER_SIZE = 8
GPKG_ENVELOPE_SIZES = {0: 0, 1: 32, 2: 48, 3: 48, 4: 64}

RULE = "-- " + "=" * 77


def get_script_dir() -> Path:
    return Path(__file__).parent.resolve()


def read_geometries(features: Path, layer: str) -> list[shapely.Geometry]:
    """Geometries of a features.gpkg layer, in (easting, northing) metres."""
    geometries = []
    with sqlite3.connect(f"file:{features}?mode=ro", uri=True) as db:
        # The layer name is one of this script's constants, not input
        for (blob,) in db.execute(f"SELECT geom FROM {layer} ORDER BY fid"):
            flags = blob[3]
            envelope_size = GPKG_ENVELOPE_SIZES[(flags >> 1) & 0b111]
            geometries.append(
                shapely.from_wkb(blob[GPKG_HEADER_SIZE + envelope_size :])
            )
    return geometries


def read_place(places: Path, name: str) -> Point:
    with places.open() as f:
        for row in csv.DictReader(f):
            if row["name"] == name:
                # GIS easting is DCS z, northing is DCS x
                return Point(float(row["z"]), float(row["x"]))
    raise ValueError(f"{name} is not in {places}")


def largest_polygon(geometry: shapely.Geometry) -> Polygon:
    parts = getattr(geometry, "geoms", [geometry])
    return max(parts, key=lambda part: part.area)


def build_area(terrain_dir: Path) -> Polygon:
    """The merged outline of the provinces that contain PROVINCE_PLACES."""
    borders = unary_union(read_geometries(terrain_dir / "features.gpkg", "borders"))
    # The national border closes; the province borders inside it do not
    country = largest_polygon(unary_union(list(polygonize(borders))))
    provinces = country.difference(borders.buffer(BORDER_GAP_M))
    chosen = []
    for name in PROVINCE_PLACES:
        place = read_place(terrain_dir / "places.csv", name)
        province = next(p for p in provinces.geoms if p.contains(place))
        log.info("province", place=name, area_km2=round(province.area / 1e6))
        chosen.append(province)
    merged = unary_union(chosen).buffer(PROVINCE_SEAM_M).buffer(-PROVINCE_SEAM_M)
    # Undo the widening at the national border
    area = largest_polygon(merged.intersection(country))
    return Polygon(area.exterior)


def disk_mean(values: np.ndarray, radius_pixels: int) -> np.ndarray:
    """Mean of values within radius_pixels of each pixel."""
    y, x = np.ogrid[
        -radius_pixels : radius_pixels + 1, -radius_pixels : radius_pixels + 1
    ]
    kernel = (x * x + y * y <= radius_pixels * radius_pixels).astype(float)
    return signal.fftconvolve(values, kernel / kernel.sum(), mode="same")


def relief_on_grid(
    elevation: Path, shape: tuple[int, int], transform: rasterio.Affine
) -> np.ndarray:
    """Local relief from the elevation raster, resampled to the land cover grid."""
    with rasterio.open(elevation) as src:
        heights = src.read(1).astype(float)
        nodata = heights == ELEVATION_NODATA
        highest = ndimage.maximum_filter(
            np.where(nodata, -np.inf, heights), size=RELIEF_BLOCK_PIXELS
        )
        lowest = ndimage.minimum_filter(
            np.where(nodata, np.inf, heights), size=RELIEF_BLOCK_PIXELS
        )
        relief = np.where(nodata, np.inf, highest - lowest)
        out = np.full(shape, np.inf)
        reproject(
            relief,
            out,
            src_transform=src.transform,
            dst_transform=transform,
            src_crs=src.crs,
            dst_crs=src.crs,
            resampling=Resampling.nearest,
        )
    return out


def build_sites(
    terrain_dir: Path, area: Polygon
) -> tuple[np.ndarray, float, float, float]:
    """
    The site mask over the bounding box of the area of operations.

    Returns:
        (mask, north_x, west_z, cell_size): mask rows run north to south.
    """
    with rasterio.open(terrain_dir / "landcover.tif") as src:
        window = from_bounds(*area.bounds, src.transform)
        window = window.round_offsets().round_lengths()
        classes = src.read(1, window=window)
        transform = src.window_transform(window)
        pixel = transform.a

    inside = rasterize(
        [(area, 1)], out_shape=classes.shape, transform=transform, fill=0
    ).astype(bool)
    town = (classes == TOWN).astype(float)
    compounds = disk_mean(town, round(COMPOUND_RADIUS_M / pixel))
    city = disk_mean(town, round(CITY_RADIUS_M / pixel))
    runway_distance = ndimage.distance_transform_edt(classes != RUNWAY) * pixel
    relief = relief_on_grid(terrain_dir / "elevation.tif", classes.shape, transform)

    open_ground = np.isin(classes, SITE_CLASSES)
    has_compounds = compounds >= MIN_COMPOUND_FRACTION
    not_in_village = compounds <= MAX_COMPOUND_FRACTION
    not_in_city = city <= MAX_CITY_FRACTION
    clear_of_airfields = runway_distance >= MIN_RUNWAY_DISTANCE_M
    flat = relief <= MAX_RELIEF_M
    site = (
        inside
        & open_ground
        & has_compounds
        & not_in_village
        & not_in_city
        & clear_of_airfields
        & flat
    )

    rows = site.shape[0] // FACTOR * FACTOR
    cols = site.shape[1] // FACTOR * FACTOR
    blocks = site[:rows, :cols].reshape(rows // FACTOR, FACTOR, cols // FACTOR, FACTOR)
    mask = blocks.all(axis=(1, 3))
    # GIS easting is DCS z, northing is DCS x
    return mask, transform.f, transform.c, pixel * FACTOR


def run_lengths(row: np.ndarray) -> list[int]:
    """Run lengths alternating non-site and site, starting with non-site."""
    edges = np.flatnonzero(np.diff(row.astype(np.int8))) + 1
    bounds = np.concatenate(([0], edges, [len(row)]))
    runs = np.diff(bounds).tolist()
    if row[0]:
        runs = [0, *runs]
    return runs


def render_lua(
    area: Polygon, mask: np.ndarray, north_x: float, west_z: float, cell: float
) -> str:
    # Plain string templating, as in Operation Infinity's generator: the output
    # matches stylua's format, and the strings hold only digits and commas.
    simplified = area.simplify(AREA_SIMPLIFY_M)
    # Drop the closing vertex; Sites:pointInPolygon closes the ring itself
    vertices = list(simplified.exterior.coords)[:-1]
    counts = mask.sum(axis=1)
    lines = [
        RULE,
        "-- TERRAIN DATA",
        f"-- Generated by generate_terrain_data.py from {THEATRE} landcover.tif,",
        "-- elevation.tif, features.gpkg, and places.csv.",
        "-- Do not edit; rerun the generator after a terrain export update.",
        RULE,
        "",
        "TerrainData = {",
        f'    theatre = "{THEATRE}",',
        "    -- Kandahar and Helmand provinces, as map points { x, y }",
        "    areaOfOperations = {",
    ]
    # GIS easting is DCS z (map y), northing is DCS x
    lines += [f"        {{ x = {round(n)}, y = {round(e)} }}," for e, n in vertices]
    lines += [
        "    },",
        "    -- Tasking site mask",
        f"    cellSize = {cell:g},",
        f"    northX = {north_x:g}, -- DCS x of the mask's north edge",
        f"    westZ = {west_z:g}, -- DCS z of the mask's west edge",
        f"    columns = {mask.shape[1]},",
        "    -- Site cells per row, north to south",
        f'    siteCounts = "{",".join(map(str, counts.tolist()))}",',
        "    -- Run lengths per row, north to south, alternating non-site and site",
        "    rows = {",
    ]
    lines += [f'        "{",".join(map(str, run_lengths(row)))}",' for row in mask]
    lines += ["    },", "}", ""]
    return "\n".join(lines)


def main() -> int:
    structlog.configure(logger_factory=structlog.PrintLoggerFactory(sys.stderr))
    script_dir = get_script_dir()
    terrain_dir = script_dir.parents[1] / "docs" / "data" / "terrains" / THEATRE
    output = script_dir / "src" / "l10n" / "DEFAULT" / "TerrainData.lua"

    log.info("building area of operations", path=str(terrain_dir))
    area = build_area(terrain_dir)
    log.info("building site mask")
    mask, north_x, west_z, cell = build_sites(terrain_dir, area)
    output.write_text(render_lua(area, mask, north_x, west_z, cell))
    log.info(
        "wrote terrain data",
        file=output.name,
        area_km2=round(area.area / 1e6),
        rows=mask.shape[0],
        columns=mask.shape[1],
        cell_m=cell,
        sites=int(mask.sum()),
        site_km2=round(mask.sum() * cell * cell / 1e6),
        size=humanize.naturalsize(output.stat().st_size),
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
