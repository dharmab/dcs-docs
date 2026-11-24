"""Rasterize land cover from the terrain mesh (``Surface/<terrain>.surface5``).

The terrain mesh is split into square tiles (typically about 17 km across), each a
node with its own translation. The file repeats the whole tiling at several
levels of detail; the first group is the most detailed, and the tile count of
that group is the ``u32`` just before the first node matrix.

Within a tile:

- ``Pbase`` holds the tile's vertex positions (float3, roughly 50 m apart in
  detailed areas). It follows all the tile's material records.
- The ``Surface5.0`` record holds the base triangles (``TRI``, indices into
  ``Pbase``) and a per-triangle bit field ``TRITYPE``.
- Overlay records (fields, forest, towns, rivers, ...) pick a subset of
  ``Pbase`` with ``baseIndex`` and triangulate it with their own ``TRI``.

The material records carry class-specific trailers that this tool does not
decode, so records are located by pattern rather than parsed sequentially.

``TRITYPE`` bits, worked out by rendering each bit on its own:

=====  ==========================================
bit    meaning
=====  ==========================================
1      sea
2      lake
4      river
8      road
16     railway
32     runway
64     town
128    field
256    beach / shoreline
=====  ==========================================

Forest has no bit; it comes from overlay records whose material name is
``Forest``.
"""

from __future__ import annotations

import re
import struct
from dataclasses import dataclass, field
from pathlib import Path

import cv2
import numpy as np

from .landscape import IDENTITY_ROTATION, BulkData, FormatError, Stream, read_header

SEA, LAKE, RIVER, ROAD, RAIL, RUNWAY, TOWN, FIELD, BEACH = (
    1,
    2,
    4,
    8,
    16,
    32,
    64,
    128,
    256,
)


@dataclass(frozen=True)
class LandCoverClass:
    value: int
    name: str
    color: tuple[int, int, int]
    description: str


# Drawn in this order, so later classes win where they overlap.
CLASSES = [
    LandCoverClass(0, "nodata", (0, 0, 0), "Outside the terrain mesh"),
    LandCoverClass(1, "land", (232, 222, 186), "Open ground not covered below"),
    LandCoverClass(2, "field", (206, 230, 150), "Farmland"),
    LandCoverClass(3, "forest", (70, 140, 70), "Forest"),
    LandCoverClass(4, "town", (214, 96, 72), "Built-up area"),
    LandCoverClass(5, "beach", (246, 236, 160), "Beach and shoreline strip"),
    LandCoverClass(6, "river", (96, 170, 250), "River surface"),
    LandCoverClass(7, "lake", (70, 130, 230), "Lake or reservoir"),
    LandCoverClass(8, "sea", (36, 80, 170), "Sea"),
    LandCoverClass(9, "runway", (60, 60, 60), "Runway and airfield paving"),
]
CLASS_VALUE = {c.name: c.value for c in CLASSES}

# Base-mesh bits per class, in draw order.
_BIT_CLASSES = [
    ("field", FIELD),
    ("town", TOWN),
    ("beach", BEACH),
    ("river", RIVER),
    ("lake", LAKE),
    ("sea", SEA),
    ("runway", RUNWAY),
]

# The low-detail mesh at the map edges has a few very long triangles flagged as
# town or field. Real features never produce triangles this large.
_MAX_FEATURE_EDGE_M = 3000.0
_SIZE_FILTERED = {"field", "forest", "town", "runway"}

_STREAM_SHAPES = {
    "TRI": (6, 12),
    "TRITYPE": (4, 4),
    "baseIndex": (4, 4),
    "P": (2, 12),
    "Pbase": (2, 12),
}
_STREAM_RX = re.compile(
    rb"\x01\x00\x00\x00([\x01-\x10])\x00\x00\x00(TRITYPE|TRI|baseIndex|Pbase|P)"
    rb"(.{2})(.{2})(.{4})(.{8})(.{6})",
    re.S,
)
_MATERIAL_RX = re.compile(
    rb"\x02\x00\x00\x00([\x03-\x30])\x00\x00\x00([A-Za-z0-9_]+\d\.\d)"
    rb"([\x01-\x30])\x00\x00\x00([A-Za-z_]+)",
    re.S,
)
_NODE_RX = re.compile(re.escape(IDENTITY_ROTATION))


@dataclass
class TileRecord:
    material_class: str
    material: str
    streams: dict[str, Stream]


