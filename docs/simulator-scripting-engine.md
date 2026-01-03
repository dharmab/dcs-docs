# Simulator Scripting Engine

The Simulator Scripting Engine (SSE) provides mission designers with programmatic access to the DCS World simulation. Through Lua scripting, mission builders can monitor and control nearly every aspect of a running mission, from spawning units dynamically to tracking combat statistics to creating sophisticated campaign logic that would be impossible with the Mission Editor's trigger system alone.

## Overview

The SSE exposes the games's internal data and state through Lua, a lightweight programming language designed for embedding in applications. Scripts can read information about the game world and modify it. Scripts can do things like dynamically spawn units based on player actions or game state, execute conditions and event handlers more complex than can be done through Triggers alone, and add custom menus and submenus to the F10 radio menu.

## Lua Basics

This section covers just enough Lua to start writing mission scripts. Lua is a small language that you can learn as you go; most of its features are intuitive once you see them in action.

### Variables and Basic Types

Variables store values. Use `local` to declare a variable, which limits its visibility to the current scope. Variables without `local` become global and can accidentally interfere with other scripts.

```lua
local callsign = "Viper 1-1"        -- a string (text)
local altitude = 25000              -- a number
local isAlive = true                -- a boolean (true or false)
local target = nil                  -- nil means "no value" or "nothing"
```

Lua does not distinguish between integers and floating-point numbers; everything is just a number. Strings can use single or double quotes interchangeably.

### Tables

Tables are Lua's only data structure, but they are versatile enough to serve as arrays, dictionaries, objects, and more.

As an array (ordered list of values):

```lua
local waypoints = {"Alpha", "Bravo", "Charlie"}
local first = waypoints[1]   -- "Alpha" (Lua arrays start at index 1, not 0)
local count = #waypoints     -- 3 (the # operator gives the length)
```

As a dictionary (key-value pairs):

```lua
local aircraft = {
    callsign = "Cowboy 1",
    fuel = 0.75,
    altitude = 15000
}
local name = aircraft.callsign       -- "Cowboy 1"
```

Dot notation works when keys are simple identifiers. For keys with spaces, special characters, or keys stored in variables, use bracket notation with a quoted string:

```lua
local unit = {
    ["unit name"] = "SA-10",         -- key with a space
    ["type-id"] = 42,                -- key with a hyphen
}
local description = unit["unit name"]    -- bracket access required
```

You can also use brackets with a variable to access keys dynamically:

```lua
local key = "fuel"
local value = aircraft[key]   -- same as aircraft.fuel
```

You can add and modify entries at any time:

```lua
aircraft.speed = 450          -- adds a new key
aircraft.fuel = 0.50          -- updates existing value
```

### Control Structures

Conditional execution uses `if`, `then`, `else`, and `end`:

```lua
local fuel = unit:getFuel()

if fuel < 0.2 then
    trigger.action.outText("Bingo fuel!", 10)
elseif fuel < 0.5 then
    trigger.action.outText("Fuel state is low", 10)
else
    trigger.action.outText("Fuel state is good", 10)
end
```

The `elseif` and `else` branches are optional.

Lua's boolean logic uses `and`, `or`, and `not` (not `&&`, `||`, `!`):

```lua
if isAlive and altitude > 1000 then
    -- both conditions must be true
end

if isDamaged or fuel < 0.1 then
    -- either condition can be true
end

if not isDestroyed then
    -- true when isDestroyed is false
end
```

### Loops

A `for` loop can iterate over a range of numbers:

```lua
for i = 1, 10 do
    trigger.action.outText("Count: " .. i, 1)
end
```

The `pairs` function iterates over table keys and values:

```lua
local scores = {red = 5, blue = 3}
for side, points in pairs(scores) do
    trigger.action.outText(side .. " has " .. points .. " points", 5)
end
```

The `ipairs` function iterates over array elements in order:

```lua
local targets = {"SAM Site", "Radar", "Command Post"}
for index, name in ipairs(targets) do
    trigger.action.outText("Target " .. index .. ": " .. name, 5)
end
```

A `while` loop repeats as long as a condition remains true:

```lua
local attempts = 0
while attempts < 3 do
    attempts = attempts + 1
    -- do something
end
```

Use `break` to exit a loop early.

### Functions

Functions are defined with the `function` keyword and called by name with parentheses:

```lua
local function calculateDistance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

local distance = calculateDistance(0, 0, 100, 100)
```

Functions can return multiple values:

```lua
local function getPosition()
    return 100, 200, 5000   -- x, y, altitude
end

local x, y, alt = getPosition()
```

### String Concatenation

Join strings with the `..` operator:

```lua
local message = "Unit " .. unitName .. " destroyed at " .. time .. " seconds"
```

Convert numbers to strings automatically through concatenation, or explicitly with `tostring()`.

### Comments

Single-line comments start with two dashes:

```lua
-- This is a comment
local x = 10  -- comments can follow code
```

Multi-line comments use bracket notation:

```lua
--[[
    This is a multi-line comment.
    It can span several lines.
]]
```

### Nil and Truthiness

In Lua, `nil` represents the absence of a value. Variables that have not been assigned are `nil`. Functions that do not explicitly return a value return `nil`.

When evaluating conditions, `nil` and `false` are considered false; everything else (including zero and empty strings) is considered true:

```lua
local unit = Unit.getByName("Bandit 1")
if unit then
    -- unit exists (is not nil)
else
    -- unit is nil (not found or destroyed)
end
```

This pattern appears constantly in DCS scripting because functions like `getByName` return `nil` when objects do not exist.

## Scripting Concepts

### Singletons

A singleton is a global object that provides access to a category of game functionality. You access singletons by their name, then call functions on them. For example, `timer.getTime()` calls the `getTime` function on the `timer` singleton.

The main singletons are:

| Singleton | Purpose |
|-----------|---------|
| `env` | Logging and environment information |
| `timer` | Mission time and scheduled functions |
| `land` | Terrain queries (ground height, surface type) |
| `atmosphere` | Weather conditions |
| `world` | Event handlers and object searches |
| `coalition` | Operations related to the red and blue sides |
| `trigger` | Trigger zones and trigger-style actions like messages |
| `coord` | Coordinate conversions (lat/long to game coordinates) |
| `missionCommands` | F10 radio menu manipulation |

### Objects and Functions

The game world contains objects: aircraft, ground units, ships, airbases, weapons, and scenery. Scripts can get references to these objects and then call functions on them to get information or make changes.

For example, to get a unit and check its remaining fuel:

```lua
-- Get a reference to a unit named "Eagle 1-1"
local myUnit = Unit.getByName("Eagle 1-1")

-- Check if the unit exists (it might have been destroyed)
if myUnit then
    -- Get the fuel level as a percentage (0.0 to 1.0)
    local fuelPercent = myUnit:getFuel()
    -- Convert to percentage for display
    trigger.action.outText("Fuel: " .. math.floor(fuelPercent * 100) .. "%", 5)
end
```

Note the colon (`:`) when calling functions on objects: `myUnit:getFuel()`. This is Lua syntax for calling a function that belongs to an object. The singleton functions use a dot (`.`) instead: `timer.getTime()`.

Common object types and some of their functions:

**Unit** (aircraft, vehicles, ships)
- `getName()` - Get the unit's name
- `getPosition()` - Get location and orientation
- `getLife()` - Get remaining hit points
- `getFuel()` - Get fuel level (0.0 to 1.0)
- `getAmmo()` - Get ammunition counts
- `getVelocity()` - Get speed and direction of movement
- `inAir()` - Check if an aircraft is flying

**Group** (collection of units)
- `getName()` - Get the group's name
- `getUnits()` - Get a list of all units in the group
- `getSize()` - Get how many units are in the group
- `activate()` - Activate a late-activation group

**Airbase** (airports, FARPs, carriers)
- `getName()` - Get the airbase name
- `getCallsign()` - Get the radio callsign
- `getParking()` - Get parking spot information

### Events

The event system notifies your scripts when things happen in the simulation. You create an event handler and register it with the game, then your handler function gets called whenever events occur.

```lua
-- Create a table to serve as our event handler
local myHandler = {}

-- Define what happens when an event occurs
function myHandler:onEvent(event)
    -- Check if this is a unit being destroyed
    if event.id == world.event.S_EVENT_DEAD then
        local deadUnit = event.initiator
        if deadUnit then
            trigger.action.outText(deadUnit:getName() .. " was destroyed!", 10)
        end
    end
end

-- Register our handler to receive events
world.addEventHandler(myHandler)
```

Common events include:

| Event | When it fires |
|-------|---------------|
| `S_EVENT_SHOT` | A weapon is fired |
| `S_EVENT_HIT` | An object is struck by a weapon |
| `S_EVENT_TAKEOFF` | An aircraft departs |
| `S_EVENT_LAND` | An aircraft lands |
| `S_EVENT_CRASH` | An aircraft crashes |
| `S_EVENT_EJECTION` | A pilot ejects |
| `S_EVENT_DEAD` | An object is destroyed |
| `S_EVENT_BIRTH` | A unit spawns |
| `S_EVENT_PLAYER_ENTER_UNIT` | A player takes control of a unit |
| `S_EVENT_KILL` | One unit kills another |
| `S_EVENT_MARK_ADDED` | A map marker is created |

The event table passed to your handler contains different information depending on the event type. Most events include `id` (which event occurred), `time` (mission time), and `initiator` (the object involved).

### Scheduled Functions

You can tell the game to run a function at a specific time in the future. This is useful for periodic checks, delayed actions, or creating repeating behaviors.

```lua
local function showTimeMessage()
    local missionTime = timer.getTime()
    trigger.action.outText("Mission time: " .. math.floor(missionTime) .. " seconds", 5)

    -- Return a time to run this function again
    -- If we return nil instead, the function stops repeating
    return timer.getTime() + 60  -- Run again in 60 seconds
end

-- Schedule the first run 10 seconds from now
timer.scheduleFunction(showTimeMessage, nil, timer.getTime() + 10)
```

The scheduled function can return a number to reschedule itself at that mission time, or return nothing (nil) to stop running.

## Adding Scripts to Missions

Scripts can be embedded in missions through several mechanisms in the Mission Editor:

<!-- TODO: This section needs improvement. Add:
     1. Specific UI location (where exactly is the initialization slot in the Triggers panel?)
     2. Step-by-step instructions for adding an initialization script -->

### Initialization Script

The initialization script runs as the mission loads, before any units spawn or triggers evaluate. It is the earliest point at which scripting code executes. Access this through the Triggers panel by selecting the initialization slot.

Use the initialization script to set up global variables, define functions that will be used later, or configure settings that need to be in place before the mission begins.

### Trigger Actions

The trigger system provides two actions for running scripts:

**Do Script** embeds Lua code directly in the mission file. You type or paste your code into a text box, and it becomes part of the mission data. This approach has significant drawbacks: the text box has size limitations, no syntax highlighting, and the code becomes embedded inside the mission's Lua data structure where external tools cannot easily work with it.

**Do Script File** references a separate Lua file. When you select a file, the Mission Editor copies it into the mission archive. This approach is strongly preferred for new missions because it keeps your code in standalone `.lua` files. Code editors provide syntax highlighting, autocompletion, and error detection. Language servers can analyze your code for problems. Autoformatters like StyLua can keep your code consistently styled. AI coding assistants can read and modify your scripts. None of these tools can easily help you with code embedded via Do Script.

New missions should use Do Script File exclusively. Reserve Do Script only for trivial one-liners where creating a separate file would be overkill.

Both actions execute the script when their trigger conditions become true. The code runs once per trigger activation. Triggers may activate either once or repeatedly depending on how they are configured in the Mission Editor.

### Group Actions

Scripts can be attached to individual groups through waypoint actions and triggered actions. These scripts run in the context of that specific group.

Within a group action script, a special variable written as `...` (three dots) refers to the group the script is attached to. You can use this to write generic scripts that work with any group:

```lua
-- Within a group action, ... refers to the current group
local thisGroup = ...
local groupName = thisGroup:getName()
trigger.action.outText("Group " .. groupName .. " is doing something", 10)
```

This feature lets you write one script and attach it to multiple groups without having to change the group name in the code each time.

### Group Spawn Condition

Each group can have a spawn condition script that runs during mission loading. This script must return either `true` or `false` to determine whether the group spawns into the mission.

```lua
-- 50% chance to spawn this group
return math.random() < 0.5
```

If the script returns `true`, the group spawns normally. If it returns `false`, the group does not appear in the mission at all.

### LUA Predicate Condition

Triggers can use the LUA PREDICATE condition type to evaluate custom Lua code. The script must return `true` or `false`. This enables complex conditions that the built-in trigger conditions cannot express:

```lua
-- Check if a group named 'reinforcements' exists
if Group.getByName('reinforcements') then
    return true
else
    return false
end
```

One important limitation: the built-in trigger conditions (like GROUP ALIVE) only recognize groups placed in the Mission Editor. If you spawn groups dynamically through scripting, you must use LUA PREDICATE conditions to check their state.

## Script Execution Order

Understanding when scripts execute is critical when scripts depend on each other. For example, if script B uses a function defined in script A, script A must run first.

The execution order is:

1. **Initialization Script** - Runs first as the mission loads
2. **Group Spawn Conditions** - Evaluate during mission loading
3. **MISSION START Triggers** - Execute at mission start
4. **Waypoint 1 Scripts** - Execute as groups spawn at their first waypoints
5. **TIME LESS Triggers** - Triggers that are already true at mission start
6. **TIME MORE Triggers** - Triggers that become true after time elapses
7. **Waypoint 2+ Scripts** - Execute as groups reach subsequent waypoints

Within a single trigger, conditions and actions evaluate top to bottom in the order they appear in the editor. If trigger A is above trigger B in the trigger list and both execute at the same time, trigger A runs first.

This ordering allows a single trigger to load multiple dependent scripts in sequence:

```
Once > Time More than 3 > Do Script File(A.lua) AND Do Script File(B.lua) AND Do Script File(C.lua)
```

If script C depends on B and B depends on A, this trigger correctly loads them in order because actions execute left to right.

## MIZ File Storage

Understanding how scripts are stored in mission files helps when troubleshooting or when you want to update scripts without opening the Mission Editor.

MIZ files are ZIP archives that you can open with any archive utility. When you use **Do Script**, your code is embedded directly in the `mission` file as text within the trigger data.

When you use **Do Script File**, the Lua file is:
1. Copied into the `l10n/DEFAULT` directory inside the archive
2. Registered in the `l10n/DEFAULT/mapResource` file
3. Referenced by the trigger action

This means you can extract a MIZ file with a tool like 7-Zip, edit the Lua files in a text editor, and repack it to update your mission logic without opening the Mission Editor.

## Debugging

When scripts do not work as expected, logging helps you understand what is happening. The `env` singleton provides logging functions:

```lua
env.info("This is an information message")
env.warning("This is a warning")
env.error("This is an error")
```

These messages appear in `dcs.log` in your DCS Saved Games directory (typically `C:\Users\[YourName]\Saved Games\DCS` or `DCS.openbeta`). Open this file in a text editor to see your messages along with any errors the game encountered.

You can also display messages in-game for quick feedback while developing:

```lua
trigger.action.outText("Debug: reached this point in the code", 5)
```

The number at the end (5) is how many seconds the message stays on screen.

## Further Reading

The DCS scripting engine has hundreds of functions covering nearly every aspect of the simulation. The Hoggit Wiki maintains community documentation with examples for most functions. Search for "hoggit wiki scripting" to find detailed reference material for specific functions and features.

## API Reference

This section provides comprehensive documentation of all DCS scripting engine functions, classes, and data structures.

### Data Types and Conventions

#### Coordinate Systems

DCS World uses a right-handed coordinate system where the origin varies by map. All positions are measured in meters.

**Vec2** represents a 2D point on the map surface:

```lua
Vec2 = {
    x = number,  -- East-West position (positive = East)
    y = number   -- North-South position (positive = North)
}
```

**Vec3** represents a 3D point in world space:

```lua
Vec3 = {
    x = number,  -- East-West position (positive = East)
    y = number,  -- Altitude (positive = up)
    z = number   -- North-South position (positive = North)
}
```

Note that Vec2 and Vec3 use different conventions for the "y" axis. In Vec2, `y` is the North-South position. In Vec3, `y` is altitude while `z` is North-South. This is a common source of confusion when converting between the two formats.

**Position3** represents both position and orientation in 3D space:

```lua
Position3 = {
    p = Vec3,  -- World position
    x = Vec3,  -- Forward unit vector (out the nose)
    y = Vec3,  -- Up unit vector (out the top)
    z = Vec3   -- Right unit vector (out the right side)
}
```

The orientation vectors form an orthonormal basis. You can calculate heading and pitch from Position3:

```lua
local pos = unit:getPosition()
local heading = math.atan2(pos.x.z, pos.x.x)  -- radians, 0 = North
local pitch = math.asin(pos.x.y)              -- radians, positive = nose up
```

