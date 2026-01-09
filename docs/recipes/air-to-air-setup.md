# AI Air-to-Air Fighter Configuration

This recipe describes how to configure AI fighter aircraft for air-to-air combat roles by directly editing the mission Lua file. It covers four operational scenarios: Combat Air Patrol, Fighter Sweep, Intercept, and Strike Escort.

For dynamic spawning of interceptors in response to player actions, see the [Dynamic Air Intercept Script](air-intercept-script.md). This recipe focuses on static mission file configuration where AI fighters are pre-placed in the mission.

## Overview

Air-to-air AI configuration requires:

- **Aircraft Group** - A fighter-capable aircraft with appropriate loadout
- **Route** - Waypoints defining the patrol area or attack vector
- **En-route Tasks** - Engagement behavior (what targets to attack)
- **AI Options** - Rules of engagement, radar usage, and combat behavior

The four operational scenarios covered are:

| Scenario | Purpose | Primary Task | Key Characteristic |
|----------|---------|--------------|-------------------|
| Combat Air Patrol | Defend an area from enemy aircraft | Orbit + EngageTargets | Loiters on station |
| Fighter Sweep | Clear enemy aircraft from an area | EngageTargets (linear route) | Moves through hostile airspace |
| Intercept | Engage a specific known threat | AttackGroup/AttackUnit | Direct attack on designated target |
| Strike Escort | Protect a friendly group | Escort | Maintains formation with protected group |

## Fighter Aircraft Type Strings

| Aircraft | Type String | Coalition | Role | Radar Range |
|----------|-------------|-----------|------|-------------|
| F-15C Eagle | `F-15C` | Blue | Air superiority | Long |
| F-16C Viper | `F-16C_50` | Blue | Multirole | Medium |
| F/A-18C Hornet | `FA-18C_hornet` | Blue | Multirole | Medium |
| F-14B Tomcat | `F-14B` | Blue | Fleet defense | Long |
| Su-27 Flanker | `Su-27` | Red | Air superiority | Long |
| Su-33 Flanker-D | `Su-33` | Red | Carrier-based | Long |
| MiG-29A Fulcrum | `MiG-29A` | Red | Tactical fighter | Medium |
| MiG-29S Fulcrum | `MiG-29S` | Red | Improved tactical | Medium |
| MiG-31 Foxhound | `MiG-31` | Red | Interceptor | Very long |
| Mirage 2000-5 | `Mirage 2000-5` | Blue | Multirole | Medium |

## AI Options Reference

AI options control fighter behavior in combat. Set them via waypoint tasks using `WrappedAction` or via script using `controller:setOption()`.

### Rules of Engagement (ROE)

| Value | Constant | Behavior |
|-------|----------|----------|
| 0 | `WEAPON_FREE` | Attack any detected enemy |
| 1 | `OPEN_FIRE_WEAPON_FREE` | Attack enemies threatening friendlies while engaging at will |
| 2 | `OPEN_FIRE` | Attack only enemies threatening friendlies |
| 3 | `RETURN_FIRE` | Fire only when fired upon |
| 4 | `WEAPON_HOLD` | Do not fire weapons |

For air-to-air, use `WEAPON_FREE` (0) for aggressive patrols or `OPEN_FIRE_WEAPON_FREE` (1) for escort missions.

### Reaction on Threat

| Value | Constant | Behavior | Use Case |
|-------|----------|----------|----------|
| 0 | `NO_REACTION` | No defensive action | Suicide attackers |
| 1 | `PASSIVE_DEFENCE` | Countermeasures only | BVR-focused intercepts |
| 2 | `EVADE_FIRE` | Maneuver + countermeasures | Standard dogfighting |
| 3 | `BYPASS_AND_ESCAPE` | Route around threats | Non-combat transit |
| 4 | `ALLOW_ABORT_MISSION` | RTB if situation critical | Defensive CAP |

Use `EVADE_FIRE` (2) for most combat scenarios.

### Radar Usage

| Value | Constant | Behavior |
|-------|----------|----------|
| 0 | `NEVER` | Radar off (EMCON) |
| 1 | `FOR_ATTACK_ONLY` | Radar on only when engaging |
| 2 | `FOR_SEARCH_IF_REQUIRED` | Search when needed |
| 3 | `FOR_CONTINUOUS_SEARCH` | Radar always active |