@dataclass
class Tile:
    translation: tuple[float, float, float]
    bbox: tuple[float, ...]
    records: list[TileRecord] = field(default_factory=list)
    pbase: Stream | None = None


@dataclass
class LandCover:
    data: np.ndarray  # uint8, row 0 = north
    west: float  # easting (DCS z) of the left edge
    north: float  # northing (DCS x) of the top edge
    resolution: float
    tile_count: int
    # Pixels touched by road / railway triangles, grown by one pixel. Used to
    # tell roads from railways in the map overlay, whose colours vary by terrain.
    road_mask: np.ndarray
    rail_mask: np.ndarray

    def mask_fractions(self, en: np.ndarray) -> tuple[float, float]:
        """Fraction of (easting, northing) points on road and on rail pixels."""
        h, w = self.data.shape
        col = np.floor((en[:, 0] - self.west) / self.resolution).astype(np.int64)
        row = np.floor((self.north - en[:, 1]) / self.resolution).astype(np.int64)
        inside = (col >= 0) & (col < w) & (row >= 0) & (row < h)
        if not inside.any():
            return 0.0, 0.0
        col, row = col[inside], row[inside]
        return (
            float(self.road_mask[row, col].mean()),
            float(self.rail_mask[row, col].mean()),
        )


def _scan_tile(seg: bytes, tile: Tile) -> None:
    events: list[tuple[int, str, object]] = []
    for m in _STREAM_RX.finditer(seg):
        name = m.group(2).decode()
        if m.group(1)[0] != len(name):
            continue
        elem_type = struct.unpack("<H", m.group(3))[0]
        elem_size = struct.unpack("<H", m.group(4))[0]
        if (elem_type, elem_size) != _STREAM_SHAPES[name]:
            continue
        stream = Stream(
            name,
            elem_type,
            elem_size,
            struct.unpack("<I", m.group(5))[0] == 1,
            struct.unpack("<Q", m.group(6))[0],
            int.from_bytes(m.group(7), "little"),
        )
        events.append((m.start(), "stream", stream))
    for m in _MATERIAL_RX.finditer(seg):
        if m.group(1)[0] != len(m.group(2)) or m.group(3)[0] != len(m.group(4)):
            continue
        events.append(
            (m.start(), "material", (m.group(2).decode(), m.group(4).decode()))
        )
    events.sort(key=lambda e: e[0])
    pending: dict[str, Stream] = {}
    for _, kind, value in events:
        if kind == "stream":
            assert isinstance(value, Stream)
            pending[value.name] = value
        else:
            assert isinstance(value, tuple)
            tile.records.append(TileRecord(value[0], value[1], pending))
            pending = {}
    tile.pbase = pending.get("Pbase")


@dataclass(frozen=True)
class Grid:
    """The land cover raster: pixel size, top-left corner and size in pixels."""

    west: float  # easting (DCS z) of the left edge
    north: float  # northing (DCS x) of the top edge
    resolution: float
    width: int
    height: int


@dataclass(frozen=True)
class TilePlan:
    """Where the most detailed tiles sit in a surface5 file, for splitting work."""

    data_offset: int
    grid: Grid
    # Byte range of each tile's node in the metadata, in file order.
    spans: list[tuple[int, int]]


@dataclass
class TileRaster:
    """One tile drawn on its own small canvas, to be composited in tile order."""

    row: int
    col: int
    img: np.ndarray
    road: np.ndarray
    rail: np.ndarray


def plan_tiles(path: Path, resolution: float) -> TilePlan:
    """Index the most detailed tile group and the raster grid that covers it."""
    data_offset, type_name = read_header(path)
    if type_name != "landscape5::Surface5File":
        raise FormatError(f"{path} is {type_name}, not a surface5 file")
    with path.open("rb") as f:
        meta = f.read(data_offset)
    nodes = [m.start() for m in _NODE_RX.finditer(meta)]
    if not nodes:
        raise FormatError(f"no tiles found in {path}")
    count = struct.unpack_from("<I", meta, nodes[0] - 8)[0]
    if not 0 < count <= len(nodes):
        raise FormatError(f"implausible tile count {count} in {path}")
    spans = [
        (nodes[i], nodes[i + 1] if i + 1 < len(nodes) else len(meta))
        for i in range(count)
    ]
    tiles = [_tile_node(meta, start) for start, _ in spans]
    # Kola repeats one tile; many repeats would mean the group count is wrong.
    duplicates = len(tiles) - len({t.translation for t in tiles})
    if duplicates > len(tiles) // 100:
        raise FormatError(f"{duplicates} duplicate tiles in the first group")
    west, south, east, north = _extent(tiles, resolution)
    grid = Grid(
        west,
        north,
        resolution,
        round((east - west) / resolution),
        round((north - south) / resolution),
    )
    return TilePlan(data_offset, grid, spans)


