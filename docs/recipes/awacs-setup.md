# AWACS/AEW&C Aircraft Setup

This recipe describes how to create an Airborne Warning and Control System (AWACS) or Airborne Early Warning & Control (AEW&C) aircraft by directly editing the mission Lua file. A properly configured AWACS provides radar coverage, broadcasts on datalink, and responds to player radio requests for bogey dope and vectors.

> **Note on In-Game AWACS Limitations:** The built-in DCS AWACS radio communication system is widely considered inadequate—it provides limited information, uses non-standard brevity, and lacks situational awareness features that real-world or competitive players expect. For multiplayer servers, consider using an external GCI/AWACS bot such as [SkyEye](https://github.com/dharmab/skyeye/) on a separate frequency. The in-game AWACS aircraft remains valuable for **datalink (Link-16) contacts** via EPLRS, even when voice communications are handled externally.

## Overview

An AWACS aircraft requires:

- **Aircraft Group** - An AWACS-capable aircraft (E-3A, E-2D, A-50, or KJ-2000)
- **AWACS Task** - Activates early warning radar broadcast
- **EPLRS Command** - Enables Link-16 datalink sharing
- **Orbit Task** - Defines the patrol pattern
- **Radio Frequency** - Sets the communication frequency for player requests

## Unit Type Strings

| Aircraft | Type String | Coalition | Recommended Altitude |
|----------|-------------|-----------|---------------------|
| E-3A Sentry | `E-3A` | Blue (NATO) | 30,000 ft (9,144 m) |
| E-2D Advanced Hawkeye | `E-2C` | Blue (NATO) | 20,000 ft (6,096 m) |
| A-50 Mainstay | `A-50` | Red (Russia) | 30,000 ft (9,144 m) |
| KJ-2000 | `KJ-2000` | Red (China) | 30,000 ft (9,144 m) |

> **Note:** The E-2D uses type ID `E-2C` in the mission file despite being the Advanced Hawkeye variant.

## Orbit Pattern Selection

**Always use a Race-Track pattern instead of a Circle pattern.** DCS has a known simulation quirk where the AI's notching logic causes AWACS aircraft to intermittently lose track of contacts when flying perpendicular (90°) to them. In a circular orbit, the aircraft continuously passes through these perpendicular aspects, causing unreliable radar coverage.

A long-legged racetrack pattern minimizes time spent at perpendicular aspects and provides consistent radar coverage toward the threat axis.

### Racetrack Orientation

Orient the racetrack legs **perpendicular to the expected threat direction** so the AWACS radar points toward the threat area during most of the orbit. For example, if threats come from the north, orient the racetrack east-west.

## Mission File Structure

AWACS aircraft are placed in `coalition.[side].country[n].plane.group`. Each group contains units and a route.

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
                            -- AWACS group definition here
                        },
                    },
                },
            },
        },
    },
},
```

## Complete AWACS Group Definition

The following example creates an E-3A AWACS orbiting at 30,000 feet on a racetrack pattern.

```lua
[1] = {
    ["groupId"] = 100,
    ["name"] = "Overlord",
    ["task"] = "AWACS",
    ["modulation"] = 0,           -- 0 = AM
    ["communication"] = true,
    ["frequency"] = 251,          -- MHz (default AWACS frequency)
    ["start_time"] = 0,
    ["uncontrolled"] = false,
    ["hidden"] = false,
    ["x"] = -200000,              -- Initial X position (meters)
    ["y"] = 600000,               -- Initial Y position (meters)
    ["units"] = {
        [1] = {
            ["unitId"] = 100,
            ["name"] = "Overlord-1",
            ["type"] = "E-3A",
            ["skill"] = "High",
            ["x"] = -200000,
            ["y"] = 600000,
            ["alt"] = 9144,       -- 30,000 feet in meters
            ["alt_type"] = "BARO",
            ["speed"] = 180,      -- m/s (~350 knots)
            ["heading"] = 0,
            ["psi"] = 0,
            ["payload"] = {
                ["flare"] = 0,
                ["chaff"] = 0,
                ["fuel"] = 65000,
                ["gun"] = 0,
                ["pylons"] = {},
            },
            ["callsign"] = {
                [1] = 1,          -- Overlord
                [2] = 1,          -- 1
                [3] = 1,          -- 1 (full: "Overlord 11")
                ["name"] = "Overlord11",
            },
        },
    },
    ["route"] = {
        -- Route definition (see below)
    },
},
```

## Route Configuration

The route should start at the orbit position with all tasks assigned to the first waypoint. Use two waypoints to define the racetrack pattern.

### Route Structure

```lua
["route"] = {
    ["routeRelativeTOT"] = true,
    ["points"] = {
        -- Waypoint 1: Orbit start point with AWACS/EPLRS/Orbit tasks
        [1] = {
            ["alt"] = 9144,           -- 30,000 feet in meters
            ["type"] = "Turning Point",
            ["action"] = "Turning Point",
            ["x"] = -200000,
            ["y"] = 600000,
            ["speed"] = 180,          -- m/s (~350 knots)
            ["speed_locked"] = true,
            ["ETA"] = 0,
            ["ETA_locked"] = true,
            ["task"] = {
                ["id"] = "ComboTask",
                ["params"] = {
                    ["tasks"] = {
                        -- AWACS, EPLRS, Frequency, and Orbit tasks here
                    },
                },
            },
        },
        -- Waypoint 2: Orbit end point (for racetrack pattern)
        [2] = {
            ["alt"] = 9144,
            ["type"] = "Turning Point",
            ["action"] = "Turning Point",
            ["x"] = -120000,          -- 80 km leg length (~43 nm)
            ["y"] = 600000,
            ["speed"] = 180,
            ["speed_locked"] = true,
            ["ETA"] = 0,
            ["ETA_locked"] = false,
            ["task"] = {
                ["id"] = "ComboTask",
                ["params"] = {
                    ["tasks"] = {},
                },
            },
        },
    },
},
```

## Waypoint Tasks

All tasks are assigned on the first waypoint using a `ComboTask` container. The order should be:

1. **AWACS** - Activates AWACS functionality
2. **EPLRS** - Enables datalink broadcast
3. **SetFrequency** - Sets radio frequency
4. **Orbit** - Defines the patrol pattern

### AWACS Task

The AWACS task activates the aircraft's early warning radar and enables it to broadcast contacts to friendly units.

```lua
{
    ["enabled"] = true,
    ["auto"] = true,
    ["id"] = "AWACS",
    ["number"] = 1,
    ["params"] = {},
},
```

### EPLRS Task

The EPLRS (Enhanced Position Location Reporting System) task enables Link-16 datalink, allowing the AWACS to share radar contacts with datalink-equipped aircraft.

```lua
{
    ["enabled"] = true,
    ["auto"] = false,
    ["id"] = "WrappedAction",
    ["number"] = 2,
    ["params"] = {
        ["action"] = {
            ["id"] = "EPLRS",
            ["params"] = {
                ["value"] = true,
                ["groupId"] = 100,    -- This group's ID
            },
        },
    },
},
```

### Set Frequency Task

Sets the radio frequency players use to communicate with AWACS for bogey dope and vectors.

```lua
{
    ["enabled"] = true,
    ["auto"] = false,
    ["id"] = "WrappedAction",
    ["number"] = 3,
    ["params"] = {
        ["action"] = {
            ["id"] = "SetFrequency",
            ["params"] = {
                ["frequency"] = 251000000,  -- 251 MHz (standard AWACS)
                ["modulation"] = 0,         -- 0 = AM
                ["power"] = 10,
            },
        },
    },
},
```

### Orbit Task (Race-Track)

The orbit task defines the patrol pattern. Use `Race-Track` pattern with `point` and `point2` defining the leg endpoints.

```lua
{
    ["enabled"] = true,
    ["auto"] = false,
    ["id"] = "Orbit",
    ["number"] = 4,
    ["params"] = {
        ["pattern"] = "Race-Track",
        ["point"] = {
            ["x"] = -200000,
            ["y"] = 600000,
        },
        ["point2"] = {
            ["x"] = -120000,
            ["y"] = 600000,
        },
        ["speed"] = 180,              -- m/s (~350 knots)
        ["altitude"] = 9144,          -- 30,000 feet in meters
    },
},
```

## Complete First Waypoint Task Block

```lua
["task"] = {
    ["id"] = "ComboTask",
    ["params"] = {
        ["tasks"] = {
            [1] = {
                ["enabled"] = true,
                ["auto"] = true,
                ["id"] = "AWACS",
                ["number"] = 1,
                ["params"] = {},
            },
            [2] = {
                ["enabled"] = true,
                ["auto"] = false,
                ["id"] = "WrappedAction",
                ["number"] = 2,
                ["params"] = {
                    ["action"] = {
                        ["id"] = "EPLRS",
                        ["params"] = {
                            ["value"] = true,
                            ["groupId"] = 100,
                        },
                    },
                },
            },
            [3] = {
                ["enabled"] = true,
                ["auto"] = false,
                ["id"] = "WrappedAction",
                ["number"] = 3,
                ["params"] = {
                    ["action"] = {
                        ["id"] = "SetFrequency",
                        ["params"] = {
                            ["frequency"] = 251000000,
                            ["modulation"] = 0,
                            ["power"] = 10,
                        },
                    },
                },
            },
            [4] = {
                ["enabled"] = true,
                ["auto"] = false,
                ["id"] = "Orbit",
                ["number"] = 4,
                ["params"] = {
                    ["pattern"] = "Race-Track",
                    ["point"] = {
                        ["x"] = -200000,
                        ["y"] = 600000,
                    },
                    ["point2"] = {
                        ["x"] = -120000,
                        ["y"] = 600000,
                    },
                    ["speed"] = 180,
                    ["altitude"] = 9144,
                },
            },
        },
    },
},
```

## E-2D Hawkeye Example

The E-2D operates at lower altitude due to its smaller airframe. Use 20,000 feet (6,096 m) and approximately 260 knots (134 m/s).

```lua
[1] = {
    ["groupId"] = 101,
    ["name"] = "Closeout",
    ["task"] = "AWACS",
    ["modulation"] = 0,
    ["communication"] = true,
    ["frequency"] = 264,
    ["start_time"] = 0,
    ["uncontrolled"] = false,
    ["hidden"] = false,
    ["x"] = -180000,
    ["y"] = 550000,
    ["units"] = {
        [1] = {
            ["unitId"] = 101,
            ["name"] = "Closeout-1",
            ["type"] = "E-2C",        -- E-2D uses "E-2C" type string
            ["skill"] = "High",
            ["x"] = -180000,
            ["y"] = 550000,
            ["alt"] = 6096,           -- 20,000 feet in meters
            ["alt_type"] = "BARO",
            ["speed"] = 134,          -- m/s (~260 knots)
            ["heading"] = 0,
            ["psi"] = 0,
            ["payload"] = {
                ["flare"] = 0,
                ["chaff"] = 0,
                ["fuel"] = 5624,
                ["gun"] = 0,
                ["pylons"] = {},
            },
            ["callsign"] = {
                [1] = 3,              -- Chalice
                [2] = 1,
                [3] = 1,
                ["name"] = "Chalice11",
            },
        },
    },
    ["route"] = {
        ["routeRelativeTOT"] = true,
        ["points"] = {
            [1] = {
                ["alt"] = 6096,
                ["type"] = "Turning Point",
                ["action"] = "Turning Point",
                ["x"] = -180000,
                ["y"] = 550000,
                ["speed"] = 134,
                ["speed_locked"] = true,
                ["ETA"] = 0,
                ["ETA_locked"] = true,
                ["task"] = {
                    ["id"] = "ComboTask",
                    ["params"] = {
                        ["tasks"] = {
                            [1] = {
                                ["enabled"] = true,
                                ["auto"] = true,
                                ["id"] = "AWACS",
                                ["number"] = 1,
                                ["params"] = {},
                            },
                            [2] = {
                                ["enabled"] = true,
                                ["auto"] = false,
                                ["id"] = "WrappedAction",
                                ["number"] = 2,
                                ["params"] = {
                                    ["action"] = {
                                        ["id"] = "EPLRS",
                                        ["params"] = {
                                            ["value"] = true,
                                            ["groupId"] = 101,
                                        },
                                    },
                                },
                            },
                            [3] = {
                                ["enabled"] = true,
                                ["auto"] = false,
                                ["id"] = "WrappedAction",
                                ["number"] = 3,
                                ["params"] = {
                                    ["action"] = {
                                        ["id"] = "SetFrequency",
                                        ["params"] = {
                                            ["frequency"] = 264000000,
                                            ["modulation"] = 0,
                                            ["power"] = 10,
                                        },
                                    },
                                },
                            },
                            [4] = {
                                ["enabled"] = true,
                                ["auto"] = false,
                                ["id"] = "Orbit",
                                ["number"] = 4,
                                ["params"] = {
                                    ["pattern"] = "Race-Track",
                                    ["point"] = {
                                        ["x"] = -180000,
                                        ["y"] = 550000,
                                    },
                                    ["point2"] = {
                                        ["x"] = -100000,
                                        ["y"] = 550000,
                                    },
                                    ["speed"] = 134,
                                    ["altitude"] = 6096,
                                },
                            },
                        },
                    },
                },
            },
            [2] = {
                ["alt"] = 6096,
                ["type"] = "Turning Point",
                ["action"] = "Turning Point",
                ["x"] = -100000,
                ["y"] = 550000,
                ["speed"] = 134,
                ["speed_locked"] = true,
                ["ETA"] = 0,
                ["ETA_locked"] = false,
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

## A-50 Mainstay Example (REDFOR)

For Red coalition AWACS, use the A-50 Mainstay. Place in a Russian country entry.

```lua
["coalition"] = {
    ["red"] = {
        ["country"] = {
            [1] = {
                ["id"] = 0,  -- Russia
                ["name"] = "Russia",
                ["plane"] = {
                    ["group"] = {
                        [1] = {
                            ["groupId"] = 200,
                            ["name"] = "Bandar",
                            ["task"] = "AWACS",
                            ["modulation"] = 0,
                            ["communication"] = true,
                            ["frequency"] = 124,
                            ["start_time"] = 0,
                            ["uncontrolled"] = false,
                            ["x"] = 100000,
                            ["y"] = 400000,
                            ["units"] = {
                                [1] = {
                                    ["unitId"] = 200,
                                    ["name"] = "Bandar-1",
                                    ["type"] = "A-50",
                                    ["skill"] = "High",
                                    ["x"] = 100000,
                                    ["y"] = 400000,
                                    ["alt"] = 9144,
                                    ["alt_type"] = "BARO",
                                    ["speed"] = 180,
                                    ["heading"] = 3.14159,   -- Facing south
                                    ["psi"] = -3.14159,
                                    ["payload"] = {
                                        ["flare"] = 192,
                                        ["chaff"] = 192,
                                        ["fuel"] = 70000,
                                        ["gun"] = 0,
                                        ["pylons"] = {},
                                    },
                                    ["callsign"] = 200,
                                },
                            },
                            ["route"] = {
                                -- Similar route structure as E-3A
                            },
                        },
                    },
                },
            },
        },
    },
},
```

## AWACS Callsigns

### NATO Callsigns (Array Format)

| Index | Callsign |
|-------|----------|
| 1 | Overlord |
| 2 | Magic |
| 3 | Chalice |
| 4 | Wizard |
| 5 | Focus |
| 6 | Darkstar |

```lua
["callsign"] = {
    [1] = 1,          -- Callsign family (1 = Overlord)
    [2] = 1,          -- Flight number
    [3] = 1,          -- Element number
    ["name"] = "Overlord11",
},
```

### Russian Callsigns (Numeric Format)

Russian aircraft use a simple numeric callsign:

```lua
["callsign"] = 200,   -- Three-digit number
```

## Common Radio Frequencies

| Frequency | Use |
|-----------|-----|
| 251.000 MHz | Default AWACS (Blue) |
| 264.000 MHz | Alternate AWACS (Blue) |
| 124.000 MHz | Common Russian frequency |
| 225.000 MHz | Military common |

## Unit Conversions

| Measurement | Conversion |
|-------------|------------|
| 30,000 ft | 9,144 m |
| 25,000 ft | 7,620 m |
| 20,000 ft | 6,096 m |
| 350 knots | 180 m/s |
| 300 knots | 154 m/s |
| 260 knots | 134 m/s |
| 50 nm | 92,600 m |
| 40 nm | 74,080 m |

## Checklist

Before finalizing the AWACS setup, verify:

- [ ] Aircraft type matches coalition (E-3A/E-2D for Blue, A-50/KJ-2000 for Red)
- [ ] AWACS task is enabled on first waypoint (`["id"] = "AWACS"`)
- [ ] EPLRS is enabled with correct `groupId` reference
- [ ] Radio frequency is set via `SetFrequency` action
- [ ] Orbit pattern is `Race-Track` (not `Circle`)
- [ ] Racetrack leg length is at least 40-50 nm (74-93 km)
- [ ] Racetrack oriented perpendicular to threat direction
- [ ] Altitude is realistic for aircraft type (30,000 ft for E-3A/A-50, 20,000 ft for E-2D)
- [ ] Speed is appropriate for aircraft (~350 kts for E-3A, ~260 kts for E-2D)
- [ ] Waypoint 1 altitude/speed matches Orbit task altitude/speed
- [ ] All `groupId` and `unitId` values are unique within the mission

## Troubleshooting

### AWACS Not Broadcasting Contacts

- Verify the AWACS task is enabled (`["enabled"] = true`)
- Check that the aircraft has reached its patrol altitude
- Ensure contacts are within radar range (approximately 200+ nm for E-3A)

### No AWACS Option in Comms Menu

- Verify you are tuned to the correct radio frequency (AM band)
- Check that `SetFrequency` action is on the first waypoint
- Ensure your aircraft radio is set to the matching frequency

### AWACS Returning to Base

- Check that the orbit altitude in the task matches waypoint altitudes
- Verify speed settings are consistent between waypoints and orbit task
- Ensure fuel is sufficient (AWACS aircraft consume significant fuel)

### Intermittent Contact Tracking

- Switch from Circle to Race-Track pattern
- Increase racetrack leg length for less time in turns
- Orient racetrack perpendicular to primary threat axis

## See Also

- [Mission File Schema](../mission/mission-file-schema.md) - Complete mission file reference
- [AI Tasks Reference](../scripting/reference/ai/tasks.md) - Detailed task documentation
- [AI Commands Reference](../scripting/reference/ai/commands.md) - Command documentation including EPLRS