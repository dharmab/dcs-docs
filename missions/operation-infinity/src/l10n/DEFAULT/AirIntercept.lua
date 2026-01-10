-- =============================================================================
-- AIR INTERCEPT SYSTEM
-- Dynamic spawning of enemy interceptors from Erusean airfields
-- Integrates with OperationInfinity for difficulty-based aircraft selection
-- =============================================================================

AirIntercept = {}

-- =============================================================================
-- CONFIGURATION
-- =============================================================================

AirIntercept.config = {
    checkInterval = 30,           -- Seconds between zone checks
    spawnCooldown = 120,          -- Seconds between spawns from same airfield
    debug = true,

    -- Aircraft category weights for dynamic max calculation
    aircraftWeights = {
        -- A-A Fighters (weight 2.0)
        ["F-15C"] = 2.0,
        ["F-14A-135-GR"] = 2.0,
        ["F-14B"] = 2.0,
        -- Multirole (weight 1.5)
        ["F-16C_50"] = 1.5,
        ["FA-18C_hornet"] = 1.5,
        ["MiG-29A"] = 1.5,
        ["M-2000C"] = 1.5,
        ["F-15ESE"] = 1.5,
        ["F-4E-45MC"] = 1.5,
        ["Mirage-F1CE"] = 1.5,
        -- Attack/CAS (weight 0.5)
        ["A-10C_2"] = 0.5,
    },

    -- Erusean airfields with defense zones
    airfields = {
        {
            name = "Tbilisi-Lochini",
            zoneCenter = {x = -315000, y = 895000},
            zoneRadius = 45000,
            spawnPoint = {x = -315500, y = 894000},
            spawnAltitude = 3000,
            spawnHeading = 4.71,  -- West
        },
        {
            name = "Mozdok",
            zoneCenter = {x = -83000, y = 835000},
            zoneRadius = 50000,
            spawnPoint = {x = -83500, y = 834000},
            spawnAltitude = 3000,
            spawnHeading = 4.71,
        },
        {
            name = "Kutaisi",
            zoneCenter = {x = -285000, y = 683000},
            zoneRadius = 45000,
            spawnPoint = {x = -284600, y = 685000},
            spawnAltitude = 3000,
            spawnHeading = 4.71,
        },
        {
            name = "Kobuleti",
            zoneCenter = {x = -317000, y = 635000},
            zoneRadius = 40000,
            spawnPoint = {x = -318000, y = 634000},
            spawnAltitude = 3000,
            spawnHeading = 4.71,
        },
        {
            name = "Sukhumi-Babushara",
            zoneCenter = {x = -220000, y = 565000},
            zoneRadius = 50000,
            spawnPoint = {x = -220500, y = 563000},
            spawnAltitude = 3000,
            spawnHeading = 4.71,
        },
    },
}

-- =============================================================================
-- STATE
-- =============================================================================

AirIntercept.state = {
    initialized = false,
    enabled = false,
    difficulty = nil,
    groupCounter = 2000,
    unitCounter = 2000,
    totalAirborne = 0,
    airfieldState = {},  -- Runtime state per airfield
}

-- =============================================================================
-- UTILITY FUNCTIONS
-- =============================================================================

function AirIntercept:log(message)
    if self.config.debug then
        env.info("[AirIntercept] " .. message)
    end
end

function AirIntercept:getNextGroupId()
    self.state.groupCounter = self.state.groupCounter + 1
    return self.state.groupCounter
end

function AirIntercept:getNextUnitId()
    self.state.unitCounter = self.state.unitCounter + 1
    return self.state.unitCounter
end

function AirIntercept:getDistance2D(pos1, pos2)
    local dx = pos1.x - pos2.x
    local dy = pos1.y - pos2.y
    return math.sqrt(dx * dx + dy * dy)
end

-- =============================================================================
-- PLAYER ANALYSIS
-- =============================================================================

function AirIntercept:getPlayersInZone(airfield)
    local players = coalition.getPlayers(coalition.side.BLUE)
    local inZone = {}

    for _, player in ipairs(players) do
        if player and player:isExist() then
            local pos = player:getPoint()
            local playerPos2D = {x = pos.x, y = pos.z}
            local distance = self:getDistance2D(playerPos2D, airfield.zoneCenter)

            -- Only count airborne players (alt > 100m)
            if distance < airfield.zoneRadius and pos.y > 100 then
                table.insert(inZone, player)
            end
        end
    end

    return inZone
