# Server Hooks

Server hooks provide a scripting environment for DCS World servers that operates independently of any specific mission. Unlike mission scripts that are bundled with `.miz` files, server hook scripts persist across mission changes and provide control over player connections, chat moderation, mission rotation, and server administration.

## Overview

### Differences from Mission Scripting

Server hooks differ from mission scripting (the SSE) in several important ways:

| Aspect | Mission Scripting | Server Hooks |
|--------|------------------|--------------|
| Location | Inside `.miz` files | `$WRITE_DIR/Scripts/Hooks/` |
| Lua State | Mission environment | GUI/hooks environment |
| Persistence | Resets each mission | Persists across missions |
| Access | Unit/group control, triggers | Player management, server control |
| API | `trigger`, `coalition`, `Group`, etc. | `Sim`, `net`, `log`, `Export` |

### The Saved Games Folder ($WRITE_DIR)

Throughout this documentation, `$WRITE_DIR` refers to the DCS "Saved Games" folder. This path varies by installation type:

| Installation | Path |
|--------------|------|
| Steam | `%userprofile%\Saved Games\DCS` |
| Standalone | `%userprofile%\Saved Games\DCS` |
| Legacy Open Beta | `%userprofile%\Saved Games\DCS.Openbeta` |

> **Note:** If you upgraded from an Open Beta version prior to patch 2.9.3.51704, your saved games folder may still be `DCS.Openbeta` even after the Open Beta and Stable versions were unified.

The `%userprofile%` variable typically expands to `C:\Users\YourUsername`.

### How Hooks Are Loaded

When DCS starts, it searches for Lua files in `$WRITE_DIR/Scripts/Hooks/`. All `*.lua` files in this directory are:

1. Sorted alphabetically by filename
2. Loaded into the GUI Lua state
3. Each script runs in an isolated environment

Scripts share the simulator state but not their local variables. This isolation means multiple hook scripts can coexist without interfering with each other.

## Getting Started

### Creating a Hook Script

Create a new file in `$WRITE_DIR/Scripts/Hooks/` with a `.lua` extension:

```lua
-- $WRITE_DIR/Scripts/Hooks/MyServerHooks.lua

local myHooks = {}

function myHooks.onPlayerTryConnect(addr, name, ucid, playerID)
    print(string.format("Connection attempt: %s (%s) from %s", name, ucid, addr))
    return true  -- Allow connection
end

function myHooks.onSimulationStart()
    print("Current mission is " .. Sim.getMissionName())
end

-- Register the callbacks
Sim.setUserCallbacks(myHooks)
```

### Callback Registration

Callbacks are registered by creating a table with callback functions and passing it to `Sim.setUserCallbacks()`. For each event type, all registered hooks from all scripts are called in the order the scripts were loaded (alphabetically by filename).

### Return Value Behavior

Most callbacks have no return value. However, three callbacks can return values to control behavior:

- `onPlayerTryConnect`
- `onPlayerTrySendChat`
- `onPlayerTryChangeSlot`

For these callbacks:
- Returning a value breaks the callback chain and uses that result
- Returning nothing (or `nil`) continues to the next hook in the chain
- If no hook returns a value, a default allow-all behavior is used

## Lua API Reference

Server hook scripts have access to standard Lua 5.1 libraries plus DCS-specific APIs.

### Standard Libraries

All standard Lua 5.1 libraries are available:

- Base API (`print`, `type`, `pairs`, `ipairs`, `tonumber`, `tostring`, etc.)
- `math.*`
- `table.*`
- `string.*`
- `io.*`
- `os.*`
- `debug.*`

### Lua File System (lfs)

The `lfs` module provides file system access.

#### lfs.currentdir

```lua
string lfs.currentdir()
```

Returns the path of the DCS installation folder.

**Returns:** The installation directory path as a string.

#### lfs.writedir

```lua
string lfs.writedir()
```

Returns the path of the current Saved Games folder (`$WRITE_DIR`).

**Returns:** The write directory path as a string.

```lua
local writeDir = lfs.writedir()
-- e.g., "C:\Users\Username\Saved Games\DCS\"
```

#### lfs.tempdir

```lua
string lfs.tempdir()
```

Returns the path of the application temp folder, typically inside `AppData\Local\Temp\`.

**Returns:** The temp directory path as a string.

#### lfs.mkdir

```lua
boolean, string lfs.mkdir(string path)
```

Creates a new directory.

**Parameters:**
- `path` (string): The path of the directory to create.

**Returns:** `true` on success, or `nil` and an error message on failure.

#### lfs.rmdir

```lua
boolean, string lfs.rmdir(string path)
```

Removes an empty directory.

**Parameters:**
- `path` (string): The path of the directory to remove.

**Returns:** `true` on success, or `nil` and an error message on failure.

#### lfs.attributes

```lua
table lfs.attributes(string path, string attributeName)
```

Returns file or directory attributes.

**Parameters:**
- `path` (string): The path to query.
- `attributeName` (string): Optional. A specific attribute to return.

**Returns:** A table of attributes, or a specific attribute value.

#### lfs.dir

```lua
iterator lfs.dir(string path)
```

Returns an iterator over directory entries.

**Parameters:**
- `path` (string): The directory path.

**Returns:** An iterator function.

```lua
for entry in lfs.dir(lfs.writedir() .. "Missions") do
    if entry ~= "." and entry ~= ".." then
        print(entry)
    end
