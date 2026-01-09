# Mission File Schema

The `mission` file is a Lua table containing the complete mission definition. This document describes every top-level key and their nested structures.

> **Important:** When programmatically generating mission files, all top-level keys listed below must be present, even if empty. DCS will fail to load missions that omit required fields such as `goals`, `result`, `trig`, or `weather`. Use empty tables `{}` for unused sections rather than omitting them entirely.

## Top-Level Keys

| Key | Type | Description |
|-----|------|-------------|
| `coalition` | table | Unit placement organized by coalition (blue/red/neutrals) |
| `coalitions` | table | Country ID assignments to each coalition |
| `currentKey` | number | Internal counter for generating unique IDs |
| `date` | table | Mission date (Year, Month, Day) |
| `descriptionBlueTask` | string | Dictionary key for blue coalition briefing text |
| `descriptionNeutralsTask` | string | Dictionary key for neutral coalition briefing text |
| `descriptionRedTask` | string | Dictionary key for red coalition briefing text |
| `descriptionText` | string | Dictionary key for main mission description |
| `drawings` | table | F10 map drawings and annotations |
| `failures` | table | Aircraft system failure configurations |
| `forcedOptions` | table | Mission-enforced difficulty settings |
| `goals` | table | Mission scoring goals and objectives |
| `groundControl` | table | Combined Arms role settings |
| `map` | table | Mission Editor map view settings |
| `maxDictId` | number | Highest dictionary key ID used |
| `pictureFileNameB` | table | Briefing images for blue coalition |
| `pictureFileNameN` | table | Briefing images for neutral coalition |
| `pictureFileNameR` | table | Briefing images for red coalition |
| `pictureFileNameServer` | table | Briefing images for server (multiplayer) |
| `requiredModules` | table | List of required DLC modules |
| `result` | table | Mission result conditions and scoring |
| `sortie` | string | Dictionary key for mission sortie name |
| `start_time` | number | Mission start time in seconds from midnight |
| `theatre` | string | Map/theatre name (e.g., "Syria", "Caucasus") |
| `trig` | table | Legacy trigger system (compiled actions) |
| `triggers` | table | Trigger zones defined in the mission |
| `trigrules` | table | Trigger rules with conditions and actions |
| `version` | number | Mission file format version |
| `weather` | table | Weather configuration |

---

## coalition

Contains the actual unit placements organized by coalition side. Each coalition has a bullseye reference point, navigation points, and countries containing unit groups.

```lua
coalition = {
    blue = {
        bullseye = { x = number, y = number },
        nav_points = { ... },
        country = { ... }
    },
    red = { ... },
    neutrals = { ... }
}
```

### coalition.[side].bullseye

The bullseye reference point for the coalition, used for BRAA (Bearing, Range, Altitude, Aspect) calls.

| Field | Type | Description |
|-------|------|-------------|
| `x` | number | X coordinate (meters, map coordinates) |
| `y` | number | Y coordinate (meters, map coordinates) |

### coalition.[side].nav_points

Named navigation waypoints available to units in this coalition.

| Field | Type | Description |
|-------|------|-------------|
| `type` | string | Waypoint type (e.g., "Default") |
| `comment` | string | Description or label |
| `callsignStr` | string | Display name for the waypoint |
| `id` | number | Unique waypoint ID |
| `properties` | table | Additional waypoint properties |
| `x` | number | X coordinate |
| `y` | number | Y coordinate |
| `callsign` | number | Numeric callsign (unsure of purpose) | <!-- TODO: QA - Verify the purpose of the numeric callsign field in nav_points -->

### coalition.[side].country

Array of countries within the coalition. Each country contains groups organized by unit category.

| Field | Type | Description |
|-------|------|-------------|
| `id` | number | Country ID (DCS country enum) |
| `name` | string | Country name |
| `helicopter` | table | Helicopter groups |
| `plane` | table | Fixed-wing aircraft groups |
| `vehicle` | table | Ground vehicle groups |
| `ship` | table | Naval vessel groups |
| `static` | table | Static object groups |

---

## coalitions

Maps country IDs to coalition sides. Each coalition is an array of numeric country IDs.

```lua
coalitions = {
    blue = { 21, 11, 8, 80, ... },
    red = { 18, 24, 27, 81, ... },
    neutrals = { 70, 83, 23, ... }
}
```

---

## date

Mission date configuration.

| Field | Type | Description |
|-------|------|-------------|
| `Year` | number | Year (e.g., 2016) |
| `Month` | number | Month (1-12) |
| `Day` | number | Day of month (1-31) |

