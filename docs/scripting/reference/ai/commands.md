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
```

The `value` field specifies whether to enable invisibility; set to true to make the group invisible.

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
```

The `value` field specifies whether to enable invulnerability; set to true to make the group immortal.

## SetUnlimitedFuel

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

## Start

The `Start` command starts the engines of an aircraft. This command takes no parameters.

**For:** Airplanes, Helicopters

```lua
local cmd = {
    id = 'Start',
    params = {}
}
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
```

The `type` field specifies the beacon type from the beacon type constants. The `system` field specifies the beacon system from the `SystemName` enum. The `name` field is optional and specifies a display name for the beacon. The `callsign` field specifies the Morse code callsign. The `frequency` field specifies the beacon frequency in Hz.

## DeactivateBeacon

The `DeactivateBeacon` command deactivates any active beacon on the unit. This command takes no parameters.

**For:** All unit types

```lua
local cmd = {
    id = 'DeactivateBeacon',
    params = {}
}
```

## ActivateACLS

The `ActivateACLS` command activates the Automatic Carrier Landing System on a carrier. This command takes no parameters.

**For:** Ships (carriers)

```lua
local cmd = {
    id = 'ActivateACLS',
    params = {}
}
```

## DeactivateACLS

The `DeactivateACLS` command deactivates the Automatic Carrier Landing System. This command takes no parameters.

**For:** Ships (carriers)

```lua
local cmd = {
    id = 'DeactivateACLS',
    params = {}
}
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
```

The `value` field specifies whether to enable the smoke trail.

## See Also

- [AI Tasks](tasks.md) - AI task definitions
- [AI Options](options.md) - AI behavior options
- [AI Enums](../enums/ai.md) - Beacon types and systems
- [Controller](../classes/controller.md) - Controller class for issuing commands
