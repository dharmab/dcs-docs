# Artillery Battery Setup

This recipe describes how to create a dramatic artillery battery firing continuously at a distant point on the ground. The purpose is visual spectacle—muzzle flashes, smoke, and distant explosions—while providing gameplay opportunities for players hunting the battery by its fire signature.

> **Note:** All artillery units can run out of ammunition. Position ammunition carriers (M30 Cargo Carrier) within 100 meters of firing units to sustain prolonged bombardment. Without resupply, artillery will exhaust their ammunition and cease firing.

## Overview

An effective artillery spectacle requires:

- **Artillery Group** - Self-propelled howitzers or multiple rocket launchers
- **Ammunition Carriers** - Keep the guns supplied for continuous fire
- **FireAtPoint Task** - Direct fire at a distant, harmless location
- **Distant Target Point** - Far from any friendly forces to avoid fratricide
- **Multiple Groups (Optional)** - Stagger fire timing for varied visual effect

## Unit Type Strings

### Self-Propelled Howitzers

| Unit | Type ID | Caliber | Country | Notes |
|------|---------|---------|---------|-------|
| SPH M109 Paladin | `M-109` | 155mm | USA | Standard NATO SPH, dramatic muzzle flash |
| SPH 2S3 Akatsia | `SAU Akatsia` | 152mm | USSR | Soviet equivalent, heavy smoke |
| SPH 2S19 Msta | `SAU Msta` | 152mm | Russia | Modern SPH, rapid fire |
| SPH 2S1 Gvozdika | `SAU Gvozdika` | 122mm | USSR | Light SPH, high rate of fire |
| SPH Dana vz77 | `SpGH_Dana` | 152mm | Czechoslovakia | 8x8 wheeled, distinctive look |
| SPH T155 Firtina | `T155_Firtina` | 155mm | Turkey | Modern, very loud |
| PLZ-05 | `PLZ05` | 155mm | China | Modern Chinese SPH |
| SPM 2S9 Nona | `SAU 2-C9` | 120mm | USSR | Airborne mortar/howitzer |

### Multiple Rocket Launchers

MRLs fire in salvos rather than continuously, creating different visual effects—spectacular bursts followed by reload pauses.

| Unit | Type ID | Caliber | Country | Notes |
|------|---------|---------|---------|-------|
| MLRS BM-21 Grad | `Grad-URAL` | 122mm | USSR | 40 rockets, iconic Soviet MRL |
| MLRS BM-27 Uragan | `Uragan_BM-27` | 220mm | USSR | 16 rockets, heavier warheads |
| MLRS BM-30 Smerch | `Smerch` | 300mm | Russia | 12 rockets, massive explosions |
| MLRS BM-30 Smerch HE | `Smerch_HE` | 300mm | Russia | HE variant |
| MLRS M270 | `MLRS` | 227mm | USA | 12 rockets, NATO standard |
| MLRS TOS-1A | `CHAP_TOS1A` | 220mm | Russia | Thermobaric, spectacular fireballs |

### Towed Artillery and Mortars

Towed pieces lack the dramatic vehicle silhouette but can be effective for infantry support scenarios.

| Unit | Type ID | Caliber | Notes |
|------|---------|---------|-------|
| Mortar 2B11 | `2B11 mortar` | 120mm | Soviet heavy mortar, high rate of fire |
| L118 Light Gun | `L118_Unit` | 105mm | British towed howitzer |
| FH M2A1 | `M2A1-105` | 105mm | WWII American howitzer |

### Ammunition Carriers

| Unit | Type ID | Notes |
|------|---------|-------|
| Ammo M30 Cargo Carrier | `M30_CC` | Automatically reloads nearby units (within 100m) |

## Mission File Structure

Artillery units are placed in `coalition.[side].country[n].vehicle.group`. For varied fire patterns, use multiple groups with different target points.

```lua
["coalition"] = {
    ["red"] = {
        ["country"] = {
            [1] = {
                ["id"] = 0,  -- Russia
                ["name"] = "Russia",
                ["vehicle"] = {
                    ["group"] = {
                        [1] = { --[[ Artillery Battery 1 ]] },
                        [2] = { --[[ Artillery Battery 2 (optional) ]] },
                    },
                },
            },
        },
    },
},
```

## FireAtPoint Task Structure

The `FireAtPoint` task orders ground units to fire at a specific map location. For artillery spectacle, the target should be a distant, empty area—dramatic to watch but harmless.