---

## drawings

F10 map drawing layers and visibility settings.

### drawings.options.hiddenOnF10Map

Controls drawing visibility for different player roles.

| Field | Type | Description |
|-------|------|-------------|
| `Observer` | table | Visibility by coalition for observers |
| `Instructor` | table | Visibility by coalition for instructors |
| `ForwardObserver` | table | Visibility by coalition for forward observers |
| `ArtilleryCommander` | table | Visibility by coalition for artillery commanders |
| `Spectrator` | table | Visibility by coalition for spectators (note: typo in DCS) |
| `Pilot` | table | Visibility by coalition for pilots |

Each role has sub-fields: `Neutral`, `Blue`, `Red` (boolean).

### drawings.layers

Array of drawing layers with visibility and objects.

| Field | Type | Description |
|-------|------|-------------|
| `visible` | boolean | Whether layer is visible |
| `name` | string | Layer name ("Red", "Blue", "Neutral", "Common") |
| `objects` | table | Array of drawing objects |

#### Drawing Object (Polygon Example)

| Field | Type | Description |
|-------|------|-------------|
| `visible` | boolean | Visibility flag |
| `primitiveType` | string | Shape type ("Polygon", "Line", etc.) |
| `polygonMode` | string | Drawing mode ("free", etc.) |
| `thickness` | number | Line thickness |
| `colorString` | string | RGBA color as hex string |
| `fillColorString` | string | Fill color as hex string |
| `name` | string | Object name |
| `mapX` | number | X position |
| `mapY` | number | Y position |
| `points` | table | Array of {x, y} vertices |

---

## failures

Aircraft system failure configuration for each possible failure mode.

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Failure identifier (e.g., "Failure_Ctrl_Aileron") |
| `enable` | boolean | Whether failure is enabled |
| `prob` | number | Probability (0-100) |
| `hh` | number | Hours component of delay (unsure) | <!-- TODO: QA - Verify what the hh field represents in failure configuration -->
| `mm` | number | Minutes component of delay |
| `mmint` | number | Interval in minutes (unsure) | <!-- TODO: QA - Verify what the mmint field represents in failure configuration -->

---

## forcedOptions

Mission-enforced difficulty settings that override player preferences.

| Field | Type | Description |
|-------|------|-------------|
| `fuel` | boolean | Unlimited fuel |
| `weapons` | boolean | Unlimited weapons |
| `immortal` | boolean | Invulnerability |
| `easyFlight` | boolean | Simplified flight model |
| `easyRadar` | boolean | Simplified radar |
| `easyCommunication` | boolean | Simplified radio communication |
| `radio` | boolean | (Unsure - radio assistance) | <!-- TODO: QA - Verify what the radio forced option controls -->
| `geffect` | string | G-force effects ("realistic", etc.) |
| `externalViews` | boolean | Allow external camera views |
| `userMarks` | boolean | Allow player map markers |
| `optionsView` | string | View options ("optview_all", etc.) |
| `civTraffic` | string | Civilian traffic density |
| `accidental_failures` | boolean | Random system failures |
| `wakeTurbulence` | boolean | Wake turbulence effects |
| `unrestrictedSATNAV` | boolean | GPS always available |

---

## goals

Mission scoring goals and objectives.

| Field | Type | Description |
|-------|------|-------------|
| `rules` | table | Array of conditions for this goal |
| `side` | string | Which side ("OFFLINE", "BLUE", "RED") |
| `score` | number | Points awarded |
| `predicate` | string | Goal type (e.g., "score") |
| `comment` | string | Description |

### Goal Rule

| Field | Type | Description |
|-------|------|-------------|
| `coalitionlist` | string | Target coalition |
| `unitType` | string | Unit type filter ("ALL", or specific type) |
| `zone` | number | Zone ID reference |
| `flag` | string | Flag name to check |
| `predicate` | string | Condition function (e.g., "c_flag_is_true") |

---

## groundControl

Combined Arms role configuration.

| Field | Type | Description |
|-------|------|-------------|
| `isPilotControlVehicles` | boolean | Whether pilots can control ground units |
| `passwords` | table | Passwords for each role |
| `roles` | table | Slot counts per coalition for each role |

### Roles

- `artillery_commander`
- `instructor`
- `observer`
- `forward_observer`

Each role has sub-fields: `blue`, `red`, `neutrals` (number of slots).

---

## map

