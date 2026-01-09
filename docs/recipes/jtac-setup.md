# JTAC Setup Guide

This recipe describes how to configure AI Joint Terminal Attack Controllers (JTACs) and Forward Air Controllers (FACs) by directly editing the mission Lua file. A properly configured JTAC provides target coordinates, laser designation, and smoke marking for Close Air Support operations.

> **Note:** JTAC setup in DCS can be finicky. Line of sight, range, and unit selection all affect reliability. Ground units require clear sightlines to targets, while UAVs provide more consistent results from altitude. Expect some experimentation to achieve reliable designation.

## Overview

A JTAC requires:

- **JTAC Unit** - A ground vehicle or aircraft capable of target designation
- **FAC Task** - Either FAC-Assign Group or FAC-Engage Group
- **Callsign and Frequency** - Radio settings for player communication
- **Target Group** - Enemy units for the JTAC to designate
- **EPLRS** (optional) - Datalink for target coordinates

## JTAC-Capable Units

### Ground Units

Ground JTACs must be armed vehicles with optical targeting systems. Unarmed vehicles and infantry (during night) cannot reliably designate targets.

| Unit | Type ID | Notes |
|------|---------|-------|
| M1045 HMMWV TOW | `M1045 HMMWV TOW` | Good optical system, ~4 km effective range |
| M1134 Stryker ATGM | `M1134 Stryker ATGM` | Superior optics, recommended for night ops |
| M1043 HMMWV | `M1043 HMMWV Armament` | Armed Humvee, shorter range |

> **Night Operations:** For night missions requiring IR pointer designation, use the M1134 Stryker ATGM. Other ground units have unreliable night capability.

### UAV Units

UAVs provide the most reliable JTAC capability due to altitude advantage and consistent line of sight. Set the aircraft task to **AFAC** (Armed Forward Air Controller) when placing the unit.

| Unit | Type ID | Notes |
|------|---------|-------|
| MQ-9 Reaper | `MQ-9 Reaper` | Recommended for JTAC, superior sensors |
| MQ-1A Predator | `RQ-1A Predator` | Lighter payload, still effective |

## Mission File Structure

Ground JTACs are placed in `coalition.[side].country[n].vehicle.group`. UAV JTACs are placed in `coalition.[side].country[n].plane.group`.

```lua
["coalition"] = {
    ["blue"] = {
        ["country"] = {
            [1] = {
                ["id"] = 2,  -- USA
                ["name"] = "USA",
                ["vehicle"] = {
                    ["group"] = {
                        [1] = {
                            -- Ground JTAC group here
                        },
                    },
                },
                ["plane"] = {
                    ["group"] = {
                        [1] = {
                            -- UAV JTAC group here
                        },
                    },
                },
            },
        },
    },
},
```

---

## Ground JTAC Setup

### Group Definition

The following example creates a ground JTAC using an M1045 HMMWV TOW.

```lua
[1] = {
    ["groupId"] = 500,
    ["name"] = "Axeman",
    ["task"] = "Ground Nothing",
    ["start_time"] = 0,
    ["visible"] = false,      -- Set true for debugging, false for production
    ["hidden"] = false,
    ["x"] = -100000,
    ["y"] = 500000,
    ["units"] = {
        [1] = {
            ["unitId"] = 500,
            ["name"] = "Axeman-1",
            ["type"] = "M1045 HMMWV TOW",
            ["skill"] = "Excellent",
            ["x"] = -100000,
            ["y"] = 500000,
            ["heading"] = 0,
            ["playerCanDrive"] = false,
        },
    },
    ["route"] = {
        ["points"] = {
            [1] = {
                ["x"] = -100000,
                ["y"] = 500000,
                ["type"] = "Turning Point",
                ["action"] = "Off Road",
                ["speed"] = 0,
                ["ETA"] = 0,
                ["ETA_locked"] = true,
                ["formation_template"] = "",
                ["task"] = {
                    ["id"] = "ComboTask",
                    ["params"] = {
                        ["tasks"] = {
                            -- JTAC tasks defined below
                        },
                    },
                },
            },
        },
    },
},
```

### Waypoint Tasks for Ground JTAC

The first waypoint must include:

