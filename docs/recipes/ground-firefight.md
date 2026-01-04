# Ground Firefight Setup

This recipe describes how to create a dramatic front-line firefight between ground AI forces by directly editing the mission Lua file. The groups fire at points near each other rather than directly engaging, creating a sustained visual spectacle without immediate destruction.

> **Note:** All ground units can run out of ammunition. Position ammunition carriers (M30 Cargo Carrier) within 100 meters of any units you want to sustain prolonged fire. Without resupply, units will exhaust their ammunition and cease firing.

## Overview

A dramatic firefight requires:

- **Multiple Firing Groups** - AI tasks are set at the group level, so use separate small groups for different FireAtPoint targets
- **Ammunition Carriers** - Keep firing units supplied (include one per firing group)
- **FireAtPoint Tasks** - Direct fire at coordinates near (not at) enemies
- **Immortal and Invisible Settings** - Friendly forces persist and aren't targeted by enemy SHORAD
- **Separate Air Defense Group** - SHORAD units in their own group with no FireAtPoint task, so they engage aircraft

## Unit Type Strings

### Direct-Fire Units (Front-Line Appropriate)

| Unit | Type ID | Role | Notes |
|------|---------|------|-------|
| T-72B3 | `T-72B3` | Main battle tank | Russian modern MBT |
| T-80U | `T-80UD` | Main battle tank | Russian MBT |
| T-55 | `T-55` | Main battle tank | Older Soviet MBT |
| BMP-2 | `BMP-2` | Infantry fighting vehicle | 30mm autocannon |
| BMP-3 | `BMP-3` | Infantry fighting vehicle | 100mm gun + 30mm |
| BTR-80 | `BTR-80` | Armored personnel carrier | 14.5mm MG |
| M1A2 Abrams | `M-1 Abrams` | Main battle tank | NATO MBT |
| M2A2 Bradley | `M-2 Bradley` | Infantry fighting vehicle | 25mm chain gun |
| M1126 Stryker | `M1126 Stryker ICV` | Infantry carrier | .50 cal MG |
| Leopard 2 | `Leopard-2` | Main battle tank | German MBT |
| ZSU-23-4 Shilka | `ZSU-23-4 Shilka` | SPAAG | High rate of fire, tracers |
| M163 Vulcan | `Vulcan` | SPAAG | 20mm Gatling, spectacular tracers |

### Ammunition Carriers

| Unit | Type ID | Notes |
|------|---------|-------|
| Ammo M30 Cargo Carrier | `M30_CC` | Automatically reloads nearby units |

### Short-Range Air Defense

Early Cold War and simpler systems are often more fun to fight against—they're dangerous but defeatable with good tactics.

**Gun-Based (No Missiles)**

| Unit | Type ID | Caliber | Notes |
|------|---------|---------|-------|
| ZSU-23-4 Shilka | `ZSU-23-4 Shilka` | 23mm | Radar-guided, iconic Soviet SPAAG |
| ZSU-57-2 | `ZSU_57_2` | 57mm | Twin 57mm, slow rate of fire |
| ZU-23 Emplacement | `ZU-23 Emplacement` | 23mm | Towed twin autocannon |
| ZU-23 on Ural | `Ural-375 ZU-23` | 23mm | Truck-mounted |
| M163 Vulcan | `Vulcan` | 20mm | M61 Gatling on M113 |
| Gepard | `Gepard` | 35mm | German twin 35mm SPAAG |
| S-60 57mm | `S-60_Type59_Artillery` | 57mm | Heavy AAA (needs SON-9 radar) |

**IR Missiles (Early Generation - No Radar Warning)**

| Unit | Type ID | Era | Notes |
|------|---------|-----|-------|
| SA-9 Gaskin | `Strela-1 9P31` | 1968 | BRDM-2 mounted, early IR seeker |
| SA-13 Gopher | `Strela-10M3` | 1976 | MT-LB mounted, improved seeker |

**Modern SHORAD (More Challenging)**