Mission Editor viewport settings. Not used at runtime.

| Field | Type | Description |
|-------|------|-------------|
| `centerX` | number | Map center X coordinate |
| `centerY` | number | Map center Y coordinate |
| `zoom` | number | Zoom level |

---

## result

Mission result conditions for scoring.

```lua
result = {
    total = number,
    offline = { conditions = {}, actions = {}, func = {} },
    blue = { conditions = {}, actions = {}, func = {} },
    red = { conditions = {}, actions = {}, func = {} }
}
```

Each section contains parallel arrays where `conditions[i]` triggers `actions[i]`, with `func[i]` being the compiled evaluation code.

---

## triggers

Trigger zones used for spatial conditions.

### Trigger Zone

| Field | Type | Description |
|-------|------|-------------|
| `zoneId` | number | Unique zone ID |
| `name` | string | Zone name |
| `type` | number | Zone type (0 = circle, 2 = polygon) |
| `x` | number | Center X coordinate |
| `y` | number | Center Y coordinate |
| `radius` | number | Radius for circular zones |
| `verticies` | table | Array of {x, y} points for polygon zones |
| `color` | table | RGBA color array [R, G, B, A] (0-1 range) |
| `hidden` | boolean | Hide zone on map |
| `heading` | number | Zone heading (radians) |
| `properties` | table | Custom key-value properties |

---

## trigrules

Trigger rules system with conditions and actions.

### Trigger Rule

| Field | Type | Description |
|-------|------|-------------|
| `rules` | table | Array of condition rules |
| `eventlist` | string | Event type filter |
| `comment` | string | Trigger name/description |
| `predicate` | string | Trigger type (e.g., "triggerStart", "triggerOnce") |
| `actions` | table | Array of actions to execute |

### Common Predicates

**Trigger Types:**
- `triggerStart` - Runs once at mission start
- `triggerOnce` - Runs once when conditions are met
- `triggerContinuous` - Runs continuously while conditions are met

**Action Predicates:**
- `a_set_flag` - Set a flag value
- `a_do_script` - Execute inline Lua script
- `a_do_script_file` - Execute Lua script from file
- `a_activate_group` - Activate a late-activated group
- `a_deactivate_group` - Deactivate a group
- `a_out_text_delay` - Display text message
- `a_radio_transmission` - Play radio audio
- `a_effect_smoke` - Create smoke effect
- `a_set_ATC_silent_mode` - Silence ATC
- `a_ai_task` - Assign AI task
- `a_set_flag_random` - Set flag to random value

---

## trig

Legacy/compiled trigger system. Contains the same information as `trigrules` but in a different format with pre-compiled action strings.

| Field | Type | Description |
|-------|------|-------------|
| `actions` | table | Array of compiled action strings |
| `conditions` | table | Array of condition strings |
| `func` | table | Array of compiled function strings |
| `flag` | table | Array of flag configurations |
| `funcStartup` | table | Startup function array |

---

## weather

Weather configuration for the mission.

| Field | Type | Description |
|-------|------|-------------|
| `atmosphere_type` | number | Atmosphere model type |
| `type_weather` | number | Weather type ID |
| `name` | string | Weather preset name |
| `modifiedTime` | boolean | Whether time affects weather |

### weather.wind

Wind configuration at different altitudes.

| Field | Type | Description |
|-------|------|-------------|
| `atGround` | table | Ground-level wind {speed, dir} |
| `at2000` | table | Wind at 2000m {speed, dir} |
| `at8000` | table | Wind at 8000m {speed, dir} |

Speed is in m/s, direction is in degrees (where wind is coming FROM).

### weather.clouds

| Field | Type | Description |
|-------|------|-------------|
| `preset` | string | Cloud preset name (e.g., "Preset16") |
| `base` | number | Cloud base altitude (meters) |
| `thickness` | number | Cloud layer thickness (meters) |
| `density` | number | Cloud density (0-10) |
| `iprecptns` | number | Precipitation type |

### weather.fog

| Field | Type | Description |
|-------|------|-------------|
| `thickness` | number | Fog thickness (meters) |
| `visibility` | number | Visibility in fog (meters) |

### weather.visibility

| Field | Type | Description |
|-------|------|-------------|
| `distance` | number | Visibility distance (meters) |

### weather.season

| Field | Type | Description |
|-------|------|-------------|
| `temperature` | number | Temperature (Celsius) |

### weather.groundTurbulence

Number representing ground turbulence intensity (meters/second).

### weather.halo

