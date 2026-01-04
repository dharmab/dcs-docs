# Unit

The Unit class represents controllable units: aircraft, helicopters, ground vehicles, ships, and armed structures.

Inherits from: [Object](object.md), [CoalitionObject](coalition-object.md)

You can obtain Unit objects using `Unit.getByName("name")` to get a unit by its Mission Editor name, `group:getUnits()` to get all units in a group, or `event.initiator` to get the unit from an event.

The `Unit.Category` enum defines the unit categories:

```lua
Unit.Category = {
    AIRPLANE = 0,
    HELICOPTER = 1,
    GROUND_UNIT = 2,
    SHIP = 3,
    STRUCTURE = 4
}
```

The `unit:getCategory()` method returns `Object.Category.UNIT`. To get the unit type (airplane, helicopter, etc.), use `unit:getDesc().category` which returns a value from `Unit.Category`.

## Unit.getByName

```lua
Unit Unit.getByName(string name)
```

The `Unit.getByName` function is a static function that returns a unit by its Mission Editor name.

**Parameters:**
- `name` (string): The unit's name as defined in the Mission Editor.

**Returns:** A Unit object, or nil if the unit is not found or has been destroyed.

```lua
local player = Unit.getByName("Player F-16")
if player then
    env.info("Player aircraft found")
end
```

## unit:isActive

```lua
boolean unit:isActive()
```

The `unit:isActive` method returns whether the unit is active. Units with late activation are inactive until activated by a trigger.

**Returns:** True if the unit is active, or false otherwise.

```lua
if not unit:isActive() then
    unit:getGroup():activate()
end
```

## unit:getPlayerName

```lua
string unit:getPlayerName()
```

The `unit:getPlayerName` method returns the player's name if this unit is controlled by a human.

**Returns:** The player name as a string, or nil for AI units.

```lua
local playerName = unit:getPlayerName()
if playerName then
    env.info("Controlled by: " .. playerName)
end
```

## unit:getID

```lua
number unit:getID()
```

The `unit:getID` method returns the unit's unique numeric ID.

**Returns:** The unit ID as a number.

## unit:getNumber

```lua
number unit:getNumber()
```

The `unit:getNumber` method returns the unit's position number within its group. The numbering is 1-based.

**Returns:** The position in the group as a number.

```lua
local num = unit:getNumber()
if num == 1 then
    env.info("This is the flight lead")
end
```

## unit:getGroup

```lua
Group unit:getGroup()
```

The `unit:getGroup` method returns the group this unit belongs to.

**Returns:** A Group object.

```lua
local group = unit:getGroup()
local groupName = group:getName()
```

## unit:getCallsign

```lua
string unit:getCallsign()
```

The `unit:getCallsign` method returns the unit's callsign.

**Returns:** The callsign as a string, such as "Enfield11".

```lua
local callsign = unit:getCallsign()
trigger.action.outText(callsign .. ", cleared hot", 5)
```

## unit:getLife

```lua
number unit:getLife()
```

The `unit:getLife` method returns the unit's current hit points. Units with a life value less than 1 are considered dead. Ground units that are on fire but have not yet exploded return 0.

**Returns:** The current hit points as a number.

```lua
local life = unit:getLife()
local maxLife = unit:getDesc().life
local healthPercent = (life / maxLife) * 100
```

## unit:getLife0

```lua
number unit:getLife0()
```

The `unit:getLife0` method returns the unit's initial (maximum) hit points.

**Returns:** The initial hit points as a number.

## unit:getFuel

```lua
number unit:getFuel()
```

The `unit:getFuel` method returns the unit's fuel level as a fraction of internal fuel capacity. Ground vehicles and ships always return 1. Aircraft with external tanks can return values above 1.0.

**Returns:** The fuel fraction as a number from 0.0 to 1.0 or higher. Values above 1.0 indicate external tanks are present.

```lua
local fuel = unit:getFuel()
if fuel < 0.2 then
    trigger.action.outText("Bingo fuel!", 10)
end
```

## unit:getAmmo

```lua
table unit:getAmmo()
```

The `unit:getAmmo` method returns detailed ammunition information.

**Returns:** An array of ammo entries. Each entry contains a `count` field and a `desc` field with the weapon description.

```lua
local ammo = unit:getAmmo()
for _, wpn in ipairs(ammo or {}) do
    env.info(wpn.desc.displayName .. ": " .. wpn.count)
end
```

## unit:getController

```lua
Controller unit:getController()
```

The `unit:getController` method returns the unit's AI controller. For aircraft, you can control individual units. For ground and ship units, use the group controller instead.

**Returns:** A Controller object.

```lua
local controller = unit:getController()
controller:setOption(AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.WEAPON_FREE)
```

## unit:getSensors

```lua
table unit:getSensors()
```

The `unit:getSensors` method returns information about the unit's sensors, such as radar and IRST.

**Returns:** A table of sensor information.

## unit:getRadar

```lua
boolean, Object unit:getRadar()
```

The `unit:getRadar` method returns the radar status and current target.

**Returns:** Two values: a boolean indicating whether the radar is on, and the target Object or nil if no target is locked.

```lua
local radarOn, target = unit:getRadar()
if radarOn and target then
    env.info("Radar locked onto: " .. target:getName())
end
```

## unit:enableEmission

```lua
nil unit:enableEmission(boolean enable)
```

The `unit:enableEmission` method enables or disables radar and radio emissions for the unit.

**Parameters:**
- `enable` (boolean): Set to true to enable emissions, or false to disable.

```lua
unit:enableEmission(false)
```

## See Also

- [object](object.md) - Base class methods
- [coalition-object](coalition-object.md) - Coalition and country methods
- [group](group.md) - Group class
- [controller](controller.md) - AI control interface
- [events](../events/events.md) - Unit-related events
