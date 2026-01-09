#!/usr/bin/env python3
"""
DCS Terrain Data Processor

Reads raw terrain JSON exports from DCS and generates:
1. Classified terrain regions (mountain, hill, plain, valley)
2. Water body identification (sea vs lake)
3. Settlement detection from road density
4. Road connectivity graph
5. Airport data with parking spots

Output: Markdown documentation for LLM consumption
"""

from __future__ import annotations

import argparse
import json
import math
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Any, TypedDict

import numpy as np
from matplotlib.path import Path as PolygonPath
from numpy.typing import NDArray
from scipy import ndimage
from scipy.spatial import ConvexHull
from sklearn.cluster import DBSCAN


# Type definitions for JSON data structures
class BoundsDict(TypedDict):
    """Map coordinate bounds."""

    minX: float
    maxX: float
    minZ: float
    maxZ: float


class MetadataDict(TypedDict):
    """Terrain export metadata."""

    theatre: str
    exportTime: str
    gridResolution: float
    bounds: BoundsDict
    version: str


class TerrainPointDict(TypedDict):
    """A single terrain sample point."""

    x: float
    z: float
    height: float
    surface: int
    lat: float
    lon: float


class RoadPointDict(TypedDict):
    """A road network point."""

    x: float
    z: float
    lat: float
    lon: float


class RoadEndpointDict(TypedDict):
    """A road segment endpoint."""

    x: float
    z: float


class RoadSegmentDict(TypedDict):
    """A road segment connecting two points."""

    from_: RoadEndpointDict
    to: RoadEndpointDict


class RoadsDict(TypedDict):
    """Road network data."""

    points: list[RoadPointDict]
    segments: list[dict[str, RoadEndpointDict]]


class ParkingSpotDict(TypedDict, total=False):
    """Airport parking spot data."""

    Term_Index: int
    Term_Type: int
    x: float
    z: float
    fDistToRW: float


class RunwayDict(TypedDict, total=False):
    """Airport runway data."""

    heading: float
    length: float
    width: float
    x: float
    z: float


class AirbaseDict(TypedDict, total=False):
    """Raw airbase data from JSON export."""

    name: str
    callsign: str
    x: float
    z: float
    height: float
    lat: float
    lon: float
    category: int
    parking: list[ParkingSpotDict]
    runways: list[RunwayDict]


class TerrainExportDict(TypedDict):
    """Complete terrain export JSON structure."""

    metadata: MetadataDict
    terrain: list[TerrainPointDict]
    roads: RoadsDict
    airbases: list[AirbaseDict]


class GridDict(TypedDict):
    """Processed terrain grid data."""

    elevation: NDArray[np.floating[Any]]
    surface: NDArray[np.int32]
    lat: NDArray[np.floating[Any]]
    lon: NDArray[np.floating[Any]]
    bounds: BoundsDict
    resolution: float
    shape: tuple[int, int]


@dataclass
class Region:
    """A classified terrain region."""

    name: str
    classification: str  # mountain, hill, plain, valley
    vertices: list[tuple[float, float]]  # (x, z) polygon
    center: tuple[float, float]
    area_km2: float
    avg_elevation: float
    lat_lon_center: tuple[float, float]

    def bounding_box(self) -> tuple[float, float, float, float]:
        """Return (min_x, max_x, min_z, max_z) bounding box."""
        if not self.vertices:
            return (0, 0, 0, 0)
        xs = [v[0] for v in self.vertices]
        zs = [v[1] for v in self.vertices]
        return (min(xs), max(xs), min(zs), max(zs))


@dataclass
class WaterBody:
    """A water body (sea, lake, reservoir)."""

    name: str
    body_type: str  # sea, lake, reservoir
    vertices: list[tuple[float, float]]
    center: tuple[float, float]
    area_km2: float
    lat_lon_center: tuple[float, float]


@dataclass
class Settlement:
    """A detected settlement from road density."""

    name: str
    center: tuple[float, float]
    road_density: float
    lat_lon_center: tuple[float, float]


@dataclass
class Airbase:
    """Airport/FARP/Carrier data."""

    name: str
    callsign: str
    x: float
    z: float
    height: float
    lat: float
    lon: float
    category: int
    parking: list[ParkingSpotDict]
    runways: list[RunwayDict]


