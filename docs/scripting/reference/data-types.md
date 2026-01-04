# Data Types and Conventions

This document describes the fundamental data types and conventions used throughout the DCS World Simulator Scripting Engine.

## Coordinate Systems

DCS World simulates a flat earth model using a Transverse Mercator projection for each theater. Each map has its own projection origin point, and the simulation uses a Cartesian coordinate system measured in meters from that origin. This approach trades global accuracy for local precision, which is appropriate for the scale of combat operations depicted in the simulation.

The terrain engine does not provide a one-to-one representation of real-world geography. Maps are composites assembled from multiple time periods and may include features that have been added, removed, or modified to improve gameplay or engine performance. Features like buildings, roads, and vegetation do not necessarily match their real-world counterparts in location, appearance, or presence. Scripts that rely on real-world geographic data should account for these discrepancies.

The native coordinate system uses X, Y, and Z axes measured in meters. The `coord` singleton provides conversion functions between this native system and real-world coordinate systems including latitude/longitude (geodetic coordinates) and MGRS (Military Grid Reference System, based on UTM). These conversions allow scripts to work with familiar geographic coordinates while the engine operates in its internal Cartesian space.

**Vec2** represents a 2D point on the map surface:

```lua
Vec2 = {
    x = number,
    y = number
}
```

The `x` field contains the East-West position, where positive values indicate positions to the East. The `y` field contains the North-South position, where positive values indicate positions to the North.

**Vec3** represents a 3D point in world space:

```lua
Vec3 = {
    x = number,
    y = number,
    z = number
}
```

The `x` field contains the East-West position, where positive values indicate positions to the East. The `y` field contains the altitude, where positive values indicate positions above sea level. The `z` field contains the North-South position, where positive values indicate positions to the North.

Vec2 and Vec3 use different conventions for the "y" axis. In Vec2, `y` is the North-South position. In Vec3, `y` is altitude while `z` is North-South. This difference is a common source of confusion when converting between the two formats.

**Position3** represents both position and orientation in 3D space:

```lua
Position3 = {
    p = Vec3,
    x = Vec3,
    y = Vec3,
    z = Vec3
}
```

The `p` field contains the world position as a Vec3. The `x` field contains the forward unit vector, pointing out of the object's nose. The `y` field contains the up unit vector, pointing out of the object's top. The `z` field contains the right unit vector, pointing out of the object's right side. These orientation vectors form an orthonormal basis. You can calculate heading and pitch from a Position3 value:

```lua
local pos = unit:getPosition()
local heading = math.atan2(pos.x.z, pos.x.x)
local pitch = math.asin(pos.x.y)
```

The heading calculation returns radians where 0 represents North. The pitch calculation returns radians where positive values indicate the nose is pointing up.

## Time Values

The DCS scripting engine measures mission time in seconds as a floating-point number with millisecond precision. The timer singleton provides time-related functions. The `timer.getTime()` function returns mission time, which is the number of seconds since the mission started and pauses when the game is paused. The `timer.getAbsTime()` function returns absolute time, which is the number of seconds since midnight of the mission date. The `timer.getTime0()` function returns the mission start time expressed as absolute time.

## Distance and Angles

All distances in the DCS scripting engine are measured in meters. All angles are measured in radians unless otherwise noted. To convert between degrees and radians:

```lua
local radians = degrees * math.pi / 180
local degrees = radians * 180 / math.pi
```

Headings use true north as 0 and increase clockwise: East is π/2, South is π, and West is 3π/2.

## Country and Coalition

Countries are identified by numeric IDs from the `country.id` enum. The game determines coalition membership based on the country. The three coalitions are represented by the `coalition.side` enum:

```lua
coalition.side = {
    NEUTRAL = 0,
    RED = 1,
    BLUE = 2
}
```

Some functions such as `markupToAll` accept a coalition value of -1, which represents "all coalitions."

## See Also

- [coord](coord.md) - Coordinate conversion functions
- [timer](timer.md) - Time-related functions
- [coalition](coalition.md) - Coalition management functions
