# Dynamic Air Intercept Script

This recipe describes how to create a dynamic air intercept script that spawns enemy aircraft from red airfields in response to blue aircraft entering a defense zone. The script scales the response to the number of trespassing aircraft and supports customizable interceptor types, loadouts, and spawn limits.

## Overview

The air intercept system provides:

- **Zone-based detection** - Monitor circular defense zones around red airfields
- **Scaled response** - Spawn interceptors proportional to intruder count (erring on the easier side)
- **Customizable interceptors** - Configure aircraft type, loadout, and skill level per airfield
- **Spawn control** - Support for infinite respawns with airborne limits or finite interceptor pools
- **Cooldown system** - Prevent spam-spawning with configurable delays

## Design Philosophy

Most DCS players are not experts at air combat. Even skilled pilots can be overwhelmed by multiple bandits, especially when flying complex multirole aircraft focused on ground attack. This script errs on the easier side:

- 1-2 intruders spawn 1 interceptor
- 3 intruders spawn 2 interceptors
- 4 intruders spawn 3 interceptors
- 5+ intruders spawn 4 interceptors (maximum per wave)

This keeps engagements manageable while still providing a credible air threat.

## Script Components

The complete script consists of:

1. **Configuration table** - Define airfields, zones, interceptor types, and limits
2. **State tracking** - Track spawned groups, airborne counts, and total spawns
3. **Detection loop** - Periodically scan for blue aircraft in defense zones
4. **Spawn function** - Create interceptor groups with proper tasking
5. **Event handlers** - Track interceptor deaths to update airborne counts

## Complete Script

