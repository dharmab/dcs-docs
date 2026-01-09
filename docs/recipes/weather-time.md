# Weather and Time Configuration

This recipe describes how to configure weather, fog, haze, and time settings by directly editing the mission Lua file. Weather significantly affects gameplay, visual atmosphere, and AI behavior.

This recipe uses the static weather system with cloud presets, which provides the modern volumetric cloud visuals introduced in DCS 2.7. Do not use the dynamic weather system with cyclones.

## Mission File Structure

Weather and time settings are stored in the top-level `weather`, `date`, and `start_time` fields of the mission file.

```lua
mission = {
    ["date"] = {
        ["Year"] = 2024,
        ["Month"] = 6,
        ["Day"] = 15,
    },
    ["start_time"] = 28800,  -- seconds since midnight
    ["weather"] = {
        -- Weather configuration here
    },
    -- Other mission fields...
}
```

---

## Date and Time

### Date

The `date` table sets the mission calendar date. This affects:

- Seasonal foliage and terrain textures (green summer vs brown autumn vs snow-covered winter)
- Unit camouflage patterns on certain vehicles
- Sun position and day length

| Field | Type | Description |
|-------|------|-------------|
| `Year` | number | Year (e.g., 2024) |
| `Month` | number | Month (1-12) |
| `Day` | number | Day of month (1-31) |

```lua
["date"] = {
    ["Year"] = 2024,
    ["Month"] = 1,   -- January (winter textures)
    ["Day"] = 15,
},
```

### Start Time

The `start_time` field specifies the mission start time in seconds since midnight (00:00:00).

**Formula:** `start_time = (hours * 3600) + (minutes * 60) + seconds`

```lua
["start_time"] = 28800,  -- 08:00:00
```

**Note on sunrise and sunset:** The actual times of sunrise and sunset depend on the mission date, the map's latitude, and longitude. Northern maps like Caucasus have shorter winter days and longer summer days than southern maps like Persian Gulf. Consult real-world sunrise/sunset tables for the map's geographic location and date to determine appropriate start times for dawn, dusk, or night missions.

---

## Weather Table Overview

The `weather` table contains all atmospheric conditions. Always use `atmosphere_type = 0` for static weather with modern cloud presets.

```lua
["weather"] = {
    ["atmosphere_type"] = 0,  -- Always 0 for static weather
    ["type_weather"] = 0,
    ["name"] = "Summer, clean sky",
    ["modifiedTime"] = true,
    ["qnh"] = 760,
    ["groundTurbulence"] = 0,
    ["wind"] = { ... },
    ["visibility"] = { ... },
    ["season"] = { ... },
    ["clouds"] = { ... },
    ["fog"] = { ... },
    ["enable_fog"] = false,
    ["enable_dust"] = false,
    ["dust_density"] = 0,
    ["halo"] = { ["preset"] = "auto" },
    ["cyclones"] = {},  -- Always empty; do not use cyclone system
},
```

---

## Temperature

Temperature is stored in `weather.season.temperature` in degrees Celsius.

```lua
["season"] = {
    ["temperature"] = 20,  -- 20°C
},
```

Temperature affects:

- Available precipitation types (rain vs snow)
- Air density (affects aircraft performance at high temperatures)
- Terrain visual appearance when combined with date

| Temperature | Available Precipitation |
|-------------|------------------------|
| Above 0°C | None, Rain, Thunderstorm |
| At or below 0°C | None, Snow, Snowstorm |

---

## Atmospheric Pressure (QNH)

The `qnh` field sets the sea-level pressure in millimeters of mercury (mmHg). Standard pressure is 760 mmHg (29.92 inHg / 1013.25 hPa).

```lua
["qnh"] = 760,  -- Standard pressure
```

Lower pressure indicates stormy conditions; higher pressure indicates fair weather.

---

## Wind

Wind is configured at three altitude bands. Each band specifies speed in meters per second and direction in degrees (the direction the wind is blowing FROM).

```lua
["wind"] = {
    ["atGround"] = {
        ["speed"] = 5,    -- 5 m/s (~10 knots)
        ["dir"] = 270,    -- From the west
    },
    ["at2000"] = {
        ["speed"] = 10,   -- 10 m/s (~20 knots)
        ["dir"] = 260,
    },
    ["at8000"] = {
        ["speed"] = 15,   -- 15 m/s (~30 knots)
        ["dir"] = 250,
    },
},
```

| Altitude Band | Description |
|---------------|-------------|
| `atGround` | Ground level (10 meters / 33 ft AGL) |
| `at2000` | 2000 meters (~6,600 ft) |
| `at8000` | 8000 meters (~26,000 ft) |

**Wind Speed Reference:**