| Unit | Type ID | Role |
|------|---------|------|
| SA-19 Tunguska | `2S6 Tunguska` | Gun/missile combo |
| SA-15 Tor | `Tor 9A331` | Missile SHORAD |
| M6 Linebacker | `M6 Linebacker` | Bradley with Stingers |
| M1097 Avenger | `M1097 Avenger` | HMMWV with Stingers |

**Machine Guns and Technicals**

| Unit | Type ID | Caliber | Notes |
|------|---------|---------|-------|
| M45 Quadmount | `M45_Quadmount` | 12.7mm | Quad .50 cal, WWII era |
| Technical (DShK) | `HL_DSHK` | 12.7mm | Pickup with heavy MG |
| Technical (KORD) | `HL_KORD` | 12.7mm | Pickup with heavy MG |
| LC Technical (DShK) | `tt_DSHK` | 12.7mm | Land Cruiser with DShK |

## Mission File Structure

Ground units are placed in `coalition.[side].country[n].vehicle.group`. Since each group can only have one task, you need multiple groups for varied fire effects.

```lua
["coalition"] = {
    ["blue"] = {
        ["country"] = {
            [1] = {
                ["id"] = 2,  -- USA
                ["name"] = "USA",
                ["vehicle"] = {
                    ["group"] = {
                        [1] = { --[[ Blue firing group 1 ]] },
                        [2] = { --[[ Blue firing group 2 ]] },
                        [3] = { --[[ Blue firing group 3 ]] },
                    },
                },
            },
        },
    },
    ["red"] = {
        ["country"] = {
            [1] = {
                ["id"] = 0,  -- Russia
                ["name"] = "Russia",
                ["vehicle"] = {
                    ["group"] = {
                        [1] = { --[[ Red firing group 1 ]] },
                        [2] = { --[[ Red firing group 2 ]] },
                        [3] = { --[[ Red SHORAD group (separate!) ]] },
                    },
                },
            },
        },
    },
},
```

## FireAtPoint Task Structure

The `FireAtPoint` task orders ground units to fire at a specific map location. By targeting points *near* the enemy rather than the enemy units themselves, you create sustained suppressive fire without immediately destroying targets.

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
                    ["x"] = -100050,           -- Target X coordinate
                    ["y"] = 500025,            -- Target Y coordinate
                    ["radius"] = 100,          -- Dispersion radius (meters)
                    ["expendQty"] = 100,       -- Rounds to fire
                    ["expendQtyEnabled"] = true,
                    ["templateId"] = "",
                    ["zoneRadius"] = 100,
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
| `radius` | number | Dispersion radius for impacts (meters) |
| `expendQty` | number | Number of rounds to fire |
| `expendQtyEnabled` | boolean | Whether to limit ammunition expenditure |

> **Tip:** Set the target point 20-100 meters offset from the actual enemy position. This creates near-misses and dramatic incoming fire without quickly destroying targets.

## SetImmortal and SetInvisible Actions