```lua
-- =============================================================================
-- AIRFIELD INTERCEPT SYSTEM
-- Dynamic spawning of interceptors when players enter airfield defense zones
-- =============================================================================

AirfieldIntercept = {}

-- =============================================================================
-- CONFIGURATION
-- =============================================================================

AirfieldIntercept.config = {
    -- How often to check for intruders (seconds)
    checkInterval = 30,
    
    -- Minimum time between spawns from the same airfield (seconds)
    spawnCooldown = 120,
    
    -- Debug logging
    debug = true,
    
    -- Airfield definitions
    airfields = {
        -- Example: Sukhumi-Babushara
        {
            name = "Sukhumi-Babushara",
            -- Defense zone center (Vec2, map coordinates)
            zoneCenter = {x = -220000, y = 565000},
            -- Defense zone radius (meters) - typically 40-60 km
            zoneRadius = 50000,
            -- Spawn point for interceptors (should be near runway)
            spawnPoint = {x = -220500, y = 563000},
            -- Country ID for spawned aircraft
            countryId = country.id.RUSSIA,
            -- Interceptor configuration
            interceptor = {
                type = "MiG-29A",
                skill = "Good",
                -- Payload configuration
                payload = {
                    pylons = {
                        [1] = {CLSID = "{FBC29BFE-3D24-4C64-B81D-941239D12249}"}, -- R-73
                        [2] = {CLSID = "{9B25D316-0434-4954-868F-D51DB1A38DF0}"}, -- R-27R
                        [3] = {CLSID = "{2BEC576B-CDF5-4B7F-961F-B0FA4312B841}"}, -- Fuel tank
                        [4] = {CLSID = "{2BEC576B-CDF5-4B7F-961F-B0FA4312B841}"}, -- Fuel tank
                        [5] = {CLSID = "{9B25D316-0434-4954-868F-D51DB1A38DF0}"}, -- R-27R
                        [6] = {CLSID = "{FBC29BFE-3D24-4C64-B81D-941239D12249}"}, -- R-73
                    },
                    fuel = 3376,
                    flare = 30,
                    chaff = 30,
                    gun = 100,
                },
                -- Aircraft-specific properties (optional)
                AddPropAircraft = {},
            },
            -- Spawn limits
            maxAirborne = 4,      -- Maximum interceptors in the air at once
            maxTotal = nil,       -- nil = infinite, or set a number for finite pool
            -- Current state (managed by script)
            airborne = 0,
            totalSpawned = 0,
            lastSpawnTime = 0,
            spawnedGroups = {},
        },
        
        -- Example: Kutaisi with Su-27s
        {
            name = "Kutaisi",
            zoneCenter = {x = -285000, y = 683000},
            zoneRadius = 45000,
            spawnPoint = {x = -284600, y = 685000},
            countryId = country.id.RUSSIA,
            interceptor = {
                type = "Su-27",
                skill = "Average",
                payload = {
                    pylons = {
                        [1] = {CLSID = "{FBC29BFE-3D24-4C64-B81D-941239D12249}"},  -- R-73
                        [2] = {CLSID = "{E8ACB3A8-B328-45AB-BD18-015FB6B05C3B}"},  -- R-73
                        [3] = {CLSID = "{9B25D316-0434-4954-868F-D51DB1A38DF0}"},  -- R-27R
                        [4] = {CLSID = "{88DAC840-9F75-4531-8689-B46A5C613D43}"},  -- R-27ER
                        [5] = {CLSID = "{B79C379A-9E87-4E50-A1EE-7F7E29C2E87A}"},  -- R-27ET
                        [6] = {CLSID = "{B79C379A-9E87-4E50-A1EE-7F7E29C2E87A}"},  -- R-27ET
                        [7] = {CLSID = "{88DAC840-9F75-4531-8689-B46A5C613D43}"},  -- R-27ER
                        [8] = {CLSID = "{9B25D316-0434-4954-868F-D51DB1A38DF0}"},  -- R-27R
                        [9] = {CLSID = "{E8ACB3A8-B328-45AB-BD18-015FB6B05C3B}"},  -- R-73
                        [10] = {CLSID = "{FBC29BFE-3D24-4C64-B81D-941239D12249}"}, -- R-73
                    },
                    fuel = 9400,
                    flare = 96,
                    chaff = 96,
                    gun = 100,
                },
            },
            maxAirborne = 2,
            maxTotal = 8,  -- Only 8 interceptors available, then airfield is "dry"
            airborne = 0,
            totalSpawned = 0,
            lastSpawnTime = 0,
            spawnedGroups = {},
        },
    },
}

-- =============================================================================
-- STATE TRACKING
-- =============================================================================

AirfieldIntercept.state = {
    groupCounter = 1000,  -- Starting group ID for spawned interceptors
    unitCounter = 1000,   -- Starting unit ID
    initialized = false,
}

-- =============================================================================
-- UTILITY FUNCTIONS
-- =============================================================================

function AirfieldIntercept:log(message)
    if self.config.debug then
        env.info("[AirfieldIntercept] " .. message)
    end
end

function AirfieldIntercept:getDistance2D(pos1, pos2)
    local dx = pos1.x - pos2.x
    local dy = (pos1.y or pos1.z) - (pos2.y or pos2.z)
    return math.sqrt(dx * dx + dy * dy)
end

function AirfieldIntercept:getNextGroupId()
    self.state.groupCounter = self.state.groupCounter + 1
    return self.state.groupCounter
end

function AirfieldIntercept:getNextUnitId()
    self.state.unitCounter = self.state.unitCounter + 1
    return self.state.unitCounter
end

-- =============================================================================
-- DETECTION FUNCTIONS
-- =============================================================================

function AirfieldIntercept:countIntrudersInZone(airfield)
    local intruders = {}
    local zoneCenter = airfield.zoneCenter
    local zoneRadius = airfield.zoneRadius
    
    -- Get all blue players (human-controlled aircraft)
    local bluePlayers = coalition.getPlayers(coalition.side.BLUE)
    
    for _, player in ipairs(bluePlayers) do
        if player and player:isExist() then
            local pos = player:getPoint()
            local pos2d = {x = pos.x, y = pos.z}
            local distance = self:getDistance2D(pos2d, zoneCenter)
            
            if distance <= zoneRadius then
                table.insert(intruders, player)
            end
        end
    end
    
    return intruders
end

function AirfieldIntercept:calculateResponseSize(intruderCount)
    -- Scale response to intruder count, erring on the easier side
    if intruderCount <= 0 then
        return 0
    elseif intruderCount <= 2 then
        return 1  -- 1-2 intruders: 1 interceptor
    elseif intruderCount == 3 then
        return 2  -- 3 intruders: 2 interceptors
    elseif intruderCount == 4 then
        return 3  -- 4 intruders: 3 interceptors
    else
        return 4  -- 5+ intruders: 4 interceptors (max per wave)
    end
end

-- =============================================================================
-- SPAWN FUNCTIONS
-- =============================================================================

function AirfieldIntercept:generateCallsign()
    -- Russian-style numeric callsigns
    local hundreds = math.random(1, 9)
    local tens = math.random(0, 9)
    local ones = math.random(0, 9)
    return tostring(hundreds) .. tostring(tens) .. tostring(ones)
end

function AirfieldIntercept:createInterceptorGroup(airfield, flightSize, targetUnit)
    local groupId = self:getNextGroupId()
    local groupName = airfield.name .. " Interceptor " .. groupId
    local config = airfield.interceptor
    
    -- Build units array
    local units = {}
    for i = 1, flightSize do
        local unitId = self:getNextUnitId()
        local callsign = self:generateCallsign()
        
        -- Offset wingmen positions slightly
        local offsetX = (i - 1) * 50
        local offsetY = (i - 1) * 30
        
        units[i] = {
            unitId = unitId,
            name = groupName .. "-" .. i,
            type = config.type,
            skill = config.skill,
            x = airfield.spawnPoint.x + offsetX,
            y = airfield.spawnPoint.y + offsetY,
            alt = 300,  -- Spawn altitude (meters)
            alt_type = "BARO",
            speed = 200,  -- Initial speed (m/s)
            heading = 0,
            psi = 0,
            payload = config.payload,
            callsign = callsign,
            onboard_num = callsign,
            AddPropAircraft = config.AddPropAircraft or {},
        }
    end
    
    -- Build route with intercept tasking
    local targetPos = targetUnit:getPoint()
    
    local route = {
        points = {
            -- Takeoff from runway
            [1] = {
                alt = 300,
                alt_type = "BARO",
                type = "TakeOff",
                action = "From Runway",
                x = airfield.spawnPoint.x,
                y = airfield.spawnPoint.y,
                speed = 200,
                speed_locked = true,
                ETA = 0,
                ETA_locked = true,
                formation_template = "",
                task = {
                    id = "ComboTask",
                    params = {
                        tasks = {
                            -- En-route task: Engage air targets
                            [1] = {
                                id = "EngageTargets",
                                enabled = true,
                                auto = false,
                                params = {
                                    targetTypes = {"Air"},
                                    priority = 0,
                                },
                            },
                        },
                    },
                },
            },
            -- Intercept point (toward the intruder)
            [2] = {
                alt = 7000,
                alt_type = "BARO",
                type = "Turning Point",
                action = "Turning Point",
                x = targetPos.x,
                y = targetPos.z,
                speed = 250,
                speed_locked = false,
                ETA_locked = false,
                formation_template = "",
                task = {
                    id = "ComboTask",
                    params = {
                        tasks = {},
                    },
                },
            },
        },
    }
    
    -- Complete group data
    local groupData = {
        groupId = groupId,
        name = groupName,
        task = "CAP",
        modulation = 0,
        communication = true,
        frequency = 124,
        start_time = 0,
        uncontrolled = false,
        hidden = false,
        x = airfield.spawnPoint.x,
        y = airfield.spawnPoint.y,
        units = units,
        route = route,
    }
    
    return groupData
end

function AirfieldIntercept:spawnInterceptors(airfield, flightSize, targetUnit)
    local currentTime = timer.getTime()
    
    -- Check cooldown
    if currentTime - airfield.lastSpawnTime < self.config.spawnCooldown then
        self:log(airfield.name .. ": Spawn on cooldown")
        return nil
    end
    
    -- Check airborne limit
    if airfield.airborne >= airfield.maxAirborne then
        self:log(airfield.name .. ": Max airborne limit reached (" .. airfield.airborne .. "/" .. airfield.maxAirborne .. ")")
        return nil
    end
    
    -- Check total spawn limit (if set)
    if airfield.maxTotal and airfield.totalSpawned >= airfield.maxTotal then
        self:log(airfield.name .. ": Airfield exhausted (no more interceptors available)")
        return nil
    end
    
    -- Adjust flight size based on available capacity
    local availableSlots = airfield.maxAirborne - airfield.airborne
    if airfield.maxTotal then
        local remainingTotal = airfield.maxTotal - airfield.totalSpawned
        availableSlots = math.min(availableSlots, remainingTotal)
    end
    flightSize = math.min(flightSize, availableSlots)
    
    if flightSize <= 0 then
        return nil
    end
    
    -- Create and spawn the group
    local groupData = self:createInterceptorGroup(airfield, flightSize, targetUnit)
    local group = coalition.addGroup(airfield.countryId, Group.Category.AIRPLANE, groupData)
    
    if group then
        -- Update state
        airfield.airborne = airfield.airborne + flightSize
        airfield.totalSpawned = airfield.totalSpawned + flightSize
        airfield.lastSpawnTime = currentTime
        
        -- Track the spawned group
        table.insert(airfield.spawnedGroups, {
            groupName = groupData.name,
            size = flightSize,
        })
        
        self:log(airfield.name .. ": Spawned " .. flightSize .. " interceptor(s) - " .. groupData.name)
        self:log("  Airborne: " .. airfield.airborne .. "/" .. airfield.maxAirborne)
        if airfield.maxTotal then
            self:log("  Total spawned: " .. airfield.totalSpawned .. "/" .. airfield.maxTotal)
        end
        
        -- Set AI options after a short delay (required for stability)
        timer.scheduleFunction(function()
            if group and group:isExist() then
                local controller = group:getController()
                if controller then
                    -- Weapon free against air targets
                    controller:setOption(AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.WEAPON_FREE)
                    -- Aggressive pursuit
                    controller:setOption(AI.Option.Air.id.REACTION_ON_THREAT, AI.Option.Air.val.REACTION_ON_THREAT.EVADE_FIRE)
                    -- Use radar
                    controller:setOption(AI.Option.Air.id.RADAR_USING, AI.Option.Air.val.RADAR_USING.FOR_CONTINUOUS_SEARCH)
                    -- Don't RTB on bingo (fight to the death)
                    controller:setOption(AI.Option.Air.id.RTB_ON_BINGO, false)
                    controller:setOption(AI.Option.Air.id.RTB_ON_OUT_OF_AMMO, false)
                end
            end
        end, nil, timer.getTime() + 2)
        
        return group
    else
        self:log(airfield.name .. ": Failed to spawn interceptors!")
        return nil
    end
end

-- =============================================================================
-- EVENT HANDLER
-- =============================================================================

AirfieldIntercept.eventHandler = {}

function AirfieldIntercept.eventHandler:onEvent(event)
    -- Track interceptor deaths
    if event.id == world.event.S_EVENT_DEAD or 
       event.id == world.event.S_EVENT_CRASH or
       event.id == world.event.S_EVENT_UNIT_LOST then
        
        local unit = event.initiator
        if unit then
            local unitName = unit:getName()
            
            -- Check if this is one of our interceptors
            for _, airfield in ipairs(AirfieldIntercept.config.airfields) do
                for i, spawnedGroup in ipairs(airfield.spawnedGroups) do
                    if string.find(unitName, spawnedGroup.groupName) then
                        -- Decrement airborne count
                        airfield.airborne = math.max(0, airfield.airborne - 1)
                        AirfieldIntercept:log(airfield.name .. ": Interceptor lost (" .. unitName .. ") - Airborne: " .. airfield.airborne)
                        return
                    end
                end
            end
        end
    end
end

-- =============================================================================
-- MAIN LOOP
-- =============================================================================

function AirfieldIntercept:checkAirfields()
    for _, airfield in ipairs(self.config.airfields) do
        -- Skip exhausted airfields
        if airfield.maxTotal and airfield.totalSpawned >= airfield.maxTotal then
            goto continue
        end
        
        -- Count intruders in zone
        local intruders = self:countIntrudersInZone(airfield)
        local intruderCount = #intruders
        
        if intruderCount > 0 then
            self:log(airfield.name .. ": " .. intruderCount .. " intruder(s) detected in zone")
            
            -- Calculate response size
            local responseSize = self:calculateResponseSize(intruderCount)
            
            -- Pick a target (first intruder)
            local targetUnit = intruders[1]
            
            -- Attempt to spawn interceptors
            self:spawnInterceptors(airfield, responseSize, targetUnit)
        end
        
        ::continue::
    end
    
    -- Schedule next check
    return timer.getTime() + self.config.checkInterval
end

-- =============================================================================
-- INITIALIZATION
-- =============================================================================

function AirfieldIntercept:init()
    if self.state.initialized then
        self:log("Already initialized!")
        return
    end
    
    self:log("Initializing Airfield Intercept System...")
    
    -- Register event handler
    world.addEventHandler(self.eventHandler)
    
    -- Start the main check loop
    timer.scheduleFunction(function(_, time)
        return AirfieldIntercept:checkAirfields()
    end, nil, timer.getTime() + self.config.checkInterval)
    
    self.state.initialized = true
    self:log("Initialization complete. Monitoring " .. #self.config.airfields .. " airfield(s)")
    
    -- Log configured airfields
    for _, airfield in ipairs(self.config.airfields) do
        self:log("  - " .. airfield.name .. " (" .. airfield.interceptor.type .. ")")
        self:log("    Zone radius: " .. (airfield.zoneRadius / 1000) .. " km")
        self:log("    Max airborne: " .. airfield.maxAirborne)
        if airfield.maxTotal then
            self:log("    Max total: " .. airfield.maxTotal)
        else
            self:log("    Max total: Unlimited")
        end
    end
end

-- =============================================================================
-- API FUNCTIONS
-- =============================================================================

-- Get status of all airfields
function AirfieldIntercept:getStatus()
    local status = {}
    for _, airfield in ipairs(self.config.airfields) do
        table.insert(status, {
            name = airfield.name,
            airborne = airfield.airborne,
            maxAirborne = airfield.maxAirborne,
            totalSpawned = airfield.totalSpawned,
            maxTotal = airfield.maxTotal,
            exhausted = airfield.maxTotal and airfield.totalSpawned >= airfield.maxTotal,
        })
    end
    return status
end

-- Reset an airfield's spawn count (useful for resupply missions)
function AirfieldIntercept:resupplyAirfield(airfieldName, amount)
    for _, airfield in ipairs(self.config.airfields) do
        if airfield.name == airfieldName then
            if airfield.maxTotal then
                local oldTotal = airfield.totalSpawned
                airfield.totalSpawned = math.max(0, airfield.totalSpawned - (amount or airfield.totalSpawned))
                self:log(airfieldName .. ": Resupplied. Total spawned reset from " .. oldTotal .. " to " .. airfield.totalSpawned)
            end
            return true
        end
    end
    return false
end

-- Manually trigger a scramble from an airfield
function AirfieldIntercept:scramble(airfieldName, flightSize, targetUnit)
    for _, airfield in ipairs(self.config.airfields) do
        if airfield.name == airfieldName then
            return self:spawnInterceptors(airfield, flightSize or 2, targetUnit)
        end
    end
    self:log("Airfield not found: " .. airfieldName)
    return nil
end

-- =============================================================================
-- START THE SYSTEM
-- =============================================================================

-- Call this at mission start
AirfieldIntercept:init()
```

