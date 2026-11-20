# Terrain Geodata

`docs/data/terrains/<theatre>/` holds GIS files for every terrain, exported
directly from the game install by [tools/terrain-geodata](../../tools/terrain-geodata/README.md).
The folder name is the theatre id that missions store in `mission.theatre`.

| File            | Format                  | Contents                                                          |
| --------------- | ----------------------- | ----------------------------------------------------------------- |
| `terrain.json`  | JSON                    | Projection parameters, raster extent, feature counts, class areas |
| `places.csv`    | CSV                     | Named places with lat/long and DCS `x`/`z`                        |
| `features.gpkg` | GeoPackage (SQLite)     | Vector layers from the Mission Editor map                         |
| `landcover.tif` | Cloud-optimized GeoTIFF | 100 m land cover classes from the terrain mesh                    |

All geometry is in the terrain's own transverse Mercator projection, so GIS
coordinates are DCS coordinates: **easting is DCS `z` and northing is DCS
`x`**. A point at GIS `(E, N)` is DCS `x = N`, `z = E` (Vec2 `{x = N, y = E}`).
QGIS, GDAL, `rasterio`, `geopandas` and `sqlite3` open every file directly.

## Coordinate System

Each terrain is a transverse Mercator projection on the WGS84 ellipsoid with
scale factor 0.9996 and latitude of origin 0. `x` increases to the north and `z`
to the east, in metres[^proj].

| Theatre              | Central meridian | False easting (m) | False northing (m) | Fit error |
| -------------------- | ---------------- | ----------------- | ------------------ | --------- |
| `Caucasus`           | 33°              | -99,517           | -4,998,115         | 7 cm      |
| `GermanyCW`          | 21°              | 35,427.617        | -6,061,633.131     | 6 cm      |
| `Kola`               | 21°              | -62,702           | -7,543,625         | 6 cm      |
| `MarianaIslandsWWII` | 147°             | 238,418           | -1,491,840         | 6 cm      |
| `MarianaIslands`     | 147°             | 238,418           | -1,491,840         | 8 cm      |
| `Nevada`             | -117°            | -193,996.810      | -4,410,028.066     | 7 cm      |
| `Normandy`           | -3°              | -195,526          | -5,484,813         | 7 cm      |
| `PersianGulf`        | 57°              | 75,756            | -2,894,933         | 7 cm      |
| `SinaiMap`           | 33°              | 169,222           | -3,325,313         | 7 cm      |
| `Syria`              | 39°              | 282,801           | -3,879,866         | 7 cm      |

`fit error` is the largest disagreement between the projection and the
reference points the game ships (beacon and town positions given in both
systems). A few centimetres means the parameters are exact. `terrain.json`
holds the same values plus a ready-made `proj4` string.

To convert with `pyproj`:

```python
import json
from pyproj import Transformer

crs = json.load(open("docs/data/terrains/Caucasus/terrain.json"))["crs"]["proj4"]
to_dcs = Transformer.from_crs("EPSG:4326", crs, always_xy=True)
z, x = to_dcs.transform(41.6, 41.6)  # (longitude, latitude) in, (z, x) out
```

## Land Cover

`landcover.tif` is a single-band `uint8` raster. Each pixel takes the class of
the terrain mesh triangle under its centre. Later rows win where classes
overlap (a river through a forest is `river`).

| Value | Class    | Meaning                                                         |
| ----- | -------- | --------------------------------------------------------------- |
| 0     | `nodata` | Outside the terrain mesh                                        |
| 1     | `land`   | Open ground: grass, scrub, rock, desert, snow                   |
| 2     | `field`  | Farmland                                                        |
| 3     | `forest` | Forest                                                          |
| 4     | `town`   | Built-up ground texture: cities, villages and scattered housing |
| 5     | `beach`  | Beach and the shoreline strip                                   |
| 6     | `river`  | River surface                                                   |
| 7     | `lake`   | Lake or reservoir                                               |
| 8     | `sea`    | Sea                                                             |
| 9     | `runway` | Runway and airfield paving                                      |

Things to keep in mind:

- `town` follows the ground texture under buildings, so it is generous: in
  densely settled regions it covers whole valleys of villages. It says
  buildings are likely, not that a spot is blocked.
- Roads and railways are too narrow for 100 m pixels and are not in the
  raster; use the vector layers.
- `land` includes steep mountainsides. The raster has no elevation; check slope
  with `land.getHeight` in a mission before placing ground units.
