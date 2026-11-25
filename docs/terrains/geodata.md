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
| `elevation.tif` | Cloud-optimized GeoTIFF | 1 km ground height in metres from the terrain mesh                |

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
- `land` includes steep mountainsides. Check slope at runtime by sampling
  `land.getHeight` around a spot before placing ground units there.
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

## Elevation

`elevation.tif` is a single-band `int16` raster of height above sea level in
whole metres, with 1 km pixels. Each pixel is the terrain mesh height at its
centre, interpolated across the triangle under it[^elev]. Sea, lakes and
pixels outside the mesh are `-32768` (the raster's nodata value). `terrain.json`
records the pixel size and the lowest and highest values under `elevation`.

It is meant for planning at map scale: which areas are mountains, valleys or
plains, where low ground runs between ridges, and roughly how high a region
sits. Anything that depends on the exact spot, such as slope under a unit or
line of sight, belongs at runtime with `land.getHeight`, `land.getIP` and
`land.isVisible`.

The committed files are 1 km to keep the repository small. For finer
heights, re-export a terrain with a smaller pixel; the mesh holds vertices
about 50 m apart in detailed areas, so going below that adds no detail:

```bash
cd tools/terrain-geodata
uv run terrain-geodata export --out /tmp/terrains --terrain Caucasus --elevation-resolution 50
```

Things to keep in mind:

- Sea and lakes are masked out (nodata). The mesh under them is the bed, not
  the water surface, and reaches thousands of metres below sea level.
- Rivers are not masked. A river is tens of metres wide, so a pixel only
  lands on one when its centre falls on the river surface, and then it holds
  the height of the river bed. Masking rivers
  would leave scattered holes along valleys. Use `landcover.tif` or the
  `rivers` layer to find rivers.
- A pixel is the height at one point, not the average or peak of the square
  kilometre around it. Ridgelines, cliffs and narrow valleys between pixel
  centres do not show up.
- `elevation.tif` also contains overviews: copies at 2, 4 and on the larger
  terrains 8 km pixels, which GIS tools read when zoomed out. Each overview
  pixel is the mean of the pixels it covers, so zoomed-out views show average
  heights and flatten peaks. Reads at full resolution, such as `sample` or
  `read(1)`, are unaffected.

Sample a height, and find the places above 1,500 m:

```python
import csv
import rasterio

with rasterio.open("docs/data/terrains/Caucasus/elevation.tif") as src:
    x, z = -276848.2, 646568.0  # Senaki, from places.csv
    [height] = next(src.sample([(z, x)]))
    print(height)

    rows = list(csv.DictReader(open("docs/data/terrains/Caucasus/places.csv")))
    points = [(float(r["z"]), float(r["x"])) for r in rows]
    high = [
        r["name"]
        for r, [h] in zip(rows, src.sample(points))
        if h != src.nodata and h > 1500
    ]
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
uv run terrain-geodata export --out ../../docs/data/terrains
```

On Windows the install is found through the registry; elsewhere pass
`--dcs-path`. `terrain.json` records the DCS version the files came from.

[^elev]: Read from the vertex heights (`Pbase`) of the most detailed tiles in `Surface/*.surface5`. Checked against the beacons that carry a `position` in `Beacons.lua` (every terrain except Normandy and Mariana Islands WWII). At the committed 1 km, 1,107 of the 1,131 beacons fall on a land pixel. For those, the median difference from the beacon height is 0.5 m, and 90% are within 6.7 m. The largest misses, up to 130 m, are on steep ground, where the pixel centre is several hundred metres from the beacon on a different slope.

[^proj]: Fitted by the export tool against `Beacons.lua` (`position` and `positionGeo` of each beacon) and the Mission Editor town labels paired with `Map/towns.lua`. The Caucasus and Syria parameters match pydcs's `dcs/terrain/projections`.
