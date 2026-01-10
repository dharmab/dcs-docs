-- =============================================================================
-- OPERATION INFINITY - MAIN MISSION SCRIPT
-- F10 menu, battlefield generation, and coordination display
-- =============================================================================

OperationInfinity = {}

-- =============================================================================
-- CONFIGURATION
-- =============================================================================

OperationInfinity.config = {
    coordinateDisplayInterval = 60,  -- Seconds between coordinate broadcasts
    maxSpawnedUnits = 800,
    debug = true,

    -- Battlefield zones by playtime
    battlefieldZones = {
        ["45"] = {
            center = {x = -40000, y = 320000},
            radius = 30000,        -- 30 km
            name = "Anapa/Novorossiysk Area",
            description = "Close Air Support",
        },
        ["90"] = {
            center = {x = -220000, y = 560000},
            radius = 50000,        -- 50 km
            name = "Sukhumi/Zugdidi Area",
            description = "Interdiction",
        },
        ["180"] = {
            center = {x = -290000, y = 700000},
            radius = 60000,        -- 60 km
            name = "Kutaisi/Tbilisi Area",
            description = "Deep Strike",
        },
    },

    -- Frontline generation parameters
    frontline = {
        sectorsMin = 3,
        sectorsMax = 5,
        platoonPairsMin = 2,
        platoonPairsMax = 3,
        engagementDistance = 800,    -- Meters between opposing platoons
        fireOffset = 50,             -- Meters offset for FireAtPoint
    },

    -- Behind-lines targets
    behindLines = {
        convoyCount = {2, 4},        -- Min/max convoys
        artilleryCount = {1, 3},     -- Min/max artillery batteries
        patrolCount = {3, 6},        -- Min/max patrol groups
    },

    -- SAM site counts by difficulty
    samCounts = {
        Normal = {
            SA2 = {0, 1},
            SA3 = {1, 2},
            SA6 = {1, 2},
            SA8 = {2, 3},
            EWR = {2, 3},
        },
        Hard = {
            SA10 = {1, 1},
            SA11 = {1, 2},
            SA6 = {1, 2},
            SA15 = {2, 3},
            EWR = {2, 4},
        },
    },
}

-- =============================================================================
-- STATE
-- =============================================================================

OperationInfinity.state = {
    initialized = false,
    missionGenerated = false,

    -- Settings (locked when first player selects both)
    difficulty = nil,
    playtime = nil,
    settingsLockedBy = nil,

    -- Generated battlefield
    battlefield = {
        center = nil,
        radius = nil,
        sectors = {},
    },

    -- Menu tracking
    settingsMenu = nil,
    difficultyMenu = nil,
    playtimeMenu = nil,

    -- Player tracking
    knownPlayers = {},

    -- Unit counters
    groupCounter = 3000,
    unitCounter = 3000,
}

-- =============================================================================
-- UTILITY FUNCTIONS
-- =============================================================================

function OperationInfinity:log(message)
    if self.config.debug then
        env.info("[OperationInfinity] " .. message)
    end
end

function OperationInfinity:getNextGroupId()
    self.state.groupCounter = self.state.groupCounter + 1
    return self.state.groupCounter
end

function OperationInfinity:getNextUnitId()
    self.state.unitCounter = self.state.unitCounter + 1
    return self.state.unitCounter
end

function OperationInfinity:randomInRange(min, max)
    return math.random(min, max)
end

function OperationInfinity:randomPointInRadius(center, radius)
    local angle = math.random() * 2 * math.pi
    local distance = math.random() * radius
    return {
        x = center.x + distance * math.cos(angle),
        y = center.y + distance * math.sin(angle),
    }
end

-- =============================================================================
-- F10 MENU SYSTEM
-- =============================================================================