Use `FOR_CONTINUOUS_SEARCH` (3) for CAP and sweep missions. Use `FOR_ATTACK_ONLY` (1) for stealthy intercepts.

### Missile Attack Range

| Value | Constant | Behavior | Tactical Use |
|-------|----------|----------|--------------|
| 0 | `MAX_RANGE` | Fire at maximum range | BVR engagement |
| 1 | `NEZ_RANGE` | Fire at no-escape zone | Close-in fights |
| 2 | `HALF_WAY_RMAX_NEZ` | Fire halfway between max and NEZ | Balanced approach |
| 3 | `TARGET_THREAT_EST` | Based on threat assessment | Escort missions |
| 4 | `RANDOM_RANGE` | Random selection | Variety |

### RTB Behavior

| Option | Default | Description |
|--------|---------|-------------|
| `RTB_ON_BINGO` | true | Return to base when fuel low |
| `RTB_ON_OUT_OF_AMMO` | true | Return to base when weapons expended |

Disable these for fighter sweep missions where completing the route is more important than survival.

## Combat Air Patrol (CAP)

CAP aircraft orbit a designated zone and engage any hostile aircraft that enter detection range. This is the most common air defense configuration.

### Key Components

- **Orbit task** - Defines the patrol pattern (use Race-Track for consistent coverage)
- **EngageTargets en-route task** - Specifies what targets to attack
- **Aggressive ROE** - WEAPON_FREE allows engaging any detected hostile
- **Continuous radar** - Maximizes detection range

### Complete CAP Example

This example creates a 2-ship F-15C CAP flight orbiting at 25,000 feet.