```lua
["task"] = {
    ["id"] = "ComboTask",
    ["params"] = {
        ["tasks"] = {
            [1] = {
                ["enabled"] = true,
                ["auto"] = false,
                ["id"] = "FireAtPoint",
                ["number"] = 1,
                ["params"] = {
                    ["x"] = -95000,            -- Target X coordinate (distant)
                    ["y"] = 510000,            -- Target Y coordinate
                    ["radius"] = 200,          -- Dispersion radius (meters)
                    ["expendQty"] = 1000,      -- Rounds to fire (set high!)
                    ["expendQtyEnabled"] = true,
                    ["templateId"] = "",
                    ["zoneRadius"] = 200,
                },
            },
        },
    },
},
```

**Key Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `x` | number | Target X coordinate (meters) |
| `y` | number | Target Y coordinate (meters) |
| `radius` | number | Dispersion radius for impacts (meters, 100-500 typical) |
| `expendQty` | number | Number of rounds to fire—set very high (500-9999) for sustained fire |
| `expendQtyEnabled` | boolean | Whether to limit ammunition expenditure |

> **Tip:** For sustained bombardment, set `expendQty` to a very high number (1000+) and include ammunition carriers. The carriers will continuously resupply the guns.

## Target Point Selection

Choose a target point that is:

1. **Distant from the battery** - 5-20 km for realistic artillery ranges
2. **Visible to players** - Open terrain where explosions can be seen
3. **Away from friendly units** - Prevent accidental fratricide
4. **Dramatically placed** - Near a landmark, road junction, or objective area

### Example Target Scenarios

| Scenario | Target Placement | Effect |
|----------|------------------|--------|
| Suppression fire | Open field ahead of player advance | Distant rumble, smoke on horizon |
| Counter-battery target | Empty hillside | Players see impacts, search for source |
| Area denial | Road junction | Explosions block route, tension builder |
| Harassment fire | Near (not at) enemy airfield | Dramatic backdrop for takeoff/landing |

## Complete Example: Russian Artillery Battery

A 4-gun battery of 2S19 Msta howitzers with ammunition support, firing at a distant hillside.

