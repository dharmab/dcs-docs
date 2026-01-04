# Controller

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

## controller:setTask

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

## controller:pushTask

```lua
nil controller:pushTask(table task)
```

The `controller:pushTask` method adds a task to the front of the task queue. The current task is suspended until the new task completes.

**Parameters:**
- `task` (table): The task definition table.

## controller:popTask

```lua
nil controller:popTask()
```

The `controller:popTask` method removes and discards the current task, resuming the previous one.

## controller:resetTask

```lua
nil controller:resetTask()
```

The `controller:resetTask` method clears all tasks from the controller.

## controller:hasTask

```lua
boolean controller:hasTask()
```

The `controller:hasTask` method returns whether the controller has any active task.

**Returns:** True if a task is active, or false otherwise.

## controller:setCommand

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

## controller:setOption

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

## controller:setOnOff

```lua
nil controller:setOnOff(boolean on)
```

The `controller:setOnOff` method enables or disables the AI controller.

**Parameters:**
- `on` (boolean): Set to true to enable the controller, or false to disable it and make the unit passive.

## controller:setAltitude

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

## controller:setSpeed

```lua
nil controller:setSpeed(number speed, boolean keep)
```

The `controller:setSpeed` method sets the desired speed for aircraft.

**Parameters:**
- `speed` (number): The speed in meters per second.
- `keep` (boolean): If true, the aircraft maintains speed even when not tasked.

## controller:getDetectedTargets

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

## controller:isTargetDetected

```lua
boolean, boolean, ... controller:isTargetDetected(Object target, number detectionTypes)
```

The `controller:isTargetDetected` method checks if a specific target is detected.

**Parameters:**
- `target` (Object): The object to check.
- `detectionTypes` (number): A bitmask of detection types.

**Returns:** Multiple values indicating detection status by each sensor type.

## controller:knowTarget

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

## See Also

- [unit](unit.md) - Unit class (has getController method)
- [group](group.md) - Group class (has getController method)
- [AI Tasks](../ai/tasks.md) - Task definitions
- [AI Commands](../ai/commands.md) - Command definitions
- [AI Options](../ai/options.md) - Option definitions
