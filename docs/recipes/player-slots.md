# Adding Player Slots at an Airfield

This recipe describes how to create player-controllable aircraft slots at an airfield by directly editing the mission Lua file. Player slots allow human players to fly aircraft in both singleplayer and multiplayer missions.

## Overview

DCS World supports three types of player slots:

| Slot Type | `skill` Value | Use Case |
|-----------|---------------|----------|
| **Singleplayer** | `"Player"` | Single slot for solo missions |
| **Traditional Multiplayer** | `"Client"` | Individual slots for each player aircraft |
| **Dynamic Spawn Template** | `"Client"` + `dynSpawnTemplate = true` | Template-based spawning from warehouse (preferred for multiplayer) |

A mission typically uses one approach:
- **Singleplayer missions**: One unit with `skill = "Player"`
- **Traditional multiplayer**: Multiple units with `skill = "Client"` for each available slot
- **Dynamic spawn (recommended for multiplayer)**: One template per aircraft type with `dynSpawnTemplate = true`, players spawn from warehouse inventory

## Dynamic Spawn System (Recommended for Multiplayer)

The dynamic spawn system, introduced in DCS 2.9, allows players to spawn any aircraft available in the airfield's warehouse without requiring pre-placed slots for every possible aircraft. This dramatically reduces mission file complexity and allows unlimited player capacity.

### How Dynamic Spawn Works

1. Enable dynamic spawn on the airfield via warehouse settings
2. Create template aircraft groups with `dynSpawnTemplate = true`
3. Players select aircraft type, loadout, and spawn location in-game
4. Aircraft spawn from warehouse inventory (can be unlimited or restricted)

### Enabling Dynamic Spawn on an Airfield

Dynamic spawn is enabled via the airfield's warehouse configuration in `warehouses` (a separate file in the .miz archive). The mission file aircraft group only needs the template flag.

### Dynamic Spawn Template Group

A template group requires `dynSpawnTemplate = true` at the group level:

```lua
[1] = {
    ["dynSpawnTemplate"] = true,  -- Marks this as a dynamic spawn template
    ["groupId"] = 1,
    ["name"] = "F-4E Template",
    ["task"] = "CAP",
    ["modulation"] = 0,
    ["communication"] = true,
    ["frequency"] = 305,
    ["start_time"] = 0,
    ["uncontrolled"] = false,
    ["uncontrollable"] = false,
    ["units"] = {
        [1] = {
            ["unitId"] = 1,
            ["name"] = "Aerial-1-1",
            ["type"] = "F-4E-45MC",
            ["skill"] = "Client",
            ["x"] = -7178.9565429688,
            ["y"] = 294729.28125,
            ["alt"] = 20,
            ["alt_type"] = "BARO",
            ["speed"] = 138.88888888889,
            ["heading"] = 0,
            ["psi"] = 0,
            ["parking"] = "55",
            ["parking_id"] = "36",
            ["onboard_num"] = "010",
            ["livery_id"] = "default",
            ["payload"] = {
                ["pylons"] = {},
                ["fuel"] = 5510.5,
                ["flare"] = 30,
                ["chaff"] = 120,
                ["gun"] = 100,
            },
            ["callsign"] = {
                [1] = 1,
                [2] = 1,
                [3] = 1,
                ["name"] = "Enfield11",
            },
        },
    },
    ["x"] = -7178.9565429688,
    ["y"] = 294729.28125,
    ["route"] = {
        ["points"] = {
            [1] = {
                ["alt"] = 20,
                ["alt_type"] = "BARO",
                ["type"] = "TakeOffParking",
                ["action"] = "From Parking Area",
                ["x"] = -7178.9565429688,
                ["y"] = 294729.28125,
                ["speed"] = 138.88888888889,
                ["speed_locked"] = true,
                ["ETA"] = 0,
                ["ETA_locked"] = true,
                ["airdromeId"] = 15,
                ["formation_template"] = "",
                ["task"] = {
                    ["id"] = "ComboTask",
                    ["params"] = {
                        ["tasks"] = {},
                    },
                },
            },
        },
    },
},
```

### Dynamic Spawn Advantages

- **Reduced mission complexity**: One template per aircraft type instead of dozens of individual slots
- **Flexible player count**: Unlimited players can spawn (within warehouse limits)
- **In-game loadout selection**: Players choose weapons, fuel, and livery when spawning
- **Hot/cold start option**: Players can choose start type (if enabled in warehouse settings)
- **Waypoint sharing**: All spawned aircraft of a type inherit the template's waypoints

