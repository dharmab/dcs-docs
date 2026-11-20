# Simulator Scripting Engine

The Simulator Scripting Engine (SSE) provides mission designers with programmatic access to the DCS World simulation. Through Lua scripting, mission builders can monitor and control nearly every aspect of a running mission, from spawning units dynamically to tracking combat statistics to creating sophisticated campaign logic that would be impossible with the Mission Editor's trigger system alone.

## Contents

- [Overview](#overview)
- [Scripting Environments](#scripting-environments)
- [Lua Basics](#lua-basics)
- [Data Types](#data-types)
- [Scripting Concepts](#scripting-concepts)
- [Adding Scripts to Missions](#adding-scripts-to-missions)
- [Script Execution Order](#script-execution-order)
- [MIZ File Storage](#miz-file-storage)
- [Debugging](#debugging)
- [API Reference](#api-reference)

## Overview

The SSE exposes the games's internal data and state through Lua, a lightweight programming language designed for embedding in applications. Scripts can read information about the game world and modify it. Scripts can do things like dynamically spawn units based on player actions or game state, execute conditions and event handlers more complex than can be done through Triggers alone, and add custom menus and submenus to the F10 radio menu.

## Scripting Environments

DCS World provides two distinct Lua scripting environments that serve different purposes and have different capabilities.

**Mission scripting** runs inside the simulation as part of a `.miz` mission file. Mission scripts can control units, respond to events, spawn groups, display messages, and manipulate the game world. This document focuses primarily on mission scripting. Mission scripts run in a sandboxed environment with restricted access to the filesystem and operating system for security reasons, since missions downloaded from multiplayer servers execute automatically.

**Server hooks** run outside the simulation in a separate Lua state that persists across mission changes. Server hooks can manage player connections, moderate chat, control mission rotation, and access server administration functions. Unlike mission scripts, server hooks have full access to filesystem and operating system functions. See [Server Hooks](reference/hooks/server-hooks.md) for documentation on server-side scripting.

These two environments cannot directly share variables. They use mostly different APIs and have different security models. Both can call the [`net`](reference/singletons/net.md) API, but server hooks can call extra `net` functions; see [Available APIs](reference/hooks/server-hooks.md#available-apis). Server hooks can run code in the mission environment with [`net.dostring_in`](reference/singletons/net.md#netdostring_in). When reading this documentation, be aware of which environment a feature applies to.

## Lua Basics

For an introduction to the Lua programming language, including variables, tables, control structures, loops, functions, and other fundamentals, see [Lua Basics for DCS Scripting](lua-basics.md).

### Standard Library Availability

Mission scripts have access to most of the Lua standard library, including `math`, `string`, and `table`. Missions are shared online and downloaded from multiplayer servers, and their scripts run without any prompt, so a malicious mission could harm the computer that runs it. To prevent this, `Scripts/MissionScripting.lua` sets six globals to `nil` before any mission script runs: `io`, `lfs`, `os`, `require`, `loadlib`, and `package`. Without `io`, `lfs` (LuaFileSystem), and `os`, a script cannot read, write, or delete files, or start other programs through the operating system shell. Without `require`, `loadlib`, and `package`, a script cannot load Lua modules or DLLs.

Server hooks operate in a different environment with full access to `io`, `lfs`, `os`, and `debug`. See [Server Hooks](reference/hooks/server-hooks.md) for details on server-side scripting capabilities.

Users who want to enable `io`, `lfs`, and `os` in mission scripts for local development or trusted environments can modify `Scripts/MissionScripting.lua` in their DCS installation folder. This file contains lines that sanitize the scripting environment by removing dangerous functions:

```lua
do
	sanitizeModule('os')
	sanitizeModule('io')
	sanitizeModule('lfs')
	_G['require'] = nil
	_G['loadlib'] = nil
	_G['package'] = nil
end
```

Commenting out a line restores that library or function. This process is commonly called "desanitizing" the scripting environment.

Desanitization carries significant security risks. Any mission you load, including missions from multiplayer servers, will gain the ability to access your filesystem. A malicious mission could read sensitive files, install malware, or delete data. Only desanitize if you understand these risks and only play missions from trusted sources.

Additionally, DCS updates typically overwrite `Scripts/MissionScripting.lua`, which resets any desanitization changes. After each DCS update, you must re-apply your modifications if you want to continue using `io`, `lfs`, and `os` in mission scripts.

## Data Types

### Coordinate Systems

DCS World simulates a flat earth model using a Transverse Mercator projection for each theater. Each map has its own projection origin point, and the simulation uses a Cartesian coordinate system measured in meters from that origin. This approach trades global accuracy for local precision, which is appropriate for the scale of combat operations depicted in the simulation.

The terrain engine does not provide a one-to-one representation of real-world geography. Maps are composites assembled from multiple time periods and may include features that have been added, removed, or modified to improve gameplay or engine performance. Features like buildings, roads, and vegetation do not necessarily match their real-world counterparts in location, appearance, or presence. Scripts that rely on real-world geographic data should account for these discrepancies.

The native coordinate system uses X, Y, and Z axes measured in meters. The [coord](reference/singletons/coord.md) singleton provides conversion functions between this native system and real-world coordinate systems including latitude/longitude (geodetic coordinates) and MGRS (Military Grid Reference System, based on UTM). These conversions allow scripts to work with familiar geographic coordinates while the engine operates in its internal Cartesian space.

Vec2 and Vec3 share the `x` axis (north-south, positive north) but use different conventions for the "y" axis. In Vec2, `y` is the east-west position (positive east). In Vec3, `y` is altitude while `z` is east-west. This difference is a common source of confusion when converting between the two formats. See [Coordinate Types](reference/types/coordinates.md) for formal type definitions.

### Time Values

The DCS scripting engine measures mission time in seconds as a floating-point number with millisecond precision. The [timer](reference/singletons/timer.md) singleton provides time-related functions. The [`timer.getTime()`](reference/singletons/timer.md#timergettime) function returns mission time, which is the number of seconds since the mission started and pauses when the game is paused. The [`timer.getAbsTime()`](reference/singletons/timer.md#timergetabstime) function returns absolute time, which is the number of seconds since midnight of the mission date. The [`timer.getTime0()`](reference/singletons/timer.md#timergettime0) function returns the mission start time expressed as absolute time.

### Distance and Angles

All distances in the DCS scripting engine are measured in meters. All angles are measured in radians unless otherwise noted. To convert between degrees and radians:

```lua
local radians = degrees * math.pi / 180
local degrees = radians * 180 / math.pi
```

Headings use true north as 0 and increase clockwise: East is π/2, South is π, and West is 3π/2.

## Scripting Concepts

### Singletons

A singleton is a global object that provides access to a category of game functionality. You access singletons by their name, then call functions on them. For example, [`timer.getTime()`](reference/singletons/timer.md#timergettime) calls the [`getTime`](reference/singletons/timer.md#timergettime) function on the [`timer`](reference/singletons/timer.md) singleton.

The main singletons are:

| Singleton                                                     | Purpose                                               |
| ------------------------------------------------------------- | ----------------------------------------------------- |
| [`env`](reference/singletons/env.md)                          | Logging and environment information                   |
| [`timer`](reference/singletons/timer.md)                      | Mission time and scheduled functions                  |
| [`land`](reference/singletons/land.md)                        | Terrain queries (ground height, surface type)         |
| [`atmosphere`](reference/singletons/atmosphere.md)            | Weather conditions                                    |
| [`world`](reference/singletons/world.md)                      | Event handlers and object searches                    |
| [`coalition`](reference/singletons/coalition.md)              | Operations related to the red and blue sides          |
| [`trigger`](reference/singletons/trigger.md)                  | Trigger zones and trigger-style actions like messages |
| [`coord`](reference/singletons/coord.md)                      | Coordinate conversions (lat/long to game coordinates) |
| [`missionCommands`](reference/singletons/mission-commands.md) | F10 radio menu manipulation                           |
| [`net`](reference/singletons/net.md)                          | Chat, player information, and slot control            |

### Objects and Functions

The game world contains objects: aircraft, ground units, ships, airbases, weapons, and scenery. Scripts can get references to these objects and then call functions on them to get information or make changes.

For example, use [`Unit.getByName()`](reference/classes/unit.md#unitgetbyname) to get a unit, [`Unit:getFuel()`](reference/classes/unit.md#unitgetfuel) to check its remaining fuel, and [`trigger.action.outText()`](reference/singletons/trigger.md#triggeractionouttext) to display the result:

```lua
-- Get a reference to a unit named "Eagle 1-1"
local eagle = Unit.getByName("Eagle 1-1")

-- Check if the unit exists (it might have been destroyed)
if eagle then
    -- Get the fuel level as a percentage (0.0 to 1.0)
    local fuelPercent = eagle:getFuel()
    -- Convert to percentage for display
    trigger.action.outText("Fuel: " .. math.floor(fuelPercent * 100) .. "%", 5)
end
```

Note the colon (`:`) when calling functions on objects: [`eagle:getFuel()`](reference/classes/unit.md#unitgetfuel). This is Lua syntax for calling a function that belongs to an object. The singleton functions use a dot (`.`) instead: [`timer.getTime()`](reference/singletons/timer.md#timergettime).

Common object types and some of their functions:

**Unit** (aircraft, vehicles, ships)

- [`getName()`](reference/classes/object.md#objectgetname) - Get the unit's name
- [`getPosition()`](reference/classes/object.md#objectgetposition) - Get location and orientation
- [`getLife()`](reference/classes/unit.md#unitgetlife) - Get remaining hit points
- [`getFuel()`](reference/classes/unit.md#unitgetfuel) - Get fuel level (0.0 to 1.0)
- [`getAmmo()`](reference/classes/unit.md#unitgetammo) - Get ammunition counts
- [`getVelocity()`](reference/classes/object.md#objectgetvelocity) - Get speed and direction of movement
- [`inAir()`](reference/classes/object.md#objectinair) - Check if an aircraft is flying

**Group** (collection of units)

- [`getName()`](reference/classes/group.md#groupgetname) - Get the group's name
- [`getUnits()`](reference/classes/group.md#groupgetunits) - Get a list of all units in the group
- [`getSize()`](reference/classes/group.md#groupgetsize) - Get how many units are in the group
- [`activate()`](reference/classes/group.md#groupactivate) - Activate a late-activation group

**Airbase** (airports, FARPs, carriers)

- [`getName()`](reference/classes/object.md#objectgetname) - Get the airbase name
- [`getCallsign()`](reference/classes/airbase.md#airbasegetcallsign) - Get the radio callsign
- [`getParking()`](reference/classes/airbase.md#airbasegetparking) - Get parking spot information

### Events

The event system notifies your scripts when things happen in the simulation. You create an event handler and register it with [`world.addEventHandler()`](reference/singletons/world.md#worldaddeventhandler), then your handler function gets called whenever events occur. This example uses [`getName()`](reference/classes/object.md#objectgetname) and [`trigger.action.outText()`](reference/singletons/trigger.md#triggeractionouttext) to announce a destroyed unit.

```lua
-- Create a table to serve as our event handler
local deathTracker = {}

-- Define what happens when an event occurs
function deathTracker:onEvent(event)
    -- Check if this is a unit being destroyed
    if event.id == world.event.S_EVENT_DEAD then
        local deadUnit = event.initiator
        if deadUnit then
            trigger.action.outText(deadUnit:getName() .. " was destroyed!", 10)
        end
    end
end

-- Register our handler to receive events
world.addEventHandler(deathTracker)
```

Common events include:

| Event                       | When it fires                    |
| --------------------------- | -------------------------------- |
| `S_EVENT_SHOT`              | A weapon is fired                |
| `S_EVENT_HIT`               | An object is struck by a weapon  |
| `S_EVENT_TAKEOFF`           | An aircraft departs              |
| `S_EVENT_LAND`              | An aircraft lands                |
| `S_EVENT_RUNWAY_TAKEOFF`    | An aircraft leaves the ground    |
| `S_EVENT_RUNWAY_TOUCH`      | An aircraft touches down         |
| `S_EVENT_CRASH`             | An aircraft crashes              |
| `S_EVENT_EJECTION`          | A pilot ejects                   |
| `S_EVENT_DEAD`              | An object is destroyed           |
| `S_EVENT_BIRTH`             | A unit spawns                    |
| `S_EVENT_PLAYER_ENTER_UNIT` | A player takes control of a unit |
| `S_EVENT_KILL`              | One unit kills another           |
| `S_EVENT_MARK_ADDED`        | A map marker is created          |

The event table passed to your handler contains different information depending on the event type. Most events include `id` (which event occurred), `time` (mission time), and `initiator` (the object involved).

### Scheduled Functions

You can tell the game to run a function at a specific time in the future with [`timer.scheduleFunction()`](reference/singletons/timer.md#timerschedulefunction). This is useful for periodic checks, delayed actions, or creating repeating behaviors. This example reads the mission time with [`timer.getTime()`](reference/singletons/timer.md#timergettime) and displays it with [`trigger.action.outText()`](reference/singletons/trigger.md#triggeractionouttext).

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

### Startup and Long-Running Work

The scripting engine is unreliable right after mission start while assets are still loading. Delay mission scripts by at least 5 seconds after start, longer for players on slow machines.

Scripts run on the simulation thread, so long blocking calls freeze or stutter the game. Freezes usually show up in `dcs.log` as this pair of lines:

```
ModelTimeQuantizer: ANTIFREEZE ENABLED
ModelTimeQuantizer: SAME MODEL TIME
```

ED hasn't documented these messages. They appear during freezes from many causes, including mods, `Export.lua` hooks, and heavy mission scripts. If they show up while your script is running, the script is probably blocking too long.

Spread large jobs across frames with a batch scheduler. Operation Infinity's [`BatchScheduler.lua`](../../missions/operation-infinity/src/l10n/DEFAULT/BatchScheduler.lua) is a reference implementation with two functions:

- `BatchScheduler:processArray` calls a callback for each array item, stops when the per-frame time budget is spent, and reschedules itself for the next frame until done.
- `BatchScheduler:runSequence` runs async steps in order. Each step receives a `done(err)` callback and the next step starts on the following frame.

```lua
BatchScheduler:processArray({
    array = groupsToSpawn,
    callback = function(groupData, index, context)
        coalition.addGroup(context.country, Group.Category.GROUND, groupData)
    end,
    onComplete = function(context)
        env.info("Spawned " .. #groupsToSpawn .. " groups")
    end,
    context = { country = country.id.RUSSIA },
})
```

## Adding Scripts to Missions

Scripts can be embedded in missions through several mechanisms in the Mission Editor:

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

This example uses [`Group:getName()`](reference/classes/group.md#groupgetname) to get the group's name and [`trigger.action.outText()`](reference/singletons/trigger.md#triggeractionouttext) to display a message. This feature lets you write one script and attach it to multiple groups without having to change the group name in the code each time.

### Group Spawn Condition

Each group can have a spawn condition script that runs during mission loading. This script must return either `true` or `false` to determine whether the group spawns into the mission.

```lua
-- 50% chance to spawn this group
return math.random() < 0.5
```

If the script returns `true`, the group spawns normally. If it returns `false`, the group does not appear in the mission at all.

### LUA Predicate Condition

Triggers can use the LUA PREDICATE condition type to evaluate custom Lua code. The script must return `true` or `false`. This enables complex conditions that the built-in trigger conditions cannot express, such as checking for a group with [`Group.getByName()`](reference/classes/group.md#groupgetbyname):

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

When scripts do not work as expected, logging helps you understand what is happening. The [`env`](reference/singletons/env.md) singleton provides logging functions: [`env.info()`](reference/singletons/env.md#envinfo), [`env.warning()`](reference/singletons/env.md#envwarning), and [`env.error()`](reference/singletons/env.md#enverror).

```lua
env.info("This is an information message")
env.warning("This is a warning")
env.error("This is an error")
```

These messages appear in `dcs.log` in your DCS Saved Games directory (typically `C:\Users\[YourName]\Saved Games\DCS` or `DCS.openbeta`). Open this file in a text editor to see your messages along with any errors the game encountered.

You can also display messages in-game with [`trigger.action.outText()`](reference/singletons/trigger.md#triggeractionouttext) for quick feedback while developing:

```lua
trigger.action.outText("Debug: reached this point in the code", 5)
```

The number at the end (5) is how many seconds the message stays on screen.

## API Reference

The reference documentation is organized into the [reference/](reference/) directory.

### Types and Enums

| Reference                                          | Description                                   |
| -------------------------------------------------- | --------------------------------------------- |
| [Coordinate Types](reference/types/coordinates.md) | Vec2, Vec3, Position3 type definitions        |
| [Coalition Enums](reference/enums/coalition.md)    | Coalition and country identifiers             |
| [AI Enums](reference/enums/ai.md)                  | AI skill levels, task enums, and beacon types |

### Singletons

| Singleton                                                   | Description                                                           |
| ----------------------------------------------------------- | --------------------------------------------------------------------- |
| [timer](reference/singletons/timer.md)                      | Mission time and scheduled functions                                  |
| [env](reference/singletons/env.md)                          | Logging, environment info, and mission data access                    |
| [trigger](reference/singletons/trigger.md)                  | Trigger zones and trigger-style actions (messages, smoke, explosions) |
| [world](reference/singletons/world.md)                      | Event handlers, object searches, and world queries                    |
| [coalition](reference/singletons/coalition.md)              | Coalition-specific operations, group spawning, and queries            |
| [missionCommands](reference/singletons/mission-commands.md) | F10 radio menu manipulation                                           |
| [net](reference/singletons/net.md)                          | Chat, player information, and slot control                            |
| [coord](reference/singletons/coord.md)                      | Coordinate conversions (lat/long, MGRS, game coordinates)             |
| [land](reference/singletons/land.md)                        | Terrain queries (height, surface type, line of sight, pathfinding)    |
| [atmosphere](reference/singletons/atmosphere.md)            | Weather conditions (wind, temperature, pressure)                      |

### Classes

| Class                                                    | Description                                           |
| -------------------------------------------------------- | ----------------------------------------------------- |
| [Object](reference/classes/object.md)                    | Base class for all game objects                       |
| [CoalitionObject](reference/classes/coalition-object.md) | Extends Object with coalition and country information |
| [Unit](reference/classes/unit.md)                        | Aircraft, vehicles, ships, and structures             |
| [Group](reference/classes/group.md)                      | Collections of units                                  |
| [Airbase](reference/classes/airbase.md)                  | Airports, FARPs, and carriers                         |
| [StaticObject](reference/classes/static-object.md)       | Non-moving objects (buildings, cargo, decorations)    |
| [Weapon](reference/classes/weapon.md)                    | Weapons in flight (missiles, bombs, rockets)          |
| [Controller](reference/classes/controller.md)            | AI control interface for issuing tasks and commands   |
| [Spot](reference/classes/spot.md)                        | Laser and infrared designator spots                   |

### Events

| Reference                            | Description                               |
| ------------------------------------ | ----------------------------------------- |
| [Events](reference/events/events.md) | Event system overview and all event types |

### AI Control

| Reference                               | Description                                    |
| --------------------------------------- | ---------------------------------------------- |
| [AI Tasks](reference/ai/tasks.md)       | Main tasks, en-route tasks, and task wrappers  |
| [AI Commands](reference/ai/commands.md) | Instant AI commands (frequency, beacons, etc.) |
| [AI Options](reference/ai/options.md)   | Air, ground, and naval behavior options        |

### Server Development

| Reference                                       | Description                                                       |
| ----------------------------------------------- | ----------------------------------------------------------------- |
| [Server Hooks](reference/hooks/server-hooks.md) | Server-side scripting API (lfs, Sim, log, net, Export, callbacks) |
