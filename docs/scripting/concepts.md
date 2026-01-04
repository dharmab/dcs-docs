# Scripting Concepts

This document describes fundamental concepts used throughout the DCS World Simulator Scripting Engine.

## Coordinate Systems

DCS World simulates a flat earth model using a Transverse Mercator projection for each theater. Each map has its own projection origin point, and the simulation uses a Cartesian coordinate system measured in meters from that origin. This approach trades global accuracy for local precision, which is appropriate for the scale of combat operations depicted in the simulation.

The terrain engine does not provide a one-to-one representation of real-world geography. Maps are composites assembled from multiple time periods and may include features that have been added, removed, or modified to improve gameplay or engine performance. Features like buildings, roads, and vegetation do not necessarily match their real-world counterparts in location, appearance, or presence. Scripts that rely on real-world geographic data should account for these discrepancies.

The native coordinate system uses X, Y, and Z axes measured in meters. The `coord` singleton provides conversion functions between this native system and real-world coordinate systems including latitude/longitude (geodetic coordinates) and MGRS (Military Grid Reference System, based on UTM). These conversions allow scripts to work with familiar geographic coordinates while the engine operates in its internal Cartesian space.

Vec2 and Vec3 use different conventions for the "y" axis. In Vec2, `y` is the North-South position. In Vec3, `y` is altitude while `z` is North-South. This difference is a common source of confusion when converting between the two formats.

## Time Values

The DCS scripting engine measures mission time in seconds as a floating-point number with millisecond precision. The timer singleton provides time-related functions. The `timer.getTime()` function returns mission time, which is the number of seconds since the mission started and pauses when the game is paused. The `timer.getAbsTime()` function returns absolute time, which is the number of seconds since midnight of the mission date. The `timer.getTime0()` function returns the mission start time expressed as absolute time.

## Distance and Angles

All distances in the DCS scripting engine are measured in meters. All angles are measured in radians unless otherwise noted. To convert between degrees and radians:

```lua
local radians = degrees * math.pi / 180
local degrees = radians * 180 / math.pi
```

Headings use true north as 0 and increase clockwise: East is π/2, South is π, and West is 3π/2.

## See Also

- [Coordinate Types](reference/types/coordinates.md) - Vec2, Vec3, and Position3 type definitions
- [coord](reference/singletons/coord.md) - Coordinate conversion functions
- [timer](reference/singletons/timer.md) - Time-related functions
