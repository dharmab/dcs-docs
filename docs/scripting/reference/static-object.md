# StaticObject

The StaticObject class represents non-moving objects placed in the mission, such as buildings, cargo, and decorations.

Inherits from: [Object](object.md), [CoalitionObject](coalition-object.md)

You can obtain StaticObject objects using `StaticObject.getByName("name")` to get a static object by name, or `coalition.getStaticObjects(coalitionId)` to get all static objects for a coalition.

## StaticObject.getByName

```lua
StaticObject StaticObject.getByName(string name)
```

The `StaticObject.getByName` function is a static function that returns a static object by name.

**Parameters:**
- `name` (string): The object's name as defined in the Mission Editor.

**Returns:** A StaticObject, or nil if the object is not found.

## staticObject:getLife

```lua
number staticObject:getLife()
```

The `staticObject:getLife` method returns the object's current hit points.

**Returns:** The current hit points as a number.

## See Also

- [object](object.md) - Base class methods
- [coalition-object](coalition-object.md) - Coalition and country methods
- [coalition](coalition.md) - Static object spawning and queries
