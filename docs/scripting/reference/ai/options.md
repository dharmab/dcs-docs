# AI Options

Options configure AI behavior settings. They are set using `controller:setOption(optionId, value)`:

- `optionId` identifies **which option** to change. Constants under `AI.Option.<domain>.id` are numeric IDs.
- `value` specifies **the setting** for that option. Depending on the option, this is a boolean (`true` or `false`), an enum value, or another number.

```lua
controller:setOption(AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.WEAPON_FREE)
```

Options are separated by unit domain: Air, Ground, and Naval.

The calls in each example block show alternative settings: choose the one you need. Running every call in a block would leave only the last setting active.

## Air Options

### ROE (Rules of Engagement)

The `ROE` option controls when AI aircraft will engage targets.

**ID:** `AI.Option.Air.id.ROE` (`0`)

Values in `AI.Option.Air.val.ROE`:

| Name                    | Value | Behavior                                                    |
| ----------------------- | ----- | ----------------------------------------------------------- |
| `WEAPON_FREE`           | `0`   | Attack any detected enemy.                                  |
| `OPEN_FIRE_WEAPON_FREE` | `1`   | Attack enemies attacking friendlies while engaging at will. |
| `OPEN_FIRE`             | `2`   | Attack only enemies attacking friendlies.                   |
| `RETURN_FIRE`           | `3`   | Fire only when fired upon.                                  |
| `WEAPON_HOLD`           | `4`   | Do not fire weapons.                                        |

```lua
controller:setOption(AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.WEAPON_FREE)           -- Attack any detected enemy
controller:setOption(AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.OPEN_FIRE_WEAPON_FREE) -- Defend friendlies and engage at will
controller:setOption(AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.OPEN_FIRE)             -- Attack enemies attacking friendlies
controller:setOption(AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.RETURN_FIRE)           -- Fire only when fired upon
controller:setOption(AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.WEAPON_HOLD)           -- Do not fire
```

### REACTION_ON_THREAT

The `REACTION_ON_THREAT` option defines how aircraft respond to threats.

**ID:** `AI.Option.Air.id.REACTION_ON_THREAT` (`1`)

Values in `AI.Option.Air.val.REACTION_ON_THREAT`:

| Name                  | Value | Behavior                                                        |
| --------------------- | ----- | --------------------------------------------------------------- |
| `NO_REACTION`         | `0`   | Take no defensive action.                                       |
| `PASSIVE_DEFENCE`     | `1`   | Use jammers and countermeasures without defensive maneuvering.  |
| `EVADE_FIRE`          | `2`   | Use defensive maneuvers and countermeasures.                    |
| `BYPASS_AND_ESCAPE`   | `3`   | Route around threat zones and fly above threats.                |
| `ALLOW_ABORT_MISSION` | `4`   | Allow returning to base if the situation becomes too dangerous. |
| `AAA_EVADE_FIRE`      | `5`   | Perform S-turns at altitude.                                    |

The default is `ALLOW_ABORT_MISSION`. `BYPASS_AND_ESCAPE` may not be implemented.[^na-options]

```lua
controller:setOption(AI.Option.Air.id.REACTION_ON_THREAT, AI.Option.Air.val.REACTION_ON_THREAT.NO_REACTION)         -- No defensive action
controller:setOption(AI.Option.Air.id.REACTION_ON_THREAT, AI.Option.Air.val.REACTION_ON_THREAT.PASSIVE_DEFENCE)     -- Jammers and countermeasures only
controller:setOption(AI.Option.Air.id.REACTION_ON_THREAT, AI.Option.Air.val.REACTION_ON_THREAT.EVADE_FIRE)          -- Defensive maneuvers and countermeasures
controller:setOption(AI.Option.Air.id.REACTION_ON_THREAT, AI.Option.Air.val.REACTION_ON_THREAT.BYPASS_AND_ESCAPE)   -- Avoid threat zones
controller:setOption(AI.Option.Air.id.REACTION_ON_THREAT, AI.Option.Air.val.REACTION_ON_THREAT.ALLOW_ABORT_MISSION) -- Allow aborting the mission
controller:setOption(AI.Option.Air.id.REACTION_ON_THREAT, 5) -- AAA_EVADE_FIRE: S-turns at altitude
```

### RADAR_USING

The `RADAR_USING` option controls radar usage.

**ID:** `AI.Option.Air.id.RADAR_USING` (`3`)

Values in `AI.Option.Air.val.RADAR_USING`:

| Name                     | Value | Behavior                           |
| ------------------------ | ----- | ---------------------------------- |
| `NEVER`                  | `0`   | Never use radar.                   |
| `FOR_ATTACK_ONLY`        | `1`   | Use radar only for attacks.        |
| `FOR_SEARCH_IF_REQUIRED` | `2`   | Use radar to search when required. |
| `FOR_CONTINUOUS_SEARCH`  | `3`   | Use radar for continuous search.   |

```lua
controller:setOption(AI.Option.Air.id.RADAR_USING, AI.Option.Air.val.RADAR_USING.NEVER)                  -- Never use radar
controller:setOption(AI.Option.Air.id.RADAR_USING, AI.Option.Air.val.RADAR_USING.FOR_ATTACK_ONLY)        -- Use radar only for attacks
controller:setOption(AI.Option.Air.id.RADAR_USING, AI.Option.Air.val.RADAR_USING.FOR_SEARCH_IF_REQUIRED) -- Search when required
controller:setOption(AI.Option.Air.id.RADAR_USING, AI.Option.Air.val.RADAR_USING.FOR_CONTINUOUS_SEARCH)  -- Search continuously
```

### FLARE_USING

The `FLARE_USING` option controls flare and chaff deployment.

**ID:** `AI.Option.Air.id.FLARE_USING` (`4`)

Values in `AI.Option.Air.val.FLARE_USING`:

| Name                       | Value | Behavior                                                       |
| -------------------------- | ----- | -------------------------------------------------------------- |
| `NEVER`                    | `0`   | Never deploy flares or chaff.                                  |
| `AGAINST_FIRED_MISSILE`    | `1`   | Deploy against incoming missiles.                              |
| `WHEN_FLYING_IN_SAM_WEZ`   | `2`   | Deploy while flying within a SAM weapon engagement zone (WEZ). |
| `WHEN_FLYING_NEAR_ENEMIES` | `3`   | Deploy while flying near enemies.                              |

The default is `WHEN_FLYING_IN_SAM_WEZ`. `WHEN_FLYING_NEAR_ENEMIES` may not be implemented.[^na-options]

```lua
controller:setOption(AI.Option.Air.id.FLARE_USING, AI.Option.Air.val.FLARE_USING.NEVER)                    -- Never deploy countermeasures
controller:setOption(AI.Option.Air.id.FLARE_USING, AI.Option.Air.val.FLARE_USING.AGAINST_FIRED_MISSILE)    -- Deploy against incoming missiles
controller:setOption(AI.Option.Air.id.FLARE_USING, AI.Option.Air.val.FLARE_USING.WHEN_FLYING_IN_SAM_WEZ)   -- Deploy within a SAM engagement zone
controller:setOption(AI.Option.Air.id.FLARE_USING, AI.Option.Air.val.FLARE_USING.WHEN_FLYING_NEAR_ENEMIES) -- Deploy near enemies
```

### Formation

The `Formation` option sets the flight formation. The value is a formation index number.

**ID:** `AI.Option.Air.id.Formation` (`5`)

### RTB_ON_BINGO

The `RTB_ON_BINGO` option controls whether aircraft automatically return to base when fuel is low.

| Argument   | Type              | Meaning                                                               |
| ---------- | ----------------- | --------------------------------------------------------------------- |
| `optionId` | Number            | `AI.Option.Air.id.RTB_ON_BINGO` (numeric ID `6`) selects this option. |
| `value`    | Boolean or number | See the values below.                                                 |

| Value   | Behavior                                                                           |
| ------- | ---------------------------------------------------------------------------------- |
| `false` | Never return to base for fuel.                                                     |
| `true`  | At bingo fuel, refuel from a tanker if one is available; if none is, RTB. Default. |
| `2`     | Return to base at bingo fuel without looking for a tanker.                         |

```lua
controller:setOption(AI.Option.Air.id.RTB_ON_BINGO, true)  -- Refuel or RTB (default)
controller:setOption(AI.Option.Air.id.RTB_ON_BINGO, false) -- Never RTB for fuel
controller:setOption(AI.Option.Air.id.RTB_ON_BINGO, 2)     -- RTB, ignore tankers
```

The ID `6` goes in the first argument; the setting goes in the second. Use `true` or `false` for the first two settings, not `1` or `0`.

### SILENCE

The `SILENCE` option disables radio communications. The value is a boolean.

**ID:** `AI.Option.Air.id.SILENCE` (`7`)

