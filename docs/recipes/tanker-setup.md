# Aerial Refueling Tanker Setup

This recipe describes how to create aerial refueling tanker aircraft by directly editing the mission Lua file. A properly configured tanker flies a racetrack pattern, broadcasts a TACAN beacon for navigation, and provides fuel to requesting aircraft.

## Overview

A tanker aircraft requires:

- **Aircraft Group** - A tanker-capable aircraft (KC-135, KC-135MPRS, KC-130, S-3B Tanker, or IL-78M)
- **Tanker Task** - Activates aerial refueling capability
- **TACAN Beacon** - Allows aircraft without radar to navigate to the tanker
- **Orbit Task** - Defines the refueling racetrack pattern
- **Unlimited Fuel** - Ensures the tanker doesn't run out of fuel during extended operations
- **Radio Frequency** - Sets the communication frequency for tanker requests

## Refueling System Compatibility

DCS models two distinct aerial refueling systems. Aircraft must use a tanker compatible with their refueling system:

| Refueling System | Tanker Aircraft | Receiver Aircraft |
|------------------|-----------------|-------------------|
| Probe-and-Drogue (Basket) | KC-130, KC-135MPRS, S-3B Tanker, IL-78M | F/A-18, AV-8B, A-6, Mirage, Rafale, Su-27/33, MiG-29, Tornado, all helicopters |
| Flying Boom | KC-135 | F-15, F-16, A-10, F-4, B-52 |

> **Note:** The KC-135MPRS (Multi-Point Refueling System) is a KC-135 variant equipped with wing-mounted drogue pods, allowing it to refuel probe-equipped aircraft. Use this tanker when you need to support Navy/Marine aircraft with a boom-equipped tanker airframe.

## Unit Type Strings

| Aircraft | Type String | Coalition | Refueling System | Recommended Altitude |
|----------|-------------|-----------|------------------|---------------------|
| KC-135 Stratotanker | `KC-135` | Blue (NATO) | Flying Boom | 20,000-25,000 ft (6,096-7,620 m) |
| KC-135MPRS | `KC135MPRS` | Blue (NATO) | Probe-and-Drogue | 20,000-25,000 ft (6,096-7,620 m) |
| KC-130 Hercules | `KC130` | Blue (NATO) | Probe-and-Drogue | 15,000-20,000 ft (4,572-6,096 m) |
| S-3B Viking Tanker | `S-3B Tanker` | Blue (NATO) | Probe-and-Drogue | 15,000-20,000 ft (4,572-6,096 m) |
| Il-78M Midas | `IL-78M` | Red (Russia) | Probe-and-Drogue | 20,000-25,000 ft (6,096-7,620 m) |

> **Note:** The S-3B Tanker is typically used for carrier-based operations, providing organic tanking capability to the carrier air wing.

> **Slow Receiver Aircraft:** When supporting slow aircraft like the A-10, configure the tanker to fly significantly slower—between 180 and 250 knots indicated airspeed. The A-10's maximum speed with combat loads may not allow it to catch or maintain formation with a tanker flying at typical jet speeds (350-400 knots).

## Orbit Pattern Selection

**Always use a Race-Track pattern for tanker operations.** The racetrack provides predictable, straight refueling legs that make it easier for receiver aircraft to join and maintain formation during fuel transfer. Orient the racetrack legs to provide clear airspace for approach and departure.

### Racetrack Orientation

- Orient the racetrack parallel to the expected flow of receiver traffic
- Consider placing the tanker track perpendicular to the threat axis so receivers can refuel while remaining relatively close to their operating area
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

The following example creates a KC-135 tanker orbiting at 22,000 feet on a racetrack pattern with TACAN beacon.

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

The route should start at the orbit position with all tasks assigned to the first waypoint. Use two waypoints to define the racetrack pattern.

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

The Tanker task activates the aircraft's aerial refueling capability, allowing it to respond to refueling requests.

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

The TACAN beacon allows aircraft to navigate to the tanker using their TACAN receiver. Use the `TACAN_TANKER` system (4) instead of regular `TACAN` (3) to enable air-to-air TACAN mode.

> **Note:** Always use X-mode TACAN channels for tankers. Y-mode is not commonly used for air-to-air refueling operations.

**TACAN Frequency Calculation (X-mode):**
- Channels 70-126: frequency = 1088 + channel (MHz)