#### Time Values

Mission time is measured in seconds as a floating-point number with millisecond precision. The timer singleton provides time-related functions:

- `timer.getTime()` returns mission time (seconds since mission start, pauses when game is paused)
- `timer.getAbsTime()` returns absolute time (seconds since midnight of the mission date)
- `timer.getTime0()` returns the mission start time as absolute time

#### Distance and Angles

All distances are in meters. All angles are in radians unless otherwise noted. To convert:

```lua
local radians = degrees * math.pi / 180
local degrees = radians * 180 / math.pi
```

Headings use true north as 0, increasing clockwise (East = π/2, South = π, West = 3π/2).

#### Country and Coalition

Countries are identified by numeric IDs from the `country.id` enum. Coalition membership is determined by the country. The three coalitions are:

```lua
coalition.side = {
    NEUTRAL = 0,
    RED = 1,
    BLUE = 2
}
```

A value of -1 represents "all coalitions" in some functions like `markupToAll`.

### Singletons

Singletons are global objects that provide access to game systems. You call their functions using dot notation (e.g., `timer.getTime()`).

#### timer

The timer singleton provides mission time information and function scheduling.

##### timer.getTime

```lua
number timer.getTime()
```

Returns the mission time in seconds since the mission started. This value pauses when the simulation is paused. Precision is to three decimal places.

**Returns:** Mission time in seconds (e.g., `65.385`).

```lua
-- Check if 5 minutes have elapsed
if timer.getTime() > 300 then
    startSecondWave()
end
```

##### timer.getAbsTime

```lua
number timer.getAbsTime()
```

Returns the time of day as seconds since midnight on the mission date. Unlike `getTime()`, this includes the mission start time offset.

**Returns:** Absolute time in seconds since midnight.

```lua
-- Check if it's past noon (12:00)
if timer.getAbsTime() > 43200 then
    env.info("It's afternoon")
end
```

##### timer.getTime0

```lua
number timer.getTime0()
```

Returns the mission's start time as seconds since midnight. This represents the "start time" configured in the Mission Editor.

**Returns:** Mission start time as absolute time.

```lua
-- Calculate current time of day
local currentTimeOfDay = timer.getTime0() + timer.getTime()
local hours = math.floor(currentTimeOfDay / 3600) % 24
```

##### timer.scheduleFunction

```lua
functionId timer.scheduleFunction(function callback, any argument, number runTime)
```

Schedules a function to run at a specific mission time. The callback receives the provided argument and the scheduled time. If the callback returns a number, it will be rescheduled for that mission time.

**Parameters:**
- `callback` (function): The function to call. Signature: `function(argument, time)`.
- `argument` (any): Value passed to the callback. Use a table to pass multiple values.
- `runTime` (number): Mission time when the function should run.

**Returns:** A function ID that can be used with `removeFunction` or `setFunctionTime`.

**Gotchas:** If you schedule a function for a time that has already passed, it runs immediately on the next simulation frame.

```lua
-- Run a function every 30 seconds
local function periodicCheck(_, time)
    local aliveCount = countAliveUnits()
    env.info("Alive units: " .. aliveCount)
    return time + 30  -- Reschedule 30 seconds from now
end

timer.scheduleFunction(periodicCheck, nil, timer.getTime() + 30)
```

```lua
-- Run once after a delay, passing data
local function delayedMessage(data, time)
    trigger.action.outText(data.message, data.duration)
    -- Return nil to not reschedule
end

timer.scheduleFunction(delayedMessage, {message = "5 minutes elapsed!", duration = 10}, timer.getTime() + 300)
```

##### timer.removeFunction

```lua
nil timer.removeFunction(functionId id)
```

Removes a scheduled function so it will not run. Has no effect if the function has already run or was already removed.

**Parameters:**
- `id` (functionId): The ID returned by `scheduleFunction`.

```lua
local funcId = timer.scheduleFunction(myCallback, nil, timer.getTime() + 60)
-- Later, cancel it
timer.removeFunction(funcId)
```

##### timer.setFunctionTime

```lua
nil timer.setFunctionTime(functionId id, number newTime)
```

Changes when a scheduled function will run. Useful for delaying or advancing scheduled tasks.

**Parameters:**
- `id` (functionId): The ID returned by `scheduleFunction`.
- `newTime` (number): New mission time when the function should run.

```lua
local funcId = timer.scheduleFunction(myCallback, nil, timer.getTime() + 60)
-- Delay it by another 30 seconds
timer.setFunctionTime(funcId, timer.getTime() + 90)
```

#### env

The env singleton provides logging, mission information, and warning systems.

##### env.info

```lua
nil env.info(string message, boolean showMessageBox)
```

Logs an informational message to `dcs.log`. This is the primary debugging tool for mission scripts.

**Parameters:**
- `message` (string): The message to log.
- `showMessageBox` (boolean): Optional. If true, also displays a message box to the user. Default is false.

```lua
env.info("Script initialized successfully")
env.info("Player entered zone: " .. zoneName)
```

##### env.warning

```lua
nil env.warning(string message, boolean showMessageBox)
```

Logs a warning message to `dcs.log`. Use for recoverable issues.

**Parameters:**
- `message` (string): The warning message.
- `showMessageBox` (boolean): Optional. If true, displays a message box.

```lua
if not targetGroup then
    env.warning("Target group not found, using fallback")
end
```

##### env.error

```lua
nil env.error(string message, boolean showMessageBox)
```

Logs an error message to `dcs.log`. Use for serious problems that may affect mission functionality.

**Parameters:**
- `message` (string): The error message.
- `showMessageBox` (boolean): Optional. If true, displays a message box.

```lua
if not requiredUnit then
    env.error("Critical unit missing - mission may not function correctly")
end
```

##### env.setErrorMessageBoxEnabled

```lua
nil env.setErrorMessageBoxEnabled(boolean enabled)
```

Enables or disables the error message box that appears when script errors occur.

**Parameters:**
- `enabled` (boolean): True to show error dialogs, false to suppress them.

```lua
-- Disable error popups for production missions
env.setErrorMessageBoxEnabled(false)
```

##### env.getValueDictByKey

```lua
string env.getValueDictByKey(string key)
```

Returns a localized string from the mission's dictionary. Used for internationalization.

**Parameters:**
- `key` (string): The dictionary key.

**Returns:** The localized string value, or the key if not found.

##### env.mission

A table containing the complete mission data as loaded from the MIZ file. This includes all groups, units, triggers, and other mission elements in their raw format.

```lua
-- Access mission start time
local startTime = env.mission.start_time

-- Iterate through coalition groups
for coalitionName, coalitionData in pairs(env.mission.coalition) do
    env.info("Coalition: " .. coalitionName)
end
```

#### trigger

The trigger singleton provides access to trigger zones, user flags, and trigger-style actions like messages, smoke, and explosions. It is divided into two sub-tables: `trigger.action` for actions and `trigger.misc` for utilities.

##### trigger.action.outText

```lua
nil trigger.action.outText(string text, number displayTime, boolean clearView)
```

Displays a message to all players on screen.

**Parameters:**
- `text` (string): The message to display.
- `displayTime` (number): How long the message remains visible in seconds.
- `clearView` (boolean): Optional. If true, clears other messages first.

```lua
trigger.action.outText("Mission objective updated!", 10)
```

##### trigger.action.outTextForCoalition

```lua
nil trigger.action.outTextForCoalition(number coalitionId, string text, number displayTime, boolean clearView)
```

Displays a message only to players of a specific coalition.

**Parameters:**
- `coalitionId` (number): The coalition (0=neutral, 1=red, 2=blue).
- `text` (string): The message to display.
- `displayTime` (number): Display duration in seconds.
- `clearView` (boolean): Optional. If true, clears other messages first.

```lua
trigger.action.outTextForCoalition(coalition.side.BLUE, "Blue team: reinforcements inbound", 15)
```

##### trigger.action.outTextForGroup

```lua
nil trigger.action.outTextForGroup(number groupId, string text, number displayTime, boolean clearView)
```

Displays a message only to players in a specific group.

**Parameters:**
- `groupId` (number): The group's numeric ID.
- `text` (string): The message to display.
- `displayTime` (number): Display duration in seconds.
- `clearView` (boolean): Optional.

```lua
local group = Group.getByName("Player Flight")
if group then
    trigger.action.outTextForGroup(group:getID(), "Your target is marked with smoke", 10)
end
```

##### trigger.action.outTextForUnit

```lua
nil trigger.action.outTextForUnit(number unitId, string text, number displayTime, boolean clearView)
```

Displays a message only to a specific player unit.

**Parameters:**
- `unitId` (number): The unit's numeric ID.
- `text` (string): The message to display.
- `displayTime` (number): Display duration in seconds.
- `clearView` (boolean): Optional.

##### trigger.action.smoke

```lua
nil trigger.action.smoke(Vec3 position, number smokeColor)
```

Creates a smoke marker at the specified position.

**Parameters:**
- `position` (Vec3): World position for the smoke.
- `smokeColor` (number): Color from `trigger.smokeColor` enum (0=Green, 1=Red, 2=White, 3=Orange, 4=Blue).

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

##### trigger.action.effectSmokeBig

```lua
nil trigger.action.effectSmokeBig(Vec3 position, number smokeType, number density, string name)
```

Creates a large smoke effect at the specified position.

**Parameters:**
- `position` (Vec3): World position.
- `smokeType` (number): Type of smoke (1-3, larger numbers = more smoke).
- `density` (number): Smoke density (0.1 to 1.0).
- `name` (string): Unique identifier for this smoke effect.

```lua
local crashSite = {x = 100000, y = 0, z = 200000}
trigger.action.effectSmokeBig(crashSite, 2, 0.8, "crash_smoke_1")
```

##### trigger.action.illuminationBomb

```lua
nil trigger.action.illuminationBomb(Vec3 position, number power)
```

Creates an illumination flare at the specified position.

**Parameters:**
- `position` (Vec3): World position (altitude determines where the flare appears).
- `power` (number): Brightness of the illumination.

```lua
local flarePos = {x = 100000, y = 500, z = 200000}  -- 500m altitude
trigger.action.illuminationBomb(flarePos, 1000000)
```

##### trigger.action.signalFlare

```lua
nil trigger.action.signalFlare(Vec3 position, number flareColor, number azimuth)
```

Fires a signal flare from the specified position.

**Parameters:**
- `position` (Vec3): Launch position.
- `flareColor` (number): Color from `trigger.flareColor` enum (0=Green, 1=Red, 2=White, 3=Yellow).
- `azimuth` (number): Direction in radians.

```lua
trigger.flareColor = {
    Green = 0,
    Red = 1,
    White = 2,
    Yellow = 3
}
```

##### trigger.action.explosion

```lua
nil trigger.action.explosion(Vec3 position, number power)
```

Creates an explosion at the specified position.

**Parameters:**
- `position` (Vec3): World position.
- `power` (number): Explosion power (equivalent to kg of explosives).

**Gotchas:** Very large explosions can cause performance issues. Values above 1000 should be used carefully.

```lua
-- Create a small explosion
trigger.action.explosion({x = 100000, y = 100, z = 200000}, 100)
```

##### trigger.action.setUserFlag

```lua
nil trigger.action.setUserFlag(string flagName, number value)
```

Sets the value of a user flag. Flags are integer values that can be read by triggers or scripts.

**Parameters:**
- `flagName` (string): The flag name or number.
- `value` (number): The value to set.

```lua
trigger.action.setUserFlag("objective_complete", 1)
```

##### trigger.misc.getUserFlag

```lua
number trigger.misc.getUserFlag(string flagName)
```

Returns the current value of a user flag.

**Parameters:**
- `flagName` (string): The flag name or number.

**Returns:** The flag's value as a number.

```lua
if trigger.misc.getUserFlag("objective_complete") == 1 then
    spawnReinforcements()
end
```

##### trigger.misc.getZone

```lua
table trigger.misc.getZone(string zoneName)
```

Returns information about a trigger zone defined in the Mission Editor.

**Parameters:**
- `zoneName` (string): The name of the trigger zone.

**Returns:** A table with zone properties, or nil if the zone doesn't exist.

For circular zones:
```lua
{
    point = Vec3,    -- Center position
    radius = number  -- Radius in meters
}
```

For polygon zones (quad-point zones):
```lua
{
    point = Vec3,           -- Center position
    verticies = {Vec3, ...} -- Corner points (note the typo in the API)
}
```

**Gotchas:** The API uses "verticies" (misspelled) rather than "vertices".

```lua
local zone = trigger.misc.getZone("LandingZone")
if zone then
    local center = zone.point
    local radius = zone.radius
    env.info("Zone center: " .. center.x .. ", " .. center.z)
end
```

#### world

The world singleton provides event handling and object searching capabilities. See the Events section for event handling details.

##### world.addEventHandler

```lua
nil world.addEventHandler(table handler)
```

Registers an event handler to receive game events. The handler must be a table with an `onEvent` function.

**Parameters:**
- `handler` (table): A table containing an `onEvent(self, event)` function.

```lua
local myHandler = {}

function myHandler:onEvent(event)
    if event.id == world.event.S_EVENT_DEAD then
        local unit = event.initiator
        if unit then
            env.info(unit:getName() .. " was destroyed")
        end
    end
end

world.addEventHandler(myHandler)
```

##### world.removeEventHandler

```lua
nil world.removeEventHandler(table handler)
```

Unregisters a previously registered event handler.

**Parameters:**
- `handler` (table): The same handler table that was passed to `addEventHandler`.

##### world.getPlayer

```lua
Unit world.getPlayer()
```

Returns the player's unit in single-player missions.

**Returns:** The player's Unit object, or nil in multiplayer.

**Gotchas:** Only works in single-player. In multiplayer, use `coalition.getPlayers()` instead.

##### world.getAirbases

```lua
table world.getAirbases(number coalitionId)
```

Returns all airbases belonging to a coalition. This includes airports, FARPs, and carrier ships.

**Parameters:**
- `coalitionId` (number): Optional. If provided, returns only airbases for that coalition.

**Returns:** Array of Airbase objects.

```lua
local blueAirbases = world.getAirbases(coalition.side.BLUE)
for i, airbase in ipairs(blueAirbases) do
    env.info("Blue airbase: " .. airbase:getName())
end
```

##### world.searchObjects

```lua
nil world.searchObjects(number objectCategory, table searchVolume, function handler)
```

Searches for objects within a 3D volume and calls a handler for each one found.

**Parameters:**
- `objectCategory` (number): Category from `Object.Category` (UNIT, WEAPON, STATIC, BASE, SCENERY, CARGO).
- `searchVolume` (table): Defines the search area (sphere, box, or pyramid).
- `handler` (function): Called for each found object. Return true to continue searching, false to stop.

Volume types:
```lua
world.VolumeType = {
    SEGMENT = 0,
    BOX = 1,
    SPHERE = 2,
    PYRAMID = 3
}
```

```lua
-- Search for all units within 5km of a point
local searchVolume = {
    id = world.VolumeType.SPHERE,
    params = {
        point = {x = 100000, y = 0, z = 200000},
        radius = 5000
    }
}

local foundUnits = {}
world.searchObjects(Object.Category.UNIT, searchVolume, function(foundObject)
    table.insert(foundUnits, foundObject)
    return true  -- Continue searching
end)
```

##### world.removeJunk

```lua
number world.removeJunk(table searchVolume)
```

Removes debris and wreckage within a volume.

**Parameters:**
- `searchVolume` (table): The area to clear (same format as `searchObjects`).

**Returns:** The number of objects removed.

```lua
-- Clear debris around an airfield
local clearZone = {
    id = world.VolumeType.SPHERE,
    params = {
        point = airbase:getPoint(),
        radius = 2000
    }
}
local removed = world.removeJunk(clearZone)
env.info("Removed " .. removed .. " debris objects")
```

##### world.getMarkPanels

```lua
table world.getMarkPanels()
```

Returns all map markers currently visible.

**Returns:** Array of marker tables with fields: `idx` (marker ID), `time` (creation time), `initiator` (Unit that created it), `coalition` (-1 for all), `groupID` (-1 for all), `text`, `pos` (Vec3).

#### coalition

The coalition singleton provides functions to query and spawn groups and static objects.

##### coalition.addGroup

```lua
Group coalition.addGroup(number countryId, number groupCategory, table groupData)
```

Dynamically spawns a group into the mission. This is one of the most powerful scripting functions, enabling dynamic spawning of any unit type.

**Parameters:**
- `countryId` (number): Country ID from `country.id` enum.
- `groupCategory` (number): Category from `Group.Category` (AIRPLANE, HELICOPTER, GROUND, SHIP, TRAIN).
- `groupData` (table): Complete group definition (see below).

**Returns:** The spawned Group object.

