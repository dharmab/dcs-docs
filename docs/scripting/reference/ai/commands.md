# AI Commands

Commands are instant actions that execute immediately. They do not enter the task queue and are issued via `controller:setCommand()`.

## SetFrequency

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
local cmd = {
    id = "SetFrequency",
    params = {
        power = 10,
        modulation = 0,
        frequency = 131000000
    }
}
Group.getByName("AWACS"):getController():setCommand(cmd)
```

## SetInvisible

The `SetInvisible` command makes the group invisible to enemy AI sensors.

**For:** All unit types

```lua
local cmd = {
    id = 'SetInvisible',
    params = {
        value = boolean
    }
}
controller:setCommand(cmd)
```

The `value` field sets the invisibility state: `true` makes the group invisible to enemy AI sensors, while `false` disables invisibility.

## SetImmortal

The `SetImmortal` command makes the group invulnerable to all damage.

**For:** All unit types

```lua
local cmd = {
    id = 'SetImmortal',
    params = {
        value = boolean
    }
}
controller:setCommand(cmd)
```

The `value` field sets the invulnerability state: `true` makes the group invulnerable to damage, while `false` disables invulnerability.

## SetUnlimitedFuel

The `SetUnlimitedFuel` command enables or disables unlimited fuel for the group.

**For:** Airplanes, Helicopters

```lua
local cmd = {
    id = 'SetUnlimitedFuel',
    params = {
        value = boolean
    }
}
controller:setCommand(cmd)
```

The `value` field sets the unlimited fuel state: `true` enables unlimited fuel, while `false` disables it if it is already enabled.

## Start

The `Start` command starts the engines of an aircraft. This command takes no parameters.

**For:** Airplanes, Helicopters

```lua
local cmd = {
    id = 'Start',
    params = {}
}
controller:setCommand(cmd)
```

## SwitchWaypoint

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
controller:setCommand(cmd)
```

The `fromWaypointIndex` field specifies the starting waypoint index. The `goToWaypointIndex` field specifies the destination waypoint index.

## StopRoute

The `StopRoute` command stops or resumes the group's route following.

**For:** All unit types

```lua
local cmd = {
    id = 'StopRoute',
    params = {
        value = boolean
    }
}
controller:setCommand(cmd)
```

The `value` field specifies whether to stop the route; set to true to stop route following.

## SwitchAction

The `SwitchAction` command switches the group's current action.

**For:** All unit types

```lua
local cmd = {
    id = 'SwitchAction',
    params = {
        actionIndex = number
    }
}
controller:setCommand(cmd)
```

The `actionIndex` field specifies the index of the action to switch to.