class RegionIndex:
    """Spatial index for fast region lookups using grid-based bucketing.

    Divides the map into a grid of cells and precomputes which regions
    potentially overlap each cell. Point lookups only check regions in
    the relevant cell instead of all regions.
    """

    # Default cell size in meters (50km provides good balance)
    DEFAULT_CELL_SIZE = 50000

    def __init__(
        self,
        regions: list[Region],
        bounds: BoundsDict,
        cell_size: float = DEFAULT_CELL_SIZE,
    ) -> None:
        self.regions = regions
        self.bounds = bounds
        self.cell_size = cell_size

        # Calculate grid dimensions
        self.min_x = bounds["minX"]
        self.min_z = bounds["minZ"]
        self.nx = int(math.ceil((bounds["maxX"] - self.min_x) / cell_size)) + 1
        self.nz = int(math.ceil((bounds["maxZ"] - self.min_z) / cell_size)) + 1

        # Build the index: cell -> list of (region, polygon_path)
        self._index: dict[tuple[int, int], list[tuple[Region, PolygonPath]]] = (
            defaultdict(list)
        )
        self._build_index()

    def _cell_for_point(self, x: float, z: float) -> tuple[int, int]:
        """Return the grid cell indices for a point."""
        ix = int((x - self.min_x) / self.cell_size)
        iz = int((z - self.min_z) / self.cell_size)
        # Clamp to valid range
        ix = max(0, min(ix, self.nx - 1))
        iz = max(0, min(iz, self.nz - 1))
        return (ix, iz)

    def _cells_for_bbox(
        self, min_x: float, max_x: float, min_z: float, max_z: float
    ) -> list[tuple[int, int]]:
        """Return all grid cells that overlap a bounding box."""
        ix_min = max(0, int((min_x - self.min_x) / self.cell_size))
        ix_max = min(self.nx - 1, int((max_x - self.min_x) / self.cell_size))
        iz_min = max(0, int((min_z - self.min_z) / self.cell_size))
        iz_max = min(self.nz - 1, int((max_z - self.min_z) / self.cell_size))

        cells = []
        for ix in range(ix_min, ix_max + 1):
            for iz in range(iz_min, iz_max + 1):
                cells.append((ix, iz))
        return cells

    def _build_index(self) -> None:
        """Build the spatial index by assigning regions to grid cells."""
        for region in self.regions:
            if not region.vertices or len(region.vertices) < 3:
                continue

            # Create polygon path once per region
            polygon = PolygonPath(region.vertices)

            # Get bounding box and find overlapping cells
            min_x, max_x, min_z, max_z = region.bounding_box()
            cells = self._cells_for_bbox(min_x, max_x, min_z, max_z)

            # Add region to each overlapping cell
            for cell in cells:
                self._index[cell].append((region, polygon))

    def region_for_point(self, x: float, z: float) -> str | None:
        """Find which region contains a point.

        Returns the region name or None if the point is not in any region.
        """
        cell = self._cell_for_point(x, z)
        candidates = self._index.get(cell, [])

        for region, polygon in candidates:
            # Quick bounding box check
            min_x, max_x, min_z, max_z = region.bounding_box()
            if not (min_x <= x <= max_x and min_z <= z <= max_z):
                continue
            # Proper polygon containment test
            if polygon.contains_point((x, z)):
                return region.name

        return None


class TerrainExportError(Exception):
    """Error raised when terrain export validation fails."""

    pass


