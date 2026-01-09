# Convoy Route Setup

This recipe describes how to create ground vehicle convoys that travel along roads by directly editing the mission Lua file. Convoys can be used for supply lines, troop movements, or interdiction targets.

> **Note:** DCS ground AI pathfinding has known quirks. Vehicles may occasionally deviate from roads, especially at complex intersections or when resuming from a hold command. The techniques in this guide help minimize these issues but cannot eliminate them entirely.

## Overview

A functional convoy requires:

- **Single Group** - All convoy vehicles in one group for proper spacing and speed synchronization
- **Road Waypoints** - Waypoints with `action = "On Road"` to follow the road network
- **Consistent Speed** - The group moves at the slowest vehicle's maximum speed
- **Optional Loop** - `GoToWaypoint` task for continuous patrol routes

## Unit Type Strings

### Transport Trucks

| Unit | Type ID | Origin | Notes |
|------|---------|--------|-------|
| Ural-375 | `Ural-375` | Soviet/Russian | Standard cargo truck |
| Ural-4320-31 | `Ural-4320-31` | Russia | Armored cab variant |
| Ural-4320T | `Ural-4320T` | Russia | Tanker variant |
| KAMAZ-43101 | `KAMAZ Truck` | Russia | Modern cargo truck |
| GAZ-66 | `GAZ-66` | Soviet/Russian | Light truck |
| GAZ-3308 | `GAZ-3308` | Russia | Medium truck |
| KrAZ-6322 | `KrAZ6322` | Ukraine | Heavy truck |
| ZIL-131 | `ZIL-131 APA-80` | Soviet | Utility truck |
| M939 | `M 818` | USA | 5-ton cargo truck |
| M1083 MTV | `CHAP_M1083` | USA | Medium tactical vehicle |
| Bedford MWD | `Bedford_MWD` | UK | WWII-era truck |
| Opel Blitz | `Blitz_36-6700A` | Germany | WWII-era truck |
| GMC CCKW-353 | `CCKW_353` | USA | WWII-era truck |

### Fuel Trucks

| Unit | Type ID | Origin |
|------|---------|--------|
| ATZ-10 | `ATZ-10` | Soviet/Russian |
| ATMZ-5 | `ATMZ-5` | Soviet/Russian |
| ATZ-5 | `ATZ-5` | Soviet/Russian |
| M978 HEMTT | `M978 HEMTT Tanker` | USA |

### Armored Personnel Carriers

For escorted or combat convoys:

| Unit | Type ID | Origin | Notes |
|------|---------|--------|-------|
| BTR-80 | `BTR-80` | Soviet/Russian | 8x8 wheeled APC |
| BTR-82A | `BTR-82A` | Russia | Improved BTR with 30mm |
| BRDM-2 | `BRDM-2` | Soviet | Scout car |
| M1126 Stryker | `M1126 Stryker ICV` | USA | 8x8 wheeled IFV |
| LAV-25 | `LAV-25` | USA | 8x8 wheeled recon |
| M1043 HMMWV | `M1043 HMMWV Armament` | USA | Armed Humvee |
| Tigr | `Tigr_233036` | Russia | Light armored vehicle |

### Self-Propelled Air Defense

For convoy escort:

| Unit | Type ID | Notes |
|------|---------|-------|
| ZSU-23-4 Shilka | `ZSU-23-4 Shilka` | Radar-guided 23mm |
| SA-9 Gaskin | `Strela-1 9P31` | IR SAM on BRDM-2 |
| SA-13 Gopher | `Strela-10M3` | IR SAM on MT-LB |
| M163 Vulcan | `Vulcan` | 20mm Gatling |
| M1097 Avenger | `M1097 Avenger` | Stinger launcher on HMMWV |

## Mission File Structure

Ground units are placed in `coalition.[side].country[n].vehicle.group`. All vehicles in a convoy should be in the same group.

```lua
["coalition"] = {
    ["red"] = {
        ["country"] = {
            [1] = {
                ["id"] = 0,  -- Russia
                ["name"] = "Russia",
                ["vehicle"] = {
                    ["group"] = {
                        [1] = {
                            -- Convoy group definition here
                        },
                    },
                },
            },
        },
    },
},
```

