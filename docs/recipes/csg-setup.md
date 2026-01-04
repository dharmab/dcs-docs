# Carrier Strike Group Setup

This recipe describes how to create a U.S. Navy Carrier Strike Group (CSG) by directly editing the mission Lua file. The CSG will feature the CVN-74 John C. Stennis as the centerpiece, escorted by Ticonderoga-class cruisers, Arleigh Burke-class destroyers, and a plane guard rescue helicopter.

## Overview

A typical CSG consists of:

- **1 Aircraft Carrier** - CVN-74 John C. Stennis (`Stennis`)
- **1-2 Ticonderoga-class Cruisers** - CG Ticonderoga (`TICONDEROG`)
- **2-3 Arleigh Burke-class Destroyers** - DDG Arleigh Burke IIa (`USS_Arleigh_Burke_IIa`)
- **1 Rescue Helicopter** - UH-60A Black Hawk (`UH-60A`) with "Golden Angels" livery

The carrier should be at the formation center with escorts positioned 5-12 nautical miles (9-22 km) around it.

## Unit Type Strings

| Unit | Type String | Livery |
|------|-------------|--------|
| CVN-74 John C. Stennis | `Stennis` | - |
| CG Ticonderoga | `TICONDEROG` | - |
| DDG Arleigh Burke IIa | `USS_Arleigh_Burke_IIa` | - |
| UH-60A Black Hawk | `UH-60A` | `Golden Angels` |

> **Note:** The Stennis is recommended because it is freely available to all DCS users without requiring the Supercarrier DLC.

## Wind and Course Calculation

Aircraft carriers must steam into the wind during flight operations to maximize wind over deck (WOD) for safe launch and recovery. The effective WOD should be approximately **30 knots (15.4 m/s)**.

### Formula

```
WOD = Ship Speed + (Wind Speed × cos(Wind Direction - Ship Heading))
```

For optimal operations, the carrier should sail **directly into the wind**, meaning:

```
Ship Heading = Wind Direction (where wind comes FROM)
```

### Example Calculation

If mission wind is set to:
- Wind speed: 10 m/s (19.4 knots)
- Wind direction: 045° (wind coming FROM northeast)

Required ship speed:
- Target WOD: 30 knots = 15.4 m/s
- Ship speed needed: 15.4 - 10 = 5.4 m/s (10.5 knots)
- Ship heading: 045° (into the wind)

## Mission File Structure

### Weather Configuration

Set a nonzero wind at ground level. The `dir` field indicates the direction wind is coming **from** in degrees.

```lua
["weather"] = {
    ["atmosphere_type"] = 0,
    ["wind"] = {
        ["atGround"] = {
            ["speed"] = 10,  -- m/s (approximately 19.4 knots)
            ["dir"] = 45,    -- Wind FROM 045 degrees (northeast)
        },
        ["at2000"] = {
            ["speed"] = 12,
            ["dir"] = 50,
        },
        ["at8000"] = {
            ["speed"] = 15,
            ["dir"] = 55,
        },
    },
    -- other weather fields...
},
```

### Ship Group Structure

Ships are placed in `coalition.[side].country[n].ship.group`. Each ship group contains units and a route.

```lua
["coalition"] = {
    ["blue"] = {
        ["country"] = {
            [1] = {
                ["id"] = 2,  -- USA
                ["name"] = "USA",
                ["ship"] = {
                    ["group"] = {
                        [1] = {
                            -- Carrier Strike Group definition here
                        },
                    },
                },
            },
        },
    },
},
```

## Complete CSG Group Definition

The following example places a CSG with the carrier at position (x, y) with escorts surrounding it. All ships share the same route to maintain formation.