1. **SetCallsign** - JTAC callsign for radio menu
2. **SetFrequency** - Radio frequency for communication
3. **FAC-Engage Group** or **FAC-Assign Group** - Target designation task
4. **SetInvisible** (optional) - Prevent JTAC from being killed
5. **SetImmortal** (optional) - Additional protection
6. **Option: Weapons Hold** (optional) - Prevent JTAC from engaging targets directly

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
                        ["id"] = "SetCallsign",
                        ["params"] = {
                            ["callname"] = 1,     -- JTAC callsign index
                            ["number"] = 1,       -- Flight number
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
                        ["id"] = "SetFrequency",
                        ["params"] = {
                            ["frequency"] = 133000000,  -- 133 MHz
                            ["modulation"] = 0,         -- 0 = AM
                            ["power"] = 10,
                        },
                    },
                },
            },
            [3] = {
                ["enabled"] = true,
                ["auto"] = false,
                ["id"] = "FAC_EngageGroup",
                ["number"] = 3,
                ["params"] = {
                    ["groupId"] = 600,            -- Target group ID
                    ["weaponType"] = 1073741822,  -- AUTO
                    ["designation"] = "Laser",    -- Designation type
                    ["datalink"] = true,          -- Enable datalink
                    ["priority"] = 0,
                },
            },
            [4] = {
                ["enabled"] = true,
                ["auto"] = false,
                ["id"] = "WrappedAction",
                ["number"] = 4,
                ["params"] = {
                    ["action"] = {
                        ["id"] = "SetInvisible",
                        ["params"] = {
                            ["value"] = true,
                        },
                    },
                },
            },
            [5] = {
                ["enabled"] = true,
                ["auto"] = false,
                ["id"] = "WrappedAction",
                ["number"] = 5,
                ["params"] = {
                    ["action"] = {
                        ["id"] = "SetImmortal",
                        ["params"] = {
                            ["value"] = true,
                        },
                    },
                },
            },
            [6] = {
                ["enabled"] = true,
                ["auto"] = false,
                ["id"] = "WrappedAction",
                ["number"] = 6,
                ["params"] = {
                    ["action"] = {
                        ["id"] = "Option",
                        ["params"] = {
                            ["name"] = 0,    -- ROE
                            ["value"] = 4,   -- Weapons Hold
                        },
                    },
                },
            },
        },
    },
},
```

---

## UAV JTAC Setup

UAVs provide more reliable JTAC functionality due to altitude advantage. The key difference from ground JTACs is that you must set the aircraft task to **AFAC** and configure an orbit pattern.

### Group Definition

```lua
[1] = {
    ["groupId"] = 550,
    ["name"] = "Reaper JTAC",
    ["task"] = "AFAC",              -- Critical: Set to AFAC, not Reconnaissance
    ["modulation"] = 0,
    ["communication"] = true,
    ["frequency"] = 133,
    ["start_time"] = 0,
    ["uncontrolled"] = false,
    ["hidden"] = false,
    ["x"] = -95000,
    ["y"] = 505000,
    ["units"] = {
        [1] = {
            ["unitId"] = 550,
            ["name"] = "Reaper-1",
            ["type"] = "MQ-9 Reaper",
            ["skill"] = "Excellent",
            ["x"] = -95000,
            ["y"] = 505000,
            ["alt"] = 3000,           -- 3 km altitude (~10,000 ft)
            ["alt_type"] = "BARO",
            ["speed"] = 60,           -- m/s (~120 knots)
            ["heading"] = 0,
            ["psi"] = 0,
            ["payload"] = {
                ["flare"] = 0,
                ["chaff"] = 0,
                ["fuel"] = 1800,
                ["gun"] = 0,
                ["pylons"] = {},       -- Empty for pure JTAC role
            },
            ["callsign"] = 550,
        },
    },
    ["route"] = {
        ["routeRelativeTOT"] = true,
        ["points"] = {
            [1] = {
                ["alt"] = 3000,
                ["type"] = "Turning Point",
                ["action"] = "Turning Point",
                ["x"] = -95000,
                ["y"] = 505000,
                ["speed"] = 60,
                ["speed_locked"] = true,
                ["ETA"] = 0,
                ["ETA_locked"] = true,
                ["task"] = {
                    ["id"] = "ComboTask",
                    ["params"] = {
                        ["tasks"] = {
                            -- UAV JTAC tasks
                        },
                    },
                },
            },
        },
    },
},
```

### Waypoint Tasks for UAV JTAC

UAV JTACs should include an orbit task to maintain station over the target area. Position the orbit within 5 km of targets at 2-3 km altitude for optimal sensor performance.

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
                        ["id"] = "EPLRS",
                        ["params"] = {
                            ["value"] = true,
                            ["groupId"] = 550,
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
                        ["id"] = "SetCallsign",
                        ["params"] = {
                            ["callname"] = 1,
                            ["number"] = 1,
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
                            ["frequency"] = 133000000,
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
                    ["pattern"] = "Circle",
                    ["point"] = {
                        ["x"] = -95000,
                        ["y"] = 505000,
                    },
                    ["speed"] = 60,
                    ["altitude"] = 3000,
                },
            },
            [5] = {
                ["enabled"] = true,
                ["auto"] = false,
                ["id"] = "FAC_EngageGroup",
                ["number"] = 5,
                ["params"] = {
                    ["groupId"] = 600,
                    ["weaponType"] = 1073741822,
                    ["designation"] = "Laser",
                    ["datalink"] = true,
                    ["priority"] = 0,
                },
            },
        },
    },
},
```

