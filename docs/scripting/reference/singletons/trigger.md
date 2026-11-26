# trigger

The trigger singleton contains functions for trigger zones, user flags, and trigger actions such as messages, sounds, radio transmissions, smoke, explosions, and F10 map drawings. It contains two sub-tables: `trigger.action` for actions and `trigger.misc` for utilities.

Functions that accept position parameters (such as `smoke`, `explosion`, `illuminationBomb`, and `signalFlare`) may fail or return wrong results for coordinates outside the map. Wrap calls with computed positions in `pcall()`.

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

## trigger.action.outTextForCountry

```lua
nil trigger.action.outTextForCountry(number countryId, string text, number displayTime, boolean clearView)
```

The `trigger.action.outTextForCountry` function displays a message only to players of a specific country.[^text]

**Parameters:**

- `countryId` (number): The country to display the message to, from the `country.id` enum.
- `text` (string): The message to display.
- `displayTime` (number): The duration in seconds that the message remains visible.
- `clearView` (boolean): Optional. If true, the function clears other messages before displaying this one.

```lua
trigger.action.outTextForCountry(country.id.USA, "US forces: hold at the FLOT", 10)
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

## trigger.action.outSound

```lua
nil trigger.action.outSound(string soundFile)
```

The `trigger.action.outSound` function plays a sound file to all players.[^sound]

**Parameters:**

- `soundFile` (string): The path of the sound file inside the `.miz`. Files in the archive root are under `l10n/DEFAULT/`, so the path may need that prefix.

```lua
trigger.action.outSound("l10n/DEFAULT/alarm.ogg")
```

The sound file must be inside the `.miz`. See [MIZ File Format](../../../mission/miz-file-format.md) for where resource files go.

## trigger.action.outSoundForCoalition

```lua
nil trigger.action.outSoundForCoalition(number coalitionId, string soundFile)
```

The `trigger.action.outSoundForCoalition` function plays a sound file to players of one coalition.[^sound]

**Parameters:**

- `coalitionId` (number): The coalition, from `coalition.side`.
- `soundFile` (string): The path of the sound file inside the `.miz`.

## trigger.action.outSoundForCountry

```lua
nil trigger.action.outSoundForCountry(number countryId, string soundFile)
```

The `trigger.action.outSoundForCountry` function plays a sound file to players of one country.[^sound]

**Parameters:**

- `countryId` (number): The country, from `country.id`.
- `soundFile` (string): The path of the sound file inside the `.miz`.

## trigger.action.outSoundForGroup

```lua
nil trigger.action.outSoundForGroup(number groupId, string soundFile)
```

The `trigger.action.outSoundForGroup` function plays a sound file to players in one group.[^sound]

**Parameters:**

- `groupId` (number): The group's numeric ID. Call `group:getID()` on a Group object to obtain this value.
- `soundFile` (string): The path of the sound file inside the `.miz`.

## trigger.action.outSoundForUnit

```lua
nil trigger.action.outSoundForUnit(number unitId, string soundFile)
```

The `trigger.action.outSoundForUnit` function plays a sound file to the player in one unit.[^sound]

**Parameters:**

- `unitId` (number): The unit's numeric ID. Call `unit:getID()` on a Unit object to obtain this value.
- `soundFile` (string): The path of the sound file inside the `.miz`.

## trigger.action.radioTransmission

```lua
nil trigger.action.radioTransmission(string soundFile, Vec3 position, number modulation, boolean loop, number frequency, number power, string name)
```

The `trigger.action.radioTransmission` function transmits a sound file on a radio frequency from a point in the world. Only players tuned to the frequency and within range hear it.[^radio]

**Parameters:**

- `soundFile` (string): The path of the sound file inside the `.miz`.
- `position` (Vec3): The world position of the transmitter.
- `modulation` (number): 0 for AM, 1 for FM.
- `loop` (boolean): If true, the transmission repeats until stopped.
- `frequency` (number): The frequency in Hz. For example, 124 MHz is `124000000`.
- `power` (number): The transmitter power in watts.
- `name` (string): A name for the transmission. `stopRadioTransmission` needs this name to stop it.

```lua
local p = trigger.misc.getZone("Beacon").point
trigger.action.radioTransmission("l10n/DEFAULT/beacon.ogg", p, 0, true, 124000000, 100, "beacon")
```

## trigger.action.stopRadioTransmission

```lua
nil trigger.action.stopRadioTransmission(string name)
```

The `trigger.action.stopRadioTransmission` function stops a transmission started by `radioTransmission`.[^radio]

**Parameters:**

- `name` (string): The name passed to `radioTransmission`.

```lua
trigger.action.stopRadioTransmission("beacon")
```

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

## trigger.action.effectSmokeStop

```lua
nil trigger.action.effectSmokeStop(string name)
```

The `trigger.action.effectSmokeStop` function stops a smoke effect created by `effectSmokeBig`.[^smoke]

**Parameters:**

- `name` (string): The name passed to `effectSmokeBig`.

```lua
trigger.action.effectSmokeStop("crash_smoke_1")
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