```lua
[1] = {
    ["groupId"] = 100,
    ["name"] = "CVN-74 Stennis CSG",
    ["hidden"] = false,
    ["units"] = {
        -- Carrier (center of formation)
        [1] = {
            ["unitId"] = 101,
            ["name"] = "CVN-74 Stennis",
            ["type"] = "Stennis",
            ["skill"] = "Excellent",
            ["x"] = -200000,     -- Center position X
            ["y"] = 500000,      -- Center position Y
            ["heading"] = 0.785, -- Heading in radians (45 degrees into wind)
        },
        -- Ticonderoga #1 (port forward, ~8 nm / 15 km)
        [2] = {
            ["unitId"] = 102,
            ["name"] = "CG-47 Ticonderoga",
            ["type"] = "TICONDEROG",
            ["skill"] = "High",
            ["x"] = -200000 + 10600,   -- ~7 nm forward
            ["y"] = 500000 - 10600,    -- ~7 nm port
            ["heading"] = 0.785,
        },
        -- Ticonderoga #2 (starboard forward, ~8 nm / 15 km)
        [3] = {
            ["unitId"] = 103,
            ["name"] = "CG-48 Yorktown",
            ["type"] = "TICONDEROG",
            ["skill"] = "High",
            ["x"] = -200000 + 10600,   -- ~7 nm forward
            ["y"] = 500000 + 10600,    -- ~7 nm starboard
            ["heading"] = 0.785,
        },
        -- Arleigh Burke #1 (port beam, ~6 nm / 11 km)
        [4] = {
            ["unitId"] = 104,
            ["name"] = "DDG-51 Arleigh Burke",
            ["type"] = "USS_Arleigh_Burke_IIa",
            ["skill"] = "High",
            ["x"] = -200000,
            ["y"] = 500000 - 11000,    -- ~6 nm port
            ["heading"] = 0.785,
        },
        -- Arleigh Burke #2 (starboard beam, ~6 nm / 11 km)
        [5] = {
            ["unitId"] = 105,
            ["name"] = "DDG-52 Barry",
            ["type"] = "USS_Arleigh_Burke_IIa",
            ["skill"] = "High",
            ["x"] = -200000,
            ["y"] = 500000 + 11000,    -- ~6 nm starboard
            ["heading"] = 0.785,
        },
        -- Arleigh Burke #3 (astern, ~10 nm / 18.5 km)
        [6] = {
            ["unitId"] = 106,
            ["name"] = "DDG-53 John Paul Jones",
            ["type"] = "USS_Arleigh_Burke_IIa",
            ["skill"] = "High",
            ["x"] = -200000 - 18500,   -- ~10 nm astern
            ["y"] = 500000,
            ["heading"] = 0.785,
        },
    },
    ["x"] = -200000,
    ["y"] = 500000,
    ["route"] = {
        ["routeRelativeTOT"] = true,
        ["points"] = {
            -- See route section below
        },
    },
},
```

## Route Configuration

The carrier group needs a looped route with the longest leg oriented into the wind for flight operations. The route should form a racetrack or box pattern.

### Waypoint Structure

