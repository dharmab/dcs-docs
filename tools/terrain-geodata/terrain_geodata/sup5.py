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


# Share of a strip's triangles inside a thinner strip for it to count as a copy.
_COVERED_FRACTION = 0.5
# A strip shorter than this many widths is a dot, not a line.
_DOT_WIDTHS = 3
# Loose strip ends are joined to another strip this many strip widths away.
_BRIDGE_WIDTHS = 1.5
# A line is dashed when this share of loose ends have another loose end within
# this many times the median gap between ends.
_DASHED_FRACTION = 0.75
_DASH_GAP_SPREAD = 1.25


def _edge_ids(tris: np.ndarray) -> np.ndarray:
    """``(n, 3)`` ids of each triangle's edges; shared edges get the same id."""
    a, b = tris, np.roll(tris, -1, axis=1)
    swap = (a[..., 0] > b[..., 0]) | (
        (a[..., 0] == b[..., 0]) & (a[..., 1] > b[..., 1])
    )
    lo = np.where(swap[..., None], b, a)
    hi = np.where(swap[..., None], a, b)
    flat = np.concatenate([lo, hi], axis=-1).reshape(-1, 4)
    _, inverse = np.unique(flat, axis=0, return_inverse=True)
    return inverse.reshape(-1, 3)


def _strip_width(tris: np.ndarray) -> float:
    """Median shortest edge: the width of a strip of thin quads."""
    edges = np.linalg.norm(tris - np.roll(tris, -1, axis=1), axis=2)
    return float(np.median(edges.min(axis=1)))


def _split_strips(tris: np.ndarray) -> list[np.ndarray]:
    """Group triangles that are joined by shared edges."""
    ids = _edge_ids(tris).ravel()
    parent = np.arange(len(tris))

    def root(i: int) -> int:
        while parent[i] != i:
            parent[i] = parent[parent[i]]
            i = parent[i]
        return i

    order = np.argsort(ids, kind="stable")
    tri = order // 3
    same = ids[order][1:] == ids[order][:-1]
    for i, j in zip(tri[:-1][same], tri[1:][same], strict=True):
        ri, rj = root(i), root(j)
        if ri != rj:
            parent[ri] = rj
    labels = np.array([root(i) for i in range(len(tris))])
    _, labels = np.unique(labels, return_inverse=True)
    return [tris[labels == k] for k in range(labels.max() + 1)]


def _is_dot(tris: np.ndarray, width: float) -> bool:
    box = shapely.oriented_envelope(shapely.multipoints(tris.reshape(-1, 2)))
    c = shapely.get_coordinates(box)
    if len(c) < 4:
        return True
    length = max(np.hypot(*(c[1] - c[0])), np.hypot(*(c[2] - c[1])))
    return length < _DOT_WIDTHS * width


def _keep_line_strips(strips: list[np.ndarray]) -> list[np.ndarray]:
    """Drop dots, and keep the thinnest copy of a line drawn several times."""
    widths = np.array([_strip_width(s) for s in strips])
    lines = [i for i, s in enumerate(strips) if not _is_dot(s, widths[i])]
    strips = [strips[i] for i in lines]
    widths = widths[lines]
    tris = np.concatenate(strips)
    owner = np.repeat(np.arange(len(strips)), [len(s) for s in strips])
    tree = shapely.STRtree(shapely.polygons(tris))
    # A wider copy's triangle centres can sit on the thinner copy's edge.
    inside, hit = tree.query(
        shapely.points(tris.mean(axis=1)),
        predicate="dwithin",
        distance=widths[owner] / 2,
    )
    kept = np.zeros(len(strips), dtype=bool)
    for i in np.argsort(widths, kind="stable"):
        mine = owner[inside] == i
        covered = np.unique(inside[mine][kept[owner[hit[mine]]]])
        if len(covered) <= _COVERED_FRACTION * len(strips[i]):
            kept[i] = True
    return [s for s, k in zip(strips, kept, strict=True) if k]