function OperationInfinity:setupMenu()
    -- Create root menu
    self.state.settingsMenu = missionCommands.addSubMenuForCoalition(
        coalition.side.BLUE, "Mission Settings", nil
    )

    -- Difficulty submenu
    self.state.difficultyMenu = missionCommands.addSubMenuForCoalition(
        coalition.side.BLUE, "Difficulty", self.state.settingsMenu
    )

    local difficulties = {
        {key = "VeryEasy", label = "Very Easy (Training - no enemies shoot back)"},
        {key = "Easy", label = "Easy (Light defenses, IR missiles only)"},
        {key = "Normal", label = "Normal (IADS, semi-active radar missiles)"},
        {key = "Hard", label = "Hard (Layered IADS, active radar missiles)"},
    }

    for _, diff in ipairs(difficulties) do
        missionCommands.addCommandForCoalition(
            coalition.side.BLUE,
            diff.label,
            self.state.difficultyMenu,
            function() OperationInfinity:selectDifficulty(diff.key) end
        )
    end

    -- Playtime submenu
    self.state.playtimeMenu = missionCommands.addSubMenuForCoalition(
        coalition.side.BLUE, "Target Playtime", self.state.settingsMenu
    )

    local playtimes = {
        {key = "45", label = "45 Minutes (CAS - targets near Krymsk)"},
        {key = "90", label = "90 Minutes (Interdiction - central Caucasus)"},
        {key = "180", label = "180 Minutes (Deep Strike - eastern Caucasus)"},
    }

    for _, pt in ipairs(playtimes) do
        missionCommands.addCommandForCoalition(
            coalition.side.BLUE,
            pt.label,
            self.state.playtimeMenu,
            function() OperationInfinity:selectPlaytime(pt.key) end
        )
    end
end

function OperationInfinity:selectDifficulty(difficulty)
    if self.state.missionGenerated then
        trigger.action.outTextForCoalition(coalition.side.BLUE,
            "Mission already generated!", 10)
        return
    end

    self.state.difficulty = difficulty
    trigger.action.outTextForCoalition(coalition.side.BLUE,
        "Difficulty set to: " .. difficulty, 10)

    self:checkAndGenerate()
end

function OperationInfinity:selectPlaytime(playtime)
    if self.state.missionGenerated then
        trigger.action.outTextForCoalition(coalition.side.BLUE,
            "Mission already generated!", 10)
        return
    end

    self.state.playtime = playtime
    trigger.action.outTextForCoalition(coalition.side.BLUE,
        "Playtime set to: " .. playtime .. " minutes", 10)

    self:checkAndGenerate()
end

function OperationInfinity:checkAndGenerate()
    if self.state.difficulty and self.state.playtime and not self.state.missionGenerated then
        self:lockSettings()
        self:generateBattlefield()
    end
end

function OperationInfinity:lockSettings()
    -- Remove menu items
    if self.state.settingsMenu then
        missionCommands.removeItemForCoalition(coalition.side.BLUE, self.state.settingsMenu)
        self.state.settingsMenu = nil
        self.state.difficultyMenu = nil
        self.state.playtimeMenu = nil
    end
end

-- =============================================================================
-- BATTLEFIELD GENERATION
-- =============================================================================

