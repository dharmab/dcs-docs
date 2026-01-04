# CoalitionObject

The CoalitionObject class extends Object with coalition and country information. This class is the base class for Unit, Weapon, StaticObject, and Airbase.

Inherits from: [Object](object.md)

## object:getCoalition

```lua
number object:getCoalition()
```

The `object:getCoalition` method returns the object's coalition.

**Returns:** A coalition value from `coalition.side`. The value is 0 for neutral, 1 for red, or 2 for blue.

```lua
if unit:getCoalition() == coalition.side.BLUE then
    env.info("Friendly unit")
end
```

## object:getCountry

```lua
number object:getCountry()
```

The `object:getCountry` method returns the object's country.

**Returns:** A country ID from the `country.id` enum.

```lua
local countryId = unit:getCountry()
```

## See Also

- [object](object.md) - Base class methods
- [unit](unit.md) - Unit class (extends CoalitionObject)
- [static-object](static-object.md) - Static object class (extends CoalitionObject)
- [weapon](weapon.md) - Weapon class (extends CoalitionObject)
- [airbase](airbase.md) - Airbase class (extends CoalitionObject)
- [Coalition Enums](../enums/coalition.md) - Coalition and country identifiers