end
```

#### lfs.normpath

```lua
string lfs.normpath(string path)
```

Normalizes a file path.

**Parameters:**
- `path` (string): The path to normalize.

**Returns:** The normalized path.

#### lfs.realpath

```lua
string lfs.realpath(string path)
```

Returns the absolute path, resolving any symbolic links.

**Parameters:**
- `path` (string): The path to resolve.

**Returns:** The resolved absolute path.

### Sim Control API (Sim.*)

The `Sim` singleton provides simulation control functions.

#### Sim.setUserCallbacks

```lua
nil Sim.setUserCallbacks(table callbacks)
```

Registers a table of callback functions to receive server hooks.

**Parameters:**
- `callbacks` (table): A table with hook functions as members.

```lua
local myHooks = {}
function myHooks.onSimulationStart()
    print("Simulation started!")
end
Sim.setUserCallbacks(myHooks)
```

#### Sim.setPause

```lua
nil Sim.setPause(boolean paused)
```

Pauses or resumes the simulation. This function is only available on the server.

**Parameters:**
- `paused` (boolean): `true` to pause, `false` to resume.

#### Sim.getPause

```lua
boolean Sim.getPause()
```

Returns whether the simulation is currently paused.

**Returns:** `true` if paused, `false` otherwise.

#### Sim.stopMission

```lua
nil Sim.stopMission()
```

Stops the current mission.

#### Sim.exitProcess

```lua
nil Sim.exitProcess()
```

Exits the DCS process.

#### Sim.isMultiplayer

```lua
boolean Sim.isMultiplayer()
```

Returns whether the game is running in multiplayer mode.

**Returns:** `true` if multiplayer, `false` if single-player.

#### Sim.isServer

```lua
boolean Sim.isServer()
```

Returns whether this instance is running as a server or in single-player mode.

**Returns:** `true` if server or single-player, `false` if client.

#### Sim.getModelTime

```lua
number Sim.getModelTime()
```

Returns the current simulation time in seconds.

**Returns:** Simulation time in seconds.

#### Sim.getRealTime

```lua
number Sim.getRealTime()
```

Returns the real time in seconds since application start.

**Returns:** Real time in seconds.

#### Sim.getMissionOptions

```lua
table Sim.getMissionOptions()
```

Returns the mission options table from the current mission.

**Returns:** The `mission.options` table.

#### Sim.getMissionDescription

```lua
string Sim.getMissionDescription()
```

Returns the translated mission description text.

**Returns:** The description string.

#### Sim.getAvailableCoalitions

```lua
table Sim.getAvailableCoalitions()
```

Returns coalitions that have available slots.

**Returns:** A table where keys are coalition IDs and values are tables with a `name` field.

```lua
local coalitions = Sim.getAvailableCoalitions()
-- { [1] = { name = "Red" }, [2] = { name = "Blue" } }
```

#### Sim.getAvailableSlots

```lua
table Sim.getAvailableSlots(number coalitionID)
```

Returns available slots for a coalition.

**Parameters:**
- `coalitionID` (number): The coalition ID (1=red, 2=blue).

**Returns:** An array of slot tables, each containing:
- `unitId`: The slot ID (for multi-seat units this is `unitID_seatID`)
- `type`: Aircraft type
- `role`: Crew position/role
- `callsign`: Unit callsign
- `groupName`: Group name
- `country`: Country ID

#### Sim.getCurrentMission

```lua
table Sim.getCurrentMission()
```

Returns the full mission table for the currently loaded mission.

**Returns:** The mission table.

> **Note:** To get valid mission options, use `Sim.getMissionOptions()` instead.

#### Sim.getMissionName

```lua
string Sim.getMissionName()
```

Returns the name of the current mission.

**Returns:** The mission name.

#### Sim.getMissionFilename

```lua
string Sim.getMissionFilename()
```

Returns the filename of the current mission. Returns `nil` when running as a multiplayer client.

**Returns:** The mission filename, or `nil`.

#### Sim.getMissionResult

```lua
number Sim.getMissionResult(string side)
```

Returns the mission result score for a side.

**Parameters:**
- `side` (string): Either `"red"` or `"blue"`.

**Returns:** A score from 0 to 100.

#### Sim.getUnitProperty

```lua
any Sim.getUnitProperty(number missionId, number propertyId)
```

Returns a property of a unit by its mission ID.

**Parameters:**
- `missionId` (number): The unit's mission ID.
- `propertyId` (number): One of the `Sim.UNIT_*` constants.

**Property Constants:**
- `Sim.UNIT_RUNTIME_ID` - Unique within runtime mission (int)
- `Sim.UNIT_MISSION_ID` - Unique within mission file (int > 0)
- `Sim.UNIT_NAME` - Unit name from mission designer
- `Sim.UNIT_TYPE` - Unit type (e.g., "Ural", "ZU-23")
- `Sim.UNIT_CATEGORY` - Unit category
- `Sim.UNIT_GROUP_MISSION_ID` - Group ID (int > 0)
- `Sim.UNIT_GROUPNAME` - Group name from mission designer
- `Sim.UNIT_GROUPCATEGORY` - Group category
- `Sim.UNIT_CALLSIGN` - Unit callsign
- `Sim.UNIT_HIDDEN` - Mission Editor hidden flag
- `Sim.UNIT_COALITION` - "blue", "red", or "neutral"
- `Sim.UNIT_COUNTRY_ID` - Country ID
- `Sim.UNIT_TASK` - Group task
- `Sim.UNIT_PLAYER_NAME` - Player name for occupied units
- `Sim.UNIT_ROLE` - Role (e.g., "artillery_commander", "instructor")
- `Sim.UNIT_INVISIBLE_MAP_ICON` - Mission Editor invisible icon flag

**Returns:** The property value.

#### Sim.getUnitType

```lua
string Sim.getUnitType(number missionId)
```

Returns the unit type for a mission ID. This is a shortcut for `Sim.getUnitProperty(missionId, Sim.UNIT_TYPE)`.

**Parameters:**
- `missionId` (number): The unit's mission ID.

**Returns:** The unit type string.

#### Sim.getUnitTypeAttribute

```lua
string Sim.getUnitTypeAttribute(string typeId, string attribute)
```

Returns a database attribute for a unit type.

**Parameters:**
- `typeId` (string): The unit type (e.g., "Ural").
- `attribute` (string): The attribute name.

**Returns:** The attribute value.

```lua
local displayName = Sim.getUnitTypeAttribute("Ural", "DisplayName")
```

#### Sim.writeDebriefing

```lua
nil Sim.writeDebriefing(string text)
```

Writes a custom string to the debriefing file.

**Parameters:**
- `text` (string): The text to write.

#### Sim.makeScreenShot

```lua
nil Sim.makeScreenShot(string name)
```

Takes a screenshot with the given name.

**Parameters:**
- `name` (string): The screenshot filename.

#### Sim.getLogHistory

```lua
table, number Sim.getLogHistory(number fromIndex)
```

Returns recent log messages starting from a given index.

**Parameters:**
- `fromIndex` (number): The starting index.

**Returns:** An array of log entries and the last index. Each entry is a table with:
- `abstime`: Absolute time
- `level`: Log level
- `subsystem`: Subsystem name
- `message`: Log message

```lua
local logIndex = 0
local logHistory = {}
logHistory, logIndex = Sim.getLogHistory(logIndex)
```

#### Sim.getConfigValue

```lua
any Sim.getConfigValue(string configPath)
```

Reads a value from the configuration state.

**Parameters:**
- `configPath` (string): The configuration path.

**Returns:** The configuration value.

### Logging API (log.*)

The logging API provides structured logging with subsystems and levels.

#### Log Levels

Messages are tagged with a level indicating severity:

| Constant | Description |
|----------|-------------|
| `log.ALERT` | Critical alerts |
| `log.ERROR` | Error conditions |
| `log.WARNING` | Warning conditions |
| `log.INFO` | Informational messages |
| `log.DEBUG` | Debug messages |
| `log.ALL` | All of the above levels |
| `log.TRACE` | Trace messages (excluded from main log) |

#### Output Flags

Output formatting is controlled by flags:

| Constant | Description |
|----------|-------------|
| `log.MESSAGE` | Include the message |
| `log.TIME_UTC` | Include UTC timestamp |
| `log.TIME_LOCAL` | Include local timestamp |
| `log.TIME_RELATIVE` | Include relative timestamp |
| `log.MODULE` | Include subsystem name |
| `log.LEVEL` | Include log level |
| `log.FULL` | `MESSAGE + TIME_UTC + MODULE + LEVEL` |

#### log.write

```lua
nil log.write(string subsystem, number level, string message, ...)
```

Writes a message to the logger.

**Parameters:**
- `subsystem` (string): The subsystem name.
- `level` (number): One of the log level constants.
- `message` (string): The message format string.
- `...`: Optional format arguments (uses `string.format`).

```lua
log.write("MyHooks", log.INFO, "Player %s connected from %s", playerName, ipAddr)
```

#### log.set_output

```lua
nil log.set_output(string logName, string subsystem, number levelMask, number outputMode)
```

Configures a log output file.

**Parameters:**
- `logName` (string): Log filename without extension. Creates `$WRITE_DIR/Logs/<logName>.log`.
- `subsystem` (string): Subsystem name to match, or empty string for all subsystems.
- `levelMask` (number): Sum of log level flags to include.
- `outputMode` (number): Sum of output flags.

```lua
-- Log all LuaNET trace messages
log.set_output('lua-net', 'LuaNET', log.TRACE, log.MESSAGE + log.TIME_UTC)