function OperationInfinity:generateBattlefield()
    self.state.missionGenerated = true

    local zone = self.config.battlefieldZones[self.state.playtime]
    self.state.battlefield.center = zone.center
    self.state.battlefield.radius = zone.radius

    trigger.action.outTextForCoalition(coalition.side.BLUE,
        "=== OPERATION INFINITY ===\n" ..
        "Difficulty: " .. self.state.difficulty .. "\n" ..
        "Playtime: " .. self.state.playtime .. " minutes\n" ..
        "Area: " .. zone.name .. "\n\n" ..
        "Generating battlefield...", 15)

    self:log("Generating battlefield - Difficulty: " .. self.state.difficulty ..
             ", Playtime: " .. self.state.playtime)

    -- Generate frontline sectors
    self:generateFrontlineSectors()

    -- Generate behind-lines targets
    self:generateBehindLinesTargets()

    -- Generate SAM sites (Normal/Hard)
    if self.state.difficulty == "Normal" or self.state.difficulty == "Hard" then
        self:generateAirDefenses()
    end

    -- Generate EWRs (Easy+)
    if self.state.difficulty ~= "VeryEasy" then
        self:generateEWRs()
    end

    -- Initialize other systems
    Virtualization:init()
    Virtualization:spawnPermanentGroups()

    AirIntercept:init()
    AirIntercept:enable(self.state.difficulty)

    IADS:init()
    IADS:enable(self.state.difficulty)

    -- Display coordinates after a short delay
    timer.scheduleFunction(function()
        OperationInfinity:displayCoordinates()
    end, nil, timer.getTime() + 3)

    -- Start coordinate display loop
    self:startCoordinateLoop()

    self:log("Battlefield generation complete")
end

-- =============================================================================
-- FRONTLINE GENERATION
-- =============================================================================

function OperationInfinity:generateFrontlineSectors()
    local numSectors = self:randomInRange(
        self.config.frontline.sectorsMin,
        self.config.frontline.sectorsMax
    )

    self:log("Generating " .. numSectors .. " frontline sectors")

    for i = 1, numSectors do
        local sector = self:generateSector(i)
        table.insert(self.state.battlefield.sectors, sector)
    end
end

function OperationInfinity:generateSector(index)
    -- Position sectors in a spread pattern
    local angle = ((index - 1) / 5) * 2 * math.pi + (math.random() - 0.5) * 0.5
    local distance = self.state.battlefield.radius * (0.3 + math.random() * 0.5)

    local sectorCenter = {
        x = self.state.battlefield.center.x + distance * math.cos(angle),
        y = self.state.battlefield.center.y + distance * math.sin(angle),
    }

    local numPairs = self:randomInRange(
        self.config.frontline.platoonPairsMin,
        self.config.frontline.platoonPairsMax
    )

    self:log("Sector " .. index .. ": " .. numPairs .. " platoon pairs at (" ..
             math.floor(sectorCenter.x) .. ", " .. math.floor(sectorCenter.y) .. ")")

    -- Generate platoon pairs
    for j = 1, numPairs do
        self:generatePlatoonPair(sectorCenter, index, j)
    end

    -- Generate SHORAD for this sector
    self:generateSectorSHORAD(sectorCenter, index)

    return {center = sectorCenter, platoonPairs = numPairs}
end

function OperationInfinity:generatePlatoonPair(sectorCenter, sectorIndex, pairIndex)
    local offset = (pairIndex - 1) * 300  -- Spread pairs along front
    local engageDist = self.config.frontline.engagementDistance

    -- Randomize the front line orientation slightly
    local frontAngle = math.random() * 0.3 - 0.15  -- Small angle variation

    -- ISAF platoon position (south side)
    local isafPos = {
        x = sectorCenter.x + offset * math.cos(frontAngle),
        y = sectorCenter.y - engageDist / 2,
    }

    -- Erusea platoon position (north side)
    local eruseaPos = {
        x = sectorCenter.x + offset * math.cos(frontAngle),
        y = sectorCenter.y + engageDist / 2,
    }

    -- Build ISAF units
    local isafUnits = self:buildPlatoonUnits(UnitTemplates.ISAFPlatoon, isafPos)
    Virtualization:registerGroup({
        name = "ISAF-S" .. sectorIndex .. "-P" .. pairIndex,
        center = isafPos,
        units = isafUnits,
        countryId = country.id.CJTF_BLUE,
        category = Group.Category.GROUND,
    }, {
        immortal = true,
        invisible = true,
        fireAtPoint = {
            x = eruseaPos.x,
            y = eruseaPos.y - self.config.frontline.fireOffset,
            radius = 50,
            expendQty = 200,
        },
    })

    -- Build Erusea units
    local diff = self.state.difficulty
    local eruseaTemplate = UnitTemplates.EruseaPlatoon[diff] or UnitTemplates.EruseaPlatoon.Normal
    local eruseaUnits = self:buildPlatoonUnits(eruseaTemplate, eruseaPos)
    Virtualization:registerGroup({
        name = "Erusea-S" .. sectorIndex .. "-P" .. pairIndex,
        center = eruseaPos,
        units = eruseaUnits,
        countryId = country.id.CJTF_RED,
        category = Group.Category.GROUND,
    }, {
        immortal = false,
        invisible = false,
        fireAtPoint = {
            x = isafPos.x,
            y = isafPos.y + self.config.frontline.fireOffset,
            radius = 50,
            expendQty = 200,
        },
    })
