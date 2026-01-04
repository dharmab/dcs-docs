# AI Control

The AI control system allows scripts to direct AI behavior through tasks, commands, and options. These are issued through the Controller object obtained from groups or units.

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

### EWR

The `EWR` en-route task designates a unit as an Early Warning Radar. This task takes no parameters.

**For:** Ground Vehicles (radar-equipped)

```lua
local ewr = {
    id = 'EWR',
    params = {}
}
```

## Commands

Commands are instant actions that execute immediately. They do not enter the task queue.

### SetFrequency

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

### SetInvisible

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

### SetImmortal

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

### SetUnlimitedFuel

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

### Start

The `Start` command starts the engines of an aircraft. This command takes no parameters.

**For:** Airplanes, Helicopters

```lua
local cmd = {
    id = 'Start',
    params = {}
}
```

### SwitchWaypoint

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

### StopRoute

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

### SwitchAction

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

### ActivateBeacon

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

### DeactivateBeacon

The `DeactivateBeacon` command deactivates any active beacon on the unit. This command takes no parameters.

**For:** All unit types

```lua
local cmd = {
    id = 'DeactivateBeacon',
    params = {}
}
```

### ActivateACLS

The `ActivateACLS` command activates the Automatic Carrier Landing System on a carrier. This command takes no parameters.

**For:** Ships (carriers)

```lua
local cmd = {
    id = 'ActivateACLS',
    params = {}
}
```

### DeactivateACLS

The `DeactivateACLS` command deactivates the Automatic Carrier Landing System. This command takes no parameters.

**For:** Ships (carriers)

```lua
local cmd = {
    id = 'DeactivateACLS',
    params = {}
}
```

### ActivateLink4

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

### DeactivateLink4

The `DeactivateLink4` command deactivates Link 4 datalink. This command takes no parameters.

**For:** Ships (carriers)

```lua
local cmd = {
    id = 'DeactivateLink4',
    params = {}
}
```

### ActivateICLS

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

### DeactivateICLS

The `DeactivateICLS` command deactivates the Instrument Carrier Landing System. This command takes no parameters.

**For:** Ships (carriers)

```lua
local cmd = {
    id = 'DeactivateICLS',
    params = {}
}
```

### EPLRS

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

### TransmitMessage

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

### StopTransmission

The `StopTransmission` command stops any active transmission. This command takes no parameters.

**For:** All unit types

```lua
local cmd = {
    id = 'StopTransmission',
    params = {}
}
```

### Smoke_On_Off

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

## Options

Options configure AI behavior settings. They are set using `controller:setOption(optionId, value)`.

```lua
controller:setOption(AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.WEAPON_FREE)
```

Options are separated by unit domain: Air, Ground, and Naval.

## Air Options

### ROE (Rules of Engagement)

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

### REACTION_ON_THREAT

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

### RADAR_USING

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

### FLARE_USING

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

### Formation

The `Formation` option sets the flight formation. The value is a formation index number.

```lua
AI.Option.Air.id.Formation = 5
```

### RTB_ON_BINGO

The `RTB_ON_BINGO` option controls whether aircraft return to base when fuel is low. The value is a boolean.

```lua
AI.Option.Air.id.RTB_ON_BINGO = 6
```

### SILENCE

The `SILENCE` option disables radio communications. The value is a boolean.

```lua
AI.Option.Air.id.SILENCE = 7
```

### RTB_ON_OUT_OF_AMMO

The `RTB_ON_OUT_OF_AMMO` option controls whether aircraft return to base when out of ammunition. The value is a boolean.

```lua
AI.Option.Air.id.RTB_ON_OUT_OF_AMMO = 10
```

### ECM_USING

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

### PROHIBIT_AA

The `PROHIBIT_AA` option prohibits air-to-air attacks. The value is a boolean.

```lua
AI.Option.Air.id.PROHIBIT_AA = 14
```

### PROHIBIT_JETT