## ActivateBeacon

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
controller:setCommand(cmd)
```

The `type` field specifies the beacon type using one of these numeric values (see [Beacon Types](../enums/ai.md#beacon-types)):

| Constant                                | Value |
| --------------------------------------- | ----- |
| `BEACON_TYPE_NULL`                      | 0     |
| `BEACON_TYPE_VOR`                       | 1     |
| `BEACON_TYPE_DME`                       | 2     |
| `BEACON_TYPE_VOR_DME`                   | 3     |
| `BEACON_TYPE_TACAN`                     | 4     |
| `BEACON_TYPE_VORTAC`                    | 5     |
| `BEACON_TYPE_HOMER`                     | 8     |
| `BEACON_TYPE_RSBN`                      | 32    |
| `BEACON_TYPE_BROADCAST_STATION`         | 1024  |
| `BEACON_TYPE_AIRPORT_HOMER`             | 4104  |
| `BEACON_TYPE_AIRPORT_HOMER_WITH_MARKER` | 4136  |
| `BEACON_TYPE_ILS_FAR_HOMER`             | 16408 |
| `BEACON_TYPE_ILS_NEAR_HOMER`            | 16456 |
| `BEACON_TYPE_ILS_LOCALIZER`             | 16640 |
| `BEACON_TYPE_ILS_GLIDESLOPE`            | 16896 |
| `BEACON_TYPE_NAUTICAL_HOMER`            | 32776 |

For example, `type = 4` selects TACAN.

The `system` field specifies the beacon system using one of these numeric values from the `SystemName` enum (see [Beacon Systems](../enums/ai.md#beacon-systems)):

| Constant                       | Value |
| ------------------------------ | ----- |
| `SystemName.PAR_10`            | 1     |
| `SystemName.RSBN_5`            | 2     |
| `SystemName.TACAN`             | 3     |
| `SystemName.TACAN_TANKER`      | 4     |
| `SystemName.ILS_LOCALIZER`     | 5     |
| `SystemName.ILS_GLIDESLOPE`    | 6     |
| `SystemName.BROADCAST_STATION` | 7     |

For example, `system = 3` selects the TACAN system. The `type` and `system` values are separate: TACAN uses `type = 4` and `system = 3`.

The `name` field is optional and specifies a display name for the beacon. The `callsign` field specifies the Morse code callsign. The `frequency` field specifies the beacon frequency in Hz.

## DeactivateBeacon

The `DeactivateBeacon` command deactivates any active beacon on the unit. This command takes no parameters.

**For:** All unit types

```lua
local cmd = {
    id = 'DeactivateBeacon',
    params = {}
}
controller:setCommand(cmd)
```

## ActivateACLS

The `ActivateACLS` command activates the Automatic Carrier Landing System on a carrier. This command takes no parameters.

**For:** Ships (carriers)

```lua
local cmd = {
    id = 'ActivateACLS',
    params = {}
}
controller:setCommand(cmd)
```

## DeactivateACLS

The `DeactivateACLS` command deactivates the Automatic Carrier Landing System. This command takes no parameters.

**For:** Ships (carriers)

```lua
local cmd = {
    id = 'DeactivateACLS',
    params = {}
}
controller:setCommand(cmd)
```

## ActivateLink4

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
controller:setCommand(cmd)
```

The `unitId` field contains the aircraft unit ID. The `frequency` field specifies the Link 4 frequency.

## DeactivateLink4

The `DeactivateLink4` command deactivates Link 4 datalink. This command takes no parameters.

**For:** Ships (carriers)

```lua
local cmd = {
    id = 'DeactivateLink4',
    params = {}
}
controller:setCommand(cmd)
```

## ActivateICLS

The `ActivateICLS` command activates the Instrument Carrier Landing System.

**For:** Ships (carriers)

```lua
local cmd = {
    id = 'ActivateICLS',
    params = {
        channel = number
    }
}
controller:setCommand(cmd)
```

The `channel` field specifies the ICLS channel.

## DeactivateICLS

The `DeactivateICLS` command deactivates the Instrument Carrier Landing System. This command takes no parameters.

**For:** Ships (carriers)

```lua
local cmd = {
    id = 'DeactivateICLS',
    params = {}
}
controller:setCommand(cmd)
```

## EPLRS

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
controller:setCommand(cmd)
```

The `value` field specifies whether to enable EPLRS. The `groupId` field is optional and specifies the group to link with.

## TransmitMessage

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
controller:setCommand(cmd)
```

The `file` field specifies the sound file path. The `duration` field specifies the message duration. The `subtitle` field specifies the subtitle text. The `loop` field specifies whether to loop the message.

## StopTransmission

The `StopTransmission` command stops any active transmission. This command takes no parameters.

**For:** All unit types

```lua
local cmd = {
    id = 'StopTransmission',
    params = {}
}
controller:setCommand(cmd)
```

## Smoke_On_Off

The `Smoke_On_Off` command toggles a smoke trail on or off.

**For:** Airplanes (aerobatic aircraft)

```lua
local cmd = {
    id = 'Smoke_On_Off',
    params = {
        value = boolean
    }
}
controller:setCommand(cmd)
```

The `value` field sets the smoke trail state: `true` enables the smoke trail, while `false` disables it.

## See Also

- [AI Tasks](tasks.md) - AI task definitions
- [AI Options](options.md) - AI behavior options
- [AI Enums](../enums/ai.md) - Beacon types and systems
- [Controller](../classes/controller.md) - Controller class for issuing commands
