# trigger

The trigger singleton provides access to trigger zones, user flags, and trigger-style actions like messages, smoke, and explosions. The singleton is divided into two sub-tables: `trigger.action` for actions and `trigger.misc` for utilities.

Functions that accept position parameters (such as `smoke`, `explosion`, `illuminationBomb`, and `signalFlare`) may fail or produce unexpected results if the coordinates fall outside the current map's boundaries. When calling these functions with dynamically calculated positions, consider using `pcall()` to handle potential errors gracefully.

## trigger.action.outText

```lua
nil trigger.action.outText(string text, number displayTime, boolean clearView)
```

The `trigger.action.outText` function displays a message to all players on screen.

**Parameters:**

- `text` (string): The message to display.
- `displayTime` (number): The duration in seconds that the message remains visible.
- `clearView` (boolean): Optional. If true, the function clears other messages before displaying this one.

```lua
trigger.action.outText("Mission objective updated!", 10)
```

## trigger.action.outTextForCoalition

```lua
nil trigger.action.outTextForCoalition(number coalitionId, string text, number displayTime, boolean clearView)
```

The `trigger.action.outTextForCoalition` function displays a message only to players of a specific coalition.

**Parameters:**

- `coalitionId` (number): The coalition to display the message to. Use `coalition.side.NEUTRAL` (0), `coalition.side.RED` (1), or `coalition.side.BLUE` (2).
- `text` (string): The message to display.
- `displayTime` (number): The duration in seconds that the message remains visible.
- `clearView` (boolean): Optional. If true, the function clears other messages before displaying this one.

```lua
trigger.action.outTextForCoalition(coalition.side.BLUE, "Blue team: reinforcements inbound", 15)
```

## trigger.action.outTextForGroup

```lua
nil trigger.action.outTextForGroup(number groupId, string text, number displayTime, boolean clearView)
```

The `trigger.action.outTextForGroup` function displays a message only to players in a specific group.

**Parameters:**

- `groupId` (number): The group's numeric ID. Call `group:getID()` on a Group object to obtain this value.
- `text` (string): The message to display.
- `displayTime` (number): The duration in seconds that the message remains visible.
- `clearView` (boolean): Optional. If true, the function clears other messages before displaying this one.

```lua
local group = Group.getByName("Player Flight")
if group then
    trigger.action.outTextForGroup(group:getID(), "Your target is marked with smoke", 10)
end
```

## trigger.action.outTextForUnit

```lua
nil trigger.action.outTextForUnit(number unitId, string text, number displayTime, boolean clearView)
```

The `trigger.action.outTextForUnit` function displays a message only to a specific player unit.

**Parameters:**

- `unitId` (number): The unit's numeric ID. Call `unit:getID()` on a Unit object to obtain this value.
- `text` (string): The message to display.
- `displayTime` (number): The duration in seconds that the message remains visible.
- `clearView` (boolean): Optional. If true, the function clears other messages before displaying this one.

## trigger.action.smoke

```lua
nil trigger.action.smoke(Vec3 position, number smokeColor)
```

The `trigger.action.smoke` function creates a smoke marker at the specified position.

**Parameters:**

- `position` (Vec3): The world position where the smoke appears.
- `smokeColor` (number): The smoke color from the `trigger.smokeColor` enum.

The `trigger.smokeColor` enum defines the available smoke colors:

```lua
trigger.smokeColor = {
    Green = 0,
    Red = 1,
    White = 2,
    Orange = 3,
    Blue = 4
}
```

```lua
local targetPos = Unit.getByName("Target"):getPoint()
trigger.action.smoke(targetPos, trigger.smokeColor.Red)
```

## trigger.action.effectSmokeBig

```lua
nil trigger.action.effectSmokeBig(Vec3 position, number smokeType, number density, string name)
```

The `trigger.action.effectSmokeBig` function creates a large smoke effect at the specified position.

**Parameters:**

- `position` (Vec3): The world position where the smoke effect appears.
- `smokeType` (number): The type of smoke, where values range from 1 to 3 and larger numbers produce more smoke.
- `density` (number): The smoke density, where values range from 0.1 to 1.0.
- `name` (string): A unique identifier for this smoke effect.

```lua
local crashSite = {x = 100000, y = 0, z = 200000}
trigger.action.effectSmokeBig(crashSite, 2, 0.8, "crash_smoke_1")
```

## trigger.action.illuminationBomb

```lua
nil trigger.action.illuminationBomb(Vec3 position, number power)
```

The `trigger.action.illuminationBomb` function creates an illumination flare at the specified position. The altitude component of the position determines where the flare appears in the sky.

**Parameters:**

- `position` (Vec3): The world position where the flare appears.
- `power` (number): The brightness of the illumination.

```lua
local flarePos = {x = 100000, y = 500, z = 200000}
trigger.action.illuminationBomb(flarePos, 1000000)
```

## trigger.action.signalFlare

```lua
nil trigger.action.signalFlare(Vec3 position, number flareColor, number azimuth)
```

The `trigger.action.signalFlare` function fires a signal flare from the specified position.

