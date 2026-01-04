# land

The land singleton provides terrain information and pathfinding.

## land.getHeight

```lua
number land.getHeight(Vec2 position)
```

The `land.getHeight` function returns the terrain height at a position.

**Parameters:**
- `position` (Vec2): A table with x and y coordinates.

**Returns:** The height in meters above sea level.

```lua
local height = land.getHeight({x = 100000, y = 200000})
```

## land.getSurfaceHeightWithSeabed

```lua
number land.getSurfaceHeightWithSeabed(Vec2 position)
```

The `land.getSurfaceHeightWithSeabed` function returns the height including the seabed. This function returns negative values for underwater terrain.

**Parameters:**
- `position` (Vec2): A table with x and y coordinates.

**Returns:** The height in meters, where negative values indicate the seabed.

## land.getSurfaceType

```lua
number land.getSurfaceType(Vec2 position)
```

The `land.getSurfaceType` function returns the surface type at a position.

**Parameters:**
- `position` (Vec2): A table with x and y coordinates.

**Returns:** A surface type enum value from `land.SurfaceType`.

The `land.SurfaceType` enum defines the available surface types:

```lua
land.SurfaceType = {
    LAND = 1,
    SHALLOW_WATER = 2,
    WATER = 3,
    ROAD = 4,
    RUNWAY = 5
}
```

The RUNWAY value also includes taxiways and ramps.

```lua
local surface = land.getSurfaceType({x = pos.x, y = pos.z})
if surface == land.SurfaceType.WATER then
    env.info("Position is over water")
end
```

## land.isVisible

```lua
boolean land.isVisible(Vec3 origin, Vec3 destination)
```

The `land.isVisible` function checks if there is line-of-sight between two points. This function only considers terrain and ignores objects.

**Parameters:**
- `origin` (Vec3): The starting position.
- `destination` (Vec3): The target position.

**Returns:** True if the destination is visible from the origin, or false if terrain blocks the view.

```lua
local observer = Unit.getByName("JTAC"):getPoint()
local target = Unit.getByName("Target"):getPoint()
if land.isVisible(observer, target) then
    env.info("JTAC has eyes on target")
end
```

## land.getIP

```lua
Vec3 land.getIP(Vec3 origin, Vec3 direction, number distance)
```

The `land.getIP` function performs a ray cast and returns the intersection point with terrain. The direction parameter is a vector, not angles; use unit vectors from `getPosition()`.

**Parameters:**
- `origin` (Vec3): The starting position for the ray.
- `direction` (Vec3): The direction vector. The function normalizes this vector.
- `distance` (number): The maximum ray distance in meters.

**Returns:** The intersection point as a Vec3, or nil if there is no intersection within the specified distance.

```lua
local pos = aircraft:getPosition()
local impactPoint = land.getIP(pos.p, pos.x, 20000)
if impactPoint then
    env.info("Looking at ground point: " .. impactPoint.x .. ", " .. impactPoint.z)
end
```

## land.profile

```lua
table land.profile(Vec2 start, Vec2 finish)
```

The `land.profile` function returns terrain heights along a path between two points.

**Parameters:**
- `start` (Vec2): The starting position.
- `finish` (Vec2): The ending position.

**Returns:** An array of Vec3 points along the terrain profile.

## land.getClosestPointOnRoads

```lua
number, number land.getClosestPointOnRoads(string roadType, number x, number y)
```

The `land.getClosestPointOnRoads` function finds the nearest point on a road network.

**Parameters:**
- `roadType` (string): The type of road network. Valid values are "roads" or "railroads".
- `x` (number): The X coordinate.
- `y` (number): The Y coordinate using Vec2 convention.

**Returns:** The x and y coordinates of the nearest road point.

```lua
local roadX, roadY = land.getClosestPointOnRoads("roads", unitPos.x, unitPos.z)
```

## land.findPathOnRoads

```lua
table land.findPathOnRoads(string roadType, number x1, number y1, number x2, number y2)
```

The `land.findPathOnRoads` function finds a path along roads between two points.

**Parameters:**
- `roadType` (string): The type of road network. Valid values are "roads" or "railroads".
- `x1` (number): The starting X coordinate.
- `y1` (number): The starting Y coordinate.
- `x2` (number): The ending X coordinate.
- `y2` (number): The ending Y coordinate.

**Returns:** An array of Vec2 waypoints along the road.

```lua
local path = land.findPathOnRoads("roads", startX, startZ, endX, endZ)
if path then
    for i, waypoint in ipairs(path) do
        env.info("Waypoint " .. i .. ": " .. waypoint.x .. ", " .. waypoint.y)
    end
end
```

## See Also

- [Coordinate Types](../types/coordinates.md) - Vec2 and Vec3 coordinate systems
- [coord](coord.md) - Coordinate conversion functions
