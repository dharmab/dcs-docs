"""Write terrains' GIS files."""

from __future__ import annotations

import csv
import functools
import json
import re
import shutil
import time
import warnings
from collections.abc import Callable
from dataclasses import dataclass
from pathlib import Path

import humanize
import numpy as np
import pyogrio.raw
import rasterio
import shapely
import structlog
from pyproj import Transformer
from rasterio.errors import NotGeoreferencedWarning

# Compiled, without type stubs.
from rasterio.shutil import copy as copy_dataset  # ty: ignore[import-not-found]
from rasterio.transform import Affine
from shapely.geometry.base import BaseGeometry

from . import geonames, luafiles, projection, schedule, sup5, surface5
from .schedule import Call

logger = structlog.get_logger()


@dataclass(frozen=True)
class TerrainSource:
    folder: Path
    theatre: str
    towns: Path
    beacons: Path | None
    geonames: Path | None
    map_overlay: Path | None
    surface: Path | None


# Map overlay line sets that sit on neither road nor rail mesh, by theatre:
# (material, colorIndex) -> layer. Checked by plotting each set.
OVERLAY_OVERRIDES: dict[str, dict[tuple[str, str], str]] = {
    # National (13) and province (2) borders, drawn as thin triangle strips.
    "Afghanistan": {("Undef", "13"): "borders", ("Undef", "2"): "borders"},
    # Drawn as "Road" but traces the inner-German and national borders.
    "GermanyCW": {("Road", "12"): "borders"},
}


def _find(folder: Path, pattern: str) -> Path | None:
    """Case-insensitive glob relative to ``folder`` (folder names vary in case)."""
    rx = re.compile(pattern, re.I)
    candidates = [*folder.glob("*"), *folder.glob("*/*")]
    matches = sorted(
        p for p in candidates if rx.fullmatch(p.relative_to(folder).as_posix())
    )
    return matches[0] if matches else None


def discover(dcs_path: Path) -> list[TerrainSource]:
    terrains_dir = dcs_path / "Mods" / "terrains"
    if not terrains_dir.is_dir():
        raise FileNotFoundError(f"{terrains_dir} not found; is this a DCS install?")
    found: list[TerrainSource] = []
    for folder in sorted(p for p in terrains_dir.iterdir() if p.is_dir()):
        towns = _find(folder, r"map/towns\.lua")
        entry = folder / "entry.lua"
        if towns is None or not entry.exists():
            continue
        m = re.search(r"\['id'\]\s*=\s*\"([^\"]+)\"", entry.read_text(errors="replace"))
        found.append(
            TerrainSource(
                folder,
                m.group(1) if m else folder.name,
                towns,
                _find(folder, r"beacons\.lua"),
                _find(folder, r"map/[^/]+\.gn4"),
                _find(folder, r"map/[^/]+\.sup5"),
                _find(folder, r"surface/[^/]+\.surface5"),
            )
        )
    return found


def _num(v: float) -> int | float:
    return int(v) if float(v).is_integer() else v


def dcs_version(dcs_path: Path) -> str | None:
    cfg = dcs_path / "autoupdate.cfg"
    if not cfg.exists():
        return None
    try:
        return json.loads(cfg.read_text(encoding="utf-8")).get("version")
    except json.JSONDecodeError:
        return None


def _reference_points(
    src: TerrainSource,
    towns: list[luafiles.Town],
    labels: list[geonames.Label],
) -> list[projection.ReferencePoint]:
    points: list[projection.ReferencePoint] = []
    if src.beacons is not None:
        points += [
            projection.ReferencePoint(
                "beacon", b.display_name, b.x, b.z, b.latitude, b.longitude
            )
            for b in luafiles.read_beacons(src.beacons)
        ]
    by_name = _unique_town_labels(labels)
    for t in towns:
        label = by_name.get(t.key)
        if label is not None:
            points.append(
                projection.ReferencePoint(
                    "town", t.key, label.x, label.z, t.latitude, t.longitude
                )
            )
    return points


def _unique_town_labels(labels: list[geonames.Label]) -> dict[str, geonames.Label]:
    seen: dict[str, geonames.Label | None] = {}
    for label in labels:
        if label.is_town:
            seen[label.name] = None if label.name in seen else label
    return {k: v for k, v in seen.items() if v is not None}


def _write_gpkg_layer(
    path: Path,
    layer: str,
    geoms: list[BaseGeometry],
    crs_wkt: str,
    geometry_type: str,
    fields: dict[str, np.ndarray],
) -> None:
    pyogrio.raw.write(
        str(path),
        geometry=shapely.to_wkb(np.array(geoms, dtype=object)),
        field_data=list(fields.values()),
        fields=list(fields.keys()),
        layer=layer,
        driver="GPKG",
        crs=crs_wkt,
        geometry_type=geometry_type,
        append=path.exists(),
    )