def _centreline_segments(tris: np.ndarray) -> np.ndarray:
    ids = _edge_ids(tris)
    shared = np.bincount(ids.ravel())[ids] > 1
    a, b = tris, np.roll(tris, -1, axis=1)
    mids = np.round((a + b) / 2, _SNAP_DECIMALS)  # (n, 3, 2)
    length = np.linalg.norm(b - a, axis=-1)

    two = shared.sum(axis=1) == 2
    segments = [mids[two][shared[two]].reshape(-1, 2, 2)]
    one = shared.sum(axis=1) == 1
    if one.any():
        end_len = np.where(shared[one], np.inf, length[one])
        end = mids[one, end_len.argmin(axis=1)]
        diag = mids[one][shared[one]]
        segments.append(np.stack([diag, end], axis=1))
    seg = np.concatenate(segments)
    return seg[np.any(seg[:, 0] != seg[:, 1], axis=1)]


def _gap_tolerance(ends: np.ndarray, width: float) -> float:
    """How far apart two loose ends can be and still be joined.

    A solid line only has small gaps where strips overlap at a corner. In a
    dashed line nearly every end is one dash gap from the next dash's end.
    """
    tolerance = _BRIDGE_WIDTHS * width
    if len(ends) < 2:
        return tolerance
    points = shapely.points(ends)
    _, dist = shapely.STRtree(points).query_nearest(
        points, exclusive=True, return_distance=True, all_matches=False
    )
    gap = float(np.median(dist))
    if np.mean(dist <= _DASH_GAP_SPREAD * gap) >= _DASHED_FRACTION:
        tolerance = max(tolerance, _DASH_GAP_SPREAD * gap)
    return tolerance


def _bridge_gaps(seg: np.ndarray, width: float) -> np.ndarray:
    """Segments joining loose chain ends across gaps and dash gaps.

    The closest pairs of loose ends are joined first. An end with no loose end
    left nearby is joined to the nearest point on another chain, such as where
    one border meets another.
    """
    points, counts = np.unique(seg.reshape(-1, 2), axis=0, return_counts=True)
    ends = points[counts == 1]
    tolerance = _gap_tolerance(ends, width)
    chains = shapely.get_parts(shapely.line_merge(shapely.multilinestrings(seg)))
    # Which chain each loose end belongs to.
    chain_of = shapely.STRtree(chains).query_nearest(shapely.points(ends))[1]

    tree = shapely.STRtree(shapely.points(ends))
    i, j = tree.query(shapely.points(ends), predicate="dwithin", distance=tolerance)
    pair = (i < j) & (chain_of[i] != chain_of[j])
    i, j = i[pair], j[pair]
    dist = np.hypot(*(ends[i] - ends[j]).T)
    used = np.zeros(len(ends), dtype=bool)
    bridges = []
    for k in np.argsort(dist, kind="stable"):
        if not used[i[k]] and not used[j[k]]:
            used[i[k]] = used[j[k]] = True
            bridges.append([ends[i[k]], ends[j[k]]])

    chain_tree = shapely.STRtree(chains)
    for e in np.flatnonzero(~used):
        p = shapely.Point(ends[e])
        near = [
            c
            for c in chain_tree.query(p, predicate="dwithin", distance=tolerance)
            if c != chain_of[e]
        ]
        if near:
            c = min(near, key=lambda c: chains[c].distance(p))
            target = shapely.get_coordinates(shapely.shortest_line(p, chains[c]))[1]
            # Not snapped: rounding would move the point off the chain, and the
            # merge would split the chain at both points.
            bridges.append([ends[e], target])
    bridges = np.array(bridges).reshape(-1, 2, 2)
    return bridges[np.any(bridges[:, 0] != bridges[:, 1], axis=1)]