end

function AirIntercept:calculateWeightedPlayerCount()
    local players = coalition.getPlayers(coalition.side.BLUE)
    local weightedCount = 0

    for _, player in ipairs(players) do
        if player and player:isExist() then
            local typeName = player:getTypeName()
            local weight = self.config.aircraftWeights[typeName] or 1.0
            weightedCount = weightedCount + weight
        end
    end

    return weightedCount
end

function AirIntercept:calculateDynamicMaxAirborne()
    local fighterConfig = UnitTemplates.Fighters[self.state.difficulty]
    if not fighterConfig then
        return 0
    end

    local baseMax = fighterConfig.maxAirborne or 0
    if baseMax == 0 then
        return 0
    end

    local weightedCount = self:calculateWeightedPlayerCount()
    local dynamicMax = baseMax + math.floor(math.log(weightedCount + 1) / math.log(2))

    -- Cap at 8
    return math.min(dynamicMax, 8)
end

function AirIntercept:calculateResponseSize(intruderCount)
    if intruderCount <= 0 then
        return 0
    elseif intruderCount <= 2 then
        return 1
    elseif intruderCount == 3 then
        return 2
    elseif intruderCount == 4 then
        return 3
    else
        return 4  -- Max per wave
    end
end

-- =============================================================================
-- SPAWN FUNCTIONS
-- =============================================================================

