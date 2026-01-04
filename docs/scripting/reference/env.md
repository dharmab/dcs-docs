# env

The env singleton provides logging, mission information, and warning systems.

## env.info

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

## env.warning

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

## env.error

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

## env.setErrorMessageBoxEnabled

```lua
nil env.setErrorMessageBoxEnabled(boolean enabled)
```

The `env.setErrorMessageBoxEnabled` function enables or disables the error message box that appears when script errors occur.

**Parameters:**
- `enabled` (boolean): Set to true to show error dialogs, or false to suppress them.

```lua
env.setErrorMessageBoxEnabled(false)
```

## env.getValueDictByKey

```lua
string env.getValueDictByKey(string key)
```

The `env.getValueDictByKey` function returns a localized string from the mission's dictionary. This function is used for internationalization.

**Parameters:**
- `key` (string): The dictionary key to look up.

**Returns:** The localized string value, or the key itself if the key is not found.

## env.mission

The `env.mission` field is a table containing the complete mission data as loaded from the MIZ file. This table includes all groups, units, triggers, and other mission elements in their raw format.

```lua
local startTime = env.mission.start_time

for coalitionName, coalitionData in pairs(env.mission.coalition) do
    env.info("Coalition: " .. coalitionName)
end
```

## See Also

- [trigger](trigger.md) - Trigger actions including message display
- [timer](timer.md) - Time-related functions for debugging