```lua
[1] = {
    ["groupId"] = 300,
    ["name"] = "Viper CAP",
    ["task"] = "CAP",
    ["modulation"] = 0,
    ["communication"] = true,
    ["frequency"] = 124,
    ["start_time"] = 0,
    ["uncontrolled"] = false,
    ["hidden"] = false,
    ["x"] = -100000,
    ["y"] = 500000,
    ["units"] = {
        [1] = {
            ["unitId"] = 300,
            ["name"] = "Viper-1",
            ["type"] = "F-15C",
            ["skill"] = "High",
            ["x"] = -100000,
            ["y"] = 500000,
            ["alt"] = 7620,           -- 25,000 feet
            ["alt_type"] = "BARO",
            ["speed"] = 220,          -- m/s (~430 knots)
            ["heading"] = 0,
            ["psi"] = 0,
            ["payload"] = {
                ["flare"] = 60,
                ["chaff"] = 60,
                ["fuel"] = 6103,
                ["gun"] = 100,
                ["pylons"] = {
                    -- Configure A2A loadout - obtain CLSIDs from Mission Editor
                    -- F-15C typical: AIM-9M on pylons 1, 9, 11; AIM-120C on pylons 3-8
                },
            },
            ["callsign"] = {
                [1] = 1,              -- Enfield
                [2] = 1,
                [3] = 1,
                ["name"] = "Enfield11",
            },
        },
        [2] = {
            ["unitId"] = 301,
            ["name"] = "Viper-2",
            ["type"] = "F-15C",
            ["skill"] = "Good",
            ["x"] = -100050,
            ["y"] = 499950,
            ["alt"] = 7620,
            ["alt_type"] = "BARO",
            ["speed"] = 220,
            ["heading"] = 0,
            ["psi"] = 0,
            ["payload"] = {
                ["flare"] = 60,
                ["chaff"] = 60,
                ["fuel"] = 6103,
                ["gun"] = 100,
                ["pylons"] = {},
            },
            ["callsign"] = {
                [1] = 1,
                [2] = 1,
                [3] = 2,
                ["name"] = "Enfield12",
            },
        },
    },
    ["route"] = {
        ["routeRelativeTOT"] = true,
        ["points"] = {
            [1] = {
                ["alt"] = 7620,
                ["type"] = "Turning Point",
                ["action"] = "Turning Point",
                ["x"] = -100000,
                ["y"] = 500000,
                ["speed"] = 220,
                ["speed_locked"] = true,
                ["ETA"] = 0,
                ["ETA_locked"] = true,
                ["task"] = {
                    ["id"] = "ComboTask",
                    ["params"] = {
                        ["tasks"] = {
                            -- EngageTargets en-route task
                            [1] = {
                                ["enabled"] = true,
                                ["auto"] = false,
                                ["id"] = "EngageTargets",
                                ["number"] = 1,
                                ["params"] = {
                                    ["targetTypes"] = {"Air"},
                                    ["priority"] = 0,
                                },
                            },
                            -- ROE: Weapon Free
                            [2] = {
                                ["enabled"] = true,
                                ["auto"] = false,
                                ["id"] = "WrappedAction",
                                ["number"] = 2,
                                ["params"] = {
                                    ["action"] = {
                                        ["id"] = "Option",
                                        ["params"] = {
                                            ["name"] = 0,   -- ROE
                                            ["value"] = 0,  -- WEAPON_FREE
                                        },
                                    },
                                },
                            },
                            -- Radar: Continuous Search
                            [3] = {
                                ["enabled"] = true,
                                ["auto"] = false,
                                ["id"] = "WrappedAction",
                                ["number"] = 3,
                                ["params"] = {
                                    ["action"] = {
                                        ["id"] = "Option",
                                        ["params"] = {
                                            ["name"] = 3,   -- RADAR_USING
                                            ["value"] = 3,  -- FOR_CONTINUOUS_SEARCH
                                        },
                                    },
                                },
                            },
                            -- Reaction on Threat: Evade Fire
                            [4] = {
                                ["enabled"] = true,
                                ["auto"] = false,
                                ["id"] = "WrappedAction",
                                ["number"] = 4,
                                ["params"] = {
                                    ["action"] = {
                                        ["id"] = "Option",
                                        ["params"] = {
                                            ["name"] = 1,   -- REACTION_ON_THREAT
                                            ["value"] = 2,  -- EVADE_FIRE
                                        },
                                    },
                                },
                            },
                            -- Orbit task (Race-Track pattern)
                            [5] = {
                                ["enabled"] = true,
                                ["auto"] = false,
                                ["id"] = "Orbit",
                                ["number"] = 5,
                                ["params"] = {
                                    ["pattern"] = "Race-Track",
                                    ["point"] = {
                                        ["x"] = -100000,
                                        ["y"] = 500000,
                                    },
                                    ["point2"] = {
                                        ["x"] = -100000,
                                        ["y"] = 580000,  -- 80 km leg
                                    },
                                    ["speed"] = 220,
                                    ["altitude"] = 7620,
                                },
                            },
                        },
                    },
                },
            },
            [2] = {
                ["alt"] = 7620,
                ["type"] = "Turning Point",
                ["action"] = "Turning Point",
                ["x"] = -100000,
                ["y"] = 580000,
                ["speed"] = 220,
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

### Zone-Constrained CAP

To restrict engagement to a specific area, use `EngageTargetsInZone` instead of `EngageTargets`:

```lua
[1] = {
    ["enabled"] = true,
    ["auto"] = false,
    ["id"] = "EngageTargetsInZone",
    ["number"] = 1,
    ["params"] = {
        ["targetTypes"] = {"Air"},
        ["priority"] = 0,
        ["point"] = {
            ["x"] = -100000,
            ["y"] = 540000,
        },
        ["zoneRadius"] = 60000,  -- 60 km radius
    },
},
```

## Fighter Sweep

Fighter sweep aircraft fly a linear route through enemy territory, engaging any hostile aircraft encountered. Unlike CAP, sweep flights do not loiter—they push forward aggressively.

### Key Components

- **Linear multi-waypoint route** - Progresses through hostile airspace
- **EngageTargets en-route task** - Active throughout the route
- **Aggressive settings** - WEAPON_FREE ROE, RTB disabled
- **EVADE_FIRE reaction** - Continue mission despite threats

### Fighter Sweep Example

This example creates a 4-ship sweep pushing 150 km into enemy territory.

```lua
[1] = {
    ["groupId"] = 400,
    ["name"] = "Sweep Flight",
    ["task"] = "Fighter Sweep",
    ["modulation"] = 0,
    ["communication"] = true,
    ["frequency"] = 127,
    ["start_time"] = 0,
    ["uncontrolled"] = false,
    ["hidden"] = false,
    ["x"] = -50000,
    ["y"] = 400000,
    ["units"] = {
        [1] = {
            ["unitId"] = 400,
            ["name"] = "Sweep-1",
            ["type"] = "F-16C_50",
            ["skill"] = "High",
            ["x"] = -50000,
            ["y"] = 400000,
            ["alt"] = 7620,
            ["alt_type"] = "BARO",
            ["speed"] = 250,
            ["heading"] = 0,
            ["psi"] = 0,
            ["payload"] = {
                ["flare"] = 60,
                ["chaff"] = 60,
                ["fuel"] = 3249,
                ["gun"] = 100,
                ["pylons"] = {},  -- Configure A2A loadout
            },
            ["callsign"] = {
                [1] = 3,          -- Springfield
                [2] = 1,
                [3] = 1,
                ["name"] = "Springfield11",
            },
        },
        -- Add units 2-4 with similar configuration
    },
    ["route"] = {
        ["routeRelativeTOT"] = true,
        ["points"] = {
            [1] = {
                ["alt"] = 7620,
                ["type"] = "Turning Point",
                ["action"] = "Turning Point",
                ["x"] = -50000,
                ["y"] = 400000,
                ["speed"] = 250,
                ["speed_locked"] = true,
                ["ETA"] = 0,
                ["ETA_locked"] = true,
                ["task"] = {
                    ["id"] = "ComboTask",
                    ["params"] = {
                        ["tasks"] = {
                            -- EngageTargets
                            [1] = {
                                ["enabled"] = true,
                                ["auto"] = false,
                                ["id"] = "EngageTargets",
                                ["number"] = 1,
                                ["params"] = {
                                    ["targetTypes"] = {"Air"},
                                    ["priority"] = 0,
                                },
                            },
                            -- ROE: Weapon Free
                            [2] = {
                                ["enabled"] = true,
                                ["auto"] = false,
                                ["id"] = "WrappedAction",
                                ["number"] = 2,
                                ["params"] = {
                                    ["action"] = {
                                        ["id"] = "Option",
                                        ["params"] = {
                                            ["name"] = 0,
                                            ["value"] = 0,
                                        },
                                    },
                                },
                            },
                            -- Disable RTB on Bingo
                            [3] = {
                                ["enabled"] = true,
                                ["auto"] = false,
                                ["id"] = "WrappedAction",
                                ["number"] = 3,
                                ["params"] = {
                                    ["action"] = {
                                        ["id"] = "Option",
                                        ["params"] = {
                                            ["name"] = 6,    -- RTB_ON_BINGO
                                            ["value"] = false,
                                        },
                                    },
                                },
                            },
                            -- Disable RTB on Out of Ammo
                            [4] = {
                                ["enabled"] = true,
                                ["auto"] = false,
                                ["id"] = "WrappedAction",
                                ["number"] = 4,
                                ["params"] = {
                                    ["action"] = {
                                        ["id"] = "Option",
                                        ["params"] = {
                                            ["name"] = 10,   -- RTB_ON_OUT_OF_AMMO
                                            ["value"] = false,
                                        },
                                    },
                                },
                            },
                            -- Missile Attack: NEZ Range (close-in)
                            [5] = {
                                ["enabled"] = true,
                                ["auto"] = false,
                                ["id"] = "WrappedAction",
                                ["number"] = 5,
                                ["params"] = {
                                    ["action"] = {
                                        ["id"] = "Option",
                                        ["params"] = {
                                            ["name"] = 18,   -- MISSILE_ATTACK
                                            ["value"] = 1,   -- NEZ_RANGE
                                        },
                                    },
                                },
                            },
                        },
                    },
                },
            },
            -- Waypoint 2: First turn
            [2] = {
                ["alt"] = 7620,
                ["type"] = "Turning Point",
                ["action"] = "Turning Point",
                ["x"] = 0,
                ["y"] = 450000,
                ["speed"] = 250,
                ["speed_locked"] = true,
                ["ETA"] = 0,
                ["ETA_locked"] = false,
                ["task"] = {
                    ["id"] = "ComboTask",
                    ["params"] = {["tasks"] = {}},
                },
            },
            -- Waypoint 3: Deep penetration
            [3] = {
                ["alt"] = 7620,
                ["type"] = "Turning Point",
                ["action"] = "Turning Point",
                ["x"] = 50000,
                ["y"] = 500000,
                ["speed"] = 250,
                ["speed_locked"] = true,
                ["ETA"] = 0,
                ["ETA_locked"] = false,
                ["task"] = {
                    ["id"] = "ComboTask",
                    ["params"] = {["tasks"] = {}},
                },
            },
            -- Waypoint 4: Egress
            [4] = {
                ["alt"] = 7620,
                ["type"] = "Turning Point",
                ["action"] = "Turning Point",
                ["x"] = -50000,
                ["y"] = 400000,
                ["speed"] = 250,
                ["speed_locked"] = true,
                ["ETA"] = 0,
                ["ETA_locked"] = false,
                ["task"] = {
                    ["id"] = "ComboTask",
                    ["params"] = {["tasks"] = {}},
                },
            },
        },
    },
},
```

## Intercept

Intercept missions send fighters directly at a known threat. Unlike CAP (which waits for targets) or sweep (which searches an area), intercept is a focused attack on a specific group or unit.

### Using AttackGroup

For pre-planned intercepts where the target is known at mission start, use the `AttackGroup` main task:

```lua
["task"] = {
    ["id"] = "ComboTask",
    ["params"] = {
        ["tasks"] = {
            [1] = {
                ["enabled"] = true,
                ["auto"] = false,
                ["id"] = "AttackGroup",
                ["number"] = 1,
                ["params"] = {
                    ["groupId"] = 500,  -- Target group ID
                    ["weaponType"] = 4161536,  -- A2A weapons
                },
            },
            -- ROE: Weapon Free
            [2] = {
                ["enabled"] = true,
                ["auto"] = false,
                ["id"] = "WrappedAction",
                ["number"] = 2,
                ["params"] = {
                    ["action"] = {
                        ["id"] = "Option",
                        ["params"] = {
                            ["name"] = 0,
                            ["value"] = 0,
                        },
                    },
                },
            },
            -- Missile Attack: Max Range (BVR)
            [3] = {
                ["enabled"] = true,
                ["auto"] = false,
                ["id"] = "WrappedAction",
                ["number"] = 3,
                ["params"] = {
                    ["action"] = {
                        ["id"] = "Option",
                        ["params"] = {
                            ["name"] = 18,
                            ["value"] = 0,  -- MAX_RANGE
                        },
                    },
                },
            },
        },
    },
},
```

### Scripted Intercept

For dynamic intercepts triggered during mission execution, use the SSE to assign targets:

```lua
-- Get the interceptor group and target
local interceptors = Group.getByName("Alert Fighters")
local target = Group.getByName("Incoming Bombers")

