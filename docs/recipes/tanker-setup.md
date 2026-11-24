# Aerial Refueling Tanker Setup

This recipe creates tankers by editing the mission Lua file. A tanker flies a racetrack pattern, broadcasts a TACAN beacon for navigation, and refuels aircraft that request it.

## Overview

A tanker aircraft requires:

- **Aircraft Group** - A tanker-capable aircraft (KC-135, KC-135MPRS, KC-130, S-3B Tanker, or IL-78M)
- **Tanker Task** - Activates aerial refueling capability
- **TACAN Beacon** - Allows aircraft without radar to navigate to the tanker
- **Orbit Task** - Defines the refueling racetrack pattern
- **Unlimited Fuel** - Ensures the tanker doesn't run out of fuel during extended operations
- **Radio Frequency** - Sets the communication frequency for tanker requests

## Refueling System Compatibility

DCS models two aerial refueling systems. Each aircraft must use a tanker that matches its refueling system:

| Refueling System          | Tanker Aircraft                         | Receiver Aircraft                                                              |
| ------------------------- | --------------------------------------- | ------------------------------------------------------------------------------ |
| Probe-and-Drogue (Basket) | KC-130, KC-135MPRS, S-3B Tanker, IL-78M | F/A-18, AV-8B, A-6, Mirage, Rafale, Su-27/33, MiG-29, Tornado, all helicopters |
| Flying Boom               | KC-135                                  | F-15, F-16, A-10, F-4, B-52                                                    |

> **Note:** The KC-135MPRS (Multi-Point Refueling System) is a KC-135 variant with wing-mounted drogue pods. The real aircraft also has a functioning boom, but in DCS the KC-135MPRS refuels only probe-equipped aircraft. Use a standard KC-135 for boom receivers.

## Unit Type Strings

| Aircraft            | Type String   | Coalition    | Refueling System | Recommended Altitude             |
| ------------------- | ------------- | ------------ | ---------------- | -------------------------------- |
| KC-135 Stratotanker | `KC-135`      | Blue (NATO)  | Flying Boom      | 20,000-25,000 ft (6,096-7,620 m) |
| KC-135MPRS          | `KC135MPRS`   | Blue (NATO)  | Probe-and-Drogue | 20,000-25,000 ft (6,096-7,620 m) |
| KC-130 Hercules     | `KC130`       | Blue (NATO)  | Probe-and-Drogue | 15,000-20,000 ft (4,572-6,096 m) |
| S-3B Viking Tanker  | `S-3B Tanker` | Blue (NATO)  | Probe-and-Drogue | 15,000-20,000 ft (4,572-6,096 m) |
| Il-78M Midas        | `IL-78M`      | Red (Russia) | Probe-and-Drogue | 20,000-25,000 ft (6,096-7,620 m) |

> **Note:** The S-3B Tanker is typically used for carrier operations, giving the carrier air wing its own tanker.

> **Slow Receiver Aircraft:** When supporting slow aircraft such as the A-10, configure the tanker to fly much slower, between 180 and 250 knots indicated airspeed. An A-10 with a combat load may not be able to catch or stay in formation with a tanker flying at typical jet speeds (350-400 knots).

## Orbit Pattern Selection

**Use a Race-Track or Anchored pattern for tanker operations, never Circle.** The straight refueling legs make it easier for receivers to join and hold formation during fuel transfer. Orient the legs so the approach and departure airspace is clear.