```lua
["route"] = {
    ["routeRelativeTOT"] = true,
    ["points"] = {
        -- Waypoint 1: Starting position
        [1] = {
            ["alt"] = 0,
            ["type"] = "Turning Point",
            ["action"] = "Turning Point",
            ["x"] = -200000,
            ["y"] = 500000,
            ["speed"] = 5.4,              -- m/s (~10.5 knots to achieve 30kt WOD)
            ["speed_locked"] = true,
            ["ETA"] = 0,
            ["ETA_locked"] = true,
            ["task"] = {
                ["id"] = "ComboTask",
                ["params"] = {
                    ["tasks"] = {
                        -- TACAN, ICLS, Frequency tasks here (see below)
                    },
                },
            },
        },
        -- Waypoint 2: End of into-wind leg (~50 nm / 92 km)
        [2] = {
            ["alt"] = 0,
            ["type"] = "Turning Point",
            ["action"] = "Turning Point",
            ["x"] = -200000 + 65000,      -- 50 nm into the wind (NE)
            ["y"] = 500000 + 65000,
            ["speed"] = 5.4,
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
        -- Waypoint 3: Turn point (crosswind leg)
        [3] = {
            ["alt"] = 0,
            ["type"] = "Turning Point",
            ["action"] = "Turning Point",
            ["x"] = -200000 + 65000 + 18500,  -- 10 nm crosswind
            ["y"] = 500000 + 65000 - 18500,
            ["speed"] = 7.7,              -- Faster during non-ops (~15 knots)
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
        -- Waypoint 4: Return leg start
        [4] = {
            ["alt"] = 0,
            ["type"] = "Turning Point",
            ["action"] = "Turning Point",
            ["x"] = -200000 + 18500,
            ["y"] = 500000 - 18500,
            ["speed"] = 7.7,
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
        -- Waypoint 5: Close the loop (back to start area)
        [5] = {
            ["alt"] = 0,
            ["type"] = "Turning Point",
            ["action"] = "Turning Point",
            ["x"] = -200000,
            ["y"] = 500000,
            ["speed"] = 5.4,
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

## Carrier Systems Configuration

Configure TACAN, ICLS, and radio frequency as waypoint tasks on the first waypoint.

### TACAN Configuration

The TACAN beacon allows aircraft to navigate to the carrier. Use channel **71X** (matching CVN-71's convention, easily memorable).

TACAN frequency calculation for channel 71X:
- X-mode channels 70-126: frequency = 1088 + channel = 1088 + 71 = **1159 MHz** = **1159000000 Hz**

```lua
{
    ["enabled"] = true,
    ["auto"] = false,
    ["id"] = "WrappedAction",
    ["number"] = 1,
    ["params"] = {
        ["action"] = {
            ["id"] = "ActivateBeacon",
            ["params"] = {
                ["type"] = 4,           -- BEACON_TYPE_TACAN
                ["system"] = 3,         -- TACAN system
                ["name"] = "Stennis",
                ["callsign"] = "STN",
                ["frequency"] = 1159000000,  -- 1159 MHz (Channel 71X)
                ["channel"] = 71,
                ["modeChannel"] = "X",
                ["AA"] = false,
                ["bearing"] = true,
            },
        },
    },
},
```

### ICLS Configuration

The Instrument Carrier Landing System provides glideslope and localizer guidance. Use channel **11**.

```lua
{
    ["enabled"] = true,
    ["auto"] = false,
    ["id"] = "WrappedAction",
    ["number"] = 2,
    ["params"] = {
        ["action"] = {
            ["id"] = "ActivateICLS",
            ["params"] = {
                ["type"] = 131584,    -- ICLS type constant
                ["channel"] = 11,
            },
        },
    },
},
```

### Radio Frequency Configuration

Set an easily tuned AM frequency for ATC communications. **127.5 MHz** is a common, easy-to-remember frequency.

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
                ["frequency"] = 127500000,  -- 127.5 MHz
                ["modulation"] = 0,          -- 0 = AM
                ["power"] = 10,
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
                ["auto"] = false,
                ["id"] = "WrappedAction",
                ["number"] = 1,
                ["params"] = {
                    ["action"] = {
                        ["id"] = "ActivateBeacon",
                        ["params"] = {
                            ["type"] = 4,
                            ["system"] = 3,
                            ["name"] = "Stennis",
                            ["callsign"] = "STN",
                            ["frequency"] = 1159000000,
                            ["channel"] = 71,
                            ["modeChannel"] = "X",
                            ["AA"] = false,
                            ["bearing"] = true,
                        },
                    },
                },
            },
            [2] = {
                ["enabled"] = true,
                ["auto"] = false,
                ["id"] = "WrappedAction",
                ["number"] = 2,
                ["params"] = {
                    ["action"] = {
                        ["id"] = "ActivateICLS",
                        ["params"] = {
                            ["type"] = 131584,
                            ["channel"] = 11,
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
                            ["frequency"] = 127500000,
                            ["modulation"] = 0,
                            ["power"] = 10,
                        },
                    },
                },
            },
        },
    },
},
```

## Formation Geometry

The following diagram illustrates escort positioning relative to the carrier:

```
                    Wind Direction (FROM)
                           ↓
                         045°
                           
        CG Yorktown                    CG Ticonderoga
            ●                               ●
             \                             /
              \         7 nm             /
               \                        /
                \                      /
    DDG Barry    \                    /    DDG Arleigh Burke
        ●─────────●──────────────────●─────────●
        6 nm      │     STENNIS      │      6 nm
                  │        ▲         │
                  │    (center)      │
                  │                  │
                  │                  │
                  │                  │
                  │      10 nm       │
                  │                  │
                  ●                  
           DDG John Paul Jones
               (astern)
```

## Distance Conversions

| Distance | Nautical Miles | Meters |
|----------|----------------|--------|
| Close escort | 5 nm | 9,260 m |
| Standard | 7 nm | 12,964 m |
| Wide | 10 nm | 18,520 m |
| Maximum | 12 nm | 22,224 m |

