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

The "Anchored" pattern is also valid but is not included in this enum. See [Orbit](../ai/tasks.md#orbit) for its parameters.

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

These constants are not defined in the mission scripting environment, so pass the numbers directly.

```lua
BEACON_TYPE_NULL = 0
BEACON_TYPE_VOR = 1
BEACON_TYPE_DME = 2
BEACON_TYPE_VOR_DME = 3
BEACON_TYPE_TACAN = 4
BEACON_TYPE_VORTAC = 5
BEACON_TYPE_HOMER = 8
BEACON_TYPE_RSBN = 128
BEACON_TYPE_BROADCAST_STATION = 1024
BEACON_TYPE_AIRPORT_HOMER = 4104
BEACON_TYPE_AIRPORT_HOMER_WITH_MARKER = 4136
BEACON_TYPE_ILS_FAR_HOMER = 16408
BEACON_TYPE_ILS_NEAR_HOMER = 16424
BEACON_TYPE_ILS_LOCALIZER = 16640
BEACON_TYPE_ILS_GLIDESLOPE = 16896
BEACON_TYPE_PRMG_LOCALIZER = 33024
BEACON_TYPE_PRMG_GLIDESLOPE = 33280
BEACON_TYPE_NAUTICAL_HOMER = 65536
BEACON_TYPE_ICLS_LOCALIZER = 131328
BEACON_TYPE_ICLS_GLIDESLOPE = 131584
BEACON_TYPE_TACAN_RANGE = 262144
```

## Beacon Systems

`SystemName` is not defined in the mission scripting environment, so pass the numbers directly.

```lua
SystemName = {
    PAR_10 = 1,
    RSBN_4H = 2,
    TACAN = 3,
    TACAN_TANKER_MODE_X = 4,
    TACAN_TANKER_MODE_Y = 5,
    VOR = 6,
    ILS_LOCALIZER = 7,
    ILS_GLIDESLOPE = 8,
    PRMG_LOCALIZER = 9,
    PRMG_GLIDESLOPE = 10,
    BROADCAST_STATION = 11,
    VORTAC = 12,
    TACAN_AA_MODE_X = 13,
    TACAN_AA_MODE_Y = 14,
    VORDME = 15,
    ICLS_LOCALIZER = 16,
    ICLS_GLIDESLOPE = 17,
    TACAN_MOBILE_MODE_X = 18,
    TACAN_MOBILE_MODE_Y = 19,
    TACAN_AA_MODE_X_AND_BRG = 20, -- "future provision" in the source
    TACAN_AA_MODE_Y_AND_BRG = 21, -- "future provision" in the source
}
```

## Weapon Flags

Weapon flags are a bitmask of weapon classes. Each class occupies one or more bits, and broader categories combine the bits of their members. They are used by the `weaponType` field of attack tasks and by the [`RTB_ON_OUT_OF_AMMO`](../ai/options.md#rtb_on_out_of_ammo) option. There are no constants for them in the mission scripting environment, so pass the numbers directly.

Each bit, or range of bits, is one weapon class:

| Bits  | Hex           | Weapon class                                        |
| ----- | ------------- | --------------------------------------------------- |
| 0     | `0x1`         | Unnamed; included in All                            |
| 1-3   | `0xE`         | Guided bombs                                        |
| 4-7   | `0xF0`        | Iron bombs                                          |
| 8-9   | `0x300`       | Cluster bombs                                       |
| 10    | `0x400`       | Candle (illumination) bombs                         |
| 11    | `0x800`       | Light rockets                                       |
| 12    | `0x1000`      | Smoke rockets                                       |
| 13    | `0x2000`      | Candle (illumination) rockets                       |
| 14    | `0x4000`      | Heavy rockets                                       |
| 15    | `0x8000`      | Anti-radiation missiles (ARM)                       |
| 16    | `0x10000`     | Antiship missiles                                   |
| 17    | `0x20000`     | Anti-tank guided missiles (ATGM)                    |
| 18-20 | `0x1C0000`    | Standard air-to-surface missiles                    |
| 21    | `0x200000`    | Cruise missiles                                     |
| 22    | `0x400000`    | Short-range air-to-air missiles                     |
| 23    | `0x800000`    | Medium-range air-to-air missiles                    |
| 24    | `0x1000000`   | Long-range air-to-air missiles                      |
| 25-27 | `0xE000000`   | Unnamed air-to-air missile classes; included in AAM |
| 28-29 | `0x30000000`  | Cannons                                             |
| 30-31 | `0xC0000000`  | Unnamed; included in All                            |
| 32    | `0x100000000` | Torpedoes                                           |
| 33    | `0x200000000` | Decoys                                              |
| 34    | `0x400000000` | Smoke shells                                        |
| 35    | `0x800000000` | Illumination shells                                 |

The named values below combine these bits:

| Name                | Value         | Hex           | Bits         | Includes                                                                   |
| ------------------- | ------------- | ------------- | ------------ | -------------------------------------------------------------------------- |
| No weapon           | `0`           | `0x0`         | None         | Nothing                                                                    |
| All                 | `4294967295`  | `0xFFFFFFFF`  | 0-31         | Everything except torpedoes, decoys, smoke shells, and illumination shells |
| Unguided            | `805339120`   | `0x30007FF0`  | 4-14, 28-29  | Cannons, rockets, bombs                                                    |
| Cannons             | `805306368`   | `0x30000000`  | 28-29        | Guns                                                                       |
| Shells              | `52344913920` | `0xC30000000` | 28-29, 34-35 | Cannons, smoke shells, illumination shells                                 |
| Smoke shells        | `17179869184` | `0x400000000` | 34           |                                                                            |
| Illumination shells | `34359738368` | `0x800000000` | 35           |                                                                            |
| Rockets             | `30720`       | `0x7800`      | 11-14        | All rockets                                                                |
| Light rockets       | `2048`        | `0x800`       | 11           |                                                                            |
| Smoke rockets       | `4096`        | `0x1000`      | 12           |                                                                            |
| Candle rockets      | `8192`        | `0x2000`      | 13           | Illumination rockets                                                       |
| Heavy rockets       | `16384`       | `0x4000`      | 14           |                                                                            |
| Bombs               | `2032`        | `0x7F0`       | 4-10         | Iron, cluster, and candle bombs                                            |
| Iron bombs          | `240`         | `0xF0`        | 4-7          |                                                                            |
| Cluster bombs       | `768`         | `0x300`       | 8-9          |                                                                            |
| Candle bombs        | `1024`        | `0x400`       | 10           | Illumination bombs                                                         |
| Torpedoes           | `4294967296`  | `0x100000000` | 32           |                                                                            |
| Guided              | `268402702`   | `0xFFF800E`   | 1-3, 15-27   | Guided bombs and missiles                                                  |
| Guided bombs        | `14`          | `0xE`         | 1-3          |                                                                            |
| Missiles            | `268402688`   | `0xFFF8000`   | 15-27        | ASM and AAM                                                                |
| ASM                 | `4161536`     | `0x3F8000`    | 15-21        | All air-to-surface missiles                                                |
| ARM                 | `32768`       | `0x8000`      | 15           | Anti-radiation missiles                                                    |
| Antiship missiles   | `65536`       | `0x10000`     | 16           |                                                                            |
| ATGM                | `131072`      | `0x20000`     | 17           | Anti-tank guided missiles                                                  |
| Standard ASM        | `1835008`     | `0x1C0000`    | 18-20        |                                                                            |
| Cruise missiles     | `2097152`     | `0x200000`    | 21           |                                                                            |
| AAM                 | `264241152`   | `0xFC00000`   | 22-27        | All air-to-air missiles, including unnamed classes in bits 25-27           |
| SR AAM              | `4194304`     | `0x400000`    | 22           | Short-range air-to-air missiles                                            |
| MR AAM              | `8388608`     | `0x800000`    | 23           | Medium-range air-to-air missiles                                           |
| LR AAM              | `16777216`    | `0x1000000`   | 24           | Long-range air-to-air missiles                                             |
| Decoys              | `8589934592`  | `0x200000000` | 33           |                                                                            |

A category's value is the sum of its members' bits. For example, Bombs (`0x7F0`, bits 4-10) is Iron bombs (`0xF0`) + Cluster bombs (`0x300`) + Candle bombs (`0x400`). To allow several classes that do not overlap, add their values: Guided bombs + ASM is `14 + 4161536 = 4161550` (`0x3F800E`). Use addition rather than bitwise operators, because [Lua](https://www.lua.org/about.html) 5.1 has no bitwise operators and some values do not fit in 32 bits.

`RTB_ON_OUT_OF_AMMO` accepts every named value except Decoys and the shell values.

## See Also

- [AI Tasks](../ai/tasks.md) - Task definitions using these enums
- [AI Commands](../ai/commands.md) - Command definitions using beacon enums
- [AI Options](../ai/options.md) - Option definitions