end

function OperationInfinity:buildPlatoonUnits(template, center)
    local units = {}
    local unitIndex = 1
    local spacing = 30  -- Meters between units

    for _, def in ipairs(template) do
        for c = 1, def.count do
            local row = math.floor((unitIndex - 1) / 3)
            local col = (unitIndex - 1) % 3
            local offset_x = col * spacing
            local offset_y = row * spacing

            units[#units + 1] = {
                type = def.type,
                x = center.x + offset_x,
                y = center.y + offset_y,
                heading = 0,
                skill = "High",
            }
            unitIndex = unitIndex + 1
        end
    end

    return units
end

function OperationInfinity:generateSectorSHORAD(sectorCenter, sectorIndex)
    local diff = self.state.difficulty
    local shoradTemplate = UnitTemplates.SHORAD[diff]

    if not shoradTemplate or #shoradTemplate == 0 then
        return
    end

    -- Position SHORAD slightly behind Erusean lines
    local shoradPos = {
        x = sectorCenter.x + (math.random() - 0.5) * 500,
        y = sectorCenter.y + 1000 + math.random() * 500,
    }

    local units = self:buildPlatoonUnits(shoradTemplate, shoradPos)
    Virtualization:registerGroup({
        name = "SHORAD-S" .. sectorIndex,
        center = shoradPos,
        units = units,
        countryId = country.id.CJTF_RED,
        category = Group.Category.GROUND,
    }, {
        immortal = false,
        invisible = false,
    })
end

-- =============================================================================
-- BEHIND-LINES TARGETS
-- =============================================================================

function OperationInfinity:generateBehindLinesTargets()
    -- Generate convoys
    local numConvoys = self:randomInRange(
        self.config.behindLines.convoyCount[1],
        self.config.behindLines.convoyCount[2]
    )
    for i = 1, numConvoys do
        self:generateConvoy(i)
    end

    -- Generate artillery batteries
    local numArtillery = self:randomInRange(
        self.config.behindLines.artilleryCount[1],
        self.config.behindLines.artilleryCount[2]
    )
    for i = 1, numArtillery do
        self:generateArtilleryBattery(i)
    end

    -- Generate patrol groups
    local numPatrols = self:randomInRange(
        self.config.behindLines.patrolCount[1],
        self.config.behindLines.patrolCount[2]
    )
    for i = 1, numPatrols do
        self:generatePatrolGroup(i)
    end

    self:log("Generated behind-lines targets: " .. numConvoys .. " convoys, " ..
             numArtillery .. " artillery, " .. numPatrols .. " patrols")
end

function OperationInfinity:generateConvoy(index)
    -- Position convoys behind Erusean lines (north of battlefield center)
    local pos = {
        x = self.state.battlefield.center.x + (math.random() - 0.5) * self.state.battlefield.radius,
        y = self.state.battlefield.center.y + self.state.battlefield.radius * 0.3 +
            math.random() * self.state.battlefield.radius * 0.5,
    }

    local units = self:buildPlatoonUnits(UnitTemplates.LogisticsConvoy, pos)
    Virtualization:registerGroup({
        name = "Convoy-" .. index,
        center = pos,
        units = units,
        countryId = country.id.CJTF_RED,
        category = Group.Category.GROUND,
    }, {
        immortal = false,
        invisible = false,
    })
