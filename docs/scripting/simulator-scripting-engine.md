# Simulator Scripting Engine

The Simulator Scripting Engine (SSE) runs [Lua](https://www.lua.org/about.html) scripts inside a DCS World mission and provides the functions those scripts use to read and control the simulation. For example, scripts can:

- Spawn groups during the mission
- React to events such as shots, kills, and takeoffs
- Give AI groups new tasks
- Add player commands to the F10 radio menu
- Draw lines, shapes, and text on the F10 map

## Contents

- [Overview](#overview)
- [Scripting Environments](#scripting-environments)
- [Standard Library Availability](#standard-library-availability)
- [Data Types](#data-types)
- [Scripting Concepts](#scripting-concepts)
- [Adding Scripts to Missions](#adding-scripts-to-missions)
- [Script Execution Order](#script-execution-order)
- [MIZ File Storage](#miz-file-storage)
- [Debugging](#debugging)
- [API Reference](#api-reference)

## Overview

DCS scripts are written in Lua, a scripting language that many games use for mods and in-game scripting. Lua is easy to learn, and you can pick it up as you go. If you are new to Lua, start with [Lua Basics](lua-basics.md).

## Scripting Environments

DCS World runs Lua scripts in two separate environments: mission scripts and server hooks. This document covers mission scripts.

**Mission scripts** are stored in a mission's `.miz` file, and they run while that mission runs. Mission scripts work with the game world: units, groups, events, triggers, and the F10 map. By default, mission scripts cannot access the filesystem or operating system, because a mission downloaded from the internet runs its scripts automatically.

**Server hooks** are Lua files in the `Scripts/Hooks` folder in the DCS Saved Games directory. DCS loads them at startup, and they keep running as missions load and end. Hooks can access the filesystem and operating system. Multiplayer servers use hooks to manage players, chat, and mission rotation. See [Server Hooks](reference/hooks/server-hooks.md).

Use a mission script for behavior specific to one mission. Use a server hook for behavior that applies to every mission on a server, or that needs the filesystem or operating system.

The two environments do not share variables, and most functions are available in only one of them. Most of this documentation, including the `coalition`, `trigger`, and `world` singletons, applies only to mission scripts. The [Available APIs](reference/hooks/server-hooks.md#available-apis) table lists which APIs each environment can call.

## Standard Library Availability

Mission scripts have access to most of the Lua standard library, including `math`, `string`, and `table`. Missions are shared online and downloaded from multiplayer servers, and their scripts run without any prompt, so a malicious mission could harm the computer that runs it. To prevent this, `Scripts/MissionScripting.lua` sets six globals to `nil` before any mission script runs: `io`, `lfs`, `os`, `require`, `loadlib`, and `package`. Without `io`, `lfs` (LuaFileSystem), and `os`, a script cannot read, write, or delete files, or start other programs through the operating system shell. Without `require`, `loadlib`, and `package`, a script cannot load Lua modules or DLLs.

Server hooks have full access to `io`, `lfs`, `os`, and `debug`. See [Server Hooks](reference/hooks/server-hooks.md).

To enable `io`, `lfs`, and `os` in mission scripts for local development, edit `Scripts/MissionScripting.lua` in the DCS installation folder. These lines remove the libraries:

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

Desanitizing is a security risk. Every mission you load, including missions from multiplayer servers, can then access your filesystem, so a malicious mission could read files, install malware, or delete data. Only desanitize if you play only trusted missions.

DCS updates usually overwrite `Scripts/MissionScripting.lua`. Re-apply the changes after each update.

## Data Types

### Coordinate Systems

DCS World uses a flat earth with a Transverse Mercator projection per theater. Each map has its own origin, and positions are Cartesian coordinates in meters from that origin. This trades global accuracy for local precision.

Maps do not match real geography exactly. They are composites from several time periods, with features added, removed, or changed for gameplay or performance. Buildings, roads, and vegetation may differ from the real world in location, appearance, or presence. Scripts that use real-world geographic data must allow for this.

Native coordinates are X, Y, and Z in meters. The [coord](reference/singletons/coord.md) singleton converts between native coordinates, latitude/longitude, and MGRS (Military Grid Reference System, based on UTM).

Vec2 and Vec3 share the `x` axis (north-south, positive north) but use different conventions for the "y" axis. In Vec2, `y` is the east-west position (positive east). In Vec3, `y` is altitude while `z` is east-west. This difference is a common source of bugs. See [Coordinate Types](reference/types/coordinates.md) for formal type definitions.

### Time Values

DCS scripts work with two kinds of time. Both are in seconds, as floating-point numbers with millisecond precision.

- **Mission time** is the number of seconds since the mission started. It stops while the game is paused. The [`timer.getTime()`](reference/singletons/timer.md#timergettime) function returns mission time.
- **Absolute time** is the time of day in the mission, as the number of seconds since midnight on the mission date. The [`timer.getAbsTime()`](reference/singletons/timer.md#timergetabstime) function returns absolute time, and the [`timer.getTime0()`](reference/singletons/timer.md#timergettime0) function returns the absolute time when the mission started.

Use mission time to measure durations, such as how long ago an event happened. Use absolute time when the time of day matters. All three functions are in the [timer](reference/singletons/timer.md) singleton.

### Distance and Angles

The DCS scripting engine measures all distances in meters and all angles in radians, unless a function's documentation says otherwise. Many cockpits and briefings use feet, nautical miles, and degrees instead, so scripts often need to convert values.

To convert between meters and feet or nautical miles:

```lua
local meters = feet * 0.3048
local feet = meters / 0.3048

local meters = nauticalMiles * 1852
local nauticalMiles = meters / 1852
```

To convert between degrees and radians:

```lua
local radians = degrees * math.pi / 180
local degrees = radians * 180 / math.pi
```

Headings use true north as 0 and increase clockwise: East is π/2, South is π, and West is 3π/2.

## Scripting Concepts

### Singletons

A singleton is a global object that groups related game functions. For example, [`timer.getTime()`](reference/singletons/timer.md#timergettime) calls the [`getTime`](reference/singletons/timer.md#timergettime) function on the [`timer`](reference/singletons/timer.md) singleton.

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

Objects in the game world include aircraft, ground units, ships, airbases, weapons, and scenery. Scripts obtain references to objects and call functions on them.

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

Object methods use a colon (`:`): [`eagle:getFuel()`](reference/classes/unit.md#unitgetfuel). Singleton functions use a dot (`.`): [`timer.getTime()`](reference/singletons/timer.md#timergettime).

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

DCS creates an event each time something happens in the simulation, such as an aircraft taking off, a unit firing a weapon, or a unit being destroyed. Scripts react to events with an event handler, which is a table containing an `onEvent` function. After a script registers the handler with [`world.addEventHandler()`](reference/singletons/world.md#worldaddeventhandler), DCS calls the handler's `onEvent` function for every event. DCS passes the function a table describing the event, and the function checks the event's `id` to decide whether to act.

This example uses [`getName()`](reference/classes/object.md#objectgetname) and [`trigger.action.outText()`](reference/singletons/trigger.md#triggeractionouttext) to announce a destroyed unit.

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

The event table's fields depend on the event type. Most events include `id` (which event occurred), `time` (mission time), and `initiator` (the object involved).

### Scheduled Functions

[`timer.scheduleFunction()`](reference/singletons/timer.md#timerschedulefunction) runs a function at a future mission time, for periodic checks, delayed actions, or repeating behavior. This example reads the mission time with [`timer.getTime()`](reference/singletons/timer.md#timergettime) and displays it with [`trigger.action.outText()`](reference/singletons/trigger.md#triggeractionouttext).

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

The Mission Editor can add scripts to a mission in several ways:

### Initialization Script

The initialization script runs as the mission loads, before units spawn or triggers evaluate. It is the earliest point scripts run. Set it in the Triggers panel's initialization slot.

Use the initialization script to set up global variables, define functions for later use, and configure settings that must be in place before the mission begins.

### Trigger Actions

Two trigger actions run scripts:

**Do Script** embeds Lua code in the mission file from a text box. The text box has a size limit and no syntax highlighting, and the code ends up inside the mission's Lua data where external tools cannot easily work with it.

**Do Script File** references a Lua file, which the Mission Editor copies into the mission archive. The code stays in standalone `.lua` files, so editors, language servers, formatters such as StyLua, and AI coding assistants can work with it.

New missions should use Do Script File. Reserve Do Script for trivial one-liners.

Both actions run the script once each time the trigger activates. A trigger activates once or repeatedly depending on its type.

### Group Actions

Scripts can be attached to a group through waypoint actions and triggered actions.

In a group action script, `...` (three dots) is the group the script is attached to. This lets you write one script that works for any group:

```lua
-- Within a group action, ... refers to the current group
local thisGroup = ...
local groupName = thisGroup:getName()
trigger.action.outText("Group " .. groupName .. " is doing something", 10)
```

This example uses [`Group:getName()`](reference/classes/group.md#groupgetname) and [`trigger.action.outText()`](reference/singletons/trigger.md#triggeractionouttext).

### Group Spawn Condition

A group can have a spawn condition script that runs during mission loading and returns `true` or `false`.

```lua
-- 50% chance to spawn this group
return math.random() < 0.5
```

If it returns `false`, the group does not appear in the mission.

### LUA Predicate Condition

The LUA PREDICATE trigger condition runs Lua code that returns `true` or `false`. Use it for conditions that the built-in conditions cannot express.

For example, built-in conditions such as GROUP ALIVE only recognize groups placed in the Mission Editor. To check for a group that a script spawned, use [`Group.getByName()`](reference/classes/group.md#groupgetbyname) in a LUA PREDICATE:

```lua
-- Check if a group named 'reinforcements' exists
if Group.getByName('reinforcements') then
    return true
else
    return false
end
```

## Script Execution Order

Execution order matters when scripts depend on each other. If script B uses a function defined in script A, script A must run first.

The execution order is:

1. **Initialization Script** - Runs first as the mission loads
2. **Group Spawn Conditions** - Evaluate during mission loading
3. **MISSION START Triggers** - Execute at mission start
4. **Waypoint 1 Scripts** - Execute as groups spawn at their first waypoints
5. **Triggers true at mission start** - Triggers whose conditions are true at time 0, such as `TIME LESS 1`
6. **Triggers true later** - Triggers whose conditions first become true after time 0, such as `TIME MORE 0`
7. **Waypoint 2+ Scripts** - Execute as groups reach subsequent waypoints

Within a single trigger, conditions and actions evaluate top to bottom in the order they appear in the editor. If trigger A is above trigger B in the trigger list and both execute at the same time, trigger A runs first.

This order lets a single trigger load dependent scripts in sequence:

```
Once > Time More than 3 > Do Script File(A.lua) AND Do Script File(B.lua) AND Do Script File(C.lua)
```

If script C depends on B and B depends on A, this trigger loads them in order, because actions run left to right.

## MIZ File Storage

Knowing how scripts are stored lets you update them without the Mission Editor.

MIZ files are ZIP archives. **Do Script** code is stored as text in the trigger data in the `mission` file.

When you use **Do Script File**, the Lua file is:

1. Copied into the `l10n/DEFAULT` directory inside the archive
2. Registered in the `l10n/DEFAULT/mapResource` file
3. Referenced by the trigger action

You can extract a MIZ file, edit the Lua files, and repack it without opening the Mission Editor.

## Debugging

The [`env`](reference/singletons/env.md) singleton contains logging functions: [`env.info()`](reference/singletons/env.md#envinfo), [`env.warning()`](reference/singletons/env.md#envwarning), and [`env.error()`](reference/singletons/env.md#enverror).

```lua
env.info("This is an information message")
env.warning("This is a warning")
env.error("This is an error")
```

Messages go to `dcs.log` in the DCS Saved Games directory (typically `C:\Users\[YourName]\Saved Games\DCS` or `DCS.openbeta`), along with game errors.

[`trigger.action.outText()`](reference/singletons/trigger.md#triggeractionouttext) displays messages in-game:

```lua
trigger.action.outText("Debug: reached this point in the code", 5)
```

The number at the end (5) is how many seconds the message stays on screen.

## API Reference

Reference pages are in [reference/](reference/).

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
