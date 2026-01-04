# AI Options

Options configure AI behavior settings. They are set using `controller:setOption(optionId, value)`.

```lua
controller:setOption(AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.WEAPON_FREE)
```

Options are separated by unit domain: Air, Ground, and Naval.

## Air Options

### ROE (Rules of Engagement)

The `ROE` option controls when AI aircraft will engage targets.

```lua
AI.Option.Air.id.ROE = 0

AI.Option.Air.val.ROE = {
    WEAPON_FREE = 0,
    OPEN_FIRE_WEAPON_FREE = 1,
    OPEN_FIRE = 2,
    RETURN_FIRE = 3,
    WEAPON_HOLD = 4
}
```

The `WEAPON_FREE` value allows attacking any detected enemy. The `OPEN_FIRE_WEAPON_FREE` value allows attacking enemies attacking friendlies while engaging at will. The `OPEN_FIRE` value allows attacking only enemies attacking friendlies. The `RETURN_FIRE` value allows firing only when fired upon. The `WEAPON_HOLD` value prevents all weapons fire.

```lua
controller:setOption(AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.WEAPON_FREE)
```

### REACTION_ON_THREAT

The `REACTION_ON_THREAT` option defines how aircraft respond to threats.

```lua
AI.Option.Air.id.REACTION_ON_THREAT = 1

AI.Option.Air.val.REACTION_ON_THREAT = {
    NO_REACTION = 0,
    PASSIVE_DEFENCE = 1,
    EVADE_FIRE = 2,
    BYPASS_AND_ESCAPE = 3,
    ALLOW_ABORT_MISSION = 4
}
```

The `NO_REACTION` value causes no defensive actions. The `PASSIVE_DEFENCE` value causes the aircraft to use jammers and countermeasures only, without maneuvering. The `EVADE_FIRE` value causes defensive maneuvers plus countermeasures. The `BYPASS_AND_ESCAPE` value causes the aircraft to route around threat zones and fly above threats. The `ALLOW_ABORT_MISSION` value allows the aircraft to return to base if the situation becomes too dangerous. The value 5 (AAA_EVADE_FIRE) is also valid and causes S-turns at altitude.

### RADAR_USING

The `RADAR_USING` option controls radar usage.

```lua
AI.Option.Air.id.RADAR_USING = 3

AI.Option.Air.val.RADAR_USING = {
    NEVER = 0,
    FOR_ATTACK_ONLY = 1,
    FOR_SEARCH_IF_REQUIRED = 2,
    FOR_CONTINUOUS_SEARCH = 3
}
```

### FLARE_USING

The `FLARE_USING` option controls flare and chaff deployment.

```lua
AI.Option.Air.id.FLARE_USING = 4

AI.Option.Air.val.FLARE_USING = {
    NEVER = 0,
    AGAINST_FIRED_MISSILE = 1,
    WHEN_FLYING_IN_SAM_WEZ = 2,
    WHEN_FLYING_NEAR_ENEMIES = 3
}
```

### Formation

The `Formation` option sets the flight formation. The value is a formation index number.

```lua
AI.Option.Air.id.Formation = 5
```

### RTB_ON_BINGO

The `RTB_ON_BINGO` option controls whether aircraft return to base when fuel is low. The value is a boolean.

```lua
AI.Option.Air.id.RTB_ON_BINGO = 6
```

### SILENCE

The `SILENCE` option disables radio communications. The value is a boolean.

```lua
AI.Option.Air.id.SILENCE = 7
```

### RTB_ON_OUT_OF_AMMO

The `RTB_ON_OUT_OF_AMMO` option controls whether aircraft return to base when out of ammunition. The value is a boolean.

```lua
AI.Option.Air.id.RTB_ON_OUT_OF_AMMO = 10
```

### ECM_USING

The `ECM_USING` option controls ECM (Electronic Counter Measures) usage.

```lua
AI.Option.Air.id.ECM_USING = 13

AI.Option.Air.val.ECM_USING = {
    NEVER_USE = 0,
    USE_IF_ONLY_LOCK_BY_RADAR = 1,
    USE_IF_DETECTED_LOCK_BY_RADAR = 2,
    ALWAYS_USE = 3
}
```

### PROHIBIT_AA

The `PROHIBIT_AA` option prohibits air-to-air attacks. The value is a boolean.

```lua
AI.Option.Air.id.PROHIBIT_AA = 14
```

### PROHIBIT_JETT

The `PROHIBIT_JETT` option prohibits jettisoning stores. The value is a boolean.

```lua
AI.Option.Air.id.PROHIBIT_JETT = 15
```

### PROHIBIT_AB

The `PROHIBIT_AB` option prohibits afterburner use. The value is a boolean.

```lua
AI.Option.Air.id.PROHIBIT_AB = 16
```

### PROHIBIT_AG

The `PROHIBIT_AG` option prohibits air-to-ground attacks. The value is a boolean.