def _tile_node(meta: bytes, start: int) -> Tile:
    matrix = struct.unpack_from("<16f", meta, start)
    bbox = struct.unpack_from("<6f", meta, start + 64)
    return Tile((matrix[12], matrix[13], matrix[14]), bbox)


def _extent(tiles: list[Tile], res: float) -> tuple[float, float, float, float]:
    west = min(t.translation[2] + t.bbox[2] for t in tiles)
    east = max(t.translation[2] + t.bbox[5] for t in tiles)
    south = min(t.translation[0] + t.bbox[0] for t in tiles)
    north = max(t.translation[0] + t.bbox[3] for t in tiles)
    return (
        np.floor(west / res) * res,
        np.floor(south / res) * res,
        np.ceil(east / res) * res,
        np.ceil(north / res) * res,
    )


def _max_edge(tris: np.ndarray) -> np.ndarray:
    """Longest edge of each triangle in an ``(n, 3, 2)`` array."""
    d = tris - np.roll(tris, 1, axis=1)
    return np.sqrt((d**2).sum(axis=2)).max(axis=1)


def rasterize_tiles(
    path: Path, data_offset: int, grid: Grid, spans: list[tuple[int, int]]
) -> list[TileRaster]:
    """Draw a run of consecutive tiles from ``TilePlan.spans``, each on its own
    canvas. Compositing every run in order with ``assemble`` gives the same
    raster as drawing all tiles onto one canvas."""
    first, last = spans[0][0], spans[-1][1]
    with path.open("rb") as f:
        f.seek(first)
        meta = f.read(last - first)
    rasters: list[TileRaster] = []
    with BulkData(path, data_offset) as bulk:
        for start, end in spans:
            seg = meta[start - first : end - first]
            tile = _tile_node(seg, 0)
            _scan_tile(seg, tile)
            raster = _rasterize_tile(bulk, tile, grid)
            if raster is not None:
                rasters.append(raster)
    return rasters


_IMG, _ROAD, _RAIL = range(3)