## Speed Conversions

| Speed | Knots | m/s |
|-------|-------|-----|
| Minimum steerage | 5 kt | 2.6 m/s |
| Cruise | 12 kt | 6.2 m/s |
| Flight ops | 15 kt | 7.7 m/s |
| High speed | 20 kt | 10.3 m/s |
| Flank | 30 kt | 15.4 m/s |

## Rescue Helicopter (Plane Guard)

During flight operations, a rescue helicopter maintains station on the carrier's port side to recover aircrew in case of a mishap. Per NAVAIR 00-80T-105, during recovery of aircraft with forward-firing ordnance, the plane guard helicopter shall not be positioned on the starboard side from 360° to 090° relative bearing within 5 nm of the carrier.

### Helicopter Position

The rescue helicopter should maintain:
- **Altitude:** 70 meters (230 feet)
- **Offset X:** 200 meters ahead of the carrier (in direction of travel)
- **Offset Z:** -200 meters (port side, negative value)

### Following the Carrier

DCS does not have a native "follow ship" task for helicopters. To make the rescue helicopter follow the carrier, create a helicopter group with waypoints that mirror the carrier's route, offset to the port side. The helicopter must fly at the same speed as the carrier group.

Since the helicopter will be airborne for the duration of flight operations (potentially hours), it must have **unlimited fuel** enabled via a `SetUnlimitedFuel` command on its first waypoint.

### Helicopter Group Definition

Place the helicopter group in `coalition.[side].country[n].helicopter.group`:

```lua
[1] = {
    ["groupId"] = 200,
    ["name"] = "Plane Guard",
    ["task"] = "Transport",
    ["hidden"] = false,
    ["units"] = {
        [1] = {
            ["unitId"] = 201,
            ["name"] = "Angel 1",
            ["type"] = "UH-60A",
            ["skill"] = "Excellent",
            ["x"] = -200000 + 141,         -- 200m ahead (at 45° heading)
            ["y"] = 500000 - 341,          -- 200m port + 200m ahead offset
            ["alt"] = 70,
            ["alt_type"] = "RADIO",
            ["speed"] = 5.4,               -- Match carrier speed
            ["heading"] = 0.785,           -- Match carrier heading (45°)
            ["livery_id"] = "Golden Angels",
            ["psi"] = -0.785,
            ["onboard_num"] = "001",
            ["callsign"] = {
                [1] = 9,                   -- Callsign group (9 = custom)
                [2] = 1,
                [3] = 1,
                ["name"] = "Angel11",
            },
            ["payload"] = {
                ["pylons"] = {},
                ["fuel"] = "1100",
                ["flare"] = 30,
                ["chaff"] = 30,
                ["gun"] = 100,
            },
        },
    },
    ["x"] = -200000 + 141,
    ["y"] = 500000 - 341,
    ["communication"] = true,
    ["frequency"] = 127.5,
    ["modulation"] = 0,
    ["route"] = {
        ["routeRelativeTOT"] = true,
        ["points"] = {
            -- Waypoints mirror carrier route with port offset
        },
    },
},
```

### Helicopter Route Waypoints

Each waypoint must mirror the carrier's waypoints with the port-side offset applied. The offset depends on the carrier's heading at each waypoint.

For a carrier heading of 045° (northeast into the wind), the port offset of 200m translates to:
- X offset: +141m (200 × cos(45°) for ahead) + (-141m for port) = 0m net, but we want ahead+port
- Y offset: +141m (200 × sin(45°) for ahead) + (-141m for port side)

**Offset Calculation Formula:**

For a given carrier waypoint at (x, y) with heading θ (radians), and desired offset of `ahead` meters forward and `port` meters to port:

```
helo_x = carrier_x + (ahead × cos(θ)) - (port × sin(θ))
helo_y = carrier_y + (ahead × sin(θ)) + (port × cos(θ))
```

For 200m ahead and 200m port at 45° heading:
```
helo_x = carrier_x + (200 × 0.707) - (200 × 0.707) = carrier_x
helo_y = carrier_y + (200 × 0.707) + (200 × 0.707) = carrier_y + 283
```