## trigger.action.ctfColorTag

```lua
nil trigger.action.ctfColorTag(string unitName, number smokeColor, number altitude)
```

The `trigger.action.ctfColorTag` function turns on a colored smoke trail behind an aircraft. Calling it again on the same unit with a different color changes the color.[^smoke]

**Parameters:**

- `unitName` (string): The unit name.
- `smokeColor` (number): 0 disables the trail. 1 Green, 2 Red, 3 White, 4 Orange, 5 Blue. These are the `trigger.smokeColor` values plus 1.
- `altitude` (number): Optional. The altitude in meters above which the trail is on. Below it the trail stops, and it restarts when the aircraft climbs back above it.

```lua
trigger.action.ctfColorTag("Display Lead", trigger.smokeColor.Red + 1)
```

## trigger.action.explosion

```lua
nil trigger.action.explosion(Vec3 position, number power)
```

The `trigger.action.explosion` function creates an explosion at the specified position. Values above 1000 can hurt performance.

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

In multiplayer, players see drawings for coalition -1 and their own coalition. In single player with no aircraft selected, players also see drawings for coalition 0.[^drawings]

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

```lua
trigger.action.circleToAll(-1, 1002, {x = -280000, y = 0, z = 650000}, 1500, {1, 0, 0, 1}, {1, 0, 0, 0.15}, 2, true, "")
```

## trigger.action.lineToAll

```lua
nil trigger.action.lineToAll(number coalitionId, number id, Vec3 startPoint, Vec3 endPoint, table color, number lineType, boolean readOnly, string message)
```

The `trigger.action.lineToAll` function draws a line between two points on the F10 map.[^drawings]

**Parameters:**

- `coalitionId` (number): The coalition that can see the line, from `coalition.side`, or -1 for all coalitions.
- `id` (number): A unique ID, shared with marks.
- `startPoint` (Vec3): The world position of one end.
- `endPoint` (Vec3): The world position of the other end.
- `color` (table): The line color as `{r, g, b, a}`, each 0 to 1.
- `lineType` (number): The line type, using the same values as `circleToAll`.
- `readOnly` (boolean): Optional. If true, players cannot edit or delete the line.
- `message` (string): Optional. Text for an on-screen message box shown when the line is added.

```lua
trigger.action.lineToAll(-1, 1010, {x = -280000, y = 0, z = 650000}, {x = -270000, y = 0, z = 660000}, {0, 0, 1, 1}, 1, true, "")
```

## trigger.action.rectToAll

```lua
nil trigger.action.rectToAll(number coalitionId, number id, Vec3 startPoint, Vec3 endPoint, table color, table fillColor, number lineType, boolean readOnly, string message)
```

The `trigger.action.rectToAll` function draws a rectangle on the F10 map. `startPoint` and `endPoint` are opposite corners.[^drawings]

