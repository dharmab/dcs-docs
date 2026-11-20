"""Read the Mission Editor map overlay (``Map/<terrain>.sup5``).

This file holds the vector linework the Mission Editor draws over its map: roads,
railways, rivers, power lines, borders, town outlines, runways, the MGRS grid and
the lat/long graticule. Land, water and forest fills are not in this file; the
editor shades those from the terrain mesh (see ``surface5``).

Layout after the common header (see ``landscape``)::

    u32  0
    f32  bbox[6]                  unused, always an empty box
    u32  group count              zoom levels; group 0 is the most detailed
    u64  0
    repeat per group:
        u64  node count
        repeat per node:
            f32  matrix[16]        translation in elements 12..14
            f32  bbox[6]
            u64  record count
            record[record count]
        ...  per-group lookup table (skipped)

    record:
        u32  2
        u32  vertex count
        u32  stream count
        stream[stream count]       "P" positions plus "LINELIST" or "TRI" indices
        u32  usually 0
        u32  2
        str  material class        "Map4.0"
        str  material name         "Road", "River", "Town", ...
        u32  parameter count
        repeat: str key, u32 type, u32 value count, str value[value count]
        i32  -1
        u32  0

A feature can appear in several groups at different detail; it is taken from the
lowest-numbered group that contains it.
"""

from __future__ import annotations

import re
from collections import defaultdict
from collections.abc import Callable
from dataclasses import dataclass
from pathlib import Path

import numpy as np
import shapely
from shapely.geometry.base import BaseGeometry

from .landscape import (
    IDENTITY_ROTATION,
    TYPE_NAME_OFFSET,
    BulkData,
    FormatError,
    Reader,
    Stream,
    read_header,
)


@dataclass(frozen=True)
class MapRecord:
    group: int
    translation: tuple[float, float, float]
    material: str
    color_index: str
    primitive: str
    positions: Stream
    indices: Stream


# Output layer -> primitive. Material names and colour indexes are not consistent
# between terrains (Caucasus draws railways as "Road" with colorIndex 8,
# GermanyCW as "Road" with colorIndex 11, Syria as "Rail"), so road-like lines
# are sorted into roads and railways by checking them against the terrain mesh.
LAYERS = {
    "roads": "LINELIST",
    "railways": "LINELIST",
    "rivers": "LINELIST",
    "power_lines": "LINELIST",
    "borders": "LINELIST",
    "urban_areas": "TRI",
    "runways": "TRI",
}
_FIXED_LAYERS = {
    ("River", "LINELIST"): "rivers",
    ("ELT", "LINELIST"): "power_lines",
    ("Undef", "LINELIST"): "borders",
    ("Town", "TRI"): "urban_areas",
    ("Runway", "TRI"): "runways",
}
_ROAD_LIKE = {"Road", "Rail", "Railway"}
# Share of a line set's vertices that must sit on road (or rail) mesh triangles.
_MATCH_FRACTION = 0.6

# Called with (easting, northing) points; returns (road fraction, rail fraction).
LineClassifier = Callable[[np.ndarray], tuple[float, float]]

_NEXT_GROUP = re.compile(rb"(.{8})" + re.escape(IDENTITY_ROTATION[:24]), re.S)

# Vertices are float32 relative to each node; snap so segments from neighbouring
# nodes join when merged.
_SNAP_DECIMALS = 2


def _read_record(r: Reader, group: int, translation: tuple[float, float, float]):
    if r.u32() != 2:
        raise FormatError(f"unexpected record version at {r.pos - 4:#x}")
    r.u32()  # vertex count
    streams = {s.name: s for s in (r.stream() for _ in range(r.u32()))}
    r.u32()  # usually 0; 23 on some GermanyCW records, meaning unknown
    if r.u32() != 2:
        raise FormatError(f"unexpected material version at {r.pos - 4:#x}")
    r.string(64)  # material class
    material = r.string(64)
    params: dict[str, list[str]] = {}
    for _ in range(r.u32()):
        key = r.string(64)
        r.u32()
        params[key] = [r.string(256) for _ in range(r.u32())]
    r.i32()
    r.u32()
    color_index = params.get("colorIndex", [""])[0]
    positions = streams.get("P")
    for primitive in ("LINELIST", "TRI"):
        if primitive in streams and positions is not None:
            return MapRecord(
                group,
                translation,
                material,
                color_index,
                primitive,
                positions,
                streams[primitive],
            )
    return None