| Condition | Speed (m/s) | Speed (knots) |
|-----------|-------------|---------------|
| Calm | 0-2 | 0-4 |
| Light breeze | 3-5 | 6-10 |
| Moderate | 6-10 | 12-20 |
| Fresh | 11-15 | 22-30 |
| Strong | 16-20 | 32-40 |
| Gale | 21+ | 42+ |

### Wind Direction Considerations

Wind direction is an important mission design decision that affects multiple gameplay systems:

- **AI runway selection:** AI aircraft choose runways based on wind direction to take off and land into the wind. Setting wind direction determines which runways will be active.
- **Carrier operations:** Aircraft carriers turn into the wind for launch and recovery operations. Wind direction affects the carrier's heading during flight operations.
- **Aerial refueling:** Tanker patterns may need adjustment based on wind to maintain stable refueling tracks.
- **Helicopter operations:** Strong crosswinds affect helicopter hover and landing capabilities.
- **Weapons delivery:** Wind affects unguided bomb and rocket accuracy.

When generating missions, confirm the desired wind direction with the mission designer to ensure runways and carrier operations function as intended.

---

## Ground Turbulence

The `groundTurbulence` field controls low-level turbulence intensity in meters per second. This creates buffeting effects during flight.

```lua
["groundTurbulence"] = 5,  -- Moderate turbulence
```

| Value | Effect |
|-------|--------|
| 0 | No turbulence (smooth air) |
| 1-5 | Light turbulence |
| 6-10 | Moderate turbulence |
| 11+ | Severe turbulence |

---

## Visibility

Base visibility distance is set in meters. This is the maximum visibility when fog and dust are disabled.

```lua
["visibility"] = {
    ["distance"] = 80000,  -- 80 km visibility
},
```

| Condition | Distance (meters) |
|-----------|------------------|
| Excellent | 80000+ |
| Good | 40000-80000 |
| Moderate | 10000-40000 |
| Poor | 5000-10000 |
| Very poor | 1000-5000 |

---

## Clouds

### Cloud Presets

DCS provides pre-configured cloud presets that create realistic multi-layer volumetric cloud configurations. Using presets is required for the modern cloud visuals.

```lua
["clouds"] = {
    ["preset"] = "Preset7",
    ["base"] = 2000,       -- Cloud base altitude in meters
    ["thickness"] = 200,   -- Ignored when using presets
    ["density"] = 0,       -- Ignored when using presets
    ["iprecptns"] = 0,     -- Precipitation type
},
```

**Available Presets:**

| Preset | Coverage | Description |
|--------|----------|-------------|
| `Preset1` | FEW | Few clouds at ~7000 ft |
| `Preset2` | FEW | Few clouds, scattered high layer |
| `Preset3`-`Preset6` | SCT | Scattered clouds, 2 layers |
| `Preset7`-`Preset12` | SCT-BKN | Scattered to broken, multiple layers |
| `Preset13`-`Preset20` | BKN | Broken clouds, good for tactical missions |
| `Preset21`-`Preset27` | OVC | Overcast, heavy cloud coverage |
| `RainyPreset1` | OVC+RA | Overcast with rain |
| `RainyPreset3`-`RainyPreset5` | Various+RA | Various coverage with rain |

**Recommended Presets by Mission Type:**

| Mission Type | Suggested Presets |
|--------------|-------------------|
| Clear day operations | `Preset1`, `Preset2` |
| Scattered clouds | `Preset3`, `Preset4`, `Preset6` |
| Tactical (some cover) | `Preset7`, `Preset9`, `Preset14` |
| Overcast | `Preset21`, `Preset24`, `Preset25` |
| Bad weather training | `RainyPreset1`, `RainyPreset3` |

### Precipitation

The `iprecptns` field controls precipitation type. Available options depend on temperature.

| Value | Type | Requires |
|-------|------|----------|
| 0 | None | Any temperature |
| 1 | Rain | Temperature > 0°C |
| 2 | Thunderstorm | Temperature > 0°C |
| 3 | Snow | Temperature <= 0°C |
| 4 | Snowstorm | Temperature <= 0°C |

```lua
["clouds"] = {
    ["preset"] = "RainyPreset1",
    ["base"] = 1500,
    ["iprecptns"] = 1,  -- Rain
},
```

### Thunderstorms Without Preset

To create thunderstorms with lightning effects without using a rainy preset, omit the preset field and set density to 9 or 10:

```lua
["clouds"] = {
    ["base"] = 1000,
    ["thickness"] = 2000,
    ["density"] = 10,
    ["iprecptns"] = 2,  -- Thunderstorm
},
```

---

## Fog

The volumetric fog system affects AI detection and creates atmospheric visual effects, particularly at dawn and dusk.

### Enabling Fog

```lua
["enable_fog"] = true,
["fog"] = {
    ["visibility"] = 1000,   -- Visibility in meters (100-100000)
    ["thickness"] = 200,     -- Vertical extent in meters (100-5000)
},
```