**Parameters:** The same as `lineToAll`, plus `fillColor` (table) after `color`.

```lua
trigger.action.rectToAll(-1, 1011, {x = -280000, y = 0, z = 650000}, {x = -275000, y = 0, z = 655000}, {1, 1, 0, 1}, {1, 1, 0, 0.1}, 1, true, "")
```

## trigger.action.quadToAll

```lua
nil trigger.action.quadToAll(number coalitionId, number id, Vec3 point1, Vec3 point2, Vec3 point3, Vec3 point4, table color, table fillColor, number lineType, boolean readOnly, string message)
```

The `trigger.action.quadToAll` function draws a quadrilateral with the given corners on the F10 map.[^drawings]

**Parameters:** The same as `rectToAll`, with four corner points in place of `startPoint` and `endPoint`.

## trigger.action.arrowToAll

```lua
nil trigger.action.arrowToAll(number coalitionId, number id, Vec3 startPoint, Vec3 endPoint, table color, table fillColor, number lineType, boolean readOnly, string message)
```

The `trigger.action.arrowToAll` function draws an arrow on the F10 map. The arrowhead is at `startPoint`. The width and head size are fixed.[^drawings]

**Parameters:** The same as `rectToAll`.

```lua
-- Arrow pointing from the staging area toward the target
local target = {x = -280000, y = 0, z = 650000}
local staging = {x = -290000, y = 0, z = 640000}
trigger.action.arrowToAll(-1, 1012, target, staging, {1, 0, 0, 1}, {1, 0, 0, 0.5}, 1, true, "")
```

## trigger.action.textToAll

```lua
nil trigger.action.textToAll(number coalitionId, number id, Vec3 point, table color, table fillColor, number fontSize, boolean readOnly, string text)
```

The `trigger.action.textToAll` function draws text on the F10 map. The text scales with the map zoom.[^drawings]

**Parameters:**

- `coalitionId` (number): The coalition that can see the text, from `coalition.side`, or -1 for all coalitions.
- `id` (number): A unique ID, shared with marks.
- `point` (Vec3): The world position of the text.
- `color` (table): The text color as `{r, g, b, a}`, each 0 to 1.
- `fillColor` (table): The color of the box behind the text. Use alpha 0 for no box.
- `fontSize` (number): The font size.
- `readOnly` (boolean): If true, players cannot edit or delete the text.
- `text` (string): The text to show. Unlike the other drawing functions, the last argument is map text, not a message box.

```lua
trigger.action.textToAll(-1, 1013, {x = -280000, y = 0, z = 650000}, {1, 1, 1, 1}, {0, 0, 0, 0.5}, 18, true, "OBJECTIVE ALPHA")
```

## trigger.action.markupToAll

```lua
nil trigger.action.markupToAll(number shapeId, number coalitionId, number id, Vec3 point1, ... , table color, table fillColor, number lineType, boolean readOnly, string message)
```

The `trigger.action.markupToAll` function draws any type of F10 map drawing. `shapeId` selects the type, and the remaining arguments follow that type's function. It is the only function that draws a freeform polygon.[^drawings]

**Parameters:**

- `shapeId` (number): 1 Line, 2 Circle, 3 Rect, 4 Arrow, 5 Text, 6 Quad, 7 Freeform.
- `coalitionId` (number): The coalition that can see the drawing, from `coalition.side`, or -1 for all coalitions.
- `id` (number): A unique ID, shared with marks.
- `point1, ...` (Vec3): The drawing's points. A freeform drawing takes three or more points.
- `color`, `fillColor`, `lineType`, `readOnly`, `message`: As in `rectToAll`.

```lua
-- Freeform polygon from the corners of a quad-point trigger zone
local zone = trigger.misc.getZone("Restricted Area")
local v = zone.verticies
trigger.action.markupToAll(7, -1, 1014, v[1], v[2], v[3], v[4], {1, 0, 0, 1}, {1, 0, 0, 0.2}, 2, true, "")
```