The `PROHIBIT_JETT` option prohibits jettisoning stores. The value is a boolean.

```lua
AI.Option.Air.id.PROHIBIT_JETT = 15
```

### PROHIBIT_AB

The `PROHIBIT_AB` option prohibits afterburner use. The value is a boolean.

```lua
AI.Option.Air.id.PROHIBIT_AB = 16
```

### PROHIBIT_AG

The `PROHIBIT_AG` option prohibits air-to-ground attacks. The value is a boolean.

```lua
AI.Option.Air.id.PROHIBIT_AG = 17
```

### MISSILE_ATTACK

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

### PROHIBIT_WP_PASS_REPORT

The `PROHIBIT_WP_PASS_REPORT` option disables waypoint passage radio calls. The value is a boolean.

```lua
AI.Option.Air.id.PROHIBIT_WP_PASS_REPORT = 19
```

### JETT_TANKS_IF_EMPTY

The `JETT_TANKS_IF_EMPTY` option causes the aircraft to jettison external fuel tanks when empty. The value is a boolean.

```lua
AI.Option.Air.id.JETT_TANKS_IF_EMPTY = 25
```

### FORCED_ATTACK

The `FORCED_ATTACK` option forces the AI to continue attacking regardless of threats. The value is a boolean.

```lua
AI.Option.Air.id.FORCED_ATTACK = 26
```

### PREFER_VERTICAL

The `PREFER_VERTICAL` option causes the AI to prefer vertical maneuvering in combat. The value is a boolean.

```lua
AI.Option.Air.id.PREFER_VERTICAL = 32
```

### ALLOW_FORMATION_SIDE_SWAP

The `ALLOW_FORMATION_SIDE_SWAP` option allows wingmen to switch formation sides. The value is a boolean.

```lua
AI.Option.Air.id.ALLOW_FORMATION_SIDE_SWAP = 35
```

## Ground Options

### ROE

The `ROE` option for ground units controls when they will engage targets.

```lua
AI.Option.Ground.id.ROE = 0

AI.Option.Ground.val.ROE = {
    OPEN_FIRE = 2,
    RETURN_FIRE = 3,
    WEAPON_HOLD = 4
}
```

### ALARM_STATE

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

### DISPERSE_ON_ATTACK

The `DISPERSE_ON_ATTACK` option causes ground units to disperse when attacked. The value is a boolean.

```lua
AI.Option.Ground.id.DISPERSE_ON_ATTACK = 8
```

### ENGAGE_AIR_WEAPONS

The `ENGAGE_AIR_WEAPONS` option controls what types of air targets to engage. The value is a boolean.

```lua
AI.Option.Ground.id.ENGAGE_AIR_WEAPONS = 20
```

### AC_ENGAGEMENT_RANGE_RESTRICTION

The `AC_ENGAGEMENT_RANGE_RESTRICTION` option limits the engagement range for air defense units. The value is a range expressed as a percentage from 0 to 100.

```lua
AI.Option.Ground.id.AC_ENGAGEMENT_RANGE_RESTRICTION = 24
```

### EVASION_OF_ARM

The `EVASION_OF_ARM` option controls SAM behavior when targeted by anti-radiation missiles. The value is a boolean; when set to true, the unit shuts down its radar when an anti-radiation missile is detected.

```lua
AI.Option.Ground.id.EVASION_OF_ARM = 31
```

## Naval Options

### ROE

The `ROE` option for naval units controls when they will engage targets.

```lua
AI.Option.Naval.id.ROE = 0

AI.Option.Naval.val.ROE = {
    OPEN_FIRE = 2,
    RETURN_FIRE = 3,
    WEAPON_HOLD = 4
}
```

## AI Skill Levels

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

## AI Task Enums

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

## See Also

- [controller](controller.md) - Controller class for issuing tasks and commands
- [unit](unit.md) - Unit class (has getController method)
- [group](group.md) - Group class (has getController method)
- [Data Types](data-types.md) - Vec2 and Vec3 coordinate types
