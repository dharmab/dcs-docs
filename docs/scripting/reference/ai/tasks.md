# AI Tasks

Scripts direct AI with tasks, commands, and options, issued through a group's or unit's Controller.

Tasks that accept coordinate parameters (such as `Orbit`, `Bombing`, `CarpetBombing`, `FireAtPoint`, `Land`, and `EngageTargetsInZone`) may fail or return wrong results for coordinates outside the map. Check computed positions are in bounds before issuing the task.

## Overview

AI behavior is controlled through three mechanisms:

- **Tasks** define what the AI should do (attack, orbit, escort, etc.). Tasks take time to complete and can be queued.
- **Commands** are instant actions that execute immediately (set frequency, activate beacon, etc.). They do not enter the task queue.
- **Options** configure AI behavior settings (ROE, reaction to threat, formation, etc.).

Tasks are issued via `controller:setTask()`, `controller:pushTask()`, or `controller:popTask()`. Commands use `controller:setCommand()`. Options use `controller:setOption()`. After `coalition.addGroup()`, wait at least 1 second (with `timer.scheduleFunction()`) before issuing tasks; tasking immediately after spawning can crash the game.

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

The `ComboTask` wrapper contains tasks that run in sequence. The Mission Editor uses it for waypoints with multiple tasks.

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

The `tasks` field is an array of tasks, run in order.

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

- `task` (table): The inner task.
- `condition` (table): Start conditions, checked once when the task is reached.
  - `time` (number): Mission time in seconds.
  - `condition` (string): Lua code that returns true or false.
  - `userFlag` (string): Flag name to check.
  - `userFlagValue` (boolean): Expected flag value.
  - `probability` (number): Chance of running, 0-100.
- `stopCondition` (table): Stop conditions, checked continuously. Takes the same `time`, `condition`, `userFlag`, and `userFlagValue` fields, plus:
  - `duration` (number): Seconds to run before stopping.
  - `lastWaypoint` (number): Waypoint index at which to stop.

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

The `action` field is the command or option to be wrapped.

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

- `pattern` (string): `"Circle"`, `"Race-Track"`, or `"Anchored"`.
- `pattern` values:
  - `"Circle"` orbits around `point`.
  - `"Race-Track"` flies back and forth between `point` and `point2`, turning at each end.
  - `"Anchored"` flies a fixed oval of set length and width hung off `point`, like an air refueling anchor or holding pattern.
- `point` (Vec2): Center point for Circle, first leg endpoint for Race-Track, and the anchor point for Anchored. If omitted, the aircraft uses the current waypoint.
- `point2` (Vec2): Second point for Race-Track.
- `speed` (number): Orbit speed in m/s. If omitted, about 1.5 times stall speed.
- `altitude` (number): Orbit altitude in meters.
- Anchored only:
  - `hotLegDir` (number): Heading of the hot (inbound) leg in radians, flown toward `point`.
  - `legLength` (number): Length of each straight leg in meters, not counting the turns.
  - `width` (number): Distance in meters between the hot leg and the return leg, which is also the diameter of the end turns.
  - `clockWise` (boolean): Turn right (clockwise) instead of left. Defaults to `false`.

#### Anchored pattern geometry

An Anchored orbit is an oval with two straight legs joined by 180° turns:

- **Hot leg** - The straight leg flown on `hotLegDir`, ending at `point`. The mission editor labels its heading "Hot Leg Brg". On a tanker track this is the leg receivers plan to join on. A holding pattern calls it the inbound leg.
- **Return leg** - The parallel straight leg flown the opposite way, back to the start of the hot leg. It lies `width` meters to one side of the hot leg. A holding pattern calls it the outbound leg, and tanker crews call it the cold leg.
- **ARCP** - The anchor point, `point`, at the end of the hot leg where the aircraft turns onto the return leg.

DCS AI tankers refuel on either leg, so the hot leg only sets where the track sits and which way it faces.

`point` is the anchor point, which tankers call the ARCP (Air Refueling Control Point). It sits at the **end** of the hot leg, not the start: the aircraft flies the hot leg on `hotLegDir`, reaches `point`, then turns onto the return leg. The oval extends behind `point`, opposite `hotLegDir`. This is the same layout as a holding pattern, where the holding fix is at the end of the inbound leg.[^anchored]

With `clockWise = false` the turns are to the left, so the return leg lies `width` meters to the left of the hot leg. With `clockWise = true` it lies to the right.

```text
hotLegDir = 090° (east), clockWise = false, legLength = 50 nm, width = 20 nm

      <────────────── return leg (270°) ──────────────┐
    ╭                                                 ╮
    │                                                 │  width 20 nm
    ╰                                                 ╯
      ─────────────── hot leg (090°) ───────────> ARCP (point)
      |<──────────────── legLength 50 nm ───────────>|
```

To put a tanker's hot leg on a given segment, place `point` at the downstream end of the segment and set `hotLegDir` to the segment's heading.

```lua
local anchored = {
    id = 'Orbit',
    params = {
        pattern = 'Anchored',
        point = {x = 100000, y = 200000},   -- ARCP: end of the hot leg
        speed = 220,
        altitude = 7620,
        hotLegDir = math.rad(90),            -- hot leg flown east into the ARCP
        legLength = 50 * 1852,               -- 50 nm
        width = 20 * 1852,                   -- 20 nm
        clockWise = false                    -- left turns, return leg to the north
    }
}
```