A call written out in code has a fixed number of arguments. When the number of points varies, build the argument list in a table and pass it with `unpack`:

```lua
local args = {7, -1, 1015}
for _, p in ipairs(points) do
    table.insert(args, p)
end
table.insert(args, {1, 0, 0, 1})
table.insert(args, {1, 0, 0, 0.2})
table.insert(args, 2)
table.insert(args, true)
table.insert(args, "")
trigger.action.markupToAll(unpack(args))
```

## Updating Drawings

These functions change a drawing in place. Each takes the drawing's `id` first. A function that does not apply to the drawing (such as `setMarkupRadius` on a line) does nothing.[^markup]

| Function                                           | Changes                                                       |
| -------------------------------------------------- | ------------------------------------------------------------- |
| `trigger.action.setMarkupRadius(id, radius)`       | Radius of a circle, in meters                                 |
| `trigger.action.setMarkupText(id, text)`           | Text of a text drawing                                        |
| `trigger.action.setMarkupFontSize(id, fontSize)`   | Font size of a text drawing                                   |
| `trigger.action.setMarkupColor(id, color)`         | Outline or text color, `{r, g, b, a}`                         |
| `trigger.action.setMarkupColorFill(id, fillColor)` | Fill color, `{r, g, b, a}`                                    |
| `trigger.action.setMarkupTypeLine(id, lineType)`   | Line type. Not synced to multiplayer clients as of DCS 2.7.0. |
| `trigger.action.setMarkupPositionStart(id, point)` | First point of the drawing                                    |
| `trigger.action.setMarkupPositionEnd(id, point)`   | Last point of the drawing                                     |

```lua
-- Shrink a threat ring and move it to the SAM's current position
trigger.action.setMarkupRadius(1002, 800)
trigger.action.setMarkupPositionStart(1002, Unit.getByName("SA-15"):getPoint())
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

The `point` field is the center position of the zone. The `radius` field is the zone radius in meters.

For polygon zones (quad-point zones), the returned table contains:

```lua
{
    point = Vec3,
    verticies = {Vec3, ...}
}
```

The `point` field is the center position of the zone. The `verticies` field (misspelled in the API) is an array of Vec3 corner points.

Vertex order follows how the zone was drawn, so it may be clockwise or counter-clockwise. Geometry code that needs a specific orientation (such as triangulation) should check the signed area and reverse the points if needed.

```lua
local zone = trigger.misc.getZone("LandingZone")
if zone then
    local center = zone.point
    local radius = zone.radius
    env.info("Zone center: " .. center.x .. ", " .. center.z)