**Parameters:**

- `position` (Vec3): The launch position for the flare.
- `flareColor` (number): The flare color from the `trigger.flareColor` enum.
- `azimuth` (number): The direction in radians.

The `trigger.flareColor` enum defines the available flare colors:

```lua
trigger.flareColor = {
    Green = 0,
    Red = 1,
    White = 2,
    Yellow = 3
}
```

## trigger.action.explosion

```lua
nil trigger.action.explosion(Vec3 position, number power)
```

The `trigger.action.explosion` function creates an explosion at the specified position. Very large explosions can cause performance issues, so values above 1000 should be used carefully.

**Parameters:**

- `position` (Vec3): The world position where the explosion occurs.
- `power` (number): The explosion power, equivalent to kilograms of explosives.

```lua
trigger.action.explosion({x = 100000, y = 100, z = 200000}, 100)
```

## trigger.action.markToAll

```lua
nil trigger.action.markToAll(number id, string text, Vec3 position, boolean readOnly, string message)
```

The `trigger.action.markToAll` function adds a labelled mark point to the F10 map for all players.[^markers]

**Parameters:**

- `id` (number): A unique ID for the mark. Marks and drawings share one ID space, so an ID already used by either is rejected.
- `text` (string): The label shown on the mark.
- `position` (Vec3): The world position of the mark.
- `readOnly` (boolean): Optional. If true, players cannot edit or delete the mark.
- `message` (string): Optional. Text for an on-screen message box shown when the mark is added. The text does not appear on the F10 map.

```lua
trigger.action.markToAll(1000, "BULLSEYE", {x = -280000, y = 0, z = 650000}, true, "")
```

## trigger.action.markToCoalition

```lua
nil trigger.action.markToCoalition(number id, string text, Vec3 position, number coalitionId, boolean readOnly, string message)
```

The `trigger.action.markToCoalition` function adds a labelled mark point to the F10 map for one coalition.[^markers]

**Parameters:**

- `id` (number): A unique ID for the mark. Marks and drawings share one ID space, so an ID already used by either is rejected.
- `text` (string): The label shown on the mark.
- `position` (Vec3): The world position of the mark.
- `coalitionId` (number): The coalition that can see the mark, from `coalition.side`.
- `readOnly` (boolean): Optional. If true, players cannot edit or delete the mark.
- `message` (string): Optional. Text for an on-screen message box shown when the mark is added. The text does not appear on the F10 map.

```lua
trigger.action.markToCoalition(1001, "SUPPLY DEPOT", {x = -280000, y = 0, z = 650000}, coalition.side.BLUE, true, "")
```

## trigger.action.markToGroup

```lua
nil trigger.action.markToGroup(number id, string text, Vec3 position, number groupId, boolean readOnly, string message)
```

The `trigger.action.markToGroup` function adds a labelled mark point to the F10 map for one group.[^markers]

**Parameters:**

- `id` (number): A unique ID for the mark. Marks and drawings share one ID space, so an ID already used by either is rejected.
- `text` (string): The label shown on the mark.
- `position` (Vec3): The world position of the mark.
- `groupId` (number): The group that can see the mark. Call `group:getID()` on a Group object to obtain this value.
- `readOnly` (boolean): Optional. If true, players cannot edit or delete the mark.
- `message` (string): Optional. Text for an on-screen message box shown when the mark is added. The text does not appear on the F10 map.

```lua
local group = Group.getByName("Player Flight")
if group then
    trigger.action.markToGroup(1003, "TARGET", {x = -280000, y = 0, z = 650000}, group:getID(), true, "")
end
```

## trigger.action.circleToAll

```lua
nil trigger.action.circleToAll(number coalitionId, number id, Vec3 center, number radius, table color, table fillColor, number lineType, boolean readOnly, string message)
```

The `trigger.action.circleToAll` function draws a circle on the F10 map.[^markers]

**Parameters:**

- `coalitionId` (number): The coalition that can see the circle, from `coalition.side`, or -1 for all coalitions.
- `id` (number): A unique ID, shared with marks.
- `center` (Vec3): The world position of the circle center.
- `radius` (number): The radius in meters.
- `color` (table): The outline color as `{r, g, b, a}`, each 0 to 1.
- `fillColor` (table): The fill color as `{r, g, b, a}`, each 0 to 1.
- `lineType` (number): 0 no line, 1 solid, 2 dashed, 3 dotted, 4 dot dash, 5 long dash, 6 two dash.
- `readOnly` (boolean): Optional. If true, players cannot edit or delete the circle.
- `message` (string): Optional. Text for an on-screen message box shown when the circle is added. The text does not appear on the F10 map.

`lineToAll`, `arrowToAll`, and `textToAll` follow the same pattern: coalition first, then ID, then shape-specific arguments.

```lua
trigger.action.circleToAll(-1, 1002, {x = -280000, y = 0, z = 650000}, 1500, {1, 0, 0, 1}, {1, 0, 0, 0.15}, 2, true, "")
```

## trigger.action.removeMark