## Configuration Reference

### Airfield Configuration

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Airfield identifier (used for logging and API calls) |
| `zoneCenter` | Vec2 | Defense zone center coordinates `{x, y}` |
| `zoneRadius` | number | Defense zone radius in meters |
| `spawnPoint` | Vec2 | Aircraft spawn location near runway |
| `countryId` | number | Country ID for spawned aircraft (e.g., `country.id.RUSSIA`) |
| `interceptor` | table | Aircraft configuration (see below) |
| `maxAirborne` | number | Maximum interceptors in the air simultaneously |
| `maxTotal` | number or nil | Maximum total spawns (`nil` for unlimited) |

### Interceptor Configuration

| Field | Type | Description |
|-------|------|-------------|
| `type` | string | Aircraft type string (e.g., `"MiG-29A"`, `"Su-27"`) |
| `skill` | string | AI skill level (`"Average"`, `"Good"`, `"High"`, `"Excellent"`) |
| `payload` | table | Weapons and fuel configuration |

### Payload Configuration

| Field | Type | Description |
|-------|------|-------------|
| `pylons` | table | Weapon stations with CLSID references |
| `fuel` | number | Internal fuel in kg |
| `flare` | number | Flare count |
| `chaff` | number | Chaff count |
| `gun` | number | Gun ammunition percentage (0-100) |