**Gotchas:**
- You **MUST** add a delay before accessing the group's controller after spawning. Issuing tasks immediately can crash the game.
- If a group or unit name matches an existing object, the existing object is destroyed.
- Cannot spawn aircraft with skill "Client" but can use "Player" in single-player (destroys current player aircraft).
- FARPs are spawned with `groupCategory = -1`.

Group data structure:
```lua
groupData = {
    -- Required
    name = string,           -- Unique group name
    task = string,           -- Main task (e.g., "Ground Nothing", "CAP", "CAS")
    units = {                -- Array of unit definitions
        [1] = {
            name = string,   -- Unique unit name
            type = string,   -- Unit type (e.g., "M1A2", "F-16C_50")
            x = number,      -- East-West position
            y = number,      -- North-South position (Vec2 convention)
            -- Aircraft also require:
            alt = number,    -- Altitude in meters
            alt_type = string, -- "BARO" or "RADIO"
            speed = number,  -- Speed in m/s
            payload = table, -- Weapons and fuel
            callsign = table -- {[1]=name_index, [2]=number, [3]=flight_number}
        },
    },

    -- Optional
    groupId = number,        -- Custom group ID (auto-generated if omitted)
    start_time = number,     -- Spawn delay in seconds (0 = immediate)
    lateActivation = boolean, -- Require trigger to activate
    hidden = boolean,        -- Hide from F10 map
    hiddenOnMFD = boolean,   -- Hide from aircraft MFDs
    route = table,           -- Waypoints and tasks
    uncontrolled = boolean,  -- For aircraft: spawn inactive
}
```

```lua
-- Spawn a simple ground unit
local groupData = {
    name = "Reinforcement Tank",
    task = "Ground Nothing",
    units = {
        [1] = {
            name = "Tank 1",
            type = "M1A2",
            x = -288585,
            y = 616314,
            heading = 0,
            skill = "Average",
        },
    },
}

local newGroup = coalition.addGroup(country.id.USA, Group.Category.GROUND, groupData)

-- IMPORTANT: Wait before issuing commands
timer.scheduleFunction(function()
    local controller = newGroup:getController()
    -- Now safe to issue tasks
end, nil, timer.getTime() + 1)
```

##### coalition.addStaticObject

```lua
StaticObject coalition.addStaticObject(number countryId, table staticData)
```

Spawns a static object into the mission.

**Parameters:**
- `countryId` (number): Country ID from `country.id` enum.
- `staticData` (table): Static object definition.

**Returns:** The spawned StaticObject.

```lua
local staticData = {
    name = "Cargo Crate",
    type = "uh1h_cargo",
    x = -288000,
    y = 616000,
    heading = 0,
}

coalition.addStaticObject(country.id.USA, staticData)
```

##### coalition.getGroups

```lua
table coalition.getGroups(number coalitionId, number groupCategory)
```

Returns all groups belonging to a coalition.

**Parameters:**
- `coalitionId` (number): Coalition from `coalition.side`.
- `groupCategory` (number): Optional. Filter by `Group.Category`.

**Returns:** Array of Group objects.

```lua
local redAircraft = coalition.getGroups(coalition.side.RED, Group.Category.AIRPLANE)
for _, group in ipairs(redAircraft) do
    env.info("Red aircraft group: " .. group:getName())
end
```

##### coalition.getStaticObjects

```lua
table coalition.getStaticObjects(number coalitionId)
```

Returns all static objects belonging to a coalition.

**Parameters:**
- `coalitionId` (number): Coalition from `coalition.side`.

**Returns:** Array of StaticObject objects.

##### coalition.getPlayers

```lua
table coalition.getPlayers(number coalitionId)
```

Returns all human player units in a coalition.

**Parameters:**
- `coalitionId` (number): Coalition from `coalition.side`.

**Returns:** Array of Unit objects (only player-controlled units).

```lua
local bluePlayers = coalition.getPlayers(coalition.side.BLUE)
for _, player in ipairs(bluePlayers) do
    local name = player:getPlayerName()
    env.info("Blue player: " .. (name or "Unknown"))
end
```

##### coalition.getAirbases

```lua
table coalition.getAirbases(number coalitionId)
```

Returns all airbases belonging to a coalition.

**Parameters:**
- `coalitionId` (number): Coalition from `coalition.side`.

**Returns:** Array of Airbase objects.

##### coalition.getServiceProviders

```lua
table coalition.getServiceProviders(number coalitionId, number serviceType)
```

Returns groups providing a specific service.

**Parameters:**
- `coalitionId` (number): Coalition from `coalition.side`.
- `serviceType` (number): Service from `coalition.service` (ATC=0, AWACS=1, TANKER=2, FAC=3).

**Returns:** Array of Group objects providing that service.

```lua
local tankers = coalition.getServiceProviders(coalition.side.BLUE, coalition.service.TANKER)
```

##### coalition.addRefPoint

```lua
nil coalition.addRefPoint(number coalitionId, table refPoint)
```

Adds a reference point (bullseye or custom waypoint) for a coalition.

**Parameters:**
- `coalitionId` (number): Coalition from `coalition.side`.
- `refPoint` (table): Reference point with `callsign` (string) and `point` (Vec3).

##### coalition.getRefPoints

```lua
table coalition.getRefPoints(number coalitionId)
```

Returns all reference points for a coalition.

**Parameters:**
- `coalitionId` (number): Coalition from `coalition.side`.

**Returns:** Table of reference points indexed by callsign.

##### coalition.getMainRefPoint

```lua
Vec3 coalition.getMainRefPoint(number coalitionId)
```

Returns the main bullseye position for a coalition.

**Parameters:**
- `coalitionId` (number): Coalition from `coalition.side`.

**Returns:** Vec3 position of the bullseye.

```lua
local bullseye = coalition.getMainRefPoint(coalition.side.BLUE)
env.info("Blue bullseye at: " .. bullseye.x .. ", " .. bullseye.z)
```

##### coalition.getCountryCoalition

```lua
number coalition.getCountryCoalition(number countryId)
```

Returns which coalition a country belongs to.

**Parameters:**
- `countryId` (number): Country ID from `country.id`.

**Returns:** Coalition from `coalition.side`.

#### missionCommands

The missionCommands singleton allows you to add and remove entries in the F10 "Other" radio menu.

##### missionCommands.addCommand

```lua
table missionCommands.addCommand(string name, table path, function handler, any argument)
```

Adds a command to the F10 menu that all players can see and use.

**Parameters:**
- `name` (string): The menu item text.
- `path` (table): Parent menu path, or nil for the root menu.
- `handler` (function): Function called when the command is selected.
- `argument` (any): Value passed to the handler.

**Returns:** Path table identifying this command.

```lua
-- Add a command at the root level
missionCommands.addCommand("Request SITREP", nil, function()
    trigger.action.outText("All objectives intact", 10)
end)

-- Add a command in a submenu
local supportMenu = missionCommands.addSubMenu("Support", nil)
missionCommands.addCommand("Call Artillery", supportMenu, function()
    fireArtillery()
end)
```

##### missionCommands.addSubMenu

```lua
table missionCommands.addSubMenu(string name, table path)
```

Adds a submenu to the F10 menu.

**Parameters:**
- `name` (string): The submenu text.
- `path` (table): Parent menu path, or nil for the root menu.

**Returns:** Path table for this submenu (use as `path` for child items).

```lua
local mainMenu = missionCommands.addSubMenu("Mission Control", nil)
local airMenu = missionCommands.addSubMenu("Air Support", mainMenu)
missionCommands.addCommand("CAS Strike", airMenu, performCAS)
```

##### missionCommands.removeItem

```lua
nil missionCommands.removeItem(table path)
```

Removes a command or submenu from the F10 menu.

**Parameters:**
- `path` (table): The path returned by `addCommand` or `addSubMenu`.

##### missionCommands.addCommandForCoalition

```lua
table missionCommands.addCommandForCoalition(number coalitionId, string name, table path, function handler, any argument)
```

Adds a command visible only to a specific coalition.

**Parameters:**
- `coalitionId` (number): Coalition from `coalition.side`.
- `name`, `path`, `handler`, `argument`: Same as `addCommand`.

**Returns:** Path table for this command.

##### missionCommands.addSubMenuForCoalition

```lua
table missionCommands.addSubMenuForCoalition(number coalitionId, string name, table path)
```

Adds a submenu visible only to a specific coalition.

##### missionCommands.removeItemForCoalition

```lua
nil missionCommands.removeItemForCoalition(number coalitionId, table path)
```

Removes a coalition-specific menu item.

##### missionCommands.addCommandForGroup

```lua
table missionCommands.addCommandForGroup(number groupId, string name, table path, function handler, any argument)
```

Adds a command visible only to a specific group. This is the most common way to create player-specific menus.

**Parameters:**
- `groupId` (number): The group's numeric ID.
- `name`, `path`, `handler`, `argument`: Same as `addCommand`.

**Returns:** Path table for this command.

```lua
local function setupPlayerMenu(unit)
    local group = unit:getGroup()
    local groupId = group:getID()

    local menu = missionCommands.addSubMenuForGroup(groupId, "Player Actions", nil)
    missionCommands.addCommandForGroup(groupId, "Check Fuel", menu, function()
        local fuel = unit:getFuel() * 100
        trigger.action.outTextForGroup(groupId, "Fuel: " .. math.floor(fuel) .. "%", 5)
    end)
end
```

##### missionCommands.addSubMenuForGroup

```lua
table missionCommands.addSubMenuForGroup(number groupId, string name, table path)
```

Adds a submenu visible only to a specific group.

##### missionCommands.removeItemForGroup

```lua
nil missionCommands.removeItemForGroup(number groupId, table path)
```

Removes a group-specific menu item.

#### coord

The coord singleton provides coordinate conversion between the game's internal XYZ system, Latitude/Longitude, and MGRS.

##### coord.LLtoLO

```lua
number, number, number coord.LLtoLO(number latitude, number longitude, number altitude)
```

Converts Latitude/Longitude/Altitude to the game's XYZ coordinate system.

**Parameters:**
- `latitude` (number): Latitude in decimal degrees (positive = North).
- `longitude` (number): Longitude in decimal degrees (positive = East).
- `altitude` (number): Altitude in meters MSL.

**Returns:** x, y, z (game coordinates, where y is altitude).

```lua
local x, y, z = coord.LLtoLO(41.657, 41.597, 0)
local position = {x = x, y = y, z = z}
```

##### coord.LOtoLL

```lua
number, number, number coord.LOtoLL(number x, number y, number z)
```

Converts game XYZ coordinates to Latitude/Longitude/Altitude.

**Parameters:**
- `x` (number): X coordinate (East-West).
- `y` (number): Y coordinate (altitude).
- `z` (number): Z coordinate (North-South).

**Returns:** latitude, longitude, altitude.

```lua
local pos = unit:getPoint()
local lat, lon, alt = coord.LOtoLL(pos.x, pos.y, pos.z)
env.info(string.format("Position: %.4f, %.4f", lat, lon))
```

##### coord.LLtoMGRS

```lua
table coord.LLtoMGRS(number latitude, number longitude)
```

Converts Latitude/Longitude to MGRS (Military Grid Reference System).

**Parameters:**
- `latitude` (number): Latitude in decimal degrees.
- `longitude` (number): Longitude in decimal degrees.

**Returns:** MGRS table with fields: `UTMZone`, `MGRSDigraph`, `Easting`, `Northing`.

```lua
local mgrs = coord.LLtoMGRS(41.657, 41.597)
local mgrsString = mgrs.UTMZone .. mgrs.MGRSDigraph .. " " ..
                   string.format("%05d", mgrs.Easting) .. " " ..
                   string.format("%05d", mgrs.Northing)
```

##### coord.MGRStoLL

```lua
number, number coord.MGRStoLL(table mgrs)
```

Converts MGRS coordinates to Latitude/Longitude.

**Parameters:**
- `mgrs` (table): MGRS table with `UTMZone`, `MGRSDigraph`, `Easting`, `Northing`.

**Returns:** latitude, longitude.

#### land

The land singleton provides terrain information and pathfinding.

##### land.getHeight

```lua
number land.getHeight(Vec2 position)
```

Returns the terrain height at a position.

**Parameters:**
- `position` (Vec2): A table with x and y coordinates.

**Returns:** Height in meters above sea level.

```lua
local height = land.getHeight({x = 100000, y = 200000})
```

##### land.getSurfaceHeightWithSeabed

```lua
number land.getSurfaceHeightWithSeabed(Vec2 position)
```

Returns the height including the seabed (returns negative values for underwater terrain).

**Parameters:**
- `position` (Vec2): A table with x and y coordinates.

**Returns:** Height in meters (negative for seabed).

##### land.getSurfaceType

```lua
number land.getSurfaceType(Vec2 position)
```

Returns the surface type at a position.

**Parameters:**
- `position` (Vec2): A table with x and y coordinates.

**Returns:** Surface type enum value.

```lua
land.SurfaceType = {
    LAND = 1,
    SHALLOW_WATER = 2,
    WATER = 3,
    ROAD = 4,
    RUNWAY = 5  -- Also includes taxiways and ramps
}
```

```lua
local surface = land.getSurfaceType({x = pos.x, y = pos.z})
if surface == land.SurfaceType.WATER then
    env.info("Position is over water")
end
```

##### land.isVisible

```lua
boolean land.isVisible(Vec3 origin, Vec3 destination)
```

Checks if there is line-of-sight between two points (terrain only, ignores objects).

**Parameters:**
- `origin` (Vec3): Starting position.
- `destination` (Vec3): Target position.

**Returns:** True if visible, false if terrain blocks the view.

```lua
local observer = Unit.getByName("JTAC"):getPoint()
local target = Unit.getByName("Target"):getPoint()
if land.isVisible(observer, target) then
    env.info("JTAC has eyes on target")
end
```

##### land.getIP

```lua
Vec3 land.getIP(Vec3 origin, Vec3 direction, number distance)
```

Performs a ray cast and returns the intersection point with terrain.

**Parameters:**
- `origin` (Vec3): Starting position.
- `direction` (Vec3): Direction vector (will be normalized).
- `distance` (number): Maximum ray distance in meters.

**Returns:** Vec3 intersection point, or nil if no intersection.

**Gotchas:** The direction is a vector, not angles. Use unit vectors from `getPosition()`.

```lua
-- Find where an aircraft's nose is pointing at the ground
local pos = aircraft:getPosition()
local impactPoint = land.getIP(pos.p, pos.x, 20000)  -- pos.x is forward vector
if impactPoint then
    env.info("Looking at ground point: " .. impactPoint.x .. ", " .. impactPoint.z)
end
```

##### land.profile

```lua
table land.profile(Vec2 start, Vec2 finish)
```

Returns terrain heights along a path between two points.

**Parameters:**
- `start` (Vec2): Starting position.
- `finish` (Vec2): Ending position.

**Returns:** Array of Vec3 points along the terrain profile.

##### land.getClosestPointOnRoads

```lua
number, number land.getClosestPointOnRoads(string roadType, number x, number y)
```

Finds the nearest point on a road network.

**Parameters:**
- `roadType` (string): "roads" or "railroads".
- `x` (number): X coordinate.
- `y` (number): Y coordinate (Vec2 convention).

**Returns:** x, y coordinates of the nearest road point.

```lua
local roadX, roadY = land.getClosestPointOnRoads("roads", unitPos.x, unitPos.z)
```

##### land.findPathOnRoads

```lua
table land.findPathOnRoads(string roadType, number x1, number y1, number x2, number y2)
```

Finds a path along roads between two points.

**Parameters:**
- `roadType` (string): "roads" or "railroads".
- `x1`, `y1` (number): Start coordinates.
- `x2`, `y2` (number): End coordinates.

**Returns:** Array of Vec2 waypoints along the road.

```lua
local path = land.findPathOnRoads("roads", startX, startZ, endX, endZ)
if path then
    for i, waypoint in ipairs(path) do
        env.info("Waypoint " .. i .. ": " .. waypoint.x .. ", " .. waypoint.y)
    end
end
```

#### atmosphere

The atmosphere singleton provides weather information.

##### atmosphere.getWind

```lua
Vec3 atmosphere.getWind(Vec3 position)
```

Returns the wind vector at a position (without turbulence).

**Parameters:**
- `position` (Vec3): World position.

**Returns:** Vec3 wind vector in m/s (direction wind is blowing TO, not FROM).

```lua
local windVec = atmosphere.getWind(unit:getPoint())
local windSpeed = math.sqrt(windVec.x^2 + windVec.z^2)
local windHeading = math.atan2(windVec.z, windVec.x)
```

##### atmosphere.getWindWithTurbulence

```lua
Vec3 atmosphere.getWindWithTurbulence(Vec3 position)
```

Returns the wind vector including turbulence effects.

**Parameters:**
- `position` (Vec3): World position.

**Returns:** Vec3 wind vector in m/s.

##### atmosphere.getTemperatureAndPressure