### Delayed JTAC Activation

To have a UAV transit to the target area before activating as a JTAC:

1. Remove the FAC task from waypoint 0
2. Add the FAC task to the waypoint over the target area
3. The UAV will fly its route normally, then activate JTAC capability upon reaching the designated waypoint

---

## FAC Task Types

DCS provides two FAC task types with different behaviors:

### FAC-Engage Group

`FAC_EngageGroup` directs the JTAC to designate a specific enemy group. The JTAC will automatically cycle through units in the group.

```lua
{
    ["id"] = "FAC_EngageGroup",
    ["params"] = {
        ["groupId"] = 600,            -- Target group ID (required)
        ["weaponType"] = 1073741822,  -- AUTO
        ["designation"] = "Laser",    -- See designation types below
        ["datalink"] = true,          -- Share via Link-16
        ["priority"] = 0,             -- Lower = higher priority
    },
},
```

**When to use:** Single-player missions, training scenarios, or when specific target priority is needed.

### FAC-Assign Group

`FAC_AssignGroup` allows dynamic target assignment. The JTAC responds to radio commands to designate targets.

```lua
{
    ["id"] = "FAC_AssignGroup",
    ["params"] = {
        ["groupId"] = 600,
        ["weaponType"] = 1073741822,
        ["designation"] = "Laser",
        ["datalink"] = true,
    },
},
```

**When to use:** Multiplayer missions where target sequencing needs flexibility.

**Known Issue:** FAC-Assign Group may not work reliably in multiplayer when units are activated via triggers. Use FAC-Engage Group with the "Visual" checkbox enabled for better multiplayer reliability.

---

## Designation Types

The `designation` parameter controls how the JTAC marks targets:

| Designation | Value | Notes |
|-------------|-------|-------|
| Auto | `"Auto"` | JTAC selects best available method |
| Laser | `"Laser"` | Laser designation (code 1688) |
| IR Pointer | `"IR-Pointer"` | Infrared pointer (night, NVG required) |
| WP | `"WP"` | White phosphorus smoke |
| WP + Laser | `"WP + Laser"` | Smoke and laser simultaneously |
| No Mark | `"No"` | Coordinates only, no marking |

### Laser Codes

DCS JTACs use a fixed laser code of **1688**. This cannot be changed through the mission editor.

> **Workaround:** For missions requiring multiple JTACs with different laser codes, use third-party scripts like JTAC Autolase or Ciribob's CTLD, which allow configurable laser codes.

Configure your aircraft's laser-guided weapons to code 1688:

- **A-10C:** Set LSS code to 1688
- **F-16C:** Set TGP laser code to 1688
- **F/A-18C:** Set ATFLIR LST code to 1688
- **AH-64D:** Set laser code to 1688 in LRFD settings

---

## JTAC Callsigns

Ground JTAC callsigns use a different set than aircraft. The `callname` parameter indexes into this list:

| Index | Callsign |
|-------|----------|
| 1 | Axeman |
| 2 | Darknight |
| 3 | Warrior |
| 4 | Pointer |
| 5 | Eyeball |
| 6 | Moonbeam |
| 7 | Whiplash |
| 8 | Finger |
| 9 | Pinpoint |
| 10 | Ferret |
| 11 | Shaba |
| 12 | Playboy |
| 13 | Hammer |
| 14 | Jaguar |
| 15 | Deathstar |

---

## Recommended Radio Frequencies

| Frequency | Use |
|-----------|-----|
| 30.000 MHz FM | JTAC Primary (FM band) |
| 133.000 MHz AM | JTAC Primary (AM band) |
| 134.000 MHz AM | JTAC Alternate |
| 252.000 MHz AM | JTAC Tertiary |

Ground units support both FM (30-88 MHz) and AM (110-150 MHz). For aircraft like the A-10C that have separate FM and UHF radios, FM frequencies in the 30 MHz range often work well.

---

## JTAC Positioning

### Ground JTACs

Ground JTACs require **line of sight** to targets for laser and IR designation. Poor positioning is the most common cause of JTAC failures.

**Placement Guidelines:**

- Position JTAC at **equal or higher elevation** than targets
- Maintain **2 km or less** distance to targets for reliable designation
- Avoid placing JTACs behind hills, buildings, or in depressions
- The engagement circle around the JTAC in the Mission Editor shows designation range

**Survivability:**

- Set `["visible"] = false` to hide the JTAC marker on the F10 map
- Use `SetInvisible` and `SetImmortal` actions to prevent the JTAC from being killed
- Use `Option: Weapons Hold` to prevent the JTAC from shooting at targets and revealing position

### UAV JTACs

UAVs are more forgiving with positioning but still have constraints:

- Maintain orbit within **5 km horizontal distance** of targets
- Fly at **2-3 km altitude** (6,500-10,000 ft) for optimal sensor performance
- Keep the Reaper at moderate speed (~120 knots) for stable designation

---

## Complete Ground JTAC Example