def _rasterize_tile(bulk: BulkData, tile: Tile, grid: Grid) -> TileRaster | None:
    base = next((r for r in tile.records if "TRITYPE" in r.streams), None)
    if tile.pbase is None or base is None:
        return None
    pos = bulk.positions(tile.pbase)
    en = np.stack(
        [pos[:, 2] + tile.translation[2], pos[:, 0] + tile.translation[0]], axis=1
    )
    tri = bulk.indices(base.streams["TRI"])
    types = bulk.array(base.streams["TRITYPE"], "<u4")
    if len(types) != len(tri) or (len(tri) and tri.max() >= len(en)):
        raise FormatError("base mesh streams disagree; layout changed?")
    px = _to_px(en, grid)
    forest_en, forest_px = _forest_triangles(bulk, tile, en, px, grid)

    # Fills in draw order, as (canvas, triangle pixel coordinates, value).
    # Vertices are converted to pixels once and triangles index into them.
    fills: list[tuple[int, np.ndarray, int]] = []

    def fill(canvas: int, tris_px: np.ndarray, value: int) -> None:
        if len(tris_px):
            fills.append((canvas, tris_px, value))

    def draw(cls: str, tris_px: np.ndarray, tris_en: np.ndarray | None) -> None:
        if cls in _SIZE_FILTERED and len(tris_px):
            assert tris_en is not None
            tris_px = tris_px[_max_edge(tris_en) <= _MAX_FEATURE_EDGE_M]
        fill(_IMG, tris_px, CLASS_VALUE[cls])

    fill(_IMG, px[tri], CLASS_VALUE["land"])
    for cls, bit in _BIT_CLASSES:
        if cls == "town":
            draw("forest", forest_px, forest_en)  # over fields, under towns
        sel = tri[(types & bit) != 0]
        draw(cls, px[sel], en[sel] if cls in _SIZE_FILTERED else None)
    fill(_ROAD, px[tri[(types & ROAD) != 0]], 1)
    fill(_RAIL, px[tri[(types & RAIL) != 0]], 1)
    if not fills:
        return None

    # Pixels any fill can touch, clipped to the grid. Every fill is a subset of
    # the base mesh or of the forest. Shifting by whole pixels leaves the
    # rasterization unchanged.
    used = np.concatenate([px[np.unique(tri)], forest_px.reshape(-1, 2)])
    lo, hi = used.min(axis=0), used.max(axis=0)
    col0 = max(int(lo[0]) // 16 - 1, 0)
    row0 = max(int(lo[1]) // 16 - 1, 0)
    col1 = min(int(hi[0]) // 16 + 2, grid.width)
    row1 = min(int(hi[1]) // 16 + 2, grid.height)
    if col0 >= col1 or row0 >= row1:
        return None
    canvases = [np.zeros((row1 - row0, col1 - col0), np.uint8) for _ in range(3)]
    offset = np.array([col0, row0], np.int32) * 16
    for canvas, tris_px, value in fills:
        # OpenCV reads each row of an (n, 3) two-channel array as one polygon.
        cv2.fillPoly(canvases[canvas], tris_px - offset, value, shift=4)
    return TileRaster(row0, col0, *canvases)


def assemble(grid: Grid, rasters: list[TileRaster], tile_count: int) -> LandCover:
    """Composite tile rasters, given in tile order, into the land cover."""
    img = np.zeros((grid.height, grid.width), np.uint8)
    road_mask = np.zeros_like(img)
    rail_mask = np.zeros_like(img)
    for r in rasters:
        h, w = r.img.shape
        window = (slice(r.row, r.row + h), slice(r.col, r.col + w))
        # Every class value is non-zero, so a zero pixel is one the tile left alone.
        np.copyto(img[window], r.img, where=r.img != 0)
        road_mask[window] |= r.road
        rail_mask[window] |= r.rail
    kernel = np.ones((3, 3), np.uint8)
    return LandCover(
        img,
        grid.west,
        grid.north,
        grid.resolution,
        tile_count,
        cv2.dilate(road_mask, kernel),
        cv2.dilate(rail_mask, kernel),
    )


def _to_px(en: np.ndarray, grid: Grid) -> np.ndarray:
    """(easting, northing) to pixel coordinates with 4 sub-pixel bits.

    OpenCV puts pixel centres on integer coordinates."""
    px = np.empty(en.shape, np.int32)
    px[..., 0] = np.round(((en[..., 0] - grid.west) / grid.resolution - 0.5) * 16)
    px[..., 1] = np.round(((grid.north - en[..., 1]) / grid.resolution - 0.5) * 16)
    return px


def _forest_triangles(
    bulk: BulkData, tile: Tile, en: np.ndarray, px: np.ndarray, grid: Grid
) -> tuple[np.ndarray, np.ndarray]:
    """Forest triangles as ``(n, 3, 2)`` arrays in metres and in pixels."""
    parts_en: list[np.ndarray] = [np.empty((0, 3, 2))]
    parts_px: list[np.ndarray] = [np.empty((0, 3, 2), np.int32)]
    for rec in tile.records:
        if rec.material != "Forest" or "TRI" not in rec.streams:
            continue
        tri = bulk.indices(rec.streams["TRI"])
        if "baseIndex" in rec.streams:
            base_index = bulk.array(rec.streams["baseIndex"], "<u4")
            if len(base_index) and base_index.max() >= len(en):
                continue
            verts, verts_px = en[base_index], px[base_index]
        elif "P" in rec.streams:
            p = bulk.positions(rec.streams["P"])
            verts = np.stack(
                [p[:, 2] + tile.translation[2], p[:, 0] + tile.translation[0]],
                axis=1,
            )
            verts_px = _to_px(verts, grid)
        else:
            verts, verts_px = en, px
        if len(tri) and tri.max() < len(verts):
            parts_en.append(verts[tri])
            parts_px.append(verts_px[tri])
    return np.concatenate(parts_en), np.concatenate(parts_px)


def class_stats(lc: LandCover) -> dict[str, float]:
    """Area of each class in square kilometres."""
    counts = np.bincount(lc.data.ravel(), minlength=len(CLASSES))
    px_km2 = (lc.resolution / 1000.0) ** 2
    return {c.name: round(float(counts[c.value]) * px_km2, 1) for c in CLASSES}