```lua
number, number atmosphere.getTemperatureAndPressure(Vec3 position)
```

Returns atmospheric conditions at a position.

**Parameters:**
- `position` (Vec3): World position.

**Returns:** temperature (Kelvin), pressure (Pascals).

```lua
local temp, pressure = atmosphere.getTemperatureAndPressure(unit:getPoint())
local tempC = temp - 273.15  -- Convert to Celsius
local pressureHPa = pressure / 100  -- Convert to hPa/mbar
```

### Classes

Classes represent game objects like units, groups, and airbases. You call their functions using colon notation (e.g., `unit:getName()`). Objects are obtained through static functions, other objects, or events.

#### Object

The base class for all objects with a physical presence in the game world. This is an abstract class; you work with its subclasses (Unit, Weapon, StaticObject, etc.).

**Category Enum:**
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

##### Object.isExist

```lua
boolean object:isExist()
```

Returns whether the object currently exists in the mission. Objects cease to exist when destroyed.

**Returns:** True if the object exists, false otherwise.

**Gotchas:** Always check `isExist()` before calling other functions on objects obtained from stored references, as the object may have been destroyed since you acquired the reference.

```lua
local unit = Unit.getByName("Target 1")
if unit and unit:isExist() then
    local pos = unit:getPoint()
end
```

##### Object.destroy

```lua
nil object:destroy()
```

Destroys the object, removing it from the mission. For units, this kills them instantly without any death animation or explosion.

```lua
local debris = StaticObject.getByName("wreckage")
if debris then
    debris:destroy()
end
```

##### Object.getCategory

```lua
number object:getCategory()
```

Returns the object's category from `Object.Category`.

**Returns:** Category enum value.

```lua
local cat = object:getCategory()
if cat == Object.Category.UNIT then
    env.info("This is a unit")
end
```

##### Object.getTypeName

```lua
string object:getTypeName()
```

Returns the object's type name as used in the mission file (e.g., "F-16C_50", "SA-11 Buk LN 9A310M1").

**Returns:** Type name string.

```lua
local typeName = unit:getTypeName()
env.info("Unit type: " .. typeName)
```

##### Object.getDesc

```lua
table object:getDesc()
```

Returns a description table with detailed information about the object type. The contents vary by object type.

**Returns:** Description table with at minimum `life` and `box` fields.

```lua
local desc = unit:getDesc()
env.info("Max life: " .. desc.life)
```

##### Object.hasAttribute

```lua
boolean object:hasAttribute(string attributeName)
```

Checks if the object has a specific attribute (e.g., "Air", "Ground Units", "SAM related").

**Parameters:**
- `attributeName` (string): The attribute to check for.

**Returns:** True if the object has the attribute.

```lua
if unit:hasAttribute("SAM related") then
    env.info("This is a SAM unit")
end
```

##### Object.getName

```lua
string object:getName()
```

Returns the object's unique name as defined in the Mission Editor.

**Returns:** Object name string.

```lua
local name = unit:getName()
trigger.action.outText(name .. " has been spotted", 10)
```

##### Object.getPoint

```lua
Vec3 object:getPoint()
```

Returns the object's position in 3D space.

**Returns:** Vec3 with x, y (altitude), z coordinates.

```lua
local pos = unit:getPoint()
local altitude = pos.y
env.info("Altitude: " .. altitude .. " meters")
```

##### Object.getPosition

```lua
Position3 object:getPosition()
```

Returns the object's position and orientation.

**Returns:** Position3 table with `p` (position) and `x`, `y`, `z` (orientation vectors).

```lua
local pos = unit:getPosition()
local heading = math.atan2(pos.x.z, pos.x.x)
```

##### Object.getVelocity

```lua
Vec3 object:getVelocity()
```

Returns the object's velocity vector.

**Returns:** Vec3 velocity in m/s for each axis.

```lua
local vel = unit:getVelocity()
local speed = math.sqrt(vel.x^2 + vel.y^2 + vel.z^2)
env.info("Speed: " .. speed .. " m/s")
```

##### Object.inAir

```lua
boolean object:inAir()
```

Returns whether the object is airborne.

**Returns:** True if in the air, false if on the ground.

```lua
if unit:inAir() then
    env.info("Aircraft is flying")
else
    env.info("Aircraft is on the ground")
end
```

#### CoalitionObject

Extends Object with coalition and country information. Base class for Unit, Weapon, StaticObject, and Airbase.

##### CoalitionObject.getCoalition

```lua
number object:getCoalition()
```

Returns the object's coalition.

**Returns:** Coalition from `coalition.side` (0=neutral, 1=red, 2=blue).

```lua
if unit:getCoalition() == coalition.side.BLUE then
    env.info("Friendly unit")
end
```

##### CoalitionObject.getCountry

```lua
number object:getCountry()
```

Returns the object's country.

**Returns:** Country ID from `country.id`.

```lua
local countryId = unit:getCountry()
```

#### Unit

Represents controllable units: aircraft, helicopters, ground vehicles, ships, and armed structures. Inherits from Object and CoalitionObject.

**Obtaining Units:**
- `Unit.getByName("name")` - Get by Mission Editor name
- `group:getUnits()` - Get all units in a group
- `event.initiator` - From events

**Category Enum:**
```lua
Unit.Category = {
    AIRPLANE = 0,
    HELICOPTER = 1,
    GROUND_UNIT = 2,
    SHIP = 3,
    STRUCTURE = 4
}
```

**Gotchas:** `unit:getCategory()` returns `Object.Category.UNIT`. To get the unit type (airplane, helicopter, etc.), use `unit:getDesc().category` which returns `Unit.Category`.

##### Unit.getByName

```lua
Unit Unit.getByName(string name)
```

Static function that returns a unit by its Mission Editor name.

**Parameters:**
- `name` (string): The unit's name.

**Returns:** Unit object, or nil if not found or destroyed.

```lua
local player = Unit.getByName("Player F-16")
if player then
    env.info("Player aircraft found")
end
```

##### Unit.isActive

```lua
boolean unit:isActive()
```

Returns whether the unit is active. Units with late activation are inactive until activated by trigger.

**Returns:** True if active.

```lua
if not unit:isActive() then
    unit:getGroup():activate()
end
```

##### Unit.getPlayerName

```lua
string unit:getPlayerName()
```

Returns the player's name if this unit is controlled by a human.

**Returns:** Player name string, or nil for AI units.

```lua
local playerName = unit:getPlayerName()
if playerName then
    env.info("Controlled by: " .. playerName)
end
```

##### Unit.getID

```lua
number unit:getID()
```

Returns the unit's unique numeric ID.

**Returns:** Unit ID number.

##### Unit.getNumber

```lua
number unit:getNumber()
```

Returns the unit's position number within its group (1-based).

**Returns:** Position in group.

```lua
local num = unit:getNumber()
if num == 1 then
    env.info("This is the flight lead")
end
```

##### Unit.getGroup

```lua
Group unit:getGroup()
```

Returns the group this unit belongs to.

**Returns:** Group object.

```lua
local group = unit:getGroup()
local groupName = group:getName()
```

##### Unit.getCallsign

```lua
string unit:getCallsign()
```

Returns the unit's callsign.

**Returns:** Callsign string (e.g., "Enfield11").

```lua
local callsign = unit:getCallsign()
trigger.action.outText(callsign .. ", cleared hot", 5)
```

##### Unit.getLife

```lua
number unit:getLife()
```

Returns the unit's current hit points. Units with life < 1 are considered dead.

**Returns:** Current hit points.

**Gotchas:** Ground units that are on fire but haven't exploded yet return 0.

```lua
local life = unit:getLife()
local maxLife = unit:getDesc().life
local healthPercent = (life / maxLife) * 100
```

##### Unit.getLife0

```lua
number unit:getLife0()
```

Returns the unit's initial (maximum) hit points.

**Returns:** Initial hit points.

##### Unit.getFuel

```lua
number unit:getFuel()
```

Returns the unit's fuel level as a fraction of internal fuel capacity.

**Returns:** Fuel fraction (0.0 to 1.0+). Values above 1.0 indicate external tanks.

**Gotchas:** Ground vehicles and ships always return 1. Aircraft with external tanks can return values above 1.0.

```lua
local fuel = unit:getFuel()
if fuel < 0.2 then
    trigger.action.outText("Bingo fuel!", 10)
end
```

##### Unit.getAmmo

```lua
table unit:getAmmo()
```

Returns detailed ammunition information.

**Returns:** Array of ammo entries, each with `count` and `desc` (weapon description) fields.

```lua
local ammo = unit:getAmmo()
for _, wpn in ipairs(ammo or {}) do
    env.info(wpn.desc.displayName .. ": " .. wpn.count)
end
```

##### Unit.getController

```lua
Controller unit:getController()
```

Returns the unit's AI controller. For aircraft, individual units can be controlled. For ground/ship units, use the group controller instead.

**Returns:** Controller object.

```lua
local controller = unit:getController()
controller:setOption(AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.WEAPON_FREE)
```

##### Unit.getSensors

```lua
table unit:getSensors()
```

Returns information about the unit's sensors (radar, IRST, etc.).

**Returns:** Table of sensor information.

##### Unit.getRadar

```lua
boolean, Object unit:getRadar()
```

Returns radar status and current target.

**Returns:** isOn (boolean), target (Object or nil).

```lua
local radarOn, target = unit:getRadar()
if radarOn and target then
    env.info("Radar locked onto: " .. target:getName())
end
```

##### Unit.enableEmission

```lua
nil unit:enableEmission(boolean enable)
```

Enables or disables radar/radio emissions for the unit.

**Parameters:**
- `enable` (boolean): True to enable emissions, false to disable.

```lua
-- Go emissions silent
unit:enableEmission(false)
```

#### Group

Represents a group of units. Groups are the primary unit of control for AI.

**Obtaining Groups:**
- `Group.getByName("name")` - Get by Mission Editor name
- `unit:getGroup()` - Get from a unit
- `coalition.getGroups(coalitionId)` - Get all groups for a coalition

**Category Enum:**
```lua
Group.Category = {
    AIRPLANE = 0,
    HELICOPTER = 1,
    GROUND = 2,
    SHIP = 3,
    TRAIN = 4
}
```

##### Group.getByName

```lua
Group Group.getByName(string name)
```

Static function that returns a group by its Mission Editor name.

**Parameters:**
- `name` (string): The group's name.

**Returns:** Group object, or nil if not found.

```lua
local enemyGroup = Group.getByName("Enemy CAP")
if enemyGroup and enemyGroup:isExist() then
    local size = enemyGroup:getSize()
end
```

##### Group.isExist

```lua
boolean group:isExist()
```

Returns whether the group exists. Groups cease to exist when all units are destroyed.

**Returns:** True if at least one unit is alive.

##### Group.activate

```lua
nil group:activate()
```

Activates a late-activation group, causing it to spawn and begin its mission.

```lua
local reinforcements = Group.getByName("Reinforcements")
reinforcements:activate()
```

##### Group.destroy

```lua
nil group:destroy()
```

Destroys the entire group, removing all units.

##### Group.getCategory

```lua
number group:getCategory()
```

Returns the group category.

**Returns:** Category from `Group.Category`.

##### Group.getCoalition

```lua
number group:getCoalition()
```

Returns the group's coalition.

**Returns:** Coalition from `coalition.side`.

##### Group.getName

```lua
string group:getName()
```

Returns the group's name.

**Returns:** Group name string.

##### Group.getID

```lua
number group:getID()
```

Returns the group's unique numeric ID. Used for group-specific menu commands and messages.

**Returns:** Group ID number.

```lua
local groupId = group:getID()
missionCommands.addCommandForGroup(groupId, "Request Support", nil, requestSupport)
```

##### Group.getUnit

```lua
Unit group:getUnit(number index)
```

Returns a specific unit from the group by index (1-based).

**Parameters:**
- `index` (number): Unit position in group (1 = lead).

**Returns:** Unit object.

```lua
local lead = group:getUnit(1)
local wingman = group:getUnit(2)
```

##### Group.getUnits

```lua
table group:getUnits()
```

Returns all units in the group.

**Returns:** Array of Unit objects.

```lua
for i, unit in ipairs(group:getUnits()) do
    env.info("Unit " .. i .. ": " .. unit:getName())
end
```

##### Group.getSize

```lua
number group:getSize()
```

Returns the number of units currently alive in the group.

**Returns:** Current unit count.

##### Group.getInitialSize

```lua
number group:getInitialSize()
```

Returns the number of units the group started with.

**Returns:** Initial unit count.

```lua
local current = group:getSize()
local initial = group:getInitialSize()
local losses = initial - current
```

##### Group.getController

```lua
Controller group:getController()
```

Returns the group's AI controller. This is the primary way to control AI behavior.

**Returns:** Controller object.

```lua
local controller = group:getController()
controller:setTask(orbitTask)
```

##### Group.enableEmission

```lua
nil group:enableEmission(boolean enable)
```

Enables or disables radar/radio emissions for all units in the group.

**Parameters:**
- `enable` (boolean): True to enable, false to disable.

#### Airbase

Represents airports, FARPs (Forward Arming and Refueling Points), and ships with flight decks. Inherits from Object and CoalitionObject.

**Obtaining Airbases:**
- `Airbase.getByName("name")` - Get by name
- `coalition.getAirbases(coalitionId)` - Get all for a coalition
- `world.getAirbases()` - Get all in mission

**Category Enum:**
```lua
Airbase.Category = {
    AIRDROME = 0,
    HELIPAD = 1,
    SHIP = 2
}
```

**Gotchas:** `airbase:getCategory()` returns `Object.Category.BASE`. Use `airbase:getDesc().category` to get `Airbase.Category`.

##### Airbase.getByName

```lua
Airbase Airbase.getByName(string name)
```

Static function that returns an airbase by name.

**Parameters:**
- `name` (string): The airbase name (e.g., "Batumi", "CVN-74 John C. Stennis").

**Returns:** Airbase object, or nil if not found.

```lua
local batumi = Airbase.getByName("Batumi")
local pos = batumi:getPoint()
```

##### Airbase.getCallsign

```lua
string airbase:getCallsign()
```

Returns the airbase's radio callsign.

**Returns:** Callsign string.

##### Airbase.getUnit

```lua
Unit airbase:getUnit(number index)
```

For ship-based airbases, returns the ship unit.

**Parameters:**
- `index` (number): Unit index (typically 1).

**Returns:** Unit object for ships, nil for ground airbases.

##### Airbase.getParking

```lua
table airbase:getParking(boolean available)
```

Returns parking spot information.

**Parameters:**
- `available` (boolean): Optional. If true, returns only unoccupied spots.

**Returns:** Array of parking spot tables with `Term_Index`, `vTerminalPos`, `fDistToRW`, `Term_Type`, etc.

```lua
local spots = airbase:getParking(true)
for _, spot in ipairs(spots) do
    env.info("Available spot: " .. spot.Term_Index)
end
```

##### Airbase.getRunways

```lua
table airbase:getRunways()
```

Returns runway information.

**Returns:** Array of runway tables with heading, length, and position data.

##### Airbase.getRadioSilentMode

```lua
boolean airbase:getRadioSilentMode()
```

Returns whether the airbase's radio is silenced.

**Returns:** True if radio is silent.

##### Airbase.setRadioSilentMode

```lua
nil airbase:setRadioSilentMode(boolean silent)
```

Enables or disables the airbase's radio.

**Parameters:**
- `silent` (boolean): True to silence, false to enable.

##### Airbase.setCoalition

```lua
nil airbase:setCoalition(number coalitionId)
```

Changes the airbase's coalition (captures it).

**Parameters:**
- `coalitionId` (number): New coalition from `coalition.side`.

```lua
-- Capture the airbase for blue team
airbase:setCoalition(coalition.side.BLUE)
```

##### Airbase.autoCapture

```lua
nil airbase:autoCapture(boolean enable)
```

Enables or disables automatic capture when ground forces are nearby.

**Parameters:**
- `enable` (boolean): True to enable auto-capture.

##### Airbase.autoCaptureIsOn

```lua
boolean airbase:autoCaptureIsOn()
```

Returns whether auto-capture is enabled.

**Returns:** True if auto-capture is on.

##### Airbase.getWarehouse

```lua
Warehouse airbase:getWarehouse()
```

Returns the airbase's warehouse (logistics) object.

**Returns:** Warehouse object.

#### StaticObject

Represents non-moving objects placed in the mission: buildings, cargo, decorations. Inherits from Object and CoalitionObject.

**Obtaining StaticObjects:**
- `StaticObject.getByName("name")` - Get by name
- `coalition.getStaticObjects(coalitionId)` - Get all for a coalition

##### StaticObject.getByName

```lua
StaticObject StaticObject.getByName(string name)
```

Static function that returns a static object by name.

**Parameters:**
- `name` (string): The object's name.

**Returns:** StaticObject, or nil if not found.

##### StaticObject.getLife

