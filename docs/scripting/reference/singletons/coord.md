# coord

The coord singleton provides coordinate conversion between the game's internal XYZ system, Latitude/Longitude, and MGRS.

Coordinate conversion functions may fail or return undefined results if the input coordinates fall outside the current map's boundaries. When calling these functions with dynamically calculated positions, consider using `pcall()` to handle potential errors gracefully.

## coord.LLtoLO

```lua
number, number, number coord.LLtoLO(number latitude, number longitude, number altitude)
```

The `coord.LLtoLO` function converts Latitude/Longitude/Altitude to the game's XYZ coordinate system.

**Parameters:**
- `latitude` (number): The latitude in decimal degrees, where positive values indicate North.
- `longitude` (number): The longitude in decimal degrees, where positive values indicate East.
- `altitude` (number): The altitude in meters above mean sea level.

**Returns:** Three numbers representing the x, y, and z game coordinates, where y is altitude.

```lua
local x, y, z = coord.LLtoLO(41.657, 41.597, 0)
local position = {x = x, y = y, z = z}
```

## coord.LOtoLL

```lua
number, number, number coord.LOtoLL(number x, number y, number z)
```

The `coord.LOtoLL` function converts game XYZ coordinates to Latitude/Longitude/Altitude.

**Parameters:**
- `x` (number): The X coordinate representing the East-West position.
- `y` (number): The Y coordinate representing altitude.
- `z` (number): The Z coordinate representing the North-South position.

**Returns:** Three numbers representing the latitude, longitude, and altitude.

```lua
local pos = unit:getPoint()
local lat, lon, alt = coord.LOtoLL(pos.x, pos.y, pos.z)
env.info(string.format("Position: %.4f, %.4f", lat, lon))
```

## coord.LLtoMGRS

```lua
table coord.LLtoMGRS(number latitude, number longitude)
```

The `coord.LLtoMGRS` function converts Latitude/Longitude to MGRS (Military Grid Reference System).

**Parameters:**
- `latitude` (number): The latitude in decimal degrees.
- `longitude` (number): The longitude in decimal degrees.

**Returns:** An MGRS table with the following fields: `UTMZone`, `MGRSDigraph`, `Easting`, and `Northing`.

```lua
local mgrs = coord.LLtoMGRS(41.657, 41.597)
local mgrsString = mgrs.UTMZone .. mgrs.MGRSDigraph .. " " ..
                   string.format("%05d", mgrs.Easting) .. " " ..
                   string.format("%05d", mgrs.Northing)
```

## coord.MGRStoLL

```lua
number, number coord.MGRStoLL(table mgrs)
```

The `coord.MGRStoLL` function converts MGRS coordinates to Latitude/Longitude.

**Parameters:**
- `mgrs` (table): An MGRS table with the following fields: `UTMZone`, `MGRSDigraph`, `Easting`, and `Northing`.

**Returns:** Two numbers representing the latitude and longitude.

## See Also

- [Coordinate Types](../types/coordinates.md) - Vec2, Vec3, and coordinate systems
- [land](land.md) - Terrain height queries
