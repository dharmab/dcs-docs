"""Write one terrain's GIS files."""

from __future__ import annotations

import csv
import json
import re
import shutil
import time
from dataclasses import dataclass
from pathlib import Path

import numpy as np
import pyogrio.raw
import rasterio
import shapely
from pyproj import Transformer
from rasterio.transform import Affine
from shapely.geometry.base import BaseGeometry

from . import geonames, luafiles, projection, sup5, surface5


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


def _write_landcover(path: Path, lc: surface5.LandCover, crs_wkt: str) -> None:
    height, width = lc.data.shape
    transform = Affine(lc.resolution, 0, lc.west, 0, -lc.resolution, lc.north)
    # The COG driver can only copy, so rasterio stages the raster in memory and
    # builds the tiled, overviewed file when the dataset closes.
    with rasterio.open(
        path,
        "w",
        driver="COG",
        width=width,
        height=height,
        count=1,
        dtype="uint8",
        crs=crs_wkt,
        transform=transform,
        nodata=0,
        compress="DEFLATE",
        level=9,
        overview_resampling="mode",
        blocksize=512,
    ) as dst:
        dst.write(lc.data, 1)
        dst.write_colormap(1, {c.value: (*c.color, 255) for c in surface5.CLASSES})
        dst.set_band_description(1, "land cover class")
        dst.update_tags(1, **{f"CLASS_{c.value}": c.name for c in surface5.CLASSES})


def export_terrain(
    src: TerrainSource,
    out_root: Path,
    resolution: float,
    version: str | None,
    log=print,
) -> Path:
    out = out_root / src.theatre
    if out.exists():
        shutil.rmtree(out)
    out.mkdir(parents=True)
    started = time.monotonic()

    towns = luafiles.read_towns(src.towns)
    labels = geonames.read_labels(src.geonames) if src.geonames else []
    points = _reference_points(src, towns, labels)
    proj = projection.fit(points)
    crs = proj.crs(src.theatre)
    crs_wkt = crs.to_wkt()
    log(
        f"  projection: lon_0={proj.central_meridian} x_0={proj.false_easting} "
        f"y_0={proj.false_northing} ({proj.point_count} points, "
        f"rms {proj.rms_error_m} m, max {proj.max_error_m} m)"
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
    lc = (
        surface5.rasterize_landcover(src.surface, resolution)
        if src.surface is not None
        else None
    )

    layer_counts: dict[str, int] = {"places": len(place_rows)}
    decisions: dict[str, str] = {}
    if src.map_overlay is not None:
        layers, decisions = sup5.read_layers(
            src.map_overlay,
            classify=lc.mask_fractions if lc is not None else None,
            overrides=OVERLAY_OVERRIDES.get(src.theatre),
        )
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
        log("  features: " + ", ".join(f"{k} {v}" for k, v in layer_counts.items()))
        skipped = [k for k, v in decisions.items() if v == "skipped"]
        if skipped:
            log(f"  skipped map materials: {', '.join(skipped)}")

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
        _write_landcover(out / "landcover.tif", lc, crs_wkt)
        height, width = lc.data.shape
        meta["landcover"] = {
            "resolution_m": resolution,
            "width": width,
            "height": height,
            "extent": {
                "x_min": lc.north - height * resolution,
                "x_max": lc.north,
                "z_min": lc.west,
                "z_max": lc.west + width * resolution,
            },
            "area_km2": surface5.class_stats(lc),
        }
        log(f"  landcover: {width}x{height} px from {lc.tile_count} tiles")

    (out / "terrain.json").write_text(
        json.dumps(meta, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    log(f"  done in {time.monotonic() - started:.0f} s")
    return out