```lua
number staticObject:getLife()
```

Returns the object's current hit points.

**Returns:** Current hit points.

#### Weapon

Represents a weapon in flight: missiles, bombs, rockets, shells. Inherits from Object and CoalitionObject. Obtained through events.

**Category Enum:**
```lua
Weapon.Category = {
    SHELL = 0,
    MISSILE = 1,
    ROCKET = 2,
    BOMB = 3
}
```

**Guidance Enum:**
```lua
Weapon.GuidanceType = {
    INS = 1,
    IR = 2,
    RADAR_ACTIVE = 3,
    RADAR_SEMI_ACTIVE = 4,
    RADAR_PASSIVE = 5,
    TV = 6,
    LASER = 7,
    TELE = 8
}
```

**Gotchas:** `weapon:getCategory()` returns `Object.Category.WEAPON`. Use `weapon:getDesc().category` for `Weapon.Category`.

##### Weapon.getLauncher

```lua
Unit weapon:getLauncher()
```

Returns the unit that fired this weapon.

**Returns:** Unit object, or nil.

```lua
function handler:onEvent(event)
    if event.id == world.event.S_EVENT_SHOT then
        local shooter = event.weapon:getLauncher()
        local weaponType = event.weapon:getTypeName()
        env.info(shooter:getName() .. " fired " .. weaponType)
    end
end
```

##### Weapon.getTarget

```lua
Object weapon:getTarget()
```

Returns the weapon's target.

**Returns:** Target Object, or nil for unguided weapons.

#### Controller

The AI control interface. Controllers are obtained from groups or units and used to issue tasks, commands, and options.

**Detection Enum:**
```lua
Controller.Detection = {
    VISUAL = 1,
    OPTIC = 2,
    RADAR = 4,
    IRST = 8,
    RWR = 16,
    DLINK = 32
}
```

##### Controller.setTask

```lua
nil controller:setTask(table task)
```

Sets the group's main task, replacing any existing task.

**Parameters:**
- `task` (table): Task definition table.

**Gotchas:** For newly spawned groups, add a delay before setting tasks to avoid crashes.

```lua
local orbitTask = {
    id = 'Orbit',
    params = {
        pattern = AI.Task.OrbitPattern.CIRCLE,
        point = targetPoint,
        speed = 150,
        altitude = 5000
    }
}
controller:setTask(orbitTask)
```

##### Controller.pushTask

```lua
nil controller:pushTask(table task)
```

Adds a task to the front of the task queue. The current task is suspended until the new task completes.

**Parameters:**
- `task` (table): Task definition table.

##### Controller.popTask

```lua
nil controller:popTask()
```

Removes and discards the current task, resuming the previous one.

##### Controller.resetTask

```lua
nil controller:resetTask()
```

Clears all tasks from the controller.

##### Controller.hasTask

```lua
boolean controller:hasTask()
```

Returns whether the controller has any active task.

**Returns:** True if a task is active.

##### Controller.setCommand

```lua
nil controller:setCommand(table command)
```

Issues an immediate command to the controller.

**Parameters:**
- `command` (table): Command definition table.

```lua
local startCommand = {
    id = 'Start',
    params = {}
}
controller:setCommand(startCommand)
```

##### Controller.setOption

```lua
nil controller:setOption(number optionId, any value)
```

Sets an AI behavior option.

**Parameters:**
- `optionId` (number): Option ID from `AI.Option.[Air/Ground/Naval].id`.
- `value` (any): Option value from corresponding enum.

```lua
-- Set weapons free ROE
controller:setOption(AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.WEAPON_FREE)

-- Set reaction to threat: evade
controller:setOption(AI.Option.Air.id.REACTION_ON_THREAT, AI.Option.Air.val.REACTION_ON_THREAT.EVADE_FIRE)
```

##### Controller.setOnOff

```lua
nil controller:setOnOff(boolean on)
```

Enables or disables the AI controller.

**Parameters:**
- `on` (boolean): True to enable, false to disable (unit becomes passive).

##### Controller.setAltitude

```lua
nil controller:setAltitude(number altitude, boolean keep, string altType)
```

Sets the desired altitude for aircraft.

**Parameters:**
- `altitude` (number): Altitude in meters.
- `keep` (boolean): If true, maintains altitude even when not tasked.
- `altType` (string): "RADIO" (AGL) or "BARO" (MSL).

```lua
controller:setAltitude(8000, true, "BARO")
```

##### Controller.setSpeed

```lua
nil controller:setSpeed(number speed, boolean keep)
```

Sets the desired speed for aircraft.

**Parameters:**
- `speed` (number): Speed in m/s.
- `keep` (boolean): If true, maintains speed even when not tasked.

##### Controller.getDetectedTargets

```lua
table controller:getDetectedTargets(number detectionTypes)
```

Returns targets detected by the unit/group.

**Parameters:**
- `detectionTypes` (number): Optional. Bitmask of `Controller.Detection` values.

**Returns:** Array of detected target tables with `object`, `visible`, `type`, and `distance` fields.

```lua
local targets = controller:getDetectedTargets(Controller.Detection.RADAR + Controller.Detection.VISUAL)
for _, target in ipairs(targets) do
    if target.object and target.object:isExist() then
        env.info("Detected: " .. target.object:getName())
    end
end
```

##### Controller.isTargetDetected

```lua
boolean, boolean, ... controller:isTargetDetected(Object target, number detectionTypes)
```

Checks if a specific target is detected.

**Parameters:**
- `target` (Object): The object to check.
- `detectionTypes` (number): Bitmask of detection types.

**Returns:** Multiple values indicating detection status by each sensor type.

##### Controller.knowTarget

```lua
nil controller:knowTarget(Object target, boolean type, boolean distance)
```

Forces the AI to "know" about a target.

**Parameters:**
- `target` (Object): Target to reveal.
- `type` (boolean): If true, AI knows the target type.
- `distance` (boolean): If true, AI knows the exact distance.

```lua
-- Reveal an enemy unit to friendly AI
local enemy = Unit.getByName("Hidden Enemy")
controller:knowTarget(enemy, true, true)
```

#### Spot

Represents a laser or infrared designator spot. Created dynamically through static functions.

**Category Enum:**
```lua
Spot.Category = {
    INFRA_RED = 0,
    LASER = 1
}
```

##### Spot.createLaser

```lua
Spot Spot.createLaser(Object source, table localPosition, Vec3 targetPoint, number laserCode)
```

Creates a laser spot emanating from an object.

**Parameters:**
- `source` (Object): The object the laser originates from.
- `localPosition` (table): Offset from the object's center.
- `targetPoint` (Vec3): Where the laser is pointing.
- `laserCode` (number): 4-digit laser code (1111-1788).

**Returns:** Spot object.

```lua
local jtac = Unit.getByName("JTAC")
local target = Unit.getByName("Target"):getPoint()
local spot = Spot.createLaser(jtac, {x=0, y=2, z=0}, target, 1688)
```

##### Spot.createInfraRed

```lua
Spot Spot.createInfraRed(Object source, table localPosition, Vec3 targetPoint)
```

Creates an infrared pointer spot.

**Parameters:**
- `source` (Object): The object the IR pointer originates from.
- `localPosition` (table): Offset from the object's center.
- `targetPoint` (Vec3): Where the IR is pointing.

**Returns:** Spot object.

##### Spot.destroy

```lua
nil spot:destroy()
```

Removes the spot.

##### Spot.getPoint

```lua
Vec3 spot:getPoint()
```

Returns where the spot is currently pointing.

**Returns:** Vec3 target position.

##### Spot.setPoint

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

##### Spot.getCode

```lua
number spot:getCode()
```

Returns the laser code (laser spots only).

**Returns:** 4-digit laser code.

##### Spot.setCode

```lua
nil spot:setCode(number code)
```

Changes the laser code.

**Parameters:**
- `code` (number): New 4-digit laser code (1111-1788).

### Events

The event system allows scripts to react to game events like weapon fire, unit deaths, takeoffs, and player actions. Events are received through handlers registered with `world.addEventHandler()`.

#### Event System Overview

To receive events, create a handler table with an `onEvent` function and register it:

```lua
local myHandler = {}

function myHandler:onEvent(event)
    if event.id == world.event.S_EVENT_SHOT then
        -- Handle shot event
    end
end

world.addEventHandler(myHandler)
```

All events contain at least:
- `id` (number): Event type from `world.event`
- `time` (number): Mission time when the event occurred

Many events include `initiator`, which is typically the Unit that caused the event. Always nil-check `initiator` as it may be nil in some edge cases (especially in multiplayer).

**Event ID Enum:**
```lua
world.event = {
    S_EVENT_SHOT = 1,
    S_EVENT_HIT = 2,
    S_EVENT_TAKEOFF = 3,
    S_EVENT_LAND = 4,
    S_EVENT_CRASH = 5,
    S_EVENT_EJECTION = 6,
    S_EVENT_REFUELING = 7,
    S_EVENT_DEAD = 8,
    S_EVENT_PILOT_DEAD = 9,
    S_EVENT_BASE_CAPTURED = 10,
    S_EVENT_MISSION_START = 11,
    S_EVENT_MISSION_END = 12,
    S_EVENT_REFUELING_STOP = 14,
    S_EVENT_BIRTH = 15,
    S_EVENT_HUMAN_FAILURE = 16,
    S_EVENT_DETAILED_FAILURE = 17,
    S_EVENT_ENGINE_STARTUP = 18,
    S_EVENT_ENGINE_SHUTDOWN = 19,
    S_EVENT_PLAYER_ENTER_UNIT = 20,
    S_EVENT_PLAYER_LEAVE_UNIT = 21,
    S_EVENT_PLAYER_COMMENT = 22,
    S_EVENT_SHOOTING_START = 23,
    S_EVENT_SHOOTING_END = 24,
    S_EVENT_MARK_ADDED = 25,
    S_EVENT_MARK_CHANGE = 26,
    S_EVENT_MARK_REMOVE = 27,
    S_EVENT_KILL = 28,
    S_EVENT_SCORE = 29,
    S_EVENT_UNIT_LOST = 30,
    S_EVENT_LANDING_AFTER_EJECTION = 31,
    S_EVENT_DISCARD_CHAIR_AFTER_EJECTION = 32,
    S_EVENT_WEAPON_ADD = 33,
    S_EVENT_LANDING_QUALITY_MARK = 34,
    S_EVENT_AI_ABORT_MISSION = 35,
    S_EVENT_RUNWAY_TAKEOFF = 36,
    S_EVENT_RUNWAY_TOUCH = 37,
}
```

#### Combat Events

##### S_EVENT_SHOT

Fires when a unit fires a weapon (missile, bomb, rocket). Does not fire for guns.

**Event Table:**
```lua
{
    id = 1,
    time = number,
    initiator = Unit,    -- Unit that fired
    weapon = Weapon      -- The weapon object
}
```

```lua
function handler:onEvent(event)
    if event.id == world.event.S_EVENT_SHOT then
        local shooter = event.initiator
        local weapon = event.weapon
        if shooter and weapon then
            env.info(shooter:getName() .. " fired " .. weapon:getTypeName())
        end
    end
end
```

##### S_EVENT_HIT

Fires when a weapon hits a target.

**Event Table:**
```lua
{
    id = 2,
    time = number,
    initiator = Unit,    -- Unit that fired the weapon
    weapon = Weapon,     -- The weapon that hit
    target = Object      -- Object that was hit
}
```

**Gotchas:** In multiplayer, the `weapon` field may be nil due to network desync.

##### S_EVENT_SHOOTING_START

Fires when a unit begins firing guns (continuous fire weapons).

**Event Table:**
```lua
{
    id = 23,
    time = number,
    initiator = Unit,
    weapon_name = string  -- Weapon type name
}
```

##### S_EVENT_SHOOTING_END

Fires when a unit stops firing guns.

**Event Table:**
```lua
{
    id = 24,
    time = number,
    initiator = Unit,
    weapon_name = string
}
```

##### S_EVENT_KILL

Fires when a unit kills another unit.

**Event Table:**
```lua
{
    id = 28,
    time = number,
    initiator = Unit,    -- Killer
    target = Unit,       -- Victim
    weapon = Weapon,     -- Weapon used
    weapon_name = string -- Weapon type name
}
```

#### Death and Damage Events

##### S_EVENT_DEAD

Fires when a unit is destroyed (HP reaches 0).

**Event Table:**
```lua
{
    id = 8,
    time = number,
    initiator = Object  -- The object that died
}
```

**Gotchas:** For aircraft, `S_EVENT_CRASH` may fire instead of or in addition to `S_EVENT_DEAD`.

```lua
function handler:onEvent(event)
    if event.id == world.event.S_EVENT_DEAD then
        local unit = event.initiator
        if unit then
            env.info(unit:getName() .. " was destroyed")
        end
    end
end
```

##### S_EVENT_CRASH

Fires when an aircraft crashes into the ground and is completely destroyed.

**Event Table:**
```lua
{
    id = 5,
    time = number,
    initiator = Unit  -- Aircraft that crashed
}
```

##### S_EVENT_PILOT_DEAD

Fires when a pilot dies (separate from aircraft destruction).

**Event Table:**
```lua
{
    id = 9,
    time = number,
    initiator = Unit  -- Aircraft whose pilot died
}
```

##### S_EVENT_UNIT_LOST

Fires when any unit is lost from the mission for any reason.

**Event Table:**
```lua
{
    id = 30,
    time = number,
    initiator = Unit
}
```

##### S_EVENT_HUMAN_FAILURE

Fires when a player-controlled aircraft experiences a system failure.

**Event Table:**
```lua
{
    id = 16,
    time = number,
    initiator = Unit
}
```

##### S_EVENT_DETAILED_FAILURE

Fires with detailed information about system failures.

**Event Table:**
```lua
{
    id = 17,
    time = number,
    initiator = Unit
}
```

#### Flight Events

##### S_EVENT_TAKEOFF

Fires when an aircraft takes off from an airbase, FARP, or ship. Fires several seconds after liftoff.

**Event Table:**
```lua
{
    id = 3,
    time = number,
    initiator = Unit,    -- Aircraft that took off
    place = Airbase,     -- Airbase/FARP/ship
    subPlace = number    -- Sub-location identifier
}
```

**Gotchas:** As of DCS 2.9.6, this event fires after the aircraft has departed the immediate vicinity. Use `S_EVENT_RUNWAY_TAKEOFF` for the moment of liftoff.

##### S_EVENT_LAND

Fires when an aircraft lands at an airbase, FARP, or ship and sufficiently slows down.

**Event Table:**
```lua
{
    id = 4,
    time = number,
    initiator = Unit,    -- Aircraft that landed
    place = Airbase,     -- Where it landed
    subPlace = number
}
```

**Gotchas:** As of DCS 2.9.6, this event fires after the aircraft has fully stopped. Use `S_EVENT_RUNWAY_TOUCH` for the moment of touchdown.

##### S_EVENT_RUNWAY_TAKEOFF

Fires at the exact moment an aircraft leaves the ground.

**Event Table:**
```lua
{
    id = 36,
    time = number,
    initiator = Unit,
    place = Airbase
}
```

##### S_EVENT_RUNWAY_TOUCH

Fires at the exact moment an aircraft touches the ground after being airborne.

**Event Table:**
```lua
{
    id = 37,
    time = number,
    initiator = Unit,
    place = Airbase
}
```

##### S_EVENT_REFUELING

Fires when an aircraft connects with a tanker and begins taking on fuel.

**Event Table:**
```lua
{
    id = 7,
    time = number,
    initiator = Unit  -- Aircraft receiving fuel
}
```

##### S_EVENT_REFUELING_STOP

Fires when an aircraft disconnects from a tanker.

**Event Table:**
```lua
{
    id = 14,
    time = number,
    initiator = Unit
}
```

##### S_EVENT_EJECTION

Fires when a pilot ejects from an aircraft.

**Event Table:**
```lua
{
    id = 6,
    time = number,
    initiator = Unit,  -- Aircraft being ejected from
    target = Object    -- Ejector seat or pilot object
}
```

**Gotchas:** For aircraft with ejector seats, `target` is the seat object. Wait for `S_EVENT_DISCARD_CHAIR_AFTER_EJECTION` to get the pilot. The pilot object is special and most scripting functions don't work on it.

##### S_EVENT_DISCARD_CHAIR_AFTER_EJECTION

Fires when the ejector seat separates from the pilot.

**Event Table:**
```lua
{
    id = 32,
    time = number,
    initiator = Unit,
    target = Object  -- Pilot object
}
```

##### S_EVENT_LANDING_AFTER_EJECTION

Fires when an ejected pilot lands (parachute touchdown).

**Event Table:**
```lua
{
    id = 31,
    time = number,
    initiator = Unit,
    target = Object  -- Pilot object
}
```

##### S_EVENT_ENGINE_STARTUP

Fires when an aircraft starts its engines.