### Dynamic Spawn Limitations

- Multiplayer only (not available in singleplayer)
- Does not work with Supercarrier (carrier manages spawn positions)
- Template aircraft should be hidden from traditional slot screen using password protection
- Each aircraft type needs its own template if you want custom waypoints

---

## Mission File Structure

Player aircraft are placed in `coalition.[side].country[n].plane.group`. Each group contains one or more units.

```lua
["coalition"] = {
    ["blue"] = {
        ["country"] = {
            [1] = {
                ["id"] = 2,  -- USA
                ["name"] = "USA",
                ["plane"] = {
                    ["group"] = {
                        [1] = {
                            -- Player group definition here
                        },
                    },
                },
            },
        },
    },
},
```

## Required Fields

### Group-Level Fields

| Field | Type | Description |
|-------|------|-------------|
| `groupId` | number | Unique group ID (must be unique across all groups in mission) |
| `name` | string | Group name (displayed in mission planning) |
| `task` | string | Primary task (e.g., "CAP", "CAS", "Ground Attack") |
| `units` | table | Array of unit definitions |
| `route` | table | Route with waypoints |
| `x` | number | Initial X position (meters, map coordinates) |
| `y` | number | Initial Y position (meters, map coordinates) |
| `hidden` | boolean | Hidden on planning map |
| `uncontrolled` | boolean | Starts with engines off, no AI control |
| `communication` | boolean | Radio communications enabled |
| `frequency` | number | Radio frequency (MHz) |
| `modulation` | number | Radio modulation (0=AM, 1=FM) |
| `start_time` | number | Spawn time offset from mission start (seconds) |
| `radioSet` | boolean | Use preset radio frequencies |
| `dynSpawnTemplate` | boolean | (Dynamic spawn only) Marks group as a template |

### Unit-Level Fields

| Field | Type | Description |
|-------|------|-------------|
| `unitId` | number | Unique unit ID (must be unique across all units in mission) |
| `name` | string | Unit name (displayed in slot selection) |
| `type` | string | Aircraft type string (e.g., "F-16C_50", "F/A-18C_hornet") |
| `skill` | string | `"Player"` for singleplayer, `"Client"` for multiplayer/dynamic |
| `x` | number | Position X (same as group for parking start) |
| `y` | number | Position Y (same as group for parking start) |
| `alt` | number | Altitude (meters, typically airfield elevation) |
| `alt_type` | string | Altitude reference ("BARO" or "RADIO") |
| `speed` | number | Initial speed (m/s) |
| `heading` | number | Heading (radians) |
| `psi` | number | Orientation angle (radians, typically same as heading) |
| `parking` | string | Parking spot number at the airfield |
| `parking_id` | string | Parking spot identifier |
| `onboard_num` | string | Aircraft tail number |
| `livery_id` | string | Livery/skin name |
| `payload` | table | Weapons and stores configuration |
| `callsign` | table | Callsign configuration |

## Parking Spot Assignment

When starting from an airfield parking area, you must specify both `parking` and `parking_id`:

- `parking` - The parking spot number (as a string, e.g., "23")
- `parking_id` - The parking spot identifier (as a string, e.g., "17")

These values are airfield-specific and can be found by:
1. Placing a unit in the Mission Editor and examining the generated mission file
2. Using the SSE `airbase:getParking()` method to query available spots

## Start Types

The waypoint `type` and `action` fields determine how the aircraft spawns:

| Start Type | Waypoint Type | Waypoint Action |
|------------|---------------|-----------------|
| Cold on ramp | `"TakeOffParking"` | `"From Parking Area"` |
| Hot on ramp | `"TakeOffParkingHot"` | `"From Parking Area Hot"` |
| On runway | `"TakeOff"` | `"From Runway"` |

---

## Traditional Slot Examples

### Singleplayer Slot Example

This example places an F-16C at Batumi airfield (airdromeId 24) with a cold start:

```lua
[1] = {
    ["groupId"] = 1,
    ["name"] = "Player Flight",
    ["task"] = "CAP",
    ["units"] = {
        [1] = {
            ["unitId"] = 1,
            ["name"] = "Player",
            ["type"] = "F-16C_50",
            ["skill"] = "Player",
            ["x"] = -318165.3125,
            ["y"] = 635727.5,
            ["alt"] = 18,
            ["alt_type"] = "BARO",
            ["speed"] = 138.88888888889,
            ["heading"] = 0,
            ["psi"] = 0,
            ["parking"] = "23",
            ["parking_id"] = "17",
            ["onboard_num"] = "010",
            ["livery_id"] = "77th_fighter_squadron",
            ["payload"] = {
                ["pylons"] = {},
                ["fuel"] = 3249,
                ["flare"] = 60,
                ["chaff"] = 60,
                ["gun"] = 100,
            },
            ["callsign"] = {
                [1] = 7,        -- Callsign group (7 = Chevy)
                [2] = 1,        -- Flight number
                [3] = 1,        -- Aircraft number
                ["name"] = "Chevy11",
            },
        },
    },
    ["x"] = -318165.3125,
    ["y"] = 635727.5,
    ["hidden"] = false,
    ["uncontrolled"] = false,
    ["communication"] = true,
    ["frequency"] = 305,
    ["modulation"] = 0,
    ["radioSet"] = false,
    ["start_time"] = 0,
    ["route"] = {
        ["points"] = {
            [1] = {
                ["alt"] = 18,
                ["alt_type"] = "BARO",
                ["type"] = "TakeOffParking",
                ["action"] = "From Parking Area",
                ["x"] = -318165.3125,
                ["y"] = 635727.5,
                ["speed"] = 138.88888888889,
                ["speed_locked"] = true,
                ["ETA"] = 0,
                ["ETA_locked"] = true,
                ["airdromeId"] = 24,
                ["formation_template"] = "",
                ["task"] = {
                    ["id"] = "ComboTask",
                    ["params"] = {
                        ["tasks"] = {},
                    },
                },
            },
        },
    },
},
```

### Traditional Multiplayer Slots Example

For traditional multiplayer missions without dynamic spawn, use `skill = "Client"` and create multiple units for each available slot:

```lua
[1] = {
    ["groupId"] = 1,
    ["name"] = "Viper Flight",
    ["task"] = "CAP",
    ["units"] = {
        [1] = {
            ["unitId"] = 1,
            ["name"] = "Viper 1-1",
            ["type"] = "F-16C_50",
            ["skill"] = "Client",
            ["x"] = -318165.3125,
            ["y"] = 635727.5,
            ["alt"] = 18,
            ["alt_type"] = "BARO",
            ["speed"] = 138.88888888889,
            ["heading"] = 0,
            ["psi"] = 0,
            ["parking"] = "23",
            ["parking_id"] = "17",
            ["onboard_num"] = "101",
            ["livery_id"] = "77th_fighter_squadron",
            ["payload"] = {
                ["pylons"] = {},
                ["fuel"] = 3249,
                ["flare"] = 60,
                ["chaff"] = 60,
                ["gun"] = 100,
            },
            ["callsign"] = {
                [1] = 7,
                [2] = 1,
                [3] = 1,
                ["name"] = "Chevy11",
            },
        },
        [2] = {
            ["unitId"] = 2,
            ["name"] = "Viper 1-2",
            ["type"] = "F-16C_50",
            ["skill"] = "Client",
            ["x"] = -318185.0,
            ["y"] = 635750.0,
            ["alt"] = 18,
            ["alt_type"] = "BARO",
            ["speed"] = 138.88888888889,
            ["heading"] = 0,
            ["psi"] = 0,
            ["parking"] = "24",
            ["parking_id"] = "18",
            ["onboard_num"] = "102",
            ["livery_id"] = "77th_fighter_squadron",
            ["payload"] = {
                ["pylons"] = {},
                ["fuel"] = 3249,
                ["flare"] = 60,
                ["chaff"] = 60,
                ["gun"] = 100,
            },
            ["callsign"] = {
                [1] = 7,
                [2] = 1,
                [3] = 2,
                ["name"] = "Chevy12",
            },
        },
    },
    ["x"] = -318165.3125,
    ["y"] = 635727.5,
    ["hidden"] = false,
    ["uncontrolled"] = false,
    ["communication"] = true,
    ["frequency"] = 305,
    ["modulation"] = 0,
    ["radioSet"] = false,
    ["start_time"] = 0,
    ["route"] = {
        ["points"] = {
            [1] = {
                ["alt"] = 18,
                ["alt_type"] = "BARO",
                ["type"] = "TakeOffParking",
                ["action"] = "From Parking Area",
                ["x"] = -318165.3125,
                ["y"] = 635727.5,
                ["speed"] = 138.88888888889,
                ["speed_locked"] = true,
                ["ETA"] = 0,
                ["ETA_locked"] = true,
                ["airdromeId"] = 24,
                ["formation_template"] = "",
                ["task"] = {
                    ["id"] = "ComboTask",
                    ["params"] = {
                        ["tasks"] = {},
                    },
                },
            },
        },
    },
},
```