end

function OperationInfinity:generateArtilleryBattery(index)
    -- Position artillery further behind lines
    local pos = {
        x = self.state.battlefield.center.x + (math.random() - 0.5) * self.state.battlefield.radius * 0.8,
        y = self.state.battlefield.center.y + self.state.battlefield.radius * 0.5 +
            math.random() * self.state.battlefield.radius * 0.3,
    }

    local units = self:buildPlatoonUnits(UnitTemplates.ArtilleryBattery, pos)

    -- Find a frontline position to fire at
    local targetSector = self.state.battlefield.sectors[math.random(#self.state.battlefield.sectors)]
    local fireTarget = nil
    if targetSector then
        fireTarget = {
            x = targetSector.center.x + (math.random() - 0.5) * 500,
            y = targetSector.center.y - 400,  -- Aim at ISAF side
            radius = 100,
            expendQty = 500,
        }
    end

    Virtualization:registerGroup({
        name = "Artillery-" .. index,
        center = pos,
        units = units,
        countryId = country.id.CJTF_RED,
        category = Group.Category.GROUND,
    }, {
        immortal = false,
        invisible = false,
        fireAtPoint = fireTarget,
    })
end

function OperationInfinity:generatePatrolGroup(index)
    -- Scatter patrol groups throughout the battlefield
    local pos = self:randomPointInRadius(
        self.state.battlefield.center,
        self.state.battlefield.radius * 0.9
    )

    local units = {
        {type = "BRDM-2", x = pos.x, y = pos.y, heading = math.random() * 2 * math.pi, skill = "Average"},
        {type = "BRDM-2", x = pos.x + 30, y = pos.y + 30, heading = math.random() * 2 * math.pi, skill = "Average"},
    }

    Virtualization:registerGroup({
        name = "Patrol-" .. index,
        center = pos,
        units = units,
        countryId = country.id.CJTF_RED,
        category = Group.Category.GROUND,
    }, {
        immortal = false,
        invisible = false,
    })
end

-- =============================================================================
-- AIR DEFENSE GENERATION
-- =============================================================================

function OperationInfinity:generateAirDefenses()
    local samCounts = self.config.samCounts[self.state.difficulty]
    if not samCounts then
        return
    end

    local samTemplates = UnitTemplates.SAMSites[self.state.difficulty]
    if not samTemplates then
        return
    end

    self:log("Generating air defenses for difficulty: " .. self.state.difficulty)

    for samType, countRange in pairs(samCounts) do
        if samType ~= "EWR" then
            local template = samTemplates[samType]
            if template then
                local count = self:randomInRange(countRange[1], countRange[2])
                for i = 1, count do
                    self:generateSAMSite(samType, template, i)
                end
            end
        end
    end
end

function OperationInfinity:generateSAMSite(samType, template, index)
    -- Position SAM sites within battlefield, with heavier ones further back
    local distanceMultiplier = 0.5
    if samType == "SA10" or samType == "SA11" then
        distanceMultiplier = 0.7  -- Longer range SAMs further back
    end

    local angle = math.random() * 2 * math.pi
    local distance = self.state.battlefield.radius * distanceMultiplier +
                     math.random() * self.state.battlefield.radius * 0.3

    local pos = {
        x = self.state.battlefield.center.x + distance * math.cos(angle),
        y = self.state.battlefield.center.y + distance * math.sin(angle),
    }

    local units = self:buildSAMUnits(template, pos)
    local groupName = samType .. "-" .. index

    -- Register as permanent group (always spawned - SAM radars need to be active)
    Virtualization:registerPermanentGroup({
        name = groupName,
        center = pos,
        units = units,
        countryId = country.id.CJTF_RED,
        category = Group.Category.GROUND,
    })

    -- Register with IADS for emission control
    IADS:registerSAMSite(groupName, samType, pos)

    self:log("Generated " .. samType .. " at (" .. math.floor(pos.x) .. ", " .. math.floor(pos.y) .. ")")
end

function OperationInfinity:buildSAMUnits(template, center)
    local units = {}
    local unitIndex = 1

    for _, def in ipairs(template) do
        for c = 1, def.count do
            -- Arrange in a circular pattern
            local angle = (unitIndex - 1) * (2 * math.pi / 8)
            local radius = 50 + (unitIndex - 1) * 30

            units[#units + 1] = {
                type = def.type,
                x = center.x + radius * math.cos(angle),
                y = center.y + radius * math.sin(angle),
                heading = angle + math.pi,  -- Face outward
                skill = "Excellent",
            }
            unitIndex = unitIndex + 1
        end
    end

    return units
end

function OperationInfinity:generateEWRs()
    local samCounts = self.config.samCounts[self.state.difficulty]
    local ewrCountRange = nil

    if samCounts and samCounts.EWR then
        ewrCountRange = samCounts.EWR
    else
        -- Default for Easy difficulty
        ewrCountRange = {1, 2}
    end

    local samTemplates = UnitTemplates.SAMSites[self.state.difficulty]
    local ewrTemplate = nil

    if samTemplates and samTemplates.EWR then
        ewrTemplate = samTemplates.EWR
    else
        -- Default EWR
        ewrTemplate = {{type = "1L13 EWR", count = 1}}
    end

    local count = self:randomInRange(ewrCountRange[1], ewrCountRange[2])

    for i = 1, count do
        -- Position EWRs on high ground throughout the area
        local angle = (i - 1) * (2 * math.pi / count) + math.random() * 0.5
        local distance = self.state.battlefield.radius * 0.6 + math.random() * self.state.battlefield.radius * 0.3

        local pos = {
            x = self.state.battlefield.center.x + distance * math.cos(angle),
            y = self.state.battlefield.center.y + distance * math.sin(angle),
        }

        local units = {}
        for _, def in ipairs(ewrTemplate) do
            for c = 1, def.count do
                units[#units + 1] = {
                    type = def.type,
                    x = pos.x + (c - 1) * 50,
                    y = pos.y,
                    heading = 0,
                    skill = "Excellent",
                }
            end
        end

        local groupName = "EWR-" .. i

        -- EWRs are permanent groups
        Virtualization:registerPermanentGroup({
            name = groupName,
            center = pos,
            units = units,
            countryId = country.id.CJTF_RED,
            category = Group.Category.GROUND,
        })

        IADS:registerEWR(groupName)

        self:log("Generated EWR at (" .. math.floor(pos.x) .. ", " .. math.floor(pos.y) .. ")")
    end
end

-- =============================================================================
-- COORDINATE DISPLAY
-- =============================================================================

function OperationInfinity:formatCoordinates(pos)
    -- Convert to Lat/Lon
    local lat, lon, alt = coord.LOtoLL(pos.x, 0, pos.y)

    -- Convert to MGRS
    local mgrs = coord.LLtoMGRS(lat, lon)
    local mgrsStr = mgrs.UTMZone .. mgrs.MGRSDigraph .. " " ..
                    string.format("%05d", math.floor(mgrs.Easting)) .. " " ..
                    string.format("%05d", math.floor(mgrs.Northing))

    -- Format Lat/Lon
    local latDir = lat >= 0 and "N" or "S"
    local lonDir = lon >= 0 and "E" or "W"
    local latDeg = math.floor(math.abs(lat))
    local latMin = (math.abs(lat) - latDeg) * 60
    local lonDeg = math.floor(math.abs(lon))
    local lonMin = (math.abs(lon) - lonDeg) * 60

    local llStr = string.format("%02d*%06.3f'%s %03d*%06.3f'%s",
        latDeg, latMin, latDir, lonDeg, lonMin, lonDir)

    return llStr, mgrsStr
end

function OperationInfinity:displayCoordinates()
    if not self.state.missionGenerated then
        return
    end

    local center = self.state.battlefield.center
    local zone = self.config.battlefieldZones[self.state.playtime]

    local llStr, mgrsStr = self:formatCoordinates(center)

    local msg = string.format(
        "=== TARGET AREA ===\n" ..
        "%s\n\n" ..
        "Center:\n" ..
        "  MGRS: %s\n" ..
        "  LL: %s\n\n" ..
        "Radius: %d km\n\n" ..
        "Difficulty: %s\n" ..
        "Good hunting!",
        zone.name, mgrsStr, llStr,
        zone.radius / 1000,
        self.state.difficulty
    )

    trigger.action.outTextForCoalition(coalition.side.BLUE, msg, 30)
end

function OperationInfinity:startCoordinateLoop()
    timer.scheduleFunction(function(_, time)
        if OperationInfinity.state.missionGenerated then
            OperationInfinity:displayCoordinates()
        end
        return time + OperationInfinity.config.coordinateDisplayInterval
    end, nil, timer.getTime() + self.config.coordinateDisplayInterval)
end

-- =============================================================================
-- LATE JOINER SUPPORT
-- =============================================================================

function OperationInfinity:checkForNewPlayers()
    local players = coalition.getPlayers(coalition.side.BLUE)

    for _, player in ipairs(players) do
        if player and player:isExist() then
            local name = player:getName()
            if not self.state.knownPlayers[name] then
                self.state.knownPlayers[name] = true

                if self.state.missionGenerated then
                    -- Send coordinates to new player after a short delay
                    timer.scheduleFunction(function()
                        OperationInfinity:displayCoordinates()
                    end, nil, timer.getTime() + 5)

                    self:log("New player joined: " .. name)
                end
            end
        end
    end
end

-- =============================================================================
-- STATS
-- =============================================================================

function OperationInfinity:getStats()
    local virtStats = Virtualization:getStats()
    local airStats = AirIntercept:getStats()
    local iadsStats = IADS:getStats()

    return {
        missionGenerated = self.state.missionGenerated,
        difficulty = self.state.difficulty,
        playtime = self.state.playtime,
        sectors = #self.state.battlefield.sectors,
        virtualization = virtStats,
        airIntercept = airStats,
        iads = iadsStats,
    }
end

-- =============================================================================
-- INITIALIZATION
-- =============================================================================

function OperationInfinity:init()
    if self.state.initialized then
        self:log("Already initialized!")
        return
    end

    self:log("Initializing Operation Infinity...")

    -- Seed random number generator
    math.randomseed(os.time())

    -- Display initial hint
    timer.scheduleFunction(function()
        trigger.action.outTextForCoalition(coalition.side.BLUE,
            "=== OPERATION INFINITY ===\n\n" ..
            "Welcome to Operation Infinity!\n\n" ..
            "Use the F10 menu to select:\n" ..
            "  1. Difficulty\n" ..
            "  2. Target Playtime\n\n" ..
            "The first player to make both selections\n" ..
            "locks the settings for all players.\n\n" ..
            "Support assets available:\n" ..
            "  AWACS Overlord: 255.5 MHz\n" ..
            "  Texaco (boom): 270.5 MHz, TACAN 100X\n" ..
            "  Arco (drogue): 270.1 MHz, TACAN 101X", 30)
    end, nil, timer.getTime() + 5)

    -- Setup F10 menu
    self:setupMenu()

    -- Start late joiner check loop
    timer.scheduleFunction(function(_, time)
        OperationInfinity:checkForNewPlayers()
        return time + 10  -- Check every 10 seconds
    end, nil, timer.getTime() + 10)

    self.state.initialized = true
    self:log("Initialization complete")
end

-- =============================================================================
-- START
-- =============================================================================

OperationInfinity:init()

env.info("[OperationInfinity] Loaded successfully")