## Waypoint Structure for Road Movement

Each waypoint uses `action = "On Road"` to follow the road network. The AI pathfinding calculates a route using available roads between waypoints.

```lua
["route"] = {
    ["points"] = {
        [1] = {
            ["x"] = -100000,
            ["y"] = 500000,
            ["alt"] = 0,
            ["alt_type"] = "BARO",
            ["type"] = "Turning Point",
            ["action"] = "On Road",        -- Follow roads
            ["speed"] = 10,                -- 10 m/s (~36 km/h)
            ["speed_locked"] = true,
            ["ETA"] = 0,
            ["ETA_locked"] = true,
            ["formation_template"] = "",
            ["task"] = {
                ["id"] = "ComboTask",
                ["params"] = {
                    ["tasks"] = {},
                },
            },
        },
        [2] = {
            ["x"] = -95000,
            ["y"] = 510000,
            ["alt"] = 0,
            ["alt_type"] = "BARO",
            ["type"] = "Turning Point",
            ["action"] = "On Road",
            ["speed"] = 10,
            ["speed_locked"] = true,
            ["ETA"] = 0,
            ["ETA_locked"] = false,
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
```

**Key Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `x`, `y` | number | Waypoint coordinates (should be near a road) |
| `action` | string | `"On Road"` for road following, `"Off Road"` for direct movement |
| `speed` | number | Speed in meters per second |
| `speed_locked` | boolean | When true, maintains specified speed |
| `formation_template` | string | Formation name (leave empty for default column) |

## Speed Recommendations

Ground unit speed affects both realism and AI behavior stability. Higher speeds can cause erratic pathfinding.

| Speed (m/s) | Speed (km/h) | Use Case |
|-------------|--------------|----------|
| 8-10 | 29-36 | Tactical convoy, realistic truck speeds |
| 12-15 | 43-54 | Fast road march |
| 5-8 | 18-29 | Slow, cautious movement through contested areas |
| 20+ | 72+ | Not recommended; causes pathfinding issues |

> **Tip:** Use slower speeds (8-10 m/s) for more reliable pathfinding behavior. Higher speeds can cause the lead vehicle to make erratic turns at intersections.

## Complete Example: Supply Convoy

This example creates a six-vehicle supply convoy with an escort.