- **Race-Track** - Two points define the ends of the legs. Use it when you want to place both ends exactly.
- **Anchored** - One point (the ARCP) plus a hot leg heading, leg length, width, and turn direction. Use it to build a track from a published refueling anchor, or when you want fixed leg length and width. See [Orbit Task (Anchored)](#orbit-task-anchored).

### Racetrack Orientation

- Orient the racetrack parallel to the expected flow of receiver traffic
- Consider a track perpendicular to the threat axis so receivers refuel close to their operating area
- A typical leg length of 30-50 nm provides adequate time for refueling on each leg

## Mission File Structure

Tanker aircraft are placed in `coalition.[side].country[n].plane.group`. Each group contains units and a route.

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
                            -- Tanker group definition here
                        },
                    },
                },
            },
        },
    },
},
```

## Complete KC-135 Tanker Group Definition

The following example creates a KC-135 tanker on a racetrack at 22,000 feet with a TACAN beacon.

```lua
[1] = {
    ["groupId"] = 200,
    ["name"] = "Texaco",
    ["task"] = "Refueling",
    ["modulation"] = 0,           -- 0 = AM
    ["communication"] = true,
    ["frequency"] = 251,          -- MHz
    ["start_time"] = 0,
    ["uncontrolled"] = false,
    ["hidden"] = false,
    ["x"] = -200000,              -- Initial X position (meters)
    ["y"] = 550000,               -- Initial Y position (meters)
    ["units"] = {
        [1] = {
            ["unitId"] = 200,
            ["name"] = "Texaco-1",
            ["type"] = "KC-135",
            ["skill"] = "Excellent",
            ["x"] = -200000,
            ["y"] = 550000,
            ["alt"] = 6706,       -- 22,000 feet in meters
            ["alt_type"] = "BARO",
            ["speed"] = 154,      -- m/s (~300 knots)
            ["heading"] = 0,
            ["psi"] = 0,
            ["payload"] = {
                ["flare"] = 0,
                ["chaff"] = 0,
                ["fuel"] = 90700,
                ["gun"] = 0,
                ["pylons"] = {},
            },
            ["callsign"] = {
                [1] = 1,          -- Texaco
                [2] = 1,          -- 1
                [3] = 1,          -- 1 (full: "Texaco 11")
                ["name"] = "Texaco11",
            },
        },
    },
    ["route"] = {
        -- Route definition (see below)
    },
},
```

## Route Configuration

Start the route at the orbit position, with all tasks on the first waypoint, and use two waypoints to define the racetrack.

### Route Structure

```lua
["route"] = {
    ["routeRelativeTOT"] = true,
    ["points"] = {
        -- Waypoint 1: Orbit start point with Tanker/TACAN/Orbit tasks
        [1] = {
            ["alt"] = 6706,           -- 22,000 feet in meters
            ["type"] = "Turning Point",
            ["action"] = "Turning Point",
            ["x"] = -200000,
            ["y"] = 550000,
            ["speed"] = 154,          -- m/s (~300 knots)
            ["speed_locked"] = true,
            ["ETA"] = 0,
            ["ETA_locked"] = true,
            ["task"] = {
                ["id"] = "ComboTask",
                ["params"] = {
                    ["tasks"] = {
                        -- Tanker, TACAN, Frequency, Orbit, Unlimited Fuel tasks here
                    },
                },
            },
        },
        -- Waypoint 2: Orbit end point (for racetrack pattern)
        [2] = {
            ["alt"] = 6706,
            ["type"] = "Turning Point",
            ["action"] = "Turning Point",
            ["x"] = -120000,          -- 80 km leg length (~43 nm)
            ["y"] = 550000,
            ["speed"] = 154,
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

1. **Tanker** - Activates tanker functionality
2. **ActivateBeacon** - Enables TACAN beacon
3. **SetFrequency** - Sets radio frequency
4. **Orbit** - Defines the patrol pattern
5. **SetUnlimitedFuel** - Prevents fuel depletion

### Tanker Task

The Tanker task turns on the aircraft's refueling capability so it answers refueling requests.

```lua
{
    ["enabled"] = true,
    ["auto"] = true,
    ["id"] = "Tanker",
    ["number"] = 1,
    ["params"] = {},
},
```

### TACAN Beacon Configuration

The TACAN beacon lets receiving aircraft find the tanker with their TACAN. It is an `ActivateBeacon` command on the tanker's first waypoint.

| Field         | Value                                                                              |
| ------------- | ---------------------------------------------------------------------------------- |
| `type`        | `4` (`BEACON_TYPE_TACAN`)                                                          |
| `system`      | `4` (`TACAN_TANKER_MODE_X`) or `5` (`TACAN_TANKER_MODE_Y`), matching `modeChannel` |
| `channel`     | `1` to `126`                                                                       |
| `modeChannel` | `"X"` or `"Y"`                                                                     |
| `frequency`   | Hz, calculated from the channel and mode (see below)                               |
| `AA`          | `false`                                                                            |
| `bearing`     | `true`                                                                             |
| `callsign`    | Morse identifier, e.g. `"TXC"`                                                     |

TACAN has two modes, X and Y, each with channels 1 to 126, for 252 channels in total. Channels with the same number in different modes use different frequencies, so 33X and 33Y do not conflict.

**Frequency for X-mode channels:**

- Channels 1-63: 962 + channel - 1 MHz
- Channels 64-126: 1151 + channel - 64 MHz

For example, channel 100X is 1151 + 100 - 64 = 1187 MHz, so `frequency = 1187000000`. See [ActivateBeacon](../scripting/reference/ai/commands.md#activatebeacon) for Y-mode channels.

```lua
{
    ["enabled"] = true,
    ["auto"] = false,
    ["id"] = "WrappedAction",
    ["number"] = 2,
    ["params"] = {
        ["action"] = {
            ["id"] = "ActivateBeacon",
            ["params"] = {
                ["type"] = 4,
                ["system"] = 4,
                ["name"] = "Texaco",
                ["callsign"] = "TXC",
                ["frequency"] = 1187000000,  -- Channel 100X
                ["channel"] = 100,
                ["modeChannel"] = "X",
                ["AA"] = false,
                ["bearing"] = true,
            },
        },
    },
},
```

### Set Frequency Task

Sets the radio frequency players use to communicate with the tanker for join-up requests.

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
                ["frequency"] = 251000000,  -- 251 MHz (common tanker frequency)
                ["modulation"] = 0,         -- 0 = AM
                ["power"] = 10,
            },
        },
    },
},
```

### Orbit Task (Race-Track)

The orbit task defines the tanker's pattern. Use `Race-Track`, with `point` and `point2` as the leg endpoints.

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
            ["y"] = 550000,
        },
        ["point2"] = {
            ["x"] = -120000,
            ["y"] = 550000,
        },
        ["speed"] = 154,              -- m/s (~300 knots)
        ["altitude"] = 6706,          -- 22,000 feet in meters
    },
},
```

