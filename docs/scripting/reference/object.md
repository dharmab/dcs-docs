# Object

The Object class is the base class for all objects with a physical presence in the game world. This is an abstract class; you work with its subclasses such as Unit, Weapon, and StaticObject.

The `Object.Category` enum defines the object categories:

```lua
Object.Category = {
    UNIT = 1,
    WEAPON = 2,
    STATIC = 3,
    BASE = 4,
    SCENERY = 5,
    CARGO = 6
}
```

## object:isExist

```lua
boolean object:isExist()
```

The `object:isExist` method returns whether the object currently exists in the mission. Objects cease to exist when destroyed. Always check `isExist()` before calling other methods on objects obtained from stored references, as the object may have been destroyed since you acquired the reference.

**Returns:** True if the object exists, or false otherwise.

```lua
local unit = Unit.getByName("Target 1")
if unit and unit:isExist() then
    local pos = unit:getPoint()
end
```

## object:destroy

```lua
nil object:destroy()
```

The `object:destroy` method destroys the object, removing it from the mission. For units, this method kills them instantly without any death animation or explosion.

```lua
local debris = StaticObject.getByName("wreckage")
if debris then
    debris:destroy()
end
```

## object:getCategory

```lua
number object:getCategory()
```

The `object:getCategory` method returns the object's category from the `Object.Category` enum.

**Returns:** A category enum value.

```lua
local cat = object:getCategory()
if cat == Object.Category.UNIT then
    env.info("This is a unit")
end
```

## object:getTypeName

```lua
string object:getTypeName()
```

The `object:getTypeName` method returns the object's type name as used in the mission file, such as "F-16C_50" or "SA-11 Buk LN 9A310M1".

**Returns:** The type name as a string.

```lua
local typeName = unit:getTypeName()
env.info("Unit type: " .. typeName)
```

## object:getDesc

```lua
table object:getDesc()
```

The `object:getDesc` method returns a description table with detailed information about the object type. The contents of the table vary by object type.

**Returns:** A description table that contains at minimum the `life` and `box` fields.

```lua
local desc = unit:getDesc()
env.info("Max life: " .. desc.life)
```

## object:hasAttribute

```lua
boolean object:hasAttribute(string attributeName)
```

The `object:hasAttribute` method checks if the object has a specific attribute, such as "Air", "Ground Units", or "SAM related".

**Parameters:**
- `attributeName` (string): The attribute to check for.

**Returns:** True if the object has the attribute, or false otherwise.

```lua
if unit:hasAttribute("SAM related") then
    env.info("This is a SAM unit")
end
```

## object:getName

```lua
string object:getName()
```

The `object:getName` method returns the object's unique name as defined in the Mission Editor.

**Returns:** The object name as a string.

```lua
local name = unit:getName()
trigger.action.outText(name .. " has been spotted", 10)
```

## object:getPoint

```lua
Vec3 object:getPoint()
```

The `object:getPoint` method returns the object's position in 3D space.

**Returns:** A Vec3 containing the x, y (altitude), and z coordinates.

```lua
local pos = unit:getPoint()
local altitude = pos.y
env.info("Altitude: " .. altitude .. " meters")
```

## object:getPosition

```lua
Position3 object:getPosition()
```

The `object:getPosition` method returns the object's position and orientation.

**Returns:** A Position3 table with `p` (the position) and `x`, `y`, `z` (the orientation vectors).

```lua
local pos = unit:getPosition()
local heading = math.atan2(pos.x.z, pos.x.x)
```

## object:getVelocity

```lua
Vec3 object:getVelocity()
```

The `object:getVelocity` method returns the object's velocity vector.

**Returns:** A Vec3 containing the velocity in meters per second for each axis.

```lua
local vel = unit:getVelocity()
local speed = math.sqrt(vel.x^2 + vel.y^2 + vel.z^2)
env.info("Speed: " .. speed .. " m/s")
```

## object:inAir

```lua
boolean object:inAir()
```

The `object:inAir` method returns whether the object is airborne.

**Returns:** True if the object is in the air, or false if the object is on the ground.

```lua
if unit:inAir() then
    env.info("Aircraft is flying")
else
    env.info("Aircraft is on the ground")
end
```

## See Also

- [coalition-object](coalition-object.md) - Coalition and country information (extends Object)
- [unit](unit.md) - Unit class (extends Object and CoalitionObject)
- [static-object](static-object.md) - Static object class (extends Object and CoalitionObject)
- [weapon](weapon.md) - Weapon class (extends Object and CoalitionObject)
- [Data Types](data-types.md) - Vec3 and Position3 coordinate systems