if interceptors and target then
    local controller = interceptors:getController()

    -- Build the intercept task
    local interceptTask = {
        id = 'AttackGroup',
        params = {
            groupId = target:getID(),
            weaponType = 4161536,  -- A2A weapons
        }
    }

    -- Set options for aggressive BVR engagement
    controller:setOption(AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.WEAPON_FREE)
    controller:setOption(AI.Option.Air.id.RADAR_USING, AI.Option.Air.val.RADAR_USING.FOR_CONTINUOUS_SEARCH)
    controller:setOption(AI.Option.Air.id.MISSILE_ATTACK, AI.Option.Air.val.MISSILE_ATTACK.MAX_RANGE)

    -- Issue the task (delay 1 second after spawn if newly created)
    controller:setTask(interceptTask)
end
```

## Strike Escort

Escort fighters protect a designated strike package from enemy aircraft. They maintain formation relative to the protected group and engage threats within a specified range.

### Escort Task Structure

```lua
[1] = {
    ["enabled"] = true,
    ["auto"] = false,
    ["id"] = "Escort",
    ["number"] = 1,
    ["params"] = {
        ["groupId"] = 600,           -- ID of group to escort
        ["engagementDistMax"] = 60000,  -- Max pursuit distance (60 km)
        ["targetTypes"] = {"Air"},   -- Only engage air threats
        ["pos"] = {
            ["x"] = -500,            -- 500m behind
            ["y"] = 300,             -- 300m above
            ["z"] = 1000,            -- 1000m to the side
        },
    },
},
```

### Complete Escort Example

```lua
[1] = {
    ["groupId"] = 350,
    ["name"] = "Escort Flight",
    ["task"] = "Escort",
    ["modulation"] = 0,
    ["communication"] = true,
    ["frequency"] = 130,
    ["start_time"] = 0,
    ["uncontrolled"] = false,
    ["hidden"] = false,
    ["x"] = -80000,
    ["y"] = 480000,
    ["units"] = {
        [1] = {
            ["unitId"] = 350,
            ["name"] = "Escort-1",
            ["type"] = "F-15C",
            ["skill"] = "High",
            ["x"] = -80000,
            ["y"] = 480000,
            ["alt"] = 7620,
            ["alt_type"] = "BARO",
            ["speed"] = 200,
            ["heading"] = 0,
            ["psi"] = 0,
            ["payload"] = {
                ["flare"] = 60,
                ["chaff"] = 60,
                ["fuel"] = 6103,
                ["gun"] = 100,
                ["pylons"] = {},  -- Configure A2A loadout
            },
            ["callsign"] = {
                [1] = 2,          -- Springfield
                [2] = 1,
                [3] = 1,
                ["name"] = "Springfield11",
            },
        },
        [2] = {
            ["unitId"] = 351,
            ["name"] = "Escort-2",
            ["type"] = "F-15C",
            ["skill"] = "Good",
            ["x"] = -80050,
            ["y"] = 479950,
            ["alt"] = 7620,
            ["alt_type"] = "BARO",
            ["speed"] = 200,
            ["heading"] = 0,
            ["psi"] = 0,
            ["payload"] = {
                ["flare"] = 60,
                ["chaff"] = 60,
                ["fuel"] = 6103,
                ["gun"] = 100,
                ["pylons"] = {},
            },
            ["callsign"] = {
                [1] = 2,
                [2] = 1,
                [3] = 2,
                ["name"] = "Springfield12",
            },
        },
    },
    ["route"] = {
        ["routeRelativeTOT"] = true,
        ["points"] = {
            [1] = {
                ["alt"] = 7620,
                ["type"] = "Turning Point",
                ["action"] = "Turning Point",
                ["x"] = -80000,
                ["y"] = 480000,
                ["speed"] = 200,
                ["speed_locked"] = true,
                ["ETA"] = 0,
                ["ETA_locked"] = true,
                ["task"] = {
                    ["id"] = "ComboTask",
                    ["params"] = {
                        ["tasks"] = {
                            -- Escort task
                            [1] = {
                                ["enabled"] = true,
                                ["auto"] = false,
                                ["id"] = "Escort",
                                ["number"] = 1,
                                ["params"] = {
                                    ["groupId"] = 600,  -- Strike package group ID
                                    ["engagementDistMax"] = 60000,
                                    ["targetTypes"] = {"Air"},
                                    ["pos"] = {
                                        ["x"] = -500,
                                        ["y"] = 300,
                                        ["z"] = 1000,
                                    },
                                },
                            },
                            -- ROE: Open Fire Weapon Free
                            [2] = {
                                ["enabled"] = true,
                                ["auto"] = false,
                                ["id"] = "WrappedAction",
                                ["number"] = 2,
                                ["params"] = {
                                    ["action"] = {
                                        ["id"] = "Option",
                                        ["params"] = {
                                            ["name"] = 0,
                                            ["value"] = 1,  -- OPEN_FIRE_WEAPON_FREE
                                        },
                                    },
                                },
                            },
                            -- Missile Attack: Target Threat Estimate
                            [3] = {
                                ["enabled"] = true,
                                ["auto"] = false,
                                ["id"] = "WrappedAction",
                                ["number"] = 3,
                                ["params"] = {
                                    ["action"] = {
                                        ["id"] = "Option",
                                        ["params"] = {
                                            ["name"] = 18,
                                            ["value"] = 3,  -- TARGET_THREAT_EST
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

## AI Skill and Difficulty

Air-to-air combat is challenging for most players. A few enemy fighters (2-4 aircraft) provides a meaningful challenge; a dozen will overwhelm even experienced pilots. Bias toward easier encounters to give players room to recover from mistakes.

### Skill Levels

| Skill | AI Behavior | Recommended Use |
|-------|-------------|-----------------|
| Average | Slow reactions, poor accuracy | Training scenarios |
| Good | Competent but beatable | Standard encounters |
| High | Aggressive, accurate | Challenging opponents |
| Excellent | Expert-level performance | Elite enemy aces |

Avoid the "Random" skill level—it can produce erratic behavior. Mixing skill levels within a flight (e.g., lead at High, wingmen at Good) creates natural variety.

### Flight Size Guidelines

| Scenario | Recommended Size | Rationale |
|----------|------------------|-----------|
| Light opposition | 2 aircraft | Manageable threat |
| Standard CAP | 2-4 aircraft | Meaningful challenge |
| Major threat | 4 aircraft | Difficult engagement |
| Boss fight | 4 aircraft (all High/Excellent) | Climactic encounter |

## Recommended Configurations

Quick reference for AI options by scenario:

| Scenario | ROE | Threat Reaction | Radar | Missile Attack | RTB Bingo | RTB Ammo |
|----------|-----|-----------------|-------|----------------|-----------|----------|
| Defensive CAP | OPEN_FIRE (2) | EVADE_FIRE (2) | CONTINUOUS (3) | HALF_WAY (2) | true | true |
| Aggressive CAP | WEAPON_FREE (0) | EVADE_FIRE (2) | CONTINUOUS (3) | MAX_RANGE (0) | false | false |
| Fighter Sweep | WEAPON_FREE (0) | EVADE_FIRE (2) | CONTINUOUS (3) | NEZ_RANGE (1) | false | false |
| Intercept | WEAPON_FREE (0) | PASSIVE_DEFENCE (1) | ATTACK_ONLY (1) | MAX_RANGE (0) | false | false |
| Strike Escort | OPEN_FIRE_WEAPON_FREE (1) | EVADE_FIRE (2) | CONTINUOUS (3) | TARGET_THREAT_EST (3) | true | true |

## Obtaining Weapon CLSIDs

To get weapon CLSIDs for the `pylons` table:

1. Open the DCS Mission Editor
2. Place the desired aircraft and configure its loadout
3. Save the mission
4. Open the `.miz` file (it's a ZIP archive)
5. Extract and open the `mission` file
6. Find the aircraft group and copy the `pylons` table with CLSIDs

Alternatively, examine loadout `.lua` files in:
`Saved Games\DCS\MissionEditor\UnitPayloads\`

The [Dynamic Air Intercept Script](air-intercept-script.md) contains example CLSID configurations for MiG-29A and Su-27 loadouts that can be adapted.

## Checklist

Before finalizing air-to-air configuration, verify:

- [ ] Aircraft type is fighter-capable (check available tasks in planes.md)
- [ ] ROE is appropriate for mission type (not WEAPON_HOLD)
- [ ] EngageTargets includes `"Air"` in targetTypes
- [ ] PROHIBIT_AA option is not set to true
- [ ] Radar usage is configured (CONTINUOUS_SEARCH for patrol)
- [ ] Skill level provides desired challenge (2-4 fighters at Good/High)
- [ ] Orbit pattern uses Race-Track for CAP (not Circle)
- [ ] Altitude appropriate for engagement (20,000-30,000 ft typical)
- [ ] Flight size is manageable (2-4 aircraft recommended)
- [ ] All groupId and unitId values are unique

## Troubleshooting

### Fighters Not Engaging

- Verify ROE is WEAPON_FREE or OPEN_FIRE_WEAPON_FREE
- Check that `targetTypes` includes `"Air"`
- Ensure PROHIBIT_AA option is not set
- Confirm targets are within radar range

### Fighters Breaking Off Too Easily

- Set REACTION_ON_THREAT to EVADE_FIRE, not ALLOW_ABORT_MISSION
- Disable RTB_ON_BINGO and RTB_ON_OUT_OF_AMMO
- Check fuel load is sufficient for mission duration

### Fighters Ignoring Bandits

- Verify radar usage is FOR_CONTINUOUS_SEARCH
- Check EngageTargets task is enabled
- Ensure priority is 0 (highest)

### Fighters Wasting Missiles at Long Range

- Set MISSILE_ATTACK to NEZ_RANGE or HALF_WAY_RMAX_NEZ
- Consider TARGET_THREAT_EST for smarter engagement

### CAP Leaving Station

- Verify Orbit task altitude matches waypoint altitude
- Check that Orbit speed matches waypoint speed
- Ensure orbit point coordinates are within the waypoint route

### Escort Not Protecting Strike Package

- Verify groupId references the correct strike group
- Check engagementDistMax is large enough (40-60 km)
- Ensure targetTypes includes the expected threat types

## See Also

- [AI Tasks Reference](../scripting/reference/ai/tasks.md) - Complete task documentation
- [AI Options Reference](../scripting/reference/ai/options.md) - All AI option values
- [AI Commands Reference](../scripting/reference/ai/commands.md) - Instant AI commands
- [Dynamic Air Intercept Script](air-intercept-script.md) - Scripted spawning system
- [AWACS Setup](awacs-setup.md) - Early warning and datalink configuration
- [Aircraft Reference](../units/planes.md) - Aircraft types and loadouts
- [Mission Design Wisdom](../wisdom.md) - Difficulty balancing guidance