| Field | Range | Description |
|-------|-------|-------------|
| `enable_fog` | boolean | Enables/disables fog |
| `visibility` | 100-100000 m | Horizontal visibility at sea level |
| `thickness` | 100-5000 m | Fog extends from sea level to this altitude |

**Fog Thickness Limits:**

- Minimum: 100 meters
- Maximum: 5000 meters
- Cannot exceed cloud base altitude (automatically clamped)

### Fog Visibility Reference

| Condition | Visibility (m) |
|-----------|----------------|
| Dense fog | 100-500 |
| Thick fog | 500-1000 |
| Moderate fog | 1000-2000 |
| Light fog | 2000-5000 |
| Mist | 5000-10000 |

### Fog and AI Behavior

Fog blocks visual detection for AI:

| System | Affected by Fog |
|--------|-----------------|
| AI ground vehicle detection | Yes - blocked |
| AI aircraft visual detection | Yes - blocked |
| Radar systems | No - radar penetrates fog |

Fog creates tactical opportunities for low-level ingress against optically-guided threats. SAM systems that rely on optical tracking (IR SAMs, optically-guided AAA) are degraded by fog, while radar-guided systems remain fully effective.

---

## Dust and Haze

Dust creates a yellow-brown atmospheric haze, simulating desert or dusty conditions. Unlike fog, dust maintains a fixed altitude above ground level.

```lua
["enable_dust"] = true,
["dust_density"] = 2000,  -- Visibility in meters (300-3000)
```

| Field | Range | Description |
|-------|-------|-------------|
| `enable_dust` | boolean | Enables/disables dust |
| `dust_density` | 300-3000 m | Visibility through dust layer |

Dust always extends approximately 700 meters (2,300 ft) above ground level. On high-elevation maps, dust effects may be less visible.

---

## Complete Examples

### Clear Summer Day

```lua
["date"] = {
    ["Year"] = 2024,
    ["Month"] = 7,
    ["Day"] = 15,
},
["start_time"] = 36000,  -- 10:00
["weather"] = {
    ["atmosphere_type"] = 0,
    ["type_weather"] = 0,
    ["name"] = "Clear summer",
    ["modifiedTime"] = true,
    ["qnh"] = 760,
    ["groundTurbulence"] = 2,
    ["wind"] = {
        ["atGround"] = { ["speed"] = 3, ["dir"] = 180 },
        ["at2000"] = { ["speed"] = 5, ["dir"] = 200 },
        ["at8000"] = { ["speed"] = 10, ["dir"] = 220 },
    },
    ["visibility"] = { ["distance"] = 80000 },
    ["season"] = { ["temperature"] = 25 },
    ["clouds"] = {
        ["preset"] = "Preset2",
        ["base"] = 3000,
        ["thickness"] = 200,
        ["density"] = 0,
        ["iprecptns"] = 0,
    },
    ["fog"] = { ["visibility"] = 0, ["thickness"] = 0 },
    ["enable_fog"] = false,
    ["enable_dust"] = false,
    ["dust_density"] = 0,
    ["halo"] = { ["preset"] = "auto" },
    ["cyclones"] = {},
},
```

### Overcast with Rain

```lua
["date"] = {
    ["Year"] = 2024,
    ["Month"] = 11,
    ["Day"] = 5,
},
["start_time"] = 43200,  -- 12:00
["weather"] = {
    ["atmosphere_type"] = 0,
    ["type_weather"] = 0,
    ["name"] = "Overcast rain",
    ["modifiedTime"] = true,
    ["qnh"] = 745,
    ["groundTurbulence"] = 8,
    ["wind"] = {
        ["atGround"] = { ["speed"] = 8, ["dir"] = 270 },
        ["at2000"] = { ["speed"] = 15, ["dir"] = 260 },
        ["at8000"] = { ["speed"] = 25, ["dir"] = 250 },
    },
    ["visibility"] = { ["distance"] = 20000 },
    ["season"] = { ["temperature"] = 12 },
    ["clouds"] = {
        ["preset"] = "RainyPreset1",
        ["base"] = 800,
        ["thickness"] = 2000,
        ["density"] = 9,
        ["iprecptns"] = 1,
    },
    ["fog"] = { ["visibility"] = 0, ["thickness"] = 0 },
    ["enable_fog"] = false,
    ["enable_dust"] = false,
    ["dust_density"] = 0,
    ["halo"] = { ["preset"] = "auto" },
    ["cyclones"] = {},
},
```

### Dawn Fog