class TerrainProcessor:
    """Processes raw DCS terrain data into structured regions."""

    # Elevation thresholds (meters)
    MOUNTAIN_THRESHOLD = 2000
    HILL_THRESHOLD = 500
    HIGH_RELIEF_THRESHOLD = 500
    LOW_RELIEF_THRESHOLD = 100

    # Minimum region size (grid cells)
    MIN_REGION_CELLS = 10

    # Water body size thresholds (km^2)
    SEA_MIN_AREA = 100
    LAKE_MIN_AREA = 10

    # DBSCAN clustering parameters for settlement detection
    SETTLEMENT_CLUSTER_RADIUS = 10000  # eps: max distance between points (meters)
    SETTLEMENT_MIN_SAMPLES = 5  # min_samples: minimum points to form a cluster

    # Required fields for validation
    REQUIRED_TOP_LEVEL_KEYS = ("metadata", "terrain", "roads", "airbases")
    REQUIRED_METADATA_KEYS = ("theatre", "exportTime", "gridResolution", "bounds")
    REQUIRED_BOUNDS_KEYS = ("minX", "maxX", "minZ", "maxZ")

    json_path: Path
    data: TerrainExportDict
    grid: GridDict

    def __init__(self, json_path: Path) -> None:
        self.json_path = json_path
        self.data = self._load_data()
        self._validate_data()
        self.grid = self._build_grid()

    def _load_data(self) -> TerrainExportDict:
        with open(self.json_path) as f:
            return json.load(f)

    def _validate_data(self) -> None:
        """Validate that the JSON export has the required structure.

        Raises:
            TerrainExportError: If required fields are missing or malformed.
        """
        errors: list[str] = []

        # Check top-level keys
        for key in self.REQUIRED_TOP_LEVEL_KEYS:
            if key not in self.data:
                errors.append(f"Missing required top-level key: '{key}'")

        if "metadata" not in self.data:
            errors.append("Cannot validate metadata: 'metadata' key is missing")
        else:
            metadata = self.data["metadata"]
            if not isinstance(metadata, dict):
                errors.append("'metadata' must be a dictionary")
            else:
                # Check metadata keys
                for key in self.REQUIRED_METADATA_KEYS:
                    if key not in metadata:
                        errors.append(f"Missing required metadata key: '{key}'")

                # Check bounds structure
                if "bounds" in metadata:
                    bounds = metadata["bounds"]
                    if not isinstance(bounds, dict):
                        errors.append("'metadata.bounds' must be a dictionary")
                    else:
                        for key in self.REQUIRED_BOUNDS_KEYS:
                            if key not in bounds:
                                errors.append(
                                    f"Missing required bounds key: '{key}'"
                                )

        # Check terrain is a list
        if "terrain" in self.data and not isinstance(self.data["terrain"], list):
            errors.append("'terrain' must be a list of sample points")

        # Check roads structure
        if "roads" in self.data:
            roads = self.data["roads"]
            if not isinstance(roads, dict):
                errors.append("'roads' must be a dictionary")
            elif "points" not in roads or "segments" not in roads:
                errors.append("'roads' must contain 'points' and 'segments' keys")

        # Check airbases is a list
        if "airbases" in self.data and not isinstance(self.data["airbases"], list):
            errors.append("'airbases' must be a list")

        if errors:
            error_msg = f"Invalid terrain export from {self.json_path}:\n"
            error_msg += "\n".join(f"  - {e}" for e in errors)
            raise TerrainExportError(error_msg)

    def _build_grid(self) -> GridDict:
        """Convert terrain samples to a 2D grid for spatial analysis."""
        terrain = self.data["terrain"]
        bounds = self.data["metadata"]["bounds"]
        resolution = self.data["metadata"]["gridResolution"]

        # Calculate grid dimensions
        nx = int((bounds["maxX"] - bounds["minX"]) / resolution) + 1
        nz = int((bounds["maxZ"] - bounds["minZ"]) / resolution) + 1

        # Initialize grids
        elevation = np.full((nx, nz), np.nan)
        surface = np.zeros((nx, nz), dtype=np.int32)
        lat_grid = np.full((nx, nz), np.nan)
        lon_grid = np.full((nx, nz), np.nan)

        for point in terrain:
            ix = int((point["x"] - bounds["minX"]) / resolution)
            iz = int((point["z"] - bounds["minZ"]) / resolution)

            if 0 <= ix < nx and 0 <= iz < nz:
                elevation[ix, iz] = point["height"]
                surface[ix, iz] = point["surface"]
                lat_grid[ix, iz] = point["lat"]
                lon_grid[ix, iz] = point["lon"]

        return {
            "elevation": elevation,
            "surface": surface,
            "lat": lat_grid,
            "lon": lon_grid,
            "bounds": bounds,
            "resolution": resolution,
            "shape": (nx, nz),
        }

    def classify_terrain(self) -> list[Region]:
        """Classify terrain into regions by elevation characteristics."""
        elevation = self.grid["elevation"]
        resolution = self.grid["resolution"]
        bounds = self.grid["bounds"]

        # Compute local terrain characteristics
        # Use Gaussian smoothing to reduce noise
        smoothed = ndimage.gaussian_filter(np.nan_to_num(elevation, nan=0), sigma=2)

        # Compute local relief (max - min in neighborhood)
        relief = ndimage.maximum_filter(smoothed, size=5) - ndimage.minimum_filter(
            smoothed, size=5
        )

        # Compute local average for valley detection
        local_avg = ndimage.uniform_filter(smoothed, size=7)

        # Classification masks
        # Mountains: high elevation OR high relief at moderate elevation
        mountain_mask = (smoothed > self.MOUNTAIN_THRESHOLD) | (
            (smoothed > self.HILL_THRESHOLD) & (relief > self.HIGH_RELIEF_THRESHOLD)
        )

        # Hills: moderate elevation, not already mountain
        hill_mask = (smoothed > self.HILL_THRESHOLD) & ~mountain_mask

        # Plains: low elevation, low relief
        plain_mask = (smoothed <= self.HILL_THRESHOLD) & (
            relief < self.LOW_RELIEF_THRESHOLD
        )

        # Valleys: lower than surroundings, not plain/mountain
        valley_mask = (
            ~mountain_mask & ~hill_mask & ~plain_mask & (smoothed < local_avg - 50)
        )

        regions = []

        for classification, mask in [
            ("mountain", mountain_mask),
            ("hill", hill_mask),
            ("plain", plain_mask),
            ("valley", valley_mask),
        ]:
            # Find connected components
            labeled, num_features = ndimage.label(mask)

            for label_id in range(1, num_features + 1):
                component_mask = labeled == label_id

                # Skip small regions
                cell_count = np.sum(component_mask)
                if cell_count < self.MIN_REGION_CELLS:
                    continue

                # Extract region properties
                indices = np.where(component_mask)

                # Convert grid indices to world coordinates
                xs = bounds["minX"] + indices[0] * resolution
                zs = bounds["minZ"] + indices[1] * resolution

                center_x = float(np.mean(xs))
                center_z = float(np.mean(zs))

                # Compute convex hull for polygon
                points = np.column_stack([xs, zs])
                try:
                    if len(points) >= 3:
                        hull = ConvexHull(points)
                        vertices = [
                            (float(points[v, 0]), float(points[v, 1]))
                            for v in hull.vertices
                        ]
                    else:
                        vertices = [(float(x), float(z)) for x, z in points]
                except Exception:
                    # Fallback for degenerate cases
                    vertices = [
                        (float(np.min(xs)), float(np.min(zs))),
                        (float(np.max(xs)), float(np.min(zs))),
                        (float(np.max(xs)), float(np.max(zs))),
                        (float(np.min(xs)), float(np.max(zs))),
                    ]

                # Calculate area (km^2)
                area_m2 = cell_count * resolution * resolution
                area_km2 = area_m2 / 1_000_000

                # Average elevation
                elev_values = elevation[component_mask]
                avg_elev = float(np.nanmean(elev_values))

                # Get lat/lon center
                lat_vals = self.grid["lat"][component_mask]
                lon_vals = self.grid["lon"][component_mask]
                lat_center = float(np.nanmean(lat_vals))
                lon_center = float(np.nanmean(lon_vals))

                # Generate name based on location
                name = self._generate_region_name(
                    classification, center_x, center_z, len(regions)
                )

                regions.append(
                    Region(
                        name=name,
                        classification=classification,
                        vertices=vertices,
                        center=(center_x, center_z),
                        area_km2=area_km2,
                        avg_elevation=avg_elev,
                        lat_lon_center=(lat_center, lon_center),
                    )
                )

        return regions

    def identify_water_bodies(self) -> list[WaterBody]:
        """Identify and classify water bodies."""
        surface = self.grid["surface"]
        resolution = self.grid["resolution"]
        bounds = self.grid["bounds"]

        # Water mask (SHALLOW_WATER=2, WATER=3)
        water_mask = (surface == 2) | (surface == 3)

        # Find connected components
        labeled, num_features = ndimage.label(water_mask)

        water_bodies = []

        for label_id in range(1, num_features + 1):
            component_mask = labeled == label_id

            # Calculate area
            area_cells = np.sum(component_mask)
            area_km2 = area_cells * resolution * resolution / 1_000_000

            # Skip tiny water bodies
            if area_km2 < 1:
                continue

            indices = np.where(component_mask)
            xs = bounds["minX"] + indices[0] * resolution
            zs = bounds["minZ"] + indices[1] * resolution

            center_x = float(np.mean(xs))
            center_z = float(np.mean(zs))

            # Classify: sea if touches boundary and large, else lake
            touches_boundary = (
                np.any(indices[0] == 0)
                or np.any(indices[0] == surface.shape[0] - 1)
                or np.any(indices[1] == 0)
                or np.any(indices[1] == surface.shape[1] - 1)
            )

            if touches_boundary and area_km2 > self.SEA_MIN_AREA:
                body_type = "sea"
            elif area_km2 > self.LAKE_MIN_AREA:
                body_type = "lake"
            else:
                body_type = "reservoir"

            # Get vertices
            points = np.column_stack([xs, zs])
            try:
                if len(points) >= 3:
                    hull = ConvexHull(points)
                    vertices = [
                        (float(points[v, 0]), float(points[v, 1]))
                        for v in hull.vertices
                    ]
                else:
                    vertices = []
            except Exception:
                vertices = []

            # Lat/lon center
            lat_vals = self.grid["lat"][component_mask]
            lon_vals = self.grid["lon"][component_mask]
            lat_center = float(np.nanmean(lat_vals))
            lon_center = float(np.nanmean(lon_vals))

            name = self._generate_water_name(body_type, len(water_bodies))

            water_bodies.append(
                WaterBody(
                    name=name,
                    body_type=body_type,
                    vertices=vertices,
                    center=(center_x, center_z),
                    area_km2=area_km2,
                    lat_lon_center=(lat_center, lon_center),
                )
            )

        return water_bodies

    def detect_settlements(self) -> list[Settlement]:
        """Detect settlements from road density clustering."""
        road_points = self.data["roads"]["points"]

        if len(road_points) < 10:
            return []

        # Extract coordinates
        coords = np.array([[p["x"], p["z"]] for p in road_points])

        # Cluster road points using DBSCAN
        clustering = DBSCAN(
            eps=self.SETTLEMENT_CLUSTER_RADIUS,
            min_samples=self.SETTLEMENT_MIN_SAMPLES,
        ).fit(coords)

        settlements = []

        for cluster_id in set(clustering.labels_):
            if cluster_id == -1:  # Skip noise
                continue

            cluster_mask = clustering.labels_ == cluster_id
            cluster_points = coords[cluster_mask]

            center_x = float(np.mean(cluster_points[:, 0]))
            center_z = float(np.mean(cluster_points[:, 1]))

            # Road density = points per area
            x_range = np.max(cluster_points[:, 0]) - np.min(cluster_points[:, 0])
            z_range = np.max(cluster_points[:, 1]) - np.min(cluster_points[:, 1])
            area = max(x_range * z_range, 1_000_000)  # Minimum 1 km^2
            density = len(cluster_points) / (area / 1_000_000)

            # Get lat/lon from nearest road point
            distances = np.sqrt(
                (cluster_points[:, 0] - center_x) ** 2
                + (cluster_points[:, 1] - center_z) ** 2
            )
            nearest_idx = np.argmin(distances)
            original_idx = np.where(cluster_mask)[0][nearest_idx]
            lat = road_points[original_idx]["lat"]
            lon = road_points[original_idx]["lon"]

            name = f"S-{len(settlements) + 1:03d}"

            settlements.append(
                Settlement(
                    name=name,
                    center=(center_x, center_z),
                    road_density=density,
                    lat_lon_center=(lat, lon),
                )
            )

        return settlements

    def compute_connectivity(
        self, regions: list[Region]
    ) -> list[tuple[str, str, float]]:
        """Compute road connectivity between regions.

        Uses a spatial index for efficient region lookups, reducing
        complexity from O(segments * regions) to approximately
        O(segments * regions_per_cell).
        """
        road_segments = self.data["roads"]["segments"]

        if not road_segments or not regions:
            return []

        # Build spatial index for fast region lookups
        bounds = self.data["metadata"]["bounds"]
        region_index = RegionIndex(regions, bounds)

        connections: dict[tuple[str, str], float] = defaultdict(float)

        for segment in road_segments:
            from_region = region_index.region_for_point(
                segment["from"]["x"], segment["from"]["z"]
            )
            to_region = region_index.region_for_point(
                segment["to"]["x"], segment["to"]["z"]
            )

            if from_region and to_region and from_region != to_region:
                sorted_pair = sorted([from_region, to_region])
                key: tuple[str, str] = (sorted_pair[0], sorted_pair[1])
                connections[key] += 1

        return [(k[0], k[1], v) for k, v in connections.items()]

    def get_airbases(self) -> list[Airbase]:
        """Extract airbase data."""
        airbases = []
        for ab in self.data.get("airbases", []):
            airbases.append(
                Airbase(
                    name=ab["name"],
                    callsign=ab.get("callsign", ""),
                    x=ab["x"],
                    z=ab["z"],
                    height=ab["height"],
                    lat=ab["lat"],
                    lon=ab["lon"],
                    category=ab.get("category", -1),
                    parking=ab.get("parking", []),
                    runways=ab.get("runways", []),
                )
            )
        return sorted(airbases, key=lambda a: a.name)

    def _generate_region_name(
        self, classification: str, x: float, z: float, index: int
    ) -> str:
        """Generate a descriptive region name."""
        bounds = self.grid["bounds"]
        mid_x = (bounds["minX"] + bounds["maxX"]) / 2
        mid_z = (bounds["minZ"] + bounds["maxZ"]) / 2

        directions = []
        if z > mid_z:
            directions.append("North")
        else:
            directions.append("South")
        if x > mid_x:
            directions.append("East")
        else:
            directions.append("West")

        direction = "".join(directions)
        return f"{direction} {classification.title()} {index + 1}"

    def _generate_water_name(self, body_type: str, index: int) -> str:
        """Generate a water body name."""
        type_names = {
            "sea": "Sea",
            "lake": "Lake",
            "reservoir": "Reservoir",
        }
        return f"{type_names.get(body_type, 'Water')} {index + 1}"