```lua
nil trigger.action.removeMark(number id)
```

The `trigger.action.removeMark` function removes the mark or drawing with the given ID from the F10 map.[^markers]

```lua
trigger.action.removeMark(1002)
```

## trigger.action.setUserFlag

```lua
nil trigger.action.setUserFlag(string flagName, number value)
```

The `trigger.action.setUserFlag` function sets the value of a user flag. Flags are integer values that can be read by triggers or scripts.

**Parameters:**

- `flagName` (string): The flag name or number.
- `value` (number): The value to set.

```lua
trigger.action.setUserFlag("objective_complete", 1)
```

## trigger.misc.getUserFlag

```lua
number trigger.misc.getUserFlag(string flagName)
```

The `trigger.misc.getUserFlag` function returns the current value of a user flag.

**Parameters:**

- `flagName` (string): The flag name or number to look up.

**Returns:** The flag's value as a number.

```lua
if trigger.misc.getUserFlag("objective_complete") == 1 then
    spawnReinforcements()
end
```

## trigger.misc.getZone

```lua
table trigger.misc.getZone(string zoneName)
```

The `trigger.misc.getZone` function returns information about a trigger zone defined in the Mission Editor.

**Parameters:**

- `zoneName` (string): The name of the trigger zone to look up.

**Returns:** A table with zone properties, or nil if the zone does not exist.

For circular zones, the returned table contains:

```lua
{
    point = Vec3,
    radius = number
}
```

The `point` field contains the center position of the zone. The `radius` field contains the radius of the zone in meters.

For polygon zones (quad-point zones), the returned table contains:

```lua
{
    point = Vec3,
    verticies = {Vec3, ...}
}
```

The `point` field contains the center position of the zone. The `verticies` field contains an array of Vec3 values representing the corner points. The API uses "verticies" (misspelled) rather than "vertices."

Vertex order follows how the zone was drawn, so it may be clockwise or counter-clockwise. Geometry code that needs a specific orientation (such as triangulation) should check the signed area and reverse the points if needed.

```lua
local zone = trigger.misc.getZone("LandingZone")
if zone then
    local center = zone.point
    local radius = zone.radius
    env.info("Zone center: " .. center.x .. ", " .. center.z)
end
```

## Lua-Defined Wrappers

These `trigger.action` functions are thin Lua wrappers around other API calls. Calling the underlying function directly is clearer.

| Function                                                                      | What it calls                                                                            |
| ----------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| `trigger.action.activateGroup(group)`                                         | `group:activate()`                                                                       |
| `trigger.action.deactivateGroup(group)`                                       | `group:destroy()`                                                                        |
| `trigger.action.setGroupAIOn(group)`                                          | `group:getController():setOnOff(true)`                                                   |
| `trigger.action.setGroupAIOff(group)`                                         | `group:getController():setOnOff(false)`                                                  |
| `trigger.action.groupStopMoving(group)`                                       | `group:getController():setCommand({id = 'StopRoute', params = {value = true}})`          |
| `trigger.action.groupContinueMoving(group)`                                   | `group:getController():setCommand({id = 'StopRoute', params = {value = false}})`         |
| `trigger.action.addOtherCommand(name, flagName, flagValue)`                   | `missionCommands.addCommand(name, nil, ...)`; the command sets `flagName` to `flagValue` |
| `trigger.action.removeOtherCommand(name)`                                     | `missionCommands.removeItem({name})`                                                     |
| `trigger.action.addOtherCommandForCoalition(side, name, flagName, flagValue)` | `missionCommands.addCommandForCoalition(side, name, nil, ...)`                           |
| `trigger.action.removeOtherCommandForCoalition(side, name)`                   | `missionCommands.removeItemForCoalition(side, {name})`                                   |
| `trigger.action.addOtherCommandForGroup(groupId, name, flagName, flagValue)`  | `missionCommands.addCommandForGroup(groupId, name, nil, ...)`                            |
| `trigger.action.removeOtherCommandForGroup(groupId, name)`                    | `missionCommands.removeItemForGroup(groupId, {name})`                                    |

If `flagValue` is omitted, the `addOtherCommand*` functions set the flag to `true`. Note that `deactivateGroup` destroys the group; it cannot be activated again.

## See Also

- [Coordinate Types](../types/coordinates.md) - Vec3 and coordinate systems
- [coalition](coalition.md) - Coalition identifiers
- [group](../classes/group.md) - Group objects and IDs
- [unit](../classes/unit.md) - Unit objects and IDs

[^markers]: Hoggit Wiki, [DCS func markToAll](https://wiki.hoggitworld.com/view/DCS_func_markToAll), [DCS func markToCoalition](https://wiki.hoggitworld.com/view/DCS_func_markToCoalition), [DCS func markToGroup](https://wiki.hoggitworld.com/view/DCS_func_markToGroup), [DCS func circleToAll](https://wiki.hoggitworld.com/view/DCS_func_circleToAll), and [DCS func removeMark](https://wiki.hoggitworld.com/view/DCS_func_removeMark). These functions are engine-side; no installed Lua file defines them.