-- Log everything from LuaNET
log.set_output('lua-net', 'LuaNET', log.TRACE + log.ALL, log.MESSAGE + log.TIME_UTC + log.LEVEL)
```

To close a log file:

```lua
log.set_output('lua-net', '', 0, 0)
```

> **Note:** The `log.*` API is also available from `$WRITE_DIR/Config/autoexec.cfg` for controlling log output on your local machine.

### Network API (net.*)

The `net` singleton provides network and player management functions.

#### Logging Shortcuts

##### net.log

```lua
nil net.log(string message)
```

Equivalent to `log.write('LuaNET', log.INFO, message)`. Always writes to the main log but may lose messages at high output rates.

##### net.trace

```lua
nil net.trace(string message)
```

Equivalent to `log.write('LuaNET', log.TRACE, message)`. Never appears in the main log file; must be explicitly directed to a log file. Never loses messages when an output is active, but may block if output rate exceeds write speed.

#### Chat Functions

##### net.send_chat

```lua
nil net.send_chat(string message, boolean all)
```

Sends a chat message.

**Parameters:**
- `message` (string): The message to send.
- `all` (boolean): `true` to send to all players, `false` for coalition only.

```lua
net.send_chat("Server will restart in 5 minutes", true)
```

##### net.send_chat_to

```lua
nil net.send_chat_to(string message, number playerID)
```

Sends a private chat message to a specific player.

**Parameters:**
- `message` (string): The message to send.
- `playerID` (number): The target player ID, or a special constant.

**Special Player IDs:**
- `net.CHAT_ALL` - Send to all players
- `net.CHAT_TEAM` - Send to your team

##### net.recv_chat

```lua
nil net.recv_chat(string message, number from)
```

Displays a chat message locally, optionally appearing as if sent by another player.

**Parameters:**
- `message` (string): The message to display.
- `from` (number): Optional player ID. 0 or omitted means system message.

##### net.get_chat_history

```lua
table, number net.get_chat_history(number fromIndex)
```

Returns recent chat messages starting from a given index.

**Parameters:**
- `fromIndex` (number): The starting index.

**Returns:** An array of chat entries and the last index. Each entry contains:
- `abstime`: Absolute time
- `side`: Coalition
- `playerName`: Sender name
- `message`: Message content

```lua
local chatIndex = 0
local chatHistory = {}
chatHistory, chatIndex = net.get_chat_history(chatIndex)
```

#### Player Information

##### net.get_player_list

```lua
table net.get_player_list()
```

Returns an array of currently connected player IDs.

**Returns:** Array of player ID numbers.

```lua
local players = net.get_player_list()
for _, id in ipairs(players) do
    print(net.get_name(id))