The player-side forces should be both immortal (invulnerable to damage) and invisible (enemy AI won't target them). This prevents the enemy SHORAD from wasting missiles on invincible targets.

```lua
{
    ["enabled"] = true,
    ["auto"] = false,
    ["id"] = "WrappedAction",
    ["number"] = 2,
    ["params"] = {
        ["action"] = {
            ["id"] = "SetImmortal",
            ["params"] = {
                ["value"] = true,
            },
        },
    },
},
{
    ["enabled"] = true,
    ["auto"] = false,
    ["id"] = "WrappedAction",
    ["number"] = 3,
    ["params"] = {
        ["action"] = {
            ["id"] = "SetInvisible",
            ["params"] = {
                ["value"] = true,
            },
        },
    },
},
```

## Complete Example: Blue Forces (Player Side - Immortal/Invisible)

The player side uses three separate groups, each firing at a different point near the Red positions. All groups are immortal and invisible.

### Blue Firing Group 1 (Tanks)

```lua
[1] = {
    ["groupId"] = 300,
    ["name"] = "Blue Armor 1",
    ["task"] = "Ground Nothing",
    ["start_time"] = 0,
    ["visible"] = false,
    ["hidden"] = false,
    ["x"] = -100000,
    ["y"] = 500000,
    ["units"] = {
        [1] = {
            ["unitId"] = 300,
            ["name"] = "Blue-Tank-1",
            ["type"] = "M-1 Abrams",
            ["skill"] = "High",
            ["x"] = -100000,
            ["y"] = 500000,
            ["heading"] = 0,
            ["playerCanDrive"] = false,
        },
        [2] = {
            ["unitId"] = 301,
            ["name"] = "Blue-Tank-2",
            ["type"] = "M-1 Abrams",
            ["skill"] = "High",
            ["x"] = -100030,
            ["y"] = 500000,
            ["heading"] = 0,
            ["playerCanDrive"] = false,
        },
        [3] = {
            ["unitId"] = 302,
            ["name"] = "Blue-Ammo-1",
            ["type"] = "M30_CC",
            ["skill"] = "Average",
            ["x"] = -100015,
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
                                    ["y"] = 500830,     -- 30m short of Red position
                                    ["radius"] = 50,
                                    ["expendQty"] = 200,
                                    ["expendQtyEnabled"] = true,
                                    ["templateId"] = "",
                                    ["zoneRadius"] = 50,
                                },
                            },
                            [2] = {
                                ["enabled"] = true,
                                ["auto"] = false,
                                ["id"] = "WrappedAction",
                                ["number"] = 2,
                                ["params"] = {
                                    ["action"] = {
                                        ["id"] = "SetImmortal",
                                        ["params"] = {
                                            ["value"] = true,
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
                                        ["id"] = "SetInvisible",
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
        },
    },
},
```

### Blue Firing Group 2 (IFVs)

```lua
[2] = {
    ["groupId"] = 310,
    ["name"] = "Blue Mech 1",
    ["task"] = "Ground Nothing",
    ["start_time"] = 0,
    ["visible"] = false,
    ["hidden"] = false,
    ["x"] = -100080,
    ["y"] = 500000,
    ["units"] = {
        [1] = {
            ["unitId"] = 310,
            ["name"] = "Blue-IFV-1",
            ["type"] = "M-2 Bradley",
            ["skill"] = "High",
            ["x"] = -100080,
            ["y"] = 500000,
            ["heading"] = 0,
            ["playerCanDrive"] = false,
        },
        [2] = {
            ["unitId"] = 311,
            ["name"] = "Blue-IFV-2",
            ["type"] = "M-2 Bradley",
            ["skill"] = "High",
            ["x"] = -100110,
            ["y"] = 500000,
            ["heading"] = 0,
            ["playerCanDrive"] = false,
        },
        [3] = {
            ["unitId"] = 312,
            ["name"] = "Blue-Ammo-2",
            ["type"] = "M30_CC",
            ["skill"] = "Average",
            ["x"] = -100095,
            ["y"] = 499950,
            ["heading"] = 0,
            ["playerCanDrive"] = false,
        },
    },
    ["route"] = {
        ["points"] = {
            [1] = {
                ["x"] = -100080,
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
                                    ["x"] = -100120,
                                    ["y"] = 500850,     -- Different target point
                                    ["radius"] = 50,
                                    ["expendQty"] = 300,
                                    ["expendQtyEnabled"] = true,
                                    ["templateId"] = "",
                                    ["zoneRadius"] = 50,
                                },
                            },
                            [2] = {
                                ["enabled"] = true,
                                ["auto"] = false,
                                ["id"] = "WrappedAction",
                                ["number"] = 2,
                                ["params"] = {
                                    ["action"] = {
                                        ["id"] = "SetImmortal",
                                        ["params"] = {
                                            ["value"] = true,
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
                                        ["id"] = "SetInvisible",
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
        },
    },
},
```

### Blue Firing Group 3 (AAA for Tracers)

```lua
[3] = {
    ["groupId"] = 320,
    ["name"] = "Blue AAA 1",
    ["task"] = "Ground Nothing",
    ["start_time"] = 0,
    ["visible"] = false,
    ["hidden"] = false,
    ["x"] = -100160,
    ["y"] = 500000,
    ["units"] = {
        [1] = {
            ["unitId"] = 320,
            ["name"] = "Blue-AAA-1",
            ["type"] = "Vulcan",
            ["skill"] = "High",
            ["x"] = -100160,
            ["y"] = 500000,
            ["heading"] = 0,
            ["playerCanDrive"] = false,
        },
        [2] = {
            ["unitId"] = 321,
            ["name"] = "Blue-Ammo-3",
            ["type"] = "M30_CC",
            ["skill"] = "Average",
            ["x"] = -100160,
            ["y"] = 499950,
            ["heading"] = 0,
            ["playerCanDrive"] = false,
        },
    },
    ["route"] = {
        ["points"] = {
            [1] = {
                ["x"] = -100160,
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
                                    ["x"] = -100200,
                                    ["y"] = 500870,
                                    ["radius"] = 30,
                                    ["expendQty"] = 500,
                                    ["expendQtyEnabled"] = true,
                                    ["templateId"] = "",
                                    ["zoneRadius"] = 30,
                                },
                            },
                            [2] = {
                                ["enabled"] = true,
                                ["auto"] = false,
                                ["id"] = "WrappedAction",
                                ["number"] = 2,
                                ["params"] = {
                                    ["action"] = {
                                        ["id"] = "SetImmortal",
                                        ["params"] = {
                                            ["value"] = true,
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
                                        ["id"] = "SetInvisible",
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
        },
    },
},
```

## Complete Example: Red Forces (Enemy Side - Vulnerable)

The enemy side has firing groups plus a **separate** SHORAD group. The SHORAD group has no FireAtPoint task, so it will engage aircraft normally.

### Red Firing Group 1 (Tanks)

```lua
[1] = {
    ["groupId"] = 400,
    ["name"] = "Red Armor 1",
    ["task"] = "Ground Nothing",
    ["start_time"] = 0,
    ["visible"] = false,
    ["hidden"] = false,
    ["x"] = -100000,
    ["y"] = 500900,
    ["units"] = {
        [1] = {
            ["unitId"] = 400,
            ["name"] = "Red-Tank-1",
            ["type"] = "T-72B3",
            ["skill"] = "High",
            ["x"] = -100000,
            ["y"] = 500900,
            ["heading"] = 3.14159,
            ["playerCanDrive"] = false,
        },
        [2] = {
            ["unitId"] = 401,
            ["name"] = "Red-Tank-2",
            ["type"] = "T-72B3",
            ["skill"] = "High",
            ["x"] = -100030,
            ["y"] = 500900,
            ["heading"] = 3.14159,
            ["playerCanDrive"] = false,
        },
        [3] = {
            ["unitId"] = 402,
            ["name"] = "Red-Ammo-1",
            ["type"] = "M30_CC",
            ["skill"] = "Average",
            ["x"] = -100015,
            ["y"] = 500950,
            ["heading"] = 3.14159,
            ["playerCanDrive"] = false,
        },
    },
    ["route"] = {
        ["points"] = {
            [1] = {
                ["x"] = -100000,
                ["y"] = 500900,
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
                                    ["y"] = 500070,     -- 70m past Blue position
                                    ["radius"] = 50,
                                    ["expendQty"] = 200,
                                    ["expendQtyEnabled"] = true,
                                    ["templateId"] = "",
                                    ["zoneRadius"] = 50,
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

### Red Firing Group 2 (IFVs)

```lua
[2] = {
    ["groupId"] = 410,
    ["name"] = "Red Mech 1",
    ["task"] = "Ground Nothing",
    ["start_time"] = 0,
    ["visible"] = false,
    ["hidden"] = false,
    ["x"] = -100080,
    ["y"] = 500900,
    ["units"] = {
        [1] = {
            ["unitId"] = 410,
            ["name"] = "Red-IFV-1",
            ["type"] = "BMP-2",
            ["skill"] = "High",
            ["x"] = -100080,
            ["y"] = 500900,
            ["heading"] = 3.14159,
            ["playerCanDrive"] = false,
        },
        [2] = {
            ["unitId"] = 411,
            ["name"] = "Red-IFV-2",
            ["type"] = "BMP-2",
            ["skill"] = "High",
            ["x"] = -100110,
            ["y"] = 500900,
            ["heading"] = 3.14159,
            ["playerCanDrive"] = false,
        },
        [3] = {
            ["unitId"] = 412,
            ["name"] = "Red-AAA-1",
            ["type"] = "ZSU-23-4 Shilka",
            ["skill"] = "High",
            ["x"] = -100140,
            ["y"] = 500900,
            ["heading"] = 3.14159,
            ["playerCanDrive"] = false,
        },
        [4] = {
            ["unitId"] = 413,
            ["name"] = "Red-Ammo-2",
            ["type"] = "M30_CC",
            ["skill"] = "Average",
            ["x"] = -100110,
            ["y"] = 500950,
            ["heading"] = 3.14159,
            ["playerCanDrive"] = false,
        },
    },
    ["route"] = {
        ["points"] = {
            [1] = {
                ["x"] = -100080,
                ["y"] = 500900,
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
                                    ["x"] = -100050,
                                    ["y"] = 500050,
                                    ["radius"] = 50,
                                    ["expendQty"] = 300,
                                    ["expendQtyEnabled"] = true,
                                    ["templateId"] = "",
                                    ["zoneRadius"] = 50,
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

### Red SHORAD Group (Separate - No FireAtPoint)

This group has **no FireAtPoint task**. It will automatically engage any aircraft that enter its engagement envelope, providing air defense for the Red position.

This example uses Cold War era systems (Shilka, SA-9, ZU-23) that are dangerous but defeatable—more fun for players than modern systems like Tor or Tunguska.

```lua
[3] = {
    ["groupId"] = 420,
    ["name"] = "Red SHORAD",
    ["task"] = "Ground Nothing",
    ["start_time"] = 0,
    ["visible"] = false,
    ["hidden"] = false,
    ["x"] = -100100,
    ["y"] = 501000,
    ["units"] = {
        [1] = {
            ["unitId"] = 420,
            ["name"] = "Red-SHORAD-1",
            ["type"] = "ZSU-23-4 Shilka",
            ["skill"] = "High",
            ["x"] = -100050,
            ["y"] = 501000,
            ["heading"] = 3.14159,
            ["playerCanDrive"] = false,
        },
        [2] = {
            ["unitId"] = 421,
            ["name"] = "Red-SHORAD-2",
            ["type"] = "Strela-1 9P31",      -- SA-9 Gaskin
            ["skill"] = "High",
            ["x"] = -100150,
            ["y"] = 501000,
            ["heading"] = 3.14159,
            ["playerCanDrive"] = false,
        },
        [3] = {
            ["unitId"] = 422,
            ["name"] = "Red-AAA-1",
            ["type"] = "Ural-375 ZU-23",     -- Truck-mounted ZU-23
            ["skill"] = "High",
            ["x"] = -100100,
            ["y"] = 501050,
            ["heading"] = 3.14159,
            ["playerCanDrive"] = false,
        },
    },
    ["route"] = {
        ["points"] = {
            [1] = {
                ["x"] = -100100,
                ["y"] = 501000,
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
                        ["tasks"] = {},  -- No tasks! SHORAD engages aircraft automatically
                    },
                },
            },
        },
    },
},
```

## Tactical Considerations

### Engagement Distance

Front-line engagements work best at realistic direct-fire ranges:

| Distance | Effect |
|----------|--------|
| 500-800m | Close combat, intense exchange |
| 800-1500m | Typical tank engagement range |
| 1500-2500m | Long-range tank gunnery |
| 2500m+ | Extreme range, consider ATGMs |

The example uses ~900m separation, suitable for a close tank/IFV battle.

### Target Point Offset

The offset between the target point and actual enemy position controls "accuracy":

| Offset | Effect |
|--------|--------|
| 0-20m | Direct hits likely, rapid destruction |
| 20-50m | Near misses, some casualties over time |
| 50-100m | Dramatic but largely harmless suppressive fire |
| 100m+ | Fire lands nearby but is clearly missing |

### Multiple Groups for Variety

With single-task-per-group limitation, use multiple small groups to create varied fire:

- **Group A** fires at enemy left flank
- **Group B** fires at enemy center
- **Group C** fires at enemy right flank

This creates a more realistic, distributed engagement pattern.

### SHORAD Placement

Position the SHORAD group:

- **Behind** the firing line (50-150m back)
- **Spread out** to avoid single-weapon kills
- **Elevated terrain** if available for better radar coverage

### Choosing SHORAD Difficulty

| Difficulty | Recommended Units | Notes |
|------------|-------------------|-------|
| Easy | Technicals, M45 Quadmount | Machine guns only, short range |
| Medium | ZU-23, Shilka, SA-9 | Cold War AAA and early IR missiles |
| Hard | SA-13, SA-19 Tunguska | Better seekers, gun/missile combo |
| Very Hard | SA-15 Tor, Avenger, Linebacker | Modern systems, difficult to defeat |

## Placement Diagram

```
                    ~900m separation
    ←─────────────────────────────────────→
    
    Red Position (Y ≈ 500900-501050)
    
    ┌─────────────────────────────────────┐
    │          [Tor]                      │  Y = 501050 (SHORAD group)
    │   [Tunguska]    [Strela]            │  Y = 501000
    │                                     │
    │   [Ammo]        [Ammo]              │  Y = 500950
    │  [T-72] [T-72] [BMP] [BMP] [Shilka] │  Y = 500900 (firing groups)
    └─────────────────────────────────────┘
              │
              │ Fire direction (FireAtPoint targets Y ≈ 500050-500070)
              ↓
              
         ╳ ╳ ╳  Target points (offset from Blue)
         
              ↑
              │ Fire direction (FireAtPoint targets Y ≈ 500830-500870)
              │
    ┌─────────────────────────────────────┐
    │ [M1] [M1] [Bradley] [Bradley] [Vulcan] │  Y = 500000 (firing groups)
    │   [Ammo]      [Ammo]      [Ammo]       │  Y = 499950
    └─────────────────────────────────────┘
    
    Blue Position (Y = 500000)
    [All Blue units: Immortal + Invisible]
```

## Checklist

Before finalizing your firefight setup:

- [ ] Each firing element is in its own group (one FireAtPoint per group)
- [ ] All groups have unique `groupId` values
- [ ] All units have unique `unitId` values
- [ ] Ammunition carriers in each firing group (within 100m)
- [ ] Target points offset from actual enemy positions (20-100m)
- [ ] Blue forces have both `SetImmortal` and `SetInvisible` actions
- [ ] Red SHORAD is in a **separate group** with no FireAtPoint task
- [ ] `expendQty` set high enough for sustained engagement
- [ ] Engagement distance appropriate for direct-fire weapons (500-2500m)
- [ ] Units facing toward their targets (heading in radians: 0 = north, π = south)

## Troubleshooting

### Units Not Firing

- Verify the target point is within the weapon's range
- Check that the task is on waypoint 1
- Ensure units have ammunition (or ammo carriers nearby)
- Confirm line-of-sight to target area (for direct-fire weapons)

### Fire Stops Prematurely

- Increase `expendQty` value
- Add ammunition carriers to the group
- Position ammo carriers closer to firing units (within 100m)

### SHORAD Shooting at Ground

- SHORAD should not fire at ground targets—verify it's in a separate group
- Ensure the SHORAD group has no FireAtPoint task
- Check that Blue forces have `SetInvisible` so SHORAD ignores them

### Units Moving Instead of Firing

- Set `speed` to 0 in the waypoint
- Set `speed_locked` to true
- Ensure waypoint `type` is "Turning Point" with `action` "Off Road"

### One Side Destroyed Immediately

- Increase target point offset (further from actual enemy position)
- Add `SetImmortal` to friendly forces
- Reduce enemy skill level

## See Also

- [Mission File Schema](../mission/mission-file-schema.md) - Complete schema reference
- [SAM Site Deployment](sam-site-setup.md) - Air defense setup guide
- [Ground Units Reference](../units/ground.md) - Complete ground unit database
- [AI Tasks Reference](../scripting/reference/ai/tasks.md) - Task definitions including FireAtPoint
- [AI Commands Reference](../scripting/reference/ai/commands.md) - Commands including SetImmortal