# Group

The Group class represents a group of units. Groups are the primary unit of control for AI.

You can obtain Group objects using `Group.getByName("name")` to get a group by its Mission Editor name, `unit:getGroup()` to get the group from a unit, or `coalition.getGroups(coalitionId)` to get all groups for a coalition.

The `Group.Category` enum defines the group categories:

```lua
Group.Category = {
    AIRPLANE = 0,
    HELICOPTER = 1,
    GROUND = 2,
    SHIP = 3,
    TRAIN = 4
}
```

## Group.getByName

```lua
Group Group.getByName(string name)
```

The `Group.getByName` function is a static function that returns a group by its Mission Editor name.

**Parameters:**
- `name` (string): The group's name as defined in the Mission Editor.

**Returns:** A Group object, or nil if the group is not found.

```lua
local capFlight = Group.getByName("Enemy CAP")
if capFlight and capFlight:isExist() then
    local size = capFlight:getSize()
end
```

## group:isExist

```lua
boolean group:isExist()
```

The `group:isExist` method returns whether the group exists. Groups cease to exist when all units are destroyed.

**Returns:** True if at least one unit is alive, or false otherwise.

## group:activate

```lua
nil group:activate()
```

The `group:activate` method activates a late-activation group, causing it to spawn and begin its mission.

```lua
local reinforcements = Group.getByName("Reinforcements")
reinforcements:activate()
```

## group:destroy

```lua
nil group:destroy()
```

The `group:destroy` method destroys the entire group, removing all units.

## group:getCategory

```lua
number group:getCategory()
```

The `group:getCategory` method returns the group category.

**Returns:** A category value from `Group.Category`.

## group:getCoalition

```lua
number group:getCoalition()
```

The `group:getCoalition` method returns the group's coalition.

**Returns:** A coalition value from `coalition.side`.

## group:getName

```lua
string group:getName()
```

The `group:getName` method returns the group's name.

**Returns:** The group name as a string.

## group:getID

```lua
number group:getID()
```

The `group:getID` method returns the group's unique numeric ID. This ID is used for group-specific menu commands and messages.

**Returns:** The group ID as a number.

```lua
local groupId = group:getID()
missionCommands.addCommandForGroup(groupId, "Request Support", nil, requestSupport)
```

## group:getUnit

```lua
Unit group:getUnit(number index)
```

The `group:getUnit` method returns a specific unit from the group by index. The indexing is 1-based.

**Parameters:**
- `index` (number): The unit position in the group, where 1 is the lead.

**Returns:** A Unit object.

```lua
local lead = group:getUnit(1)
local wingman = group:getUnit(2)
```

## group:getUnits

```lua
table group:getUnits()
```

The `group:getUnits` method returns all units in the group.

**Returns:** An array of Unit objects.

```lua
for i, unit in ipairs(group:getUnits()) do
    env.info("Unit " .. i .. ": " .. unit:getName())
end
```

## group:getSize

```lua
number group:getSize()
```

The `group:getSize` method returns the number of units currently alive in the group.

**Returns:** The current unit count as a number.

## group:getInitialSize

```lua
number group:getInitialSize()
```

The `group:getInitialSize` method returns the number of units the group started with.

**Returns:** The initial unit count as a number.

```lua
local current = group:getSize()
local initial = group:getInitialSize()
local losses = initial - current
```

## group:getController

```lua
Controller group:getController()
```

The `group:getController` method returns the group's AI controller. This method is the primary way to control AI behavior.

**Returns:** A Controller object.

```lua
local controller = group:getController()
controller:setTask(orbitTask)
```

## group:enableEmission

```lua
nil group:enableEmission(boolean enable)
```

The `group:enableEmission` method enables or disables radar and radio emissions for all units in the group.

**Parameters:**
- `enable` (boolean): Set to true to enable emissions, or false to disable.

## See Also

- [unit](unit.md) - Unit class
- [controller](controller.md) - AI control interface
- [coalition](../singletons/coalition.md) - Group spawning and queries
- [mission-commands](../singletons/mission-commands.md) - Group-specific menu commands