- Large areas at the map edges are low-detail filler mesh. They are classed
  (mostly `land` and `sea`) but have no towns, roads or forest.

Sample a class at a DCS position:

```python
import rasterio

with rasterio.open("docs/data/terrains/Caucasus/landcover.tif") as src:
    x, z = -276848.2, 646568.0  # Senaki, from places.csv
    [value] = next(src.sample([(z, x)]))
    print(src.tags(1)[f"CLASS_{value}"])
```

## Feature Layers

`features.gpkg` has one layer per feature type. Lines are merged where
segments meet; polygons are dissolved.

| Layer         | Geometry   | Attribute                       | Contents                            |
| ------------- | ---------- | ------------------------------- | ----------------------------------- |
| `places`      | Point      | `name`, `latitude`, `longitude` | Named places from the map labels    |
| `roads`       | LineString | `length_m`                      | Roads                               |
| `railways`    | LineString | `length_m`                      | Railways                            |
| `rivers`      | LineString | `length_m`                      | River centrelines                   |
| `power_lines` | LineString | `length_m`                      | Power lines                         |
| `borders`     | LineString | `length_m`                      | National and administrative borders |
| `urban_areas` | Polygon    | `area_m2`                       | Town outlines as the map draws them |
| `runways`     | Polygon    | `area_m2`                       | Runway outlines                     |

These layers are the linework the Mission Editor draws over its map, and each
terrain's map draws different things. A layer is empty when that terrain's map
does not show it (Mariana Islands has no overlay at all). The land cover raster
is complete for every terrain, so prefer it for water, forest and built-up
areas. On most terrains the overlay roads are a subset of the roads in the 3D
terrain.

Feature counts per terrain (`-` means the map draws none):

| Theatre              | Places | `roads` | `railways` | `rivers` | `power_lines` | `borders` | `urban_areas` | `runways` |
| -------------------- | ------ | ------- | ---------- | -------- | ------------- | --------- | ------------- | --------- |
| `Caucasus`           | 1,759  | 2,190   | 561        | 2,109    | 357           | 27        | 2,853         | 26        |
| `GermanyCW`          | 127    | 173     | 167        | -        | -             | 20        | 27            | -         |
| `Kola`               | 787    | 21,608  | 1,309      | -        | -             | -         | -             | -         |
| `MarianaIslandsWWII` | 22     | -       | -          | -        | -             | -         | -             | -         |
| `MarianaIslands`     | 78     | -       | -          | -        | -             | -         | -             | -         |
| `Nevada`             | 221    | 164     | -          | -        | 368           | -         | 34            | -         |
| `Normandy`           | 1,297  | 343     | 484        | 356      | -             | -         | 183           | -         |
| `PersianGulf`        | 385    | 1,126   | 222        | -        | 2,048         | 8         | 946           | -         |
| `SinaiMap`           | 733    | 770     | 109        | 3        | -             | -         | 466           | -         |
| `Syria`              | 1,182  | 1,059   | 78         | 552      | 586           | 29        | 321           | -         |

Query a layer with plain SQLite (geometry is GeoPackage binary; use a GIS
library to read it):

```bash
sqlite3 docs/data/terrains/Caucasus/features.gpkg \
  "SELECT count(*), round(sum(length_m) / 1000) AS km FROM railways"
```

Or with `pyogrio`/`geopandas`:

```python
import geopandas as gpd
from shapely import Point

roads = gpd.read_file("docs/data/terrains/Caucasus/features.gpkg", layer="roads")
x, z = -276848.2, 646568.0  # Senaki, from places.csv
print(roads.distance(Point(z, x)).min())  # metres to the nearest major road
```

## Places

`places.csv` lists every named place on the Mission Editor map: `name`,
`latitude`, `longitude`, `x`, `z`. The lat/long comes from the terrain's
`towns.lua`; `x`/`z` is the map label position. The list mixes cities,
villages and some landmarks, with no size ranking.

## Updating

Re-export after a DCS update that changes terrains, and review the
`terrain.json` diffs:

```bash
cd tools/terrain-geodata
uv run terrain-geodata export --dcs-path "<DCS World folder>" --out ../../docs/data/terrains
```

`terrain.json` records the DCS version the files came from.

[^proj]: Fitted by the export tool against `Beacons.lua` (`position` and `positionGeo` of each beacon) and the Mission Editor town labels paired with `Map/towns.lua`. The Caucasus and Syria parameters match pydcs's `dcs/terrain/projections`.
