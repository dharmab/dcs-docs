# net

The net singleton provides chat, player information, slot control, and data conversion functions. It is available in both mission scripts and [server hooks](../hooks/server-hooks.md). Server hooks can also call extra functions for ban lists, mission lists, mission loading, and chat history, documented in the [server hooks reference](../hooks/server-hooks.md#network-api-net).

## Logging Shortcuts

### net.log

```lua
nil net.log(string message)
```

Equivalent to `log.write('LuaNET', log.INFO, message)`. Output goes to `dcs.log` by default, unlike `net.trace`. At high output rates, some messages may be dropped.

### net.trace

```lua
nil net.trace(string message)
```

Equivalent to `log.write('LuaNET', log.TRACE, message)`. DCS does not write trace messages to `dcs.log`, so this output is discarded unless you configure a separate log file for it with [`log.set_output`](../hooks/server-hooks.md#logset_output) in a server hook or `$WRITE_DIR/Config/autoexec.cfg`:

```lua
-- Write LuaNET trace messages to $WRITE_DIR/Logs/lua-net.log
log.set_output('lua-net', 'LuaNET', log.TRACE, log.MESSAGE + log.TIME_UTC)
```

Once that file is configured, no messages are dropped, but `net.trace` may block if you log faster than the disk can write.

## Chat Functions

### net.send_chat

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

### net.send_chat_to

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

### net.recv_chat

```lua
nil net.recv_chat(string message, number from)
```

Displays a chat message locally, optionally appearing as if sent by another player.

**Parameters:**
- `message` (string): The message to display.
- `from` (number): Optional player ID. 0 or omitted means system message.

## Player Information

### net.get_player_list

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

### net.get_player_info

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

### net.get_my_player_id

```lua
number net.get_my_player_id()
```

Returns the local player's ID. On a server, this is always 1.

**Returns:** Player ID number.

### net.get_server_id

```lua
number net.get_server_id()
```

Returns the server's player ID. Currently always 1.

**Returns:** Server player ID number.

### net.get_name

```lua
string net.get_name(number playerID)
```

Shortcut for `net.get_player_info(playerID, 'name')`.

**Parameters:**
- `playerID` (number): The player's ID.

**Returns:** Player name string.

### net.get_slot

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

### net.get_stat

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

## Player Management

### net.kick

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

### net.set_slot

```lua
nil net.set_slot(number sideID, string slotID)
```

Attempts to change the local player's slot.

**Parameters:**
- `sideID` (number): Target coalition (0=spectators, 1=red, 2=blue).
- `slotID` (string): Target slot ID, or empty string for spectators.

### net.force_player_slot

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

## Data Conversion

### net.lua2json

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

### net.json2lua

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

## Cross-Environment Execution

### net.dostring_in

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
## Example

```lua
-- Greet each player who enters a unit
local handler = {}
function handler:onEvent(event)
    if event.id == world.event.S_EVENT_PLAYER_ENTER_UNIT and event.initiator then
        local playerName = event.initiator:getPlayerName()
        for _, playerID in ipairs(net.get_player_list()) do
            if net.get_name(playerID) == playerName then
                net.send_chat_to("Welcome, " .. playerName, playerID)
            end
        end
    end
end
world.addEventHandler(handler)
```

## See Also

- [Server Hooks](../hooks/server-hooks.md#network-api-net) - Hooks-only `net` functions
- [Available APIs](../hooks/server-hooks.md#available-apis) - Mission scripting vs. server hooks comparison
- [events](../events/events.md) - Player events such as `S_EVENT_PLAYER_ENTER_UNIT`
