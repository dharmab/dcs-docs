# AI Tasks

The AI control system allows scripts to direct AI behavior through tasks, commands, and options. These are issued through the Controller object obtained from groups or units.

Tasks that accept coordinate parameters (such as `Orbit`, `Bombing`, `CarpetBombing`, `FireAtPoint`, `Land`, and `EngageTargetsInZone`) may fail or produce unexpected results if the coordinates fall outside the current map's boundaries. When constructing tasks with dynamically calculated positions, validate that coordinates remain within reasonable bounds before issuing the task.

Some aircraft have hardcoded role restrictions that prevent certain task assignments. The S-3B Viking, for example, is coded as an anti-ship aircraft and cannot execute OCA/Aircraft (Offensive Counter Air - Aircraft) tasks. If you need an S-3B to engage aircraft, use the AntiShipStrike task as a fallback—though this is a workaround rather than correct behavior.

## Overview

AI behavior is controlled through three mechanisms:

- **Tasks** define what the AI should do (attack, orbit, escort, etc.). Tasks take time to complete and can be queued.
- **Commands** are instant actions that execute immediately (set frequency, activate beacon, etc.). They do not enter the task queue.
- **Options** configure AI behavior settings (ROE, reaction to threat, formation, etc.).

Tasks are issued via `controller:setTask()`, `controller:pushTask()`, or `controller:popTask()`. Commands use `controller:setCommand()`. Options use `controller:setOption()`. After spawning a group with `coalition.addGroup()`, you must add a delay before issuing tasks to the controller, because issuing tasks immediately after spawning can crash the game. Use `timer.scheduleFunction()` to delay by at least 1 second.

## Task Structure

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

## Task Wrappers

### ComboTask

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

### ControlledTask

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

### WrappedAction

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

## Main Tasks

Main tasks define the primary behavior of a group.

### Orbit

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

### AttackUnit

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

### AttackGroup

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

### Bombing

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

### BombingRunway

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

### CarpetBombing

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

### Escort

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

### Follow

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

### GoToWaypoint

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

### Hold

The `Hold` task orders ground units to stop and hold position. This task takes no parameters.

**For:** Ground Vehicles

```lua
local hold = {
    id = 'Hold',
    params = {}
}
```

### FireAtPoint

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

### Land

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

### RecoveryTanker

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

## En-route Tasks

En-route tasks run alongside the main mission, defining ongoing behaviors.

### EngageTargets

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

### EngageTargetsInZone

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

### EngageGroup

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

### EngageUnit

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

### AWACS

The `AWACS` en-route task designates an aircraft as an AWACS, providing radar coverage for friendly forces. This task takes no parameters.

**For:** Airplanes (AWACS-capable)

```lua
local awacs = {
    id = 'AWACS',
    params = {}
}
```

### Tanker

The `Tanker` en-route task designates an aircraft as an aerial refueling tanker. This task takes no parameters.

**For:** Airplanes (tanker-capable)

```lua
local tanker = {
    id = 'Tanker',
    params = {}
}
```

### FAC

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

### FAC_EngageGroup

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

### EWR

The `EWR` en-route task designates a unit as an Early Warning Radar. This task takes no parameters.

**For:** Ground Vehicles (radar-equipped)

```lua
local ewr = {
    id = 'EWR',
    params = {}
}
```

## See Also

- [AI Commands](commands.md) - Instant AI commands
- [AI Options](options.md) - AI behavior options
- [AI Enums](../enums/ai.md) - AI-related enumerations
- [Controller](../classes/controller.md) - Controller class for issuing tasks