def strip_centrelines(parts: list[np.ndarray]) -> np.ndarray:
    """Centreline segments of lines drawn as thin triangle strips, ``(n, 2, 2)``.

    Some maps draw lines as strips of quads, each split into two triangles.
    Inside a strip, each triangle shares two edges with its neighbours (the edge
    across the strip and the quad's diagonal), and the segment between their
    midpoints follows the centreline. A triangle at the end of a strip shares
    only the diagonal; its shortest other edge is the strip's end.

    Strips too short to be lines (the dots of a dash-dot line) are dropped, and
    where a line is drawn several times at different widths, only the thinnest
    copy is used. Gaps between strips, where they overlap at a corner or between
    the dashes of a dashed line, are bridged.
    """
    strips = _keep_line_strips(_split_strips(np.concatenate(parts)))
    tris = np.concatenate(strips)
    seg = _centreline_segments(tris)
    return np.concatenate([seg, _bridge_gaps(seg, _strip_width(tris))])


def build_geometry(primitive: str, parts: list[np.ndarray]) -> list[BaseGeometry]:
    """Merge primitives into lines or polygons."""
    prims = np.concatenate(parts)
    if primitive == "LINELIST":
        lines = shapely.linestrings(prims)
        merged = shapely.line_merge(shapely.union_all(lines))
        # Noding can leave zero-length stubs where a line ends on another.
        min_length = 10.0**-_SNAP_DECIMALS
        return [g for g in shapely.get_parts(merged) if g.length >= min_length]
    rings = np.concatenate([prims, prims[:, :1]], axis=1)
    tris = shapely.polygons(rings)
    tris = tris[shapely.area(tris) > 0]
    merged = shapely.union_all(shapely.make_valid(tris))
    return [g for g in shapely.get_parts(merged) if g.geom_type == "Polygon"]


@dataclass
class LineSet:
    """Every primitive of one material and colour, from the finest group."""

    material: str
    primitive: str
    color_index: str
    parts: list[np.ndarray]  # (n, k, 2) arrays of (easting, northing) = (z, x)

    @property
    def label(self) -> str:
        material = self.material or "(unnamed)"
        return f"{material}/{self.primitive}/colorIndex={self.color_index}"


def read_line_sets(path: Path) -> list[LineSet]:
    """Read the map overlay's line and polygon sets in DCS (easting=z, northing=x),
    leaving out the MGRS grid and graticule."""
    data_offset, records = read_records(path)
    by_key: dict[tuple[str, str, str], list[MapRecord]] = defaultdict(list)
    for rec in records:
        if rec.material not in ("MGRS", "Line"):  # grid and graticule
            by_key[(rec.material, rec.primitive, rec.color_index)].append(rec)

    sets: list[LineSet] = []
    with BulkData(path, data_offset) as bulk:
        for (material, primitive, color), recs in sorted(by_key.items()):
            finest = min(r.group for r in recs)
            parts = [_primitives(bulk, r) for r in recs if r.group == finest]
            parts = [p for p in parts if len(p)]
            if parts:
                sets.append(LineSet(material, primitive, color, parts))
    return sets


def assign_layers(
    sets: list[LineSet],
    classify: LineClassifier | None = None,
    overrides: dict[tuple[str, str], str] | None = None,
) -> tuple[dict[str, list[np.ndarray]], dict[str, str]]:
    """Sort line sets into output layers.

    ``overrides`` maps ``(material, colorIndex)`` to a layer for line sets the
    mesh check cannot place. A triangle set overridden to a line layer is a line
    drawn as a thin strip and is reduced to its centreline. Returns
    ``(parts by layer, decisions)``, where
    ``decisions`` records which layer each material/colour set went to, or
    ``"skipped"``. Pass each layer's parts to ``build_geometry``.
    """
    parts_by_layer: dict[str, list[np.ndarray]] = defaultdict(list)
    decisions: dict[str, str] = {}
    for s in sets:
        layer = (overrides or {}).get((s.material, s.color_index)) or _layer_for(
            s.material, s.primitive, s.parts, classify
        )
        if layer is None:
            decisions[s.label] = "skipped"
            continue
        if LAYERS[layer] == s.primitive:
            parts_by_layer[layer].extend(s.parts)
        elif LAYERS[layer] == "LINELIST" and s.primitive == "TRI":
            parts_by_layer[layer].append(strip_centrelines(s.parts))
        else:
            decisions[s.label] = "skipped"
            continue
        decisions[s.label] = layer
    return dict(parts_by_layer), decisions