```lua
controller:setOption(AI.Option.Air.id.SILENCE, true)  -- Disable radio communications
controller:setOption(AI.Option.Air.id.SILENCE, false) -- Allow radio communications
```

### RTB_ON_OUT_OF_AMMO

The `RTB_ON_OUT_OF_AMMO` option sends the group home when it runs out of a type of weapon. The value is a weapon flags number (see [Weapon Flags](../enums/ai.md#weapon-flags)) naming the weapon type the group needs to keep fighting, from `0` (off, the default) to `4294967295` (all weapons).

**ID:** `AI.Option.Air.id.RTB_ON_OUT_OF_AMMO` (`10`)

```lua
controller:setOption(AI.Option.Air.id.RTB_ON_OUT_OF_AMMO, 0)          -- Off (default)
controller:setOption(AI.Option.Air.id.RTB_ON_OUT_OF_AMMO, 4294967295) -- RTB when out of all weapons
```

### ECM_USING

The `ECM_USING` option controls ECM (Electronic Counter Measures) usage.

**ID:** `AI.Option.Air.id.ECM_USING` (`13`)

Values in `AI.Option.Air.val.ECM_USING`:

| Name                            | Value | Behavior                                  |
| ------------------------------- | ----- | ----------------------------------------- |
| `NEVER_USE`                     | `0`   | Never use ECM.                            |
| `USE_IF_ONLY_LOCK_BY_RADAR`     | `1`   | Use ECM only when locked by radar.        |
| `USE_IF_DETECTED_LOCK_BY_RADAR` | `2`   | Use ECM when detected or locked by radar. |
| `ALWAYS_USE`                    | `3`   | Always use ECM.                           |

```lua
controller:setOption(AI.Option.Air.id.ECM_USING, AI.Option.Air.val.ECM_USING.NEVER_USE)                     -- Never use ECM
controller:setOption(AI.Option.Air.id.ECM_USING, AI.Option.Air.val.ECM_USING.USE_IF_ONLY_LOCK_BY_RADAR)     -- Use only when locked by radar
controller:setOption(AI.Option.Air.id.ECM_USING, AI.Option.Air.val.ECM_USING.USE_IF_DETECTED_LOCK_BY_RADAR) -- Use when detected or locked by radar
controller:setOption(AI.Option.Air.id.ECM_USING, AI.Option.Air.val.ECM_USING.ALWAYS_USE)                    -- Always use ECM
```

### PROHIBIT_AA

The `PROHIBIT_AA` option prohibits air-to-air attacks. The value is a boolean.

**ID:** `AI.Option.Air.id.PROHIBIT_AA` (`14`)

```lua
controller:setOption(AI.Option.Air.id.PROHIBIT_AA, true)  -- Prohibit air-to-air attacks
controller:setOption(AI.Option.Air.id.PROHIBIT_AA, false) -- Allow air-to-air attacks
```

### PROHIBIT_JETT

The `PROHIBIT_JETT` option prohibits jettisoning stores. The value is a boolean.

**ID:** `AI.Option.Air.id.PROHIBIT_JETT` (`15`)

```lua
controller:setOption(AI.Option.Air.id.PROHIBIT_JETT, true)  -- Prohibit jettisoning stores
controller:setOption(AI.Option.Air.id.PROHIBIT_JETT, false) -- Allow jettisoning stores
```

### PROHIBIT_AB

The `PROHIBIT_AB` option prohibits afterburner use. The value is a boolean.

**ID:** `AI.Option.Air.id.PROHIBIT_AB` (`16`)

```lua
controller:setOption(AI.Option.Air.id.PROHIBIT_AB, true)  -- Prohibit afterburner use
controller:setOption(AI.Option.Air.id.PROHIBIT_AB, false) -- Allow afterburner use
```

### PROHIBIT_AG

The `PROHIBIT_AG` option prohibits air-to-ground attacks. The value is a boolean.

**ID:** `AI.Option.Air.id.PROHIBIT_AG` (`17`)

```lua
controller:setOption(AI.Option.Air.id.PROHIBIT_AG, true)  -- Prohibit air-to-ground attacks
controller:setOption(AI.Option.Air.id.PROHIBIT_AG, false) -- Allow air-to-ground attacks
```

### MISSILE_ATTACK

The `MISSILE_ATTACK` option controls missile launch range behavior.

**ID:** `AI.Option.Air.id.MISSILE_ATTACK` (`18`)

Values in `AI.Option.Air.val.MISSILE_ATTACK`:

| Name                | Value | Behavior                                                     |
| ------------------- | ----- | ------------------------------------------------------------ |
| `MAX_RANGE`         | `0`   | Fire at maximum range.                                       |
| `NEZ_RANGE`         | `1`   | Fire at no-escape zone (NEZ) range.                          |
| `HALF_WAY_RMAX_NEZ` | `2`   | Fire halfway between maximum range and no-escape zone range. |
| `TARGET_THREAT_EST` | `3`   | Select launch range based on target threat assessment.       |
| `RANDOM_RANGE`      | `4`   | Select a random launch range.                                |

```lua
controller:setOption(AI.Option.Air.id.MISSILE_ATTACK, AI.Option.Air.val.MISSILE_ATTACK.MAX_RANGE)         -- Fire at maximum range
controller:setOption(AI.Option.Air.id.MISSILE_ATTACK, AI.Option.Air.val.MISSILE_ATTACK.NEZ_RANGE)         -- Fire at no-escape zone range
controller:setOption(AI.Option.Air.id.MISSILE_ATTACK, AI.Option.Air.val.MISSILE_ATTACK.HALF_WAY_RMAX_NEZ) -- Fire halfway between maximum and NEZ range
controller:setOption(AI.Option.Air.id.MISSILE_ATTACK, AI.Option.Air.val.MISSILE_ATTACK.TARGET_THREAT_EST) -- Use target threat assessment
controller:setOption(AI.Option.Air.id.MISSILE_ATTACK, AI.Option.Air.val.MISSILE_ATTACK.RANDOM_RANGE)      -- Select a random launch range
```

### PROHIBIT_WP_PASS_REPORT

The `PROHIBIT_WP_PASS_REPORT` option disables waypoint passage radio calls. The value is a boolean.

**ID:** `AI.Option.Air.id.PROHIBIT_WP_PASS_REPORT` (`19`)

```lua
controller:setOption(AI.Option.Air.id.PROHIBIT_WP_PASS_REPORT, true)  -- Disable waypoint passage radio calls
controller:setOption(AI.Option.Air.id.PROHIBIT_WP_PASS_REPORT, false) -- Allow waypoint passage radio calls
```

### JETT_TANKS_IF_EMPTY

The `JETT_TANKS_IF_EMPTY` option causes the aircraft to jettison external fuel tanks when empty. The value is a boolean.

**ID:** `AI.Option.Air.id.JETT_TANKS_IF_EMPTY` (`25`)

```lua
controller:setOption(AI.Option.Air.id.JETT_TANKS_IF_EMPTY, true)  -- Enable jettisoning empty external tanks
controller:setOption(AI.Option.Air.id.JETT_TANKS_IF_EMPTY, false) -- Disable jettisoning empty external tanks
```

### FORCED_ATTACK

The `FORCED_ATTACK` option forces the AI to continue attacking regardless of threats. The value is a boolean.

**ID:** `AI.Option.Air.id.FORCED_ATTACK` (`26`)

```lua
controller:setOption(AI.Option.Air.id.FORCED_ATTACK, true)  -- Enable forced attack despite threats
controller:setOption(AI.Option.Air.id.FORCED_ATTACK, false) -- Disable forced attack
```

### PREFER_VERTICAL

The `PREFER_VERTICAL` option is for helicopters. When `true`, helicopters take off and land vertically where possible, instead of making rolling takeoffs and landings like an airplane. The value is a boolean and defaults to `false`.

**ID:** `AI.Option.Air.id.PREFER_VERTICAL` (`32`)

```lua
controller:setOption(AI.Option.Air.id.PREFER_VERTICAL, true)  -- Take off and land vertically when possible
controller:setOption(AI.Option.Air.id.PREFER_VERTICAL, false) -- Use normal rolling takeoffs and landings
```

### ALLOW_FORMATION_SIDE_SWAP

The `ALLOW_FORMATION_SIDE_SWAP` option allows wingmen to switch formation sides when the leader turns. The value is a boolean and defaults to `true`.

**ID:** `AI.Option.Air.id.ALLOW_FORMATION_SIDE_SWAP` (`35`)

```lua
controller:setOption(AI.Option.Air.id.ALLOW_FORMATION_SIDE_SWAP, true)  -- Allow wingmen to switch formation sides
controller:setOption(AI.Option.Air.id.ALLOW_FORMATION_SIDE_SWAP, false) -- Prevent wingmen from switching formation sides
```

### RADIO_USAGE_CONTACT, RADIO_USAGE_ENGAGE, RADIO_USAGE_KILL

These options control which radio calls the flight makes when it contacts, engages, or kills enemies. The IDs are `21` (contact), `22` (engage), and `23` (kill). The value is a string listing target types, each followed by a semicolon. `"none;"` turns the calls off. No `AI.Option` constants are known for these options, so pass the IDs directly.

```lua
controller:setOption(21, "none;")         -- No contact calls
controller:setOption(22, "Air Defence;")  -- Engage calls for air defense targets only
controller:setOption(23, "none;")         -- No kill calls
```

### LANDING_OPTIONS

The `LANDING_OPTIONS` option sets how a flight of airplanes lands. No `AI.Option` constant is known for this option, so pass the ID `36` directly.

| Value | Behavior                      |
| ----- | ----------------------------- |
| `0`   | Straight-in landing. Default. |
| `1`   | Force pair landing.           |
| `2`   | Restrict pair landing.        |
| `3`   | Overhead break.               |

```lua
controller:setOption(36, 3) -- Overhead break
```

### ALLOW_LINE_UP_RW

The `ALLOW_LINE_UP_RW` option makes airplanes line up on the runway after taxiing, before takeoff. The value is a boolean and defaults to `true`. No `AI.Option` constant is known for this option, so pass the ID `37` directly.

```lua
controller:setOption(37, true)  -- Line up on the runway before takeoff
controller:setOption(37, false) -- Take off without lining up first
```

### DISENGAGE_AND_RTB

The `DISENGAGE_AND_RTB` option makes airplanes disengage and return to base after the formation is lost. The value is a number from `1` to `3` and defaults to `1`. No `AI.Option` constant is known for this option, so pass the ID `38` directly.

```lua
controller:setOption(38, 1)
```

## Ground Options

### ROE

The `ROE` option for ground units controls when they will engage targets.

**ID:** `AI.Option.Ground.id.ROE` (`0`)

Values in `AI.Option.Ground.val.ROE`:

| Name          | Value | Behavior                      |
| ------------- | ----- | ----------------------------- |
| `OPEN_FIRE`   | `2`   | Engage enemy targets at will. |
| `RETURN_FIRE` | `3`   | Fire only when fired upon.    |
| `WEAPON_HOLD` | `4`   | Do not fire weapons.          |

```lua
controller:setOption(AI.Option.Ground.id.ROE, AI.Option.Ground.val.ROE.OPEN_FIRE)   -- Engage enemies at will
controller:setOption(AI.Option.Ground.id.ROE, AI.Option.Ground.val.ROE.RETURN_FIRE) -- Fire only when fired upon
controller:setOption(AI.Option.Ground.id.ROE, AI.Option.Ground.val.ROE.WEAPON_HOLD) -- Do not fire
```

Ground and naval units default to `0`, which is `AI.Option.Air.val.ROE.WEAPON_FREE`. The ground and naval tables have no known constant for it.

### ALARM_STATE

The `ALARM_STATE` option sets the group's alert level.

**ID:** `AI.Option.Ground.id.ALARM_STATE` (`9`)

Values in `AI.Option.Ground.val.ALARM_STATE`:

| Name    | Value | Behavior                                                 |
| ------- | ----- | -------------------------------------------------------- |
| `AUTO`  | `0`   | Change alert state automatically based on the situation. |
| `GREEN` | `1`   | Remain relaxed with weapons safe.                        |
| `RED`   | `2`   | Remain combat ready with weapons hot.                    |

```lua
local controller = Group.getByName("SA-10"):getController()
controller:setOption(AI.Option.Ground.id.ALARM_STATE, AI.Option.Ground.val.ALARM_STATE.AUTO)  -- Change alert state automatically
controller:setOption(AI.Option.Ground.id.ALARM_STATE, AI.Option.Ground.val.ALARM_STATE.GREEN) -- Relaxed, weapons safe
controller:setOption(AI.Option.Ground.id.ALARM_STATE, AI.Option.Ground.val.ALARM_STATE.RED)   -- Combat ready, weapons hot
```

### DISPERSE_ON_ATTACK

The `DISPERSE_ON_ATTACK` option lets ground units scatter when attacked from the air. The value is how long the units stay dispersed, in seconds. The default is `600`; `0` turns dispersal off.

**ID:** `AI.Option.Ground.id.DISPERSE_ON_ATTACK` (`8`)

```lua
controller:setOption(AI.Option.Ground.id.DISPERSE_ON_ATTACK, 600) -- Disperse for 10 minutes when attacked
controller:setOption(AI.Option.Ground.id.DISPERSE_ON_ATTACK, 0)   -- Never disperse
```

### ENGAGE_AIR_WEAPONS

The `ENGAGE_AIR_WEAPONS` option lets air defense shoot at weapons in flight, such as missiles and bombs, as well as aircraft. The value is a boolean and defaults to `true`. It applies to vehicles and ships.

**ID:** `AI.Option.Ground.id.ENGAGE_AIR_WEAPONS` (`20`)

```lua
controller:setOption(AI.Option.Ground.id.ENGAGE_AIR_WEAPONS, true)  -- Enable engagement of airborne weapons
controller:setOption(AI.Option.Ground.id.ENGAGE_AIR_WEAPONS, false) -- Disable engagement of airborne weapons
```

### AC_ENGAGEMENT_RANGE_RESTRICTION

The `AC_ENGAGEMENT_RANGE_RESTRICTION` option limits the engagement range for air defense units. The value is a percentage of maximum range from 0 to 100, defaulting to 100. It applies to vehicles and ships.

**ID:** `AI.Option.Ground.id.AC_ENGAGEMENT_RANGE_RESTRICTION` (`24`)

### EVASION_OF_ARM

The `EVASION_OF_ARM` option controls SAM behavior when targeted by anti-radiation missiles. The value is a boolean and defaults to `true`; when true, the unit shuts down its radar when an anti-radiation missile is detected.

**ID:** `AI.Option.Ground.id.EVASION_OF_ARM` (`31`)

```lua
controller:setOption(AI.Option.Ground.id.EVASION_OF_ARM, true)  -- Enable radar shutdown in response to anti-radiation missiles
controller:setOption(AI.Option.Ground.id.EVASION_OF_ARM, false) -- Disable this radar-shutdown behavior
```

### ALT_RESTRICTION_MIN and ALT_RESTRICTION_MAX

These options limit the altitudes at which anti-aircraft artillery engages targets. The IDs are `27` (minimum) and `29` (maximum). The value is an altitude in meters. The defaults are `200` and `3500`. They apply to groups with AAA units. No `AI.Option` constants are known for these options, so pass the IDs directly.

```lua
controller:setOption(27, 100)  -- Do not engage below 100 m
controller:setOption(29, 5000) -- Do not engage above 5000 m
```

### RESTRICT_TARGET

The `RESTRICT_TARGET` option limits which targets a ground group engages. No `AI.Option` constant is known for this option, so pass the ID `28` directly.

| Value | Behavior                   |
| ----- | -------------------------- |
| `0`   | Engage all units. Default. |
| `1`   | Engage air units only.     |
| `2`   | Engage ground units only.  |

```lua
controller:setOption(28, 1) -- Engage air units only
```

### OPTION_SET_COLUMN_INTERVAL

The `OPTION_SET_COLUMN_INTERVAL` option sets the spacing between vehicles in a ground group, in meters from `0` to `100`. The default is `0`. No `AI.Option` constant is known for this option, so pass the ID `30` directly.

```lua
controller:setOption(30, 50)
```

## Naval Options

### ROE

The `ROE` option for naval units controls when they will engage targets.

**ID:** `AI.Option.Naval.id.ROE` (`0`)

Values in `AI.Option.Naval.val.ROE`:

| Name          | Value | Behavior                      |
| ------------- | ----- | ----------------------------- |
| `OPEN_FIRE`   | `2`   | Engage enemy targets at will. |
| `RETURN_FIRE` | `3`   | Fire only when fired upon.    |
| `WEAPON_HOLD` | `4`   | Do not fire weapons.          |

```lua
controller:setOption(AI.Option.Naval.id.ROE, AI.Option.Naval.val.ROE.OPEN_FIRE)   -- Engage enemies at will
controller:setOption(AI.Option.Naval.id.ROE, AI.Option.Naval.val.ROE.RETURN_FIRE) -- Fire only when fired upon
controller:setOption(AI.Option.Naval.id.ROE, AI.Option.Naval.val.ROE.WEAPON_HOLD) -- Do not fire
```

## See Also

- [AI Tasks](tasks.md) - AI task definitions
- [AI Commands](commands.md) - Instant AI commands
- [AI Enums](../enums/ai.md) - AI-related enumerations
- [Controller](../classes/controller.md) - Controller class for issuing options

[^na-options]: The Mission Editor labels these values "BYPASS AND ESCAPE (N/A)" and "USE WHEN FLYING NEAR ENEMIES (N/A)" in `MissionEditor/modules/me_action_db.lua`. ED does not say what "N/A" means.
