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
| [`S_EVENT_SHOT`](#s_event_shot) | A weapon is fired |
| [`S_EVENT_HIT`](#s_event_hit) | An object is struck by a weapon |
| [`S_EVENT_TAKEOFF`](#s_event_takeoff) | An aircraft departs |
| [`S_EVENT_LAND`](#s_event_land) | An aircraft lands |
| [`S_EVENT_RUNWAY_TAKEOFF`](#s_event_runway_takeoff) | An aircraft leaves the ground |
| [`S_EVENT_RUNWAY_TOUCH`](#s_event_runway_touch) | An aircraft touches down |
| [`S_EVENT_CRASH`](#s_event_crash) | An aircraft crashes |
| [`S_EVENT_EJECTION`](#s_event_ejection) | A pilot ejects |
| [`S_EVENT_DEAD`](#s_event_dead) | An object is destroyed |
| [`S_EVENT_BIRTH`](#s_event_birth) | A unit spawns |
| [`S_EVENT_PLAYER_ENTER_UNIT`](#s_event_player_enter_unit) | A player takes control of a unit |
| [`S_EVENT_KILL`](#s_event_kill) | One unit kills another |
| [`S_EVENT_MARK_ADDED`](#s_event_mark_added) | A map marker is created |

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

DCS World simulates a flat earth model using a Transverse Mercator projection for each theater. Each map has its own projection origin point, and the simulation uses a Cartesian coordinate system measured in meters from that origin. This approach trades global accuracy for local precision, which is appropriate for the scale of combat operations depicted in the simulation.

The terrain engine does not provide a one-to-one representation of real-world geography. Maps are composites assembled from multiple time periods and may include features that have been added, removed, or modified to improve gameplay or engine performance. Features like buildings, roads, and vegetation do not necessarily match their real-world counterparts in location, appearance, or presence. Scripts that rely on real-world geographic data should account for these discrepancies.

The native coordinate system uses X, Y, and Z axes measured in meters. The `coord` singleton provides conversion functions between this native system and real-world coordinate systems including latitude/longitude (geodetic coordinates) and MGRS (Military Grid Reference System, based on UTM). These conversions allow scripts to work with familiar geographic coordinates while the engine operates in its internal Cartesian space.

**Vec2** represents a 2D point on the map surface:

```lua
Vec2 = {
    x = number,
    y = number
}
```

The `x` field contains the East-West position, where positive values indicate positions to the East. The `y` field contains the North-South position, where positive values indicate positions to the North.

**Vec3** represents a 3D point in world space:

```lua
Vec3 = {
    x = number,
    y = number,
    z = number
}
```

The `x` field contains the East-West position, where positive values indicate positions to the East. The `y` field contains the altitude, where positive values indicate positions above sea level. The `z` field contains the North-South position, where positive values indicate positions to the North.

Vec2 and Vec3 use different conventions for the "y" axis. In Vec2, `y` is the North-South position. In Vec3, `y` is altitude while `z` is North-South. This difference is a common source of confusion when converting between the two formats.

**Position3** represents both position and orientation in 3D space:

```lua
Position3 = {
    p = Vec3,
    x = Vec3,
    y = Vec3,
    z = Vec3
}
```

The `p` field contains the world position as a Vec3. The `x` field contains the forward unit vector, pointing out of the object's nose. The `y` field contains the up unit vector, pointing out of the object's top. The `z` field contains the right unit vector, pointing out of the object's right side. These orientation vectors form an orthonormal basis. You can calculate heading and pitch from a Position3 value:

```lua
local pos = unit:getPosition()
local heading = math.atan2(pos.x.z, pos.x.x)
local pitch = math.asin(pos.x.y)
```

The heading calculation returns radians where 0 represents North. The pitch calculation returns radians where positive values indicate the nose is pointing up.

#### Time Values

The DCS scripting engine measures mission time in seconds as a floating-point number with millisecond precision. The timer singleton provides time-related functions. The `timer.getTime()` function returns mission time, which is the number of seconds since the mission started and pauses when the game is paused. The `timer.getAbsTime()` function returns absolute time, which is the number of seconds since midnight of the mission date. The `timer.getTime0()` function returns the mission start time expressed as absolute time.

#### Distance and Angles

All distances in the DCS scripting engine are measured in meters. All angles are measured in radians unless otherwise noted. To convert between degrees and radians:

```lua
local radians = degrees * math.pi / 180
local degrees = radians * 180 / math.pi
```

Headings use true north as 0 and increase clockwise: East is π/2, South is π, and West is 3π/2.

#### Country and Coalition

Countries are identified by numeric IDs from the `country.id` enum. The game determines coalition membership based on the country. The three coalitions are represented by the `coalition.side` enum:

```lua
coalition.side = {
    NEUTRAL = 0,
    RED = 1,
    BLUE = 2
}
```

Some functions such as `markupToAll` accept a coalition value of -1, which represents "all coalitions."

### Singletons

Singletons are global objects that provide access to game systems. You call their functions using dot notation (e.g., `timer.getTime()`).

#### timer

The timer singleton provides mission time information and function scheduling.

##### timer.getTime

```lua
number timer.getTime()
```

The `timer.getTime` function returns the mission time in seconds since the mission started. This value pauses when the simulation is paused. The precision is to three decimal places.

**Returns:** The mission time as a number in seconds, such as `65.385`.

```lua
if timer.getTime() > 300 then
    startSecondWave()
end
```

##### timer.getAbsTime

```lua
number timer.getAbsTime()
```

The `timer.getAbsTime` function returns the time of day as seconds since midnight on the mission date. Unlike `timer.getTime`, this value includes the mission start time offset.

**Returns:** The absolute time as a number in seconds since midnight.

```lua
if timer.getAbsTime() > 43200 then
    env.info("It's afternoon")
end
```

##### timer.getTime0

```lua
number timer.getTime0()
```

The `timer.getTime0` function returns the mission's start time as seconds since midnight. This value represents the "start time" configured in the Mission Editor.

**Returns:** The mission start time as absolute time in seconds since midnight.

```lua
local currentTimeOfDay = timer.getTime0() + timer.getTime()
local hours = math.floor(currentTimeOfDay / 3600) % 24
```

##### timer.scheduleFunction

```lua
functionId timer.scheduleFunction(function callback, any argument, number runTime)
```

The `timer.scheduleFunction` function schedules a function to run at a specific mission time. The callback receives the provided argument and the scheduled time as its parameters. If the callback returns a number, the game will reschedule the callback for that mission time. If you schedule a function for a time that has already passed, the game runs it immediately on the next simulation frame.

**Parameters:**
- `callback` (function): The function to call. The function signature is `function(argument, time)`.
- `argument` (any): The value passed to the callback as its first parameter. Use a table to pass multiple values.
- `runTime` (number): The mission time in seconds when the function should run.

**Returns:** A function ID that can be used with `timer.removeFunction` or `timer.setFunctionTime`.

```lua
local function periodicCheck(_, time)
    local aliveCount = countAliveUnits()
    env.info("Alive units: " .. aliveCount)
    return time + 30
end

timer.scheduleFunction(periodicCheck, nil, timer.getTime() + 30)
```

```lua
local function delayedMessage(data, time)
    trigger.action.outText(data.message, data.duration)
end

timer.scheduleFunction(delayedMessage, {message = "5 minutes elapsed!", duration = 10}, timer.getTime() + 300)
```

##### timer.removeFunction

```lua
nil timer.removeFunction(functionId id)
```

The `timer.removeFunction` function removes a scheduled function so it will not run. This function has no effect if the function has already run or was already removed.

**Parameters:**
- `id` (functionId): The ID returned by `timer.scheduleFunction`.

```lua
local funcId = timer.scheduleFunction(myCallback, nil, timer.getTime() + 60)
timer.removeFunction(funcId)
```

##### timer.setFunctionTime

```lua
nil timer.setFunctionTime(functionId id, number newTime)
```

The `timer.setFunctionTime` function changes when a scheduled function will run. This function is useful for delaying or advancing scheduled tasks.

**Parameters:**
- `id` (functionId): The ID returned by `timer.scheduleFunction`.
- `newTime` (number): The new mission time in seconds when the function should run.

```lua
local funcId = timer.scheduleFunction(myCallback, nil, timer.getTime() + 60)
timer.setFunctionTime(funcId, timer.getTime() + 90)
```

#### env

The env singleton provides logging, mission information, and warning systems.

##### env.info

```lua
nil env.info(string message, boolean showMessageBox)
```

The `env.info` function logs an informational message to `dcs.log`. This function is the primary debugging tool for mission scripts.

**Parameters:**
- `message` (string): The message to log.
- `showMessageBox` (boolean): Optional. If true, the function also displays a message box to the user. The default is false.

```lua
env.info("Script initialized successfully")
env.info("Player entered zone: " .. zoneName)
```

##### env.warning

```lua
nil env.warning(string message, boolean showMessageBox)
```

The `env.warning` function logs a warning message to `dcs.log`. Use this function for recoverable issues.

**Parameters:**
- `message` (string): The warning message to log.
- `showMessageBox` (boolean): Optional. If true, the function displays a message box to the user.

```lua
if not targetGroup then
    env.warning("Target group not found, using fallback")
end
```

##### env.error

```lua
nil env.error(string message, boolean showMessageBox)
```

The `env.error` function logs an error message to `dcs.log`. Use this function for serious problems that may affect mission functionality.

**Parameters:**
- `message` (string): The error message to log.
- `showMessageBox` (boolean): Optional. If true, the function displays a message box to the user.

```lua
if not requiredUnit then
    env.error("Critical unit missing - mission may not function correctly")
end
```

##### env.setErrorMessageBoxEnabled

```lua
nil env.setErrorMessageBoxEnabled(boolean enabled)
```

The `env.setErrorMessageBoxEnabled` function enables or disables the error message box that appears when script errors occur.

**Parameters:**
- `enabled` (boolean): Set to true to show error dialogs, or false to suppress them.

```lua
env.setErrorMessageBoxEnabled(false)
```

##### env.getValueDictByKey

```lua
string env.getValueDictByKey(string key)
```

The `env.getValueDictByKey` function returns a localized string from the mission's dictionary. This function is used for internationalization.

**Parameters:**
- `key` (string): The dictionary key to look up.

**Returns:** The localized string value, or the key itself if the key is not found.

##### env.mission

The `env.mission` field is a table containing the complete mission data as loaded from the MIZ file. This table includes all groups, units, triggers, and other mission elements in their raw format.

```lua
local startTime = env.mission.start_time

for coalitionName, coalitionData in pairs(env.mission.coalition) do
    env.info("Coalition: " .. coalitionName)
end
```

#### trigger

The trigger singleton provides access to trigger zones, user flags, and trigger-style actions like messages, smoke, and explosions. The singleton is divided into two sub-tables: `trigger.action` for actions and `trigger.misc` for utilities.

##### trigger.action.outText

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

##### trigger.action.outTextForCoalition

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

##### trigger.action.outTextForGroup

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

##### trigger.action.outTextForUnit

```lua
nil trigger.action.outTextForUnit(number unitId, string text, number displayTime, boolean clearView)
```

The `trigger.action.outTextForUnit` function displays a message only to a specific player unit.

**Parameters:**
- `unitId` (number): The unit's numeric ID. Call `unit:getID()` on a Unit object to obtain this value.
- `text` (string): The message to display.
- `displayTime` (number): The duration in seconds that the message remains visible.
- `clearView` (boolean): Optional. If true, the function clears other messages before displaying this one.

##### trigger.action.smoke

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

##### trigger.action.effectSmokeBig

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

##### trigger.action.illuminationBomb

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

##### trigger.action.signalFlare

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

##### trigger.action.explosion

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

##### trigger.action.setUserFlag

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

##### trigger.misc.getUserFlag

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

##### trigger.misc.getZone

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

#### world

The world singleton provides event handling and object searching capabilities. See the Events section for event handling details.

##### world.addEventHandler

```lua
nil world.addEventHandler(table handler)
```

The `world.addEventHandler` function registers an event handler to receive game events. The handler must be a table with an `onEvent` function.

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

The `world.removeEventHandler` function unregisters a previously registered event handler.

**Parameters:**
- `handler` (table): The same handler table that was passed to `world.addEventHandler`.

##### world.getPlayer

```lua
Unit world.getPlayer()
```

The `world.getPlayer` function returns the player's unit in single-player missions. This function only works in single-player; in multiplayer, use `coalition.getPlayers()` instead.

**Returns:** The player's Unit object, or nil in multiplayer.

##### world.getAirbases

```lua
table world.getAirbases(number coalitionId)
```

The `world.getAirbases` function returns all airbases belonging to a coalition. The returned list includes airports, FARPs, and carrier ships.

**Parameters:**
- `coalitionId` (number): Optional. If provided, the function returns only airbases for that coalition.

**Returns:** An array of Airbase objects.

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

The `world.searchObjects` function searches for objects within a 3D volume and calls a handler function for each object found.

**Parameters:**
- `objectCategory` (number): The category of objects to search for, from the `Object.Category` enum. Valid values are UNIT, WEAPON, STATIC, BASE, SCENERY, and CARGO.
- `searchVolume` (table): A table that defines the search area. The table must have an `id` field specifying the volume type and a `params` field containing the volume parameters.
- `handler` (function): A function called for each found object. Return true from the handler to continue searching, or false to stop.

The `world.VolumeType` enum defines the available volume types:

```lua
world.VolumeType = {
    SEGMENT = 0,
    BOX = 1,
    SPHERE = 2,
    PYRAMID = 3
}
```

```lua
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
    return true
end)
```

##### world.removeJunk

```lua
number world.removeJunk(table searchVolume)
```

The `world.removeJunk` function removes debris and wreckage within a volume.

**Parameters:**
- `searchVolume` (table): The area to clear. This table uses the same format as the `searchVolume` parameter of `world.searchObjects`.

**Returns:** The number of objects removed.

```lua
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

The `world.getMarkPanels` function returns all map markers currently visible.

**Returns:** An array of marker tables. Each marker table contains the following fields: `idx` (the marker ID), `time` (the creation time), `initiator` (the Unit that created the marker), `coalition` (the coalition the marker is visible to, or -1 for all coalitions), `groupID` (the group the marker is visible to, or -1 for all groups), `text` (the marker text), and `pos` (the marker position as a Vec3).

#### coalition

The coalition singleton provides functions to query and spawn groups and static objects.

##### coalition.addGroup

```lua
Group coalition.addGroup(number countryId, number groupCategory, table groupData)
```

The `coalition.addGroup` function dynamically spawns a group into the mission. This function is one of the most powerful scripting functions, enabling dynamic spawning of any unit type.

You must add a delay before accessing the group's controller after spawning, because issuing tasks immediately can crash the game. If a group or unit name matches an existing object, the game destroys the existing object. You cannot spawn aircraft with skill "Client" but can use "Player" in single-player, which destroys the current player aircraft. Spawn FARPs with `groupCategory = -1`.

**Parameters:**
- `countryId` (number): The country ID from the `country.id` enum.
- `groupCategory` (number): The category from `Group.Category`. Valid values are AIRPLANE, HELICOPTER, GROUND, SHIP, and TRAIN.
- `groupData` (table): The complete group definition. See the structure below.

**Returns:** The spawned Group object.

The `groupData` table has the following structure:

```lua
groupData = {
    name = string,
    task = string,
    units = {
        [1] = {
            name = string,
            type = string,
            x = number,
            y = number,
            alt = number,
            alt_type = string,
            speed = number,
            payload = table,
            callsign = table
        },
    },
    groupId = number,
    start_time = number,
    lateActivation = boolean,
    hidden = boolean,
    hiddenOnMFD = boolean,
    route = table,
    uncontrolled = boolean,
}
```

The required fields are `name` (a unique group name), `task` (the main task such as "Ground Nothing", "CAP", or "CAS"), and `units` (an array of unit definitions). Each unit definition requires `name` (a unique unit name), `type` (the unit type such as "M1A2" or "F-16C_50"), `x` (the East-West position), and `y` (the North-South position using Vec2 convention). Aircraft also require `alt` (altitude in meters), `alt_type` ("BARO" or "RADIO"), `speed` (speed in m/s), `payload` (weapons and fuel), and `callsign` (a table with name_index, number, and flight_number).

The optional fields are `groupId` (a custom group ID that is auto-generated if omitted), `start_time` (spawn delay in seconds where 0 means immediate), `lateActivation` (whether to require a trigger to activate), `hidden` (whether to hide from the F10 map), `hiddenOnMFD` (whether to hide from aircraft MFDs), `route` (waypoints and tasks), and `uncontrolled` (for aircraft, whether to spawn inactive).

```lua
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

timer.scheduleFunction(function()
    local controller = newGroup:getController()
end, nil, timer.getTime() + 1)
```

##### coalition.addStaticObject

```lua
StaticObject coalition.addStaticObject(number countryId, table staticData)
```

The `coalition.addStaticObject` function spawns a static object into the mission.

**Parameters:**
- `countryId` (number): The country ID from the `country.id` enum.
- `staticData` (table): The static object definition.

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

The `coalition.getGroups` function returns all groups belonging to a coalition.

**Parameters:**
- `coalitionId` (number): The coalition from `coalition.side`.
- `groupCategory` (number): Optional. If provided, the function filters the results by `Group.Category`.

**Returns:** An array of Group objects.

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

The `coalition.getStaticObjects` function returns all static objects belonging to a coalition.

**Parameters:**
- `coalitionId` (number): The coalition from `coalition.side`.

**Returns:** An array of StaticObject objects.

##### coalition.getPlayers

```lua
table coalition.getPlayers(number coalitionId)
```

The `coalition.getPlayers` function returns all human player units in a coalition.

**Parameters:**
- `coalitionId` (number): The coalition from `coalition.side`.

**Returns:** An array of Unit objects containing only player-controlled units.

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

The `coalition.getAirbases` function returns all airbases belonging to a coalition.

**Parameters:**
- `coalitionId` (number): The coalition from `coalition.side`.

**Returns:** An array of Airbase objects.

##### coalition.getServiceProviders

```lua
table coalition.getServiceProviders(number coalitionId, number serviceType)
```

The `coalition.getServiceProviders` function returns groups providing a specific service.

**Parameters:**
- `coalitionId` (number): The coalition from `coalition.side`.
- `serviceType` (number): The service type from the `coalition.service` enum. Valid values are ATC (0), AWACS (1), TANKER (2), and FAC (3).

**Returns:** An array of Group objects providing the specified service.

```lua
local tankers = coalition.getServiceProviders(coalition.side.BLUE, coalition.service.TANKER)
```

##### coalition.addRefPoint

```lua
nil coalition.addRefPoint(number coalitionId, table refPoint)
```

The `coalition.addRefPoint` function adds a reference point (such as a bullseye or custom waypoint) for a coalition.

**Parameters:**
- `coalitionId` (number): The coalition from `coalition.side`.
- `refPoint` (table): The reference point definition. This table must contain a `callsign` field (a string) and a `point` field (a Vec3).

##### coalition.getRefPoints

```lua
table coalition.getRefPoints(number coalitionId)
```

The `coalition.getRefPoints` function returns all reference points for a coalition.

**Parameters:**
- `coalitionId` (number): The coalition from `coalition.side`.

**Returns:** A table of reference points indexed by callsign.

##### coalition.getMainRefPoint

```lua
Vec3 coalition.getMainRefPoint(number coalitionId)
```

The `coalition.getMainRefPoint` function returns the main bullseye position for a coalition.

**Parameters:**
- `coalitionId` (number): The coalition from `coalition.side`.

**Returns:** The bullseye position as a Vec3.

```lua
local bullseye = coalition.getMainRefPoint(coalition.side.BLUE)
env.info("Blue bullseye at: " .. bullseye.x .. ", " .. bullseye.z)
```

##### coalition.getCountryCoalition

```lua
number coalition.getCountryCoalition(number countryId)
```

The `coalition.getCountryCoalition` function returns which coalition a country belongs to.

**Parameters:**
- `countryId` (number): The country ID from the `country.id` enum.

**Returns:** The coalition from `coalition.side`.

#### missionCommands

The missionCommands singleton allows you to add and remove entries in the F10 "Other" radio menu.

##### missionCommands.addCommand

```lua
table missionCommands.addCommand(string name, table path, function handler, any argument)
```

The `missionCommands.addCommand` function adds a command to the F10 menu that all players can see and use.

**Parameters:**
- `name` (string): The menu item text.
- `path` (table): The parent menu path. Pass nil to add the command to the root menu.
- `handler` (function): The function called when the player selects the command.
- `argument` (any): The value passed to the handler function.

**Returns:** A path table identifying this command. Use this value with `missionCommands.removeItem` to remove the command later.

```lua
missionCommands.addCommand("Request SITREP", nil, function()
    trigger.action.outText("All objectives intact", 10)
end)

local supportMenu = missionCommands.addSubMenu("Support", nil)
missionCommands.addCommand("Call Artillery", supportMenu, function()
    fireArtillery()
end)
```

##### missionCommands.addSubMenu

```lua
table missionCommands.addSubMenu(string name, table path)
```

The `missionCommands.addSubMenu` function adds a submenu to the F10 menu.

**Parameters:**
- `name` (string): The submenu text.
- `path` (table): The parent menu path. Pass nil to add the submenu to the root menu.

**Returns:** A path table for this submenu. Use this value as the `path` parameter when adding child items.

```lua
local mainMenu = missionCommands.addSubMenu("Mission Control", nil)
local airMenu = missionCommands.addSubMenu("Air Support", mainMenu)
missionCommands.addCommand("CAS Strike", airMenu, performCAS)
```

##### missionCommands.removeItem

```lua
nil missionCommands.removeItem(table path)
```

The `missionCommands.removeItem` function removes a command or submenu from the F10 menu.

**Parameters:**
- `path` (table): The path table returned by `missionCommands.addCommand` or `missionCommands.addSubMenu`.

##### missionCommands.addCommandForCoalition

```lua
table missionCommands.addCommandForCoalition(number coalitionId, string name, table path, function handler, any argument)
```

The `missionCommands.addCommandForCoalition` function adds a command visible only to players of a specific coalition.

**Parameters:**
- `coalitionId` (number): The coalition from `coalition.side`.
- `name` (string): The menu item text.
- `path` (table): The parent menu path. Pass nil to add the command to the root menu.
- `handler` (function): The function called when the player selects the command.
- `argument` (any): The value passed to the handler function.

**Returns:** A path table for this command.

##### missionCommands.addSubMenuForCoalition

```lua
table missionCommands.addSubMenuForCoalition(number coalitionId, string name, table path)
```

The `missionCommands.addSubMenuForCoalition` function adds a submenu visible only to players of a specific coalition.

**Parameters:**
- `coalitionId` (number): The coalition from `coalition.side`.
- `name` (string): The submenu text.
- `path` (table): The parent menu path. Pass nil to add the submenu to the root menu.

**Returns:** A path table for this submenu.

##### missionCommands.removeItemForCoalition

```lua
nil missionCommands.removeItemForCoalition(number coalitionId, table path)
```

The `missionCommands.removeItemForCoalition` function removes a coalition-specific menu item.

**Parameters:**
- `coalitionId` (number): The coalition from `coalition.side`.
- `path` (table): The path table returned when the item was created.

##### missionCommands.addCommandForGroup

```lua
table missionCommands.addCommandForGroup(number groupId, string name, table path, function handler, any argument)
```

The `missionCommands.addCommandForGroup` function adds a command visible only to players in a specific group. This function is the most common way to create player-specific menus.

**Parameters:**
- `groupId` (number): The group's numeric ID. Call `group:getID()` on a Group object to obtain this value.
- `name` (string): The menu item text.
- `path` (table): The parent menu path. Pass nil to add the command to the root menu.
- `handler` (function): The function called when the player selects the command.
- `argument` (any): The value passed to the handler function.

**Returns:** A path table for this command.

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

The `missionCommands.addSubMenuForGroup` function adds a submenu visible only to players in a specific group.

**Parameters:**
- `groupId` (number): The group's numeric ID. Call `group:getID()` on a Group object to obtain this value.
- `name` (string): The submenu text.
- `path` (table): The parent menu path. Pass nil to add the submenu to the root menu.

**Returns:** A path table for this submenu.

##### missionCommands.removeItemForGroup

```lua
nil missionCommands.removeItemForGroup(number groupId, table path)
```

The `missionCommands.removeItemForGroup` function removes a group-specific menu item.

**Parameters:**
- `groupId` (number): The group's numeric ID.
- `path` (table): The path table returned when the item was created.

#### coord

The coord singleton provides coordinate conversion between the game's internal XYZ system, Latitude/Longitude, and MGRS.

##### coord.LLtoLO

```lua
number, number, number coord.LLtoLO(number latitude, number longitude, number altitude)
```

The `coord.LLtoLO` function converts Latitude/Longitude/Altitude to the game's XYZ coordinate system.

**Parameters:**
- `latitude` (number): The latitude in decimal degrees, where positive values indicate North.
- `longitude` (number): The longitude in decimal degrees, where positive values indicate East.
- `altitude` (number): The altitude in meters above mean sea level.

**Returns:** Three numbers representing the x, y, and z game coordinates, where y is altitude.

```lua
local x, y, z = coord.LLtoLO(41.657, 41.597, 0)
local position = {x = x, y = y, z = z}
```

##### coord.LOtoLL

```lua
number, number, number coord.LOtoLL(number x, number y, number z)
```

The `coord.LOtoLL` function converts game XYZ coordinates to Latitude/Longitude/Altitude.

**Parameters:**
- `x` (number): The X coordinate representing the East-West position.
- `y` (number): The Y coordinate representing altitude.
- `z` (number): The Z coordinate representing the North-South position.

**Returns:** Three numbers representing the latitude, longitude, and altitude.

```lua
local pos = unit:getPoint()
local lat, lon, alt = coord.LOtoLL(pos.x, pos.y, pos.z)
env.info(string.format("Position: %.4f, %.4f", lat, lon))
```

##### coord.LLtoMGRS

```lua
table coord.LLtoMGRS(number latitude, number longitude)
```

The `coord.LLtoMGRS` function converts Latitude/Longitude to MGRS (Military Grid Reference System).

**Parameters:**
- `latitude` (number): The latitude in decimal degrees.
- `longitude` (number): The longitude in decimal degrees.

**Returns:** An MGRS table with the following fields: `UTMZone`, `MGRSDigraph`, `Easting`, and `Northing`.

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

The `coord.MGRStoLL` function converts MGRS coordinates to Latitude/Longitude.

**Parameters:**
- `mgrs` (table): An MGRS table with the following fields: `UTMZone`, `MGRSDigraph`, `Easting`, and `Northing`.

**Returns:** Two numbers representing the latitude and longitude.

#### land

The land singleton provides terrain information and pathfinding.

##### land.getHeight

```lua
number land.getHeight(Vec2 position)
```

The `land.getHeight` function returns the terrain height at a position.

**Parameters:**
- `position` (Vec2): A table with x and y coordinates.

**Returns:** The height in meters above sea level.

```lua
local height = land.getHeight({x = 100000, y = 200000})
```

##### land.getSurfaceHeightWithSeabed

```lua
number land.getSurfaceHeightWithSeabed(Vec2 position)
```

The `land.getSurfaceHeightWithSeabed` function returns the height including the seabed. This function returns negative values for underwater terrain.

**Parameters:**
- `position` (Vec2): A table with x and y coordinates.

**Returns:** The height in meters, where negative values indicate the seabed.

##### land.getSurfaceType

```lua
number land.getSurfaceType(Vec2 position)
```

The `land.getSurfaceType` function returns the surface type at a position.

**Parameters:**
- `position` (Vec2): A table with x and y coordinates.

**Returns:** A surface type enum value from `land.SurfaceType`.

The `land.SurfaceType` enum defines the available surface types:

```lua
land.SurfaceType = {
    LAND = 1,
    SHALLOW_WATER = 2,
    WATER = 3,
    ROAD = 4,
    RUNWAY = 5
}
```

The RUNWAY value also includes taxiways and ramps.

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

The `land.isVisible` function checks if there is line-of-sight between two points. This function only considers terrain and ignores objects.

**Parameters:**
- `origin` (Vec3): The starting position.
- `destination` (Vec3): The target position.

**Returns:** True if the destination is visible from the origin, or false if terrain blocks the view.

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

The `land.getIP` function performs a ray cast and returns the intersection point with terrain. The direction parameter is a vector, not angles; use unit vectors from `getPosition()`.

**Parameters:**
- `origin` (Vec3): The starting position for the ray.
- `direction` (Vec3): The direction vector. The function normalizes this vector.
- `distance` (number): The maximum ray distance in meters.

**Returns:** The intersection point as a Vec3, or nil if there is no intersection within the specified distance.

```lua
local pos = aircraft:getPosition()
local impactPoint = land.getIP(pos.p, pos.x, 20000)
if impactPoint then
    env.info("Looking at ground point: " .. impactPoint.x .. ", " .. impactPoint.z)
end
```

##### land.profile

```lua
table land.profile(Vec2 start, Vec2 finish)
```

The `land.profile` function returns terrain heights along a path between two points.

**Parameters:**
- `start` (Vec2): The starting position.
- `finish` (Vec2): The ending position.

**Returns:** An array of Vec3 points along the terrain profile.

##### land.getClosestPointOnRoads

```lua
number, number land.getClosestPointOnRoads(string roadType, number x, number y)
```

The `land.getClosestPointOnRoads` function finds the nearest point on a road network.

**Parameters:**
- `roadType` (string): The type of road network. Valid values are "roads" or "railroads".
- `x` (number): The X coordinate.
- `y` (number): The Y coordinate using Vec2 convention.

**Returns:** The x and y coordinates of the nearest road point.

```lua
local roadX, roadY = land.getClosestPointOnRoads("roads", unitPos.x, unitPos.z)
```

##### land.findPathOnRoads

```lua
table land.findPathOnRoads(string roadType, number x1, number y1, number x2, number y2)
```

The `land.findPathOnRoads` function finds a path along roads between two points.

**Parameters:**
- `roadType` (string): The type of road network. Valid values are "roads" or "railroads".
- `x1` (number): The starting X coordinate.
- `y1` (number): The starting Y coordinate.
- `x2` (number): The ending X coordinate.
- `y2` (number): The ending Y coordinate.

**Returns:** An array of Vec2 waypoints along the road.

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

The `atmosphere.getWind` function returns the wind vector at a position without including turbulence effects. The returned vector indicates the direction the wind is blowing to, not from.

**Parameters:**
- `position` (Vec3): The world position to query.

**Returns:** A Vec3 wind vector in meters per second.

```lua
local windVec = atmosphere.getWind(unit:getPoint())
local windSpeed = math.sqrt(windVec.x^2 + windVec.z^2)
local windHeading = math.atan2(windVec.z, windVec.x)
```

##### atmosphere.getWindWithTurbulence

```lua
Vec3 atmosphere.getWindWithTurbulence(Vec3 position)
```

The `atmosphere.getWindWithTurbulence` function returns the wind vector including turbulence effects.

**Parameters:**
- `position` (Vec3): The world position to query.

**Returns:** A Vec3 wind vector in meters per second.

##### atmosphere.getTemperatureAndPressure

```lua
number, number atmosphere.getTemperatureAndPressure(Vec3 position)
```

The `atmosphere.getTemperatureAndPressure` function returns atmospheric conditions at a position.

**Parameters:**
- `position` (Vec3): The world position to query.

**Returns:** Two numbers representing the temperature in Kelvin and the pressure in Pascals.

```lua
local temp, pressure = atmosphere.getTemperatureAndPressure(unit:getPoint())
local tempC = temp - 273.15
local pressureHPa = pressure / 100
```

### Classes

Classes represent game objects like units, groups, and airbases. You call their methods using colon notation (such as `unit:getName()`). You obtain objects through static functions, other objects, or events.

#### Object

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

##### Object.isExist

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

##### Object.destroy

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

##### Object.getCategory

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

##### Object.getTypeName

```lua
string object:getTypeName()
```

The `object:getTypeName` method returns the object's type name as used in the mission file, such as "F-16C_50" or "SA-11 Buk LN 9A310M1".

**Returns:** The type name as a string.

```lua
local typeName = unit:getTypeName()
env.info("Unit type: " .. typeName)
```

##### Object.getDesc

```lua
table object:getDesc()
```

The `object:getDesc` method returns a description table with detailed information about the object type. The contents of the table vary by object type.

**Returns:** A description table that contains at minimum the `life` and `box` fields.

```lua
local desc = unit:getDesc()
env.info("Max life: " .. desc.life)
```

##### Object.hasAttribute

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

##### Object.getName

```lua
string object:getName()
```

The `object:getName` method returns the object's unique name as defined in the Mission Editor.

**Returns:** The object name as a string.

```lua
local name = unit:getName()
trigger.action.outText(name .. " has been spotted", 10)
```

##### Object.getPoint

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

##### Object.getPosition

```lua
Position3 object:getPosition()
```

The `object:getPosition` method returns the object's position and orientation.

**Returns:** A Position3 table with `p` (the position) and `x`, `y`, `z` (the orientation vectors).

```lua
local pos = unit:getPosition()
local heading = math.atan2(pos.x.z, pos.x.x)
```

##### Object.getVelocity

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

##### Object.inAir

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

#### CoalitionObject

The CoalitionObject class extends Object with coalition and country information. This class is the base class for Unit, Weapon, StaticObject, and Airbase.

##### CoalitionObject.getCoalition

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

##### CoalitionObject.getCountry

```lua
number object:getCountry()
```

The `object:getCountry` method returns the object's country.

**Returns:** A country ID from the `country.id` enum.

```lua
local countryId = unit:getCountry()
```

#### Unit

The Unit class represents controllable units: aircraft, helicopters, ground vehicles, ships, and armed structures. This class inherits from Object and CoalitionObject.

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

##### Unit.getByName

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

##### Unit.isActive

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

##### Unit.getPlayerName

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

##### Unit.getID

```lua
number unit:getID()
```

The `unit:getID` method returns the unit's unique numeric ID.

**Returns:** The unit ID as a number.

##### Unit.getNumber

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

##### Unit.getGroup

```lua
Group unit:getGroup()
```

The `unit:getGroup` method returns the group this unit belongs to.

**Returns:** A Group object.

```lua
local group = unit:getGroup()
local groupName = group:getName()
```

##### Unit.getCallsign

```lua
string unit:getCallsign()
```

The `unit:getCallsign` method returns the unit's callsign.

**Returns:** The callsign as a string, such as "Enfield11".

```lua
local callsign = unit:getCallsign()
trigger.action.outText(callsign .. ", cleared hot", 5)
```

##### Unit.getLife

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

##### Unit.getLife0

```lua
number unit:getLife0()
```

The `unit:getLife0` method returns the unit's initial (maximum) hit points.

**Returns:** The initial hit points as a number.

##### Unit.getFuel

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

##### Unit.getAmmo

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

##### Unit.getController

```lua
Controller unit:getController()
```

The `unit:getController` method returns the unit's AI controller. For aircraft, you can control individual units. For ground and ship units, use the group controller instead.

**Returns:** A Controller object.

```lua
local controller = unit:getController()
controller:setOption(AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.WEAPON_FREE)
```

##### Unit.getSensors

```lua
table unit:getSensors()
```

The `unit:getSensors` method returns information about the unit's sensors, such as radar and IRST.

**Returns:** A table of sensor information.

##### Unit.getRadar

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

##### Unit.enableEmission

```lua
nil unit:enableEmission(boolean enable)
```

The `unit:enableEmission` method enables or disables radar and radio emissions for the unit.

**Parameters:**
- `enable` (boolean): Set to true to enable emissions, or false to disable.

```lua
unit:enableEmission(false)
```

#### Group

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

##### Group.getByName

```lua
Group Group.getByName(string name)
```

The `Group.getByName` function is a static function that returns a group by its Mission Editor name.

**Parameters:**
- `name` (string): The group's name as defined in the Mission Editor.

**Returns:** A Group object, or nil if the group is not found.

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

The `group:isExist` method returns whether the group exists. Groups cease to exist when all units are destroyed.

**Returns:** True if at least one unit is alive, or false otherwise.

##### Group.activate

```lua
nil group:activate()
```

The `group:activate` method activates a late-activation group, causing it to spawn and begin its mission.

```lua
local reinforcements = Group.getByName("Reinforcements")
reinforcements:activate()
```

##### Group.destroy

```lua
nil group:destroy()
```

The `group:destroy` method destroys the entire group, removing all units.

##### Group.getCategory

```lua
number group:getCategory()
```

The `group:getCategory` method returns the group category.

**Returns:** A category value from `Group.Category`.

##### Group.getCoalition

```lua
number group:getCoalition()
```

The `group:getCoalition` method returns the group's coalition.

**Returns:** A coalition value from `coalition.side`.

##### Group.getName

```lua
string group:getName()
```

The `group:getName` method returns the group's name.

**Returns:** The group name as a string.

##### Group.getID

```lua
number group:getID()
```

The `group:getID` method returns the group's unique numeric ID. This ID is used for group-specific menu commands and messages.

**Returns:** The group ID as a number.

```lua
local groupId = group:getID()
missionCommands.addCommandForGroup(groupId, "Request Support", nil, requestSupport)
```

##### Group.getUnit

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

##### Group.getUnits

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

##### Group.getSize

```lua
number group:getSize()
```

The `group:getSize` method returns the number of units currently alive in the group.

**Returns:** The current unit count as a number.

##### Group.getInitialSize

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

##### Group.getController

```lua
Controller group:getController()
```

The `group:getController` method returns the group's AI controller. This method is the primary way to control AI behavior.

**Returns:** A Controller object.

```lua
local controller = group:getController()
controller:setTask(orbitTask)
```

##### Group.enableEmission

```lua
nil group:enableEmission(boolean enable)
```

The `group:enableEmission` method enables or disables radar and radio emissions for all units in the group.

**Parameters:**
- `enable` (boolean): Set to true to enable emissions, or false to disable.

#### Airbase

The Airbase class represents airports, FARPs (Forward Arming and Refueling Points), and ships with flight decks. This class inherits from Object and CoalitionObject.

You can obtain Airbase objects using `Airbase.getByName("name")` to get an airbase by name, `coalition.getAirbases(coalitionId)` to get all airbases for a coalition, or `world.getAirbases()` to get all airbases in the mission.

The `Airbase.Category` enum defines the airbase categories:

```lua
Airbase.Category = {
    AIRDROME = 0,
    HELIPAD = 1,
    SHIP = 2
}
```

The `airbase:getCategory()` method returns `Object.Category.BASE`. Use `airbase:getDesc().category` to get a value from `Airbase.Category`.

##### Airbase.getByName

```lua
Airbase Airbase.getByName(string name)
```

The `Airbase.getByName` function is a static function that returns an airbase by name.

**Parameters:**
- `name` (string): The airbase name, such as "Batumi" or "CVN-74 John C. Stennis".

**Returns:** An Airbase object, or nil if the airbase is not found.

```lua
local batumi = Airbase.getByName("Batumi")
local pos = batumi:getPoint()
```

##### Airbase.getCallsign

```lua
string airbase:getCallsign()
```

The `airbase:getCallsign` method returns the airbase's radio callsign.

**Returns:** The callsign as a string.

##### Airbase.getUnit

```lua
Unit airbase:getUnit(number index)
```

The `airbase:getUnit` method returns the ship unit for ship-based airbases.

**Parameters:**
- `index` (number): The unit index, typically 1.

**Returns:** A Unit object for ships, or nil for ground airbases.

##### Airbase.getParking

```lua
table airbase:getParking(boolean available)
```

The `airbase:getParking` method returns parking spot information.

**Parameters:**
- `available` (boolean): Optional. If true, the method returns only unoccupied spots.

**Returns:** An array of parking spot tables. Each table contains fields such as `Term_Index`, `vTerminalPos`, `fDistToRW`, and `Term_Type`.

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

The `airbase:getRunways` method returns runway information.

**Returns:** An array of runway tables containing heading, length, and position data.

##### Airbase.getRadioSilentMode

```lua
boolean airbase:getRadioSilentMode()
```

The `airbase:getRadioSilentMode` method returns whether the airbase's radio is silenced.

**Returns:** True if the radio is silent, or false otherwise.

##### Airbase.setRadioSilentMode

```lua
nil airbase:setRadioSilentMode(boolean silent)
```

The `airbase:setRadioSilentMode` method enables or disables the airbase's radio.

**Parameters:**
- `silent` (boolean): Set to true to silence the radio, or false to enable it.

##### Airbase.setCoalition

```lua
nil airbase:setCoalition(number coalitionId)
```

The `airbase:setCoalition` method changes the airbase's coalition, effectively capturing it.

**Parameters:**
- `coalitionId` (number): The new coalition from `coalition.side`.

```lua
airbase:setCoalition(coalition.side.BLUE)
```

##### Airbase.autoCapture

```lua
nil airbase:autoCapture(boolean enable)
```

The `airbase:autoCapture` method enables or disables automatic capture when ground forces are nearby.

**Parameters:**
- `enable` (boolean): Set to true to enable auto-capture, or false to disable.

##### Airbase.autoCaptureIsOn

```lua
boolean airbase:autoCaptureIsOn()
```

The `airbase:autoCaptureIsOn` method returns whether auto-capture is enabled.

**Returns:** True if auto-capture is on, or false otherwise.

##### Airbase.getWarehouse

```lua
Warehouse airbase:getWarehouse()
```

The `airbase:getWarehouse` method returns the airbase's warehouse (logistics) object.

**Returns:** A Warehouse object.

#### StaticObject

The StaticObject class represents non-moving objects placed in the mission, such as buildings, cargo, and decorations. This class inherits from Object and CoalitionObject.

You can obtain StaticObject objects using `StaticObject.getByName("name")` to get a static object by name, or `coalition.getStaticObjects(coalitionId)` to get all static objects for a coalition.

##### StaticObject.getByName

```lua
StaticObject StaticObject.getByName(string name)
```

The `StaticObject.getByName` function is a static function that returns a static object by name.

**Parameters:**
- `name` (string): The object's name as defined in the Mission Editor.

**Returns:** A StaticObject, or nil if the object is not found.

##### StaticObject.getLife

```lua
number staticObject:getLife()
```

The `staticObject:getLife` method returns the object's current hit points.

**Returns:** The current hit points as a number.

#### Weapon

The Weapon class represents a weapon in flight: missiles, bombs, rockets, and shells. This class inherits from Object and CoalitionObject. You obtain Weapon objects through events.

The `Weapon.Category` enum defines the weapon categories:

```lua
Weapon.Category = {
    SHELL = 0,
    MISSILE = 1,
    ROCKET = 2,
    BOMB = 3
}
```

The `Weapon.GuidanceType` enum defines the guidance types:

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

The `weapon:getCategory()` method returns `Object.Category.WEAPON`. Use `weapon:getDesc().category` to get a value from `Weapon.Category`.

##### Weapon.getLauncher

```lua
Unit weapon:getLauncher()
```

The `weapon:getLauncher` method returns the unit that fired this weapon.

**Returns:** A Unit object, or nil.

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

The `weapon:getTarget` method returns the weapon's target.

**Returns:** The target Object, or nil for unguided weapons.

#### Controller

The Controller class is the AI control interface. You obtain controllers from groups or units and use them to issue tasks, commands, and options.

The `Controller.Detection` enum defines the detection types:

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

The `controller:setTask` method sets the group's main task, replacing any existing task. For newly spawned groups, add a delay before setting tasks to avoid crashes.

**Parameters:**
- `task` (table): The task definition table.

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

The `controller:pushTask` method adds a task to the front of the task queue. The current task is suspended until the new task completes.

**Parameters:**
- `task` (table): The task definition table.

##### Controller.popTask

```lua
nil controller:popTask()
```

The `controller:popTask` method removes and discards the current task, resuming the previous one.

##### Controller.resetTask

```lua
nil controller:resetTask()
```

The `controller:resetTask` method clears all tasks from the controller.

##### Controller.hasTask

```lua
boolean controller:hasTask()
```

The `controller:hasTask` method returns whether the controller has any active task.

**Returns:** True if a task is active, or false otherwise.

##### Controller.setCommand

```lua
nil controller:setCommand(table command)
```

The `controller:setCommand` method issues an immediate command to the controller.

**Parameters:**
- `command` (table): The command definition table.

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

The `controller:setOption` method sets an AI behavior option.

**Parameters:**
- `optionId` (number): The option ID from `AI.Option.[Air/Ground/Naval].id`.
- `value` (any): The option value from the corresponding enum.

```lua
controller:setOption(AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.WEAPON_FREE)

controller:setOption(AI.Option.Air.id.REACTION_ON_THREAT, AI.Option.Air.val.REACTION_ON_THREAT.EVADE_FIRE)
```

##### Controller.setOnOff

```lua
nil controller:setOnOff(boolean on)
```

The `controller:setOnOff` method enables or disables the AI controller.

**Parameters:**
- `on` (boolean): Set to true to enable the controller, or false to disable it and make the unit passive.

##### Controller.setAltitude

```lua
nil controller:setAltitude(number altitude, boolean keep, string altType)
```

The `controller:setAltitude` method sets the desired altitude for aircraft.

**Parameters:**
- `altitude` (number): The altitude in meters.
- `keep` (boolean): If true, the aircraft maintains altitude even when not tasked.
- `altType` (string): The altitude type. Use "RADIO" for altitude above ground level (AGL) or "BARO" for altitude above mean sea level (MSL).

```lua
controller:setAltitude(8000, true, "BARO")
```

##### Controller.setSpeed

```lua
nil controller:setSpeed(number speed, boolean keep)
```

The `controller:setSpeed` method sets the desired speed for aircraft.

**Parameters:**
- `speed` (number): The speed in meters per second.
- `keep` (boolean): If true, the aircraft maintains speed even when not tasked.

##### Controller.getDetectedTargets

```lua
table controller:getDetectedTargets(number detectionTypes)
```

The `controller:getDetectedTargets` method returns targets detected by the unit or group.

**Parameters:**
- `detectionTypes` (number): Optional. A bitmask of `Controller.Detection` values.

**Returns:** An array of detected target tables. Each table contains `object`, `visible`, `type`, and `distance` fields.

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

The `controller:isTargetDetected` method checks if a specific target is detected.

**Parameters:**
- `target` (Object): The object to check.
- `detectionTypes` (number): A bitmask of detection types.

**Returns:** Multiple values indicating detection status by each sensor type.

##### Controller.knowTarget

```lua
nil controller:knowTarget(Object target, boolean type, boolean distance)
```

The `controller:knowTarget` method forces the AI to "know" about a target.

**Parameters:**
- `target` (Object): The target to reveal to the AI.
- `type` (boolean): If true, the AI knows the target type.
- `distance` (boolean): If true, the AI knows the exact distance to the target.

```lua
local enemy = Unit.getByName("Hidden Enemy")
controller:knowTarget(enemy, true, true)
```

#### Spot

The Spot class represents a laser or infrared designator spot. You create spots dynamically through static functions.

The `Spot.Category` enum defines the spot categories:

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

The `Spot.createLaser` function creates a laser spot emanating from an object.

**Parameters:**
- `source` (Object): The object the laser originates from.
- `localPosition` (table): The offset from the object's center.
- `targetPoint` (Vec3): The point where the laser is pointing.
- `laserCode` (number): The 4-digit laser code, ranging from 1111 to 1788.

**Returns:** A Spot object.

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

The event system notifies your scripts when things happen in the simulation. You create an event handler and register it with the game, then your handler function gets called whenever events occur.

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

The `S_EVENT_SHOT` event fires when a unit fires a weapon such as a missile, bomb, or rocket. This event does not fire for guns; use `S_EVENT_SHOOTING_START` and `S_EVENT_SHOOTING_END` to detect gun fire.

**Event Table:**
```lua
{
    id = 1,
    time = number,
    initiator = Unit,
    weapon = Weapon
}
```

The `initiator` field contains the Unit object that fired the weapon. The `weapon` field contains the Weapon object representing the projectile in flight.

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

The `S_EVENT_HIT` event fires when a weapon hits a target. In multiplayer, the `weapon` field may be nil due to network desync.

**Event Table:**
```lua
{
    id = 2,
    time = number,
    initiator = Unit,
    weapon = Weapon,
    target = Object
}
```

The `initiator` field contains the Unit object that fired the weapon. The `weapon` field contains the Weapon object that hit the target. The `target` field contains the Object that was struck.

##### S_EVENT_SHOOTING_START

The `S_EVENT_SHOOTING_START` event fires when a unit begins firing guns or other continuous fire weapons.

**Event Table:**
```lua
{
    id = 23,
    time = number,
    initiator = Unit,
    weapon_name = string
}
```

The `initiator` field contains the Unit object that is firing. The `weapon_name` field contains the type name of the weapon being fired.

##### S_EVENT_SHOOTING_END

The `S_EVENT_SHOOTING_END` event fires when a unit stops firing guns.

**Event Table:**
```lua
{
    id = 24,
    time = number,
    initiator = Unit,
    weapon_name = string
}
```

The `initiator` field contains the Unit object that stopped firing. The `weapon_name` field contains the type name of the weapon that was being fired.

##### S_EVENT_KILL

The `S_EVENT_KILL` event fires when a unit kills another unit.

**Event Table:**
```lua
{
    id = 28,
    time = number,
    initiator = Unit,
    target = Unit,
    weapon = Weapon,
    weapon_name = string
}
```

The `initiator` field contains the Unit object that scored the kill. The `target` field contains the Unit object that was killed. The `weapon` field contains the Weapon object used in the kill. The `weapon_name` field contains the type name of the weapon.

#### Death and Damage Events

##### S_EVENT_DEAD

The `S_EVENT_DEAD` event fires when a unit is destroyed and its hit points reach zero. For aircraft, `S_EVENT_CRASH` may fire instead of or in addition to `S_EVENT_DEAD`.

**Event Table:**
```lua
{
    id = 8,
    time = number,
    initiator = Object
}
```

The `initiator` field contains the Object that was destroyed.

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

The `S_EVENT_CRASH` event fires when an aircraft crashes into the ground and is completely destroyed.

**Event Table:**
```lua
{
    id = 5,
    time = number,
    initiator = Unit
}
```

The `initiator` field contains the Unit object representing the aircraft that crashed.

##### S_EVENT_PILOT_DEAD

The `S_EVENT_PILOT_DEAD` event fires when a pilot dies, which is tracked separately from aircraft destruction.

**Event Table:**
```lua
{
    id = 9,
    time = number,
    initiator = Unit
}
```

The `initiator` field contains the Unit object representing the aircraft whose pilot died.

##### S_EVENT_UNIT_LOST

The `S_EVENT_UNIT_LOST` event fires when any unit is lost from the mission for any reason.

**Event Table:**
```lua
{
    id = 30,
    time = number,
    initiator = Unit
}
```

The `initiator` field contains the Unit object that was lost.

##### S_EVENT_HUMAN_FAILURE

The `S_EVENT_HUMAN_FAILURE` event fires when a player-controlled aircraft experiences a system failure.

**Event Table:**
```lua
{
    id = 16,
    time = number,
    initiator = Unit
}
```

The `initiator` field contains the Unit object representing the aircraft that experienced the failure.

##### S_EVENT_DETAILED_FAILURE

The `S_EVENT_DETAILED_FAILURE` event fires with detailed information about system failures.

**Event Table:**
```lua
{
    id = 17,
    time = number,
    initiator = Unit
}
```

The `initiator` field contains the Unit object representing the aircraft that experienced the failure.

#### Flight Events

##### S_EVENT_TAKEOFF

The `S_EVENT_TAKEOFF` event fires when an aircraft takes off from an airbase, FARP, or ship. This event fires several seconds after liftoff, after the aircraft has been airborne for a short period of time. Use `S_EVENT_RUNWAY_TAKEOFF` if you need to detect the exact moment of liftoff.

**Event Table:**
```lua
{
    id = 3,
    time = number,
    initiator = Unit,
    place = Airbase,
    subPlace = number
}
```

The `initiator` field contains the Unit object representing the aircraft that took off. The `place` field contains the Airbase object representing the airport, FARP, or ship from which the aircraft departed. The `subPlace` field contains a sub-location identifier.

##### S_EVENT_LAND

The `S_EVENT_LAND` event fires when an aircraft lands at an airbase, FARP, or ship and sufficiently slows down. This event fires after the aircraft has fully stopped. Use `S_EVENT_RUNWAY_TOUCH` for the moment of touchdown.

**Event Table:**
```lua
{
    id = 4,
    time = number,
    initiator = Unit,
    place = Airbase,
    subPlace = number
}
```

The `initiator` field contains the Unit object representing the aircraft that landed. The `place` field contains the Airbase object where the aircraft landed. The `subPlace` field contains a sub-location identifier.

##### S_EVENT_RUNWAY_TAKEOFF

The `S_EVENT_RUNWAY_TAKEOFF` event fires at the exact moment an aircraft leaves the ground. On some maps, the 3D terrain of the runway may cause this event to fire prematurely as the aircraft "bounces" on the runway surface. Prefer `S_EVENT_TAKEOFF` for most purposes unless you specifically need the exact moment of liftoff.

**Event Table:**
```lua
{
    id = 36,
    time = number,
    initiator = Unit,
    place = Airbase
}
```

The `initiator` field contains the Unit object representing the aircraft. The `place` field contains the Airbase object.

##### S_EVENT_RUNWAY_TOUCH

The `S_EVENT_RUNWAY_TOUCH` event fires at the exact moment an aircraft touches the ground after being airborne. On some maps, the 3D terrain of the runway may cause this event to fire multiple times as the aircraft "bounces" on the runway surface. Prefer `S_EVENT_LAND` for most purposes unless you specifically need the exact moment of touchdown.

**Event Table:**
```lua
{
    id = 37,
    time = number,
    initiator = Unit,
    place = Airbase
}
```

The `initiator` field contains the Unit object representing the aircraft. The `place` field contains the Airbase object.

##### S_EVENT_REFUELING

The `S_EVENT_REFUELING` event fires when an aircraft connects with a tanker and begins taking on fuel.

**Event Table:**
```lua
{
    id = 7,
    time = number,
    initiator = Unit
}
```

The `initiator` field contains the Unit object representing the aircraft receiving fuel.

##### S_EVENT_REFUELING_STOP

The `S_EVENT_REFUELING_STOP` event fires when an aircraft disconnects from a tanker.

**Event Table:**
```lua
{
    id = 14,
    time = number,
    initiator = Unit
}
```

The `initiator` field contains the Unit object representing the aircraft that disconnected from the tanker.

##### S_EVENT_EJECTION

The `S_EVENT_EJECTION` event fires when a pilot ejects from an aircraft. For aircraft with ejector seats, the `target` field contains the seat object rather than the pilot; wait for `S_EVENT_DISCARD_CHAIR_AFTER_EJECTION` to get the pilot. The pilot object is special and most scripting functions do not work on it.

**Event Table:**
```lua
{
    id = 6,
    time = number,
    initiator = Unit,
    target = Object
}
```

The `initiator` field contains the Unit object representing the aircraft from which the pilot ejected. The `target` field contains the ejector seat or pilot object.

##### S_EVENT_DISCARD_CHAIR_AFTER_EJECTION

The `S_EVENT_DISCARD_CHAIR_AFTER_EJECTION` event fires when the ejector seat separates from the pilot.

**Event Table:**
```lua
{
    id = 32,
    time = number,
    initiator = Unit,
    target = Object
}
```

The `initiator` field contains the Unit object representing the original aircraft. The `target` field contains the pilot object.

##### S_EVENT_LANDING_AFTER_EJECTION

The `S_EVENT_LANDING_AFTER_EJECTION` event fires when an ejected pilot lands after the parachute touchdown.

**Event Table:**
```lua
{
    id = 31,
    time = number,
    initiator = Unit,
    target = Object
}
```

The `initiator` field contains the Unit object representing the original aircraft. The `target` field contains the pilot object.

##### S_EVENT_ENGINE_STARTUP

The `S_EVENT_ENGINE_STARTUP` event fires when an aircraft starts its engines.

**Event Table:**
```lua
{
    id = 18,
    time = number,
    initiator = Unit
}
```

The `initiator` field contains the Unit object representing the aircraft that started its engines.

##### S_EVENT_ENGINE_SHUTDOWN

The `S_EVENT_ENGINE_SHUTDOWN` event fires when an aircraft shuts down its engines.

**Event Table:**
```lua
{
    id = 19,
    time = number,
    initiator = Unit
}
```

The `initiator` field contains the Unit object representing the aircraft that shut down its engines.

##### S_EVENT_LANDING_QUALITY_MARK

The `S_EVENT_LANDING_QUALITY_MARK` event fires for carrier landings and includes LSO grade information.

**Event Table:**
```lua
{
    id = 34,
    time = number,
    initiator = Unit,
    place = Airbase,
    comment = string
}
```

The `initiator` field contains the Unit object representing the aircraft that landed. The `place` field contains the Airbase object representing the carrier. The `comment` field contains the LSO grade comments.

#### Player Events

##### S_EVENT_BIRTH

The `S_EVENT_BIRTH` event fires when any unit spawns into the mission.

**Event Table:**
```lua
{
    id = 15,
    time = number,
    initiator = Unit
}
```

The `initiator` field contains the Unit object that was spawned.

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

The `S_EVENT_PLAYER_ENTER_UNIT` event fires when a player takes control of a unit. This event correctly fires for Combined Arms units.

**Event Table:**
```lua
{
    id = 20,
    time = number,
    initiator = Unit
}
```

The `initiator` field contains the Unit object that the player is now controlling.

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

The `S_EVENT_PLAYER_LEAVE_UNIT` event fires when a player leaves a unit, whether by disconnecting, spectating, or changing slot.

**Event Table:**
```lua
{
    id = 21,
    time = number,
    initiator = Unit
}
```

The `initiator` field contains the Unit object that the player left.

##### S_EVENT_PLAYER_COMMENT

The `S_EVENT_PLAYER_COMMENT` event fires when a player sends a chat message.

**Event Table:**
```lua
{
    id = 22,
    time = number,
    initiator = Unit,
    comment = string
}
```

The `initiator` field contains the Unit object representing the player who sent the message. The `comment` field contains the chat message text.

#### Mission Events

##### S_EVENT_MISSION_START

The `S_EVENT_MISSION_START` event fires when the mission begins.

**Event Table:**
```lua
{
    id = 11,
    time = number
}
```

##### S_EVENT_MISSION_END

The `S_EVENT_MISSION_END` event fires when the mission ends.

**Event Table:**
```lua
{
    id = 12,
    time = number
}
```

##### S_EVENT_BASE_CAPTURED

The `S_EVENT_BASE_CAPTURED` event fires when an airbase changes coalition.

**Event Table:**
```lua
{
    id = 10,
    time = number,
    initiator = Unit,
    place = Airbase
}
```

The `initiator` field contains the Unit object that captured the base. The `place` field contains the Airbase object that was captured.

##### S_EVENT_AI_ABORT_MISSION

The `S_EVENT_AI_ABORT_MISSION` event fires when an AI group aborts its mission.

**Event Table:**
```lua
{
    id = 35,
    time = number,
    initiator = Unit
}
```

The `initiator` field contains the Unit object representing a unit from the group that aborted its mission.

#### Marker Events

Map marker events allow scripts to respond to player map annotations.

##### S_EVENT_MARK_ADDED

The `S_EVENT_MARK_ADDED` event fires when a mark or shape is added to the map.

**Event Table:**
```lua
{
    id = 25,
    time = number,
    initiator = Unit,
    idx = number,
    coalition = number,
    groupID = number,
    text = string,
    pos = Vec3
}
```

The `initiator` field contains the Unit object that created the mark, or nil if the mark was created by a script. The `idx` field contains a unique marker ID. The `coalition` field contains the coalition the marker is visible to, or -1 if visible to all coalitions. The `groupID` field contains the group the marker is visible to, or -1 if visible to all groups in the coalition. The `text` field contains the marker text. The `pos` field contains the marker position as a Vec3.

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

The `S_EVENT_MARK_CHANGE` event fires when a mark is modified.

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

The fields have the same meanings as in `S_EVENT_MARK_ADDED`.

##### S_EVENT_MARK_REMOVE

The `S_EVENT_MARK_REMOVE` event fires when a mark is deleted.

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

The fields have the same meanings as in `S_EVENT_MARK_ADDED`.

#### Weapon Events

##### S_EVENT_WEAPON_ADD

The `S_EVENT_WEAPON_ADD` event fires when a weapon is added to a unit, such as during rearming.

**Event Table:**
```lua
{
    id = 33,
    time = number,
    initiator = Unit,
    weapon_name = string
}
```

The `initiator` field contains the Unit object that received the weapon. The `weapon_name` field contains the type name of the weapon that was added.

### AI Control

The AI control system allows scripts to direct AI behavior through tasks, commands, and options. These are issued through the Controller object obtained from groups or units.

#### Overview

AI behavior is controlled through three mechanisms:

- **Tasks** define what the AI should do (attack, orbit, escort, etc.). Tasks take time to complete and can be queued.
- **Commands** are instant actions that execute immediately (set frequency, activate beacon, etc.). They do not enter the task queue.
- **Options** configure AI behavior settings (ROE, reaction to threat, formation, etc.).

Tasks are issued via `controller:setTask()`, `controller:pushTask()`, or `controller:popTask()`. Commands use `controller:setCommand()`. Options use `controller:setOption()`. After spawning a group with `coalition.addGroup()`, you must add a delay before issuing tasks to the controller, because issuing tasks immediately after spawning can crash the game. Use `timer.scheduleFunction()` to delay by at least 1 second.

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

The `ComboTask` wrapper is a container that holds multiple tasks to be executed in sequence. This is the default task format used by the Mission Editor for groups with multiple waypoint tasks.

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

The `tasks` field contains an array of task definitions that will be executed in order.

##### ControlledTask

The `ControlledTask` wrapper wraps a task with start and stop conditions. Options and commands do not support stop conditions because they execute instantly.

```lua
local controlled = {
    id = 'ControlledTask',
    params = {
        task = innerTask,
        condition = {
            time = number,
            condition = string,
            userFlag = string,
            userFlagValue = boolean,
            probability = number
        },
        stopCondition = {
            time = number,
            condition = string,
            userFlag = string,
            userFlagValue = boolean,
            duration = number,
            lastWaypoint = number
        }
    }
}
```

The `task` field contains the inner task to be controlled. The `condition` field contains start conditions that are evaluated once when the task is reached: `time` specifies a mission time in seconds, `condition` contains Lua code returning true or false, `userFlag` specifies a flag name to check, `userFlagValue` specifies the expected flag value, and `probability` specifies a 0-100 chance of execution. The `stopCondition` field contains stop conditions that are evaluated continuously: `duration` specifies seconds to run before stopping, and `lastWaypoint` specifies the waypoint index at which to stop.

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
            duration = 900
        }
    }
}
```

##### WrappedAction

The `WrappedAction` wrapper wraps a command or option as a task so it can be placed in the task queue.

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

The `action` field contains the command or option to be wrapped.

#### Main Tasks

Main tasks define the primary behavior of a group.

##### Orbit

The `Orbit` task orders aircraft to orbit at a location.

**For:** Airplanes, Helicopters

```lua
local orbit = {
    id = 'Orbit',
    params = {
        pattern = string,
        point = Vec2,
        point2 = Vec2,
        speed = number,
        altitude = number,
        hotLegDir = number,
        legLength = number,
        width = number,
        clockWise = boolean
    }
}
```

The `pattern` field specifies the orbit pattern: "Circle", "Race-Track", or "Anchored". The `point` field contains the center point as a Vec2; if omitted, the aircraft uses the current waypoint. The `point2` field specifies a second point for Race-Track patterns. The `speed` field specifies the orbit speed in meters per second; if omitted, the aircraft defaults to approximately 1.5 times its stall speed. The `altitude` field specifies the orbit altitude in meters. For the Anchored pattern only, the `hotLegDir` field specifies the heading in radians for the return leg, the `legLength` field specifies the distance in meters before turning, the `width` field specifies the orbit diameter in meters, and the `clockWise` field specifies whether to orbit clockwise (defaults to false).

**Pattern Enum:**
```lua
AI.Task.OrbitPattern = {
    RACE_TRACK = "Race-Track",
    CIRCLE = "Circle"
}
```

The "Anchored" pattern is also valid but is not included in the `AI.Task.OrbitPattern` enum.

```lua
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

The `AttackUnit` task orders aircraft to attack a specific unit. The target unit is automatically detected by the attacking group.

**For:** Airplanes, Helicopters

```lua
local attack = {
    id = 'AttackUnit',
    params = {
        unitId = number,
        weaponType = number,
        expend = string,
        direction = number,
        attackQtyLimit = boolean,
        attackQty = number,
        groupAttack = boolean
    }
}
```

The `unitId` field is required and contains the unique numeric identifier of the target unit; call `unit:getID()` on a Unit object to obtain this value. The `weaponType` field specifies a weapon flags bitmask. The `expend` field specifies how much ordnance to use per pass. The `direction` field specifies the attack azimuth in radians. The `attackQtyLimit` field enables limiting the number of attack passes. The `attackQty` field specifies how many attack passes to make when `attackQtyLimit` is true. The `groupAttack` field, when set to true, causes all aircraft in the group to attack the same target simultaneously; use this when attacking heavily defended targets like ships that require multiple simultaneous hits.

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
local attack = {
    id = 'AttackUnit',
    params = {
        unitId = Unit.getByName("Target"):getID(),
        weaponType = 4161536,
        expend = "Two",
        attackQtyLimit = true,
        attackQty = 1
    }
}
```

##### AttackGroup

The `AttackGroup` task orders aircraft to attack all units in a group.

**For:** Airplanes, Helicopters

```lua
local attack = {
    id = 'AttackGroup',
    params = {
        groupId = number,
        weaponType = number,
        expend = string,
        direction = number,
        attackQtyLimit = boolean,
        attackQty = number
    }
}
```

The `groupId` field is required and contains the unique numeric identifier of the target group; call `group:getID()` on a Group object to obtain this value. The `weaponType`, `expend`, `direction`, `attackQtyLimit`, and `attackQty` fields work the same as in the `AttackUnit` task.

##### Bombing

The `Bombing` task orders aircraft to bomb a specific point.

**For:** Airplanes, Helicopters

```lua
local bomb = {
    id = 'Bombing',
    params = {
        point = Vec2,
        weaponType = number,
        expend = string,
        attackQtyLimit = boolean,
        attackQty = number,
        direction = number,
        altitude = number,
        attackType = string
    }
}
```

The `point` field is required and contains the target coordinates as a Vec2. The `altitude` field specifies the attack altitude in meters. The `attackType` field specifies the attack profile, such as "Dive" for dive bombing or horizontal for level bombing. The `weaponType`, `expend`, `direction`, `attackQtyLimit`, and `attackQty` fields work the same as in the `AttackUnit` task.

##### BombingRunway

The `BombingRunway` task orders aircraft to bomb an airfield runway.

**For:** Airplanes

```lua
local bomb = {
    id = 'BombingRunway',
    params = {
        runwayId = number,
        weaponType = number,
        expend = string,
        direction = number
    }
}
```

The `runwayId` field contains the airbase ID. The `weaponType`, `expend`, and `direction` fields work the same as in the `AttackUnit` task.

##### CarpetBombing

The `CarpetBombing` task orders aircraft to perform carpet bombing along a path.

**For:** Airplanes

```lua
local carpet = {
    id = 'CarpetBombing',
    params = {
        point = Vec2,
        weaponType = number,
        expend = string,
        direction = number,
        attackQty = number,
        carpetLength = number
    }
}
```

The `point` field contains the start point as a Vec2. The `carpetLength` field specifies the length of the carpet in meters. The `weaponType`, `expend`, `direction`, and `attackQty` fields work the same as in the `AttackUnit` task.

##### Escort

The `Escort` task orders aircraft to escort and protect another group.

**For:** Airplanes, Helicopters

```lua
local escort = {
    id = 'Escort',
    params = {
        groupId = number,
        engagementDistMax = number,
        targetTypes = table,
        pos = Vec3,
        lastWptIndexFlag = boolean,
        lastWptIndex = number
    }
}
```

The `groupId` field contains the ID of the group to escort. The `engagementDistMax` field specifies the maximum engagement range in meters. The `targetTypes` field contains an array of attribute names specifying which target types to engage. The `pos` field specifies the position offset from the escorted group as a Vec3. The `lastWptIndexFlag` and `lastWptIndex` fields control when the escort task ends.

##### Follow

The `Follow` task orders aircraft to follow another group in formation.

**For:** Airplanes, Helicopters

```lua
local follow = {
    id = 'Follow',
    params = {
        groupId = number,
        pos = Vec3,
        lastWptIndexFlag = boolean,
        lastWptIndex = number
    }
}
```

The `groupId` field contains the ID of the group to follow. The `pos` field specifies the position offset from the followed group as a Vec3. The `lastWptIndexFlag` and `lastWptIndex` fields control when the follow task ends.

##### GoToWaypoint

The `GoToWaypoint` task orders the group to proceed to a specific waypoint.

**For:** Airplanes, Helicopters, Ground, Ships

```lua
local goto = {
    id = 'GoToWaypoint',
    params = {
        fromWaypointIndex = number,
        goToWaypointIndex = number
    }
}
```

The `fromWaypointIndex` field specifies the starting waypoint index. The `goToWaypointIndex` field specifies the destination waypoint index.

##### Hold

The `Hold` task orders ground units to stop and hold position. This task takes no parameters.

**For:** Ground Vehicles

```lua
local hold = {
    id = 'Hold',
    params = {}
}
```

##### FireAtPoint

The `FireAtPoint` task orders ground units to fire at a specific location.

**For:** Ground Vehicles (artillery)

```lua
local fire = {
    id = 'FireAtPoint',
    params = {
        point = Vec2,
        radius = number,
        expendQty = number,
        expendQtyEnabled = boolean
    }
}
```

The `point` field contains the target coordinates as a Vec2. The `radius` field specifies the dispersion radius in meters. The `expendQty` field specifies how many rounds to fire when `expendQtyEnabled` is true.

##### Land

The `Land` task orders aircraft to land at an airbase or point.

**For:** Airplanes, Helicopters

```lua
local land = {
    id = 'Land',
    params = {
        point = Vec2,
        durationFlag = boolean,
        duration = number
    }
}
```

The `point` field contains the landing point as a Vec2. The `duration` field specifies how long to stay on the ground when `durationFlag` is true.

##### RecoveryTanker

The `RecoveryTanker` task orders a tanker to act as a carrier recovery tanker.

**For:** Airplanes (tankers)

```lua
local recovery = {
    id = 'RecoveryTanker',
    params = {
        groupId = number,
        speed = number,
        altitude = number,
        lastWptIndexFlag = boolean,
        lastWptIndex = number
    }
}
```

The `groupId` field contains the carrier group ID. The `speed` field specifies the tanker's orbit speed. The `altitude` field specifies the orbit altitude. The `lastWptIndexFlag` and `lastWptIndex` fields control when the task ends.

#### En-route Tasks

En-route tasks run alongside the main mission, defining ongoing behaviors.

##### EngageTargets

The `EngageTargets` en-route task orders aircraft to engage detected targets of specified types.

**For:** Airplanes, Helicopters

```lua
local engage = {
    id = 'EngageTargets',
    params = {
        targetTypes = table,
        priority = number
    }
}
```

The `targetTypes` field contains an array of attribute names specifying which target types to engage. The `priority` field specifies the task priority, where lower values indicate higher priority; the default is 0.

```lua
local cap = {
    id = 'EngageTargets',
    params = {
        targetTypes = {"Air"},
        priority = 0
    }
}
```

##### EngageTargetsInZone

The `EngageTargetsInZone` en-route task orders aircraft to engage targets within a specified zone.

**For:** Airplanes, Helicopters

```lua
local engage = {
    id = 'EngageTargetsInZone',
    params = {
        point = Vec2,
        zoneRadius = number,
        targetTypes = table,
        priority = number
    }
}
```

The `point` field contains the zone center as a Vec2. The `zoneRadius` field specifies the zone radius in meters. The `targetTypes` field contains an array of attribute names specifying which target types to engage. The `priority` field specifies the task priority.

##### EngageGroup

The `EngageGroup` en-route task orders aircraft to engage a specific enemy group.

**For:** Airplanes, Helicopters

```lua
local engage = {
    id = 'EngageGroup',
    params = {
        groupId = number,
        weaponType = number,
        expend = string,
        priority = number
    }
}
```

The `groupId` field contains the target group ID. The `weaponType` and `expend` fields work the same as in the `AttackUnit` task. The `priority` field specifies the task priority.

##### EngageUnit

The `EngageUnit` en-route task orders aircraft to engage a specific enemy unit.

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

The `unitId` field contains the target unit ID. The `weaponType`, `expend`, and `groupAttack` fields work the same as in the `AttackUnit` task. The `priority` field specifies the task priority.

##### AWACS

The `AWACS` en-route task designates an aircraft as an AWACS, providing radar coverage for friendly forces. This task takes no parameters.

**For:** Airplanes (AWACS-capable)

```lua
local awacs = {
    id = 'AWACS',
    params = {}
}
```

##### Tanker

The `Tanker` en-route task designates an aircraft as an aerial refueling tanker. This task takes no parameters.

**For:** Airplanes (tanker-capable)

```lua
local tanker = {
    id = 'Tanker',
    params = {}
}
```

##### FAC

The `FAC` en-route task designates a unit as a Forward Air Controller.

**For:** Airplanes, Helicopters, Ground Vehicles

```lua
local fac = {
    id = 'FAC',
    params = {
        frequency = number,
        modulation = number,
        callname = number,
        number = number
    }
}
```

The `frequency` field specifies the radio frequency in Hz. The `modulation` field specifies the modulation type, where 0 is AM and 1 is FM. The `callname` field specifies the FAC callsign index. The `number` field specifies the FAC number.

##### FAC_EngageGroup

The `FAC_EngageGroup` en-route task orders a FAC to designate a group for attack.

**For:** Airplanes, Helicopters, Ground Vehicles

```lua
local facEngage = {
    id = 'FAC_EngageGroup',
    params = {
        groupId = number,
        weaponType = number,
        designation = string,
        datalink = boolean,
        frequency = number,
        modulation = number,
        callname = number,
        number = number
    }
}
```

The `groupId` field contains the target group ID. The `weaponType` field specifies the weapon flags bitmask. The `designation` field specifies the designation method from the `AI.Task.Designation` enum. The `datalink` field specifies whether to use datalink. The `frequency`, `modulation`, `callname`, and `number` fields work the same as in the `FAC` task.

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

The `EWR` en-route task designates a unit as an Early Warning Radar. This task takes no parameters.

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

The `SetFrequency` command changes the group's radio frequency.

**For:** Airplanes, Helicopters, Ground Vehicles

```lua
local cmd = {
    id = 'SetFrequency',
    params = {
        frequency = number,
        modulation = number,
        power = number
    }
}
controller:setCommand(cmd)
```

The `frequency` field specifies the frequency in Hz; for example, 251000000 represents 251 MHz. The `modulation` field specifies the modulation type, where 0 is AM and 1 is FM. The `power` field specifies the transmission power in watts; 10 is a typical value.

```lua
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

The `SetInvisible` command makes the group invisible to enemy AI sensors.

**For:** All unit types

```lua
local cmd = {
    id = 'SetInvisible',
    params = {
        value = boolean
    }
}
```

The `value` field specifies whether to enable invisibility; set to true to make the group invisible.

##### SetImmortal

The `SetImmortal` command makes the group invulnerable to all damage.

**For:** All unit types

```lua
local cmd = {
    id = 'SetImmortal',
    params = {
        value = boolean
    }
}
```

The `value` field specifies whether to enable invulnerability; set to true to make the group immortal.

##### SetUnlimitedFuel

The `SetUnlimitedFuel` command gives the group unlimited fuel.

**For:** Airplanes, Helicopters

```lua
local cmd = {
    id = 'SetUnlimitedFuel',
    params = {
        value = boolean
    }
}
```

The `value` field specifies whether to enable unlimited fuel.

##### Start

The `Start` command starts the engines of an aircraft. This command takes no parameters.

**For:** Airplanes, Helicopters

```lua
local cmd = {
    id = 'Start',
    params = {}
}
```

##### SwitchWaypoint

The `SwitchWaypoint` command changes the group's current waypoint.

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

The `fromWaypointIndex` field specifies the starting waypoint index. The `goToWaypointIndex` field specifies the destination waypoint index.

##### StopRoute

The `StopRoute` command stops or resumes the group's route following.

**For:** All unit types

```lua
local cmd = {
    id = 'StopRoute',
    params = {
        value = boolean
    }
}
```

The `value` field specifies whether to stop the route; set to true to stop route following.

##### SwitchAction

The `SwitchAction` command switches the group's current action.

**For:** All unit types

```lua
local cmd = {
    id = 'SwitchAction',
    params = {
        actionIndex = number
    }
}
```

The `actionIndex` field specifies the index of the action to switch to.

##### ActivateBeacon

The `ActivateBeacon` command activates a navigation beacon on the unit. Only one beacon can be active per unit at a time; activating a new beacon deactivates any existing beacon.

**For:** All unit types

```lua
local cmd = {
    id = 'ActivateBeacon',
    params = {
        type = number,
        system = number,
        name = string,
        callsign = string,
        frequency = number
    }
}
```

The `type` field specifies the beacon type from the beacon type constants. The `system` field specifies the beacon system from the `SystemName` enum. The `name` field is optional and specifies a display name for the beacon. The `callsign` field specifies the Morse code callsign. The `frequency` field specifies the beacon frequency in Hz.

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

##### DeactivateBeacon

The `DeactivateBeacon` command deactivates any active beacon on the unit. This command takes no parameters.

**For:** All unit types

```lua
local cmd = {
    id = 'DeactivateBeacon',
    params = {}
}
```

##### ActivateACLS

The `ActivateACLS` command activates the Automatic Carrier Landing System on a carrier. This command takes no parameters.

**For:** Ships (carriers)

```lua
local cmd = {
    id = 'ActivateACLS',
    params = {}
}
```

##### DeactivateACLS

The `DeactivateACLS` command deactivates the Automatic Carrier Landing System. This command takes no parameters.

**For:** Ships (carriers)

```lua
local cmd = {
    id = 'DeactivateACLS',
    params = {}
}
```

##### ActivateLink4

The `ActivateLink4` command activates Link 4 datalink on a carrier.

**For:** Ships (carriers)

```lua
local cmd = {
    id = 'ActivateLink4',
    params = {
        unitId = number,
        frequency = number
    }
}
```

The `unitId` field contains the aircraft unit ID. The `frequency` field specifies the Link 4 frequency.

##### DeactivateLink4

The `DeactivateLink4` command deactivates Link 4 datalink. This command takes no parameters.

**For:** Ships (carriers)

```lua
local cmd = {
    id = 'DeactivateLink4',
    params = {}
}
```

##### ActivateICLS

The `ActivateICLS` command activates the Instrument Carrier Landing System.

**For:** Ships (carriers)

```lua
local cmd = {
    id = 'ActivateICLS',
    params = {
        channel = number
    }
}
```

The `channel` field specifies the ICLS channel.

##### DeactivateICLS

The `DeactivateICLS` command deactivates the Instrument Carrier Landing System. This command takes no parameters.

**For:** Ships (carriers)

```lua
local cmd = {
    id = 'DeactivateICLS',
    params = {}
}
```

##### EPLRS

The `EPLRS` command enables or disables EPLRS (Enhanced Position Location Reporting System).

**For:** All unit types

```lua
local cmd = {
    id = 'EPLRS',
    params = {
        value = boolean,
        groupId = number
    }
}
```

The `value` field specifies whether to enable EPLRS. The `groupId` field is optional and specifies the group to link with.

##### TransmitMessage

The `TransmitMessage` command transmits an audio message.

**For:** All unit types

```lua
local cmd = {
    id = 'TransmitMessage',
    params = {
        file = string,
        duration = number,
        subtitle = string,
        loop = boolean
    }
}
```

The `file` field specifies the sound file path. The `duration` field specifies the message duration. The `subtitle` field specifies the subtitle text. The `loop` field specifies whether to loop the message.

##### StopTransmission

The `StopTransmission` command stops any active transmission. This command takes no parameters.

**For:** All unit types

```lua
local cmd = {
    id = 'StopTransmission',
    params = {}
}
```

##### Smoke_On_Off

The `Smoke_On_Off` command toggles a smoke trail on or off.

**For:** Airplanes (aerobatic aircraft)

```lua
local cmd = {
    id = 'Smoke_On_Off',
    params = {
        value = boolean
    }
}
```

The `value` field specifies whether to enable the smoke trail.

#### Options

Options configure AI behavior settings. They are set using `controller:setOption(optionId, value)`.

```lua
controller:setOption(AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.WEAPON_FREE)
```

Options are separated by unit domain: Air, Ground, and Naval.

#### Air Options

##### ROE (Rules of Engagement)

The `ROE` option controls when AI aircraft will engage targets.

```lua
AI.Option.Air.id.ROE = 0

AI.Option.Air.val.ROE = {
    WEAPON_FREE = 0,
    OPEN_FIRE_WEAPON_FREE = 1,
    OPEN_FIRE = 2,
    RETURN_FIRE = 3,
    WEAPON_HOLD = 4
}
```

The `WEAPON_FREE` value allows attacking any detected enemy. The `OPEN_FIRE_WEAPON_FREE` value allows attacking enemies attacking friendlies while engaging at will. The `OPEN_FIRE` value allows attacking only enemies attacking friendlies. The `RETURN_FIRE` value allows firing only when fired upon. The `WEAPON_HOLD` value prevents all weapons fire.

```lua
controller:setOption(AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.WEAPON_FREE)
```

##### REACTION_ON_THREAT

The `REACTION_ON_THREAT` option defines how aircraft respond to threats.

```lua
AI.Option.Air.id.REACTION_ON_THREAT = 1

AI.Option.Air.val.REACTION_ON_THREAT = {
    NO_REACTION = 0,
    PASSIVE_DEFENCE = 1,
    EVADE_FIRE = 2,
    BYPASS_AND_ESCAPE = 3,
    ALLOW_ABORT_MISSION = 4
}
```

The `NO_REACTION` value causes no defensive actions. The `PASSIVE_DEFENCE` value causes the aircraft to use jammers and countermeasures only, without maneuvering. The `EVADE_FIRE` value causes defensive maneuvers plus countermeasures. The `BYPASS_AND_ESCAPE` value causes the aircraft to route around threat zones and fly above threats. The `ALLOW_ABORT_MISSION` value allows the aircraft to return to base if the situation becomes too dangerous. The value 5 (AAA_EVADE_FIRE) is also valid and causes S-turns at altitude.

##### RADAR_USING

The `RADAR_USING` option controls radar usage.

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

The `FLARE_USING` option controls flare and chaff deployment.

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

The `Formation` option sets the flight formation. The value is a formation index number.

```lua
AI.Option.Air.id.Formation = 5
```

##### RTB_ON_BINGO

The `RTB_ON_BINGO` option controls whether aircraft return to base when fuel is low. The value is a boolean.

```lua
AI.Option.Air.id.RTB_ON_BINGO = 6
```

##### SILENCE

The `SILENCE` option disables radio communications. The value is a boolean.

```lua
AI.Option.Air.id.SILENCE = 7
```

##### RTB_ON_OUT_OF_AMMO

The `RTB_ON_OUT_OF_AMMO` option controls whether aircraft return to base when out of ammunition. The value is a boolean.

```lua
AI.Option.Air.id.RTB_ON_OUT_OF_AMMO = 10
```

##### ECM_USING

The `ECM_USING` option controls ECM (Electronic Counter Measures) usage.

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

The `PROHIBIT_AA` option prohibits air-to-air attacks. The value is a boolean.

```lua
AI.Option.Air.id.PROHIBIT_AA = 14
```

##### PROHIBIT_JETT

The `PROHIBIT_JETT` option prohibits jettisoning stores. The value is a boolean.

```lua
AI.Option.Air.id.PROHIBIT_JETT = 15
```

##### PROHIBIT_AB

The `PROHIBIT_AB` option prohibits afterburner use. The value is a boolean.

```lua
AI.Option.Air.id.PROHIBIT_AB = 16
```

##### PROHIBIT_AG

The `PROHIBIT_AG` option prohibits air-to-ground attacks. The value is a boolean.

```lua
AI.Option.Air.id.PROHIBIT_AG = 17
```

##### MISSILE_ATTACK

The `MISSILE_ATTACK` option controls missile launch range behavior.

```lua
AI.Option.Air.id.MISSILE_ATTACK = 18

AI.Option.Air.val.MISSILE_ATTACK = {
    MAX_RANGE = 0,
    NEZ_RANGE = 1,
    HALF_WAY_RMAX_NEZ = 2,
    TARGET_THREAT_EST = 3,
    RANDOM_RANGE = 4
}
```

The `MAX_RANGE` value causes firing at maximum range. The `NEZ_RANGE` value causes firing at no-escape zone range. The `HALF_WAY_RMAX_NEZ` value causes firing halfway between maximum and no-escape zone range. The `TARGET_THREAT_EST` value causes firing based on target threat assessment. The `RANDOM_RANGE` value causes random range selection.

##### PROHIBIT_WP_PASS_REPORT

The `PROHIBIT_WP_PASS_REPORT` option disables waypoint passage radio calls. The value is a boolean.

```lua
AI.Option.Air.id.PROHIBIT_WP_PASS_REPORT = 19
```

##### JETT_TANKS_IF_EMPTY

The `JETT_TANKS_IF_EMPTY` option causes the aircraft to jettison external fuel tanks when empty. The value is a boolean.

```lua
AI.Option.Air.id.JETT_TANKS_IF_EMPTY = 25
```

##### FORCED_ATTACK

The `FORCED_ATTACK` option forces the AI to continue attacking regardless of threats. The value is a boolean.

```lua
AI.Option.Air.id.FORCED_ATTACK = 26
```

##### PREFER_VERTICAL

The `PREFER_VERTICAL` option causes the AI to prefer vertical maneuvering in combat. The value is a boolean.

```lua
AI.Option.Air.id.PREFER_VERTICAL = 32
```

##### ALLOW_FORMATION_SIDE_SWAP

The `ALLOW_FORMATION_SIDE_SWAP` option allows wingmen to switch formation sides. The value is a boolean.

```lua
AI.Option.Air.id.ALLOW_FORMATION_SIDE_SWAP = 35
```

#### Ground Options

##### ROE

The `ROE` option for ground units controls when they will engage targets.

```lua
AI.Option.Ground.id.ROE = 0

AI.Option.Ground.val.ROE = {
    OPEN_FIRE = 2,
    RETURN_FIRE = 3,
    WEAPON_HOLD = 4
}
```

##### ALARM_STATE

The `ALARM_STATE` option sets the group's alert level.

```lua
AI.Option.Ground.id.ALARM_STATE = 9

AI.Option.Ground.val.ALARM_STATE = {
    AUTO = 0,
    GREEN = 1,
    RED = 2
}
```

The `AUTO` value causes automatic state changes based on the situation. The `GREEN` value puts the group in a relaxed state with weapons safe. The `RED` value puts the group in combat ready state with weapons hot.

```lua
local controller = Group.getByName("SA-10"):getController()
controller:setOption(AI.Option.Ground.id.ALARM_STATE, AI.Option.Ground.val.ALARM_STATE.RED)
```

##### DISPERSE_ON_ATTACK

The `DISPERSE_ON_ATTACK` option causes ground units to disperse when attacked. The value is a boolean.

```lua
AI.Option.Ground.id.DISPERSE_ON_ATTACK = 8
```

##### ENGAGE_AIR_WEAPONS

The `ENGAGE_AIR_WEAPONS` option controls what types of air targets to engage. The value is a boolean.

```lua
AI.Option.Ground.id.ENGAGE_AIR_WEAPONS = 20
```

##### AC_ENGAGEMENT_RANGE_RESTRICTION

The `AC_ENGAGEMENT_RANGE_RESTRICTION` option limits the engagement range for air defense units. The value is a range expressed as a percentage from 0 to 100.

```lua
AI.Option.Ground.id.AC_ENGAGEMENT_RANGE_RESTRICTION = 24
```

##### Evasion of ARM

The `EVASION_OF_ARM` option controls SAM behavior when targeted by anti-radiation missiles. The value is a boolean; when set to true, the unit shuts down its radar when an anti-radiation missile is detected.

```lua
AI.Option.Ground.id.EVASION_OF_ARM = 31
```

#### Naval Options

##### ROE

The `ROE` option for naval units controls when they will engage targets.

```lua
AI.Option.Naval.id.ROE = 0

AI.Option.Naval.val.ROE = {
    OPEN_FIRE = 2,
    RETURN_FIRE = 3,
    WEAPON_HOLD = 4
}
```

#### AI Skill Levels

The `AI.Skill` enum defines the skill level constants used in unit definitions when spawning groups dynamically.

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

#### AI Task Enums

The `AI.Task` table contains additional enumerators for task parameters.

The `AI.Task.AltitudeType` enum defines altitude reference types. The `RADIO` value indicates altitude above ground level (AGL). The `BARO` value indicates altitude above mean sea level (MSL).

```lua
AI.Task.AltitudeType = {
    RADIO = "RADIO",
    BARO = "BARO"
}
```

The `AI.Task.TurnMethod` enum defines waypoint turn methods.

```lua
AI.Task.TurnMethod = {
    FLY_OVER_POINT = "Fly Over Point",
    FIN_POINT = "Fin Point"
}
```

The `AI.Task.VehicleFormation` enum defines ground vehicle formations.

```lua
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
```

The `AI.Task.WaypointType` enum defines waypoint types.

```lua
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

The `onMissionLoadBegin` hook fires when the server begins loading a mission. Use this hook to prepare for mission loading, reset state, or log mission changes.

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

The `onMissionLoadProgress` hook fires periodically during mission loading with progress updates.

**Parameters:**
- `progress` (number): The loading progress as a fraction from 0.0 to 1.0.
- `message` (string): A description of the current loading stage.

##### onMissionLoadEnd

```lua
nil hook.onMissionLoadEnd()
```

The `onMissionLoadEnd` hook fires when a server finishes loading a mission. The mission is now ready to run but may not have started yet.

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

The `onSimulationStart` hook fires when the simulation begins running. This occurs after mission loading completes and the 3D world becomes active.

##### onSimulationStop

```lua
nil hook.onSimulationStop()
```

The `onSimulationStop` hook fires when exiting the simulation. This occurs when transitioning from the 3D game world back to the UI.

##### onSimulationPause

```lua
nil hook.onSimulationPause()
```

The `onSimulationPause` hook fires when the mission is paused. This hook is only relevant for single-player or when the server admin pauses.

##### onSimulationResume

```lua
nil hook.onSimulationResume()
```

The `onSimulationResume` hook fires when the mission resumes after being paused.

##### onSimulationFrame

```lua
nil hook.onSimulationFrame()
```

The `onSimulationFrame` hook fires every simulation frame. This hook runs very frequently and should be used sparingly as it can impact performance. Avoid expensive operations and do not use this hook for anything that can be done with scheduled functions or events instead.

#### Player Connection Hooks

##### onPlayerTryConnect

```lua
boolean, string hook.onPlayerTryConnect(string addr, string ucid, string name, number playerId)
```

The `onPlayerTryConnect` hook fires when a player initially attempts to connect to the server. This hook can allow or deny access before the player fully connects. If any value is returned from this hook, other callbacks for this event are ignored; only return a value when you want to make a definitive allow or deny decision.

**Parameters:**
- `addr` (string): The player's IP address.
- `ucid` (string): The player's unique DCS identifier, which persists across sessions.
- `name` (string): The player's display name.
- `playerId` (number): The ID the player would have if connection succeeds.

**Returns:** Return `true` to force allow the player, return `false` along with a reason string to reject the player with a message, or return nothing to allow other hooks to decide.

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

The `onPlayerConnect` hook fires when a player successfully connects to the server. The player has passed any connection checks and is now connected but may still be loading the mission.

**Parameters:**
- `id` (number): The unique player identifier for this session.

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

The `onPlayerDisconnect` hook fires when a player disconnects from the server.

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

The `onPlayerStart` hook fires when a player has fully loaded into the simulation and can select a slot. This hook fires after `onPlayerConnect` once the player finishes loading.

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

The `onPlayerStop` hook fires when a player leaves the simulation, whether by returning to spectators or disconnecting.

**Parameters:**
- `id` (number): The player's ID.

##### onPlayerChangeSlot

```lua
nil hook.onPlayerChangeSlot(number playerId)
```

The `onPlayerChangeSlot` hook fires when a player successfully moves into a new slot. This hook only fires for successful slot changes; rejected requests such as denied RIO requests do not trigger this hook.

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

The `onPlayerTryChangeSlot` hook fires when a player attempts to change slots. This hook can allow or deny the change.

**Parameters:**
- `playerId` (number): The player's ID.
- `side` (number): The target coalition, where 0 is spectators, 1 is red, and 2 is blue.
- `slotId` (number): The target slot ID.

**Returns:** Return `true` to allow the slot change, return `false` to deny the slot change, or return nothing to allow other hooks to decide.

#### Chat Hooks

##### onPlayerTrySendChat

```lua
string hook.onPlayerTrySendChat(number playerId, string message, boolean toAll)
```

The `onPlayerTrySendChat` hook fires when a player attempts to send a chat message. This hook can modify or block the message.

**Parameters:**
- `playerId` (number): The player sending the message.
- `message` (string): The message content.
- `toAll` (boolean): True if sending to all players, or false if sending to the coalition only.

**Returns:** Return a modified string to change the message, return an empty string to block the message, or return nothing to allow the original message.

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

The `onGameEvent` hook fires for various game events such as kills, crashes, and takeoffs. The event data structure varies by event type.

### net Singleton

The `net` singleton provides network-related functions for player management, chat, and server control. These functions are available in both the server hook environment and the mission scripting environment.

#### net.send_chat

```lua
nil net.send_chat(string message, boolean all)
```

The `net.send_chat` function sends a chat message to the server.

**Parameters:**
- `message` (string): The message to send.
- `all` (boolean): True to send to all players, or false for coalition only.

```lua
net.send_chat("Server message: Mission restart in 5 minutes", true)
```

#### net.send_chat_to

```lua
nil net.send_chat_to(number playerId, string message)
```

The `net.send_chat_to` function sends a private chat message to a specific player.

**Parameters:**
- `playerId` (number): The target player's ID.
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

The `net.get_player_list` function returns a table of player IDs currently connected to the server.

**Returns:** An array of player ID numbers.

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

The `net.get_player_info` function returns information about a player. If an attribute is specified, the function returns only that value; otherwise the function returns a table of all attributes. The `ipaddr` and `ucid` attributes are only available in the server hook environment, not from mission scripts.

**Parameters:**
- `playerId` (number): The player's ID.
- `attribute` (string): Optional. The specific attribute to return.

**Attributes:**
- `'id'`: Player ID number
- `'name'`: Player display name
- `'side'`: Coalition (0=spectators, 1=red, 2=blue)
- `'slot'`: Current slot ID
- `'ping'`: Network ping in milliseconds
- `'ipaddr'`: IP address (server only)
- `'ucid'`: Unique Client Identifier (server only)

**Returns:** The attribute value if an attribute was specified, or a table of all attributes otherwise.

```lua
local playerName = net.get_player_info(playerId, 'name')

local info = net.get_player_info(playerId)
env.info("Player: " .. info.name .. " Ping: " .. info.ping .. "ms")
```

#### net.get_my_player_id

```lua
number net.get_my_player_id()
```

The `net.get_my_player_id` function returns the local player's ID. On a server, this function returns the server's player ID.

**Returns:** The player ID as a number.

#### net.get_server_id

```lua
number net.get_server_id()
```

The `net.get_server_id` function returns the server host's player ID.

**Returns:** The server player ID as a number.

#### net.kick

```lua
nil net.kick(number playerId, string message)
```

The `net.kick` function kicks a player from the server.

**Parameters:**
- `playerId` (number): The player to kick.
- `message` (string): The reason shown to the kicked player.

```lua
net.kick(playerId, "AFK timeout")
```

#### net.get_slot

```lua
number, number net.get_slot(number playerId)
```

The `net.get_slot` function returns the slot information for a player.

**Parameters:**
- `playerId` (number): The player's ID.

**Returns:** Two numbers representing the side (coalition) and slotId.

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

The `net.force_player_slot` function forces a player into a specific slot.

**Parameters:**
- `playerId` (number): The player to move.
- `sideId` (number): The target coalition, where 0 is spectators, 1 is red, and 2 is blue.
- `slotId` (number): The target slot ID.

**Returns:** True if the operation was successful.

```lua
-- Move player to spectators
net.force_player_slot(playerId, 0, 0)
```

#### net.get_stat

```lua
number net.get_stat(number playerId, number statId)
```

The `net.get_stat` function returns a statistic for a player.

**Parameters:**
- `playerId` (number): The player's ID.
- `statId` (number): The statistic type ID.

**Returns:** The statistic value as a number.

#### net.get_name

```lua
string net.get_name(number playerId)
```

The `net.get_name` function returns a player's name.

**Parameters:**
- `playerId` (number): The player's ID.

**Returns:** The player name as a string.

#### net.lua2json

```lua
string net.lua2json(table data)
```

The `net.lua2json` function converts a Lua table to a JSON string.

**Parameters:**
- `data` (table): The Lua table to convert.

**Returns:** The JSON string representation of the table.

```lua
local data = {name = "Test", value = 42}
local json = net.lua2json(data)
-- json = '{"name":"Test","value":42}'
```

#### net.json2lua

```lua
table net.json2lua(string json)
```

The `net.json2lua` function converts a JSON string to a Lua table.

**Parameters:**
- `json` (string): The JSON string to parse.

**Returns:** The parsed data as a Lua table.

```lua
local json = '{"name":"Test","value":42}'
local data = net.json2lua(json)
-- data.name = "Test", data.value = 42
```

#### net.dostring_in

```lua
string net.dostring_in(string state, string luaCode)
```

The `net.dostring_in` function executes Lua code in a specific game environment. This function allows cross-environment communication. The executed code runs as a string, so you must return string values; use `tostring()` for numbers.

**Parameters:**
- `state` (string): The target Lua environment.
- `luaCode` (string): The Lua code to execute.

**States:**
- `'config'`: Configuration state ($INSTALL_DIR/Config/main.cfg environment)
- `'mission'`: Mission scripting environment
- `'export'`: Export API environment ($WRITE_DIR/Scripts/Export.lua)

**Returns:** The string result from the executed code.

```lua
local result = net.dostring_in('mission', [[
    local count = 0
    for _, group in pairs(coalition.getGroups(2)) do
        count = count + 1
    end
    return tostring(count)
]])
env.info("Blue has " .. result .. " groups")
```

#### net.log

```lua
nil net.log(string message)
```

The `net.log` function writes a message to the DCS log file.

**Parameters:**
- `message` (string): The message to log.

```lua
net.log("Server hook initialized")
```

### DCS Singleton (Server Context)

In the server hook environment, the `DCS` singleton provides additional server-specific functions.

#### DCS.getMissionName

```lua
string DCS.getMissionName()
```

The `DCS.getMissionName` function returns the name of the currently loaded mission.

**Returns:** The mission name as a string.

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

The `DCS.getMissionFilename` function returns the filename of the currently loaded mission.

**Returns:** The mission filename as a string.

#### DCS.getMissionResult

```lua
table DCS.getMissionResult(number side)
```

The `DCS.getMissionResult` function returns mission results for a coalition.

**Parameters:**
- `side` (number): The coalition, where 1 is red and 2 is blue.

**Returns:** A table of mission result data.

#### DCS.getUnitProperty

```lua
any DCS.getUnitProperty(number unitId, number propertyId)
```

The `DCS.getUnitProperty` function returns a property of a unit by ID.

**Parameters:**
- `unitId` (number): The unit ID.
- `propertyId` (number): The property type ID.

**Returns:** The property value.

#### DCS.setUserCallbacks

```lua
nil DCS.setUserCallbacks(table callbacks)
```

The `DCS.setUserCallbacks` function registers a table of callback functions to receive server hooks.

**Parameters:**
- `callbacks` (table): A table with hook functions as members.

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