## Common Interceptor Loadouts

### MiG-29A Light CAP

```lua
payload = {
    pylons = {
        [1] = {CLSID = "{FBC29BFE-3D24-4C64-B81D-941239D12249}"}, -- R-73
        [2] = {CLSID = "{9B25D316-0434-4954-868F-D51DB1A38DF0}"}, -- R-27R
        [3] = {CLSID = "{2BEC576B-CDF5-4B7F-961F-B0FA4312B841}"}, -- Fuel tank
        [4] = {CLSID = "{2BEC576B-CDF5-4B7F-961F-B0FA4312B841}"}, -- Fuel tank
        [5] = {CLSID = "{9B25D316-0434-4954-868F-D51DB1A38DF0}"}, -- R-27R
        [6] = {CLSID = "{FBC29BFE-3D24-4C64-B81D-941239D12249}"}, -- R-73
    },
    fuel = 3376,
    flare = 30,
    chaff = 30,
    gun = 100,
},
```

### Su-27 Heavy Interceptor

```lua
payload = {
    pylons = {
        [1] = {CLSID = "{FBC29BFE-3D24-4C64-B81D-941239D12249}"},  -- R-73
        [2] = {CLSID = "{E8ACB3A8-B328-45AB-BD18-015FB6B05C3B}"},  -- R-73
        [3] = {CLSID = "{9B25D316-0434-4954-868F-D51DB1A38DF0}"},  -- R-27R
        [4] = {CLSID = "{88DAC840-9F75-4531-8689-B46A5C613D43}"},  -- R-27ER
        [5] = {CLSID = "{B79C379A-9E87-4E50-A1EE-7F7E29C2E87A}"},  -- R-27ET
        [6] = {CLSID = "{B79C379A-9E87-4E50-A1EE-7F7E29C2E87A}"},  -- R-27ET
        [7] = {CLSID = "{88DAC840-9F75-4531-8689-B46A5C613D43}"},  -- R-27ER
        [8] = {CLSID = "{9B25D316-0434-4954-868F-D51DB1A38DF0}"},  -- R-27R
        [9] = {CLSID = "{E8ACB3A8-B328-45AB-BD18-015FB6B05C3B}"},  -- R-73
        [10] = {CLSID = "{FBC29BFE-3D24-4C64-B81D-941239D12249}"}, -- R-73
    },
    fuel = 9400,
    flare = 96,
    chaff = 96,
    gun = 100,
},
```