class MarkdownGenerator:
    """Generates markdown documentation from processed terrain data."""

    # Category names for airbases
    CATEGORY_NAMES: dict[int, str] = {
        0: "Airdrome",
        1: "Helipad",
        2: "Ship",
    }

    processor: TerrainProcessor
    metadata: MetadataDict

    def __init__(self, processor: TerrainProcessor) -> None:
        self.processor = processor
        self.metadata = processor.data["metadata"]

    def generate(self) -> str:
        """Generate complete markdown documentation."""
        regions = self.processor.classify_terrain()
        water_bodies = self.processor.identify_water_bodies()
        settlements = self.processor.detect_settlements()
        connectivity = self.processor.compute_connectivity(regions)
        airbases = self.processor.get_airbases()

        sections = [
            self._header(),
            self._overview(regions, water_bodies, settlements, airbases),
            self._airports(airbases),
            self._terrain_regions(regions),
            self._water_bodies(water_bodies),
            self._settlements(settlements),
            self._connectivity(connectivity),
            self._coordinate_reference(),
        ]

        return "\n\n".join(sections)

    def _header(self) -> str:
        theatre = self.metadata["theatre"]
        return f"""# {theatre} Theatre

This document provides terrain and airport data for the {theatre} map in DCS World.

**Export Date:** {self.metadata["exportTime"]}
**Grid Resolution:** {self.metadata["gridResolution"]} meters"""

    def _overview(
        self,
        regions: list[Region],
        water_bodies: list[WaterBody],
        settlements: list[Settlement],
        airbases: list[Airbase],
    ) -> str:
        bounds = self.metadata["bounds"]

        # Count by classification
        class_counts: dict[str, int] = defaultdict(int)
        for r in regions:
            class_counts[r.classification] += 1

        width_km = (bounds["maxX"] - bounds["minX"]) / 1000
        height_km = (bounds["maxZ"] - bounds["minZ"]) / 1000

        theatre = self.metadata["theatre"]
        return f"""## Overview

The {theatre} theatre spans approximately {width_km:.0f} km east-west \
and {height_km:.0f} km north-south.

**Terrain Summary:**
- Airports/FARPs: {len(airbases)}
- Mountain regions: {class_counts.get("mountain", 0)}
- Hill regions: {class_counts.get("hill", 0)}
- Plain regions: {class_counts.get("plain", 0)}
- Valley regions: {class_counts.get("valley", 0)}
- Water bodies: {len(water_bodies)}
- Detected settlements: {len(settlements)}

**Coordinate Bounds (game coordinates):**

| Axis | Minimum | Maximum |
|------|---------|---------|
| X (East-West) | {bounds["minX"]:,.0f} | {bounds["maxX"]:,.0f} |
| Z (North-South) | {bounds["minZ"]:,.0f} | {bounds["maxZ"]:,.0f} |"""

    def _airports(self, airbases: list[Airbase]) -> str:
        if not airbases:
            return "## Airports\n\nNo airports found."

        lines = ["## Airports"]

        for ab in airbases:
            category_name = self.CATEGORY_NAMES.get(ab.category, "Unknown")
            lines.append(f"\n### {ab.name}")
            lines.append("")
            pos = f"x: {ab.x:,.0f}, z: {ab.z:,.0f}"
            latlon = f"{ab.lat:.4f}N, {ab.lon:.4f}E"
            lines.append(f"- **Position:** {pos} ({latlon})")
            lines.append(f"- **Elevation:** {ab.height:.0f}m MSL")
            lines.append(f"- **Category:** {category_name}")
            if ab.callsign:
                lines.append(f"- **Callsign:** {ab.callsign}")

            # Runways
            if ab.runways:
                lines.append("")
                lines.append("#### Runways")
                lines.append("")
                lines.append("| Heading | Length | Width | Position (x, z) |")
                lines.append("|---------|--------|-------|-----------------|")
                for rwy in ab.runways:
                    heading = rwy.get("heading")
                    if heading is not None:
                        # Convert radians to degrees if needed, show reciprocal
                        if heading > 2 * math.pi:
                            heading_deg = heading
                        else:
                            heading_deg = math.degrees(heading)
                        heading_deg = heading_deg % 360
                        recip = (heading_deg + 180) % 360
                        heading_str = f"{heading_deg:03.0f}/{recip:03.0f}"
                    else:
                        heading_str = "N/A"

                    length = rwy.get("length", 0)
                    width = rwy.get("width", 0)
                    x = rwy.get("x")
                    z = rwy.get("z")
                    pos_str = (
                        f"({x:,.0f}, {z:,.0f})" if x is not None else "N/A"
                    )
                    lines.append(
                        f"| {heading_str} | {length:,.0f}m | {width:.0f}m | {pos_str} |"
                    )

            # Parking spots
            if ab.parking:
                lines.append("")
                lines.append("#### Parking Spots")
                lines.append("")

                # Group by Term_Type
                by_type: dict[int, list[ParkingSpotDict]] = defaultdict(list)
                for spot in ab.parking:
                    term_type = spot.get("Term_Type", -1)
                    by_type[term_type].append(spot)

                # Sort each group by Term_Index
                lines.append(
                    "| Term_Index | Term_Type | Position (x, z) | Dist to RW |"
                )
                lines.append("|------------|-----------|-----------------|------------|")

                sorted_spots = sorted(ab.parking, key=lambda s: s.get("Term_Index", 0))
                for spot in sorted_spots:
                    term_idx = spot.get("Term_Index", "?")
                    term_type = spot.get("Term_Type", "?")
                    x = spot.get("x")
                    z = spot.get("z")
                    dist = spot.get("fDistToRW", 0)

                    pos_str = f"({x:,.0f}, {z:,.0f})" if x is not None else "N/A"
                    lines.append(
                        f"| {term_idx} | {term_type} | {pos_str} | {dist:,.0f}m |"
                    )

        return "\n".join(lines)

    def _terrain_regions(self, regions: list[Region]) -> str:
        if not regions:
            return "## Terrain Regions\n\nNo significant terrain regions identified."

        lines = ["## Terrain Regions"]

        # Group by classification
        by_class: dict[str, list[Region]] = defaultdict(list)
        for r in regions:
            by_class[r.classification].append(r)

        for classification in ["mountain", "hill", "plain", "valley"]:
            class_regions = by_class.get(classification, [])
            if not class_regions:
                continue

            lines.append(f"\n### {classification.title()} Regions")
            lines.append("")
            lines.append(
                "| Name | Center (x, z) | Lat/Lon | Area (km2) | Avg Elevation |"
            )
            lines.append(
                "|------|---------------|---------|------------|---------------|"
            )

            # Sort by area, largest first
            for r in sorted(class_regions, key=lambda x: -x.area_km2):
                lines.append(
                    f"| {r.name} | "
                    f"({r.center[0]:,.0f}, {r.center[1]:,.0f}) | "
                    f"({r.lat_lon_center[0]:.4f}, {r.lat_lon_center[1]:.4f}) | "
                    f"{r.area_km2:,.1f} | "
                    f"{r.avg_elevation:,.0f}m |"
                )

            # Add vertices for each region
            lines.append("")
            for r in sorted(class_regions, key=lambda x: -x.area_km2):
                if r.vertices:
                    vertex_str = ", ".join(
                        f"({v[0]:.0f}, {v[1]:.0f})" for v in r.vertices[:12]
                    )
                    if len(r.vertices) > 12:
                        vertex_str += ", ..."
                    lines.append(f"**{r.name} Vertices:** {vertex_str}")
                    lines.append("")

        return "\n".join(lines)

    def _water_bodies(self, water_bodies: list[WaterBody]) -> str:
        if not water_bodies:
            return "## Water Bodies\n\nNo significant water bodies identified."

        lines = ["## Water Bodies", ""]
        lines.append("| Name | Type | Center (x, z) | Lat/Lon | Area (km2) |")
        lines.append("|------|------|---------------|---------|------------|")

        for wb in sorted(water_bodies, key=lambda x: -x.area_km2):
            lines.append(
                f"| {wb.name} | {wb.body_type} | "
                f"({wb.center[0]:,.0f}, {wb.center[1]:,.0f}) | "
                f"({wb.lat_lon_center[0]:.4f}, {wb.lat_lon_center[1]:.4f}) | "
                f"{wb.area_km2:,.1f} |"
            )

        return "\n".join(lines)

    def _settlements(self, settlements: list[Settlement]) -> str:
        if not settlements:
            return (
                "## Settlements\n\n"
                "No settlements detected from road density analysis."
            )

        lines = ["## Settlements", ""]
        lines.append("Settlements are detected from road network density clustering.")
        lines.append("")
        lines.append("| ID | Center (x, z) | Lat/Lon | Road Density |")
        lines.append("|----|---------------|---------|--------------|")

        for s in sorted(settlements, key=lambda x: -x.road_density):
            lines.append(
                f"| {s.name} | "
                f"({s.center[0]:,.0f}, {s.center[1]:,.0f}) | "
                f"({s.lat_lon_center[0]:.4f}, {s.lat_lon_center[1]:.4f}) | "
                f"{s.road_density:.1f} |"
            )

        return "\n".join(lines)

    def _connectivity(
        self, connectivity: list[tuple[str, str, float]]
    ) -> str:
        if not connectivity:
            return "## Road Connectivity\n\nNo inter-region road connections detected."

        lines = ["## Road Connectivity", ""]
        lines.append("This section shows which terrain regions are connected by roads.")
        lines.append("")
        lines.append("| Region A | Region B | Connection Strength |")
        lines.append("|----------|----------|---------------------|")

        for a, b, strength in sorted(connectivity, key=lambda x: -x[2]):
            lines.append(f"| {a} | {b} | {strength:.0f} |")

        return "\n".join(lines)

    def _coordinate_reference(self) -> str:
        return """## Coordinate Reference

DCS World uses a Transverse Mercator projection with coordinates in meters:

- **X axis (East-West):** Positive = east, negative = west
- **Z axis (North-South):** Positive = north, negative = south
- **Y axis (Altitude):** Meters above sea level

Mission files use Vec2 format `{x = number, y = number}` where `y` is the
north-south position (equivalent to Z in 3D coordinates).

**Parking Spot Fields:**
- `Term_Index` maps to `parking_id` in mission.lua unit definitions
- `Term_Type` indicates aircraft size category (values vary by airbase)

Lat/Lon values are provided for human reference but mission scripting
should use game coordinates."""


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Process DCS terrain exports into markdown documentation"
    )
    parser.add_argument(
        "input_json", type=Path, help="Path to terrain JSON export from DCS"
    )
    parser.add_argument("-o", "--output", type=Path, help="Output markdown file path")

    args = parser.parse_args()

    if not args.input_json.exists():
        print(f"Error: Input file not found: {args.input_json}")
        return 1

    # Process terrain data
    print(f"Loading: {args.input_json}")
    try:
        processor = TerrainProcessor(args.input_json)
    except TerrainExportError as e:
        print(f"Error: {e}")
        return 1

    print("Classifying terrain...")
    generator = MarkdownGenerator(processor)
    markdown = generator.generate()

    # Determine output path
    if args.output:
        output_path = args.output
    else:
        theatre = processor.data["metadata"]["theatre"].lower().replace(" ", "-")
        output_path = Path(f"../../docs/maps/{theatre}.md")

    # Write output
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(markdown)
    print(f"Generated: {output_path}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
