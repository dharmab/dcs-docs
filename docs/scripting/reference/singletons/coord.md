# coord

The coord singleton contains functions that convert coordinates between the game's internal XYZ system, Latitude/Longitude, and MGRS.

Coordinate conversion functions may fail or return undefined results for coordinates outside the map. Wrap calls with computed positions in `pcall()`.

## coord.LLtoLO

```lua
Vec3 coord.LLtoLO(number latitude, number longitude, number altitude)
```

The `coord.LLtoLO` function converts Latitude/Longitude/Altitude to the game's XYZ coordinate system.

**Parameters:**

- `latitude` (number): The latitude in decimal degrees, where positive values indicate North.
- `longitude` (number): The longitude in decimal degrees, where positive values indicate East.
- `altitude` (number): Optional. The altitude in meters above mean sea level.

**Returns:** A Vec3 with the game coordinates, where y is altitude.[^lltolo]

<!-- TODO: QA - Verify in DCS that coord.LLtoLO returns a Vec3 and that altitude is optional (MOOSE and MIST rely on both; no installed DCS Lua calls it) -->

```lua
local position = coord.LLtoLO(41.657, 41.597, 0)
```

## coord.LOtoLL

```lua
number, number, number coord.LOtoLL(Vec3 point)
```

The `coord.LOtoLL` function converts game XYZ coordinates to Latitude/Longitude/Altitude.

**Parameters:**

- `point` (Vec3): The game coordinates, where y is altitude.[^lotoll]

**Returns:** Three numbers representing the latitude, longitude, and altitude.

```lua
local pos = unit:getPoint()
local lat, lon, alt = coord.LOtoLL(pos)
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

[^lltolo]: [MOOSE `Core/Point.lua`](https://github.com/FlightControl-Master/MOOSE/blob/master/Moose%20Development/Moose/Core/Point.lua) (`COORDINATE:NewFromLLDD`, `COORDINATE:GetNorthCorrectionRadians`) and [MIST](https://github.com/mrSkortch/MissionScriptingTools/blob/master/mist.lua) (`mist.getNorthCorrection`) call `coord.LLtoLO(lat, lon)` and read `.x` and `.z` from the result.

[^lotoll]: `Scripts/Speech/NATO.lua` in the DCS install calls `coord.LOtoLL(point)` with a single point table.