**Event Table:**
```lua
{
    id = 18,
    time = number,
    initiator = Unit
}
```

##### S_EVENT_ENGINE_SHUTDOWN

Fires when an aircraft shuts down its engines.

**Event Table:**
```lua
{
    id = 19,
    time = number,
    initiator = Unit
}
```

##### S_EVENT_LANDING_QUALITY_MARK

Fires for carrier landings with LSO grade information.

**Event Table:**
```lua
{
    id = 34,
    time = number,
    initiator = Unit,
    place = Airbase,
    comment = string  -- LSO grade comments
}
```

#### Player Events

##### S_EVENT_BIRTH

Fires when any unit spawns into the mission.

**Event Table:**
```lua
{
    id = 15,
    time = number,
    initiator = Unit  -- Unit that was born
}
```

```lua
-- Set up player menus when they spawn
function handler:onEvent(event)
    if event.id == world.event.S_EVENT_BIRTH then
        local unit = event.initiator
        if unit and unit:getPlayerName() then
            setupPlayerMenu(unit)
        end
    end
end
```

##### S_EVENT_PLAYER_ENTER_UNIT

Fires when a player takes control of a unit.

**Event Table:**
```lua
{
    id = 20,
    time = number,
    initiator = Unit  -- Unit being controlled
}
```

**Gotchas:** This event correctly fires for Combined Arms units.

```lua
function handler:onEvent(event)
    if event.id == world.event.S_EVENT_PLAYER_ENTER_UNIT then
        local unit = event.initiator
        local playerName = unit:getPlayerName()
        env.info(playerName .. " entered " .. unit:getName())
    end
end
```

##### S_EVENT_PLAYER_LEAVE_UNIT

Fires when a player leaves a unit (disconnects, spectates, or changes slot).

**Event Table:**
```lua
{
    id = 21,
    time = number,
    initiator = Unit
}
```

##### S_EVENT_PLAYER_COMMENT

Fires when a player sends a chat message.

**Event Table:**
```lua
{
    id = 22,
    time = number,
    initiator = Unit,
    comment = string  -- Chat message text
}
```

#### Mission Events

##### S_EVENT_MISSION_START

Fires when the mission begins.

**Event Table:**
```lua
{
    id = 11,
    time = number
}
```

##### S_EVENT_MISSION_END

Fires when the mission ends.

**Event Table:**
```lua
{
    id = 12,
    time = number
}
```

##### S_EVENT_BASE_CAPTURED

Fires when an airbase changes coalition.

**Event Table:**
```lua
{
    id = 10,
    time = number,
    initiator = Unit,    -- Unit that captured
    place = Airbase      -- Airbase that was captured
}
```

##### S_EVENT_AI_ABORT_MISSION

Fires when an AI group aborts its mission.

**Event Table:**
```lua
{
    id = 35,
    time = number,
    initiator = Unit
}
```

#### Marker Events

Map marker events allow scripts to respond to player map annotations.

##### S_EVENT_MARK_ADDED

Fires when a mark or shape is added to the map.

**Event Table:**
```lua
{
    id = 25,
    time = number,
    initiator = Unit,     -- Unit that created the mark (nil for scripts)
    idx = number,         -- Unique mark ID
    coalition = number,   -- -1 if visible to all
    groupID = number,     -- -1 if visible to all in coalition
    text = string,        -- Mark text
    pos = Vec3            -- Mark position
}
```

```lua
-- React to player placing marks with keywords
function handler:onEvent(event)
    if event.id == world.event.S_EVENT_MARK_ADDED then
        if string.find(event.text, "CAS") then
            requestCAS(event.pos)
        end
    end
end
```

##### S_EVENT_MARK_CHANGE

Fires when a mark is modified.

**Event Table:**
```lua
{
    id = 26,
    time = number,
    initiator = Unit,
    idx = number,
    coalition = number,
    groupID = number,
    text = string,
    pos = Vec3
}
```

##### S_EVENT_MARK_REMOVE

Fires when a mark is deleted.

**Event Table:**
```lua
{
    id = 27,
    time = number,
    initiator = Unit,
    idx = number,
    coalition = number,
    groupID = number,
    pos = Vec3
}
```

#### Weapon Events

##### S_EVENT_WEAPON_ADD

Fires when a weapon is added to a unit (e.g., during rearming).

**Event Table:**
```lua
{
    id = 33,
    time = number,
    initiator = Unit,
    weapon_name = string
}
```

### AI Control

The AI control system allows scripts to direct AI behavior through tasks, commands, and options. These are issued through the Controller object obtained from groups or units.

#### Overview

AI behavior is controlled through three mechanisms:

- **Tasks** define what the AI should do (attack, orbit, escort, etc.). Tasks take time to complete and can be queued.
- **Commands** are instant actions that execute immediately (set frequency, activate beacon, etc.). They do not enter the task queue.
- **Options** configure AI behavior settings (ROE, reaction to threat, formation, etc.).

Tasks are issued via `controller:setTask()`, `controller:pushTask()`, or `controller:popTask()`. Commands use `controller:setCommand()`. Options use `controller:setOption()`.

**Gotchas:** After spawning a group with `coalition.addGroup()`, you must add a delay before issuing tasks to the controller. Issuing tasks immediately after spawning can crash the game. Use `timer.scheduleFunction()` to delay by at least 1 second.

#### Task Structure

All tasks follow a common structure:

```lua
local task = {
    id = 'TaskName',
    params = {
        -- Task-specific parameters
    }
}

controller:setTask(task)
```

Tasks are divided into:
- **Main Tasks** - Primary objectives that control the group's behavior
- **En-route Tasks** - Ongoing behaviors that run alongside the main mission
- **Task Wrappers** - Containers that hold other tasks with conditions

#### Task Wrappers

##### ComboTask

A container that holds multiple tasks to be executed in sequence.

```lua
local combo = {
    id = 'ComboTask',
    params = {
        tasks = {
            [1] = task1,
            [2] = task2,
            [3] = task3
        }
    }
}
```

This is the default task format used by the Mission Editor for groups with multiple waypoint tasks.

##### ControlledTask

Wraps a task with start and stop conditions.

```lua
local controlled = {
    id = 'ControlledTask',
    params = {
        task = innerTask,
        condition = {
            -- Start conditions (evaluated once when task is reached)
            time = number,        -- Mission time in seconds
            condition = string,   -- Lua code returning true/false
            userFlag = string,    -- Flag name to check
            userFlagValue = boolean,  -- Expected flag value
            probability = number  -- 0-100 chance of execution
        },
        stopCondition = {
            -- Stop conditions (evaluated continuously)
            time = number,
            condition = string,
            userFlag = string,
            userFlagValue = boolean,
            duration = number,    -- Seconds to run before stopping
            lastWaypoint = number -- Stop when reaching this waypoint
        }
    }
}
```

**Gotchas:** Options and commands do NOT support stopConditions because they execute instantly.

```lua
-- Task with 70% chance that runs for 15 minutes
local timedOrbit = {
    id = "ControlledTask",
    params = {
        task = {
            id = 'Orbit',
            params = {
                pattern = 'Circle',
                point = {x = 100000, y = 200000},
                speed = 200,
                altitude = 8000
            }
        },
        condition = {
            probability = 70
        },
        stopCondition = {
            duration = 900  -- 15 minutes
        }
    }
}
```

##### WrappedAction

Wraps a command or option as a task so it can be placed in the task queue.

```lua
local wrapped = {
    id = 'WrappedAction',
    params = {
        action = {
            id = 'SetFrequency',
            params = {
                frequency = 251000000,
                modulation = 0,
                power = 10
            }
        }
    }
}
```

#### Main Tasks

Main tasks define the primary behavior of a group.

##### Orbit

Orders aircraft to orbit at a location.

**For:** Airplanes, Helicopters

```lua
local orbit = {
    id = 'Orbit',
    params = {
        pattern = string,     -- "Circle", "Race-Track", or "Anchored"
        point = Vec2,         -- Center point (optional, uses current waypoint)
        point2 = Vec2,        -- Second point for Race-Track (optional)
        speed = number,       -- Speed in m/s (optional, defaults to 1.5x stall)
        altitude = number,    -- Altitude in meters (optional)
        -- For Anchored pattern only:
        hotLegDir = number,   -- Heading in radians for return leg
        legLength = number,   -- Distance in meters before turning
        width = number,       -- Orbit diameter in meters
        clockWise = boolean   -- true for clockwise (default: false)
    }
}
```

**Pattern Enum:**
```lua
AI.Task.OrbitPattern = {
    RACE_TRACK = "Race-Track",
    CIRCLE = "Circle"
}
-- "Anchored" is also valid but not in the enum
```

```lua
-- Make an aircraft orbit at 8000m altitude
local orbit = {
    id = 'Orbit',
    params = {
        pattern = 'Circle',
        point = {x = 100000, y = 200000},
        speed = 200,
        altitude = 8000
    }
}
Group.getByName('CAP Flight'):getController():setTask(orbit)
```

##### AttackUnit

Orders aircraft to attack a specific unit.

**For:** Airplanes, Helicopters

```lua
local attack = {
    id = 'AttackUnit',
    params = {
        unitId = number,          -- Required: Target unit ID
        weaponType = number,      -- Weapon flags bitmask (optional)
        expend = string,          -- Ordnance per pass (optional)
        direction = number,       -- Attack azimuth in radians (optional)
        attackQtyLimit = boolean, -- Enable attack count limit (optional)
        attackQty = number,       -- Number of attack passes (optional)
        groupAttack = boolean     -- All aircraft attack same target (optional)
    }
}
```

**WeaponExpend Enum:**
```lua
AI.Task.WeaponExpend = {
    ONE = "One",
    TWO = "Two",
    FOUR = "Four",
    QUARTER = "Quarter",
    HALF = "Half",
    ALL = "All"
}
```

```lua
-- Attack a unit with 2 missiles, single pass
local attack = {
    id = 'AttackUnit',
    params = {
        unitId = Unit.getByName("Target"):getID(),
        weaponType = 4161536,  -- Any ASM
        expend = "Two",
        attackQtyLimit = true,
        attackQty = 1
    }
}
```

**Gotchas:** The target unit is automatically detected by the attacking group. Set `groupAttack = true` when attacking heavily defended targets (like ships) that require multiple simultaneous hits.

##### AttackGroup

Orders aircraft to attack all units in a group.

**For:** Airplanes, Helicopters

```lua
local attack = {
    id = 'AttackGroup',
    params = {
        groupId = number,         -- Required: Target group ID
        weaponType = number,
        expend = string,
        direction = number,
        attackQtyLimit = boolean,
        attackQty = number
    }
}
```

##### Bombing

Orders aircraft to bomb a specific point.

**For:** Airplanes, Helicopters

```lua
local bomb = {
    id = 'Bombing',
    params = {
        point = Vec2,             -- Required: Target coordinates
        weaponType = number,
        expend = string,
        attackQtyLimit = boolean,
        attackQty = number,
        direction = number,
        altitude = number,        -- Attack altitude in meters
        attackType = string       -- "Dive" or horizontal
    }
}
```

##### BombingRunway

Orders aircraft to bomb an airfield runway.

**For:** Airplanes

```lua
local bomb = {
    id = 'BombingRunway',
    params = {
        runwayId = number,        -- Airbase ID
        weaponType = number,
        expend = string,
        direction = number
    }
}
```

##### CarpetBombing

Orders aircraft to perform carpet bombing along a path.

**For:** Airplanes

```lua
local carpet = {
    id = 'CarpetBombing',
    params = {
        point = Vec2,             -- Start point
        weaponType = number,
        expend = string,
        direction = number,
        attackQty = number,
        carpetLength = number     -- Length of carpet in meters
    }
}
```

##### Escort

Orders aircraft to escort and protect another group.

**For:** Airplanes, Helicopters

```lua
local escort = {
    id = 'Escort',
    params = {
        groupId = number,         -- Group to escort
        engagementDistMax = number, -- Max engagement range in meters
        targetTypes = table,      -- Array of attribute names to engage
        pos = Vec3,               -- Offset from escorted group
        lastWptIndexFlag = boolean,
        lastWptIndex = number
    }
}
```

##### Follow

Orders aircraft to follow another group in formation.

**For:** Airplanes, Helicopters

```lua
local follow = {
    id = 'Follow',
    params = {
        groupId = number,         -- Group to follow
        pos = Vec3,               -- Position offset
        lastWptIndexFlag = boolean,
        lastWptIndex = number
    }
}
```

##### GoToWaypoint

Orders the group to proceed to a specific waypoint.

**For:** Airplanes, Helicopters, Ground, Ships

```lua
local goto = {
    id = 'GoToWaypoint',
    params = {
        fromWaypointIndex = number, -- Starting waypoint
        goToWaypointIndex = number  -- Destination waypoint
    }
}
```

##### Hold

Orders ground units to stop and hold position.

**For:** Ground Vehicles

```lua
local hold = {
    id = 'Hold',
    params = {}
}
```

##### FireAtPoint

Orders ground units to fire at a specific location.

**For:** Ground Vehicles (artillery)

```lua
local fire = {
    id = 'FireAtPoint',
    params = {
        point = Vec2,             -- Target coordinates
        radius = number,          -- Dispersion radius in meters
        expendQty = number,       -- Rounds to fire (optional)
        expendQtyEnabled = boolean
    }
}
```

##### Land

Orders aircraft to land at an airbase or point.

**For:** Airplanes, Helicopters

```lua
local land = {
    id = 'Land',
    params = {
        point = Vec2,             -- Landing point
        durationFlag = boolean,
        duration = number         -- Time to stay on ground
    }
}
```

##### RecoveryTanker

Orders a tanker to act as a carrier recovery tanker.

**For:** Airplanes (tankers)

```lua
local recovery = {
    id = 'RecoveryTanker',
    params = {
        groupId = number,         -- Carrier group ID
        speed = number,
        altitude = number,
        lastWptIndexFlag = boolean,
        lastWptIndex = number
    }
}
```

#### En-route Tasks

En-route tasks run alongside the main mission, defining ongoing behaviors.

##### EngageTargets

Orders aircraft to engage detected targets of specified types.

**For:** Airplanes, Helicopters

```lua
local engage = {
    id = 'EngageTargets',
    params = {
        targetTypes = table,      -- Array of attribute names
        priority = number         -- Lower = higher priority (default: 0)
    }
}
```

```lua
-- Engage any detected air targets
local cap = {
    id = 'EngageTargets',
    params = {
        targetTypes = {"Air"},
        priority = 0
    }
}
```

##### EngageTargetsInZone

Orders aircraft to engage targets within a specified zone.

**For:** Airplanes, Helicopters

```lua
local engage = {
    id = 'EngageTargetsInZone',
    params = {
        point = Vec2,             -- Zone center
        zoneRadius = number,      -- Zone radius in meters
        targetTypes = table,      -- Array of attribute names
        priority = number
    }
}
```

##### EngageGroup

Orders aircraft to engage a specific enemy group.

**For:** Airplanes, Helicopters

```lua
local engage = {
    id = 'EngageGroup',
    params = {
        groupId = number,         -- Target group ID
        weaponType = number,
        expend = string,
        priority = number
    }
}
```

##### EngageUnit

Orders aircraft to engage a specific enemy unit.

**For:** Airplanes, Helicopters

```lua
local engage = {
    id = 'EngageUnit',
    params = {
        unitId = number,
        weaponType = number,
        expend = string,
        priority = number,
        groupAttack = boolean
    }
}
```

##### AWACS

Designates an aircraft as an AWACS, providing radar coverage for friendly forces.

**For:** Airplanes (AWACS-capable)

```lua
local awacs = {
    id = 'AWACS',
    params = {}
}
```

##### Tanker

Designates an aircraft as an aerial refueling tanker.

**For:** Airplanes (tanker-capable)

```lua
local tanker = {
    id = 'Tanker',
    params = {}
}
```

##### FAC

Designates a unit as a Forward Air Controller.

**For:** Airplanes, Helicopters, Ground Vehicles

```lua
local fac = {
    id = 'FAC',
    params = {
        frequency = number,       -- Radio frequency in Hz
        modulation = number,      -- 0 = AM, 1 = FM
        callname = number,        -- FAC callsign index
        number = number           -- FAC number
    }
}
```

##### FAC_EngageGroup

Orders a FAC to designate a group for attack.

**For:** Airplanes, Helicopters, Ground Vehicles

```lua
local facEngage = {
    id = 'FAC_EngageGroup',
    params = {
        groupId = number,         -- Target group
        weaponType = number,
        designation = string,     -- Designation method
        datalink = boolean,
        frequency = number,
        modulation = number,
        callname = number,
        number = number
    }
}
```

**Designation Enum:**
```lua
AI.Task.Designation = {
    NO = "No",
    WP = "WP",
    IR_POINTER = "IR-Pointer",
    LASER = "Laser",
    AUTO = "Auto"
}
```

##### EWR