```lua
AI.Option.Air.id.PROHIBIT_AG = 17
```

### MISSILE_ATTACK

The `MISSILE_ATTACK` option controls missile launch range behavior.

```lua
AI.Option.Air.id.MISSILE_ATTACK = 18

AI.Option.Air.val.MISSILE_ATTACK = {
    MAX_RANGE = 0,
    NEZ_RANGE = 1,
    HALF_WAY_RMAX_NEZ = 2,
    TARGET_THREAT_EST = 3,
    RANDOM_RANGE = 4
}
```

The `MAX_RANGE` value causes firing at maximum range. The `NEZ_RANGE` value causes firing at no-escape zone range. The `HALF_WAY_RMAX_NEZ` value causes firing halfway between maximum and no-escape zone range. The `TARGET_THREAT_EST` value causes firing based on target threat assessment. The `RANDOM_RANGE` value causes random range selection.

### PROHIBIT_WP_PASS_REPORT

The `PROHIBIT_WP_PASS_REPORT` option disables waypoint passage radio calls. The value is a boolean.

```lua
AI.Option.Air.id.PROHIBIT_WP_PASS_REPORT = 19
```

### JETT_TANKS_IF_EMPTY

The `JETT_TANKS_IF_EMPTY` option causes the aircraft to jettison external fuel tanks when empty. The value is a boolean.

```lua
AI.Option.Air.id.JETT_TANKS_IF_EMPTY = 25
```

### FORCED_ATTACK

The `FORCED_ATTACK` option forces the AI to continue attacking regardless of threats. The value is a boolean.

```lua
AI.Option.Air.id.FORCED_ATTACK = 26
```

### PREFER_VERTICAL

The `PREFER_VERTICAL` option causes the AI to prefer vertical maneuvering in combat. The value is a boolean.

```lua
AI.Option.Air.id.PREFER_VERTICAL = 32
```

### ALLOW_FORMATION_SIDE_SWAP

The `ALLOW_FORMATION_SIDE_SWAP` option allows wingmen to switch formation sides. The value is a boolean.

```lua
AI.Option.Air.id.ALLOW_FORMATION_SIDE_SWAP = 35
```

## Ground Options

### ROE

The `ROE` option for ground units controls when they will engage targets.

```lua
AI.Option.Ground.id.ROE = 0

AI.Option.Ground.val.ROE = {
    OPEN_FIRE = 2,
    RETURN_FIRE = 3,
    WEAPON_HOLD = 4
}
```

### ALARM_STATE

The `ALARM_STATE` option sets the group's alert level.

```lua
AI.Option.Ground.id.ALARM_STATE = 9

AI.Option.Ground.val.ALARM_STATE = {
    AUTO = 0,
    GREEN = 1,
    RED = 2
}
```

The `AUTO` value causes automatic state changes based on the situation. The `GREEN` value puts the group in a relaxed state with weapons safe. The `RED` value puts the group in combat ready state with weapons hot.

```lua
local controller = Group.getByName("SA-10"):getController()
controller:setOption(AI.Option.Ground.id.ALARM_STATE, AI.Option.Ground.val.ALARM_STATE.RED)
```

### DISPERSE_ON_ATTACK

The `DISPERSE_ON_ATTACK` option causes ground units to disperse when attacked. The value is a boolean.

```lua
AI.Option.Ground.id.DISPERSE_ON_ATTACK = 8
```

### ENGAGE_AIR_WEAPONS

The `ENGAGE_AIR_WEAPONS` option controls what types of air targets to engage. The value is a boolean.

```lua
AI.Option.Ground.id.ENGAGE_AIR_WEAPONS = 20
```

### AC_ENGAGEMENT_RANGE_RESTRICTION

The `AC_ENGAGEMENT_RANGE_RESTRICTION` option limits the engagement range for air defense units. The value is a range expressed as a percentage from 0 to 100.

```lua
AI.Option.Ground.id.AC_ENGAGEMENT_RANGE_RESTRICTION = 24
```

### EVASION_OF_ARM

The `EVASION_OF_ARM` option controls SAM behavior when targeted by anti-radiation missiles. The value is a boolean; when set to true, the unit shuts down its radar when an anti-radiation missile is detected.

```lua
AI.Option.Ground.id.EVASION_OF_ARM = 31
```

## Naval Options

### ROE

The `ROE` option for naval units controls when they will engage targets.

```lua
AI.Option.Naval.id.ROE = 0

AI.Option.Naval.val.ROE = {
    OPEN_FIRE = 2,
    RETURN_FIRE = 3,
    WEAPON_HOLD = 4
}
```

## See Also

- [AI Tasks](tasks.md) - AI task definitions
- [AI Commands](commands.md) - Instant AI commands
- [AI Enums](../enums/ai.md) - AI-related enumerations
- [Controller](../classes/controller.md) - Controller class for issuing options
