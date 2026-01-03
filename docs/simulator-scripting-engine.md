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