_GDAL_TYPES = {"u1": "Byte", "<i2": "Int16"}


def _write_cog(
    path: Path,
    raw: Path,
    dtype: str,
    grid: surface5.Grid,
    crs_wkt: str,
    nodata: int,
    describe: Callable[[rasterio.io.DatasetWriter], None],
    **options: str | int,
) -> None:
    """Write a Cloud Optimized GeoTIFF from a raw raster file on disk.

    The COG driver can only copy another dataset, so a VRT presents the raw file
    to GDAL, which reads it a block at a time rather than all at once. Blocks are
    compressed independently, so threads do not change the output.
    """
    itemsize = np.dtype(dtype).itemsize
    vrt = raw.with_suffix(raw.suffix + ".vrt")
    vrt.write_text(
        f'''<VRTDataset rasterXSize="{grid.width}" rasterYSize="{grid.height}">
  <VRTRasterBand dataType="{_GDAL_TYPES[dtype]}" band="1" subClass="VRTRawRasterBand">
    <SourceFilename relativeToVRT="1">{raw.name}</SourceFilename>
    <ImageOffset>0</ImageOffset>
    <PixelOffset>{itemsize}</PixelOffset>
    <LineOffset>{itemsize * grid.width}</LineOffset>
    <ByteOrder>LSB</ByteOrder>
  </VRTRasterBand>
</VRTDataset>
''',
        encoding="utf-8",
    )
    with warnings.catch_warnings():
        # The VRT has no georeferencing until it is set here.
        warnings.simplefilter("ignore", NotGeoreferencedWarning)
        with rasterio.open(vrt, "r+") as ds:
            ds.crs = crs_wkt
            ds.transform = Affine(
                grid.resolution, 0, grid.west, 0, -grid.resolution, grid.north
            )
            ds.nodata = nodata
            describe(ds)
    copy_dataset(
        vrt,
        path,
        driver="COG",
        compress="DEFLATE",
        level=9,
        blocksize=512,
        num_threads="ALL_CPUS",
        **options,
    )


def _write_landcover(
    path: Path, classes: Path, grid: surface5.Grid, crs_wkt: str
) -> dict[str, float]:
    """Write the land cover raster and return the area of each class."""

    def describe(ds: rasterio.io.DatasetWriter) -> None:
        ds.write_colormap(1, {c.value: (*c.color, 255) for c in surface5.CLASSES})
        ds.set_band_description(1, "land cover class")
        ds.update_tags(1, **{f"CLASS_{c.value}": c.name for c in surface5.CLASSES})

    _write_cog(
        path, classes, "u1", grid, crs_wkt, 0, describe, overview_resampling="mode"
    )
    data = np.memmap(classes, "u1", "r", shape=(grid.height, grid.width))
    return surface5.class_stats(data, grid.resolution)


ELEVATION_NODATA = -32768


def _write_elevation(
    path: Path, elevation: Path, grid: surface5.Grid, crs_wkt: str
) -> dict[str, float]:
    """Write heights rounded to whole metres as int16, which compresses to a
    fraction of float32 and is finer than the interpolation error. Returns the
    lowest and highest height."""
    shape = (grid.height, grid.width)
    data = np.memmap(elevation, "<f4", "r", shape=shape)
    raw = elevation.with_suffix(".i16")
    heights = np.memmap(raw, "<i2", "w+", shape=shape)
    lo, hi = np.inf, -np.inf
    for rows in surface5.strips(data):
        strip = data[rows]
        nan = np.isnan(strip)
        if not nan.all():
            lo, hi = min(lo, np.nanmin(strip)), max(hi, np.nanmax(strip))
        heights[rows] = np.where(nan, ELEVATION_NODATA, np.round(strip))
    heights.flush()
    del data, heights

    def describe(ds: rasterio.io.DatasetWriter) -> None:
        ds.set_band_description(1, "terrain height above sea level")
        ds.update_tags(1, UNITS="metre")
        ds.update_tags(1, UNITTYPE="m")

    _write_cog(
        path,
        raw,
        "<i2",
        grid,
        crs_wkt,
        ELEVATION_NODATA,
        describe,
        predictor=2,
        overview_resampling="average",
    )
    return {"min_m": round(float(lo), 1), "max_m": round(float(hi), 1)}


def _read_places(
    src: TerrainSource,
) -> tuple[list[luafiles.Town], list[geonames.Label], projection.Projection]:
    towns = luafiles.read_towns(src.towns)
    labels = geonames.read_labels(src.geonames) if src.geonames else []
    proj = projection.fit(_reference_points(src, towns, labels))
    return towns, labels, proj


