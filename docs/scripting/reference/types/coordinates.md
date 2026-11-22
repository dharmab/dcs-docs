# Coordinate Types

This document describes the coordinate and position types used throughout the DCS World Simulator Scripting Engine.

## Vec2

**Vec2** is a 2D point on the map surface:

```lua
Vec2 = {
    x = number,
    y = number
}
```

The `x` field is the north-south position, where positive values are to the north. The `y` field is the east-west position, where positive values are to the east.

## Vec3

**Vec3** is a 3D point in world space:

```lua
Vec3 = {
    x = number,
    y = number,
    z = number
}
```

The `x` field is the north-south position, where positive values are to the north. The `y` field is the altitude, where positive values are above sea level. The `z` field is the east-west position, where positive values are to the east. A Vec3 `{x, y, z}` corresponds to the Vec2 `{x = x, y = z}`.

## Position3

**Position3** is both position and orientation in 3D space:

```lua
Position3 = {
    p = Vec3,
    x = Vec3,
    y = Vec3,
    z = Vec3
}
```

The `p` field is the world position as a Vec3. The `x` field is the forward unit vector, pointing out of the object's nose. The `y` field is the up unit vector, pointing out of the object's top. The `z` field is the right unit vector, pointing out of the object's right side. These orientation vectors form an orthonormal basis. You can calculate heading and pitch from a Position3 value:

```lua
local pos = unit:getPosition()
local heading = math.atan2(pos.x.z, pos.x.x)
local pitch = math.asin(pos.x.y)
```

Heading is in radians, 0 is north. Pitch is in radians, positive is nose up.

## Map Bounds

Many SSE functions that take a Vec2 or Vec3 may fail or return undefined results for coordinates outside the map. Each theater has different bounds.

Check computed positions are in bounds before passing them to functions such as `land.getHeight()`, `atmosphere.getWind()`, or coordinate conversions, or wrap the calls in `pcall()`.

## See Also

- [Data Types](../../simulator-scripting-engine.md#data-types) - Coordinate system explanation
- [coord](../singletons/coord.md) - Coordinate conversion functions