Designates a unit as an Early Warning Radar.

**For:** Ground Vehicles (radar-equipped)

```lua
local ewr = {
    id = 'EWR',
    params = {}
}
```

#### Commands

Commands are instant actions that execute immediately. They do not enter the task queue.

##### SetFrequency

Changes the group's radio frequency.

**For:** Airplanes, Helicopters, Ground Vehicles

```lua
local cmd = {
    id = 'SetFrequency',
    params = {
        frequency = number,       -- Frequency in Hz (e.g., 251000000 for 251 MHz)
        modulation = number,      -- 0 = AM, 1 = FM
        power = number            -- Power in watts (10 is typical)
    }
}
controller:setCommand(cmd)
```

```lua
-- Set frequency to 131 MHz AM
local freq = {
    id = "SetFrequency",
    params = {
        power = 10,
        modulation = 0,
        frequency = 131000000
    }
}
Group.getByName("AWACS"):getController():setCommand(freq)
```

##### SetInvisible

Makes the group invisible to enemy AI sensors.

**For:** All unit types

```lua
local cmd = {
    id = 'SetInvisible',
    params = {
        value = boolean           -- true = invisible
    }
}
```

##### SetImmortal

Makes the group invulnerable to all damage.

**For:** All unit types

```lua
local cmd = {
    id = 'SetImmortal',
    params = {
        value = boolean           -- true = immortal
    }
}
```

##### SetUnlimitedFuel

Gives the group unlimited fuel.

**For:** Airplanes, Helicopters

```lua
local cmd = {
    id = 'SetUnlimitedFuel',
    params = {
        value = boolean
    }
}
```

##### Start

Starts the engines of an aircraft.

**For:** Airplanes, Helicopters

```lua
local cmd = {
    id = 'Start',
    params = {}
}
```

##### SwitchWaypoint

Changes the group's current waypoint.

**For:** Airplanes, Helicopters, Ground, Ships

```lua
local cmd = {
    id = 'SwitchWaypoint',
    params = {
        fromWaypointIndex = number,
        goToWaypointIndex = number
    }
}
```

##### StopRoute

Stops or resumes the group's route following.

**For:** All unit types

```lua
local cmd = {
    id = 'StopRoute',
    params = {
        value = boolean           -- true = stop route
    }
}
```

##### SwitchAction

Switches the group's current action.

**For:** All unit types

```lua
local cmd = {
    id = 'SwitchAction',
    params = {
        actionIndex = number
    }
}
```

##### ActivateBeacon

Activates a navigation beacon on the unit.

**For:** All unit types

```lua
local cmd = {
    id = 'ActivateBeacon',
    params = {
        type = number,            -- Beacon type
        system = number,          -- Beacon system
        name = string,            -- Display name (optional)
        callsign = string,        -- Morse code callsign
        frequency = number        -- Frequency in Hz
    }
}
```

**Beacon Types:**
```lua
BEACON_TYPE_NULL = 0
BEACON_TYPE_VOR = 1
BEACON_TYPE_DME = 2
BEACON_TYPE_VOR_DME = 3
BEACON_TYPE_TACAN = 4
BEACON_TYPE_VORTAC = 5
BEACON_TYPE_RSBN = 32
BEACON_TYPE_BROADCAST_STATION = 1024
BEACON_TYPE_HOMER = 8
BEACON_TYPE_AIRPORT_HOMER = 4104
BEACON_TYPE_AIRPORT_HOMER_WITH_MARKER = 4136
BEACON_TYPE_ILS_FAR_HOMER = 16408
BEACON_TYPE_ILS_NEAR_HOMER = 16456
BEACON_TYPE_ILS_LOCALIZER = 16640
BEACON_TYPE_ILS_GLIDESLOPE = 16896
BEACON_TYPE_NAUTICAL_HOMER = 32776
```

**Beacon Systems:**
```lua
SystemName = {
    PAR_10 = 1,
    RSBN_5 = 2,
    TACAN = 3,
    TACAN_TANKER = 4,
    ILS_LOCALIZER = 5,
    ILS_GLIDESLOPE = 6,
    BROADCAST_STATION = 7
}
```

**Gotchas:** Only one beacon can be active per unit at a time. Activating a new beacon deactivates the old one.

##### DeactivateBeacon

Deactivates any active beacon.

**For:** All unit types

```lua
local cmd = {
    id = 'DeactivateBeacon',
    params = {}
}
```

##### ActivateACLS

Activates the Automatic Carrier Landing System on a carrier.

**For:** Ships (carriers)

```lua
local cmd = {
    id = 'ActivateACLS',
    params = {}
}
```

##### DeactivateACLS

Deactivates ACLS.

**For:** Ships (carriers)

```lua
local cmd = {
    id = 'DeactivateACLS',
    params = {}
}
```

##### ActivateLink4

Activates Link 4 datalink on a carrier.

**For:** Ships (carriers)

```lua
local cmd = {
    id = 'ActivateLink4',
    params = {
        unitId = number,          -- Aircraft unit ID
        frequency = number        -- Link 4 frequency
    }
}
```

##### DeactivateLink4

Deactivates Link 4 datalink.

**For:** Ships (carriers)

```lua
local cmd = {
    id = 'DeactivateLink4',
    params = {}
}
```

##### ActivateICLS

Activates the Instrument Carrier Landing System.

**For:** Ships (carriers)

```lua
local cmd = {
    id = 'ActivateICLS',
    params = {
        channel = number          -- ICLS channel
    }
}
```

##### DeactivateICLS

Deactivates ICLS.

**For:** Ships (carriers)

```lua
local cmd = {
    id = 'DeactivateICLS',
    params = {}
}
```

##### EPLRS

Enables or disables EPLRS (Enhanced Position Location Reporting System).

**For:** All unit types

```lua
local cmd = {
    id = 'EPLRS',
    params = {
        value = boolean,
        groupId = number          -- Group to link with (optional)
    }
}
```

##### TransmitMessage

Transmits an audio message.

**For:** All unit types

```lua
local cmd = {
    id = 'TransmitMessage',
    params = {
        file = string,            -- Sound file path
        duration = number,        -- Message duration
        subtitle = string,        -- Subtitle text
        loop = boolean
    }
}
```

##### StopTransmission

Stops any active transmission.

**For:** All unit types

```lua
local cmd = {
    id = 'StopTransmission',
    params = {}
}
```

##### Smoke_On_Off

Toggles smoke trail on or off.

**For:** Airplanes (aerobatic aircraft)

```lua
local cmd = {
    id = 'Smoke_On_Off',
    params = {
        value = boolean
    }
}
```

#### Options

Options configure AI behavior settings. They are set using `controller:setOption(optionId, value)`.

```lua
controller:setOption(AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.WEAPON_FREE)
```

Options are separated by unit domain: Air, Ground, and Naval.

#### Air Options

##### ROE (Rules of Engagement)

Controls when AI aircraft will engage targets.

```lua
AI.Option.Air.id.ROE = 0

AI.Option.Air.val.ROE = {
    WEAPON_FREE = 0,          -- Attack any detected enemy
    OPEN_FIRE_WEAPON_FREE = 1, -- Attack enemies attacking friendlies, engage at will
    OPEN_FIRE = 2,            -- Attack enemies attacking friendlies only
    RETURN_FIRE = 3,          -- Only fire when fired upon
    WEAPON_HOLD = 4           -- Never fire
}
```

```lua
-- Set weapons free
controller:setOption(AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.WEAPON_FREE)
```

##### REACTION_ON_THREAT

Defines how aircraft respond to threats.

```lua
AI.Option.Air.id.REACTION_ON_THREAT = 1

AI.Option.Air.val.REACTION_ON_THREAT = {
    NO_REACTION = 0,          -- Ignore threats
    PASSIVE_DEFENCE = 1,      -- Use countermeasures only
    EVADE_FIRE = 2,           -- Defensive maneuvers + countermeasures
    BYPASS_AND_ESCAPE = 3,    -- Avoid threat zones entirely
    ALLOW_ABORT_MISSION = 4   -- May abort if threat is severe
}
-- AAA_EVADE_FIRE = 5 is also valid (S-turns at altitude)
```

**Behaviors:**
- **No Reaction:** No defensive actions
- **Passive Defence:** Jammers and countermeasures only, no maneuvering
- **Evade Fire:** Defensive maneuvers plus countermeasures
- **Bypass and Escape:** Route around threat zones, fly above threats
- **Allow Abort Mission:** May RTB if situation becomes too dangerous

##### RADAR_USING

Controls radar usage.

```lua
AI.Option.Air.id.RADAR_USING = 3

AI.Option.Air.val.RADAR_USING = {
    NEVER = 0,
    FOR_ATTACK_ONLY = 1,
    FOR_SEARCH_IF_REQUIRED = 2,
    FOR_CONTINUOUS_SEARCH = 3
}
```

##### FLARE_USING

Controls flare and chaff deployment.

```lua
AI.Option.Air.id.FLARE_USING = 4

AI.Option.Air.val.FLARE_USING = {
    NEVER = 0,
    AGAINST_FIRED_MISSILE = 1,
    WHEN_FLYING_IN_SAM_WEZ = 2,
    WHEN_FLYING_NEAR_ENEMIES = 3
}
```

##### Formation

Sets the flight formation.

```lua
AI.Option.Air.id.Formation = 5
-- Value is a formation index number
```

##### RTB_ON_BINGO

Controls whether aircraft return to base when fuel is low.

```lua
AI.Option.Air.id.RTB_ON_BINGO = 6
-- Value: boolean
```

##### SILENCE

Disables radio communications.

```lua
AI.Option.Air.id.SILENCE = 7
-- Value: boolean
```

##### RTB_ON_OUT_OF_AMMO

Controls whether aircraft return to base when out of ammunition.

```lua
AI.Option.Air.id.RTB_ON_OUT_OF_AMMO = 10
-- Value: boolean
```

##### ECM_USING

Controls ECM (Electronic Counter Measures) usage.

```lua
AI.Option.Air.id.ECM_USING = 13

AI.Option.Air.val.ECM_USING = {
    NEVER_USE = 0,
    USE_IF_ONLY_LOCK_BY_RADAR = 1,
    USE_IF_DETECTED_LOCK_BY_RADAR = 2,
    ALWAYS_USE = 3
}
```

##### PROHIBIT_AA

Prohibits air-to-air attacks.

```lua
AI.Option.Air.id.PROHIBIT_AA = 14
-- Value: boolean
```

##### PROHIBIT_JETT

Prohibits jettisoning stores.

```lua
AI.Option.Air.id.PROHIBIT_JETT = 15
-- Value: boolean
```

##### PROHIBIT_AB

Prohibits afterburner use.

```lua
AI.Option.Air.id.PROHIBIT_AB = 16
-- Value: boolean
```

##### PROHIBIT_AG

Prohibits air-to-ground attacks.

```lua
AI.Option.Air.id.PROHIBIT_AG = 17
-- Value: boolean
```

##### MISSILE_ATTACK

Controls missile launch range behavior.

```lua
AI.Option.Air.id.MISSILE_ATTACK = 18

AI.Option.Air.val.MISSILE_ATTACK = {
    MAX_RANGE = 0,            -- Fire at maximum range
    NEZ_RANGE = 1,            -- Fire at no-escape zone range
    HALF_WAY_RMAX_NEZ = 2,    -- Fire halfway between max and NEZ
    TARGET_THREAT_EST = 3,    -- Based on target threat assessment
    RANDOM_RANGE = 4          -- Random range selection
}
```

##### PROHIBIT_WP_PASS_REPORT

Disables waypoint passage radio calls.

```lua
AI.Option.Air.id.PROHIBIT_WP_PASS_REPORT = 19
-- Value: boolean
```

##### JETT_TANKS_IF_EMPTY

Jettisons external fuel tanks when empty.

```lua
AI.Option.Air.id.JETT_TANKS_IF_EMPTY = 25
-- Value: boolean
```

##### FORCED_ATTACK

Forces AI to continue attack regardless of threats.

```lua
AI.Option.Air.id.FORCED_ATTACK = 26
-- Value: boolean
```

##### PREFER_VERTICAL

AI prefers vertical maneuvering in combat.

```lua
AI.Option.Air.id.PREFER_VERTICAL = 32
-- Value: boolean
```

##### ALLOW_FORMATION_SIDE_SWAP

Allows wingmen to switch formation sides.

```lua
AI.Option.Air.id.ALLOW_FORMATION_SIDE_SWAP = 35
-- Value: boolean
```

#### Ground Options

##### ROE

```lua
AI.Option.Ground.id.ROE = 0

AI.Option.Ground.val.ROE = {
    OPEN_FIRE = 2,
    RETURN_FIRE = 3,
    WEAPON_HOLD = 4
}
```

##### ALARM_STATE

Sets the group's alert level.

```lua
AI.Option.Ground.id.ALARM_STATE = 9

AI.Option.Ground.val.ALARM_STATE = {
    AUTO = 0,                 -- Automatic based on situation
    GREEN = 1,                -- Relaxed, weapons safe
    RED = 2                   -- Combat ready, weapons hot
}
```

```lua
-- Set SAM site to combat ready
local controller = Group.getByName("SA-10"):getController()
controller:setOption(AI.Option.Ground.id.ALARM_STATE, AI.Option.Ground.val.ALARM_STATE.RED)
```

##### DISPERSE_ON_ATTACK

Ground units disperse when attacked.

```lua
AI.Option.Ground.id.DISPERSE_ON_ATTACK = 8
-- Value: boolean
```

##### ENGAGE_AIR_WEAPONS

Controls what types of air targets to engage.

```lua
AI.Option.Ground.id.ENGAGE_AIR_WEAPONS = 20
-- Value: boolean
```

##### AC_ENGAGEMENT_RANGE_RESTRICTION

Limits engagement range for air defense.

```lua
AI.Option.Ground.id.AC_ENGAGEMENT_RANGE_RESTRICTION = 24
-- Value: range as percentage (0-100)
```

##### Evasion of ARM

Controls SAM behavior when targeted by anti-radiation missiles.

```lua
AI.Option.Ground.id.EVASION_OF_ARM = 31
-- Value: boolean (true = shut down radar when ARM detected)
```

#### Naval Options

##### ROE

```lua
AI.Option.Naval.id.ROE = 0

AI.Option.Naval.val.ROE = {
    OPEN_FIRE = 2,
    RETURN_FIRE = 3,
    WEAPON_HOLD = 4
}
```

#### AI Skill Levels

The AI enum also includes skill level constants:

```lua
AI.Skill = {
    PLAYER = "Player",
    CLIENT = "Client",
    AVERAGE = "Average",
    GOOD = "Good",
    HIGH = "High",
    EXCELLENT = "Excellent"
}
```

These are used in unit definitions when spawning groups dynamically.

#### AI Task Enums

Additional enumerators for task parameters:

```lua
AI.Task.AltitudeType = {
    RADIO = "RADIO",          -- Above Ground Level
    BARO = "BARO"             -- Above Mean Sea Level
}

AI.Task.TurnMethod = {
    FLY_OVER_POINT = "Fly Over Point",
    FIN_POINT = "Fin Point"
}

AI.Task.VehicleFormation = {
    VEE = "Vee",
    ECHELON_RIGHT = "EchelonR",
    ECHELON_LEFT = "EchelonL",
    OFF_ROAD = "Off Road",
    RANK = "Rank",
    ON_ROAD = "On Road",
    CONE = "Cone",
    DIAMOND = "Diamond"
}

AI.Task.WaypointType = {
    TAKEOFF = "TakeOff",
    TAKEOFF_PARKING = "TakeOffParking",
    TAKEOFF_PARKING_HOT = "TakeOffParkingHot",
    TURNING_POINT = "Turning Point",
    LAND = "Land"
}
```

## Server Scripting

Server scripting extends beyond mission scripts to provide control over the DCS multiplayer server environment. Server scripts run in a different Lua state than mission scripts and have access to networking functions, player management, and server lifecycle hooks.

### Server Environment Overview

The server scripting environment differs from mission scripting in several key ways:

1. **Separate Lua State**: Server scripts run in the "GUI" or "hooks" environment, distinct from the mission scripting environment.
2. **Persistent Across Missions**: Server scripts can persist data and maintain state across mission changes.
3. **Network Access**: Functions for player management, chat, and server control are available.
4. **Hook System**: Callback functions notify your script of server events.

Server scripts are typically placed in `Saved Games\DCS\Scripts\Hooks\` and are loaded when DCS starts. They register callback functions that the server calls when specific events occur.

### Setting Up Server Hooks

To receive callbacks, create a table with your callback functions and register it:

```lua
-- MyServerScript.lua in Scripts/Hooks/
local myHooks = {}

function myHooks.onPlayerConnect(id)
    -- Handle player connection
    local name = net.get_player_info(id, 'name')
    net.send_chat("Welcome, " .. name .. "!", true)
end