```lua
["date"] = {
    ["Year"] = 2024,
    ["Month"] = 9,
    ["Day"] = 20,
},
["start_time"] = 21600,  -- 06:00
["weather"] = {
    ["atmosphere_type"] = 0,
    ["type_weather"] = 0,
    ["name"] = "Morning fog",
    ["modifiedTime"] = true,
    ["qnh"] = 762,
    ["groundTurbulence"] = 0,
    ["wind"] = {
        ["atGround"] = { ["speed"] = 1, ["dir"] = 90 },
        ["at2000"] = { ["speed"] = 3, ["dir"] = 100 },
        ["at8000"] = { ["speed"] = 8, ["dir"] = 120 },
    },
    ["visibility"] = { ["distance"] = 80000 },
    ["season"] = { ["temperature"] = 14 },
    ["clouds"] = {
        ["preset"] = "Preset1",
        ["base"] = 2500,
        ["thickness"] = 200,
        ["density"] = 0,
        ["iprecptns"] = 0,
    },
    ["fog"] = {
        ["visibility"] = 800,
        ["thickness"] = 150,
    },
    ["enable_fog"] = true,
    ["enable_dust"] = false,
    ["dust_density"] = 0,
    ["halo"] = { ["preset"] = "auto" },
    ["cyclones"] = {},
},
```

### Desert Dust Storm

```lua
["date"] = {
    ["Year"] = 2024,
    ["Month"] = 8,
    ["Day"] = 10,
},
["start_time"] = 50400,  -- 14:00
["weather"] = {
    ["atmosphere_type"] = 0,
    ["type_weather"] = 0,
    ["name"] = "Desert dust",
    ["modifiedTime"] = true,
    ["qnh"] = 758,
    ["groundTurbulence"] = 12,
    ["wind"] = {
        ["atGround"] = { ["speed"] = 12, ["dir"] = 45 },
        ["at2000"] = { ["speed"] = 18, ["dir"] = 50 },
        ["at8000"] = { ["speed"] = 20, ["dir"] = 55 },
    },
    ["visibility"] = { ["distance"] = 5000 },
    ["season"] = { ["temperature"] = 38 },
    ["clouds"] = {
        ["preset"] = "Preset1",
        ["base"] = 4000,
        ["thickness"] = 200,
        ["density"] = 0,
        ["iprecptns"] = 0,
    },
    ["fog"] = { ["visibility"] = 0, ["thickness"] = 0 },
    ["enable_fog"] = false,
    ["enable_dust"] = true,
    ["dust_density"] = 1500,
    ["halo"] = { ["preset"] = "auto" },
    ["cyclones"] = {},
},
```

### Winter Night with Snow

```lua
["date"] = {
    ["Year"] = 2024,
    ["Month"] = 1,
    ["Day"] = 20,
},
["start_time"] = 72000,  -- 20:00
["weather"] = {
    ["atmosphere_type"] = 0,
    ["type_weather"] = 0,
    ["name"] = "Winter night",
    ["modifiedTime"] = true,
    ["qnh"] = 755,
    ["groundTurbulence"] = 3,
    ["wind"] = {
        ["atGround"] = { ["speed"] = 5, ["dir"] = 315 },
        ["at2000"] = { ["speed"] = 10, ["dir"] = 300 },
        ["at8000"] = { ["speed"] = 20, ["dir"] = 290 },
    },
    ["visibility"] = { ["distance"] = 40000 },
    ["season"] = { ["temperature"] = -8 },
    ["clouds"] = {
        ["preset"] = "Preset15",
        ["base"] = 1800,
        ["thickness"] = 500,
        ["density"] = 6,
        ["iprecptns"] = 3,  -- Snow
    },
    ["fog"] = { ["visibility"] = 0, ["thickness"] = 0 },
    ["enable_fog"] = false,
    ["enable_dust"] = false,
    ["dust_density"] = 0,
    ["halo"] = { ["preset"] = "auto" },
    ["cyclones"] = {},
},
```

---

## Weather and AI Sensor Summary

Understanding which weather phenomena affect AI systems helps create balanced scenarios.

| Weather | AI Visual Detection | Radar Systems | Optical/IR SAMs |
|---------|---------------------|---------------|-----------------|
| Clouds | No effect | No effect | No effect |
| Fog | Blocked | No effect | Degraded |
| Dust | Reduced | No effect | Reduced |
| Rain | No effect | No effect | No effect |
| Night | Reduced | No effect | Reduced (optical) |

Radar systems (SAMs, AWACS, fighter radar) are unaffected by any weather or visibility conditions. Fog is the most tactically significant weather element for degrading optically-guided threats.

---

## Runtime Weather Modification (SSE)

Weather can be modified during mission execution using the Simulator Scripting Engine:

```lua
-- Set fog visibility (meters, 0 to disable)
world.weather.setFogVisibilityDistance(500)

-- Set fog thickness (meters, 0 to disable)
world.weather.setFogThickness(100)
```

These functions take effect immediately and override mission file settings.