---

## Callsign Reference

Common callsign group numbers for US aircraft:

| Number | Callsign |
|--------|----------|
| 1 | Enfield |
| 2 | Springfield |
| 3 | Uzi |
| 4 | Colt |
| 5 | Dodge |
| 6 | Ford |
| 7 | Chevy |
| 8 | Pontiac |

## Aircraft-Specific Properties

Many aircraft have additional configuration in the `AddPropAircraft` table:

```lua
["AddPropAircraft"] = {
    ["HelmetMountedDevice"] = 1,      -- JHMCS enabled
    ["STN_L16"] = "00201",            -- Link-16 STN
    ["VoiceCallsignLabel"] = "ED",    -- Voice callsign
    ["VoiceCallsignNumber"] = "11",
    ["LAU3ROF"] = 0,                  -- LAU-3 rate of fire setting
},
```

These properties vary by aircraft type. Reference the Mission Editor output for specific aircraft.

## Datalink Configuration

For aircraft with Link-16 (F-16, F/A-18, etc.), configure the datalink:

```lua
["datalinks"] = {
    ["Link16"] = {
        ["settings"] = {
            ["flightLead"] = true,
            ["transmitPower"] = 3,
            ["specialChannel"] = 1,
            ["fighterChannel"] = 1,
            ["missionChannel"] = 1,
        },
        ["network"] = {
            ["teamMembers"] = {
                [1] = {
                    ["missionUnitId"] = 1,
                    ["TDOA"] = true,
                },
            },
            ["donors"] = {},
        },
    },
},
```

## Radio Configuration

Aircraft with multiple radios can have preset channels configured:

```lua
["Radio"] = {
    [1] = {
        ["channels"] = {
            [1] = 305,
            [2] = 264,
            [3] = 265,
            -- ... up to 20 channels
        },
        ["modulations"] = {
            [1] = 0,  -- 0 = AM, 1 = FM
            [2] = 0,
            [3] = 0,
            -- ... matching channel count
        },
    },
    [2] = {
        ["channels"] = {
            [1] = 127,
            [2] = 135,
            -- ... UHF/VHF channels
        },
        ["modulations"] = {
            [1] = 0,
            [2] = 0,
        },
    },
},
```

## Common Airfield IDs (Caucasus Map)

| Airfield | airdromeId |
|----------|------------|
| Batumi | 24 |
| Kobuleti | 25 |
| Kutaisi | 26 |
| Senaki | 27 |
| Tbilisi | 32 |
| Vaziani | 33 |
| Sukhumi | 20 |
| Gudauta | 21 |
| Sochi | 18 |
| Mozdok | 15 |

## Checklist

When adding player slots, verify:

- [ ] `groupId` is unique across all groups in the mission
- [ ] `unitId` is unique across all units in the mission
- [ ] `skill` is set to `"Player"` or `"Client"` as appropriate
- [ ] `dynSpawnTemplate` is set to `true` for dynamic spawn templates
- [ ] `parking` and `parking_id` reference valid spots at the airfield
- [ ] `airdromeId` in the first waypoint matches the airfield
- [ ] `x` and `y` coordinates match the airfield location
- [ ] `type` is a valid aircraft type string
- [ ] Unit names are descriptive for slot selection in multiplayer
- [ ] `maxDictId` in the mission root is updated if adding dictionary entries
- [ ] (Dynamic spawn) Warehouse settings enable dynamic spawn for the airfield
- [ ] (Dynamic spawn) Template group is assigned to aircraft type in warehouse settings

## See Also

- [Mission File Schema](../mission/mission-file-schema.md) - Complete schema reference
- [Mission Editor Guide](../mission-editor.md) - GUI-based mission creation
- [Aircraft Reference](../units/planes.md) - Aircraft type strings and loadouts
- [DCS Forum: Dynamic Spawn Guide](https://forum.dcs.world/topic/352814-dynamic-spawn-guide/) - Official ED guide