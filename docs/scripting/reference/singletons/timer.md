# timer

The timer singleton provides mission time information and function scheduling.

## timer.getTime

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

## timer.getAbsTime

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

## timer.getTime0

```lua
number timer.getTime0()
```

The `timer.getTime0` function returns the mission's start time as seconds since midnight. This value represents the "start time" configured in the Mission Editor.

**Returns:** The mission start time as absolute time in seconds since midnight.

```lua
local currentTimeOfDay = timer.getTime0() + timer.getTime()
local hours = math.floor(currentTimeOfDay / 3600) % 24
```

## timer.scheduleFunction

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

## timer.removeFunction

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

## timer.setFunctionTime

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

## See Also

- [Scripting Concepts](../../concepts.md) - Time value conventions
- [events](../events/events.md) - Event-driven programming alternative
