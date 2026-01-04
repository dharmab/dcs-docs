# Spot

The Spot class represents a laser or infrared designator spot. You create spots dynamically through static functions.

The `Spot.Category` enum defines the spot categories:

```lua
Spot.Category = {
    INFRA_RED = 0,
    LASER = 1
}
```

## Spot.createLaser

```lua
Spot Spot.createLaser(Object source, table localPosition, Vec3 targetPoint, number laserCode)
```

The `Spot.createLaser` function creates a laser spot emanating from an object.

**Parameters:**
- `source` (Object): The object the laser originates from.
- `localPosition` (table): The offset from the object's center.
- `targetPoint` (Vec3): The point where the laser is pointing.
- `laserCode` (number): The 4-digit laser code, ranging from 1111 to 1788.

**Returns:** A Spot object.

```lua
local jtac = Unit.getByName("JTAC")
local target = Unit.getByName("Target"):getPoint()
local spot = Spot.createLaser(jtac, {x=0, y=2, z=0}, target, 1688)
```

## Spot.createInfraRed

```lua
Spot Spot.createInfraRed(Object source, table localPosition, Vec3 targetPoint)
```

Creates an infrared pointer spot.

**Parameters:**
- `source` (Object): The object the IR pointer originates from.
- `localPosition` (table): Offset from the object's center.
- `targetPoint` (Vec3): Where the IR is pointing.

**Returns:** Spot object.

## spot:destroy

```lua
nil spot:destroy()
```

Removes the spot.

## spot:getPoint

```lua
Vec3 spot:getPoint()
```

Returns where the spot is currently pointing.

**Returns:** Vec3 target position.

## spot:setPoint

```lua
nil spot:setPoint(Vec3 targetPoint)
```

Changes where the spot is pointing.

**Parameters:**
- `targetPoint` (Vec3): New target position.

```lua
-- Update laser to track a moving target
local newPos = movingTarget:getPoint()
spot:setPoint(newPos)
```

## spot:getCode

```lua
number spot:getCode()
```

Returns the laser code (laser spots only).

**Returns:** 4-digit laser code.

## spot:setCode

```lua
nil spot:setCode(number code)
```

Changes the laser code.

**Parameters:**
- `code` (number): New 4-digit laser code (1111-1788).

## See Also

- [unit](unit.md) - Unit class (source object for spots)
- [Data Types](data-types.md) - Vec3 coordinate system
