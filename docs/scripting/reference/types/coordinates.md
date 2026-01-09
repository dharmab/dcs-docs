# Coordinate Types

This document describes the coordinate and position types used throughout the DCS World Simulator Scripting Engine.

## Vec2

**Vec2** represents a 2D point on the map surface:

```lua
Vec2 = {
    x = number,
    y = number
}
```

The `x` field contains the East-West position, where positive values indicate positions to the East. The `y` field contains the North-South position, where positive values indicate positions to the North.

## Vec3

**Vec3** represents a 3D point in world space:

```lua
Vec3 = {
    x = number,
    y = number,
    z = number
}
```

The `x` field contains the East-West position, where positive values indicate positions to the East. The `y` field contains the altitude, where positive values indicate positions above sea level. The `z` field contains the North-South position, where positive values indicate positions to the North.

## Position3

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

## Map Bounds

Many SSE functions that accept Vec2 or Vec3 parameters may fail or return undefined results if the coordinates fall outside the current map's boundaries. Each theater has different dimensions, and coordinates valid on one map may be invalid on another.

When working with dynamically calculated positions, validate that coordinates remain within reasonable bounds before passing them to functions like `land.getHeight()`, `atmosphere.getWind()`, or coordinate conversion functions. Consider wrapping calls to these functions in `pcall()` when the input coordinates are not guaranteed to be within bounds.

## See Also

- [Data Types](../../simulator-scripting-engine.md#data-types) - Coordinate system explanation
- [coord](../singletons/coord.md) - Coordinate conversion functions