### MiG-31 Long-Range Interceptor

```lua
payload = {
    pylons = {
        [1] = {CLSID = "{5F26DBC2-FB43-4153-92DE-6BBCE26CB0FF}"}, -- R-33
        [2] = {CLSID = "{5F26DBC2-FB43-4153-92DE-6BBCE26CB0FF}"}, -- R-33
        [3] = {CLSID = "{5F26DBC2-FB43-4153-92DE-6BBCE26CB0FF}"}, -- R-33
        [4] = {CLSID = "{5F26DBC2-FB43-4153-92DE-6BBCE26CB0FF}"}, -- R-33
    },
    fuel = 15500,
    flare = 0,
    chaff = 0,
    gun = 100,
},
```

## Usage Examples

### Basic Setup with Two Airfields

```lua
AirfieldIntercept.config.airfields = {
    {
        name = "Mozdok",
        zoneCenter = {x = -83000, y = 835000},
        zoneRadius = 50000,
        spawnPoint = {x = -83500, y = 834000},
        countryId = country.id.RUSSIA,
        interceptor = {
            type = "MiG-29A",
            skill = "Good",
            payload = { --[[ ... ]] },
        },
        maxAirborne = 4,
        maxTotal = nil,  -- Infinite respawns
        airborne = 0,
        totalSpawned = 0,
        lastSpawnTime = 0,
        spawnedGroups = {},
    },
    {
        name = "Nalchik",
        zoneCenter = {x = -125000, y = 759000},
        zoneRadius = 40000,
        spawnPoint = {x = -125500, y = 760000},
        countryId = country.id.RUSSIA,
        interceptor = {
            type = "Su-27",
            skill = "Average",
            payload = { --[[ ... ]] },
        },
        maxAirborne = 2,
        maxTotal = 6,  -- Only 6 available, then depleted
        airborne = 0,
        totalSpawned = 0,
        lastSpawnTime = 0,
        spawnedGroups = {},
    },
}

AirfieldIntercept:init()
```