end
```

## trigger.action.setUnitInternalCargo

```lua
nil trigger.action.setUnitInternalCargo(string unitName, number mass)
```

The `trigger.action.setUnitInternalCargo` function sets a unit's internal cargo mass, replacing any previous value. It affects only airplanes and helicopters. For example, use it to add the mass of troops on board.[^cargo]

**Parameters:**

- `unitName` (string): The unit name.
- `mass` (number): The cargo mass in kilograms.

```lua
-- Eight troops at about 100 kg each
trigger.action.setUnitInternalCargo("Transport 1", 800)
```

## trigger.action.setAITask

```lua
nil trigger.action.setAITask(Group group, number taskIndex)
```

The `trigger.action.setAITask` function makes one of a group's Triggered Actions its only active task. Triggered Actions are tasks defined on the group in the Mission Editor and stored in the group's `tasks` table in the mission file.[^aitask]

**Parameters:**

- `group` (Group): The group.
- `taskIndex` (number): The index of the task in the group's Triggered Actions list.

To give a group a task built in Lua, use `controller:setTask` instead; see [controller](../classes/controller.md).

## trigger.action.pushAITask

```lua
nil trigger.action.pushAITask(Group group, number taskIndex)
```

The `trigger.action.pushAITask` function puts one of a group's Triggered Actions at the front of its task queue. The group returns to its previous task when the pushed task ends.[^aitask]

**Parameters:**

- `group` (Group): The group.
- `taskIndex` (number): The index of the task in the group's Triggered Actions list.

To push a task built in Lua, use `controller:pushTask`.

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

If `flagValue` is omitted, the `addOtherCommand*` functions set the flag to `true`. `deactivateGroup` destroys the group; it cannot be activated again.

## See Also

- [Coordinate Types](../types/coordinates.md) - Vec3 and coordinate systems
- [coalition](coalition.md) - Coalition identifiers
- [group](../classes/group.md) - Group objects and IDs
- [unit](../classes/unit.md) - Unit objects and IDs
- [controller](../classes/controller.md) - Setting AI tasks from Lua
- [MIZ File Format](../../../mission/miz-file-format.md) - Where sound files go in the archive

[^markers]: Hoggit Wiki, [DCS func markToAll](https://wiki.hoggitworld.com/view/DCS_func_markToAll), [DCS func markToCoalition](https://wiki.hoggitworld.com/view/DCS_func_markToCoalition), [DCS func markToGroup](https://wiki.hoggitworld.com/view/DCS_func_markToGroup), [DCS func circleToAll](https://wiki.hoggitworld.com/view/DCS_func_circleToAll), and [DCS func removeMark](https://wiki.hoggitworld.com/view/DCS_func_removeMark).

[^text]: Hoggit Wiki, [DCS func outTextForCountry](https://wiki.hoggitworld.com/view/DCS_func_outTextForCountry).

[^sound]: Hoggit Wiki, [DCS func outSound](https://wiki.hoggitworld.com/view/DCS_func_outSound), [outSoundForCoalition](https://wiki.hoggitworld.com/view/DCS_func_outSoundForCoalition), [outSoundForCountry](https://wiki.hoggitworld.com/view/DCS_func_outSoundForCountry), [outSoundForGroup](https://wiki.hoggitworld.com/view/DCS_func_outSoundForGroup), and [outSoundForUnit](https://wiki.hoggitworld.com/view/DCS_func_outSoundForUnit).

[^radio]: Hoggit Wiki, [DCS func radioTransmission](https://wiki.hoggitworld.com/view/DCS_func_radioTransmission) and [DCS func stopRadioTransmission](https://wiki.hoggitworld.com/view/DCS_func_stopRadioTransmission).

[^smoke]: Hoggit Wiki, [DCS func effectSmokeStop](https://wiki.hoggitworld.com/view/DCS_func_effectSmokeStop) and [DCS func ctfColorTag](https://wiki.hoggitworld.com/view/DCS_func_ctfColorTag).

[^drawings]: Hoggit Wiki, [DCS func lineToAll](https://wiki.hoggitworld.com/view/DCS_func_lineToAll), [rectToAll](https://wiki.hoggitworld.com/view/DCS_func_rectToAll), [quadToAll](https://wiki.hoggitworld.com/view/DCS_func_quadToAll), [arrowToAll](https://wiki.hoggitworld.com/view/DCS_func_arrowToAll), [textToAll](https://wiki.hoggitworld.com/view/DCS_func_textToAll), and [markupToAll](https://wiki.hoggitworld.com/view/DCS_func_markupToAll).

[^markup]: Hoggit Wiki, [DCS func setMarkupRadius](https://wiki.hoggitworld.com/view/DCS_func_setMarkupRadius) and the other `setMarkup` function pages linked from [DCS singleton trigger](https://wiki.hoggitworld.com/view/DCS_singleton_trigger).

[^cargo]: Hoggit Wiki, [DCS func setUnitInternalCargo](https://wiki.hoggitworld.com/view/DCS_func_setUnitInternalCargo).

[^aitask]: Hoggit Wiki, [DCS func setAITask](https://wiki.hoggitworld.com/view/DCS_func_setAITask) and [DCS func pushAITask](https://wiki.hoggitworld.com/view/DCS_func_pushAITask).
