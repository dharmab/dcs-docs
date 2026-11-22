# StaticObject

A StaticObject is a non-moving object placed in the mission, such as a building, cargo, or decoration.

Inherits from: [Object](object.md), [CoalitionObject](coalition-object.md)

`StaticObject.getByName("name")` and `coalition.getStaticObjects(coalitionId)` (all static objects of a coalition) return StaticObject objects.

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
- [coalition](../singletons/coalition.md) - Static object spawning and queries