### Triggering a Manual Scramble

```lua
-- Find a target
local bluePlayers = coalition.getPlayers(coalition.side.BLUE)
local target = bluePlayers[1]

-- Scramble 2 interceptors from Mozdok
if target then
    AirfieldIntercept:scramble("Mozdok", 2, target)
end
```

### Checking Airfield Status

```lua
local status = AirfieldIntercept:getStatus()
for _, af in ipairs(status) do
    env.info(af.name .. ": " .. af.airborne .. "/" .. af.maxAirborne .. " airborne")
    if af.maxTotal then
        env.info("  Spawned: " .. af.totalSpawned .. "/" .. af.maxTotal)
        if af.exhausted then
            env.info("  EXHAUSTED - No more interceptors available")
        end
    end
end
```

### Resupplying an Airfield

```lua
-- Reset Nalchik's spawn counter (simulating resupply convoy arrival)
AirfieldIntercept:resupplyAirfield("Nalchik", 4)  -- Add 4 interceptors back

-- Or fully resupply
AirfieldIntercept:resupplyAirfield("Nalchik")  -- Reset to full capacity
```

## Tuning Difficulty

### Making It Easier

- Increase `spawnCooldown` (e.g., 180-300 seconds)
- Decrease `maxAirborne` (1-2 per airfield)
- Use lower skill levels (`"Average"`, `"Good"`)
- Use lighter loadouts (fewer missiles)
- Increase `zoneRadius` to give more warning time

