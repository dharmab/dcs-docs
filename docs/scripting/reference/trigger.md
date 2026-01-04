# trigger

The trigger singleton provides access to trigger zones, user flags, and trigger-style actions like messages, smoke, and explosions. The singleton is divided into two sub-tables: `trigger.action` for actions and `trigger.misc` for utilities.

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

```lua
local zone = trigger.misc.getZone("LandingZone")
if zone then
    local center = zone.point
    local radius = zone.radius
    env.info("Zone center: " .. center.x .. ", " .. center.z)
end
```

## See Also

- [Data Types](data-types.md) - Vec3 and coordinate systems
- [coalition](coalition.md) - Coalition identifiers
- [group](group.md) - Group objects and IDs
- [unit](unit.md) - Unit objects and IDs