# Land cover work is cut into runs of tiles holding about this much metadata
# (a few seconds each), and finer for small terrains so they still spread over
# every worker.
_CHUNK_BYTES = 4_000_000
_CHUNKS_PER_WORKER = 3
# Runs are also cut at about this many bytes of rasters, which bounds the memory
# each run takes in its worker and while it waits to be composited.
_CHUNK_RASTER_BYTES = 64 << 20


def _chunks(plan: surface5.TilePlan, workers: int) -> list[list[tuple[int, int]]]:
    spans = plan.spans
    total = spans[-1][1] - spans[0][0]
    target = min(_CHUNK_BYTES, total / (workers * _CHUNKS_PER_WORKER))
    chunks: list[list[tuple[int, int]]] = []
    run: list[tuple[int, int]] = []
    size = raster_size = 0
    for span, raster_bytes in zip(spans, plan.raster_bytes, strict=True):
        if run and raster_size + raster_bytes > _CHUNK_RASTER_BYTES:
            chunks.append(run)
            run, size, raster_size = [], 0, 0
        run.append(span)
        size += span[1] - span[0]
        raster_size += raster_bytes
        if size >= target:
            chunks.append(run)
            run, size, raster_size = [], 0, 0
    if run:
        chunks.append(run)
    return chunks


def _work_estimate(src: TerrainSource) -> int:
    """Rough relative cost of exporting a terrain, to start the largest first.

    Export time tracks the size of the whole surface5 file (although only its
    most detailed tiles are read) plus the overlay, which costs about 25 times
    as much per byte to parse.
    """
    size = 25 * src.map_overlay.stat().st_size if src.map_overlay else 0
    if src.surface is not None:
        size += src.surface.stat().st_size
    return size


def export_terrains(
    terrains: list[TerrainSource],
    out_root: Path,
    resolution: float,
    elevation_resolution: float,
    version: str | None,
    workers: int,
) -> None:
    """Export every terrain, sharing ``workers`` processes between them.

    Each terrain's single-threaded steps (reading the overlay, the final
    GeoTIFF write) go ahead of land cover tiles, and larger terrains ahead of
    smaller ones, so that no long step is left running alone at the end.
    """
    ranked = sorted(terrains, key=_work_estimate, reverse=True)
    schedule.run(
        [
            _export_job(
                src, out_root, resolution, elevation_resolution, version, workers, rank
            )
            for rank, src in enumerate(ranked)
        ],
        workers,
    )