Wait—port side at 045° heading means we go to the aircraft's left, which is northwest. Let's recalculate:

At heading 045°:
- Forward vector: (cos(45°), sin(45°)) = (0.707, 0.707)
- Port vector (90° left of heading): (cos(135°), sin(135°)) = (-0.707, 0.707)

For 200m ahead and 200m port:
```
helo_x = carrier_x + 200×0.707 + 200×(-0.707) = carrier_x
helo_y = carrier_y + 200×0.707 + 200×0.707 = carrier_y + 283
```

### Complete Helicopter Waypoint Example

```lua
["route"] = {
    ["routeRelativeTOT"] = true,
    ["points"] = {
        -- Waypoint 1: Starting position (port of carrier WP1)
        [1] = {
            ["alt"] = 70,
            ["alt_type"] = "RADIO",
            ["type"] = "Turning Point",
            ["action"] = "Turning Point",
            ["x"] = -200000,              -- Same X (offset cancels out at 45°)
            ["y"] = 500000 + 283,         -- 283m port-forward offset
            ["speed"] = 5.4,
            ["speed_locked"] = true,
            ["ETA"] = 0,
            ["ETA_locked"] = true,
            ["task"] = {
                ["id"] = "ComboTask",
                ["params"] = {
                    ["tasks"] = {
                        [1] = {
                            ["enabled"] = true,
                            ["auto"] = false,
                            ["id"] = "WrappedAction",
                            ["number"] = 1,
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
        -- Waypoint 2: End of into-wind leg (port of carrier WP2)
        [2] = {
            ["alt"] = 70,
            ["alt_type"] = "RADIO",
            ["type"] = "Turning Point",
            ["action"] = "Turning Point",
            ["x"] = -200000 + 65000,
            ["y"] = 500000 + 65000 + 283,
            ["speed"] = 5.4,
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
        -- Continue mirroring all carrier waypoints with offset...
        -- Waypoint 3, 4, 5 follow the same pattern
    },
},
```

### Alternative: MOOSE Framework

For dynamic rescue helicopter behavior that automatically follows the carrier regardless of its movements, consider using the MOOSE framework's `RESCUEHELO` class. This Lua script can be loaded via a mission trigger and provides:

- Automatic station-keeping relative to the carrier
- Configurable altitude and offset
- Automatic return to station after displacement

See: [MOOSE RESCUEHELO Documentation](https://flightcontrol-master.github.io/MOOSE_DOCS/Documentation/Ops.RescueHelo.html)

## Checklist

Before finalizing the CSG setup, verify:

- [ ] Wind `atGround` speed is nonzero (recommended: 8-15 m/s)
- [ ] Carrier heading matches wind direction (sailing INTO the wind)
- [ ] Ship speed + wind speed ≈ 30 knots (15.4 m/s) for WOD
- [ ] TACAN activated with channel 71X, frequency 1159000000 Hz
- [ ] ICLS activated with channel 11
- [ ] Radio frequency set to easily tuned AM frequency (e.g., 127.5 MHz = 127500000 Hz)
- [ ] Route forms a closed loop with longest leg into the wind
- [ ] All escort ships share the same route waypoints
- [ ] Unit positions place escorts 5-12 nm from carrier
- [ ] Rescue helicopter waypoints mirror carrier route with port-side offset
- [ ] Rescue helicopter speed matches carrier speed exactly
- [ ] Rescue helicopter has `SetUnlimitedFuel` command on first waypoint
- [ ] Rescue helicopter uses `Golden Angels` livery
- [ ] All `groupId` and `unitId` values are unique within the mission

## See Also

- [Mission File Schema](../mission/mission-file-schema.md) - Complete mission file reference
- [Sea Units](../units/sea.md) - Naval unit type strings and capabilities
- [Helicopters](../units/helicopters.md) - Helicopter unit type strings
- [AI Commands](../scripting/reference/ai/commands.md) - ActivateBeacon, ActivateICLS reference
- [AI Enums](../scripting/reference/enums/ai.md) - Beacon type and system constants
- [MOOSE RESCUEHELO](https://flightcontrol-master.github.io/MOOSE_DOCS/Documentation/Ops.RescueHelo.html) - Dynamic rescue helicopter scripting