### Making It Harder

- Decrease `spawnCooldown` (60-90 seconds)
- Increase `maxAirborne` (4-6 per airfield)
- Use higher skill levels (`"High"`, `"Excellent"`)
- Use heavy interceptors (Su-27, MiG-31) with full loadouts
- Modify `calculateResponseSize()` to spawn more aircraft per intruder

### Custom Response Scaling

Override the response calculation for different behavior:

```lua
function AirfieldIntercept:calculateResponseSize(intruderCount)
    -- More aggressive scaling: match intruder count 1:1
    if intruderCount <= 0 then
        return 0
    else
        return math.min(6, intruderCount)  -- Match intruder count up to 6
    end
end
```

## Checklist

- [ ] Coordinates are in map coordinate system (Vec2: `{x, y}`)
- [ ] `zoneRadius` is appropriate for airfield defense (40-60 km typical)
- [ ] `spawnPoint` is near a runway for realistic takeoffs
- [ ] `countryId` matches the coalition (e.g., Russia for RED)
- [ ] Payload CLSIDs match the aircraft type
- [ ] `maxAirborne` prevents overwhelming players
- [ ] `maxTotal` set appropriately (or `nil` for infinite)
- [ ] State fields initialized (`airborne = 0`, `totalSpawned = 0`, etc.)
- [ ] Script placed in mission initialization trigger or DO SCRIPT FILE

## Troubleshooting

### Interceptors Not Spawning

- Verify coordinates are correct for your map
- Check that `countryId` is valid and belongs to RED coalition
- Ensure `maxAirborne` and `maxTotal` allow spawning
- Verify `spawnCooldown` has elapsed since last spawn
- Check `dcs.log` for error messages

### Interceptors Not Engaging

- Verify EngageTargets task includes `"Air"` in targetTypes
- Check that AI options are set (ROE = WEAPON_FREE)
- Ensure interceptors spawn with weapons (check payload)
- The 2-second delay before setting AI options is required

### Airborne Count Not Updating

- Verify event handler is registered with `world.addEventHandler`
- Check that group names match the pattern used in spawning
- Dead/crash events may not fire for all destruction types

## See Also

- [coalition](../scripting/reference/singletons/coalition.md) - Dynamic group spawning
- [timer](../scripting/reference/singletons/timer.md) - Scheduled function execution
- [events](../scripting/reference/events/events.md) - Event handling for death tracking
- [AI Options](../scripting/reference/ai/options.md) - AI behavior configuration
- [AI Tasks](../scripting/reference/ai/tasks.md) - Task definitions for intercept behavior