[^anchored]: ED Forums, ["I Don't Understand the 'Anchored' Orbit"](https://forum.dcs.world/topic/372349-i-dont-understand-the-anchored-orbit/), with a mission editor screenshot of the Anchored fields (Hot Leg Brg, Leg length, Width, Clockwise) and the resulting pattern on the F10 map.

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
        directionEnabled = boolean,
        attackQtyLimit = boolean,
        attackQty = number,
        groupAttack = boolean
    }
}
```

- `unitId` (number): Required. The target unit's ID, from `unit:getID()`.
- `weaponType` (number): A [weapon flags](../enums/ai.md#weapon-flags) bitmask.
- `expend` (string): How much ordnance to use per pass.
- `direction` (number): Ingress heading in radians, the course flown toward the target on the attack run. Used only when `directionEnabled` is `true`.
- `attackQtyLimit` (boolean): Limit the number of attack passes.
- `attackQty` (number): Number of attack passes when `attackQtyLimit` is `true`.
- `groupAttack` (boolean): All aircraft in the group attack the same target at once. Use for heavily defended targets, such as ships, that need simultaneous hits.

```lua
local attack = {
    id = 'AttackUnit',
    params = {
        unitId = Unit.getByName("Target"):getID(),
        weaponType = 4161536, -- ASM
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

The required `groupId` field is the target group's ID, from `group:getID()`. The `weaponType`, `expend`, `direction`, `attackQtyLimit`, `attackQty`, and `groupAttack` fields work as in `AttackUnit`.

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

The required `point` field is the target position as a Vec2. The `altitude` field is the attack altitude in meters. The `attackType` field is the attack profile, such as "Dive" for dive bombing or horizontal for level bombing. The `weaponType`, `expend`, `direction`, `attackQtyLimit`, and `attackQty` fields work as in `AttackUnit`.

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

The `runwayId` field is the airbase ID. The `weaponType`, `expend`, and `direction` fields work as in `AttackUnit`.

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

The `point` field is the start point as a Vec2. The `carpetLength` field is the length of the carpet in meters. The `weaponType`, `expend`, `direction`, and `attackQty` fields work as in `AttackUnit`.

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

The `groupId` field is the ID of the group to escort. The `engagementDistMax` field is the maximum engagement range in meters. The `targetTypes` field is an array of attribute names specifying which target types to engage. The `pos` field is the position offset from the escorted group as a Vec3. The `lastWptIndexFlag` and `lastWptIndex` fields control when the escort task ends.

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

The `groupId` field is the ID of the group to follow. The `pos` field is the position offset from the followed group as a Vec3. The `lastWptIndexFlag` and `lastWptIndex` fields control when the follow task ends.

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

The `fromWaypointIndex` field is the starting waypoint index. The `goToWaypointIndex` field is the destination waypoint index.

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

The `point` field is the target coordinates as a Vec2. The `radius` field is the dispersion radius in meters. The `expendQty` field sets how many rounds to fire when `expendQtyEnabled` is true.

Mission files store the target as `x` and `y` params instead of `point`, and the radius as `zoneRadius`. Setting both forms is safe:

```lua
local target = trigger.misc.getZone("Arty Target")
local fire = {
    id = 'FireAtPoint',
    params = {
        point = {x = target.point.x, y = target.point.z},
        x = target.point.x,
        y = target.point.z,
        radius = 100,
        zoneRadius = 100,
        expendQtyEnabled = true,
        expendQty = 20
    }
}
```

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

The `point` field is the landing point as a Vec2. The `duration` field sets how long to stay on the ground, in seconds, when `durationFlag` is true. The default is 300.

Mission files store the landing point as `x` and `y` params instead of `point`.

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

The `groupId` field is the carrier group ID. The `speed` field is the tanker's orbit speed. The `altitude` field is the orbit altitude. The `lastWptIndexFlag` and `lastWptIndex` fields control when the task ends.

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

The `targetTypes` field is an array of attribute names specifying which target types to engage. The `priority` field is the task priority, where lower values indicate higher priority; the default is 0. The optional `maxDistEnabled` and `maxDist` (meters) fields limit how far from the route the group will go to engage.

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

The `point` field is the zone center as a Vec2. The `zoneRadius` field is the zone radius in meters. The `targetTypes` field is an array of attribute names specifying which target types to engage. The `priority` field is the task priority.

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

The `groupId` field is the target group ID. The `weaponType` and `expend` fields work as in `AttackUnit`. The `priority` field is the task priority.

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

The `unitId` field is the target unit ID. The `weaponType`, `expend`, and `groupAttack` fields work as in `AttackUnit`. The `priority` field is the task priority.

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

The `frequency` field is the radio frequency in Hz. The `modulation` field is the modulation type, where 0 is AM and 1 is FM. The `callname` field is the FAC callsign index. The `number` field is the FAC number.

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

The `groupId` field is the target group ID. The `weaponType` field is the weapon flags bitmask. The `designation` field is the designation method from the `AI.Task.Designation` enum. The `datalink` field sets whether to use datalink. The `frequency`, `modulation`, `callname`, and `number` fields work the same as in the `FAC` task.

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