def _export_job(
    src: TerrainSource,
    out_root: Path,
    resolution: float,
    elevation_resolution: float,
    version: str | None,
    workers: int,
    rank: int,
) -> schedule.Job:
    urgent, bulk = (0, rank), (1, rank)
    log = logger.bind(theatre=src.theatre)
    out = out_root / src.theatre
    log.info("exporting terrain", folder=src.folder.name, out=str(out))
    if out.exists():
        shutil.rmtree(out)
    out.mkdir(parents=True)
    staging = out / "staging"
    started = time.monotonic()

    calls = {"places": Call(urgent, _read_places, (src,))}
    if src.map_overlay is not None:
        calls["sets"] = Call(urgent, sup5.read_line_sets, (src.map_overlay,))
    if src.surface is not None:
        calls["plan"] = Call(
            urgent,
            surface5.plan_tiles,
            (src.surface, resolution, elevation_resolution),
        )
    got = yield calls
    towns, labels, proj = got["places"]
    crs = proj.crs(src.theatre)
    crs_wkt = crs.to_wkt()
    log.info(
        "fitted projection",
        lon_0=proj.central_meridian,
        x_0=proj.false_easting,
        y_0=proj.false_northing,
        points=proj.point_count,
        rms_error_m=proj.rms_error_m,
        max_error_m=proj.max_error_m,
    )

    # Places: lat/long from towns.lua, DCS position from the map label when there
    # is exactly one, otherwise from the projection.
    to_dcs = Transformer.from_crs("EPSG:4326", crs, always_xy=True)
    by_name = _unique_town_labels(labels)
    place_rows = []
    for t in towns:
        label = by_name.get(t.key)
        if label is not None:
            x, z = label.x, label.z
        else:
            z, x = to_dcs.transform(t.longitude, t.latitude)
        place_rows.append((t.display_name, t.latitude, t.longitude, x, z))
    place_rows.sort(key=lambda r: r[0].casefold())
    with (out / "places.csv").open("w", newline="", encoding="utf-8") as f:
        w = csv.writer(f, lineterminator="\n")
        w.writerow(["name", "latitude", "longitude", "x", "z"])
        for name, lat, lon, x, z in place_rows:
            w.writerow([name, f"{lat:.6f}", f"{lon:.6f}", f"{x:.1f}", f"{z:.1f}"])

    gpkg = out / "features.gpkg"
    _write_gpkg_layer(
        gpkg,
        "places",
        [shapely.Point(z, x) for _, _, _, x, z in place_rows],
        crs_wkt,
        "Point",
        {
            "name": np.array([r[0] for r in place_rows], dtype=object),
            "latitude": np.array([r[1] for r in place_rows]),
            "longitude": np.array([r[2] for r in place_rows]),
        },
    )

    lc: surface5.LandCover | None = None
    plan: surface5.TilePlan | None = got.get("plan")
    if plan is not None:
        assert src.surface is not None
        chunks = _chunks(plan, workers)
        log.info("rasterizing land cover", tiles=len(plan.spans), chunks=len(chunks))
        # Rasters are composited on disk as each run of tiles comes back.
        staging.mkdir()
        compositor = surface5.Compositor(staging, plan.grid, plan.elevation_grid)
        yield {
            i: Call(
                bulk,
                surface5.rasterize_tiles,
                (
                    src.surface,
                    plan.data_offset,
                    plan.grid,
                    plan.elevation_grid,
                    chunk,
                ),
                functools.partial(compositor.add, i),
            )
            for i, chunk in enumerate(chunks)
        }
        lc = compositor.finish(len(plan.spans))
        del compositor

    final: dict[str, Call] = {}
    if lc is not None:
        final["landcover.tif"] = Call(
            urgent,
            _write_landcover,
            (out / "landcover.tif", lc.classes, lc.grid, crs_wkt),
        )
        final["elevation.tif"] = Call(
            urgent,
            _write_elevation,
            (out / "elevation.tif", lc.elevation, lc.elevation_grid, crs_wkt),
        )
    decisions: dict[str, str] = {}
    if "sets" in got:
        parts_by_layer, decisions = sup5.assign_layers(
            got["sets"],
            classify=lc.mask_fractions if lc is not None else None,
            overrides=OVERLAY_OVERRIDES.get(src.theatre),
        )
        for layer, parts in parts_by_layer.items():
            final[layer] = Call(
                urgent, sup5.build_geometry, (sup5.LAYERS[layer], parts)
            )
    if lc is not None:
        lc.close()
    log.info("writing rasters and building feature layers", steps=list(final))
    layers = yield final
    if staging.exists():
        shutil.rmtree(staging)

    layer_counts: dict[str, int] = {"places": len(place_rows)}
    if src.map_overlay is not None:
        for layer, primitive in sup5.LAYERS.items():
            geoms = layers.get(layer, [])
            layer_counts[layer] = len(geoms)
            if not geoms:
                continue
            arr = np.array(geoms, dtype=object)
            if primitive == "LINELIST":
                gtype = "LineString"
                fields = {"length_m": np.round(shapely.length(arr), 1)}
            else:
                gtype = "Polygon"
                fields = {"area_m2": np.round(shapely.area(arr), 0)}
            _write_gpkg_layer(gpkg, layer, geoms, crs_wkt, gtype, fields)
        log.info("wrote features", **layer_counts)
        skipped = [k for k, v in decisions.items() if v == "skipped"]
        if skipped:
            log.warning("skipped map materials", materials=skipped)

    meta: dict = {
        "theatre": src.theatre,
        "terrain_folder": src.folder.name,
        "dcs_version": version,
        "crs": {
            "proj4": proj.proj4,
            "central_meridian": proj.central_meridian,
            "scale_factor": projection.SCALE_FACTOR,
            "false_easting": _num(proj.false_easting),
            "false_northing": _num(proj.false_northing),
            "easting_axis": "DCS z",
            "northing_axis": "DCS x",
            "fit_points": proj.point_count,
            "fit_rms_error_m": proj.rms_error_m,
            "fit_max_error_m": proj.max_error_m,
        },
        "places": {"count": len(place_rows)},
        "features": {"layers": layer_counts, "map_overlay_sources": decisions},
    }

    if lc is not None:
        g = lc.grid
        height, width = g.height, g.width
        meta["landcover"] = {
            "resolution_m": resolution,
            "width": width,
            "height": height,
            "extent": {
                "x_min": g.north - height * resolution,
                "x_max": g.north,
                "z_min": g.west,
                "z_max": g.west + width * resolution,
            },
            "area_km2": layers["landcover.tif"],
        }
        meta["elevation"] = {
            "resolution_m": elevation_resolution,
            **layers["elevation.tif"],
        }
        log.info("wrote land cover", width=width, height=height, tiles=lc.tile_count)

    (out / "terrain.json").write_text(
        json.dumps(meta, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    elapsed = humanize.precisedelta(time.monotonic() - started, format="%0.0f")
    log.info("exported terrain", duration=elapsed)