For example, channel **100X**:
- X-mode channel 100: frequency = 1088 + 100 = **1188 MHz** = **1188000000 Hz**

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
                ["type"] = 4,           -- BEACON_TYPE_TACAN
                ["system"] = 4,         -- TACAN_TANKER (air-to-air TACAN)
                ["name"] = "Texaco",
                ["callsign"] = "TXC",
                ["frequency"] = 1188000000,  -- 1188 MHz (Channel 100X)
                ["channel"] = 100,
                ["modeChannel"] = "X",
                ["AA"] = true,          -- Air-to-Air mode
                ["bearing"] = true,
            },
        },
    },
},
```

> **Important:** Set `["system"] = 4` for `TACAN_TANKER` and `["AA"] = true` to enable air-to-air TACAN mode. Ground-based TACAN uses `["system"] = 3` and `["AA"] = false`.

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

The orbit task defines the tanker's refueling pattern. Use `Race-Track` pattern with `point` and `point2` defining the leg endpoints.

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
                            ["frequency"] = 1188000000,
                            ["channel"] = 100,
                            ["modeChannel"] = "X",
                            ["AA"] = true,
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

The KC-135MPRS is configured identically to the KC-135 but provides probe-and-drogue refueling for Navy/Marine aircraft.

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

The KC-130 operates at lower altitudes and speeds, suitable for tactical refueling of helicopters and slower aircraft.

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
                                            ["frequency"] = 1161000000,  -- Channel 73X
                                            ["channel"] = 73,
                                            ["modeChannel"] = "X",
                                            ["AA"] = true,
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

The S-3B Tanker provides organic tanking for carrier air wings and typically operates at lower altitudes closer to the carrier.

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
                                            ["frequency"] = 1178000000,  -- Channel 90X
                                            ["channel"] = 90,
                                            ["modeChannel"] = "X",
                                            ["AA"] = true,
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

| Callsign Name | Index [1] | Example |
|---------------|-----------|---------|
| Texaco | 1 | `[1]=1, [2]=1, [3]=1` → "Texaco 11" |
| Shell | 2 | `[1]=2, [2]=1, [3]=1` → "Shell 11" |
| Arco | 3 | `[1]=3, [2]=1, [3]=1` → "Arco 11" |

### Russian Callsigns (Numeric Format)

For REDFOR tankers, use a three-digit numeric callsign:

```lua
["callsign"] = 605,
```

## Common Tanker Frequencies

| Tanker Role | Frequency | Notes |
|-------------|-----------|-------|
| Primary Boom | 251.0 MHz | KC-135 |
| Primary Drogue | 264.0 MHz | KC-135MPRS/KC-130 |
| Alternate | 276.0 MHz | Secondary tanker |
| Carrier Tanker | 290.0 MHz | S-3B Viking |
| REDFOR | 132.0 MHz | IL-78M |

## Common TACAN Channels

| Tanker | Channel | Frequency (Hz) |
|--------|---------|----------------|
| Primary Boom | 100X | 1188000000 |
| Primary Drogue | 101X | 1189000000 |
| KC-130 | 73X | 1161000000 |
| S-3B | 75X | 1163000000 |
| REDFOR | 90X | 1178000000 |

## Unit Conversions

| Measurement | Conversion |
|-------------|------------|
| 25,000 ft | 7,620 m |
| 22,000 ft | 6,706 m |
| 20,000 ft | 6,096 m |
| 18,000 ft | 5,486 m |
| 15,000 ft | 4,572 m |
| 350 knots | 180 m/s |
| 300 knots | 154 m/s |
| 275 knots | 141 m/s |
| 250 knots | 128 m/s |
| 200 knots | 103 m/s |
| 50 nm | 92,600 m |
| 40 nm | 74,080 m |
| 30 nm | 55,560 m |

## Checklist

Before finalizing the tanker setup, verify:

- [ ] Aircraft type matches coalition (KC-135/KC-130/S-3B for Blue, IL-78M for Red)
- [ ] Aircraft type matches receiver refueling system (boom vs. drogue)
- [ ] Tanker task is enabled on first waypoint (`["id"] = "Tanker"`)
- [ ] TACAN beacon uses `["system"] = 4` (TACAN_TANKER) and `["AA"] = true`
- [ ] TACAN channel is unique and doesn't conflict with other beacons
- [ ] Radio frequency is set via `SetFrequency` action
- [ ] `SetUnlimitedFuel` is enabled to prevent fuel depletion
- [ ] Orbit pattern is `Race-Track` (not `Circle`)
- [ ] Racetrack leg length is at least 30-50 nm (55-93 km)
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

- Verify `["system"] = 4` (TACAN_TANKER) is set, not `3` (TACAN)
- Check that `["AA"] = true` for air-to-air TACAN mode
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