### Orbit Task (Anchored)

The Anchored pattern builds the track from one point. The track has two straight legs: the **hot leg**, flown on `hotLegDir` toward the ARCP, where receivers plan to join, and the **return leg** (the cold leg), flown the opposite way back to the start of the hot leg. `point` is the ARCP (Air Refueling Control Point), at the **end** of the hot leg, and the track extends behind it. The tanker flies the hot leg into the ARCP, turns, and flies the return leg back. `legLength` is each straight leg without the turns, and `width` is the distance between the two legs. With `clockWise = false` the tanker turns left, so the return leg is on the left of the hot leg. See [Anchored pattern geometry](../scripting/reference/ai/tasks.md#anchored-pattern-geometry).

In the mission editor these are the Hot Leg Brg, Leg length, Width, and Clockwise fields of the Orbit task with the Anchored pattern.

This example puts the ARCP at the east end of a 50 nm hot leg flown east, with the return leg 20 nm to the north.

```lua
{
    ["enabled"] = true,
    ["auto"] = false,
    ["id"] = "Orbit",
    ["number"] = 4,
    ["params"] = {
        ["pattern"] = "Anchored",
        ["point"] = {                 -- ARCP: end of the hot leg
            ["x"] = -120000,
            ["y"] = 550000,
        },
        ["hotLegDir"] = 1.5707963,    -- 90° in radians: hot leg flown east into the ARCP
        ["legLength"] = 92600,        -- 50 nm in meters, turns not included
        ["width"] = 37040,            -- 20 nm in meters between the legs
        ["clockWise"] = false,        -- left turns: return leg 20 nm north of the hot leg
        ["speed"] = 154,              -- m/s (~300 knots)
        ["altitude"] = 6706,          -- 22,000 feet in meters
    },
},
```

Place the waypoint carrying the Orbit task at the ARCP, or set `point` to it. Putting the ARCP at the start of the intended hot leg is a common mistake: the whole track then sits one leg length too far upstream.

### Unlimited Fuel Task

Enable unlimited fuel to ensure the tanker can operate for the duration of the mission without running dry.

```lua
{
    ["enabled"] = true,
    ["auto"] = false,
    ["id"] = "WrappedAction",
    ["number"] = 5,
    ["params"] = {
        ["action"] = {
            ["id"] = "SetUnlimitedFuel",
            ["params"] = {
                ["value"] = true,
            },
        },
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
                ["id"] = "Tanker",
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
                        ["id"] = "ActivateBeacon",
                        ["params"] = {
                            ["type"] = 4,
                            ["system"] = 4,
                            ["name"] = "Texaco",
                            ["callsign"] = "TXC",
                            ["frequency"] = 1187000000,
                            ["channel"] = 100,
                            ["modeChannel"] = "X",
                            ["AA"] = false,
                            ["bearing"] = true,
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
                        ["y"] = 550000,
                    },
                    ["point2"] = {
                        ["x"] = -120000,
                        ["y"] = 550000,
                    },
                    ["speed"] = 154,
                    ["altitude"] = 6706,
                },
            },
            [5] = {
                ["enabled"] = true,
                ["auto"] = false,
                ["id"] = "WrappedAction",
                ["number"] = 5,
                ["params"] = {
                    ["action"] = {
                        ["id"] = "SetUnlimitedFuel",
                        ["params"] = {
                            ["value"] = true,
                        },
                    },
                },
            },
        },
    },
},
```

## KC-135MPRS Example (Drogue-Equipped)

The KC-135MPRS is configured the same way as the KC-135. In DCS it provides only probe-and-drogue refueling, so it supports probe-equipped aircraft such as Navy and Marine jets but not boom receivers.

```lua
[1] = {
    ["groupId"] = 201,
    ["name"] = "Shell",
    ["task"] = "Refueling",
    ["modulation"] = 0,
    ["communication"] = true,
    ["frequency"] = 264,
    ["start_time"] = 0,
    ["uncontrolled"] = false,
    ["hidden"] = false,
    ["x"] = -180000,
    ["y"] = 520000,
    ["units"] = {
        [1] = {
            ["unitId"] = 201,
            ["name"] = "Shell-1",
            ["type"] = "KC135MPRS",
            ["skill"] = "Excellent",
            ["x"] = -180000,
            ["y"] = 520000,
            ["alt"] = 6706,       -- 22,000 feet
            ["alt_type"] = "BARO",
            ["speed"] = 154,      -- m/s (~300 knots)
            ["heading"] = 0,
            ["psi"] = 0,
            ["payload"] = {
                ["flare"] = 0,
                ["chaff"] = 0,
                ["fuel"] = 90700,
                ["gun"] = 0,
                ["pylons"] = {},
            },
            ["callsign"] = {
                [1] = 2,          -- Shell
                [2] = 1,
                [3] = 1,
                ["name"] = "Shell11",
            },
        },
    },
    ["route"] = {
        -- Same route structure as KC-135
    },
},
```

## KC-130 Example (Tactical Tanker)

The KC-130 flies at lower altitudes and speeds, which suits refueling helicopters and slower aircraft.

```lua
[1] = {
    ["groupId"] = 202,
    ["name"] = "Arco",
    ["task"] = "Refueling",
    ["modulation"] = 0,
    ["communication"] = true,
    ["frequency"] = 276,
    ["start_time"] = 0,
    ["uncontrolled"] = false,
    ["hidden"] = false,
    ["x"] = -160000,
    ["y"] = 500000,
    ["units"] = {
        [1] = {
            ["unitId"] = 202,
            ["name"] = "Arco-1",
            ["type"] = "KC130",
            ["skill"] = "Excellent",
            ["x"] = -160000,
            ["y"] = 500000,
            ["alt"] = 5486,       -- 18,000 feet in meters
            ["alt_type"] = "BARO",
            ["speed"] = 154,      -- m/s (~300 knots)
            ["heading"] = 0,
            ["psi"] = 0,
            ["payload"] = {
                ["flare"] = 0,
                ["chaff"] = 0,
                ["fuel"] = 30000,
                ["gun"] = 0,
                ["pylons"] = {},
            },
            ["callsign"] = {
                [1] = 3,          -- Arco
                [2] = 1,
                [3] = 1,
                ["name"] = "Arco11",
            },
        },
    },
    ["route"] = {
        ["routeRelativeTOT"] = true,
        ["points"] = {
            [1] = {
                ["alt"] = 5486,
                ["type"] = "Turning Point",
                ["action"] = "Turning Point",
                ["x"] = -160000,
                ["y"] = 500000,
                ["speed"] = 154,
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
                                ["id"] = "Tanker",
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
                                        ["id"] = "ActivateBeacon",
                                        ["params"] = {
                                            ["type"] = 4,
                                            ["system"] = 4,
                                            ["name"] = "Arco",
                                            ["callsign"] = "ARC",
                                            ["frequency"] = 1160000000,  -- Channel 73X
                                            ["channel"] = 73,
                                            ["modeChannel"] = "X",
                                            ["AA"] = false,
                                            ["bearing"] = true,
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
                                            ["frequency"] = 276000000,
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
                                        ["x"] = -160000,
                                        ["y"] = 500000,
                                    },
                                    ["point2"] = {
                                        ["x"] = -100000,
                                        ["y"] = 500000,
                                    },
                                    ["speed"] = 154,
                                    ["altitude"] = 5486,
                                },
                            },
                            [5] = {
                                ["enabled"] = true,
                                ["auto"] = false,
                                ["id"] = "WrappedAction",
                                ["number"] = 5,
                                ["params"] = {
                                    ["action"] = {
                                        ["id"] = "SetUnlimitedFuel",
                                        ["params"] = {
                                            ["value"] = true,
                                        },
                                    },
                                },
                            },
                        },
                    },
                },
            },
            [2] = {
                ["alt"] = 5486,
                ["type"] = "Turning Point",
                ["action"] = "Turning Point",
                ["x"] = -100000,
                ["y"] = 500000,
                ["speed"] = 154,
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

## S-3B Tanker Example (Carrier-Based)

The S-3B Tanker serves carrier air wings and usually flies at lower altitudes, close to the carrier.

```lua
[1] = {
    ["groupId"] = 203,
    ["name"] = "Texaco Viking",
    ["task"] = "Refueling",
    ["modulation"] = 0,
    ["communication"] = true,
    ["frequency"] = 290,
    ["start_time"] = 0,
    ["uncontrolled"] = false,
    ["hidden"] = false,
    ["x"] = -150000,
    ["y"] = 480000,
    ["units"] = {
        [1] = {
            ["unitId"] = 203,
            ["name"] = "Texaco Viking-1",
            ["type"] = "S-3B Tanker",
            ["skill"] = "Excellent",
            ["x"] = -150000,
            ["y"] = 480000,
            ["alt"] = 4572,       -- 15,000 feet in meters
            ["alt_type"] = "BARO",
            ["speed"] = 128,      -- m/s (~250 knots)
            ["heading"] = 0,
            ["psi"] = 0,
            ["payload"] = {
                ["flare"] = 30,
                ["chaff"] = 30,
                ["fuel"] = 7813,
                ["gun"] = 0,
                ["pylons"] = {},
            },
            ["callsign"] = {
                [1] = 1,
                [2] = 2,
                [3] = 1,
                ["name"] = "Texaco21",
            },
        },
    },
    ["route"] = {
        -- Orbit task with lower altitude (4572m/15000ft) and slower speed (128 m/s)
    },
},
```

## IL-78M Example (REDFOR)

The Ilyushin Il-78M provides aerial refueling capability for Russian and allied aircraft.

```lua
[1] = {
    ["groupId"] = 210,
    ["name"] = "Midas",
    ["task"] = "Refueling",
    ["modulation"] = 0,
    ["communication"] = true,
    ["frequency"] = 132,
    ["start_time"] = 0,
    ["uncontrolled"] = false,
    ["hidden"] = false,
    ["x"] = 100000,
    ["y"] = 400000,
    ["units"] = {
        [1] = {
            ["unitId"] = 210,
            ["name"] = "Midas-1",
            ["type"] = "IL-78M",
            ["skill"] = "Excellent",
            ["x"] = 100000,
            ["y"] = 400000,
            ["alt"] = 7010,       -- 23,000 feet in meters
            ["alt_type"] = "BARO",
            ["speed"] = 154,      -- m/s (~300 knots)
            ["heading"] = 0,
            ["psi"] = 0,
            ["payload"] = {
                ["flare"] = 0,
                ["chaff"] = 0,
                ["fuel"] = 70000,
                ["gun"] = 0,
                ["pylons"] = {},
            },
            ["callsign"] = 605,   -- Numeric callsign for Russian aircraft
        },
    },
    ["route"] = {
        ["routeRelativeTOT"] = true,
        ["points"] = {
            [1] = {
                ["alt"] = 7010,
                ["type"] = "Turning Point",
                ["action"] = "Turning Point",
                ["x"] = 100000,
                ["y"] = 400000,
                ["speed"] = 154,
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
                                ["id"] = "Tanker",
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
                                        ["id"] = "ActivateBeacon",
                                        ["params"] = {
                                            ["type"] = 4,
                                            ["system"] = 4,
                                            ["name"] = "Midas",
                                            ["callsign"] = "MID",
                                            ["frequency"] = 1177000000,  -- Channel 90X
                                            ["channel"] = 90,
                                            ["modeChannel"] = "X",
                                            ["AA"] = false,
                                            ["bearing"] = true,
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
                                            ["frequency"] = 132000000,
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
                                        ["x"] = 100000,
                                        ["y"] = 400000,
                                    },
                                    ["point2"] = {
                                        ["x"] = 180000,
                                        ["y"] = 400000,
                                    },
                                    ["speed"] = 154,
                                    ["altitude"] = 7010,
                                },
                            },
                            [5] = {
                                ["enabled"] = true,
                                ["auto"] = false,
                                ["id"] = "WrappedAction",
                                ["number"] = 5,
                                ["params"] = {
                                    ["action"] = {
                                        ["id"] = "SetUnlimitedFuel",
                                        ["params"] = {
                                            ["value"] = true,
                                        },
                                    },
                                },
                            },
                        },
                    },
                },
            },
            [2] = {
                ["alt"] = 7010,
                ["type"] = "Turning Point",
                ["action"] = "Turning Point",
                ["x"] = 180000,
                ["y"] = 400000,
                ["speed"] = 154,
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

## Tanker Callsigns

### NATO Callsigns (Array Format)

For BLUEFOR tankers, use the three-element array callsign format:

| Callsign Name | Index [1] | Example                             |
| ------------- | --------- | ----------------------------------- |
| Texaco        | 1         | `[1]=1, [2]=1, [3]=1` → "Texaco 11" |
| Arco          | 2         | `[1]=2, [2]=1, [3]=1` → "Arco 11"   |
| Shell         | 3         | `[1]=3, [2]=1, [3]=1` → "Shell 11"  |

DCS has only three tanker callsign names. A mission with more than three tankers must reuse a name with a different flight number (`[2]`), such as "Arco 21". A known DCS multiplayer bug can label every tanker that shares a name with the same callsign in the F10 radio menu (for example, Arco 11 and Arco 21 both shown as "Arco 11"). Separately, VAICOM recognizes only the base name.

### Russian Callsigns (Numeric Format)

For REDFOR tankers, use a three-digit numeric callsign:

```lua
["callsign"] = 605,
```

## Common Tanker Frequencies

These are typical values. Missions that follow the [standardized comm plan](comm-plan.md) should use its tanker frequencies instead (270.1 basket, 270.3 recovery, 270.5 fighter boom, 270.7 heavy boom).

| Tanker Role    | Frequency | Notes             |
| -------------- | --------- | ----------------- |
| Primary Boom   | 251.0 MHz | KC-135            |
| Primary Drogue | 264.0 MHz | KC-135MPRS/KC-130 |
| Alternate      | 276.0 MHz | Secondary tanker  |
| Carrier Tanker | 290.0 MHz | S-3B Viking       |
| REDFOR         | 132.0 MHz | IL-78M            |

## Common TACAN Channels

| Tanker         | Channel | Frequency (Hz) |
| -------------- | ------- | -------------- |
| Primary Boom   | 100X    | 1187000000     |
| Primary Drogue | 101X    | 1188000000     |
| KC-130         | 73X     | 1160000000     |
| S-3B           | 75X     | 1162000000     |
| REDFOR         | 90X     | 1177000000     |

## Unit Conversions

| Measurement | Conversion |
| ----------- | ---------- |
| 25,000 ft   | 7,620 m    |
| 22,000 ft   | 6,706 m    |
| 20,000 ft   | 6,096 m    |
| 18,000 ft   | 5,486 m    |
| 15,000 ft   | 4,572 m    |
| 350 knots   | 180 m/s    |
| 300 knots   | 154 m/s    |
| 275 knots   | 141 m/s    |
| 250 knots   | 128 m/s    |
| 200 knots   | 103 m/s    |
| 50 nm       | 92,600 m   |
| 40 nm       | 74,080 m   |
| 30 nm       | 55,560 m   |

## Checklist

Before finalizing the tanker setup, verify:

- [ ] Aircraft type matches coalition (KC-135/KC-130/S-3B for Blue, IL-78M for Red)
- [ ] Aircraft type matches receiver refueling system (boom vs. drogue)
- [ ] Tanker task is enabled on first waypoint (`["id"] = "Tanker"`)
- [ ] TACAN beacon uses `["system"] = 4` (`TACAN_TANKER_MODE_X`), `["AA"] = false`, and a frequency that matches the channel
- [ ] TACAN channel is unique and doesn't conflict with other beacons
- [ ] Radio frequency is set via `SetFrequency` action
- [ ] `SetUnlimitedFuel` is enabled to prevent fuel depletion
- [ ] Orbit pattern is `Race-Track` or `Anchored` (not `Circle`)
- [ ] Racetrack leg length is at least 30-50 nm (55-93 km)
- [ ] For `Anchored`, `point` is the ARCP at the end of the hot leg, and `hotLegDir` is in radians
- [ ] Altitude is realistic for aircraft type (15,000-25,000 ft typical)
- [ ] Speed is appropriate for aircraft and expected receivers (~275-350 kts for KC-135 with fast jets, ~180-250 kts when supporting slow aircraft like A-10, ~300 kts for KC-130, ~250 kts for S-3B)
- [ ] Waypoint 1 altitude/speed matches Orbit task altitude/speed
- [ ] All `groupId` and `unitId` values are unique within the mission

## Troubleshooting

### Tanker Not Responding to Requests

- Verify the Tanker task is enabled (`["enabled"] = true`)
- Check that the aircraft has reached its patrol altitude
- Ensure you are on the correct radio frequency (AM band)
- Verify the receiver aircraft is compatible with the tanker's refueling system

### TACAN Not Appearing

- Verify `["system"] = 4` (`TACAN_TANKER_MODE_X`) or `5` (Y mode) is set, not `3` (`TACAN`)
- Check that `["frequency"]` matches the channel, mode, and `AA` flag (see [ActivateBeacon](../scripting/reference/ai/commands.md#activatebeacon))
- Ensure the TACAN channel doesn't conflict with other beacons
- Verify the `ActivateBeacon` task is on the first waypoint

### Tanker Running Out of Fuel

- Add `SetUnlimitedFuel` command with `["value"] = true`
- Ensure the task is on the first waypoint

### Receiver Cannot Connect

- Verify the receiver is compatible with the tanker's refueling system
- Boom receivers (F-15, F-16, A-10) need KC-135
- Probe receivers (F/A-18, AV-8B, Su-27) need KC-135MPRS, KC-130, S-3B, or IL-78M
- Check that the tanker is in a stable racetrack pattern

### Tanker Returning to Base

- Check that the orbit altitude in the task matches waypoint altitudes
- Verify speed settings are consistent between waypoints and orbit task
- Ensure `SetUnlimitedFuel` is enabled

## See Also

- [AWACS Setup](awacs-setup.md) - Similar airborne support asset configuration
- [Carrier Strike Group Setup](csg-setup.md) - S-3B tanker in carrier operations context
- [Mission File Schema](../mission/mission-file-schema.md) - Complete mission file reference
- [AI Tasks](../scripting/reference/ai/tasks.md) - Tanker task reference
- [AI Commands](../scripting/reference/ai/commands.md) - ActivateBeacon, SetUnlimitedFuel reference
- [AI Enums](../scripting/reference/enums/ai.md) - Beacon type and system constants
- [Planes](../units/planes.md) - Tanker aircraft specifications
