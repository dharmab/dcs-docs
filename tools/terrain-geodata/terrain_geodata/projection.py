"""Fit each terrain's transverse Mercator projection from reference points.

DCS places every terrain on a transverse Mercator grid: WGS84 ellipsoid, scale
factor 0.9996, latitude of origin 0, a whole-degree central meridian, and false
easting/northing that put the map origin near the middle of the theatre. DCS
``x`` is the northing and ``z`` the easting.

The game install has no file stating these parameters, but ``Beacons.lua`` and
the town labels give many points in both DCS and lat/long coordinates, which pin
them down to a few centimetres.
"""

from __future__ import annotations

import math
from dataclasses import dataclass

import numpy as np
from pyproj import CRS, Transformer

SCALE_FACTOR = 0.9996


@dataclass(frozen=True)
class ReferencePoint:
    source: str
    name: str
    x: float
    z: float
    latitude: float
    longitude: float


@dataclass(frozen=True)
class Projection:
    central_meridian: int
    false_easting: float
    false_northing: float
    point_count: int
    rms_error_m: float
    max_error_m: float

    @property
    def proj4(self) -> str:
        return (
            f"+proj=tmerc +lat_0=0 +lon_0={self.central_meridian} "
            f"+k_0={SCALE_FACTOR} +x_0={_fmt(self.false_easting)} "
            f"+y_0={_fmt(self.false_northing)} +ellps=WGS84 +units=m +no_defs"
        )

    def crs(self, terrain: str) -> CRS:
        crs = CRS.from_proj4(self.proj4)
        # Give the CRS a readable name in GIS tools.
        wkt = crs.to_wkt().replace('PROJCRS["unknown"', f'PROJCRS["DCS {terrain}"', 1)
        return CRS.from_wkt(wkt)


def _fmt(v: float) -> str:
    return str(int(v)) if float(v).is_integer() else f"{v:.3f}"


def _residuals(points: list[ReferencePoint], lon0: float, fe: float, fn: float):
    tm = Transformer.from_crs(
        "EPSG:4326",
        f"+proj=tmerc +lat_0=0 +lon_0={lon0} +k_0={SCALE_FACTOR} "
        f"+x_0={fe} +y_0={fn} +ellps=WGS84 +units=m +no_defs",
        always_xy=True,
    )
    lon = np.array([p.longitude for p in points])
    lat = np.array([p.latitude for p in points])
    e, n = tm.transform(lon, lat)
    z = np.array([p.z for p in points])
    x = np.array([p.x for p in points])
    return z - e, x - n


def fit(points: list[ReferencePoint]) -> Projection:
    if len(points) < 3:
        raise ValueError("need at least three reference points")
    lons = [p.longitude for p in points]
    candidates = range(math.floor(min(lons)) - 6, math.ceil(max(lons)) + 7)
    best: tuple[float, int, float, float] | None = None
    for lon0 in candidates:
        de, dn = _residuals(points, lon0, 0.0, 0.0)
        fe, fn = float(np.median(de)), float(np.median(dn))
        rms = float(np.sqrt(np.mean((de - fe) ** 2 + (dn - fn) ** 2)))
        if best is None or rms < best[0]:
            best = (rms, lon0, fe, fn)
    assert best is not None
    _, lon0, fe, fn = best
    # ED uses whole-metre offsets; keep them when that costs nothing.
    rounded = (round(fe), round(fn))
    de, dn = _residuals(points, lon0, *rounded)
    err_rounded = np.hypot(de, dn)
    de, dn = _residuals(points, lon0, fe, fn)
    err_fit = np.hypot(de, dn)
    if np.median(err_rounded) <= np.median(err_fit) + 0.05:
        fe, fn = float(rounded[0]), float(rounded[1])
        err = err_rounded
    else:
        err = err_fit
    return Projection(
        lon0,
        fe,
        fn,
        len(points),
        round(float(np.sqrt(np.mean(err**2))), 3),
        round(float(err.max()), 3),
    )


def errors(proj: Projection, points: list[ReferencePoint]) -> np.ndarray:
    de, dn = _residuals(
        points, proj.central_meridian, proj.false_easting, proj.false_northing
    )
    return np.hypot(de, dn)