end
```

##### net.get_player_info

```lua
any net.get_player_info(number playerID, string attribute)
```

Returns player information.

**Parameters:**
- `playerID` (number): The player's ID.
- `attribute` (string): Optional. If provided, returns only that attribute.

**Attributes:**
- `'id'` - Player ID
- `'name'` - Player name
- `'side'` - Coalition (0=spectators, 1=red, 2=blue)
- `'slot'` - Current slot ID, or empty string
- `'ping'` - Ping in milliseconds
- `'ipaddr'` - IP address (server only)
- `'ucid'` - Unique Client Identifier (server only)

**Returns:** A table of all attributes, or a single attribute value.

```lua
local name = net.get_player_info(playerID, 'name')
local info = net.get_player_info(playerID)
print(string.format("%s has %dms ping", info.name, info.ping))
```

##### net.get_my_player_id

```lua
number net.get_my_player_id()
```

Returns the local player's ID. On a server, this is always 1.

**Returns:** Player ID number.

##### net.get_server_id

```lua
number net.get_server_id()
```

Returns the server's player ID. Currently always 1.

**Returns:** Server player ID number.

##### net.get_name

```lua
string net.get_name(number playerID)
```

Shortcut for `net.get_player_info(playerID, 'name')`.

**Parameters:**
- `playerID` (number): The player's ID.

**Returns:** Player name string.

##### net.get_slot

```lua
number, string net.get_slot(number playerID)
```

Returns a player's current slot.

**Parameters:**
- `playerID` (number): The player's ID.

**Returns:** Side ID and slot ID.

```lua
local side, slot = net.get_slot(playerID)
if side == 0 then
    print("Player is spectating")