function AirIntercept:createInterceptorGroup(airfield, flightSize, targetUnit)
    local fighterConfig = UnitTemplates.Fighters[self.state.difficulty]
    if not fighterConfig or not fighterConfig.types or #fighterConfig.types == 0 then
        self:log("No fighter types available for difficulty: " .. tostring(self.state.difficulty))
        return nil
    end

    -- Select random aircraft type
    local aircraftType = fighterConfig.types[math.random(#fighterConfig.types)]
    local payload = UnitTemplates:getPayload(self.state.difficulty, aircraftType)
    local skill = UnitTemplates:getRandomSkill(self.state.difficulty)

    local groupId = self:getNextGroupId()
    local groupName = "Erusea-Interceptor-" .. groupId

    -- Get target position for intercept waypoint
    local targetPos = targetUnit:getPoint()
    local interceptPoint = {
        x = (airfield.spawnPoint.x + targetPos.x) / 2,
        y = (airfield.spawnPoint.y + targetPos.z) / 2,
    }

    -- Build units
    local units = {}
    for i = 1, flightSize do
        local unitId = self:getNextUnitId()
        local offset = (i - 1) * 50  -- 50m spacing

        local unit = {
            unitId = unitId,
            name = groupName .. "-" .. i,
            type = aircraftType,
            skill = skill,
            x = airfield.spawnPoint.x + offset,
            y = airfield.spawnPoint.y,
            alt = airfield.spawnAltitude,
            alt_type = "BARO",
            speed = 200,
            heading = airfield.spawnHeading,
            psi = -airfield.spawnHeading,
            onboard_num = string.format("%03d", unitId % 1000),
            livery_id = "default",
            payload = payload or {
                pylons = {},
                fuel = 5000,
                flare = 30,
                chaff = 30,
                gun = 100,
            },
        }

        -- Handle callsign based on aircraft type
        if aircraftType == "MiG-29A" or aircraftType == "MiG-29S" or
           aircraftType == "Su-27" or aircraftType == "J-11A" or
           aircraftType == "MiG-21Bis" then
            unit.callsign = 100 + unitId % 100
        else
            unit.callsign = {
                [1] = 9,  -- Chevy
                [2] = math.floor(groupId / 10) % 10 + 1,
                [3] = i,
                ["name"] = "Chevy" .. ((groupId % 10) + 1) .. i,
            }
        end

        table.insert(units, unit)
    end

    -- Build group data
    local groupData = {
        groupId = groupId,
        name = groupName,
        task = "CAP",
        modulation = 0,
        communication = true,
        frequency = 251,
        start_time = 0,
        uncontrolled = false,
        hidden = false,
        x = airfield.spawnPoint.x,
        y = airfield.spawnPoint.y,
        units = units,
        route = {
            points = {
                [1] = {
                    alt = airfield.spawnAltitude,
                    alt_type = "BARO",
                    type = "Turning Point",
                    action = "Turning Point",
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
                                [1] = {
                                    enabled = true,
                                    auto = false,
                                    id = "EngageTargets",
                                    number = 1,
                                    params = {
                                        targetTypes = {"Air"},
                                        priority = 0,
                                    },
                                },
                                [2] = {
                                    enabled = true,
                                    auto = false,
                                    id = "WrappedAction",
                                    number = 2,
                                    params = {
                                        action = {
                                            id = "Option",
                                            params = {
                                                name = AI.Option.Air.id.ROE,
                                                value = AI.Option.Air.val.ROE.WEAPON_FREE,
                                            },
                                        },
                                    },
                                },
                                [3] = {
                                    enabled = true,
                                    auto = false,
                                    id = "WrappedAction",
                                    number = 3,
                                    params = {
                                        action = {
                                            id = "Option",
                                            params = {
                                                name = AI.Option.Air.id.RADAR_USING,
                                                value = AI.Option.Air.val.RADAR_USING.FOR_ATTACK_ONLY,
                                            },
                                        },
                                    },
                                },
                            },
                        },
                    },
                },
                [2] = {
                    alt = 6000,
                    alt_type = "BARO",
                    type = "Turning Point",
                    action = "Turning Point",
                    x = interceptPoint.x,
                    y = interceptPoint.y,
                    speed = 250,
                    speed_locked = true,
                    ETA = 0,
                    ETA_locked = false,
                    formation_template = "",
                    task = {
                        id = "ComboTask",
                        params = {
                            tasks = {},
                        },
                    },
                },
                [3] = {
                    alt = 6000,
                    alt_type = "BARO",
                    type = "Turning Point",
                    action = "Turning Point",
                    x = targetPos.x,
                    y = targetPos.z,
                    speed = 250,
                    speed_locked = true,
                    ETA = 0,
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
        },
    }

    return groupData
end

function AirIntercept:spawnInterceptors(airfield, flightSize, targetUnit)
    local afState = self.state.airfieldState[airfield.name]
    local currentTime = timer.getTime()

    -- Check cooldown
    if currentTime - afState.lastSpawnTime < self.config.spawnCooldown then
        self:log(airfield.name .. " on cooldown")
        return nil
    end

    -- Check dynamic max airborne
    local maxAirborne = self:calculateDynamicMaxAirborne()
    if self.state.totalAirborne >= maxAirborne then
        self:log("Max airborne reached: " .. self.state.totalAirborne .. "/" .. maxAirborne)
        return nil
    end

    -- Limit flight size to available slots
    local availableSlots = maxAirborne - self.state.totalAirborne
    flightSize = math.min(flightSize, availableSlots)

    -- Create group data
    local groupData = self:createInterceptorGroup(airfield, flightSize, targetUnit)
    if not groupData then
        return nil
    end

    -- Spawn the group
    local group = coalition.addGroup(country.id.CJTF_RED, Group.Category.AIRPLANE, groupData)

    if group then
        afState.lastSpawnTime = currentTime
        afState.totalSpawned = afState.totalSpawned + 1
        self.state.totalAirborne = self.state.totalAirborne + flightSize
        table.insert(afState.spawnedGroups, groupData.name)

        self:log("Spawned " .. flightSize .. " interceptors from " .. airfield.name ..
                 " (" .. groupData.name .. "), total airborne: " .. self.state.totalAirborne)

        return group
    else
        self:log("Failed to spawn interceptors from " .. airfield.name)
        return nil
    end
end

-- =============================================================================
-- EVENT HANDLER
-- =============================================================================

AirIntercept.eventHandler = {}

function AirIntercept.eventHandler:onEvent(event)
    if event.id == world.event.S_EVENT_DEAD or
       event.id == world.event.S_EVENT_CRASH or
       event.id == world.event.S_EVENT_UNIT_LOST then

        local unit = event.initiator
        if unit then
            local unitName = unit:getName()
            AirIntercept:handleUnitDeath(unitName)
        end
    end
end

function AirIntercept:handleUnitDeath(unitName)
    -- Check if this is one of our interceptors
    if not string.find(unitName, "Erusea-Interceptor-", 1, true) then
        return
    end

    -- Find which airfield spawned this group
    for afName, afState in pairs(self.state.airfieldState) do
        for i, groupName in ipairs(afState.spawnedGroups) do
            if string.find(unitName, groupName, 1, true) then
                self.state.totalAirborne = math.max(0, self.state.totalAirborne - 1)
                self:log("Interceptor killed: " .. unitName ..
                         ", total airborne: " .. self.state.totalAirborne)
                return
            end
        end
    end
end

-- =============================================================================
-- MAIN LOOP
-- =============================================================================

function AirIntercept:checkAirfields()
    if not self.state.enabled then
        return timer.getTime() + self.config.checkInterval
    end

    -- VeryEasy has no enemy fighters
    if self.state.difficulty == "VeryEasy" then
        return timer.getTime() + self.config.checkInterval
    end

    -- Cache player data ONCE per update cycle
    local playerData = {}
    local players = coalition.getPlayers(coalition.side.BLUE)
    for _, player in ipairs(players) do
        if player and player:isExist() then
            local pos = player:getPoint()
            table.insert(playerData, {
                unit = player,
                x = pos.x,
                y = pos.z,
                alt = pos.y,
            })
        end
    end

    if #playerData == 0 then
        return timer.getTime() + self.config.checkInterval
    end

    -- Build spawn requests using cached player data (fast, no batching needed)
    local spawnRequests = {}
    for _, airfield in ipairs(self.config.airfields) do
        local intruders = {}
        for _, pData in ipairs(playerData) do
            local dist = self:getDistance2D(pData, airfield.zoneCenter)
            if dist < airfield.zoneRadius and pData.alt > 100 then
                table.insert(intruders, pData)
            end
        end

        if #intruders > 0 then
            local responseSize = self:calculateResponseSize(#intruders)
            local targetUnit = intruders[math.random(#intruders)].unit

            self:log(airfield.name .. ": " .. #intruders ..
                     " intruders detected, response size: " .. responseSize)

            table.insert(spawnRequests, {
                airfield = airfield,
                responseSize = responseSize,
                targetUnit = targetUnit,
            })
        end
    end

    -- Process spawn requests with time budgeting
    if #spawnRequests > 0 then
        self:processSpawnRequestsBatched(spawnRequests)
    end

    return timer.getTime() + self.config.checkInterval
end

-- Process spawn requests with time budgeting
function AirIntercept:processSpawnRequestsBatched(spawnRequests)
    local startTime = os.clock() * 1000
    local budgetMs = BatchScheduler.config.frameBudgetMs
    local itemsProcessed = 0

    for idx, req in ipairs(spawnRequests) do
        self:spawnInterceptors(req.airfield, req.responseSize, req.targetUnit)
        itemsProcessed = itemsProcessed + 1

        local elapsed = (os.clock() * 1000) - startTime
        if itemsProcessed >= 1 and elapsed >= budgetMs then
            -- Schedule remaining spawn requests for next frame
            local remaining = {}
            for i = idx + 1, #spawnRequests do
                table.insert(remaining, spawnRequests[i])
            end
            if #remaining > 0 then
                timer.scheduleFunction(function()
                    AirIntercept:processSpawnRequestsBatched(remaining)
                end, nil, timer.getTime() + 0.001)
            end
            return
        end
    end
end

-- =============================================================================
-- PUBLIC API
-- =============================================================================

function AirIntercept:enable(difficulty)
    self.state.difficulty = difficulty
    self.state.enabled = true
    self:log("Enabled with difficulty: " .. difficulty)
end

function AirIntercept:init()
    if self.state.initialized then
        self:log("Already initialized!")
        return
    end

    self:log("Initializing Air Intercept System...")

    -- Initialize per-airfield state
    for _, airfield in ipairs(self.config.airfields) do
        self.state.airfieldState[airfield.name] = {
            lastSpawnTime = 0,
            totalSpawned = 0,
            spawnedGroups = {},
        }
    end

    -- Register event handler
    world.addEventHandler(self.eventHandler)

    -- Schedule main check loop
    timer.scheduleFunction(function(_, time)
        return AirIntercept:checkAirfields()
    end, nil, timer.getTime() + 10)

    self.state.initialized = true
    self:log("Initialization complete")
end

-- =============================================================================
-- STATS
-- =============================================================================

function AirIntercept:getStats()
    local stats = {
        enabled = self.state.enabled,
        difficulty = self.state.difficulty,
        totalAirborne = self.state.totalAirborne,
        maxAirborne = self:calculateDynamicMaxAirborne(),
        airfields = {},
    }

    for afName, afState in pairs(self.state.airfieldState) do
        stats.airfields[afName] = {
            totalSpawned = afState.totalSpawned,
            activeGroups = #afState.spawnedGroups,
        }
    end

    return stats
end

env.info("[AirIntercept] Loaded successfully")