```lua
[1] = {
    ["groupId"] = 500,
    ["name"] = "Axeman",
    ["task"] = "Ground Nothing",
    ["start_time"] = 0,
    ["visible"] = false,
    ["hidden"] = false,
    ["x"] = -100000,
    ["y"] = 500000,
    ["units"] = {
        [1] = {
            ["unitId"] = 500,
            ["name"] = "Axeman-1",
            ["type"] = "M1045 HMMWV TOW",
            ["skill"] = "Excellent",
            ["x"] = -100000,
            ["y"] = 500000,
            ["heading"] = 0,
            ["playerCanDrive"] = false,
        },
    },
    ["route"] = {
        ["points"] = {
            [1] = {
                ["x"] = -100000,
                ["y"] = 500000,
                ["type"] = "Turning Point",
                ["action"] = "Off Road",
                ["speed"] = 0,
                ["ETA"] = 0,
                ["ETA_locked"] = true,
                ["formation_template"] = "",
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
                                        ["id"] = "SetCallsign",
                                        ["params"] = {
                                            ["callname"] = 1,
                                            ["number"] = 1,
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
                                        ["id"] = "SetFrequency",
                                        ["params"] = {
                                            ["frequency"] = 133000000,
                                            ["modulation"] = 0,
                                            ["power"] = 10,
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
                            [4] = {
                                ["enabled"] = true,
                                ["auto"] = false,
                                ["id"] = "WrappedAction",
                                ["number"] = 4,
                                ["params"] = {
                                    ["action"] = {
                                        ["id"] = "SetImmortal",
                                        ["params"] = {
                                            ["value"] = true,
                                        },
                                    },
                                },
                            },
                            [5] = {
                                ["enabled"] = true,
                                ["auto"] = false,
                                ["id"] = "WrappedAction",
                                ["number"] = 5,
                                ["params"] = {
                                    ["action"] = {
                                        ["id"] = "Option",
                                        ["params"] = {
                                            ["name"] = 0,
                                            ["value"] = 4,
                                        },
                                    },
                                },
                            },
                            [6] = {
                                ["enabled"] = true,
                                ["auto"] = false,
                                ["id"] = "FAC_EngageGroup",
                                ["number"] = 6,
                                ["params"] = {
                                    ["groupId"] = 600,
                                    ["weaponType"] = 1073741822,
                                    ["designation"] = "Laser",
                                    ["datalink"] = true,
                                    ["priority"] = 0,
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

---

## CAS Procedure with JTAC

Once the JTAC is configured, players communicate via radio to receive target information and request designation.

### Radio Menu Flow

1. **Contact JTAC** - Select the JTAC from the radio menu
2. **Check In** - Establish communication and declare playtime (15, 30, 60 minutes)
3. **Request Tasking** - JTAC provides nine-line briefing with target info
4. **Call "At IP"** - Report when reaching the Initial Point
5. **Request "Laser On"** - Ask JTAC to begin lasing
6. **Call "Spot"** - Confirm laser acquisition on TGP/TPOD
7. **Call "In from [direction]"** - Announce attack heading
8. **Receive "Cleared Hot"** - Authorization to release weapons
9. **Call "Rifle/Pickle"** - Report weapon release
10. **Call "Off [direction]"** - Report egress

> **Note:** You must make the "Laser On" and "Spot" calls for the JTAC to actively lase the target. Without these calls, the nine-line may report "No Mark" even if laser designation was configured.

---

## Multiple Target Groups

To have a JTAC designate multiple target groups in sequence, add multiple FAC tasks with different priorities:

```lua
[3] = {
    ["id"] = "FAC_EngageGroup",
    ["number"] = 3,
    ["params"] = {
        ["groupId"] = 600,         -- First priority target
        ["designation"] = "Laser",
        ["priority"] = 0,
    },
},
[4] = {
    ["id"] = "FAC_EngageGroup",
    ["number"] = 4,
    ["params"] = {
        ["groupId"] = 601,         -- Second priority target
        ["designation"] = "Laser",
        ["priority"] = 1,
    },
},
```

Lower priority numbers are engaged first. The JTAC moves to the next group when all units in the current group are destroyed or the group is deactivated.

---

## Checklist

Before finalizing JTAC setup:

- [ ] JTAC unit is an armed vehicle with optics (ground) or AFAC-capable aircraft (UAV)
- [ ] FAC task (FAC_EngageGroup or FAC_AssignGroup) is configured
- [ ] Target `groupId` references a valid enemy group
- [ ] Callsign is set via SetCallsign action
- [ ] Radio frequency is set via SetFrequency action
- [ ] Ground JTAC has line of sight to targets
- [ ] Ground JTAC is within 2 km of targets (for reliable laser)
- [ ] UAV JTAC orbits within 5 km of targets at 2-3 km altitude
- [ ] Laser code in aircraft is set to 1688
- [ ] SetInvisible/SetImmortal set if JTAC survivability is needed
- [ ] Weapons Hold set if JTAC should not engage targets directly

---

## Troubleshooting

### JTAC Not Appearing in Radio Menu

- Verify SetCallsign and SetFrequency actions are on the first waypoint
- Check that you are tuned to the correct frequency
- Ensure the JTAC unit is alive and active
- For trigger-activated JTACs, the tasks may need to be re-applied after activation

### Nine-Line Reports "No Mark"

- JTAC lacks line of sight to target - reposition to higher ground
- Target is too far from JTAC - reduce distance to under 2 km
- You haven't made the required radio calls ("At IP", "Laser On", "Spot")
- IR Pointer selected but operating during day (IR requires night + NVG)

### Laser Not Acquired on TGP

- Confirm laser code is set to 1688 in your aircraft
- Verify you've called "Laser On" via radio menu
- Check that the JTAC has line of sight
- Point your TGP at the target location from the nine-line

### JTAC Engaging Targets Directly

- Add the Weapons Hold option to the task list
- Set `["value"] = 4` for the ROE option (index 0)

### JTAC Killed During Mission

- Use SetInvisible and SetImmortal actions
- Position JTAC away from direct fire lanes
- For ground JTACs, use terrain masking from enemy positions

### UAV JTAC Not Responding

- Verify aircraft task is set to "AFAC", not "Reconnaissance"
- Check that the FAC task is on the correct waypoint
- Ensure the orbit places the UAV within sensor range of targets

---

## See Also

- [Ground Units Reference](../units/ground.md) - Complete list of ground unit type strings
- [Aircraft Reference](../units/planes.md) - UAV specifications and capabilities
- [Communications Plan](./comm-plan.md) - Standard frequency allocations
- [Mission File Schema](../mission/mission-file-schema.md) - Full mission file structure reference