| Field | Type | Description |
|-------|------|-------------|
| `preset` | string | Halo effect preset ("auto", etc.) |

### Additional Weather Fields

| Field | Type | Description |
|-------|------|-------------|
| `enable_fog` | boolean | Fog enabled |
| `enable_dust` | boolean | Dust storms enabled |
| `dust_density` | number | Dust density |
| `qnh` | number | QNH pressure (mmHg) |
| `cyclones` | table | Cyclone/storm definitions (legacy); should be an empty table `{}` in new missions |

**Note:** The `cyclones` field is part of the legacy non-dynamic weather system and should not be used in new missions. New missions should use weather presets instead and leave `cyclones` as an empty table.

---

## Group Schema

Groups are containers for one or more units that share a common route and task.

### Aircraft/Helicopter Group

| Field | Type | Description |
|-------|------|-------------|
| `groupId` | number | Unique group ID |
| `name` | string | Group name |
| `task` | string | Primary task (e.g., "AWACS", "CAS", "Refueling") |
| `units` | table | Array of unit definitions |
| `route` | table | Route with waypoints |
| `x` | number | Initial X position |
| `y` | number | Initial Y position |
| `hidden` | boolean | Hidden on planning map |
| `hiddenOnPlanner` | boolean | Hidden in mission planner |
| `hiddenOnMFD` | boolean | Hidden on MFD displays |
| `lateActivation` | boolean | Requires trigger to spawn |
| `uncontrolled` | boolean | Starts with engines off, no AI |
| `start_time` | number | Spawn time offset (seconds) |
| `frequency` | number | Radio frequency (MHz) |
| `modulation` | number | Radio modulation (0=AM, 1=FM) |
| `communication` | boolean | Radio enabled |
| `radioSet` | boolean | Use preset radio frequencies |
| `tasks` | table | Additional group tasks |

### Ground Vehicle Group

| Field | Type | Description |
|-------|------|-------------|
| `groupId` | number | Unique group ID |
| `name` | string | Group name |
| `task` | string | Primary task (e.g., "Ground Nothing") |
| `units` | table | Array of unit definitions |
| `route` | table | Route with waypoints |
| `x` | number | Initial X position |
| `y` | number | Initial Y position |
| `visible` | boolean | Visible on map |
| `hidden` | boolean | Hidden from enemy |
| `uncontrollable` | boolean | Cannot be controlled |
| `taskSelected` | boolean | (Unsure) | <!-- TODO: QA - Verify what the taskSelected field does for ground vehicle groups -->
| `start_time` | number | Spawn time offset |

### Static Object Group

| Field | Type | Description |
|-------|------|-------------|
| `groupId` | number | Unique group ID |
| `name` | string | Group name |
| `units` | table | Array of static objects |
| `x` | number | Position X |
| `y` | number | Position Y |
| `heading` | number | Heading (radians) |
| `dead` | boolean | Destroyed state |
| `route` | table | Minimal route data |

---

## Unit Schema

### Aircraft Unit

| Field | Type | Description |
|-------|------|-------------|
| `unitId` | number | Unique unit ID |
| `name` | string | Unit name |
| `type` | string | Aircraft type (e.g., "F/A-18C_hornet") |
| `skill` | string | AI skill level |
| `x` | number | Position X |
| `y` | number | Position Y |
| `alt` | number | Altitude (meters) |
| `alt_type` | string | Altitude reference ("BARO" or "RADIO") |
| `speed` | number | Speed (m/s) |
| `heading` | number | Heading (radians) |
| `psi` | number | Orientation angle (radians) |
| `livery_id` | string | Livery/skin name |
| `onboard_num` | string | Aircraft tail number |
| `payload` | table | Weapons and stores configuration |
| `callsign` | table | Callsign configuration |
| `AddPropAircraft` | table | Aircraft-specific properties |

### Aircraft Skill Levels

- `"Average"`
- `"Good"`
- `"High"`
- `"Excellent"`
- `"Random"`
- `"Client"` - Player-controllable slot
- `"Player"` - Single-player slot

### payload

| Field | Type | Description |
|-------|------|-------------|
| `pylons` | table | Weapon stations configuration |
| `fuel` | string | Internal fuel (kg, as string) |
| `flare` | number | Flare count |
| `chaff` | number | Chaff count |
| `gun` | number | Gun ammunition percentage |

### callsign