end
```

##### net.get_stat

```lua
number net.get_stat(number playerID, number statID)
```

Returns a player statistic.

**Parameters:**
- `playerID` (number): The player's ID.
- `statID` (number): The statistic type.

**Statistic IDs:**
- `net.PS_PING` (0) - Ping in ms
- `net.PS_CRASH` (1) - Number of crashes
- `net.PS_CAR` (2) - Destroyed vehicles
- `net.PS_PLANE` (3) - Destroyed planes/helicopters
- `net.PS_SHIP` (4) - Destroyed ships
- `net.PS_SCORE` (5) - Total score
- `net.PS_LAND` (6) - Number of landings
- `net.PS_EJECT` (7) - Number of ejects

**Returns:** The statistic value.

#### Player Management

##### net.kick

```lua
nil net.kick(number playerID, string message)
```

Kicks a player from the server.

**Parameters:**
- `playerID` (number): The player to kick.
- `message` (string): Reason shown to the player.

```lua
net.kick(playerID, "AFK for too long")
```

##### net.set_slot

```lua
nil net.set_slot(number sideID, string slotID)
```

Attempts to change the local player's slot.

**Parameters:**
- `sideID` (number): Target coalition (0=spectators, 1=red, 2=blue).
- `slotID` (string): Target slot ID, or empty string for spectators.

##### net.force_player_slot

```lua
boolean net.force_player_slot(number playerID, number sideID, string slotID)
```

Forces a player into a specific slot. Server only.

**Parameters:**
- `playerID` (number): The player to move.
- `sideID` (number): Target coalition (0=spectators, 1=red, 2=blue).
- `slotID` (string): Target slot ID, or empty string for spectators.

**Returns:** `true` if successful.

```lua
-- Move player to spectators
net.force_player_slot(playerID, 0, '')
```

#### Ban List Management (Server Only)

##### net.banlist_get

```lua
table net.banlist_get()
```

Returns an array of active ban records.

**Returns:** Array of ban records, each containing:
- `ucid` - Unique Client Identifier
- `ipaddr` - IP address string
- `name` - Player name at time of ban
- `reason` - Ban reason
- `banned_from` - Unix timestamp of ban start
- `banned_until` - Unix timestamp of ban end

##### net.banlist_add

```lua
boolean net.banlist_add(number playerID, number period, string reason)
```

Bans and kicks a player.

**Parameters:**
- `playerID` (number): The player to ban.
- `period` (number): Ban duration in seconds.
- `reason` (string): Ban reason.

**Returns:** `true` if successful.

```lua
-- Ban for 24 hours
net.banlist_add(playerID, 86400, "Teamkilling")
```

##### net.banlist_remove

```lua
boolean net.banlist_remove(string ucid)
```

Removes a ban.

**Parameters:**
- `ucid` (string): The banned player's UCID.

**Returns:** `true` if successful.

#### Mission List Management (Server Only)

##### net.missionlist_get

```lua
table net.missionlist_get()
```

Returns the current mission list configuration.

**Returns:** A table with:
- `listLoop` - Whether list loops
- `listShuffle` - Whether list is shuffled
- `missionList` - Array of mission filenames
- `current` - Index of current mission

##### net.missionlist_append

```lua
boolean net.missionlist_append(string mizFilename)
```

Adds a mission to the end of the list.

**Parameters:**
- `mizFilename` (string): Path to the mission file.

**Returns:** `true` if successful.

##### net.missionlist_delete

```lua
boolean net.missionlist_delete(number index)
```

Removes a mission from the list.

**Parameters:**
- `index` (number): The mission index to remove.

**Returns:** `true` if successful.

##### net.missionlist_move

```lua
boolean net.missionlist_move(number oldIndex, number newIndex)
```

Moves a mission within the list.

**Parameters:**
- `oldIndex` (number): Current position.
- `newIndex` (number): New position.

**Returns:** `true` if successful.

##### net.missionlist_set_shuffle

```lua
nil net.missionlist_set_shuffle(boolean shuffle)
```

Sets whether the mission list is shuffled.

**Parameters:**
- `shuffle` (boolean): Enable or disable shuffle.

##### net.missionlist_set_loop

```lua
nil net.missionlist_set_loop(boolean loop)
```

Sets whether the mission list loops.

**Parameters:**
- `loop` (boolean): Enable or disable looping.

##### net.missionlist_run

```lua
boolean net.missionlist_run(number index)
```

Loads a mission from the list by index.

**Parameters:**
- `index` (number): The mission index to load.

**Returns:** `true` if successful.

##### net.missionlist_clear

```lua
boolean net.missionlist_clear()
```

Clears the entire mission list.

**Returns:** `true` if successful.

#### Mission Control

##### net.load_mission

```lua
nil net.load_mission(string mizFilename)
```

Loads a specific mission, temporarily overriding the server mission list. Server only.

**Parameters:**
- `mizFilename` (string): Path to the mission file.

##### net.load_next_mission

```lua
boolean net.load_next_mission()
```

Loads the next mission from the server mission list. Server only.

**Returns:** `false` if the end of the list is reached.

#### Data Conversion

##### net.lua2json

```lua
string net.lua2json(any value)
```

Converts a Lua value to a JSON string.

**Parameters:**
- `value` (any): The Lua value to convert.

**Returns:** JSON string.

```lua
local data = { name = "Test", value = 42 }
local json = net.lua2json(data)
-- '{"name":"Test","value":42}'
```

##### net.json2lua

```lua
any net.json2lua(string json)
```

Converts a JSON string to a Lua value.

**Parameters:**
- `json` (string): The JSON string to parse.

**Returns:** The parsed Lua value.

```lua
local json = '{"name":"Test","value":42}'
local data = net.json2lua(json)
-- data.name == "Test", data.value == 42
```

#### Cross-Environment Execution

##### net.dostring_in

```lua
string net.dostring_in(string state, string luaCode)
```

> **Warning:** This function is obsolete and unsafe. You can return values from `a_do_script()` in mission scripting directly instead.

Executes Lua code in a specified internal Lua state.

**Parameters:**
- `state` (string): Target state name.
- `luaCode` (string): Lua code to execute.

**Returns:** String result from the executed code.

This API must be explicitly enabled in `$WRITE_DIR/Config/autoexec.cfg`:

```lua
net.allow_unsafe_api = {
    "userhooks",  -- Enable in $WRITE_DIR/Scripts/Hooks/*.lua
    "scripting",  -- Enable in mission scripting (DANGEROUS!)
    "gui",        -- Enable in system hooks and GUI
}

net.allow_dostring_in = {
    "mission",    -- Allow net.dostring_in("scripting", "code")
}
```

### Export API (Export.*)

The Export API provides access to simulation data for external applications. In hooks, these functions are in the `Export` namespace rather than global.

See `$DCS_INSTALL/Scripts/Export.lua` for full documentation.

#### Capability Checks

```lua
boolean Export.LoIsObjectExportAllowed()   -- server.advanced.allow_object_export
boolean Export.LoIsSensorExportAllowed()   -- server.advanced.allow_sensor_export  
boolean Export.LoIsOwnshipExportAllowed()  -- server.advanced.allow_ownship_export
```

#### Always Available Functions

These functions are always available:

- `Export.LoGetPilotName()`
- `Export.LoGetAltitude()`
- `Export.LoGetNameByType()`
- `Export.LoGeoCoordinatesToLoCoordinates()`
- `Export.LoCoordinatesToGeoCoordinates()`
- `Export.LoGetVersionInfo()`
- `Export.LoGetWindAtPoint()`
- `Export.LoGetModelTime()`
- `Export.LoGetMissionStartTime()`

#### Conditionally Available Functions

**When `LoIsObjectExportAllowed()` is true:**
- `Export.LoGetObjectById()`
- `Export.LoGetWorldObjects()`

**When `LoIsSensorExportAllowed()` is true:**
- `Export.LoGetTWSInfo()`
- `Export.LoGetTargetInformation()`
- `Export.LoGetLockedTargetInformation()`
- `Export.LoGetF15_TWS_Contacts()`
- `Export.LoGetSightingSystemInfo()`
- `Export.LoGetWingTargets()`

**When `LoIsOwnshipExportAllowed()` is true:**
- `Export.LoGetPlayerPlaneId()`
- `Export.LoGetIndicatedAirSpeed()`
- `Export.LoGetAngleOfAttack()`
- `Export.LoGetAngleOfSideSlip()`
- `Export.LoGetAccelerationUnits()`
- `Export.LoGetVerticalVelocity()`
- `Export.LoGetADIPitchBankYaw()`
- `Export.LoGetTrueAirSpeed()`
- `Export.LoGetAltitudeAboveSeaLevel()`
- `Export.LoGetAltitudeAboveGroundLevel()`
- `Export.LoGetMachNumber()`
- `Export.LoGetRadarAltimeter()`
- `Export.LoGetMagneticYaw()`
- `Export.LoGetGlideDeviation()`
- `Export.LoGetSideDeviation()`
- `Export.LoGetSlipBallPosition()`
- `Export.LoGetBasicAtmospherePressure()`
- `Export.LoGetControlPanel_HSI()`
- `Export.LoGetEngineInfo()`
- `Export.LoGetSelfData()`
- `Export.LoGetCameraPosition()`
- `Export.LoSetCameraPosition()`
- `Export.LoSetCommand()`
- `Export.LoGetMCPState()`
- `Export.LoGetRoute()`
- `Export.LoGetNavigationInfo()`
- `Export.LoGetPayloadInfo()`
- `Export.LoGetWingInfo()`
- `Export.LoGetMechInfo()`
- `Export.LoGetRadioBeaconsStatus()`
- `Export.LoGetVectorVelocity()`
- `Export.LoGetVectorWindVelocity()`
- `Export.LoGetSnares()`
- `Export.LoGetAngularVelocity()`
- `Export.LoGetHeightWithObjects()`
- `Export.LoGetFMData()`

#### Unavailable in Hooks

The following Export functions are not available in hooks:
- `Export.LoSetSharedTexture()`
- `Export.LoRemoveSharedTexture()`
- `Export.LoUpdateSharedTexture()`

## Callbacks Reference

### Simulation Callbacks

#### onMissionLoadBegin

```lua
nil onMissionLoadBegin()
```

Called when the server begins loading a mission.

```lua
function myHooks.onMissionLoadBegin()
    net.log("Mission loading: " .. Sim.getMissionName())
end
```

#### onMissionLoadProgress

```lua
nil onMissionLoadProgress(number progress, string message)
```

Called periodically during mission loading.

**Parameters:**
- `progress` (number): Loading progress from 0.0 to 1.0.
- `message` (string): Description of current loading stage.

#### onMissionLoadEnd

```lua
nil onMissionLoadEnd()
```

Called when mission loading completes.

#### onSimulationStart

```lua
nil onSimulationStart()
```

Called when the simulation begins running.

#### onSimulationStop

```lua
nil onSimulationStop()
```

Called when the simulation stops.

#### onSimulationFrame

```lua
nil onSimulationFrame()
```

Called every simulation frame. Use sparingly as this impacts performance.

#### onSimulationPause

```lua
nil onSimulationPause()
```

Called when the simulation is paused.

#### onSimulationResume

```lua
nil onSimulationResume()
```

Called when the simulation resumes.

#### onGameEvent

```lua
nil onGameEvent(string eventName, ...)
```

Called for various game events. Arguments vary by event type.

**Event Types and Arguments:**
- `"friendly_fire"` - playerID, weaponName, victimPlayerID
- `"mission_end"` - winner, message
- `"kill"` - killerPlayerID, killerUnitType, killerSide, victimPlayerID, victimUnitType, victimSide, weaponName
- `"self_kill"` - playerID
- `"change_slot"` - playerID, slotID, prevSide
- `"connect"` - playerID, name
- `"disconnect"` - playerID, name, playerSide, reasonCode
- `"crash"` - playerID, unitMissionID
- `"eject"` - playerID, unitMissionID
- `"takeoff"` - playerID, unitMissionID, airdromeName
- `"landing"` - playerID, unitMissionID, airdromeName
- `"pilot_death"` - playerID, unitMissionID

```lua
function myHooks.onGameEvent(eventName, arg1, arg2, arg3, arg4, arg5, arg6, arg7)
    if eventName == "kill" then
        local killerID, killerType, killerSide = arg1, arg2, arg3
        local victimID, victimType, victimSide, weapon = arg4, arg5, arg6, arg7
        net.log(string.format("Kill: %s killed %s with %s", 
            killerType, victimType, weapon))
    end
end
```

### Network Callbacks

#### onNetConnect

```lua
nil onNetConnect(number localPlayerID)
```

Called when the local player connects to a server.

#### onNetMissionChanged

```lua
nil onNetMissionChanged(string newMissionName)
```

Called when the mission changes on the server.

#### onNetMissionEnd

```lua
nil onNetMissionEnd()
```

Called when the current mission ends.

#### onNetDisconnect

```lua
nil onNetDisconnect(string reasonMessage, number errorCode)
```

Called when disconnected from a server.

**Disconnect Error Codes:**
- `net.ERR_INVALID_ADDRESS`
- `net.ERR_CONNECT_FAILED`
- `net.ERR_WRONG_VERSION`
- `net.ERR_PROTOCOL_ERROR`
- `net.ERR_TAINTED_CLIENT`
- `net.ERR_INVALID_PASSWORD`
- `net.ERR_BANNED`
- `net.ERR_BAD_CALLSIGN`
- `net.ERR_TIMEOUT`
- `net.ERR_KICKED`

### Player Callbacks

#### onPlayerTryConnect

```lua
boolean, string onPlayerTryConnect(string addr, string name, string ucid, number playerID)
```

Called when a player attempts to connect. Can allow or deny connection.

**Parameters:**
- `addr` (string): Player's IP address.
- `name` (string): Player's display name.
- `ucid` (string): Unique Client Identifier.
- `playerID` (number): The ID the player will have if allowed.

**Returns:**
- Return `true` to allow connection
- Return `false, "reason"` to deny with a message
- Return nothing to continue the callback chain

```lua
local banned = { ["abc123ucid"] = "Cheating" }

function myHooks.onPlayerTryConnect(addr, name, ucid, playerID)
    if banned[ucid] then
        return false, "You are banned: " .. banned[ucid]
    end
    -- Return nothing to allow
end
```

#### onPlayerConnect

```lua
nil onPlayerConnect(number playerID)
```

Called when a player successfully connects.

#### onPlayerDisconnect

```lua
nil onPlayerDisconnect(number playerID, number errorCode)
```

Called when a player disconnects. Not called for the local player.

#### onPlayerStart

```lua
nil onPlayerStart(number playerID)
```

Called when a player enters the simulation. Not called for the local player.

#### onPlayerStop

```lua
nil onPlayerStop(number playerID)
```

Called when a player leaves the simulation. Not called for the local player.

#### onPlayerChangeSlot

```lua
nil onPlayerChangeSlot(number playerID)
```

Called when a player successfully changes slots.

#### onPlayerTryChangeSlot

```lua
boolean onPlayerTryChangeSlot(number playerID, number side, string slotID)
```

Called when a player attempts to change slots. Can allow or deny.

**Parameters:**
- `playerID` (number): The player's ID.
- `side` (number): Target coalition (0=spectators, 1=red, 2=blue).
- `slotID` (string): Target slot ID.

**Returns:**
- Return `true` to allow
- Return `false` to deny
- Return nothing to continue the callback chain

#### onPlayerTrySendChat

```lua
string onPlayerTrySendChat(number playerID, string message, number to)
```

Called when a player attempts to send a chat message. Can filter or block.

**Parameters:**
- `playerID` (number): The sending player's ID.
- `message` (string): The message content.
- `to` (number): Target (all or team).

**Returns:**
- Return a modified string to change the message
- Return empty string `""` to block the message
- Return nothing to allow the original message

```lua
function myHooks.onPlayerTrySendChat(playerID, message, to)
    -- Simple word filter
    if string.find(string.lower(message), "badword") then
        return ""  -- Block
    end
    -- Allow original message
end
```

### GUI Callbacks

#### onChatMessage

```lua
nil onChatMessage(string message, number from)
```

Called when a chat message is received. Useful for chat archiving.

#### onShowRadioMenu

```lua
nil onShowRadioMenu(userdata handle)
```

Called when the radio menu is shown.

#### onShowPool

```lua
nil onShowPool()
```

Called when the slot selection pool is shown.

#### onShowGameMenu

```lua
nil onShowGameMenu()
```

Called when the game menu is shown.

#### onShowBriefing

```lua
nil onShowBriefing()
```

Called when the briefing screen is shown.

#### onShowChatAll

```lua
nil onShowChatAll()
```

Called when the "all" chat input is opened.

#### onShowChatTeam

```lua
nil onShowChatTeam()
```

Called when the "team" chat input is opened.

#### onShowChatRead

```lua
nil onShowChatRead()
```

Called when the chat log is opened for reading.

#### onShowMessage

```lua
nil onShowMessage(string text, number duration)
```

Called when a message is displayed.

#### onTriggerMessage

```lua
nil onTriggerMessage(string message, number duration, boolean clearView)
```

Called when a trigger message is displayed.

#### onRadioMessage

```lua
nil onRadioMessage(string message, number duration)
```

Called when a radio message is played.

#### onRadioCommand

```lua
nil onRadioCommand(string commandMessage)
```

Called when a radio command is issued.

## Complete Example

Here is a complete server hook script demonstrating common patterns:

```lua
-- ServerAdmin.lua - Place in $WRITE_DIR/Scripts/Hooks/

local serverAdmin = {}

-- State tracking
local connectedPlayers = {}
local missionStartTime = 0

-- Logging setup
log.set_output('server-admin', 'ServerAdmin', log.ALL, log.FULL)

local function logInfo(msg)
    log.write('ServerAdmin', log.INFO, msg)
end

-- Mission lifecycle
function serverAdmin.onMissionLoadBegin()
    logInfo("Mission loading: " .. Sim.getMissionName())
end

function serverAdmin.onMissionLoadEnd()
    logInfo("Mission loaded: " .. Sim.getMissionName())
    missionStartTime = Sim.getRealTime()
end

function serverAdmin.onSimulationStart()
    logInfo("Simulation started")
    net.send_chat("Welcome to the server! Mission: " .. Sim.getMissionName(), true)
end

-- Player connection management
function serverAdmin.onPlayerTryConnect(addr, name, ucid, playerID)
    logInfo(string.format("Connection attempt: %s (UCID: %s) from %s", name, ucid, addr))
    -- Allow all connections
    return true
end

function serverAdmin.onPlayerConnect(playerID)
    local info = net.get_player_info(playerID)
    connectedPlayers[playerID] = {
        name = info.name,
        ucid = info.ucid,
        ip = info.ipaddr,
        connectTime = os.time(),
    }
    logInfo("Player connected: " .. info.name)
end

function serverAdmin.onPlayerDisconnect(playerID, errorCode)
    local player = connectedPlayers[playerID]
    if player then
        local sessionTime = os.time() - player.connectTime
        logInfo(string.format("Player disconnected: %s (session: %ds)", 
            player.name, sessionTime))
        connectedPlayers[playerID] = nil
    end
end

function serverAdmin.onPlayerStart(playerID)
    local player = connectedPlayers[playerID]
    if player then
        net.send_chat("Welcome, " .. player.name .. "!", true)
    end
end

function serverAdmin.onPlayerChangeSlot(playerID)
    local name = net.get_name(playerID)
    local side, slot = net.get_slot(playerID)
    local sideName = ({"Spectators", "Red", "Blue"})[side + 1] or "Unknown"
    logInfo(string.format("%s joined %s (slot: %s)", name, sideName, slot))
end

-- Chat moderation
function serverAdmin.onPlayerTrySendChat(playerID, message, to)
    local name = net.get_name(playerID)
    logInfo(string.format("[Chat] %s: %s", name, message))
    
    -- Command handling
    if message:sub(1, 1) == "!" then
        local cmd = message:sub(2):lower()
        if cmd == "players" then
            local count = #net.get_player_list()
            net.send_chat_to(string.format("Players online: %d", count), playerID)
            return ""  -- Don't broadcast the command
        elseif cmd == "mission" then
            net.send_chat_to("Current mission: " .. Sim.getMissionName(), playerID)
            return ""
        end
    end
    
    -- Allow the message
end

-- Game events
function serverAdmin.onGameEvent(eventName, arg1, arg2, arg3, arg4, arg5, arg6, arg7)
    if eventName == "kill" then
        logInfo(string.format("Kill: Player %s (%s) killed Player %s (%s) with %s",
            tostring(arg1), arg2, tostring(arg4), arg5, arg7))
    elseif eventName == "crash" then
        logInfo(string.format("Crash: Player %s", tostring(arg1)))
    elseif eventName == "takeoff" then
        logInfo(string.format("Takeoff: Player %s from %s", tostring(arg1), arg3))
    elseif eventName == "landing" then
        logInfo(string.format("Landing: Player %s at %s", tostring(arg1), arg3))
    end
end

-- Register hooks
Sim.setUserCallbacks(serverAdmin)
logInfo("Server admin hooks registered")
```

## Troubleshooting

### Scripts Not Loading

1. Verify the script is in `$WRITE_DIR/Scripts/Hooks/`
2. Check the filename ends with `.lua`
3. Look for Lua syntax errors in `$WRITE_DIR/Logs/dcs.log`

### Callbacks Not Firing

1. Ensure `Sim.setUserCallbacks(table)` is called
2. Verify function names match exactly (case-sensitive)
3. Check that the callback table is passed correctly

### Performance Issues

- Avoid heavy operations in `onSimulationFrame`
- Use `net.trace()` instead of `net.log()` for high-frequency logging
- Direct trace output to a separate log file

### Debugging

Enable verbose logging in `$WRITE_DIR/Config/autoexec.cfg`:

```lua
log.set_output('hooks-debug', '', log.ALL, log.FULL)
```

Use `print()` for quick debugging; output appears in `dcs.log`.

## See Also

- [Simulator Scripting Engine](../../simulator-scripting-engine.md) - Mission scripting (different API from server hooks)
- [Events](../events/events.md) - Mission scripting events (not available in hooks)
- [Coalition](../enums/coalition.md) - Coalition enumeration values