```lua
[1] = {
    ["groupId"] = 500,
    ["name"] = "Supply Convoy Alpha",
    ["task"] = "Ground Nothing",
    ["start_time"] = 0,
    ["visible"] = false,
    ["hidden"] = false,
    ["x"] = -100000,
    ["y"] = 500000,
    ["units"] = {
        [1] = {
            ["unitId"] = 500,
            ["name"] = "Convoy-Lead",
            ["type"] = "BTR-80",
            ["skill"] = "Good",
            ["x"] = -100000,
            ["y"] = 500000,
            ["heading"] = 0.5,  -- Aligned with road
            ["playerCanDrive"] = false,
        },
        [2] = {
            ["unitId"] = 501,
            ["name"] = "Convoy-Truck-1",
            ["type"] = "Ural-375",
            ["skill"] = "Average",
            ["x"] = -100000,
            ["y"] = 499970,  -- 30m behind lead
            ["heading"] = 0.5,
            ["playerCanDrive"] = false,
        },
        [3] = {
            ["unitId"] = 502,
            ["name"] = "Convoy-Truck-2",
            ["type"] = "Ural-375",
            ["skill"] = "Average",
            ["x"] = -100000,
            ["y"] = 499940,  -- 30m spacing
            ["heading"] = 0.5,
            ["playerCanDrive"] = false,
        },
        [4] = {
            ["unitId"] = 503,
            ["name"] = "Convoy-Truck-3",
            ["type"] = "KAMAZ Truck",
            ["skill"] = "Average",
            ["x"] = -100000,
            ["y"] = 499910,
            ["heading"] = 0.5,
            ["playerCanDrive"] = false,
        },
        [5] = {
            ["unitId"] = 504,
            ["name"] = "Convoy-Fuel",
            ["type"] = "ATZ-10",
            ["skill"] = "Average",
            ["x"] = -100000,
            ["y"] = 499880,
            ["heading"] = 0.5,
            ["playerCanDrive"] = false,
        },
        [6] = {
            ["unitId"] = 505,
            ["name"] = "Convoy-Tail",
            ["type"] = "ZSU-23-4 Shilka",
            ["skill"] = "High",
            ["x"] = -100000,
            ["y"] = 499850,  -- Rear guard
            ["heading"] = 0.5,
            ["playerCanDrive"] = false,
        },
    },
    ["route"] = {
        ["points"] = {
            [1] = {
                ["x"] = -100000,
                ["y"] = 500000,
                ["alt"] = 0,
                ["alt_type"] = "BARO",
                ["type"] = "Turning Point",
                ["action"] = "On Road",
                ["speed"] = 10,
                ["speed_locked"] = true,
                ["ETA"] = 0,
                ["ETA_locked"] = true,
                ["formation_template"] = "",
                ["task"] = {
                    ["id"] = "ComboTask",
                    ["params"] = {
                        ["tasks"] = {},
                    },
                },
            },
            [2] = {
                ["x"] = -95000,
                ["y"] = 510000,
                ["alt"] = 0,
                ["alt_type"] = "BARO",
                ["type"] = "Turning Point",
                ["action"] = "On Road",
                ["speed"] = 10,
                ["speed_locked"] = true,
                ["ETA"] = 0,
                ["ETA_locked"] = false,
                ["formation_template"] = "",
                ["task"] = {
                    ["id"] = "ComboTask",
                    ["params"] = {
                        ["tasks"] = {},
                    },
                },
            },
            [3] = {
                ["x"] = -90000,
                ["y"] = 520000,
                ["alt"] = 0,
                ["alt_type"] = "BARO",
                ["type"] = "Turning Point",
                ["action"] = "On Road",
                ["speed"] = 10,
                ["speed_locked"] = true,
                ["ETA"] = 0,
                ["ETA_locked"] = false,
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

## Looping Convoy Route

To create a convoy that continuously patrols a route, add a `GoToWaypoint` task on the final waypoint that returns to an earlier waypoint.

```lua
-- On the final waypoint, add this task:
["task"] = {
    ["id"] = "ComboTask",
    ["params"] = {
        ["tasks"] = {
            [1] = {
                ["enabled"] = true,
                ["auto"] = false,
                ["id"] = "GoToWaypoint",
                ["number"] = 1,
                ["params"] = {
                    ["fromWaypointIndex"] = 4,   -- Current waypoint (1-indexed)
                    ["goToWaypointIndex"] = 1,   -- Return to first waypoint
                },
            },
        },
    },
},
```

**Complete looping example:**

```lua
[1] = {
    ["groupId"] = 510,
    ["name"] = "Patrol Convoy",
    ["task"] = "Ground Nothing",
    ["start_time"] = 0,
    ["visible"] = false,
    ["hidden"] = false,
    ["x"] = -100000,
    ["y"] = 500000,
    ["units"] = {
        [1] = {
            ["unitId"] = 510,
            ["name"] = "Patrol-1",
            ["type"] = "BTR-80",
            ["skill"] = "Good",
            ["x"] = -100000,
            ["y"] = 500000,
            ["heading"] = 0,
            ["playerCanDrive"] = false,
        },
        [2] = {
            ["unitId"] = 511,
            ["name"] = "Patrol-2",
            ["type"] = "BTR-80",
            ["skill"] = "Good",
            ["x"] = -100000,
            ["y"] = 499970,
            ["heading"] = 0,
            ["playerCanDrive"] = false,
        },
    },
    ["route"] = {
        ["points"] = {
            [1] = {
                ["x"] = -100000,
                ["y"] = 500000,
                ["alt"] = 0,
                ["alt_type"] = "BARO",
                ["type"] = "Turning Point",
                ["action"] = "On Road",
                ["speed"] = 8,
                ["speed_locked"] = true,
                ["ETA"] = 0,
                ["ETA_locked"] = true,
                ["formation_template"] = "",
                ["task"] = {
                    ["id"] = "ComboTask",
                    ["params"] = {
                        ["tasks"] = {},
                    },
                },
            },
            [2] = {
                ["x"] = -95000,
                ["y"] = 505000,
                ["alt"] = 0,
                ["alt_type"] = "BARO",
                ["type"] = "Turning Point",
                ["action"] = "On Road",
                ["speed"] = 8,
                ["speed_locked"] = true,
                ["ETA"] = 0,
                ["ETA_locked"] = false,
                ["formation_template"] = "",
                ["task"] = {
                    ["id"] = "ComboTask",
                    ["params"] = {
                        ["tasks"] = {},
                    },
                },
            },
            [3] = {
                ["x"] = -90000,
                ["y"] = 500000,
                ["alt"] = 0,
                ["alt_type"] = "BARO",
                ["type"] = "Turning Point",
                ["action"] = "On Road",
                ["speed"] = 8,
                ["speed_locked"] = true,
                ["ETA"] = 0,
                ["ETA_locked"] = false,
                ["formation_template"] = "",
                ["task"] = {
                    ["id"] = "ComboTask",
                    ["params"] = {
                        ["tasks"] = {},
                    },
                },
            },
            [4] = {
                ["x"] = -100000,
                ["y"] = 500000,
                ["alt"] = 0,
                ["alt_type"] = "BARO",
                ["type"] = "Turning Point",
                ["action"] = "On Road",
                ["speed"] = 8,
                ["speed_locked"] = true,
                ["ETA"] = 0,
                ["ETA_locked"] = false,
                ["formation_template"] = "",
                ["task"] = {
                    ["id"] = "ComboTask",
                    ["params"] = {
                        ["tasks"] = {
                            [1] = {
                                ["enabled"] = true,
                                ["auto"] = false,
                                ["id"] = "GoToWaypoint",
                                ["number"] = 1,
                                ["params"] = {
                                    ["fromWaypointIndex"] = 4,
                                    ["goToWaypointIndex"] = 1,
                                },
                            },
                        },
                    },
                },
            },
        },
    },
},
```

## Delayed Start

To start a convoy at a specific mission time, set the `start_time` field to the number of seconds after mission start:

```lua
["start_time"] = 600,  -- Start 10 minutes into mission
```

For late activation via trigger, set:

```lua
["lateActivation"] = true,
```

Then activate the group using a trigger action or SSE script with `Group.getByName("name"):activate()`.

## Known Issues and Workarounds

### Waypoint 1 Skipped on Some Maps

On some maps (notably Caucasus), ground units with both waypoints set to "On Road" may skip waypoint 1 and proceed directly to waypoint 2.

**Workaround:** Place the first waypoint at the exact spawn location, or add a short "Off Road" segment at the start before transitioning to road movement.

### Erratic Lead Vehicle Behavior

The lead vehicle may make unexpected turns at intersections, especially at higher speeds.

**Workaround:** Reduce convoy speed to 8-10 m/s. Adding an intermediate waypoint at lower speed (5 m/s) before complex intersections can help stabilize pathfinding.

### Vehicles Stacking After Hold Command

When a convoy is stopped with a Hold command and then resumed, vehicles may attempt to close formation by cutting across terrain.

**Workaround:** Avoid using Hold/Resume commands on convoys. Instead, design routes that don't require stopping, or use triggers to spawn new convoy groups at different times.

### Off-Road Deviation

Vehicles may leave the road at certain intersections or when pathfinding fails.

**Workaround:** Place waypoints directly on road intersections rather than on straight road segments. Test routes in-game before finalizing the mission.

### Speed Reduction After Resume

Convoys that are stopped and resumed may move at reduced speed.

**Workaround:** Avoid stopping convoys mid-route. If you need timed arrivals, use `start_time` or late activation instead.

## Placement Tips

### Vehicle Spacing

When placing vehicles in the Mission Editor or Lua file, use consistent spacing in the direction of travel:

- **30-50 meters** for standard road convoys
- **50-100 meters** for tactical spacing in combat zones
- **15-30 meters** for dense traffic scenarios

### Initial Heading

Set the `heading` field to align with the road direction at the spawn point. Misaligned headings cause vehicles to turn in place before moving, which can trigger pathfinding issues.

```lua
["heading"] = 0.5,  -- Radians; 0 = North, π/2 = East, π = South
```

### Waypoint Placement

- Place waypoints **on or very near roads** for reliable pathfinding
- At intersections, place waypoints **at the center** of the intersection
- Avoid placing waypoints on bridges or tunnels where pathfinding is unreliable
- For long routes, add intermediate waypoints every 5-10 km to stabilize the path

## Convoy Composition Guidelines

### Supply Convoy (6-10 vehicles)

```
[Lead Scout] → [Cargo Trucks x4-6] → [Fuel Truck] → [Tail Guard]
```

- Lead: BTR-80 or BRDM-2
- Middle: Mix of Ural-375, KAMAZ
- Fuel: ATZ-10 for flammable target
- Tail: ZSU-23-4 for air defense

### Armored Column (4-8 vehicles)

```
[Recon] → [IFVs x2-4] → [Command] → [Air Defense]
```

- Lead: BRDM-2
- Middle: BMP-2 or BTR-82A
- Command: Tigr or BTR-80
- Tail: SA-9 or SA-13

### Logistics Convoy (8-12 vehicles)

```
[Escort] → [Cargo x4] → [Escort] → [Fuel x2] → [Cargo x4] → [Escort]
```

Intersperse escorts throughout long convoys for protection.

## Checklist

Before finalizing your convoy setup:

- [ ] All vehicles in the same group
- [ ] Unique `groupId` and `unitId` values
- [ ] Unique unit names
- [ ] All waypoints have `action = "On Road"`
- [ ] Speed set to 10 m/s or less for reliability
- [ ] Vehicle headings aligned with road direction
- [ ] Spawn point located on or near a road
- [ ] Waypoints placed on roads or at intersections
- [ ] For looping routes, `GoToWaypoint` task on final waypoint

## Troubleshooting

### Convoy Not Moving

- Verify the group is not set to late activation without a trigger
- Check that `start_time` has passed
- Ensure waypoint 1 speed is greater than 0
- Confirm waypoint coordinates are valid (on the map)

### Vehicles Colliding

- Increase initial spacing between vehicles
- Reduce convoy speed
- Ensure all vehicles are in the same group (separate groups may have different speeds)

### Convoy Goes Off-Road

- Place waypoints closer to road centerlines
- Add intermediate waypoints at problem intersections
- Reduce speed at complex junctions
- Test route in Mission Editor preview

### Convoy Stops Unexpectedly

- Check for obstacles or destroyed vehicles blocking the road
- Verify waypoints don't cross impassable terrain
- Ensure the route doesn't pass through restricted zones

### Loop Not Working

- Verify `GoToWaypoint` task is on the correct waypoint
- Check that `fromWaypointIndex` matches the current waypoint number
- Ensure `goToWaypointIndex` points to a valid waypoint (1-indexed)

## See Also

- [Mission File Schema](../mission/mission-file-schema.md) - Complete schema reference
- [Ground Units Reference](../units/ground.md) - Complete ground unit database
- [AI Tasks Reference](../scripting/reference/ai/tasks.md) - Task definitions including GoToWaypoint
- [Mission Editor Guide](../mission-editor.md) - GUI-based mission editing

---

## Sources

This recipe incorporates information from DCS community discussions:

- [How to loop waypoints for AI ships/land](https://forum.dcs.world/topic/222534-how-to-loop-the-waypoints-of-ai-ships-land/)
- [Combined Arms - WW2 Assets Truck Convoy](https://forum.dcs.world/topic/326033-combined-arms-ww2-assets-truck-convoy-how/)
- [Getting units to stay on the road](https://forum.dcs.world/topic/283614-getting-units-to-stay-on-the-road/)
- [AI Ground Unit 'On Road' Pathing](https://forum.dcs.world/topic/315182-28-ai-ground-unit-on-road-pathing-completely-broken-even-worse-if-you-use-holdgo-on-ground-units/)
- [Ground units "on road" ignoring waypoint 1](https://forum.dcs.world/topic/356643-ground-units-on-road-caucasus-map-ignoring-waypoint-1/)