| Field | Type | Description |
|-------|------|-------------|
| `[1]` | number | Callsign group (1=Enfield, 2=Springfield, etc.) |
| `[2]` | number | Flight number |
| `[3]` | number | Aircraft number in flight |
| `name` | string | Full callsign string (e.g., "Enfield11") |

### Ground Vehicle Unit

| Field | Type | Description |
|-------|------|-------------|
| `unitId` | number | Unique unit ID |
| `name` | string | Unit name |
| `type` | string | Vehicle type (e.g., "M1A2") |
| `skill` | string | AI skill level |
| `x` | number | Position X |
| `y` | number | Position Y |
| `heading` | number | Heading (radians) |
| `coldAtStart` | boolean | Start with engines off |
| `playerCanDrive` | boolean | Player can control in Combined Arms |

### Static Object Unit

| Field | Type | Description |
|-------|------|-------------|
| `unitId` | number | Unique unit ID |
| `name` | string | Unit name |
| `type` | string | Object type |
| `category` | string | Object category |
| `x` | number | Position X |
| `y` | number | Position Y |
| `heading` | number | Heading (radians) |
| `livery_id` | string | Livery/skin name |
| `rate` | string | (Unsure - possibly spawn rate) | <!-- TODO: QA - Verify what the rate field means for static objects -->

---

## Route Schema

Routes define the path and actions for a group.

### route

| Field | Type | Description |
|-------|------|-------------|
| `points` | table | Array of waypoints |
| `spans` | table | (Ground units) Road segment data |
| `routeRelativeTOT` | boolean | Times relative to Time On Target |

### Waypoint

| Field | Type | Description |
|-------|------|-------------|
| `alt` | number | Altitude (meters) |
| `alt_type` | string | "BARO" or "RADIO" |
| `type` | string | Waypoint type ("Turning Point", "Land", etc.) |
| `action` | string | Action at waypoint |
| `x` | number | Position X |
| `y` | number | Position Y |
| `speed` | number | Speed (m/s) |
| `speed_locked` | boolean | Speed is fixed |
| `ETA` | number | Estimated time of arrival (seconds) |
| `ETA_locked` | boolean | ETA is fixed |
| `formation_template` | string | Formation name |
| `task` | table | Tasks to perform at/after this waypoint |
| `properties` | table | Additional waypoint properties |
| `airdromeId` | number | Airport ID (for takeoff/landing waypoints) |

### Waypoint Actions

- `"Turning Point"` - Standard waypoint
- `"Fly Over Point"` - Must fly directly over
- `"Landing"` - Land at airfield
- `"Takeoff"` - Take off from runway
- `"From Runway"` - Start on runway
- `"From Parking Area"` - Start at parking
- `"From Parking Area Hot"` - Start at parking with engines running
- `"Off Road"` - (Ground) Move off-road
- `"On Road"` - (Ground) Move on road

---

## Task Schema

Tasks define AI behaviors at waypoints.

### ComboTask

Container for multiple tasks.

```lua
task = {
    id = "ComboTask",
    params = {
        tasks = { ... }
    }
}
```

### Common Task Types

| Task ID | Description |
|---------|-------------|
| `AWACS` | Airborne early warning |
| `Tanker` | Air refueling |
| `Orbit` | Orbit/hold pattern |
| `CAP` | Combat air patrol |
| `CAS` | Close air support |
| `EngageTargets` | Engage specified targets |
| `FollowBigFormation` | Formation flying |
| `Escort` | Escort another group |
| `WrappedAction` | Container for a single action |
| `ControlledTask` | Task with stop conditions |

### WrappedAction

Wraps a single action command.

```lua
{
    id = "WrappedAction",
    params = {
        action = {
            id = "SetInvisible",
            params = { value = true }
        }
    }
}
```

### Common Actions

| Action ID | Description |
|-----------|-------------|
| `SetInvisible` | Make unit invisible to AI |
| `SetImmortal` | Make unit invulnerable |
| `ActivateBeacon` | Activate TACAN/beacon |
| `EPLRS` | Enable data link |
| `Script` | Execute Lua script |
| `SetFrequency` | Change radio frequency |
| `SetCallsign` | Change callsign |

---

## Coordinate System

DCS uses a Cartesian coordinate system in meters:

- `x` - North-South axis (positive = South)
- `y` - East-West axis (positive = East)
- `z` (in 3D contexts) - Altitude (positive = Up)

Note: In 2D contexts (mission file), `y` is used for the East-West axis. In 3D Lua scripting, `y` is altitude and `z` is East-West.

Coordinates are measured from the map origin, which varies by theatre.
