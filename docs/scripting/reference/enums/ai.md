# AI Enums

This document describes the AI-related enumerations used in the DCS World Simulator Scripting Engine.

## AI.Skill

The `AI.Skill` enum defines the skill level constants used in unit definitions when spawning groups dynamically.

```lua
AI.Skill = {
    PLAYER = "Player",
    CLIENT = "Client",
    AVERAGE = "Average",
    GOOD = "Good",
    HIGH = "High",
    EXCELLENT = "Excellent"
}
```

## Task Enums

### AI.Task.OrbitPattern

```lua
AI.Task.OrbitPattern = {
    RACE_TRACK = "Race-Track",
    CIRCLE = "Circle"
}
```

The "Anchored" pattern is also valid but is not included in this enum.

### AI.Task.WeaponExpend

```lua
AI.Task.WeaponExpend = {
    ONE = "One",
    TWO = "Two",
    FOUR = "Four",
    QUARTER = "Quarter",
    HALF = "Half",
    ALL = "All"
}
```

### AI.Task.Designation

```lua
AI.Task.Designation = {
    NO = "No",
    WP = "WP",
    IR_POINTER = "IR-Pointer",
    LASER = "Laser",
    AUTO = "Auto"
}
```

### AI.Task.AltitudeType

The `AI.Task.AltitudeType` enum defines altitude reference types. The `RADIO` value indicates altitude above ground level (AGL). The `BARO` value indicates altitude above mean sea level (MSL).

```lua
AI.Task.AltitudeType = {
    RADIO = "RADIO",
    BARO = "BARO"
}
```

### AI.Task.TurnMethod

```lua
AI.Task.TurnMethod = {
    FLY_OVER_POINT = "Fly Over Point",
    FIN_POINT = "Fin Point"
}
```

### AI.Task.VehicleFormation

```lua
AI.Task.VehicleFormation = {
    VEE = "Vee",
    ECHELON_RIGHT = "EchelonR",
    ECHELON_LEFT = "EchelonL",
    OFF_ROAD = "Off Road",
    RANK = "Rank",
    ON_ROAD = "On Road",
    CONE = "Cone",
    DIAMOND = "Diamond"
}
```

### AI.Task.WaypointType

```lua
AI.Task.WaypointType = {
    TAKEOFF = "TakeOff",
    TAKEOFF_PARKING = "TakeOffParking",
    TAKEOFF_PARKING_HOT = "TakeOffParkingHot",
    TURNING_POINT = "Turning Point",
    LAND = "Land"
}
```

## Beacon Types

```lua
BEACON_TYPE_NULL = 0
BEACON_TYPE_VOR = 1
BEACON_TYPE_DME = 2
BEACON_TYPE_VOR_DME = 3
BEACON_TYPE_TACAN = 4
BEACON_TYPE_VORTAC = 5
BEACON_TYPE_RSBN = 32
BEACON_TYPE_BROADCAST_STATION = 1024
BEACON_TYPE_HOMER = 8
BEACON_TYPE_AIRPORT_HOMER = 4104
BEACON_TYPE_AIRPORT_HOMER_WITH_MARKER = 4136
BEACON_TYPE_ILS_FAR_HOMER = 16408
BEACON_TYPE_ILS_NEAR_HOMER = 16456
BEACON_TYPE_ILS_LOCALIZER = 16640
BEACON_TYPE_ILS_GLIDESLOPE = 16896
BEACON_TYPE_NAUTICAL_HOMER = 32776
```

## Beacon Systems

```lua
SystemName = {
    PAR_10 = 1,
    RSBN_5 = 2,
    TACAN = 3,
    TACAN_TANKER = 4,
    ILS_LOCALIZER = 5,
    ILS_GLIDESLOPE = 6,
    BROADCAST_STATION = 7
}
```

## See Also

- [AI Tasks](../ai/tasks.md) - Task definitions using these enums
- [AI Commands](../ai/commands.md) - Command definitions using beacon enums
- [AI Options](../ai/options.md) - Option definitions