```lua
[1] = {
    ["groupId"] = 500,
    ["name"] = "Red Artillery Battery",
    ["task"] = "Ground Nothing",
    ["start_time"] = 0,
    ["visible"] = false,
    ["hidden"] = false,
    ["x"] = -100000,
    ["y"] = 500000,
    ["units"] = {
        [1] = {
            ["unitId"] = 500,
            ["name"] = "Msta-1",
            ["type"] = "SAU Msta",
            ["skill"] = "High",
            ["x"] = -100000,
            ["y"] = 500000,
            ["heading"] = 0,             -- Facing north toward target
            ["playerCanDrive"] = false,
        },
        [2] = {
            ["unitId"] = 501,
            ["name"] = "Msta-2",
            ["type"] = "SAU Msta",
            ["skill"] = "High",
            ["x"] = -100030,
            ["y"] = 500000,
            ["heading"] = 0,
            ["playerCanDrive"] = false,
        },
        [3] = {
            ["unitId"] = 502,
            ["name"] = "Msta-3",
            ["type"] = "SAU Msta",
            ["skill"] = "High",
            ["x"] = -100060,
            ["y"] = 500000,
            ["heading"] = 0,
            ["playerCanDrive"] = false,
        },
        [4] = {
            ["unitId"] = 503,
            ["name"] = "Msta-4",
            ["type"] = "SAU Msta",
            ["skill"] = "High",
            ["x"] = -100090,
            ["y"] = 500000,
            ["heading"] = 0,
            ["playerCanDrive"] = false,
        },
        [5] = {
            ["unitId"] = 504,
            ["name"] = "Ammo-1",
            ["type"] = "M30_CC",
            ["skill"] = "Average",
            ["x"] = -100015,
            ["y"] = 499950,
            ["heading"] = 0,
            ["playerCanDrive"] = false,
        },
        [6] = {
            ["unitId"] = 505,
            ["name"] = "Ammo-2",
            ["type"] = "M30_CC",
            ["skill"] = "Average",
            ["x"] = -100075,
            ["y"] = 499950,
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
                ["action"] = "Off Road",
                ["speed"] = 0,
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
                                ["id"] = "FireAtPoint",
                                ["number"] = 1,
                                ["params"] = {
                                    ["x"] = -100000,
                                    ["y"] = 515000,     -- 15km north of battery
                                    ["radius"] = 200,
                                    ["expendQty"] = 9999,
                                    ["expendQtyEnabled"] = true,
                                    ["templateId"] = "",
                                    ["zoneRadius"] = 200,
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

## Complete Example: American MLRS Battery

An M270 MLRS battery for spectacular rocket salvos.

```lua
[1] = {
    ["groupId"] = 600,
    ["name"] = "Blue MLRS Battery",
    ["task"] = "Ground Nothing",
    ["start_time"] = 0,
    ["visible"] = false,
    ["hidden"] = false,
    ["x"] = -90000,
    ["y"] = 480000,
    ["units"] = {
        [1] = {
            ["unitId"] = 600,
            ["name"] = "MLRS-1",
            ["type"] = "MLRS",
            ["skill"] = "High",
            ["x"] = -90000,
            ["y"] = 480000,
            ["heading"] = 1.5708,        -- Facing east (π/2 radians)
            ["playerCanDrive"] = false,
        },
        [2] = {
            ["unitId"] = 601,
            ["name"] = "MLRS-2",
            ["type"] = "MLRS",
            ["skill"] = "High",
            ["x"] = -90050,
            ["y"] = 480000,
            ["heading"] = 1.5708,
            ["playerCanDrive"] = false,
        },
        [3] = {
            ["unitId"] = 602,
            ["name"] = "MLRS-Ammo",
            ["type"] = "M30_CC",
            ["skill"] = "Average",
            ["x"] = -90025,
            ["y"] = 479950,
            ["heading"] = 0,
            ["playerCanDrive"] = false,
        },
    },
    ["route"] = {
        ["points"] = {
            [1] = {
                ["x"] = -90000,
                ["y"] = 480000,
                ["alt"] = 0,
                ["alt_type"] = "BARO",
                ["type"] = "Turning Point",
                ["action"] = "Off Road",
                ["speed"] = 0,
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
                                ["id"] = "FireAtPoint",
                                ["number"] = 1,
                                ["params"] = {
                                    ["x"] = -70000,     -- 20km east of battery
                                    ["y"] = 480000,
                                    ["radius"] = 500,   -- Larger dispersion for rockets
                                    ["expendQty"] = 9999,
                                    ["expendQtyEnabled"] = true,
                                    ["templateId"] = "",
                                    ["zoneRadius"] = 500,
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

## Multiple Battery Coordination

For varied fire effects, use multiple groups firing at slightly different targets or with staggered start times.

### Staggered Start Times

Use `start_time` to delay groups, creating overlapping barrages:

```lua
-- Battery 1: Fires immediately
["start_time"] = 0,

-- Battery 2: Fires after 30 seconds
["start_time"] = 30,

-- Battery 3: Fires after 60 seconds  
["start_time"] = 60,
```

### Different Target Points

Multiple batteries can fire at different points within the same general area:

```lua
-- Battery 1 target
["x"] = -100000,
["y"] = 515000,

-- Battery 2 target (offset 500m)
["x"] = -100500,
["y"] = 515200,

-- Battery 3 target (offset 500m other direction)
["x"] = -99500,
["y"] = 514800,
```

## SEAD/DEAD Mission Integration

To create a "find and destroy the artillery" mission:

1. **Position the battery** in a concealed location (tree line, reverse slope, urban area)
2. **Give players observation clues** - Muzzle flashes visible from the air, especially at night
3. **Add light air defense** - Protect the battery with SHORAD (separate group!)
4. **Set high expendQty** - Ensure sustained fire so players have time to locate the source

### Adding SHORAD Protection

Place SHORAD in a **separate group** without FireAtPoint task so they engage aircraft normally:

```lua
[2] = {
    ["groupId"] = 510,
    ["name"] = "Battery SHORAD",
    ["task"] = "Ground Nothing",
    ["start_time"] = 0,
    ["visible"] = false,
    ["hidden"] = false,
    ["x"] = -100050,
    ["y"] = 500100,
    ["units"] = {
        [1] = {
            ["unitId"] = 510,
            ["name"] = "Tunguska-1",
            ["type"] = "2S6 Tunguska",
            ["skill"] = "High",
            ["x"] = -100050,
            ["y"] = 500100,
            ["heading"] = 0,
            ["playerCanDrive"] = false,
        },
        [2] = {
            ["unitId"] = 511,
            ["name"] = "Strela-1",
            ["type"] = "Strela-10M3",
            ["skill"] = "High",
            ["x"] = -99950,
            ["y"] = 500100,
            ["heading"] = 0,
            ["playerCanDrive"] = false,
        },
    },
    ["route"] = {
        ["points"] = {
            [1] = {
                ["x"] = -100050,
                ["y"] = 500100,
                ["alt"] = 0,
                ["alt_type"] = "BARO",
                ["type"] = "Turning Point",
                ["action"] = "Off Road",
                ["speed"] = 0,
                ["speed_locked"] = true,
                ["ETA"] = 0,
                ["ETA_locked"] = true,
                ["task"] = {
                    ["id"] = "ComboTask",
                    ["params"] = {
                        ["tasks"] = {},   -- No tasks! SHORAD engages automatically
                    },
                },
            },
        },
    },
},
```

## Visual Layout

```
    Target Area (15km north)
    ┌─────────────────────────────────────┐
    │                                     │
    │      ╳ ╳ ╳   Impact points          │  Y = 515000
    │        (radius = 200m)              │
    │                                     │
    └─────────────────────────────────────┘
              ↑
              │  Fire direction (15km)
              │
              │
    ┌─────────────────────────────────────┐
    │  [Tunguska]       [Strela]          │  Y = 500100 (SHORAD - separate group)
    │                                     │
    │  [Msta] [Msta] [Msta] [Msta]        │  Y = 500000 (artillery battery)
    │     [Ammo]        [Ammo]            │  Y = 499950 (ammo carriers)
    └─────────────────────────────────────┘
    
    Artillery Position (Y = 500000)
    X = -100000 to -100090 (30m spacing)
```

## Night Operations

Artillery is particularly dramatic at night:

- **Muzzle flashes** illuminate the battery position
- **Tracer rounds** from AAA create light trails
- **Distant explosions** produce orange glows on the horizon
- **Players can locate batteries** by observing fire signatures

For night missions, consider adding illumination via:

- Flares from aircraft
- Searchlight units near the battery
- Fires or explosions in the target area

## Checklist

Before finalizing your artillery battery:

- [ ] Artillery units have unique `unitId` values
- [ ] All groups have unique `groupId` values
- [ ] Ammunition carriers positioned within 100m of guns
- [ ] Target point is distant (5-20km for howitzers, 20-70km for MLRS)
- [ ] Target point is in an empty area (no friendly units!)
- [ ] `expendQty` set very high (1000+) for sustained fire
- [ ] `speed` set to 0 to prevent movement
- [ ] SHORAD protection in **separate group** with no FireAtPoint task
- [ ] Artillery facing toward target (heading in radians)

## Troubleshooting

### Artillery Not Firing

- Verify the target point is within the weapon's range:
  - Howitzers: 15-30 km typical
  - MLRS: 20-70+ km depending on system
- Check that the FireAtPoint task is on waypoint 1
- Ensure units have ammunition (check ammo carrier proximity)
- Confirm the task is `enabled = true`

### Fire Stops After Initial Salvo

- Increase `expendQty` value (try 9999)
- Add more ammunition carriers
- Position ammo carriers closer to artillery (within 100m)
- For MLRS, reload time is significant—fire will resume after reloading

### Rounds Landing in Wrong Location

- Verify target coordinates are correct
- Check that target is within weapon range
- Increase `radius` for larger dispersion if impacts are too concentrated

### SHORAD Not Engaging Aircraft

- Ensure SHORAD is in a **separate group**
- Verify SHORAD group has no FireAtPoint task
- Check SHORAD has appropriate skill level

### Artillery Moving Instead of Firing

- Set `speed` to 0 in the waypoint
- Set `speed_locked` to true
- Ensure waypoint `type` is "Turning Point" with `action` "Off Road"

## See Also

- [Mission File Schema](../mission/mission-file-schema.md) - Complete schema reference
- [Ground Firefight Setup](ground-firefight.md) - Related ground combat spectacle
- [SAM Site Deployment](sam-site-setup.md) - Air defense setup guide
- [Ground Units Reference](../units/ground.md) - Complete ground unit database including artillery
- [AI Tasks Reference](../scripting/reference/ai/tasks.md) - Task definitions including FireAtPoint