function myHooks.onPlayerDisconnect(id)
    -- Handle player disconnection
end

function myHooks.onMissionLoadEnd()
    -- Mission finished loading
end

-- Register our hooks
DCS.setUserCallbacks(myHooks)
```

### Hooks Reference

Hooks are callback functions that the server invokes when specific events occur. All hooks are optional; implement only the ones you need.

#### Mission Lifecycle Hooks

##### onMissionLoadBegin

```lua
nil hook.onMissionLoadBegin()
```

Fires when the server begins loading a mission. Use this to prepare for mission loading, reset state, or log mission changes.

```lua
function myHooks.onMissionLoadBegin()
    current_mission = DCS.getMissionName()
    env.info("Loading mission: " .. current_mission)
end
```

##### onMissionLoadProgress

```lua
nil hook.onMissionLoadProgress(number progress, string message)
```

Fires periodically during mission loading with progress updates.

**Parameters:**
- `progress` (number): Loading progress as a fraction (0.0 to 1.0).
- `message` (string): Description of current loading stage.

##### onMissionLoadEnd

```lua
nil hook.onMissionLoadEnd()
```

Fires when a server finishes loading a mission. The mission is now ready to run but may not have started yet.

```lua
function myHooks.onMissionLoadEnd()
    current_mission = DCS.getMissionName()
    env.info("Mission loaded: " .. current_mission)
end
```

#### Simulation Lifecycle Hooks

##### onSimulationStart

```lua
nil hook.onSimulationStart()
```

Fires when the simulation begins running. This occurs after mission loading completes and the 3D world becomes active.

##### onSimulationStop

```lua
nil hook.onSimulationStop()
```

Fires when exiting the simulation. This occurs when transitioning from the 3D game world back to the UI.

##### onSimulationPause

```lua
nil hook.onSimulationPause()
```

Fires when the mission is paused. Only relevant for single-player or when the server admin pauses.

##### onSimulationResume

```lua
nil hook.onSimulationResume()
```

Fires when the mission resumes after being paused.

##### onSimulationFrame

```lua
nil hook.onSimulationFrame()
```

Fires every simulation frame. Use sparingly as this can impact performance.

**Gotchas:** This runs very frequently. Avoid expensive operations and do not use for anything that can be done with scheduled functions or events instead.

#### Player Connection Hooks

##### onPlayerTryConnect

```lua
boolean, string hook.onPlayerTryConnect(string addr, string ucid, string name, number playerId)
```

Fires when a player initially attempts to connect to the server. Can be used to allow or deny access before the player fully connects.

**Parameters:**
- `addr` (string): The player's IP address.
- `ucid` (string): The player's unique DCS identifier (persistent across sessions).
- `name` (string): The player's display name.
- `playerId` (number): The ID the player would have if connection succeeds.

**Returns:**
- Return `true` to force allow the player.
- Return `false, "reason"` to reject the player with a message.
- Return nothing to allow other hooks to decide.

**Gotchas:** If any value is returned, other callbacks for this event are ignored. Only return a value when you want to make a definitive allow/deny decision.

```lua
local bannedPlayers = {
    ["abc123ucid"] = true
}

function myHooks.onPlayerTryConnect(addr, ucid, name, id)
    if bannedPlayers[ucid] then
        return false, "You have been banned from this server"
    end
    -- Return nothing to allow connection
end
```

##### onPlayerConnect

```lua
nil hook.onPlayerConnect(number id)
```

Fires when a player successfully connects to the server. The player has passed any connection checks and is now connected but may still be loading.

**Parameters:**
- `id` (number): Unique player identifier for this session.

```lua
local clients = {}

function myHooks.onPlayerConnect(id)
    clients[id] = {
        id = id,
        name = net.get_player_info(id, 'name'),
        ucid = net.get_player_info(id, 'ucid'),
        ip = net.get_player_info(id, 'ipaddr')
    }
end
```

##### onPlayerDisconnect

```lua
nil hook.onPlayerDisconnect(number id)
```

Fires when a player disconnects from the server.

**Parameters:**
- `id` (number): The disconnecting player's ID.

```lua
function myHooks.onPlayerDisconnect(id)
    local name = clients[id] and clients[id].name or "Unknown"
    env.info(name .. " disconnected")
    clients[id] = nil
end
```

#### Player State Hooks

##### onPlayerStart

```lua
nil hook.onPlayerStart(number id)
```

Fires when a player has fully loaded into the simulation and can select a slot. This occurs after `onPlayerConnect` once the player finishes loading.

**Parameters:**
- `id` (number): The player's ID.

```lua
function myHooks.onPlayerStart(id)
    if clients[id] then
        clients[id].inSim = true
    end
end
```

##### onPlayerStop

```lua
nil hook.onPlayerStop(number id)
```

Fires when a player leaves the simulation (returns to spectators or disconnects).

**Parameters:**
- `id` (number): The player's ID.

##### onPlayerChangeSlot

```lua
nil hook.onPlayerChangeSlot(number playerId)
```

Fires when a player successfully moves into a new slot. This only fires for successful slot changes; rejected requests (like denied RIO requests) do not trigger this hook.

**Parameters:**
- `playerId` (number): The player's ID.

```lua
local playerSlots = {}

function myHooks.onPlayerChangeSlot(playerId)
    local playerName = net.get_player_info(playerId, 'name')
    local slot = net.get_player_info(playerId, 'slot')
    playerSlots[playerName] = slot
end
```

##### onPlayerTryChangeSlot

```lua
boolean hook.onPlayerTryChangeSlot(number playerId, number side, number slotId)
```

Fires when a player attempts to change slots. Can allow or deny the change.

**Parameters:**
- `playerId` (number): The player's ID.
- `side` (number): Target coalition (0=spectators, 1=red, 2=blue).
- `slotId` (number): Target slot ID.

**Returns:**
- Return `true` to allow the slot change.
- Return `false` to deny the slot change.
- Return nothing to allow other hooks to decide.

#### Chat Hooks

##### onPlayerTrySendChat

```lua
string hook.onPlayerTrySendChat(number playerId, string message, boolean toAll)
```

Fires when a player attempts to send a chat message. Can modify or block the message.

**Parameters:**
- `playerId` (number): The player sending the message.
- `message` (string): The message content.
- `toAll` (boolean): True if sending to all, false if coalition-only.

**Returns:**
- Return a modified string to change the message.
- Return `""` (empty string) to block the message.
- Return nothing to allow the original message.

```lua
-- Simple profanity filter
local badWords = {"badword1", "badword2"}

function myHooks.onPlayerTrySendChat(playerId, message, toAll)
    for _, word in ipairs(badWords) do
        if string.find(string.lower(message), word) then
            return ""  -- Block the message
        end
    end
    -- Return nothing to allow the message
end
```

#### Game Event Hook

##### onGameEvent

```lua
nil hook.onGameEvent(table eventData)
```

Fires for various game events like kills, crashes, and takeoffs. The event data structure varies by event type.

### net Singleton

The `net` singleton provides network-related functions for player management, chat, and server control. These functions are available in both the server hook environment and the mission scripting environment.

#### net.send_chat

```lua
nil net.send_chat(string message, boolean all)
```

Sends a chat message to the server.

**Parameters:**
- `message` (string): The message to send.
- `all` (boolean): True to send to all players, false for coalition only.

```lua
net.send_chat("Server message: Mission restart in 5 minutes", true)
```

#### net.send_chat_to

```lua
nil net.send_chat_to(number playerId, string message)
```

Sends a private chat message to a specific player.

**Parameters:**
- `playerId` (number): Target player's ID.
- `message` (string): The message to send.

```lua
local function sendPrivateMessage(playerId, message)
    net.send_chat_to(playerId, message)
end
```

#### net.get_player_list

```lua
table net.get_player_list()
```

Returns a table of player IDs currently connected to the server.

**Returns:** Array of player ID numbers.

```lua
local players = net.get_player_list()
for _, playerId in ipairs(players) do
    local name = net.get_player_info(playerId, 'name')
    env.info("Connected: " .. name)
end
```

#### net.get_player_info

```lua
table net.get_player_info(number playerId, string attribute)
```

Returns information about a player. If an attribute is specified, returns only that value; otherwise returns a table of all attributes.

**Parameters:**
- `playerId` (number): The player's ID.
- `attribute` (string): Optional. Specific attribute to return.

**Attributes:**
- `'id'`: Player ID number
- `'name'`: Player display name
- `'side'`: Coalition (0=spectators, 1=red, 2=blue)
- `'slot'`: Current slot ID
- `'ping'`: Network ping in milliseconds
- `'ipaddr'`: IP address (server only)
- `'ucid'`: Unique Client Identifier (server only)

**Returns:** Attribute value or table of all attributes.

```lua
-- Get single attribute
local playerName = net.get_player_info(playerId, 'name')

-- Get all attributes
local info = net.get_player_info(playerId)
env.info("Player: " .. info.name .. " Ping: " .. info.ping .. "ms")
```

**Gotchas:** The `ipaddr` and `ucid` attributes are only available in the server hook environment, not from mission scripts.

#### net.get_my_player_id

```lua
number net.get_my_player_id()
```

Returns the local player's ID. On a server, returns the server's player ID.

**Returns:** Player ID number.

#### net.get_server_id

```lua
number net.get_server_id()
```

Returns the server host's player ID.

**Returns:** Server player ID number.

#### net.kick

```lua
nil net.kick(number playerId, string message)
```

Kicks a player from the server.

**Parameters:**
- `playerId` (number): The player to kick.
- `message` (string): Reason shown to the kicked player.

```lua
net.kick(playerId, "AFK timeout")
```

#### net.get_slot

```lua
number, number net.get_slot(number playerId)
```

Returns the slot information for a player.

**Parameters:**
- `playerId` (number): The player's ID.

**Returns:** side (coalition), slotId.

```lua
local side, slotId = net.get_slot(playerId)
if side == 0 then
    env.info("Player is spectating")
end
```

#### net.force_player_slot

```lua
boolean net.force_player_slot(number playerId, number sideId, number slotId)
```

Forces a player into a specific slot.

**Parameters:**
- `playerId` (number): The player to move.
- `sideId` (number): Target coalition (0=spectators, 1=red, 2=blue).
- `slotId` (number): Target slot ID.

**Returns:** True if successful.

```lua
-- Move player to spectators
net.force_player_slot(playerId, 0, 0)
```

#### net.get_stat

```lua
number net.get_stat(number playerId, number statId)
```

Returns a statistic for a player.

**Parameters:**
- `playerId` (number): The player's ID.
- `statId` (number): Statistic type ID.

**Returns:** Statistic value.

#### net.get_name

```lua
string net.get_name(number playerId)
```

Returns a player's name.

**Parameters:**
- `playerId` (number): The player's ID.

**Returns:** Player name string.

#### net.lua2json

```lua
string net.lua2json(table data)
```

Converts a Lua table to a JSON string.

**Parameters:**
- `data` (table): Lua table to convert.

**Returns:** JSON string representation.

```lua
local data = {name = "Test", value = 42}
local json = net.lua2json(data)
-- json = '{"name":"Test","value":42}'
```

#### net.json2lua

```lua
table net.json2lua(string json)
```

Converts a JSON string to a Lua table.

**Parameters:**
- `json` (string): JSON string to parse.

**Returns:** Lua table.

```lua
local json = '{"name":"Test","value":42}'
local data = net.json2lua(json)
-- data.name = "Test", data.value = 42
```

#### net.dostring_in

```lua
string net.dostring_in(string state, string luaCode)
```

Executes Lua code in a specific game environment. This allows cross-environment communication.

**Parameters:**
- `state` (string): Target Lua environment.
- `luaCode` (string): Lua code to execute.

**States:**
- `'config'`: Configuration state ($INSTALL_DIR/Config/main.cfg environment)
- `'mission'`: Mission scripting environment
- `'export'`: Export API environment ($WRITE_DIR/Scripts/Export.lua)

**Returns:** String result from the executed code.

```lua
-- Execute code in the mission environment from a hook
local result = net.dostring_in('mission', [[
    local count = 0
    for _, group in pairs(coalition.getGroups(2)) do
        count = count + 1
    end
    return tostring(count)
]])
env.info("Blue has " .. result .. " groups")
```

**Gotchas:** The executed code runs as a string, so you must return string values. Use `tostring()` for numbers.

#### net.log

```lua
nil net.log(string message)
```

Writes a message to the DCS log file.

**Parameters:**
- `message` (string): Message to log.

```lua
net.log("Server hook initialized")
```

### DCS Singleton (Server Context)

In the server hook environment, a `DCS` singleton provides additional server-specific functions.

#### DCS.getMissionName

```lua
string DCS.getMissionName()
```

Returns the name of the currently loaded mission.

**Returns:** Mission name string.

```lua
function myHooks.onMissionLoadEnd()
    local missionName = DCS.getMissionName()
    net.send_chat("Mission loaded: " .. missionName, true)
end
```

#### DCS.getMissionFilename

```lua
string DCS.getMissionFilename()
```

Returns the filename of the currently loaded mission.

**Returns:** Mission filename string.

#### DCS.getMissionResult

```lua
table DCS.getMissionResult(number side)
```

Returns mission results for a coalition.

**Parameters:**
- `side` (number): Coalition (1=red, 2=blue).

**Returns:** Table of mission result data.

#### DCS.getUnitProperty

```lua
any DCS.getUnitProperty(number unitId, number propertyId)
```

Returns a property of a unit by ID.

**Parameters:**
- `unitId` (number): Unit ID.
- `propertyId` (number): Property type ID.

**Returns:** Property value.

#### DCS.setUserCallbacks

```lua
nil DCS.setUserCallbacks(table callbacks)
```

Registers a table of callback functions to receive server hooks.

**Parameters:**
- `callbacks` (table): Table with hook functions as members.

```lua
local myHooks = {}

function myHooks.onPlayerConnect(id)
    -- Handle connection
end

DCS.setUserCallbacks(myHooks)
```

### Complete Server Hook Example

Here is a complete example of a server hook script that tracks players, manages chat, and logs events:

```lua
-- MyServerHooks.lua - Place in Saved Games/DCS/Scripts/Hooks/

local serverHooks = {}
local connectedPlayers = {}

-- Mission lifecycle
function serverHooks.onMissionLoadBegin()
    net.log("[MyHooks] Mission loading: " .. DCS.getMissionName())
end

function serverHooks.onMissionLoadEnd()
    net.log("[MyHooks] Mission loaded: " .. DCS.getMissionName())
    net.send_chat("Mission loaded. Welcome to the server!", true)
end

-- Player connection management
function serverHooks.onPlayerTryConnect(addr, ucid, name, playerId)
    net.log("[MyHooks] Connection attempt: " .. name .. " (" .. ucid .. ") from " .. addr)
    -- Return nothing to allow connection
    -- Return false, "reason" to deny
end

function serverHooks.onPlayerConnect(playerId)
    local info = {
        id = playerId,
        name = net.get_player_info(playerId, 'name'),
        ucid = net.get_player_info(playerId, 'ucid'),
        ip = net.get_player_info(playerId, 'ipaddr'),
        connectTime = os.time()
    }
    connectedPlayers[playerId] = info
    net.log("[MyHooks] Player connected: " .. info.name)
end

function serverHooks.onPlayerDisconnect(playerId)
    local info = connectedPlayers[playerId]
    if info then
        local sessionTime = os.time() - info.connectTime
        net.log("[MyHooks] Player disconnected: " .. info.name ..
                " (session: " .. sessionTime .. "s)")
    end
    connectedPlayers[playerId] = nil
end

function serverHooks.onPlayerStart(playerId)
    local info = connectedPlayers[playerId]
    if info then
        info.inSim = true
        net.send_chat("Welcome, " .. info.name .. "!", true)
    end
end

function serverHooks.onPlayerChangeSlot(playerId)
    local name = net.get_player_info(playerId, 'name')
    local side, slot = net.get_slot(playerId)
    local sideName = side == 1 and "Red" or (side == 2 and "Blue" or "Spectators")
    net.log("[MyHooks] " .. name .. " changed to " .. sideName .. " slot " .. slot)
end

-- Chat moderation
function serverHooks.onPlayerTrySendChat(playerId, message, toAll)
    -- Log all chat
    local name = net.get_player_info(playerId, 'name')
    net.log("[Chat] " .. name .. ": " .. message)

    -- Could filter or modify messages here
    -- Return "" to block, return modified string to change
    -- Return nothing to allow original message
end

-- Simulation events
function serverHooks.onSimulationStart()
    net.log("[MyHooks] Simulation started")
end

function serverHooks.onSimulationStop()
    net.log("[MyHooks] Simulation stopped")
end

-- Register our hooks
DCS.setUserCallbacks(serverHooks)
net.log("[MyHooks] Server hooks registered")
```

This script demonstrates the key patterns for server scripting: tracking player state across connection/disconnection, moderating chat, logging events, and responding to mission lifecycle changes.