def read_records(path: Path) -> tuple[int, list[MapRecord]]:
    """Parse every record in the file. Returns ``(data_offset, records)``."""
    data_offset, type_name = read_header(path)
    if type_name != "landscape5::sup5File":
        raise FormatError(f"{path} is {type_name}, not a sup5 file")
    with path.open("rb") as f:
        meta = f.read(data_offset)
    r = Reader(meta, TYPE_NAME_OFFSET)
    r.string()
    r.u32()
    r.f32(6)
    group_count = r.u32()
    r.u64()
    records: list[MapRecord] = []
    for group in range(group_count):
        if group > 0:
            m = _NEXT_GROUP.search(meta, r.pos, r.pos + 4096)
            if m is None:
                raise FormatError(f"group {group} not found after {r.pos:#x}")
            r.pos = m.start()
        for _ in range(r.u64()):
            matrix = r.f32(16)
            r.f32(6)
            translation = (matrix[12], matrix[13], matrix[14])
            for _ in range(r.u64()):
                rec = _read_record(r, group, translation)
                if rec is not None:
                    records.append(rec)
    return data_offset, records


def _layer_for(
    material: str,
    primitive: str,
    parts: list[np.ndarray],
    classify: LineClassifier | None,
) -> str | None:
    fixed = _FIXED_LAYERS.get((material, primitive))
    if fixed is not None:
        return fixed
    if primitive != "LINELIST" or material not in _ROAD_LIKE:
        return None
    if classify is not None:
        road, rail = classify(np.concatenate(parts).reshape(-1, 2))
        if rail >= _MATCH_FRACTION and rail >= road:
            return "railways"
        if road >= _MATCH_FRACTION:
            return "roads"
    # No mesh, or too coarse to match it (Sinai only draws its overlay at low
    # zoom): trust the material name.
    return "roads" if material == "Road" else "railways"


def _primitives(bulk: BulkData, rec: MapRecord) -> np.ndarray:
    """Primitives as ``(n, k, 2)`` arrays of (easting, northing) = (z, x)."""
    pos = bulk.positions(rec.positions)
    pos[:, 0] += rec.translation[0]
    pos[:, 2] += rec.translation[2]
    en = np.round(pos[:, [2, 0]], _SNAP_DECIMALS)
    idx = bulk.indices(rec.indices)
    if len(idx) and idx.max() >= len(en):
        raise FormatError(f"index out of range in {rec.material} record")
    return en[idx]


def _build_geometry(primitive: str, parts: list[np.ndarray]) -> list[BaseGeometry]:
    prims = np.concatenate(parts)
    if primitive == "LINELIST":
        lines = shapely.linestrings(prims)
        merged = shapely.line_merge(shapely.union_all(lines))
        return [g for g in shapely.get_parts(merged) if not g.is_empty]
    rings = np.concatenate([prims, prims[:, :1]], axis=1)
    tris = shapely.polygons(rings)
    tris = tris[shapely.area(tris) > 0]
    merged = shapely.union_all(shapely.make_valid(tris))
    return [g for g in shapely.get_parts(merged) if g.geom_type == "Polygon"]


def read_layers(
    path: Path,
    classify: LineClassifier | None = None,
    overrides: dict[tuple[str, str], str] | None = None,
) -> tuple[dict[str, list[BaseGeometry]], dict[str, str]]:
    """Read the map overlay as shapely geometry in DCS (easting=z, northing=x).

    ``overrides`` maps ``(material, colorIndex)`` to a layer for line sets the
    mesh check cannot place. Returns ``(layers, decisions)``, where
    ``decisions`` records which layer each material/colour set went to, or
    ``"skipped"``.
    """
    data_offset, records = read_records(path)
    by_key: dict[tuple[str, str, str], list[MapRecord]] = defaultdict(list)
    for rec in records:
        if rec.material not in ("MGRS", "Line"):  # grid and graticule
            by_key[(rec.material, rec.primitive, rec.color_index)].append(rec)

    parts_by_layer: dict[str, list[np.ndarray]] = defaultdict(list)
    decisions: dict[str, str] = {}
    with BulkData(path, data_offset) as bulk:
        for (material, primitive, color), recs in sorted(by_key.items()):
            finest = min(r.group for r in recs)
            parts = [_primitives(bulk, r) for r in recs if r.group == finest]
            parts = [p for p in parts if len(p)]
            if not parts:
                continue
            layer = (overrides or {}).get((material, color)) or _layer_for(
                material, primitive, parts, classify
            )
            label = f"{material or '(unnamed)'}/{primitive}/colorIndex={color}"
            if layer is None or LAYERS[layer] != primitive:
                decisions[label] = "skipped"
                continue
            decisions[label] = layer
            parts_by_layer[layer].extend(parts)

    layers = {
        layer: _build_geometry(prim, parts_by_layer[layer])
        if parts_by_layer[layer]
        else []
        for layer, prim in LAYERS.items()
    }
    return layers, decisions
